
using Distributed

@everywhere include("solver.jl")

import Redis
import Redis: execute_command

function check_worker_timeouts(pid, lk, active_timeouts)
    function (t)
        if !in(pid, workers())
            close(t)
            return
        end
        lock(lk) do
            for depth in length(active_timeouts):-1:1
                threshold_time, status, retries = active_timeouts[depth]
                if status == 1
                    if threshold_time + 10 < time()
                        active_timeouts[depth] = time(), 1, retries + 1
                        if retries >= 3
                            @warn "Killing worker $pid because retried too many times $retries"
                            # @warn "Killing worker $pid because retried too many times $retries for depth $depth $threshold_time"
                            rmprocs(pid, waitfor = 0)
                        else
                            @warn "Interrupting worker $pid again $retries"
                            # @warn "Interrupting worker $pid again $retries for depth $depth $threshold_time"
                            interrupt(pid)
                        end
                    end
                    break
                elseif threshold_time < time()
                    max_depth = length(active_timeouts)
                    last_threshold, _, _ = active_timeouts[max_depth]
                    active_timeouts[max_depth] = last_threshold, 1, retries + 1
                    @warn "Interrupting worker $pid"
                    # @warn "Interrupting worker $pid for depth $depth max $max_depth $threshold_time"
                    interrupt(pid)
                    break
                end
            end
        end
    end
end

function handle_timeout_messages(pid, lk, timeout_request_channel, timeout_response_channel, active_timeouts)
    while true
        message = take!(timeout_request_channel)
        # @info "Got message from worker $pid $message"
        lock(lk) do
            if message[1] == 0
                _, threshold_time = message
                if length(active_timeouts) > 0 && active_timeouts[end][2] == 1
                    # @warn "Don't set new timeout $threshold_time for worker $pid because previous was fired"
                    put!(timeout_response_channel, -1)
                else
                    push!(active_timeouts, (threshold_time, 0, 0))
                    # @info "Setting new timeout for worker $pid $threshold_time $(length(active_timeouts))"
                    put!(timeout_response_channel, length(active_timeouts))
                end
            elseif message[1] == 1
                _, depth, expected_status = message
                if depth > length(active_timeouts)
                    # @warn "Trying to remove already removed timeout for worker $pid $depth"
                    put!(timeout_response_channel, 2)
                else
                    if depth < length(active_timeouts)
                        _, current_status, _ = active_timeouts[end]
                        threshold_time, _, _ = active_timeouts[depth]
                        # @warn "Trying to remove non-top timeout for worker $pid $depth $threshold_time"
                        if current_status == expected_status
                            while depth < length(active_timeouts)
                                pop!(active_timeouts)
                            end
                        end
                    else
                        threshold_time, current_status, _ = active_timeouts[depth]
                    end
                    if current_status == expected_status
                        # @info "Successfully remove timeout $expected_status for worker $pid $depth $threshold_time"
                        pop!(active_timeouts)
                        put!(timeout_response_channel, 0)
                    else
                        # @info "Conflict on removing timeout $expected_status for worker $pid $depth $threshold_time"
                        put!(timeout_response_channel, 1)
                    end
                end
            end
            # while isready(timeout_response_channel)
            #     sleep(0.001)
            # end
        end
    end
end

function start_timeout_monitor(pid)
    lk = ReentrantLock()
    timeout_request_channel = RemoteChannel(() -> Channel{Tuple}(1))
    timeout_response_channel = RemoteChannel(() -> Channel{Int}(1))
    active_timeouts = []
    Timer(check_worker_timeouts(pid, lk, active_timeouts), 1, interval = 1)
    @async handle_timeout_messages(pid, lk, timeout_request_channel, timeout_response_channel, active_timeouts)
    return timeout_request_channel, timeout_response_channel
end

function setup_worker(pid, source_path)
    @async begin
        @fetchfrom pid begin
            task_local_storage()[:SOURCE_PATH] = source_path
            include("solver.jl")
        end
        @warn "Starting timeout monitor for new worker $pid"
        req_channel, resp_channel = start_timeout_monitor(pid)
        @warn "Created channels for new worker $pid"
        # @fetchfrom pid solver.init_logger()
        @spawnat pid solver.worker_loop(req_channel, resp_channel)
        @warn "Finished setting up worker $pid"
    end
end

function add_new_workers(count, source_path)
    @warn "Adding $count new workers"
    new_pids = addprocs(count)
    setup_futures = [setup_worker(pid, source_path) for pid in new_pids]
    for f in setup_futures
        fetch(f)
    end
    @info "Finished adding new workers"
    new_pids
end

function should_stop(conn)
    has_new_commands = Redis.llen(conn, "commands")
    if has_new_commands > 0
        _, message = Redis.blpop(conn, ["commands"], 0)

        if message == "stop"
            Redis.rpush(conn, "commands", message)
            @info "Stopping enumeration service"
            return true
        end
    end
    false
end

function main()
    @info "Starting enumeration service"
    # @everywhere solver.init_logger()

    source_path = get(task_local_storage(), :SOURCE_PATH, nothing)

    for pid in workers()
        req_channel, resp_channel = start_timeout_monitor(pid)
        @spawnat pid solver.worker_loop(req_channel, resp_channel)
    end

    active_workers = workers()
    num_workers = length(active_workers)

    conn = Redis.RedisConnection()
    while true
        if should_stop(conn)
            break
        end

        if workers() == active_workers
            sleep(1)
            continue
        end

        dead_pids = []
        for pid in active_workers
            if !in(pid, workers())
                @warn "Worker $pid is dead"
                push!(dead_pids, pid)
                processing_key = "processing:$pid"
                payload = Redis.get(conn, processing_key)
                if !isnothing(payload)
                    @warn "Rescheduling task from worker $pid"
                    Redis.multi(conn)
                    Redis.rpush(conn, "tasks", payload)
                    Redis.del(conn, processing_key)
                    Redis.execute_command(conn, ["exec"])
                end
            end
        end

        active_workers = [pid for pid in active_workers if !in(pid, dead_pids)]
        if should_stop(conn)
            break
        end
        new_pids = add_new_workers(num_workers - length(active_workers), source_path)
        append!(active_workers, new_pids)
        sleep(1)
    end
    Redis.disconnect(conn)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end

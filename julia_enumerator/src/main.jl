
using Distributed

@everywhere include("solver.jl")

import Redis
import Redis: execute_command

function setup_worker(pid, source_path)
    @async begin
        @fetchfrom pid begin
            task_local_storage()[:SOURCE_PATH] = source_path
            include("solver.jl")
        end
        @warn "Starting timeout monitor for new worker $pid"
        timeout_container = solver.start_timeout_monitor(pid)
        @warn "Created timeout container for new worker $pid"
        # @fetchfrom pid solver.init_logger()
        @spawnat pid solver.worker_loop(timeout_container)
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

    sleep(1)
    for pid in workers()
        timeout_container = solver.start_timeout_monitor(pid)
        @spawnat pid solver.worker_loop(timeout_container)
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

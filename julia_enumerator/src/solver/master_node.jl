
using Distributed
import Redis
import Redis: execute_command

function setup_worker(pid, source_path)
    @async begin
        ex = Expr(:toplevel, :(task_local_storage()[:SOURCE_PATH] = $(source_path)), :(using solver))
        Distributed.remotecall_eval(Main, pid, ex)
        @warn "Starting timeout monitor for new worker $pid"
        timeout_container = start_timeout_monitor(pid)
        @warn "Created timeout container for new worker $pid"
        # @spawnat pid worker_loop(timeout_container)
        remotecall(Core.eval, pid, @__MODULE__, :($worker_loop($timeout_container)))
        @warn "Finished setting up worker $pid"
    end
end

function add_new_workers(count, source_path)
    @warn "Adding $count new workers"
    new_pids = addprocs(count, exeflags = "--heap-size-hint=1G")

    created_pids = []

    setup_futures = [(pid, setup_worker(pid, source_path)) for pid in new_pids]
    for (pid, f) in setup_futures
        try
            fetch(f)
            push!(created_pids, pid)
        catch e
            bt = catch_backtrace()
            @error "Failed to setup worker $pid" exception = (e, bt)
        end
    end
    @info "Finished adding new workers"
    created_pids
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

using ArgParse
using JSON

function dc_main_node()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "-c"
        help = "number of workers to start"
        arg_type = Int
        default = 1
    end

    parsed_args = parse_args(ARGS, s)
    num_workers = parsed_args["c"]

    @info "Starting enumeration service with $num_workers workers"

    source_path = get(task_local_storage(), :SOURCE_PATH, nothing)

    sleep(1)

    active_workers = add_new_workers(num_workers, source_path)

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
                    queue = JSON.parse(payload)["queue"]
                    Redis.rpush(conn, queue, payload)
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

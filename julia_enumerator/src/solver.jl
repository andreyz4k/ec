module solver

include("timeout.jl")
include("logging.jl")
include("type.jl")
include("program.jl")
include("grammar.jl")
include("task.jl")
include("load.jl")
include("data_structures/data_structures.jl")
include("data_complexity.jl")
include("enumeration.jl")
include("export.jl")
include("profiling.jl")

import Redis
import Redis: execute_command

mutable struct RedisContext
    conn::Redis.RedisConnection
end

function get_conn(ctx::RedisContext)
    if Redis.is_connected(ctx.conn)
        ctx.conn
    else
        ctx.conn = Redis.RedisConnection()
        ctx.conn
    end
end

function disconnect_redis(ctx::RedisContext)
    if Redis.is_connected(ctx.conn)
        Redis.disconnect(ctx.conn)
    end
end

function run_solving_process(run_context, message)
    @info "running processing"
    @info message
    task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, _verbose, program_timeout = load_problems(message)
    run_context["program_timeout"] = program_timeout
    run_context["timeout"] = timeout
    solutions, number_enumerated = enumerate_for_task(g, type_weights, task, maximum_frontier, timeout)
    return export_frontiers(number_enumerated, task, solutions)
end

using Distributed

function get_new_task(redis)
    while true
        try
            conn = get_conn(redis)
            # watch(conn, "tasks")
            queue, message = Redis.blpop(conn, ["commands", "tasks"], 0)
            if queue == "commands" && message == "stop"
                # unwatch(conn)
                Redis.rpush(conn, "commands", message)
                return message
            end
            Redis.multi(conn)
            Redis.set(conn, "processing:$(myid())", message)
            res = Redis.execute_command(conn, ["exec"])
            if res == ["OK"]
                return message
            end
        catch e
            bt = catch_backtrace()
            @error "Error while fetching task" exception = (e, bt)
            disconnect_redis(redis)
            rethrow()
        end
    end
end

using JSON

function worker_loop(req_channel, resp_channel)
    @info "Starting worker loop"
    redis = RedisContext(Redis.RedisConnection())
    i = 1
    while true
        try
            message = get_new_task(redis)
            if message == "stop"
                @info "Stopping worker"
                break
            end
            payload = JSON.parse(message)
            timeout = payload["timeout"]
            name = payload["name"]
            @info "Running task number $i $name"
            i += 1
            output = @time try
                run_context = Dict{String,Any}(
                    "timeout_request_channel" => req_channel,
                    "timeout_response_channel" => resp_channel,
                    "timeout" => timeout,
                )
                result = run_solving_process(run_context, payload)
                if isnothing(result)
                    result = Dict("number_enumerated" => 0, "solutions" => [])
                end
                Dict("status" => "success", "payload" => result, "name" => name)
            catch e
                buf = IOBuffer()
                bt = catch_backtrace()
                showerror(buf, e, bt)
                @error "Error while running task" exception = (e, bt)
                Dict("status" => "error", "payload" => String(take!(buf)), "name" => name)
            end
            conn = get_conn(redis)
            Redis.multi(conn)
            Redis.rpush(conn, "results", JSON.json(output))
            Redis.del(conn, "processing:$(myid())")
            Redis.execute_command(conn, ["exec"])
        catch e
            disconnect_redis(redis)
            bt = catch_backtrace()
            @error "Error while processing a task" exception = (e, bt)
            rethrow()
        end
    end
    disconnect(conn)
end

end

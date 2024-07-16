module solver

include("timeout.jl")
include("logging.jl")
include("load.jl")
include("data_structures/data_structures.jl")
include("grammar.jl")
include("primitives.jl")
include("abstractors/abstractors.jl")
include("data_complexity.jl")
include("enumeration.jl")
include("export.jl")
include("sample.jl")
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
    task, maximum_frontier, g, type_weights, hyperparameters, _mfp, _nc, timeout, _verbose, program_timeout =
        load_problems(message)
    run_context["program_timeout"] = program_timeout
    run_context["timeout"] = timeout
    solutions, number_enumerated =
        enumerate_for_task(run_context, g, type_weights, hyperparameters, task, maximum_frontier, timeout)
    return export_frontiers(number_enumerated, task, solutions)
end

using Distributed

function get_new_task(redis)
    while true
        try
            conn = get_conn(redis)
            # watch(conn, "tasks")
            queue, message = Redis.blpop(conn, ["commands", "tasks", "sample"], 0)
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

function process_solving_task(payload, timeout_container, redis, i)
    timeout = payload["timeout"]
    name = payload["name"]
    @info "Running task number $i $name"
    output = @time try
        run_context = Dict{String,Any}("timeout_container" => timeout_container, "timeout" => timeout)
        result = run_solving_process(run_context, payload)
        if isnothing(result)
            result = Dict("number_enumerated" => 0, "solutions" => [])
        end
        Dict("status" => "success", "payload" => result, "name" => name)
    catch e
        if isa(e, InterruptException)
            @warn "Interrupted"
            rethrow()
        end
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
end

function process_sampling_task(payload, timeout_container, redis, i)
    timeout = payload["timeout"]
    @info "Running sampling number $i"
    @info payload
    output = @time try
        run_context = Dict{String,Any}("timeout_container" => timeout_container, "timeout" => timeout)
        result = run_sampling_process(run_context, payload)

        Dict("status" => "success", "payload" => result)
    catch e
        if isa(e, InterruptException)
            @warn "Interrupted"
            rethrow()
        end
        buf = IOBuffer()
        bt = catch_backtrace()
        showerror(buf, e, bt)
        @error "Error while running task" exception = (e, bt)
        Dict("status" => "error", "payload" => String(take!(buf)))
    end
    conn = get_conn(redis)
    Redis.multi(conn)
    try
        Redis.rpush(conn, "sample_result", JSON.json(output))
    catch e
        if isa(e, InterruptException)
            @warn "Interrupted"
            rethrow()
        end
        buf = IOBuffer()
        bt = catch_backtrace()
        showerror(buf, e, bt)
        @error "Error while saving result to redis" exception = (e, bt)
        output = Dict("status" => "error", "payload" => String(take!(buf)))
        Redis.rpush(conn, "sample_result", JSON.json(output))
    end
    Redis.del(conn, "processing:$(myid())")
    Redis.execute_command(conn, ["exec"])
end

function worker_loop(timeout_container)
    @info "Starting worker loop"
    redis = RedisContext(Redis.RedisConnection())
    i = 0
    j = 0
    while true
        try
            message = get_new_task(redis)
            if message == "stop"
                @info "Stopping worker"
                break
            end
            payload = JSON.parse(message)
            if payload["queue"] == "tasks"
                i += 1
                process_solving_task(payload, timeout_container, redis, i)
            elseif payload["queue"] == "sample"
                j += 1
                process_sampling_task(payload, timeout_container, redis, j)
            end

        catch e
            disconnect_redis(redis)
            bt = catch_backtrace()
            @error "Error while processing a task" exception = (e, bt)
            rethrow()
        end
    end
    disconnect_redis(redis)
end

end

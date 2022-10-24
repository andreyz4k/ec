
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

function set_timeout(redis::RedisContext, queue_name::String, end_time::Float64)
    while true
        try
            conn = get_conn(redis)
            Redis.watch(conn, queue_name)
            depth::Int = Redis.hlen(conn, queue_name)
            Redis.multi(conn)
            Redis.hset(conn, queue_name, depth, "$end_time|0")
            res = Redis.execute_command(conn, ["exec"])
            # @info "Set timeout $res"
            if res == [1]
                return depth
            end
        catch
            disconnect_redis(redis)
            rethrow()
        end
    end
end

function remove_timeout(redis::RedisContext, queue_name::String, depth::Int)
    while true
        try
            conn = get_conn(redis)
            Redis.watch(conn, queue_name)
            status::String = Redis.hget(conn, queue_name, depth)
            if status[end] == '0'
                Redis.multi(conn)
                Redis.hdel(conn, queue_name, depth)
                res = Redis.execute_command(conn, ["exec"])
                # @info "remove timeout $res"
                if res == [1]
                    return
                end
            else
                Redis.unwatch(conn)
                while true
                    sleep(1)
                end
            end
        catch
            disconnect_redis(redis)
            rethrow()
        end
    end
end

function clean_fired_timeout(redis::RedisContext, queue_name::String, depth::Int)
    while true
        try
            conn = get_conn(redis)
            Redis.watch(conn, queue_name)
            status = Redis.hget(conn, queue_name, depth)
            if status[end] == '1'
                Redis.multi(conn)
                Redis.hdel(conn, queue_name, depth)
                res = Redis.execute_command(conn, ["exec"])
                # @info "clean fired timeout $res"
                if res == [1]
                    return
                end
            else
                Redis.unwatch(conn)
                error("Wrong timeout status on cleanup")
            end
        catch
            disconnect_redis(redis)
            rethrow()
        end
    end
end

macro run_with_timeout(timeout, redis, expr)
    return quote
        local end_time = time() + $(esc(timeout))
        local queue_name = "timeouts:$(myid())"
        local depth = set_timeout($(esc(redis)), queue_name, end_time)

        local result = nothing
        try
            got_interrupt = false
            try
                result = $(esc(expr))
            catch e
                if isa(e, InterruptException)
                    got_interrupt = true
                end
                rethrow()
            finally
                if !got_interrupt
                    remove_timeout($(esc(redis)), queue_name, depth)
                end
            end
        catch e
            if isa(e, InterruptException)
                clean_fired_timeout($(esc(redis)), queue_name, depth)
            else
                rethrow()
            end
        end
        result
    end
end

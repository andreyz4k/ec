using SharedArrays
using SharedMemoryLocks
struct TimeoutContainer
    lock::SharedMemoryLock
    time::SharedArray{Float64,1}
    status::SharedArray{Int64,1}  # 0: running -1:finished 1+:fired n times
end

function TimeoutContainer(pids)
    cont = TimeoutContainer(
        SharedMemoryLock(pids),
        SharedArray{Float64,1}(1, pids = pids),
        SharedArray{Int64,1}(1, pids = pids),
    )
    cont.status[1] = -1
    return cont
end

function set_timeout(container::TimeoutContainer, timeout)
    lock(container.lock) do
        end_time = time() + timeout
        container.time[1] = end_time
        container.status[1] = 0
    end
end

function remove_timeout(container::TimeoutContainer)
    need_wait = lock(container.lock) do
        if container.status[1] > 0
            return true
        else
            container.status[1] = -1
            return false
        end
    end
    if need_wait
        @warn "Waiting for interrupt to arrive"
        flush(stdout)
        while true
            sleep(1)
        end
    end
end

function clean_fired_timeout(container::TimeoutContainer)
    lock(container.lock) do
        @warn "Cleaning fired timeout"
        if container.status[1] > 0
            container.status[1] = -1
        else
            error("Trying to clean non-fired timeout")
        end
    end
end

function check_worker_timeouts(pid, container::TimeoutContainer)
    function (t)
        if !in(pid, workers())
            @warn "Stopping timeout monitor for worker $pid"
            close(t)
            return
        end
        need_interrupt, need_kill = lock(container.lock) do
            if container.status[1] == -1
                return false, false
            elseif container.status[1] == 0
                if container.time[1] < time()
                    @warn "Timeout threshold reached for worker $pid $(container.time[1]) $(time())"
                    container.status[1] = 1
                    @warn "Interrupting worker $pid"
                    return true, false
                end
            else
                if container.time[1] + 10 < time()
                    @warn "Extended timeout threshold reached for worker $pid $(container.time[1] + 10) $(time())"
                    container.status[1] += 1
                    if container.status[1] > 3
                        @warn "Killing worker $pid because retried too many times $(container.status[1])"
                        return false, true
                    else
                        @warn "Interrupting worker $pid again $(container.status[1])"
                        return true, false
                    end
                end
            end
            return false, false
        end
        if need_interrupt
            interrupt(pid)
            @warn "Sent interrupt to worker $pid"
        end
        if need_kill
            rmprocs(pid, waitfor = 0)
            @warn "Sent kill to worker $pid"
        end
    end
end

function start_timeout_monitor(pid)
    container = TimeoutContainer([pid, myid()])
    Timer(check_worker_timeouts(pid, container), 1, interval = 1)
    return container
end

macro run_with_timeout(run_context, timeout_key, expr)
    return quote
        local context = $(esc(run_context))
        if !haskey(context, "timeout_container")
            $(esc(expr))
        else
            local timeout = context[$(esc(timeout_key))]
            local timeout_container = context["timeout_container"]
            set_timeout(timeout_container, timeout)

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
                        remove_timeout(timeout_container)
                    end
                end
            catch e
                if isa(e, InterruptException)
                    # bt = catch_backtrace()
                    # @warn "Interrupted" exception = (e, bt)
                    @warn "Interrupted"
                    clean_fired_timeout(timeout_container)
                else
                    rethrow()
                end
            end
            result
        end
    end
end

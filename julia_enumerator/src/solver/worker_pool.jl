
mutable struct ReplenishingWorkerPool <: AbstractWorkerPool
    pool::WorkerPool
    num_workers::Int
    timeout_containers::Dict{Int,TimeoutContainer}
    launcher_futures::Vector{Base.Task}
    ReplenishingWorkerPool(num_workers) = new(WorkerPool(), num_workers, Dict(), [])
end

function add_new_worker(pool::ReplenishingWorkerPool)
    @async begin
        try
            pid = addprocs(1, exeflags = "--heap-size-hint=1G")[1]
            @warn "running import on new worker $pid"
            ex = Expr(
                :toplevel,
                :(task_local_storage()[:SOURCE_PATH] = $(get(task_local_storage(), :SOURCE_PATH, nothing))),
                :(using solver),
            )
            Distributed.remotecall_eval(Main, pid, ex)
            @warn "Starting timeout monitor for new worker $pid"
            timeout_container = start_timeout_monitor(pid)
            @warn "Created timeout container for new worker $pid"
            pool.timeout_containers[pid] = timeout_container
            push!(pool.pool, pid)
        catch e
            bt = catch_backtrace()
            @error "Failed to setup worker" exception = (e, bt)
        end
    end
end

function Base.take!(pool::ReplenishingWorkerPool)
    if pool.num_workers == 0
        error("No workers available")
    end
    filter!(f -> !istaskdone(f), pool.launcher_futures)
    for worker in pool.pool.workers
        if !Distributed.id_in_procs(worker)
            delete!(pool.pool.workers, worker)
            delete!(pool.timeout_containers, worker)
        end
    end
    if length(pool.pool.workers) + length(pool.launcher_futures) < pool.num_workers
        n = pool.num_workers - length(pool.pool.workers) - length(pool.launcher_futures)
        @warn "Adding $n new workers"
        for _ in 1:n
            f = add_new_worker(pool)
            push!(pool.launcher_futures, f)
        end
    end

    wait(pool.pool.channel)
    take!(pool.pool)
end

function Base.length(pool::ReplenishingWorkerPool)
    pool.num_workers
end

function Base.put!(pool::ReplenishingWorkerPool, pid::Int64)
    put!(pool.pool, pid)
end

function Distributed.isready(pool::ReplenishingWorkerPool)
    isready(pool.pool)
end

function stop(pool::ReplenishingWorkerPool)
    pool.num_workers = 0
    for f in pool.launcher_futures
        wait(f)
    end
    rmprocs(pool.pool.workers...)
end

function Distributed.workers(pool::ReplenishingWorkerPool)
    pool.pool.workers
end

function Distributed.nworkers(pool::ReplenishingWorkerPool)
    pool.num_workers
end

function Distributed.remotecall_pool(rc_f, f, pool::ReplenishingWorkerPool, args...; kwargs...)
    worker = take!(pool)
    try
        thunk = :($f($args...; $kwargs...))
        rc_f(Core.eval, worker, @__MODULE__, thunk)
    finally
        put!(pool, worker)
    end
end

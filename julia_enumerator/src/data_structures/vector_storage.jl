
mutable struct VectorStorage{T,F}
    transaction_depth::Int
    base_values::GBMatrix{T,F}
    updates_stack::Vector{GBMatrix{T,Nothing}}
end

VectorStorage{T}() where {T} = VectorStorage{T,Nothing}(0, GBMatrix{T}(MAX_GRAPH_SIZE, 1), [])
VectorStorage{T}(v::F) where {T,F} = VectorStorage{T,F}(0, GBMatrix{T}(MAX_GRAPH_SIZE, 1, fill = v), [])

function start_transaction!(storage::VectorStorage)
    storage.transaction_depth += 1
end

function save_changes!(storage::VectorStorage)
    if storage.transaction_depth <= length(storage.updates_stack)
        new_values = storage.updates_stack[storage.transaction_depth]
        if storage.transaction_depth == 1
            values = storage.base_values
        else
            values = storage.updates_stack[storage.transaction_depth-1]
        end
        if nnz(new_values) > 0
            subassign!(values, new_values, :, :; desc = Descriptor(structural_mask = true), mask = new_values)
        end
    end
    drop_changes!(storage)
end

function drop_changes!(storage::VectorStorage)
    if storage.transaction_depth <= length(storage.updates_stack)
        empty!(storage.updates_stack[storage.transaction_depth])
    end
    storage.transaction_depth -= 1
end

function Base.setindex!(storage::VectorStorage{T}, value, ind::UInt64) where {T}
    while storage.transaction_depth > length(storage.updates_stack)
        push!(storage.updates_stack, GBMatrix{T}(MAX_GRAPH_SIZE, 1))
    end
    storage.updates_stack[storage.transaction_depth][ind, 1] = value
end

function Base.getindex(storage::VectorStorage{T}, ind::UInt64)::Union{T,Nothing} where {T}
    v = nothing
    for i in min(length(storage.updates_stack), (storage.transaction_depth)):-1:1
        v = storage.updates_stack[i][ind, 1]
        if !isnothing(v)
            return v
        end
    end
    return storage.base_values[ind, 1]
end

function Base.getindex(storage::VectorStorage, inds)
    vals = storage.base_values[inds, 1]
    for i in 1:min(length(storage.updates_stack), (storage.transaction_depth))
        # if nnz(vals) == 0
        #     vals = storage.updates_stack[i][inds, 1]
        # else
        new_vals = storage.updates_stack[i][inds, 1]
        if nnz(new_vals) > 0
            subassign!(vals, new_vals, :, :; desc = Descriptor(structural_mask = true), mask = new_vals)
        end
        # end
    end
    return vals
end

function get_new_values(storage::VectorStorage)::Vector{UInt64}
    if storage.transaction_depth == 0 || length(storage.updates_stack) == 0
        return UInt64[]
    elseif storage.transaction_depth == 1
        return nonzeroinds(storage.updates_stack[1])[1]
    else
        inds = Set{UInt64}()
        for i in 1:min(length(storage.updates_stack), (storage.transaction_depth))
            union!(inds, nonzeroinds(storage.updates_stack[i])[1])
        end
        return Vector{UInt64}(sort(collect(inds)))
    end
end

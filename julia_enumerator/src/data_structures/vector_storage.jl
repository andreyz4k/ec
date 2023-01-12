
mutable struct VectorStorage{T}
    transaction_depth::Int
    values_stack::Vector{GBMatrix{T}}
end

VectorStorage{T}() where {T} = VectorStorage{T}(0, [GBMatrix{T}(MAX_GRAPH_SIZE, 1)])
VectorStorage{T}(v) where {T} = VectorStorage{T}(0, [GBMatrix{T}(MAX_GRAPH_SIZE, 1, fill = v)])

function start_transaction!(storage::VectorStorage)
    storage.transaction_depth += 1
end

function save_changes!(storage::VectorStorage)
    if storage.transaction_depth + 1 <= length(storage.values_stack)
        new_values = storage.values_stack[storage.transaction_depth+1]
        if nnz(new_values) > 0
            subassign!(
                storage.values_stack[storage.transaction_depth],
                new_values,
                :,
                :;
                desc = Descriptor(structural_mask = true),
                mask = new_values,
            )
        end
    end
    drop_changes!(storage)
end

function drop_changes!(storage::VectorStorage)
    if storage.transaction_depth + 1 <= length(storage.values_stack)
        empty!(storage.values_stack[storage.transaction_depth+1])
    end
    storage.transaction_depth -= 1
end

function Base.setindex!(storage::VectorStorage{T}, value, ind::Integer) where {T}
    while storage.transaction_depth + 1 > length(storage.values_stack)
        push!(storage.values_stack, GBMatrix{T}(MAX_GRAPH_SIZE, 1))
    end
    storage.values_stack[storage.transaction_depth+1][ind, 1] = value
end

function Base.getindex(storage::VectorStorage, ind::Integer)
    v = nothing
    for i in min(length(storage.values_stack), (storage.transaction_depth + 1)):-1:1
        v = storage.values_stack[i][ind, 1]
        if !isnothing(v)
            return v
        end
    end
    return v
end

function Base.getindex(storage::VectorStorage, inds)
    vals = storage.values_stack[1][inds, 1]
    for i in 2:min(length(storage.values_stack), (storage.transaction_depth + 1))
        if nnz(vals) == 0
            vals = storage.values_stack[i][inds, 1]
        else
            new_vals = storage.values_stack[i][inds, 1]
            if nnz(new_vals) > 0
                subassign!(vals, new_vals, :, :; desc = Descriptor(structural_mask = true), mask = new_vals)
            end
        end
    end
    return vals
end

function get_new_values(storage::VectorStorage)::Vector{Int}
    if storage.transaction_depth == 0 || length(storage.values_stack) == 1
        return Int[]
    elseif storage.transaction_depth == 1
        return nonzeroinds(storage.values_stack[2])[1]
    else
        inds = Set{UInt64}()
        for i in 2:min(length(storage.values_stack), (storage.transaction_depth + 1))
            union!(inds, nonzeroinds(storage.values_stack[i])[1])
        end
        return Vector{Int}(sort(collect(inds)))
    end
end

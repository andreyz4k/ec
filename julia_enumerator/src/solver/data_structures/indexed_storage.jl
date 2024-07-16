
mutable struct IndexedStorage{T}
    transaction_depth::Int
    values_stack::Vector{Tuple{Vector{T},Dict{T,UInt64}}}
    total_length::Int
end

IndexedStorage{T}() where {T} = IndexedStorage{T}(0, [(Vector{T}(), Dict{T,UInt64}())], 0)

function Base.push!(storage::IndexedStorage{T}, value::T)::UInt64 where {T}
    for (_, val_to_ind) in reverse(storage.values_stack)
        if haskey(val_to_ind, value)
            return val_to_ind[value]
        end
    end
    while storage.transaction_depth + 1 > length(storage.values_stack)
        push!(storage.values_stack, (Vector{T}(), Dict{T,UInt64}()))
    end
    push!(storage.values_stack[storage.transaction_depth+1][1], value)
    storage.total_length += 1
    storage.values_stack[storage.transaction_depth+1][2][value] = storage.total_length
    return storage.total_length
end

function Base.getindex(storage::IndexedStorage, ind::UInt64)
    for (values, _) in storage.values_stack
        if ind <= length(values)
            return values[ind]
        end
        ind -= length(values)
    end
end

function Base.length(storage::IndexedStorage)
    return storage.total_length
end

function get_index(storage::IndexedStorage, value)::UInt64
    for (_, val_to_ind) in storage.values_stack
        if haskey(val_to_ind, value)
            return val_to_ind[value]
        end
    end
    throw(KeyError(value))
end

function start_transaction!(storage::IndexedStorage, depth)
    storage.transaction_depth = depth
    for d in depth+1:length(storage.values_stack)
        empty!(storage.values_stack[d][1])
        empty!(storage.values_stack[d][2])
    end
end

function save_changes!(storage::IndexedStorage{T}, depth) where {T}
    for d in (length(storage.values_stack)-1):-1:(depth+1)
        new_vals, new_vals_to_ind = storage.values_stack[d+1]
        added_vars = vcat(storage.values_stack[d][1], new_vals)
        merged_vars = merge(storage.values_stack[d][2], new_vals_to_ind)
        storage.values_stack[d:d+1] = [(added_vars, merged_vars), (Vector{T}(), Dict{T,UInt64}())]
    end
    storage.transaction_depth = depth
end

function drop_changes!(storage::IndexedStorage{T}, depth) where {T}
    for d in (length(storage.values_stack)-1):-1:(depth+1)
        new_vals = storage.values_stack[d+1][1]
        new_length = storage.total_length - length(new_vals)
        storage.total_length, storage.values_stack[d+1] = new_length, (Vector{T}(), Dict{T,UInt64}())
    end
    storage.transaction_depth = depth
end

function get_new_values(storage::IndexedStorage)
    if storage.transaction_depth == 0
        return 1:0
    end
    return (length(storage.values_stack[1][1])+1):storage.total_length
end


mutable struct IndexedStorage{T}
    transaction_depth::Int
    values_stack::Vector{Tuple{Vector{T},Dict{T,Int}}}
    total_length::Int
end

IndexedStorage{T}() where {T} = IndexedStorage{T}(0, [(Vector{T}(), Dict{T,Int}())], 0)

function Base.push!(storage::IndexedStorage{T}, value::T)::Int where {T}
    for (_, val_to_ind) in reverse(storage.values_stack)
        if haskey(val_to_ind, value)
            return val_to_ind[value]
        end
    end
    while storage.transaction_depth + 1 > length(storage.values_stack)
        push!(storage.values_stack, (Vector{T}(), Dict{T,Int}()))
    end
    push!(storage.values_stack[storage.transaction_depth+1][1], value)
    storage.total_length += 1
    storage.values_stack[storage.transaction_depth+1][2][value] = storage.total_length
    return storage.total_length
end

function Base.getindex(storage::IndexedStorage, ind::Integer)
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

function get_index(storage::IndexedStorage, value)::Int
    for (_, val_to_ind) in storage.values_stack
        if haskey(val_to_ind, value)
            return val_to_ind[value]
        end
    end
    throw(KeyError(value))
end

function start_transaction!(storage::IndexedStorage)
    storage.transaction_depth += 1
end

function save_changes!(storage::IndexedStorage)
    if storage.transaction_depth + 1 <= length(storage.values_stack)
        new_vals, new_vals_to_ind = storage.values_stack[storage.transaction_depth+1]
        append!(storage.values_stack[storage.transaction_depth][1], new_vals)
        storage.total_length += length(new_vals)
        merge!(storage.values_stack[storage.transaction_depth][2], new_vals_to_ind)
    end
    drop_changes!(storage)
end

function drop_changes!(storage::IndexedStorage)
    if storage.transaction_depth + 1 <= length(storage.values_stack)
        new_vals, new_vals_to_ind = storage.values_stack[storage.transaction_depth+1]
        storage.total_length -= length(new_vals)
        empty!(new_vals)
        empty!(new_vals_to_ind)
    end
    storage.transaction_depth -= 1
end

function get_new_values(storage::IndexedStorage)
    if storage.transaction_depth == 0
        return 1:0
    end
    return (length(storage.values_stack[1][1])+1):storage.total_length
end


mutable struct CountStorage
    transaction_depth::Int
    values::Vector{UInt64}
end

CountStorage() = CountStorage(0, [0])

function Base.getindex(storage::CountStorage)
    return storage.values[end]
end

function start_transaction!(storage::CountStorage, depth)
    while depth + 1 < length(storage.values)
        pop!(storage.values)
    end
    storage.transaction_depth = depth
end

function save_changes!(storage::CountStorage, depth)
    if depth + 1 < length(storage.values)
        storage.values[depth+1] = storage.values[end]
    end
    drop_changes!(storage, depth)
end

function drop_changes!(storage::CountStorage, depth)
    while depth + 1 < length(storage.values)
        pop!(storage.values)
    end
    storage.transaction_depth = depth
end

function increment!(storage::CountStorage)
    while storage.transaction_depth + 1 > length(storage.values)
        push!(storage.values, storage.values[end])
    end
    storage.values[end] += 1
    storage.values[end]
end

function get_new_values(storage::CountStorage)
    if storage.transaction_depth == 0
        return 1:0
    end
    return (storage.values[begin]+1):storage.values[end]
end

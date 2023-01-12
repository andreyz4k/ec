
mutable struct CountStorage
    transaction_depth::Int
    values::Vector{Int}
end

CountStorage() = CountStorage(0, [0])

function Base.getindex(storage::CountStorage)
    return storage.values[end]
end

function start_transaction!(storage::CountStorage)
    storage.transaction_depth += 1
end

function save_changes!(storage::CountStorage)
    if storage.transaction_depth + 1 == length(storage.values)
        v = pop!(storage.values)
        storage.values[end] = v
    end
    storage.transaction_depth -= 1
end

function drop_changes!(storage::CountStorage)
    if storage.transaction_depth + 1 == length(storage.values)
        pop!(storage.values)
    end
    storage.transaction_depth -= 1
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

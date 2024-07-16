
mutable struct VectorStorage{T}
    transaction_depth::Int
    values_stack::Vector{Dict{UInt64,T}}
end

VectorStorage{T}() where {T} = VectorStorage{T}(0, [Dict{UInt64,T}()])

function start_transaction!(storage::VectorStorage, depth)
    storage.transaction_depth = depth
    for d in depth+1:length(storage.values_stack)
        empty!(storage.values_stack[d])
    end
end

function save_changes!(storage::VectorStorage{T}, depth) where {T}
    for d in (length(storage.values_stack)-1):-1:(depth+1)
        new_vals = storage.values_stack[d+1]
        storage.values_stack[d:d+1] = [merge(storage.values_stack[d], new_vals), Dict{UInt64,T}()]
    end
    storage.transaction_depth = depth
end

function drop_changes!(storage::VectorStorage, depth)
    for d in (length(storage.values_stack)-1):-1:(depth+1)
        empty!(storage.values_stack[d+1])
    end
    storage.transaction_depth = depth
end

function Base.setindex!(storage::VectorStorage{T}, value, ind::UInt64) where {T}
    while storage.transaction_depth + 1 > length(storage.values_stack)
        push!(storage.values_stack, Dict{UInt64,T}())
    end
    storage.values_stack[storage.transaction_depth+1][ind] = value
end

function Base.getindex(storage::VectorStorage{T}, ind::UInt64)::Union{T,Nothing} where {T}
    for i in min(length(storage.values_stack), (storage.transaction_depth + 1)):-1:1
        if haskey(storage.values_stack[i], ind)
            return storage.values_stack[i][ind]
        end
    end
    return nothing
end

function Base.getindex(storage::VectorStorage{Bool}, ind::UInt64)::Bool
    for i in min(length(storage.values_stack), (storage.transaction_depth + 1)):-1:1
        if haskey(storage.values_stack[i], ind)
            return storage.values_stack[i][ind]
        end
    end
    return false
end

function get_new_values(storage::VectorStorage)::Vector{UInt64}
    if storage.transaction_depth == 0 || length(storage.values_stack) == 1
        return UInt64[]
    elseif storage.transaction_depth == 2
        return collect(keys(storage.values_stack[2]))
    else
        inds = Set{UInt64}()
        for i in 2:min(length(storage.values_stack), (storage.transaction_depth + 1))
            union!(inds, keys(storage.values_stack[i]))
        end
        return Vector{UInt64}(sort(collect(inds)))
    end
end

function get_sum(storage::VectorStorage, indices, init)
    result = init
    for i in indices
        c = storage[i]
        if !isnothing(c)
            result += c
        end
    end
    return result
end

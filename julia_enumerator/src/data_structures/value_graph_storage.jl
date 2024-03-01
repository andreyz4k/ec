
mutable struct ValueGraphStorage
    transaction_depth::Int
    rows::Dict{UInt64,Dict{UInt64,UInt64}}
    columns::Dict{UInt64,Dict{UInt64,UInt64}}
    updates_stack::Vector{Tuple{Dict{UInt64,Dict{UInt64,UInt64}},Dict{UInt64,Dict{UInt64,UInt64}}}}
end

ValueGraphStorage() = ValueGraphStorage(0, Dict{UInt64,Dict{UInt64,UInt64}}(), Dict{UInt64,Dict{UInt64,UInt64}}(), [])

function start_transaction!(storage::ValueGraphStorage, depth)
    storage.transaction_depth = depth
    for d in depth:length(storage.updates_stack)
        empty!(storage.updates_stack[d][1])
        empty!(storage.updates_stack[d][2])
    end
end

function save_changes!(storage::ValueGraphStorage, depth)
    for d in (length(storage.updates_stack)-1):-1:(depth)
        new_rows, new_columns = storage.updates_stack[d+1]
        if d == 0
            rows = storage.rows
            columns = storage.columns
        else
            rows = storage.updates_stack[d][1]
            columns = storage.updates_stack[d][2]
        end
        if !isempty(new_rows)
            rows = merge(merge, rows, new_rows)
            columns = merge(merge, columns, new_columns)
            if d == 0
                storage.rows, storage.columns, storage.updates_stack[d+1] =
                    rows, columns, (Dict{UInt64,Dict{UInt64,UInt64}}(), Dict{UInt64,Dict{UInt64,UInt64}}())
            else
                storage.updates_stack[d:d+1] =
                    [(rows, columns), (Dict{UInt64,Dict{UInt64,UInt64}}(), Dict{UInt64,Dict{UInt64,UInt64}}())]
            end
        end
    end
    storage.transaction_depth = depth
end

function drop_changes!(storage::ValueGraphStorage, depth)
    for d in (length(storage.updates_stack)):-1:(depth+1)
        empty!(storage.updates_stack[d][1])
        empty!(storage.updates_stack[d][2])
    end
    storage.transaction_depth = depth
end

function ensure_stack_depth(storage::ValueGraphStorage)
    while storage.transaction_depth > length(storage.updates_stack)
        push!(storage.updates_stack, (Dict{UInt64,Dict{UInt64,UInt64}}(), Dict{UInt64,Dict{UInt64,UInt64}}()))
    end
end

function Base.getindex(storage::ValueGraphStorage, i::UInt64, j::UInt64)
    for k in min(length(storage.updates_stack), storage.transaction_depth):-1:1
        if haskey(storage.updates_stack[k][1], i) && haskey(storage.updates_stack[k][1][i], j)
            return storage.updates_stack[k][1][i][j]
        end
    end
    if haskey(storage.rows, i) && haskey(storage.rows[i], j)
        return storage.rows[i][j]
    end
    return nothing
end

function get_connected_from(storage::ValueGraphStorage, i::UInt64)
    if haskey(storage.rows, i)
        res = copy(storage.rows[i])
    else
        res = Dict{UInt64,UInt64}()
    end
    for k in 1:min(storage.transaction_depth, length(storage.updates_stack))
        if haskey(storage.updates_stack[k][1], i)
            merge!(res, storage.updates_stack[k][1][i])
        end
    end
    return res
end

function get_connected_to(storage::ValueGraphStorage, j::UInt64)
    if haskey(storage.columns, j)
        res = copy(storage.columns[j])
    else
        res = Dict{UInt64,UInt64}()
    end
    for k in 1:min(storage.transaction_depth, length(storage.updates_stack))
        if haskey(storage.updates_stack[k][2], j)
            merge!(res, storage.updates_stack[k][2][j])
        end
    end
    return res
end

function Base.setindex!(storage::ValueGraphStorage, value::UInt64, i::UInt64, j::UInt64)
    ensure_stack_depth(storage)
    if storage.transaction_depth == 0
        rows = storage.rows
        columns = storage.columns
    else
        rows, columns = storage.updates_stack[storage.transaction_depth]
    end
    if !haskey(rows, i)
        rows[i] = Dict{UInt64,UInt64}()
    end
    rows[i][j] = value
    if !haskey(columns, j)
        columns[j] = Dict{UInt64,UInt64}()
    end
    columns[j][i] = value
    return
end

function Base.setindex!(storage::ValueGraphStorage, value::UInt64, is::Union{Vector{UInt64},Set{UInt64}}, j::UInt64)
    ensure_stack_depth(storage)
    if storage.transaction_depth == 0
        rows = storage.rows
        columns = storage.columns
    else
        rows, columns = storage.updates_stack[storage.transaction_depth]
    end
    if !haskey(columns, j)
        columns[j] = Dict{UInt64,UInt64}()
    end
    for i in is
        if !haskey(rows, i)
            rows[i] = Dict{UInt64,UInt64}()
        end
        rows[i][j] = value
        columns[j][i] = value
    end
    return
end

function Base.setindex!(storage::ValueGraphStorage, values::Vector{UInt64}, is::Vector{UInt64}, j::UInt64)
    if length(values) != length(is)
        throw(ArgumentError("values and indices must have the same length"))
    end
    ensure_stack_depth(storage)
    if storage.transaction_depth == 0
        rows = storage.rows
        columns = storage.columns
    else
        rows, columns = storage.updates_stack[storage.transaction_depth]
    end
    if !haskey(columns, j)
        columns[j] = Dict{UInt64,UInt64}()
    end
    for (i, value) in zip(is, values)
        if !haskey(rows, i)
            rows[i] = Dict{UInt64,UInt64}()
        end
        rows[i][j] = value
        columns[j][i] = value
    end
    return
end

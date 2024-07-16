
mutable struct ConnectionGraphStorage
    transaction_depth::Int
    rows::Dict{UInt64,Set{UInt64}}
    columns::Dict{UInt64,Set{UInt64}}
    updates_stack::Vector{Tuple{Dict{UInt64,Set{UInt64}},Dict{UInt64,Set{UInt64}},Set{Tuple{UInt64,UInt64}}}}
end

ConnectionGraphStorage() = ConnectionGraphStorage(0, Dict{UInt64,Set{UInt64}}(), Dict{UInt64,Set{UInt64}}(), [])

function start_transaction!(storage::ConnectionGraphStorage, depth::Int)
    storage.transaction_depth = depth
    for d in depth:length(storage.updates_stack)
        empty!(storage.updates_stack[d][1])
        empty!(storage.updates_stack[d][2])
        empty!(storage.updates_stack[d][3])
    end
end

function save_changes!(storage::ConnectionGraphStorage, depth)
    for d in (length(storage.updates_stack)-1):-1:(depth)
        new_rows, new_columns, deleted = storage.updates_stack[d+1]
        if isempty(new_rows) && isempty(deleted)
            continue
        end
        if d == 0
            rows = copy(storage.rows)
            columns = copy(storage.columns)
            prev_deleted = Set{Tuple{UInt64,UInt64}}()
        else
            rows = copy(storage.updates_stack[d][1])
            columns = copy(storage.updates_stack[d][2])
            prev_deleted = copy(storage.updates_stack[d][3])
        end
        if !isempty(new_rows)
            merge!(union, rows, new_rows)
            merge!(union, columns, new_columns)

            if !isempty(prev_deleted)
                for (r, c) in prev_deleted
                    if haskey(new_rows, r) && in(c, new_rows[r])
                        delete!(prev_deleted, (r, c))
                    end
                end
            end
        end

        for (r, c) in deleted
            if haskey(rows, r) && in(c, rows[r])
                delete!(rows[r], c)
                delete!(columns[c], r)
            elseif storage.transaction_depth > 1
                push!(prev_deleted, (r, c))
            else
                error("Trying to delete non-existing edge $((r, c))")
            end
        end
        if d == 0
            storage.rows, storage.columns, storage.updates_stack[1] =
                rows, columns, (Dict{UInt64,Set{UInt64}}(), Dict{UInt64,Set{UInt64}}(), Set{Tuple{UInt64,UInt64}}())
        else
            storage.updates_stack[d:d+1] = [
                (rows, columns, prev_deleted),
                (Dict{UInt64,Set{UInt64}}(), Dict{UInt64,Set{UInt64}}(), Set{Tuple{UInt64,UInt64}}()),
            ]
        end
    end
    storage.transaction_depth = depth
end

function drop_changes!(storage::ConnectionGraphStorage, depth)
    for d in (length(storage.updates_stack)):-1:(depth+1)
        storage.updates_stack[d] = (Dict{UInt64,Set{UInt64}}(), Dict{UInt64,Set{UInt64}}(), Set{Tuple{UInt64,UInt64}}())
    end
    storage.transaction_depth = depth
end

function Base.getindex(storage::ConnectionGraphStorage, i::UInt64, j::UInt64)
    for k in min(length(storage.updates_stack), storage.transaction_depth):-1:1
        if haskey(storage.updates_stack[k][1], i) && in(j, storage.updates_stack[k][1][i])
            return true
        end
        if in((i, j), storage.updates_stack[k][3])
            return false
        end
    end
    if haskey(storage.rows, i) && in(j, storage.rows[i])
        return true
    end
    return false
end

function get_connected_from(storage::ConnectionGraphStorage, i::UInt64)
    if haskey(storage.rows, i)
        res = copy(storage.rows[i])
    else
        res = Set{UInt64}()
    end
    for k in 1:min(storage.transaction_depth, length(storage.updates_stack))
        if !isempty(res) && !isempty(storage.updates_stack[k][3])
            for (r, c) in storage.updates_stack[k][3]
                if r == i
                    delete!(res, c)
                end
            end
        end
        if haskey(storage.updates_stack[k][1], i)
            union!(res, storage.updates_stack[k][1][i])
        end
    end
    return res
end

function get_connected_to(storage::ConnectionGraphStorage, j::UInt64)
    if haskey(storage.columns, j)
        res = copy(storage.columns[j])
    else
        res = Set{UInt64}()
    end
    for k in 1:min(storage.transaction_depth, length(storage.updates_stack))
        if !isempty(res) && !isempty(storage.updates_stack[k][3])
            for (r, c) in storage.updates_stack[k][3]
                if c == j
                    delete!(res, r)
                end
            end
        end
        if haskey(storage.updates_stack[k][2], j)
            union!(res, storage.updates_stack[k][2][j])
        end
    end
    return res
end

function Base.setindex!(storage::ConnectionGraphStorage, value::Bool, i::UInt64, j::UInt64)
    if !value
        deleteat!(storage, i, j)
    else
        ensure_stack_depth(storage)
        if storage.transaction_depth == 0
            rows = storage.rows
            columns = storage.columns
        else
            rows, columns, deleted = storage.updates_stack[storage.transaction_depth]
            if in((i, j), deleted)
                delete!(deleted, (i, j))
                return
            end
        end
        if !haskey(rows, i)
            rows[i] = Set{UInt64}()
        end
        push!(rows[i], j)
        if !haskey(columns, j)
            columns[j] = Set{UInt64}()
        end
        push!(columns[j], i)
    end
    return
end

function Base.setindex!(storage::ConnectionGraphStorage, value::Bool, is::Union{Vector{UInt64},Set{UInt64}}, j::UInt64)
    if !value
        deleteat!(storage, is, [j])
    else
        ensure_stack_depth(storage)
        if storage.transaction_depth == 0
            rows = storage.rows
            columns = storage.columns
        else
            rows, columns, deleted = storage.updates_stack[storage.transaction_depth]
            if !isempty(deleted)
                rest = []
                for i in is
                    if in((i, j), deleted)
                        delete!(deleted, (i, j))
                    else
                        push!(rest, i)
                    end
                end
                is = rest
                if isempty(is)
                    return
                end
            end
        end
        for i in is
            if !haskey(rows, i)
                rows[i] = Set{UInt64}()
            end
            push!(rows[i], j)
        end
        if !haskey(columns, j)
            columns[j] = Set{UInt64}()
        end
        union!(columns[j], is)
    end
    return
end

function Base.setindex!(storage::ConnectionGraphStorage, value::Bool, i::UInt64, js::Union{Vector{UInt64},Set{UInt64}})
    if !value
        deleteat!(storage, [i], js)
    else
        ensure_stack_depth(storage)
        if storage.transaction_depth == 0
            rows = storage.rows
            columns = storage.columns
        else
            rows, columns, deleted = storage.updates_stack[storage.transaction_depth]
            if !isempty(deleted)
                rest = []
                for j in js
                    if in((i, j), deleted)
                        delete!(deleted, (i, j))
                    else
                        push!(rest, j)
                    end
                end
                js = rest
                if isempty(js)
                    return
                end
            end
        end
        for j in js
            if !haskey(columns, j)
                columns[j] = Set{UInt64}()
            end
            push!(columns[j], i)
        end
        if !haskey(rows, i)
            rows[i] = Set{UInt64}()
        end
        union!(rows[i], js)
    end
    return
end

function Base.setindex!(
    storage::ConnectionGraphStorage,
    value::Bool,
    is::Union{Vector{UInt64},Set{UInt64}},
    js::Union{Vector{UInt64},Set{UInt64}},
)
    if !value
        deleteat!(storage, is, js)
    else
        ensure_stack_depth(storage)
        if storage.transaction_depth == 0
            rows = storage.rows
            columns = storage.columns
            inserts = Dict(j => is for j in js)
        else
            rows, columns, deleted = storage.updates_stack[storage.transaction_depth]
            if !isempty(deleted)
                rest = Dict()
                for j in js
                    rest_i = []
                    for i in is
                        if in((i, j), deleted)
                            delete!(deleted, (i, j))
                        else
                            push!(rest_i, i)
                        end
                    end
                    if !isempty(rest_i)
                        rest[j] = rest_i
                    end
                end
                inserts = rest
                if isempty(inserts)
                    return
                end
            else
                inserts = Dict(j => is for j in js)
            end
        end
        for (j, rest_i) in inserts
            if !haskey(columns, j)
                columns[j] = Set{UInt64}()
            end
            union!(columns[j], rest_i)
            for i in rest_i
                if !haskey(rows, i)
                    rows[i] = Set{UInt64}()
                end
                push!(rows[i], j)
            end
        end
    end
    return
end

function ensure_stack_depth(storage::ConnectionGraphStorage)
    while storage.transaction_depth > length(storage.updates_stack)
        push!(
            storage.updates_stack,
            (Dict{UInt64,Set{UInt64}}(), Dict{UInt64,Set{UInt64}}(), Set{Tuple{UInt64,UInt64}}()),
        )
    end
end

function Base.deleteat!(storage::ConnectionGraphStorage, i::UInt64, j::UInt64)
    ensure_stack_depth(storage)
    if storage.transaction_depth == 0
        delete!(storage.rows[i], j)
        if isempty(storage.rows[i])
            delete!(storage.rows, i)
        end
        delete!(storage.columns[j], i)
        if isempty(storage.columns[j])
            delete!(storage.columns, j)
        end
    else
        rows, columns, deleted = storage.updates_stack[storage.transaction_depth]
        if haskey(rows, i) && in(j, rows[i])
            delete!(rows[i], j)
            if isempty(rows[i])
                delete!(rows, i)
            end
            delete!(columns[j], i)
            if isempty(columns[j])
                delete!(columns, j)
            end
        else
            push!(deleted, (i, j))
        end
    end
    storage
end

function Base.deleteat!(
    storage::ConnectionGraphStorage,
    is::Union{Vector{UInt64},Set{UInt64}},
    js::Union{Vector{UInt64},Set{UInt64}},
)
    ensure_stack_depth(storage)
    if storage.transaction_depth == 0
        rows = storage.rows
        columns = storage.columns
    else
        rows, columns, deleted = storage.updates_stack[storage.transaction_depth]
    end
    for i in is
        if haskey(rows, i)
            to_del = setdiff(js, rows[i])
            setdiff!(rows[i], js)
            if isempty(rows[i])
                delete!(rows, i)
            end
        else
            to_del = js
        end
        if storage.transaction_depth > 0
            for c in to_del
                push!(deleted, (i, c))
            end
        end
    end
    for j in js
        if haskey(columns, j)
            setdiff!(columns[j], is)
            if isempty(columns[j])
                delete!(columns, j)
            end
        end
    end
    storage
end

function Base.deleteat!(storage::ConnectionGraphStorage, i::UInt64, j::Colon)
    js = get_connected_from(storage, i)
    deleteat!(storage, [i], js)
end

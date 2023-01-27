
using SuiteSparseGraphBLAS

const MAX_GRAPH_SIZE = 100_000

mutable struct GraphStorage{F}
    transaction_depth::Int
    edges::GBMatrix{UInt64,F}
    updates_stack::Vector{Tuple{GBMatrix{UInt64,Nothing},GBMatrix{Int,Int}}}
end

GraphStorage() = GraphStorage{Nothing}(0, GBMatrix{UInt64}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE), [])

GraphStorage(v::F) where {F} = GraphStorage{F}(0, GBMatrix{UInt64}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE, fill = v), [])

function start_transaction!(storage::GraphStorage)
    storage.transaction_depth += 1
end

function save_changes!(storage::GraphStorage)
    if storage.transaction_depth <= length(storage.updates_stack)
        new_edges, deleted = storage.updates_stack[storage.transaction_depth]
        if storage.transaction_depth == 1
            edges = storage.edges
        else
            edges = storage.updates_stack[storage.transaction_depth-1][1]
        end
        if nnz(new_edges) > 0
            subassign!(edges, new_edges, :, :; desc = Descriptor(structural_mask = true), mask = new_edges)
            if storage.transaction_depth > 1
                prev_deleted = storage.updates_stack[storage.transaction_depth-1][2]
                if !isempty(prev_deleted)
                    apply!(
                        identity,
                        prev_deleted,
                        prev_deleted;
                        mask = new_edges,
                        desc = Descriptor(complement_mask = true, replace_output = true),
                    )
                end
            end
        end
        if !isempty(deleted)
            apply!(
                identity,
                edges,
                edges;
                mask = deleted,
                desc = Descriptor(complement_mask = true, replace_output = true),
            )
        end
    end
    drop_changes!(storage)
end

function drop_changes!(storage::GraphStorage)
    if storage.transaction_depth <= length(storage.updates_stack)
        empty!(storage.updates_stack[storage.transaction_depth][1])
        empty!(storage.updates_stack[storage.transaction_depth][2])
    end
    storage.transaction_depth -= 1
end

function Base.getindex(storage::GraphStorage, i::UInt64, j::UInt64)
    for k in min(length(storage.updates_stack), storage.transaction_depth):-1:1
        new_val = storage.updates_stack[k][1][i, j]
        if isnothing(new_val) && storage.updates_stack[k][2][i, j] != 1
            continue
        end
        return new_val
    end
    return storage.edges[i, j]
end

function Base.getindex(storage::GraphStorage, inds...)
    vals = storage.edges[inds...]

    for i in 1:min(length(storage.updates_stack), storage.transaction_depth)
        if nnz(vals) == 0
            vals = storage.updates_stack[i][1][inds...]
        else
            new_vals = storage.updates_stack[i][1][inds...]
            if nnz(new_vals) > 0
                subassign!(vals, new_vals, :, :; desc = Descriptor(structural_mask = true), mask = new_vals)
            end
            deleted_mask = storage.updates_stack[i][2][inds...]
            if nnz(deleted_mask) > 0
                apply!(
                    identity,
                    vals,
                    vals;
                    mask = deleted_mask,
                    desc = Descriptor(complement_mask = true, replace_output = true),
                )
            end
        end
    end
    return vals
end

function Base.setindex!(storage::GraphStorage, value, inds...)
    subassign!(storage, value, inds...)
end

function ensure_stack_depth(storage::GraphStorage, depth::Int)
    while storage.transaction_depth > length(storage.updates_stack)
        push!(
            storage.updates_stack,
            (GBMatrix{UInt64}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE), GBMatrix{Int}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE, fill = 0)),
        )
    end
end

function Base.deleteat!(storage::GraphStorage, i, j)
    ensure_stack_depth(storage, storage.transaction_depth)
    if storage.transaction_depth == 0
        deleteat!(storage.edges, i, j)
    else
        edges, deleted = storage.updates_stack[storage.transaction_depth]
        deleted[i, j] = 1
        apply!(identity, edges, edges; mask = deleted, desc = Descriptor(complement_mask = true, replace_output = true))
    end
    storage
end

function SuiteSparseGraphBLAS.subassign!(
    storage::GraphStorage,
    values,
    i,
    j;
    mask = nothing,
    accum = nothing,
    desc = nothing,
)
    ensure_stack_depth(storage, storage.transaction_depth)
    if storage.transaction_depth == 0
        subassign!(storage.edges, values, i, j; mask, accum, desc)
    else
        edges, deleted = storage.updates_stack[storage.transaction_depth]
        subassign!(edges, values, i, j; mask, accum, desc)
        subassign!(deleted, 0, i, j; mask, accum, desc)
    end
end

function SuiteSparseGraphBLAS.subassign!(
    storage::GraphStorage,
    values::GBVector,
    i,
    j::Colon;
    mask = nothing,
    accum = nothing,
    desc = nothing,
)
    if !isnothing(mask)
        mask = mask'
    end
    ensure_stack_depth(storage, storage.transaction_depth)
    if storage.transaction_depth == 0
        subassign!(storage.edges, values', i, j; mask, accum, desc)
    else
        edges, deleted = storage.updates_stack[storage.transaction_depth]
        subassign!(edges, values', i, j; mask, accum, desc)
        subassign!(deleted, 0, i, j; mask, accum, desc)
    end
end

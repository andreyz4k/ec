
using SuiteSparseGraphBLAS

const MAX_GRAPH_SIZE = 100_000

struct GraphStorage
    edges::GBMatrix{Int}
    new_edges::GBMatrix{Int}
    deleted::GBMatrix{Int}
end

GraphStorage() = GraphStorage(
    GBMatrix{Int}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE),
    GBMatrix{Int}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE),
    GBMatrix{Int}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE, fill = 0),
)

GraphStorage(v) = GraphStorage(
    GBMatrix{Int}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE, fill = v),
    GBMatrix{Int}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE),
    GBMatrix{Int}(MAX_GRAPH_SIZE, MAX_GRAPH_SIZE, fill = 0),
)

function save_changes!(storage::GraphStorage)
    if nnz(storage.new_edges) > 0
        subassign!(
            storage.edges,
            storage.new_edges,
            :,
            :;
            desc = Descriptor(structural_mask = true),
            mask = storage.new_edges,
        )
    end
    if !isempty(storage.deleted)
        apply!(
            identity,
            storage.edges,
            storage.edges;
            mask = storage.deleted,
            desc = Descriptor(complement_mask = true, replace_output = true),
        )
    end
    drop_changes!(storage)
end

function drop_changes!(storage::GraphStorage)
    empty!(storage.new_edges)
    empty!(storage.deleted)
end

function Base.getindex(storage::GraphStorage, i::Integer, j::Integer)
    new_val = storage.new_edges[i, j]
    if isnothing(new_val) && storage.deleted[i, j] != 1
        return storage.edges[i, j]
    end
    return new_val
end

function Base.getindex(storage::GraphStorage, inds...)
    base_vals = storage.edges[inds...]
    new_vals = storage.new_edges[inds...]
    if nnz(base_vals) == 0
        return new_vals
    end
    if nnz(new_vals) > 0
        subassign!(base_vals, new_vals, :, :; desc = Descriptor(structural_mask = true), mask = new_vals)
    end
    deleted_mask = storage.deleted[inds...]
    if nnz(deleted_mask) > 0
        apply!(
            identity,
            base_vals,
            base_vals;
            mask = deleted_mask,
            desc = Descriptor(complement_mask = true, replace_output = true),
        )
    end
    return base_vals
end

function Base.setindex!(storage::GraphStorage, value, inds...)
    subassign!(storage, value, inds...)
end

function Base.deleteat!(storage::GraphStorage, i, j)
    storage.deleted[i, j] = 1
    apply!(
        identity,
        storage.new_edges,
        storage.new_edges;
        mask = storage.deleted,
        desc = Descriptor(complement_mask = true, replace_output = true),
    )
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
    subassign!(storage.new_edges, values, i, j; mask, accum, desc)
    subassign!(storage.deleted, 0, i, j; mask, accum, desc)
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
    subassign!(storage.new_edges, values', i, j; mask, accum, desc)
    subassign!(storage.deleted, 0, i, j; mask, accum, desc)
end

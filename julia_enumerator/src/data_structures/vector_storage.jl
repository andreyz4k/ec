
struct VectorStorage{T}
    values::GBMatrix{T}
    new_values::GBMatrix{T}
end

VectorStorage{T}() where {T} = VectorStorage{T}(GBMatrix{T}(MAX_GRAPH_SIZE, 1), GBMatrix{T}(MAX_GRAPH_SIZE, 1))
VectorStorage{T}(v) where {T} =
    VectorStorage{T}(GBMatrix{T}(MAX_GRAPH_SIZE, 1, fill = v), GBMatrix{T}(MAX_GRAPH_SIZE, 1))

function save_changes!(storage::VectorStorage)
    if nnz(storage.new_values) > 0
        subassign!(
            storage.values,
            storage.new_values,
            :,
            :;
            desc = Descriptor(structural_mask = true),
            mask = storage.new_values,
        )
        drop_changes!(storage)
    end
end

function drop_changes!(storage::VectorStorage{T}) where {T}
    empty!(storage.new_values)
end

function Base.setindex!(storage::VectorStorage, value, ind::Integer)
    storage.new_values[ind, 1] = value
end

function Base.getindex(storage::VectorStorage, ind::Integer)
    v = storage.new_values[ind, 1]
    if isnothing(v)
        v = storage.values[ind, 1]
    end
    return v
end

function Base.getindex(storage::VectorStorage, inds)
    base_vals = storage.values[inds, 1]
    new_vals = storage.new_values[inds, 1]
    if nnz(base_vals) == 0
        return new_vals
    end
    if nnz(new_vals) > 0
        subassign!(base_vals, new_vals, :, :; desc = Descriptor(structural_mask = true), mask = new_vals)
    end
    return base_vals
end

function get_new_values(storage::VectorStorage)::Vector{Int}
    return Vector{Int}(nonzeroinds(storage.new_values)[1])
end

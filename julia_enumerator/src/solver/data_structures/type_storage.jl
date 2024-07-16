
struct TypeStorage
    types::IndexedStorage{Tp}
    unifiable_types::ConnectionGraphStorage
end

TypeStorage() = TypeStorage(IndexedStorage{Tp}(), ConnectionGraphStorage())

function start_transaction!(storage::TypeStorage, depth)
    start_transaction!(storage.types, depth)
    start_transaction!(storage.unifiable_types, depth)
end

function save_changes!(storage::TypeStorage, depth)
    save_changes!(storage.types, depth)
    save_changes!(storage.unifiable_types, depth)
end

function drop_changes!(storage::TypeStorage, depth)
    drop_changes!(storage.types, depth)
    drop_changes!(storage.unifiable_types, depth)
end

function Base.push!(storage::TypeStorage, type::Tp)::UInt64
    l = length(storage.types)
    new_id = push!(storage.types, type)
    if new_id <= l
        return new_id
    end
    context, type = instantiate(type, empty_context)
    for t_id::UInt64 in 1:l
        t = storage.types[t_id]
        if might_unify(t, type)
            new_context, upd_t = instantiate(t, context)
            new_context = unify(new_context, upd_t, type)
            if isnothing(new_context)
                continue
            end
            if is_subtype(upd_t, type)
                storage.unifiable_types[new_id, t_id] = true
            end
            if is_subtype(type, upd_t)
                storage.unifiable_types[t_id, new_id] = true
            end
        end
    end
    storage.unifiable_types[new_id, new_id] = true
    return new_id
end

function Base.getindex(storage::TypeStorage, id::UInt64)
    return storage.types[id]
end

function get_sub_types(storage::TypeStorage, type_id::UInt64)
    return get_connected_to(storage.unifiable_types, type_id)
end

function get_super_types(storage::TypeStorage, type_id::UInt64)
    return get_connected_from(storage.unifiable_types, type_id)
end

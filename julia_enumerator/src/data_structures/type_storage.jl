
struct TypeStorage
    types::IndexedStorage{Tp}
    unifiable_types::GraphStorage
end

TypeStorage() = TypeStorage(IndexedStorage{Tp}(), GraphStorage())

function start_transaction!(storage::TypeStorage)
    start_transaction!(storage.types)
    start_transaction!(storage.unifiable_types)
end

function save_changes!(storage::TypeStorage)
    save_changes!(storage.types)
    save_changes!(storage.unifiable_types)
end

function drop_changes!(storage::TypeStorage)
    drop_changes!(storage.types)
    drop_changes!(storage.unifiable_types)
end

function Base.push!(storage::TypeStorage, type::Tp)::Int
    l = length(storage.types)
    new_id = push!(storage.types, type)
    if new_id <= l
        return new_id
    end
    for t_id in 1:l
        t = storage.types[t_id]
        if might_unify(t, type)
            storage.unifiable_types[t_id, new_id] = 1
            if !is_polymorphic(type)
                storage.unifiable_types[new_id, t_id] = 1
            end
        end
    end
    storage.unifiable_types[new_id, new_id] = 1
    return new_id
end

function Base.getindex(storage::TypeStorage, id::Integer)
    return storage.types[id]
end

function get_sub_types(storage::TypeStorage, type_id::Integer)
    return nonzeroinds(storage.unifiable_types[:, type_id])
end

function get_super_types(storage::TypeStorage, type_id::Integer)
    return nonzeroinds(storage.unifiable_types[type_id, :])
end

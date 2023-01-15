
using DataStructures

struct Path
    main_path::OrderedDict{Int,Int}
    side_vars::Dict{Int,Int}
    cost::Float64
end

Base.:(==)(path1::Path, path2::Path) = path1.main_path == path2.main_path && path1.side_vars == path2.side_vars
Base.hash(path::Path, h::UInt) = hash(path.main_path, hash(path.side_vars, h))

Base.isless(path1::Path, path2::Path) = path1.cost < path2.cost

empty_path() = Path(OrderedDict{Int,Int}(), Dict{Int,Int}(), 0.0)

function paths_compatible(path1::Path, path2::Path)
    for (v, b) in path2.main_path
        if (haskey(path1.main_path, v) && path1.main_path[v] != b) ||
           (haskey(path1.side_vars, v) && path1.side_vars[v] != b)
            return false
        end
    end
    for (v, b) in path2.side_vars
        if (haskey(path1.main_path, v) && path1.main_path[v] != b) ||
           (haskey(path1.side_vars, v) && path1.side_vars[v] != b)
            return false
        end
    end
    return true
end

function merge_paths(sc, path1::Path, path2::Path)
    if !paths_compatible(path1, path2)
        return nothing
    end
    new_main_path = merge(path1.main_path, path2.main_path)
    new_side_vars = filter(p -> !haskey(new_main_path, p.first), merge(path1.side_vars, path2.side_vars))
    new_cost = sum(sc.blocks[b_id].cost for b_id in unique(values(new_main_path)); init = 0.0)
    return Path(new_main_path, new_side_vars, new_cost)
end

function merge_path(sc, path::Path, var_id, block_id, side_vars)
    new_main_path = merge(path.main_path, Dict(var_id => block_id))
    new_side_vars = merge(path.side_vars, Dict(v => block_id for v in side_vars))
    new_cost = path.cost + sc.blocks[block_id].cost
    return Path(new_main_path, new_side_vars, new_cost)
end

path_cost(sc, path::Path) = sum(sc.blocks[b_id].cost for b_id in unique(values(path.main_path)); init = 0.0)

path_sets_var(path::Path, var_id) = haskey(path.main_path, var_id)

function have_valid_paths(sc, branches)
    checked_branches = [branches[1]]
    for br in view(branches, 2:length(branches))
        for checked_br in checked_branches
            if !any(paths_compatible(p1, p2) for p1 in sc.incoming_paths[br] for p2 in sc.incoming_paths[checked_br])
                return false
            end
        end
        push!(checked_branches, br)
    end
    return true
end

extract_block_sequence(path::Path) = unique(collect(values(path.main_path)))

STORE_MAX_PATHS = 10
using DataStructures

mutable struct PathsStorage
    transaction_depth::Int
    values::Vector{AbstractDict{Int,SortedSet{Path,Base.ReverseOrdering}}}
end

PathsStorage() = PathsStorage(
    0,
    [
        DefaultDict{Int,SortedSet{Path,Base.ReverseOrdering}}(
            () -> SortedSet{Path,Base.ReverseOrdering}(Base.ReverseOrdering()),
        ),
    ],
)

function start_transaction!(storage::PathsStorage)
    storage.transaction_depth += 1
end

function save_changes!(storage::PathsStorage)
    if storage.transaction_depth + 1 <= length(storage.values)
        new_values = storage.values[storage.transaction_depth+1]
        last_values = storage.values[storage.transaction_depth]
        for (k, v) in new_values
            if haskey(last_values, k)
                union!(last_values[k], v)
            else
                last_values[k] = v
            end
            while length(last_values[k]) > STORE_MAX_PATHS
                pop!(last_values[k])
            end
        end
    end
    drop_changes!(storage)
end

function drop_changes!(storage::PathsStorage)
    if storage.transaction_depth + 1 <= length(storage.values)
        empty!(storage.values[storage.transaction_depth+1])
    end
    storage.transaction_depth -= 1
end

function Base.getindex(storage::PathsStorage, ind::Integer)
    result = nothing
    for i in 1:min(storage.transaction_depth + 1, length(storage.values))
        vals = storage.values[i]
        if haskey(vals, ind)
            if result === nothing
                result = vals[ind]
            else
                result = union(result, vals[ind])
            end
        end
    end
    if result === nothing
        result = SortedSet{Path,Base.ReverseOrdering}(Base.ReverseOrdering())
    end
    return result
end

function Base.haskey(storage::PathsStorage, key::Integer)
    return any(haskey(storage.values[i], key) for i in 1:min(storage.transaction_depth + 1, length(storage.values)))
end

function Base.setindex!(storage::PathsStorage, value, ind::Integer)
    while storage.transaction_depth + 1 > length(storage.values)
        push!(
            storage.values,
            DefaultDict{Int,SortedSet{Path,Base.ReverseOrdering}}(
                () -> SortedSet{Path,Base.ReverseOrdering}(Base.ReverseOrdering()),
            ),
        )
    end
    storage.values[storage.transaction_depth+1][ind] = value
end

function add_path!(storage::PathsStorage, branch_id, path)
    while storage.transaction_depth + 1 > length(storage.values)
        push!(
            storage.values,
            DefaultDict{Int,SortedSet{Path,Base.ReverseOrdering}}(
                () -> SortedSet{Path,Base.ReverseOrdering}(Base.ReverseOrdering()),
            ),
        )
    end
    push!(storage.values[storage.transaction_depth+1][branch_id], path)
end

function get_new_paths(storage::PathsStorage, branch_id)
    result = nothing
    for i in 2:min(storage.transaction_depth + 1, length(storage.values))
        vals = storage.values[i]
        if haskey(vals, branch_id)
            if result === nothing
                result = vals[branch_id]
            else
                result = union(result, vals[branch_id])
            end
        end
    end
    if result === nothing
        result = SortedSet{Path,Base.ReverseOrdering}(Base.ReverseOrdering())
    end
    return result
end

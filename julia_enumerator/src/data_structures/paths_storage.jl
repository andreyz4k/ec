
using DataStructures

struct Path
    main_path::OrderedDict{Int,Int}
    side_vars::Dict{Int,Int}
end

Base.:(==)(path1::Path, path2::Path) = path1.main_path == path2.main_path && path1.side_vars == path2.side_vars

empty_path() = Path(OrderedDict{Int,Int}(), Dict{Int,Int}())

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

function Base.merge(path1::Path, path2::Path)
    if !paths_compatible(path1, path2)
        return nothing
    end
    new_main_path = merge(path1.main_path, path2.main_path)
    new_side_vars = filter(p -> !haskey(new_main_path, p.first), merge(path1.side_vars, path2.side_vars))
    return Path(new_main_path, new_side_vars)
end

function merge_path(path::Path, var_id, block_id, side_vars)
    new_main_path = merge(path.main_path, Dict(var_id => block_id))
    new_side_vars = merge(path.side_vars, Dict(v => block_id for v in side_vars))
    return Path(new_main_path, new_side_vars)
end

path_cost(sc, path::Path) = sum(sc.blocks[b_id].cost for b_id in unique(values(path.main_path)); init = 0.0)

path_sets_var(path::Path, var_id) = haskey(path.main_path, var_id)

function have_valid_paths(sc, branch_ids)
    prev_branches = Dict()
    for br_id in branch_ids
        prev_branches[br_id] = DefaultDict(() -> Set())
        prev_branch_ids = nonzeroinds(sc.previous_branches[br_id, :])
        for prev_br_id in prev_branch_ids
            prev_var_id = sc.branch_vars[prev_br_id]
            push!(prev_branches[br_id][prev_var_id], prev_br_id)
        end
        for rel_br_id in unique(nonzeroinds(sc.related_explained_complexity_branches[prev_branch_ids, :])[2])
            rel_var_id = sc.branch_vars[rel_br_id]
            push!(prev_branches[br_id][rel_var_id], rel_br_id)
        end
    end
    @info "Checking paths compatibility"
    @info prev_branches
    prev_vars_count = counter(Int)
    for (br_id, vars) in prev_branches
        for var_id in keys(vars)
            inc!(prev_vars_count, var_id)
        end
    end
    @info prev_vars_count
    for (var_id, count) in prev_vars_count
        if count > 1
            possible_branches = nothing
            for br_id in branch_ids
                if haskey(prev_branches[br_id], var_id)
                    if isnothing(possible_branches)
                        possible_branches = prev_branches[br_id][var_id]
                    else
                        possible_branches = intersect(possible_branches, prev_branches[br_id][var_id])
                        if isempty(possible_branches)
                            return false
                        end
                    end
                end
            end
        end
    end

    return true
end

extract_block_sequence(path::Path) = unique(collect(values(path.main_path)))

struct PathsStorage
    values::AbstractDict{Int,Vector{Path}}
    new_values::AbstractDict{Int,Vector{Path}}
end

PathsStorage() = PathsStorage(DefaultDict{Int,Vector{Path}}(() -> []), DefaultDict{Int,Vector{Path}}(() -> []))

function save_changes!(storage::PathsStorage)
    for (k, v) in storage.new_values
        if haskey(storage.values, k)
            append!(storage.values[k], v)
        else
            storage.values[k] = v
        end
    end
    drop_changes!(storage)
end

function drop_changes!(storage::PathsStorage)
    empty!(storage.new_values)
end

function Base.getindex(storage::PathsStorage, ind::Integer)
    if !haskey(storage.new_values, ind)
        return storage.values[ind]
    end
    if !haskey(storage.values, ind)
        return storage.new_values[ind]
    end
    return vcat(storage.values[ind], storage.new_values[ind])
end

function Base.haskey(storage::PathsStorage, key::Integer)
    return haskey(storage.values, key) || haskey(storage.new_values, key)
end

function Base.setindex!(storage::PathsStorage, value, ind::Integer)
    storage.new_values[ind] = value
end

function add_path!(storage::PathsStorage, branch_id, path)
    push!(storage.new_values[branch_id], path)
end

function get_new_paths(storage::PathsStorage, branch_id)
    return storage.new_values[branch_id]
end

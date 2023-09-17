
function get_all_parents(sc, branch_id)
    parents = get_connected_to(sc.branch_children, branch_id)
    for parent_id in parents
        parents = union(parents, get_all_parents(sc, parent_id))
    end
    return parents
end

# function is_branch_compatible(key, branch, fixed_branches)
#     for fixed_branch in fixed_branches
#         if haskey(fixed_branch.values, key)
#             return fixed_branch == branch
#         end
#     end
#     return true
# end

function value_updates(
    sc,
    block::ProgramBlock,
    block_id,
    target_output::Dict{UInt64,UInt64},
    new_values,
    fixed_branches::Dict{UInt64,UInt64},
    is_new_block,
    created_paths,
)
    branch_id = target_output[block.output_var]
    entry = sc.entries[sc.branch_entries[branch_id]]
    t_id = push!(sc.types, return_of_type(block.type))
    out_branch_id, is_new_next_block, allow_fails, next_blocks, set_explained, bl_created_paths = updated_branches(
        sc,
        entry,
        new_values,
        block_id,
        is_new_block,
        block.output_var,
        branch_id,
        t_id,
        !isa(block.p, FreeVar),
        fixed_branches,
        created_paths,
    )

    out_branches = Dict{UInt64,UInt64}(block.output_var => out_branch_id)
    block_created_paths = Dict{UInt64,Vector{Any}}(out_branch_id => bl_created_paths)
    if set_explained && !sc.branch_known_from_input[out_branch_id]
        sc.branch_known_from_input[out_branch_id] =
            any(sc.branch_known_from_input[fixed_branches[in_var]] for in_var in block.input_vars)
    end
    return out_branches, is_new_next_block, allow_fails, next_blocks, set_explained, block_created_paths
end

function value_updates(
    sc,
    block::Union{ReverseProgramBlock,WrapEitherBlock},
    block_id,
    target_output::Dict{UInt64,UInt64},
    new_values,
    fixed_branches::Dict{UInt64,UInt64},
    is_new_block,
    created_paths,
)
    out_branches = Dict{UInt64,UInt64}()
    is_new_next_block = false
    allow_fails = false
    set_explained = false
    next_blocks = Set()
    block_created_paths = Dict{UInt64,Vector{Any}}()
    for i in 1:length(block.output_vars)
        out_var = block.output_vars[i]
        values = new_values[i]
        br_id = target_output[out_var]
        entry = sc.entries[sc.branch_entries[br_id]]
        out_branch_id, is_new_nxt_block, all_fails, n_blocks, set_expl, bl_created_paths = updated_branches(
            sc,
            entry,
            values,
            block_id,
            is_new_block,
            out_var,
            br_id,
            entry.type_id,
            true,
            fixed_branches,
            created_paths,
        )
        is_new_next_block |= is_new_nxt_block
        out_branches[out_var] = out_branch_id
        allow_fails |= all_fails
        set_explained |= set_expl
        union!(next_blocks, n_blocks)
        block_created_paths[out_branch_id] = bl_created_paths
    end
    if set_explained
        known_from_input = any(sc.branch_known_from_input[fixed_branches[in_var]] for in_var in block.input_vars)
        for (_, branch_id) in out_branches
            if length(out_branches) > 1
                inds = [b_id for (_, b_id) in out_branches if b_id != branch_id]
                sc.related_explained_complexity_branches[branch_id, inds] = true
            end
            if !sc.branch_known_from_input[branch_id]
                sc.branch_known_from_input[branch_id] = known_from_input
            end
        end
    end
    return out_branches, is_new_next_block, allow_fails, next_blocks, set_explained, block_created_paths
end

function updated_branches(
    sc,
    entry::ValueEntry,
    @nospecialize(new_values),
    block_id,
    is_new_block,
    var_id::UInt64,
    branch_id::UInt64,
    t_id::UInt64,
    is_meaningful::Bool,
    fixed_branches::Dict{UInt64,UInt64},
    created_paths,
)::Tuple{UInt64,Bool,Bool,Set{Any},Bool,Vector{Any}}
    if is_meaningful && sc.branch_is_not_copy[branch_id] != true
        sc.branch_is_not_copy[branch_id] = true
    end
    set_explained = false
    if !sc.branch_is_explained[branch_id]
        sc.branch_is_explained[branch_id] = true
        sc.unused_explained_complexities[branch_id] = entry.complexity
        set_explained = true
    end
    block_created_paths =
        get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, branch_id, fixed_branches)
    if isempty(block_created_paths)
        allow_fails = false
        next_blocks = Set()
    else
        allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, branch_id, fixed_branches)
    end
    return branch_id, false, allow_fails, next_blocks, set_explained, block_created_paths
end

function find_related_branches(sc, branch_id, new_entry, new_entry_index)::Tuple{Vector{UInt64},Union{UInt64,Nothing}}
    possible_parents = UInt64[]
    for child_id in get_connected_from(sc.branch_children, branch_id)
        if sc.branch_entries[child_id] == new_entry_index
            return UInt64[], child_id
        else
            child_entry = sc.entries[sc.branch_entries[child_id]]
            if match_with_entry(sc, child_entry, new_entry)
                parents, possible_result = find_related_branches(sc, child_id, new_entry, new_entry_index)
                if !isnothing(possible_result)
                    return UInt64[], possible_result
                else
                    append!(possible_parents, parents)
                end
            end
        end
    end
    if isempty(possible_parents)
        return UInt64[branch_id], nothing
    else
        return possible_parents, nothing
    end
end

function updated_branches(
    sc,
    entry::NoDataEntry,
    @nospecialize(new_values),
    block_id,
    is_new_block,
    var_id::UInt64,
    branch_id::UInt64,
    t_id::UInt64,
    is_meaningful::Bool,
    fixed_branches::Dict{UInt64,UInt64},
    created_paths,
)::Tuple{UInt64,Bool,Bool,Set{Any},Bool,Vector{Any}}
    complexity_summary = get_complexity_summary(new_values, sc.types[t_id])
    if any(isa(value, PatternWrapper) for value in new_values)
        new_entry = PatternEntry(t_id, new_values, complexity_summary, get_complexity(sc, complexity_summary))
    else
        new_entry = ValueEntry(t_id, new_values, complexity_summary, get_complexity(sc, complexity_summary))
    end
    new_entry_index = push!(sc.entries, new_entry)
    new_parents, possible_result = find_related_branches(sc, branch_id, new_entry, new_entry_index)
    parent_constraints = keys(get_connected_from(sc.constrained_branches, branch_id))
    if !isnothing(possible_result)
        set_explained = false
        if !sc.branch_is_explained[possible_result]
            sc.branch_is_explained[possible_result] = true
            set_explained = true
        end
        block_created_paths =
            get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, possible_result, fixed_branches)
        if isempty(block_created_paths)
            allow_fails = false
            next_blocks = Set()
        else
            allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, possible_result, fixed_branches)
        end
        return possible_result, false, allow_fails, next_blocks, set_explained, block_created_paths
    end

    new_branch_id = increment!(sc.branches_count)
    sc.branch_entries[new_branch_id] = new_entry_index
    sc.branch_vars[new_branch_id] = var_id
    sc.branch_types[new_branch_id, t_id] = true
    sc.branch_is_explained[new_branch_id] = true
    if is_meaningful
        sc.branch_is_not_copy[new_branch_id] = true
    end

    sc.branch_children[new_parents, new_branch_id] = true
    sc.complexities[new_branch_id] = new_entry.complexity
    sc.unused_explained_complexities[new_branch_id] = new_entry.complexity

    block_created_paths =
        get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, new_branch_id, fixed_branches)
    if !isempty(parent_constraints)
        for constraint_id in parent_constraints
            tighten_constraint(sc, constraint_id, new_branch_id, branch_id)
        end
        if isempty(block_created_paths)
            allow_fails = false
            next_blocks = Set()
        else
            allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, new_branch_id, fixed_branches)
        end
    else
        allow_fails, next_blocks = _downstream_blocks_new_branch(sc, var_id, branch_id, new_branch_id, fixed_branches)
    end
    return new_branch_id, true, allow_fails, next_blocks, true, block_created_paths
end

function updated_branches(
    sc,
    entry::EitherEntry,
    @nospecialize(new_values),
    block_id,
    is_new_block,
    var_id::UInt64,
    branch_id::UInt64,
    t_id::UInt64,
    is_meaningful::Bool,
    fixed_branches::Dict{UInt64,UInt64},
    created_paths,
)::Tuple{UInt64,Bool,Bool,Set{Any},Bool,Vector{Any}}
    complexity_summary = get_complexity_summary(new_values, sc.types[t_id])
    if any(isa(value, PatternWrapper) for value in new_values)
        new_entry = PatternEntry(t_id, new_values, complexity_summary, get_complexity(sc, complexity_summary))
    else
        new_entry = ValueEntry(t_id, new_values, complexity_summary, get_complexity(sc, complexity_summary))
    end
    new_entry_index = push!(sc.entries, new_entry)
    new_parents, possible_result = find_related_branches(sc, branch_id, new_entry, new_entry_index)
    parent_constraints = keys(get_connected_from(sc.constrained_branches, branch_id))
    if !isnothing(possible_result)
        set_explained = false
        if !sc.branch_is_explained[possible_result]
            sc.branch_is_explained[possible_result] = true
            set_explained = true
        end
        if is_meaningful && sc.branch_is_not_copy[possible_result] != true
            sc.branch_is_not_copy[possible_result] = true
        end
        block_created_paths =
            get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, possible_result, fixed_branches)
        if isempty(block_created_paths)
            allow_fails = false
            next_blocks = Set()
        else
            allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, possible_result, fixed_branches)
        end
        return possible_result, false, allow_fails, next_blocks, set_explained, block_created_paths
    end

    new_branch_id = increment!(sc.branches_count)
    sc.branch_entries[new_branch_id] = new_entry_index
    sc.branch_vars[new_branch_id] = var_id
    sc.branch_types[new_branch_id, t_id] = true
    sc.branch_is_explained[new_branch_id] = true
    if is_meaningful
        sc.branch_is_not_copy[new_branch_id] = true
    end

    sc.branch_children[new_parents, new_branch_id] = true
    sc.complexities[new_branch_id] = new_entry.complexity
    sc.unused_explained_complexities[new_branch_id] = new_entry.complexity
    sc.unmatched_complexities[new_branch_id] = new_entry.complexity

    if isempty(parent_constraints)
        error("Either branch doesn't have constraints")
    end
    for constraint_id in parent_constraints
        tighten_constraint(sc, constraint_id, new_branch_id, branch_id)
    end
    block_created_paths =
        get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, new_branch_id, fixed_branches)
    if isempty(block_created_paths)
        allow_fails = false
        next_blocks = Set()
    else
        allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, new_branch_id, fixed_branches)
    end
    return new_branch_id, false, allow_fails, next_blocks, true, block_created_paths
end

function updated_branches(
    sc,
    entry::PatternEntry,
    @nospecialize(new_values),
    block_id,
    is_new_block,
    var_id::UInt64,
    branch_id::UInt64,
    t_id::UInt64,
    is_meaningful::Bool,
    fixed_branches::Dict{UInt64,UInt64},
    created_paths,
)::Tuple{UInt64,Bool,Bool,Set{Any},Bool,Vector{Any}}
    complexity_summary = get_complexity_summary(new_values, sc.types[t_id])
    if any(isa(value, PatternWrapper) for value in new_values)
        new_entry = PatternEntry(t_id, new_values, complexity_summary, get_complexity(sc, complexity_summary))
    else
        new_entry = ValueEntry(t_id, new_values, complexity_summary, get_complexity(sc, complexity_summary))
    end
    new_entry_index = push!(sc.entries, new_entry)
    new_parents, possible_result = find_related_branches(sc, branch_id, new_entry, new_entry_index)
    parent_constraints = keys(get_connected_from(sc.constrained_branches, branch_id))
    if !isnothing(possible_result)
        set_explained = false
        if !sc.branch_is_explained[possible_result]
            sc.branch_is_explained[possible_result] = true
            set_explained = true
        end
        if is_meaningful && sc.branch_is_not_copy[possible_result] != true
            sc.branch_is_not_copy[possible_result] = true
        end
        block_created_paths =
            get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, possible_result, fixed_branches)
        if isempty(block_created_paths)
            allow_fails = false
            next_blocks = Set()
        else
            allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, possible_result, fixed_branches)
        end
        return possible_result, false, allow_fails, next_blocks, set_explained, block_created_paths
    end

    new_branch_id = increment!(sc.branches_count)
    sc.branch_entries[new_branch_id] = new_entry_index
    sc.branch_vars[new_branch_id] = var_id
    sc.branch_types[new_branch_id, t_id] = true
    sc.branch_is_explained[new_branch_id] = true
    if is_meaningful
        sc.branch_is_not_copy[new_branch_id] = true
    end

    sc.branch_children[new_parents, new_branch_id] = true
    sc.complexities[new_branch_id] = new_entry.complexity
    sc.unused_explained_complexities[new_branch_id] = new_entry.complexity
    sc.unmatched_complexities[new_branch_id] = new_entry.complexity

    block_created_paths =
        get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, new_branch_id, fixed_branches)
    if !isempty(parent_constraints)
        for constraint_id in parent_constraints
            tighten_constraint(sc, constraint_id, new_branch_id, branch_id)
        end
        if isempty(block_created_paths)
            allow_fails = false
            next_blocks = Set()
        else
            allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, new_branch_id, fixed_branches)
        end
    else
        allow_fails, next_blocks = _downstream_blocks_new_branch(sc, var_id, branch_id, new_branch_id, fixed_branches)
    end
    return new_branch_id, true, allow_fails, next_blocks, true, block_created_paths
end

function _find_out_block(sc, out_blocks, constrained_branches)
    for (out_block_copy_id, out_block_id) in out_blocks
        in_branch_ids = keys(get_connected_to(sc.branch_outgoing_blocks, out_block_copy_id))
        good_copy = true
        in_branches = Dict()
        for in_branch_id in in_branch_ids
            in_var_id = sc.branch_vars[in_branch_id]
            if haskey(constrained_branches, in_var_id)
                if constrained_branches[in_var_id] != in_branch_id
                    good_copy = false
                    break
                end
            end
            in_branches[in_var_id] = in_branch_id
        end
        if !good_copy
            continue
        end
        out_branch_ids = keys(get_connected_to(sc.branch_incoming_blocks, out_block_copy_id))
        out_branches = Dict()
        for out_branch_id in out_branch_ids
            out_var_id = sc.branch_vars[out_branch_id]
            if haskey(constrained_branches, out_var_id)
                if constrained_branches[out_var_id] != out_branch_id
                    good_copy = false
                    break
                end
            end
            out_branches[out_var_id] = out_branch_id
        end
        if good_copy
            return sc.blocks[out_block_id], in_branches, out_branches
        end
    end
    error("No good block copy found")
end

function _get_abducted_values(sc, out_block::ProgramBlock, branches)
    in_entries = Dict(var_id => sc.entries[sc.branch_entries[branches[var_id]]] for var_id in out_block.input_vars)
    out_entry = sc.entries[sc.branch_entries[branches[out_block.output_var]]]

    updated_branches = DefaultDict{UInt64,Vector}(() -> [])
    for i in 1:sc.example_count
        updated_values = try_run_function(
            calculate_dependent_vars,
            [
                out_block.p,
                Dict{UInt64,Any}(
                    var_id => entry.values[i] for
                    (var_id, entry) in in_entries if !isa(entry.values[i], AbductibleValue)
                ),
                out_entry.values[i],
            ],
        )
        if isnothing(updated_values)
            throw(EnumerationException())
        end
        for (var_id, entry) in in_entries
            if haskey(updated_values, var_id)
                push!(updated_branches[var_id], updated_values[var_id])
            else
                push!(updated_branches[var_id], entry.values[i])
            end
        end
    end
    # @info "Block: $out_block"
    # @info "In entries: $in_entries"
    # @info "Out entry: $out_entry"
    # @info "Updated branches from block: $updated_branches"
    return updated_branches
end

function _get_abducted_values(sc, out_block::WrapEitherBlock, branches)
    out_entries = Dict(var_id => sc.entries[sc.branch_entries[branches[var_id]]] for var_id in out_block.output_vars)
    in_entry = sc.entries[sc.branch_entries[branches[out_block.input_vars[1]]]]
    fixer_entry = sc.entries[sc.branch_entries[branches[out_block.input_vars[2]]]]

    updated_branches = DefaultDict{UInt64,Vector}(() -> [])

    for i in 1:sc.example_count
        out_values = Dict{UInt64,Any}(
            var_id => entry.values[i] for (var_id, entry) in out_entries if !isa(entry.values[i], AbductibleValue)
        )
        out_values[out_block.fixer_var] = fixer_entry.values[i]
        updated_values =
            try_run_function(calculate_dependent_vars, [out_block.main_block.p, out_values, in_entry.values[i]])
        if isnothing(updated_values)
            throw(EnumerationException())
        end

        for (var_id, entry) in out_entries
            if haskey(updated_values, var_id)
                push!(updated_branches[var_id], updated_values[var_id])
                # elseif var_id == out_block.fixer_var
                #     push!(updated_branches[var_id], fixer_entry.values[i])
            else
                push!(updated_branches[var_id], entry.values[i])
            end
        end
    end
    updated_branches[out_block.fixer_var] = fixer_entry.values
    # @info "Block: $out_block"
    # @info "Out entries: $out_entries"
    # @info "In entry: $in_entry"
    # @info "Fixer entry: $fixer_entry"
    # @info "Updated branches from wrapper: $updated_branches"
    return updated_branches
end

function _find_relatives_for_abductible(sc, new_entry, branch_id, old_entry)
    if old_entry == new_entry
        return branch_id, UInt64[], UInt64[]
    end

    for child_id in get_connected_from(sc.branch_children, branch_id)
        child_entry = sc.entries[sc.branch_entries[child_id]]
        if child_entry.values == new_entry.values
            return child_id, UInt64[], UInt64[]
        end
    end

    return nothing, UInt64[branch_id], UInt64[]
end

function _abduct_next_block(sc, out_block_copy_id, out_block_id, new_branch_id, var_id, branch_id)
    branch_ids = vcat(
        collect(keys(get_connected_to(sc.branch_outgoing_blocks, out_block_copy_id))),
        collect(keys(get_connected_to(sc.branch_incoming_blocks, out_block_copy_id))),
    )
    old_branches = Dict{UInt64,UInt64}(sc.branch_vars[b_id] => b_id for b_id in branch_ids)

    old_branches[var_id] = new_branch_id

    updated_values = _get_abducted_values(sc, sc.blocks[out_block_id], old_branches)

    new_branches = Dict{UInt64,UInt64}()
    out_branches = Dict{UInt64,UInt64}()

    new_branches[branch_id] = new_branch_id
    out_branches[branch_id] = new_branch_id

    either_branch_ids = UInt64[]
    either_var_ids = UInt64[]

    for (v_id, b_id) in old_branches
        if haskey(updated_values, v_id)
            old_br_entry = sc.entries[sc.branch_entries[b_id]]
            # @info old_br_entry

            new_br_entry = _make_entry(sc, old_br_entry.type_id, updated_values[v_id])
            # @info new_br_entry
            exact_match, parents, children = _find_relatives_for_abductible(sc, new_br_entry, b_id, old_br_entry)
            if !isnothing(exact_match)
                if isa(new_br_entry, EitherEntry)
                    push!(either_branch_ids, exact_match)
                    push!(either_var_ids, v_id)
                end
                out_branches[b_id] = exact_match
            else
                entry_index = push!(sc.entries, new_br_entry)
                # @info entry_index

                created_branch_id = increment!(sc.branches_count)
                sc.branch_entries[created_branch_id] = entry_index
                sc.branch_vars[created_branch_id] = v_id
                sc.branch_types[created_branch_id, new_br_entry.type_id] = true
                if sc.branch_is_unknown[b_id]
                    sc.branch_is_unknown[created_branch_id] = true
                    sc.branch_unknown_from_output[created_branch_id] = sc.branch_unknown_from_output[b_id]
                end
                deleteat!(sc.branch_children, parents, children)
                sc.branch_children[parents, created_branch_id] = true
                sc.branch_children[created_branch_id, children] = true

                original_path_cost = sc.unknown_min_path_costs[b_id]
                if !isnothing(original_path_cost)
                    sc.unknown_min_path_costs[created_branch_id] = original_path_cost
                end
                sc.complexities[created_branch_id] = new_br_entry.complexity
                sc.unmatched_complexities[created_branch_id] = new_br_entry.complexity

                if isa(new_br_entry, EitherEntry)
                    push!(either_branch_ids, created_branch_id)
                    push!(either_var_ids, v_id)
                end
                out_branches[b_id] = created_branch_id
                new_branches[b_id] = created_branch_id
            end
        end
    end

    for (old_br_id, new_br_id) in new_branches
        if sc.branch_is_unknown[new_br_id]
            old_related_branches = get_connected_from(sc.related_unknown_complexity_branches, old_br_id)
            new_related_branches =
                UInt64[(haskey(new_branches, b_id) ? new_branches[b_id] : b_id) for b_id in old_related_branches]
            sc.related_unknown_complexity_branches[new_br_id, new_related_branches] = true
            sc.unknown_complexity_factors[new_br_id] = branch_complexity_factor_unknown(sc, new_br_id)
        end
    end

    unknown_old_branches = UInt64[br_id for (br_id, _) in new_branches]
    next_blocks = merge([get_connected_from(sc.branch_outgoing_blocks, br_id) for br_id in unknown_old_branches]...)
    for (b_copy_id, b_id) in next_blocks
        inp_branches = keys(get_connected_to(sc.branch_outgoing_blocks, b_copy_id))
        inputs = Dict(sc.branch_vars[b] => haskey(out_branches, b) ? out_branches[b] : b for b in inp_branches)
        out_block_branches = keys(get_connected_to(sc.branch_incoming_blocks, b_copy_id))
        target_branches = UInt64[haskey(out_branches, b) ? out_branches[b] : b for b in out_block_branches]

        bl = sc.blocks[b_id]
        if isa(bl, WrapEitherBlock)
            input_entries = Set([sc.branch_entries[inputs[bl.input_vars[1]]]])
        else
            input_entries = Set(sc.branch_entries[b] for b in values(inputs))
        end
        if any(in(sc.branch_entries[b], input_entries) for b in target_branches)
            if sc.verbose
                @info "Fixing constraint leads to a redundant block"
            end
            throw(EnumerationException("Fixing constraint leads to a redundant block"))
        end

        _save_block_branch_connections(sc, b_id, sc.blocks[b_id], inputs, target_branches)
        for target_branch in target_branches
            update_complexity_factors_unknown(sc, inputs, target_branch)
        end
    end

    if !isempty(either_branch_ids)
        active_constraints =
            union([collect(keys(get_connected_from(sc.constrained_branches, br_id))) for br_id in branch_ids]...)
        if length(active_constraints) == 0
            new_constraint_id = increment!(sc.constraints_count)
            # @info "Added new constraint with either $new_constraint_id"
            active_constraints = UInt64[new_constraint_id]
        end
        for constraint_id in active_constraints
            sc.constrained_branches[either_branch_ids, constraint_id] = either_var_ids
            sc.constrained_vars[either_var_ids, constraint_id] = either_branch_ids
        end
    end
end

function updated_branches(
    sc,
    entry::AbductibleEntry,
    @nospecialize(new_values),
    block_id,
    is_new_block,
    var_id::UInt64,
    branch_id::UInt64,
    t_id::UInt64,
    is_meaningful::Bool,
    fixed_branches::Dict{UInt64,UInt64},
    created_paths,
)::Tuple{UInt64,Bool,Bool,Set{Any},Bool,Vector{Any}}
    complexity_summary = get_complexity_summary(new_values, sc.types[t_id])
    if any(isa(value, PatternWrapper) for value in new_values)
        new_entry = PatternEntry(t_id, new_values, complexity_summary, get_complexity(sc, complexity_summary))
    else
        new_entry = ValueEntry(t_id, new_values, complexity_summary, get_complexity(sc, complexity_summary))
    end
    new_entry_index = push!(sc.entries, new_entry)
    new_parents, possible_result = find_related_branches(sc, branch_id, new_entry, new_entry_index)
    if !isnothing(possible_result)
        set_explained = false
        if !sc.branch_is_explained[possible_result]
            sc.branch_is_explained[possible_result] = true
            set_explained = true
        end
        if is_meaningful && sc.branch_is_not_copy[possible_result] != true
            sc.branch_is_not_copy[possible_result] = true
        end
        block_created_paths =
            get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, possible_result, fixed_branches)
        if isempty(block_created_paths)
            allow_fails = false
            next_blocks = Set()
        else
            allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, possible_result, fixed_branches)
        end
        return possible_result, false, allow_fails, next_blocks, set_explained, block_created_paths
    end

    new_branch_id = increment!(sc.branches_count)
    sc.branch_entries[new_branch_id] = new_entry_index
    sc.branch_vars[new_branch_id] = var_id
    sc.branch_types[new_branch_id, t_id] = true
    sc.branch_is_explained[new_branch_id] = true
    if is_meaningful
        sc.branch_is_not_copy[new_branch_id] = true
    end

    sc.branch_children[new_parents, new_branch_id] = true
    sc.complexities[new_branch_id] = new_entry.complexity
    sc.unused_explained_complexities[new_branch_id] = new_entry.complexity
    sc.unmatched_complexities[new_branch_id] = new_entry.complexity

    out_blocks = get_connected_from(sc.branch_outgoing_blocks, branch_id)

    for (out_block_copy_id, out_block_id) in out_blocks
        _abduct_next_block(sc, out_block_copy_id, out_block_id, new_branch_id, var_id, branch_id)
    end

    block_created_paths =
        get_new_paths_for_block(sc, block_id, is_new_block, created_paths, var_id, new_branch_id, fixed_branches)
    if isempty(block_created_paths)
        allow_fails = false
        next_blocks = Set()
    else
        allow_fails, next_blocks = _downstream_blocks_existing_branch(sc, var_id, new_branch_id, fixed_branches)
    end
    return new_branch_id, false, allow_fails, next_blocks, true, block_created_paths
end

function _downstream_branch_options_known(sc, block_id, block_copy_id, fixed_branches, unfixed_vars)
    inp_branches = keys(get_connected_to(sc.branch_outgoing_blocks, block_copy_id))
    all_inputs = Dict(sc.branch_vars[b] => b for b in inp_branches)
    for (v, b) in all_inputs
        if haskey(fixed_branches, v) && sc.branch_is_explained[b] && fixed_branches[v] != b
            return false, Set(), Set()
        end
    end
    out_branches = keys(get_connected_to(sc.branch_incoming_blocks, block_copy_id))
    target_output = Dict(sc.branch_vars[b] => b for b in out_branches)
    if isempty(unfixed_vars)
        return false, Set([(block_id, fixed_branches, target_output)]), Set()
    end
    # @info fixed_branches
    # @info unfixed_vars
    inputs = Dict(v => b for (v, b) in all_inputs if in(v, unfixed_vars))
    new_fixed_branches = merge(fixed_branches, inputs)
    if all(sc.branch_is_explained[br_id] for br_id in values(inputs))
        return false, Set([(block_id, new_fixed_branches, target_output)]), Set()
    end
    allow_fails = false
    for var_id in unfixed_vars
        br_id = inputs[var_id]
        if !sc.branch_is_explained[br_id] && isa(sc.entries[sc.branch_entries[br_id]], NoDataEntry)
            allow_fails = true
            break
        end
    end
    return allow_fails, Set(), Set([(block_id, new_fixed_branches, UInt64[b_id for (_, b_id) in target_output])])
end

function _downstream_blocks_existing_branch(sc, var_id, out_branch_id, fixed_branches)
    allow_fails = false
    outputs = Set()
    fixed_branches = merge(fixed_branches, Dict(var_id => out_branch_id))
    next_blocks = get_connected_from(sc.branch_outgoing_blocks, out_branch_id)
    for (b_copy_id, b_id) in next_blocks
        block = sc.blocks[b_id]
        unfixed_vars = [v_id for v_id in block.input_vars if !haskey(fixed_branches, v_id)]
        allow_block_fails, block_options, unfixed_options =
            _downstream_branch_options_known(sc, b_id, b_copy_id, fixed_branches, unfixed_vars)
        allow_fails |= allow_block_fails
        union!(outputs, block_options)
        # union!(unexplained_options, unfixed_options)
    end

    # @info allow_fails
    # @info outputs
    return allow_fails, outputs
end

function _downstream_blocks_new_branch(sc, var_id, target_branch_id, out_branch_id, fixed_branches)
    allow_fails = false
    outputs = Set()
    fixed_branches = merge(fixed_branches, Dict(var_id => out_branch_id))

    next_blocks = get_connected_from(sc.branch_outgoing_blocks, target_branch_id)
    unexplained_options = Set()
    for (b_copy_id, b_id) in next_blocks
        block = sc.blocks[b_id]
        unfixed_vars = [v_id for v_id in block.input_vars if !haskey(fixed_branches, v_id)]
        allow_block_fails, block_options, unfixed_options =
            _downstream_branch_options_known(sc, b_id, b_copy_id, fixed_branches, unfixed_vars)
        allow_fails |= allow_block_fails
        union!(outputs, block_options)
        union!(unexplained_options, unfixed_options)
    end
    for (b_id, inp_branches, target_branches) in unexplained_options
        _save_block_branch_connections(sc, b_id, sc.blocks[b_id], inp_branches, target_branches)
    end
    # @info allow_fails
    # @info outputs
    return allow_fails, outputs
end

function _save_block_branch_connections(sc, block_id, block, fixed_branches, out_branches)
    input_br_ids = UInt64[fixed_branches[var_id] for var_id in block.input_vars]
    existing_outgoing = DefaultDict{UInt64,Int}(() -> 0)
    for in_br_id in input_br_ids
        for (bl_copy_id, bl_id) in get_connected_from(sc.branch_outgoing_blocks, in_br_id)
            if bl_id == block_id
                existing_outgoing[bl_copy_id] += 1
            end
        end
    end
    for (bl_copy_id, count) in existing_outgoing
        if count != length(input_br_ids)
            continue
        end
        if sort(collect(keys(get_connected_to(sc.branch_incoming_blocks, bl_copy_id)))) == out_branches
            if sc.verbose
                @info "Block $block_id $block already has connections for inputs $input_br_ids and outputs $out_branches"
            end
            throw(EnumerationException())
        end
    end

    block_copy_id = increment!(sc.block_copies_count)
    sc.branch_outgoing_blocks[input_br_ids, block_copy_id] = block_id
    sc.branch_incoming_blocks[out_branches, block_copy_id] = block_id
    if sc.verbose
        inputs = [(br_id, sc.branch_entries[br_id], sc.entries[sc.branch_entries[br_id]]) for br_id in input_br_ids]
        outputs = [(br_id, sc.branch_entries[br_id], sc.entries[sc.branch_entries[br_id]]) for br_id in out_branches]

        @info "Created new block copy $block_copy_id for block $block_id $block with inputs $inputs and outputs $outputs"
    end
end


function _find_relatives_for_type(sc, t, branch_id, branch_type)
    if branch_type == t && sc.branch_is_unknown[branch_id]
        return branch_id, UInt64[], UInt64[]
    end
    if sc.branch_is_explained[branch_id] && is_subtype(t, branch_type)
        return nothing, get_connected_to(sc.branch_children, branch_id), Int[branch_id]
    end
    parents = UInt64[]
    children = UInt64[]
    for child_id in get_connected_from(sc.branch_children, branch_id)
        child_type = sc.types[first(get_connected_from(sc.branch_types, child_id))]
        if is_subtype(child_type, t)
            exact_match, parents_, children_ = _find_relatives_for_type(sc, t, child_id, child_type)
            if !isnothing(exact_match)
                return exact_match, UInt64[], UInt64[]
            end
            union!(parents, parents_)
            union!(children, children_)
        elseif is_subtype(t, child_type)
            push!(children, child_id)
        end
    end
    if isempty(parents)
        push!(parents, branch_id)
    end
    return nothing, parents, children
end

function _tighten_constraint(
    sc,
    constrained_branches,
    constrained_context_id,
    new_var_id,
    new_branch_id,
    old_entry::NoDataEntry,
)
    context = sc.constraint_contexts[constrained_context_id]

    out_branches = Dict()
    new_branches = Dict()
    out_constrained_branches = Dict()

    new_type = sc.types[first(get_connected_from(sc.branch_types, new_branch_id))]
    context = unify(context, new_type, sc.types[old_entry.type_id])

    for (var_id, branch_id) in constrained_branches
        if var_id == new_var_id
            out_branches[branch_id] = new_branch_id
            new_branches[branch_id] = new_branch_id
        else
            branch_type = sc.types[first(get_connected_from(sc.branch_types, branch_id))]
            context, new_type = apply_context(context, branch_type)

            exact_match, parents, children = _find_relatives_for_type(sc, new_type, branch_id, branch_type)
            if !isnothing(exact_match)
                if is_polymorphic(new_type)
                    out_constrained_branches[var_id] = exact_match
                end
                out_branches[branch_id] = exact_match
            else
                new_type_id = push!(sc.types, new_type)
                new_entry = NoDataEntry(new_type_id)
                entry_id = push!(sc.entries, new_entry)

                created_branch_id = increment!(sc.branches_count)
                sc.branch_entries[created_branch_id] = entry_id
                sc.branch_vars[created_branch_id] = var_id
                sc.branch_types[created_branch_id, new_type_id] = true
                deleteat!(sc.branch_children, parents, children)
                sc.branch_children[parents, created_branch_id] = true
                sc.branch_children[created_branch_id, children] = true

                sc.branch_is_unknown[created_branch_id] = true
                sc.branch_unknown_from_output[created_branch_id] = sc.branch_unknown_from_output[branch_id]
                sc.unknown_min_path_costs[created_branch_id] = sc.unknown_min_path_costs[branch_id]
                sc.unknown_complexity_factors[created_branch_id] = sc.unknown_complexity_factors[branch_id]
                related_branches = get_connected_from(sc.related_unknown_complexity_branches, branch_id)
                sc.related_unknown_complexity_branches[created_branch_id, related_branches] = true

                if is_polymorphic(new_type)
                    out_constrained_branches[var_id] = created_branch_id
                end
                out_branches[branch_id] = created_branch_id
                new_branches[branch_id] = created_branch_id
            end
        end
    end

    unknown_old_branches = UInt64[br_id for (br_id, _) in new_branches]
    next_blocks = merge([get_connected_from(sc.branch_outgoing_blocks, br_id) for br_id in unknown_old_branches]...)
    for (b_copy_id, b_id) in next_blocks
        inp_branches = keys(get_connected_to(sc.branch_outgoing_blocks, b_copy_id))
        inputs = Dict(sc.branch_vars[b] => haskey(out_branches, b) ? out_branches[b] : b for b in inp_branches)
        out_block_branches = keys(get_connected_to(sc.branch_incoming_blocks, b_copy_id))
        target_branches = UInt64[haskey(out_branches, b) ? out_branches[b] : b for b in out_block_branches]
        _save_block_branch_connections(sc, b_id, sc.blocks[b_id], inputs, target_branches)
    end

    if length(out_constrained_branches) > 1
        new_context_id = push!(sc.constraint_contexts, context)
        return out_constrained_branches, new_context_id
    else
        return Dict(), nothing
    end
end

function tighten_constraint(sc, constraint_id, new_branch_id, old_branch_id)
    old_entry = sc.entries[sc.branch_entries[old_branch_id]]
    constrained_branches = Dict(v => b for (b, v) in get_connected_to(sc.constrained_branches, constraint_id))
    constrained_context_id = sc.constrained_contexts[constraint_id]
    new_constrained_branches, new_context_id = _tighten_constraint(
        sc,
        constrained_branches,
        constrained_context_id,
        sc.branch_vars[new_branch_id],
        new_branch_id,
        old_entry,
    )

    if !isempty(new_constrained_branches)
        new_constraint_id = increment!(sc.constraints_count)
        # @info "Added new constraint on tighten $new_constraint_id from $constraint_id"

        vars = UInt64[]
        branches = UInt64[]
        for (var_id, branch_id) in new_constrained_branches
            push!(vars, var_id)
            push!(branches, branch_id)
        end
        sc.constrained_vars[vars, new_constraint_id] = branches
        sc.constrained_branches[branches, new_constraint_id] = vars
        if !isnothing(new_context_id)
            sc.constrained_contexts[new_constraint_id] = new_context_id
        end
    end
    return true
end

function _get_fixed_hashes(options::EitherOptions, value)
    out_hashes = Set()
    for (h, option) in options.options
        found, hashes = _get_fixed_hashes(option, value)
        if found
            union!(out_hashes, hashes)
            push!(out_hashes, h)
        end
    end
    return !isempty(out_hashes), out_hashes
end

function _get_fixed_hashes(options, value)
    options == value, Set()
end

function __fix_option_hashes(fixed_hashes, value::EitherOptions)
    filter_level = any(haskey(value.options, h) for h in fixed_hashes)
    out_options = Dict()
    for (h, option) in value.options
        if filter_level && !in(h, fixed_hashes)
            continue
        end
        out_options[h] = __fix_option_hashes(fixed_hashes, option)
    end
    if isempty(out_options)
        @info value
        @info fixed_hashes
        error("No options left after filtering")
    elseif length(out_options) == 1
        return first(out_options)[2]
    else
        return EitherOptions(out_options)
    end
end

function __fix_option_hashes(fixed_hashes, value)
    return value
end

function _fix_option_hashes(fixed_hashes, values)
    out_values = []
    for ((found, hashes), value) in zip(fixed_hashes, values)
        if !found
            throw(EnumerationException("Inconsistent match"))
        end
        push!(out_values, __fix_option_hashes(hashes, value))
    end
    return out_values
end

function _fix_option_hashes(sc, fixed_hashes, entry::EitherEntry)
    out_values = _fix_option_hashes(fixed_hashes, entry.values)
    return _make_entry(sc, entry.type_id, out_values)
end

function _make_entry(sc, type_id, values)
    complexity_summary = get_complexity_summary(values, sc.types[type_id])
    if any(isa(v, EitherOptions) for v in values)
        return EitherEntry(type_id, values, complexity_summary, get_complexity(sc, complexity_summary))
    elseif any(isa(v, AbductibleValue) for v in values)
        return AbductibleEntry(type_id, values, complexity_summary, get_complexity(sc, complexity_summary))
    elseif any(isa(v, PatternWrapper) for v in values)
        return PatternEntry(type_id, values, complexity_summary, get_complexity(sc, complexity_summary))
    else
        return ValueEntry(type_id, values, complexity_summary, get_complexity(sc, complexity_summary))
    end
end

function _find_relatives_for_either(sc, new_entry, branch_id, old_entry)
    if old_entry == new_entry
        return branch_id, UInt64[], UInt64[]
    end

    parents = UInt64[]
    children = UInt64[]
    for child_id in get_connected_from(sc.branch_children, branch_id)
        child_entry = sc.entries[sc.branch_entries[child_id]]
        if all(is_subeither(child_val, new_val) for (child_val, new_val) in zip(child_entry.values, new_entry.values))
            exact_match, parents_, children_ = _find_relatives_for_either(sc, new_entry, child_id, child_entry)
            if !isnothing(exact_match)
                return exact_match, UInt64[], UInt64[]
            end
            union!(parents, parents_)
            union!(children, children_)
        elseif all(
            is_subeither(new_val, child_val) for (child_val, new_val) in zip(child_entry.values, new_entry.values)
        )
            push!(children, child_id)
        end
    end
    if isempty(parents)
        push!(parents, branch_id)
    end
    return nothing, parents, children
end

function _tighten_constraint(
    sc,
    constrained_branches,
    constrained_context_id,
    new_var_id,
    new_branch_id,
    old_entry::EitherEntry,
)
    out_either_branches = Dict()
    out_branches = Dict()
    new_branches = Dict()

    # @info new_branch
    new_entry = sc.entries[sc.branch_entries[new_branch_id]]
    # @info new_entry
    fixed_hashes = [_get_fixed_hashes(old_entry.values[j], new_entry.values[j]) for j in 1:sc.example_count]
    # @info fixed_hashes

    for (var_id, branch_id) in constrained_branches
        if var_id == new_var_id
            out_branches[branch_id] = new_branch_id
            new_branches[branch_id] = new_branch_id
        else
            old_br_entry = sc.entries[sc.branch_entries[branch_id]]
            # @info old_br_entry
            if !isa(old_br_entry, EitherEntry)
                error("Non-either branch $branch_id $(sc.branch_entries[branch_id]) $old_br_entry in either constraint")
            end
            new_br_entry = _fix_option_hashes(sc, fixed_hashes, old_br_entry)
            # @info new_br_entry
            exact_match, parents, children = _find_relatives_for_either(sc, new_br_entry, branch_id, old_br_entry)
            if !isnothing(exact_match)
                if isa(new_br_entry, EitherEntry)
                    out_either_branches[var_id] = exact_match
                end
                out_branches[branch_id] = exact_match
            else
                entry_index = push!(sc.entries, new_br_entry)
                # @info entry_index

                created_branch_id = increment!(sc.branches_count)
                sc.branch_entries[created_branch_id] = entry_index
                sc.branch_vars[created_branch_id] = var_id
                sc.branch_types[created_branch_id, new_br_entry.type_id] = true
                if sc.branch_is_unknown[branch_id]
                    sc.branch_is_unknown[created_branch_id] = true
                    sc.branch_unknown_from_output[created_branch_id] = sc.branch_unknown_from_output[branch_id]
                end
                deleteat!(sc.branch_children, parents, children)
                sc.branch_children[parents, created_branch_id] = true
                sc.branch_children[created_branch_id, children] = true

                original_path_cost = sc.unknown_min_path_costs[branch_id]
                if !isnothing(original_path_cost)
                    sc.unknown_min_path_costs[created_branch_id] = original_path_cost
                end
                sc.complexities[created_branch_id] = new_br_entry.complexity
                sc.unmatched_complexities[created_branch_id] = new_br_entry.complexity

                if isa(new_br_entry, EitherEntry)
                    out_either_branches[var_id] = created_branch_id
                end
                out_branches[branch_id] = created_branch_id
                new_branches[branch_id] = created_branch_id
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

    return out_either_branches, constrained_context_id
end

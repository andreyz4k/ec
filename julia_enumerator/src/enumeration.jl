
using DataStructures

get_enumeration_timeout(timeout) = time() + timeout
enumeration_timed_out(timeout) = time() > timeout

get_argument_requests(::Index, argument_types, cg) = [(at, cg.variable_context) for at in argument_types]
get_argument_requests(::FreeVar, argumet_types, cg) = []
get_argument_requests(candidate, argument_types, cg) = zip(argument_types, cg.contextual_library[candidate])

struct WrongPath <: Exception end

follow_path(skeleton::Apply, path) =
    if isa(path[1], LeftTurn)
        follow_path(skeleton.f, view(path, 2:length(path)))
    elseif isa(path[1], RightTurn)
        follow_path(skeleton.x, view(path, 2:length(path)))
    else
        throw(WrongPath())
    end

follow_path(skeleton::Abstraction, path) =
    if isa(path[1], ArgTurn)
        follow_path(skeleton.b, view(path, 2:length(path)))
    else
        throw(WrongPath())
    end

follow_path(skeleton::Hole, path) =
    if isempty(path)
        skeleton
    else
        throw(WrongPath())
    end

follow_path(::Any, path) = throw(WrongPath())

path_environment(path) = reverse([t.type for t in path if isa(t, ArgTurn)])

modify_skeleton(skeleton::Abstraction, template, path) =
    if isa(path[1], ArgTurn)
        Abstraction(modify_skeleton(skeleton.b, template, view(path, 2:length(path))))
    else
        throw(WrongPath())
    end

modify_skeleton(::Hole, template, path) =
    if isempty(path)
        template
    else
        throw(WrongPath())
    end

modify_skeleton(skeleton::Apply, template, path) =
    if isa(path[1], LeftTurn)
        Apply(modify_skeleton(skeleton.f, template, view(path, 2:length(path))), skeleton.x)
    elseif isa(path[1], RightTurn)
        Apply(skeleton.f, modify_skeleton(skeleton.x, template, view(path, 2:length(path))))
    else
        throw(WrongPath())
    end

function _unwind_path(path)
    k = length(path)
    while k > 0
        if isa(path[k], LeftTurn)
            break
        end
        k -= 1
    end
    if k > 0
        vcat(path[1:k-1], [RightTurn()])
    else
        []
    end
end

function unwind_path(path, skeleton)
    new_path = _unwind_path(path)
    if !isempty(new_path)
        try
            follow_path(skeleton, new_path)
        catch e
            if isa(e, WrongPath)
                return unwind_path(new_path, skeleton)
            else
                rethrow()
            end
        end
    end
    return new_path
end

violates_symmetry(::Program, a, n) = false

const illegal_combinations1 = Set([
    #  McCarthy primitives
    (0, "car", "cons"),
    (0, "car", "empty"),
    (0, "cdr", "cons"),
    (0, "cdr", "empty"),
    (1, "-", "0"),
    (0, "+", "+"),
    (0, "*", "*"),
    (0, "empty?", "cons"),
    (0, "empty?", "empty"),
    (0, "zero?", "0"),
    (0, "zero?", "1"),
    (0, "zero?", "-1"),
    #  bootstrap target
    (1, "map", "empty"),
    (0, "fold", "empty"),
    (1, "index", "empty"),
])

const illegal_combinations2 = Set([
    ("+", "0"),
    ("*", "0"),
    ("*", "1"),
    ("zip", "empty"),
    ("left", "left"),
    ("left", "right"),
    ("right", "right"),
    ("right", "left"),
    #   ("tower_embed","tower_embed")
])

function violates_symmetry(f::Primitive, a, n)
    a = application_function(a)
    if !isa(a, Primitive)
        return false
    end
    return in((n, f.name, a.name), illegal_combinations1) || in((f.name, a.name), illegal_combinations2)
end

has_index(p::Index, i) = p.n == i
has_index(p::Hole, i) = true
has_index(p::Primitive, i) = false
has_index(p::Invented, i) = false
has_index(p::Apply, i) = has_index(p.f, i) || has_index(p.x, i)
has_index(p::FreeVar, i) = false
has_index(p::Abstraction, i) = has_index(p.b, i + 1)

state_violates_symmetry(p::Abstraction) = state_violates_symmetry(p.b) || !has_index(p.b, 0)
function state_violates_symmetry(p::Apply)
    (f, a) = application_parse(p)
    return state_violates_symmetry(f) ||
           any(state_violates_symmetry, a) ||
           any(violates_symmetry(f, x, n) for (n, x) in enumerate(a))
end
state_violates_symmetry(::Program) = false

function block_state_successors(
    maxFreeParameters,
    cg::ContextualGrammar,
    state::EnumerationState,
)::Vector{EnumerationState}
    current_hole = follow_path(state.skeleton, state.path)
    if !isa(current_hole, Hole)
        error("Error during following path")
    end
    request = current_hole.t
    g = current_hole.grammar

    context = state.context
    context, request = apply_context(context, request)
    if isarrow(request)
        return [
            EnumerationState(
                modify_skeleton(state.skeleton, (Abstraction(Hole(request.arguments[2], g))), state.path),
                context,
                vcat(state.path, [ArgTurn(request.arguments[1])]),
                state.cost,
                state.free_parameters,
                state.abstractors_only,
            ),
        ]
    else
        environment = path_environment(state.path)
        candidates = unifying_expressions(g, environment, request, context, state.abstractors_only)
        if !isa(state.skeleton, Hole)
            push!(candidates, (FreeVar(request, nothing), [], context, g.log_variable))
        end

        states = map(candidates) do (candidate, argument_types, context, ll)
            new_free_parameters = number_of_free_parameters(candidate)
            argument_requests = get_argument_requests(candidate, argument_types, cg)

            if isempty(argument_types)
                new_skeleton = modify_skeleton(state.skeleton, candidate, state.path)
                new_path = unwind_path(state.path, new_skeleton)
            else
                application_template = candidate
                for (a, at) in argument_requests
                    application_template = Apply(application_template, Hole(a, at))
                end
                new_skeleton = modify_skeleton(state.skeleton, application_template, state.path)
                new_path = vcat(state.path, [LeftTurn() for _ in 2:length(argument_types)], [RightTurn()])
            end
            return EnumerationState(
                new_skeleton,
                context,
                new_path,
                state.cost + ll,
                state.free_parameters + new_free_parameters,
                state.abstractors_only,
            )
        end
        return filter(
            (
                new_state ->
                    !state_violates_symmetry(new_state.skeleton) && new_state.free_parameters <= maxFreeParameters
            ),
            states,
        )
    end
end

capture_free_vars(sc::SolutionContext, p::Program, context) = p, []

function capture_free_vars(sc::SolutionContext, p::Apply, context)
    new_f, new_vars_f = capture_free_vars(sc, p.f, context)
    new_x, new_vars_x = capture_free_vars(sc, p.x, context)
    Apply(new_f, new_x), vcat(new_vars_f, new_vars_x)
end

function capture_free_vars(sc::SolutionContext, p::Abstraction, context)
    new_b, new_vars = capture_free_vars(sc, p.b, context)
    Abstraction(new_b), new_vars
end

function capture_free_vars(sc::SolutionContext, p::FreeVar, context)
    _, t = apply_context(context, p.t)
    var_id = create_next_var(sc)
    FreeVar(t, var_id), [(var_id, t)]
end

function try_run_reversed_with_value(reverse_program, value)
    try_run_function(reverse_program, [value])
end

function try_run_reversed_with_value(reverse_program, value::EitherOptions)
    hashes = []
    outputs = []
    for (h, val) in value.options
        outs = try_run_reversed_with_value(reverse_program, val)
        if isnothing(outs)
            return nothing
        end
        push!(hashes, h)
        push!(outputs, outs)
    end
    results = []
    for values in zip(outputs...)
        values = collect(values)
        if allequal(values)
            push!(results, values[1])
        else
            options = Dict(h => v for (h, v) in zip(hashes, values))
            push!(results, EitherOptions(options))
        end
    end
    return results
end

function try_get_reversed_values(sc::SolutionContext, p::Program, context, output_branch_id, cost, is_known)
    p, reverse_program = get_reversed_filled_program(p)
    out_entry = sc.entries[sc.branch_entries[output_branch_id]]

    calculated_values = []
    for value in out_entry.values
        calculated_value = try_run_reversed_with_value(reverse_program, value)
        if isnothing(calculated_value)
            return nothing
        end
        push!(calculated_values, calculated_value)
    end

    new_p, new_vars = capture_free_vars(sc, p, context)

    new_entries = []
    for ((var_id, t), values) in zip(new_vars, zip(calculated_values...))
        values = collect(values)
        complexity_summary = get_complexity_summary(values, t)
        t_id = push!(sc.types, t)
        if any(isa(value, EitherOptions) for value in values)
            new_entry = EitherEntry(t_id, values, complexity_summary, get_complexity(sc, complexity_summary))
        else
            new_entry = ValueEntry(t_id, values, complexity_summary, get_complexity(sc, complexity_summary))
        end
        push!(new_entries, (var_id, new_entry))
    end

    complexity_factor =
        (is_known ? sc.explained_complexity_factors : sc.unknown_complexity_factors)[output_branch_id] -
        out_entry.complexity + sum(entry.complexity for (_, entry) in new_entries)

    new_branches = []
    either_branch_ids = Int[]
    either_var_ids = Int[]

    if is_known
        out_related_complexity_branches = sc.related_explained_complexity_branches[output_branch_id, :]
    else
        out_related_complexity_branches = sc.related_unknown_complexity_branches[output_branch_id, :]
    end

    for (var_id, entry) in new_entries
        entry_index = push!(sc.entries, entry)
        branch_id = increment!(sc.branches_count)
        sc.branch_entries[branch_id] = entry_index
        sc.branch_vars[branch_id] = var_id
        sc.branch_types[branch_id, entry.type_id] = entry.type_id
        if is_known
            sc.explained_min_path_costs[branch_id] = cost + sc.explained_min_path_costs[output_branch_id]
            sc.explained_complexity_factors[branch_id] = complexity_factor
            sc.unused_explained_complexities[branch_id] = entry.complexity
            sc.added_upstream_complexities[branch_id] = sc.added_upstream_complexities[output_branch_id]
            sc.related_explained_complexity_branches[branch_id, :] = out_related_complexity_branches
        else
            sc.branch_is_unknown[branch_id] = true
            sc.branch_unknown_from_output[branch_id] = sc.branch_unknown_from_output[output_branch_id]
            sc.unknown_min_path_costs[branch_id] = cost + sc.unknown_min_path_costs[output_branch_id]
            sc.unknown_complexity_factors[branch_id] = complexity_factor
            sc.unmatched_complexities[branch_id] = entry.complexity
            sc.related_unknown_complexity_branches[branch_id, :] = out_related_complexity_branches
        end
        sc.complexities[branch_id] = entry.complexity

        if isa(entry, EitherEntry)
            push!(either_branch_ids, branch_id)
            push!(either_var_ids, var_id)
        end

        push!(new_branches, (var_id, branch_id, entry.type_id))
    end
    if length(new_branches) > 1
        for (_, branch_id, _) in new_branches
            inds = [b_id for (_, b_id, _) in new_branches if b_id != branch_id]
            if is_known
                sc.related_explained_complexity_branches[branch_id, inds] = 1
            else
                sc.related_unknown_complexity_branches[branch_id, inds] = 1
            end
        end
    end
    if length(either_branch_ids) >= 1
        active_constraints = nonzeroinds(sc.constrained_branches[output_branch_id, :])
        if length(active_constraints) == 0
            new_constraint_id = increment!(sc.constraints_count)
            # @info "Added new constraint with either $new_constraint_id"
            active_constraints = Int[new_constraint_id]
        end
        sc.constrained_branches[either_branch_ids, active_constraints] = either_var_ids
        sc.constrained_vars[either_var_ids, active_constraints] = either_branch_ids
    end

    return new_p, reverse_program, new_branches, either_var_ids, either_branch_ids
end

function try_get_reversed_inputs(sc, p::Program, context, output_branch_id, cost)
    reverse_results = try_get_reversed_values(sc, p, context, output_branch_id, cost, false)
    if !isnothing(reverse_results)
        new_p, _, inputs, _, _ = reverse_results
        return new_p, inputs
    end
end

function create_wrapping_block(
    sc::SolutionContext,
    block,
    cost,
    input_var,
    input_branch,
    output_vars,
    var_id,
    branch_id,
)
    unknown_type_id = [t_id for (v_id, _, t_id) in output_vars if v_id == var_id][1]
    new_var = create_next_var(sc)

    new_branch_id = increment!(sc.branches_count)
    sc.branch_entries[new_branch_id] = sc.branch_entries[branch_id]
    sc.branch_is_unknown[new_branch_id] = true
    sc.branch_vars[new_branch_id] = new_var
    sc.branch_types[new_branch_id, unknown_type_id] = unknown_type_id
    sc.complexities[new_branch_id] = sc.complexities[branch_id]

    # constraints = nonzeroinds(sc.constrained_branches[branch_id, :])
    new_constraint_id = increment!(sc.constraints_count)
    sc.constrained_branches[new_branch_id, new_constraint_id] = new_var
    sc.constrained_vars[new_var, new_constraint_id] = new_branch_id
    out_var_ids = [v_id for (v_id, _, _) in output_vars]
    out_branch_ids = [b_id for (_, b_id, _) in output_vars]
    sc.constrained_branches[out_branch_ids, new_constraint_id] = out_var_ids
    sc.constrained_vars[out_var_ids, new_constraint_id] = out_branch_ids

    sc.unknown_min_path_costs[new_branch_id] = sc.explained_min_path_costs[branch_id]
    sc.unknown_complexity_factors[new_branch_id] = sc.explained_complexity_factors[branch_id]
    sc.unmatched_complexities[new_branch_id] = sc.complexities[branch_id]
    # sc.related_unknown_complexity_branches[new_branch_id, :] = out_related_complexity_branches

    wrapper_block = WrapEitherBlock(block, var_id, cost, [input_var, new_var], [v_id for (v_id, _, _) in output_vars])
    wrapper_block_id = push!(sc.blocks, wrapper_block)
    target_outputs = Dict(v_id => b_id for (v_id, b_id, _) in output_vars)
    input_branches = Dict(input_var => input_branch, new_var => new_branch_id)
    return wrapper_block_id, input_branches, target_outputs
end

function create_reversed_block(sc, p::Program, context, input_var::Tuple{Int,Int}, cost)
    reverse_results = try_get_reversed_values(sc, p, context, input_var[2], cost, true)

    if !isnothing(reverse_results)
        new_p, reverse_program, output_vars, either_var_ids, either_branch_ids = reverse_results
        block =
            ReverseProgramBlock(new_p, reverse_program, cost, [input_var[1]], [v_id for (v_id, _, _) in output_vars])
        if isempty(either_var_ids)
            block_id = push!(sc.blocks, block)
            return [(
                block_id,
                Dict(input_var[1] => input_var[2]),
                Dict(v_id => b_id for (v_id, b_id, _) in output_vars),
            )]
        else
            results = []
            for (var_id, branch_id) in zip(either_var_ids, either_branch_ids)
                push!(
                    results,
                    create_wrapping_block(sc, block, cost, input_var[1], input_var[2], output_vars, var_id, branch_id),
                )
            end
            return results
        end
    end
end

function try_run_function(f, xs)
    try
        f(xs...)
    catch e
        #  We have to be a bit careful with exceptions if the
        #     synthesized program generated an exception, then we just
        #     terminate w/ false but if the enumeration timeout was
        #     triggered during program evaluation, we need to pass the
        #     exception on
        if isa(e, InterruptException)
            rethrow()
        elseif isa(e, UnknownPrimitive)
            error("Unknown primitive: $(e.name)")
        elseif isa(e, MethodError)
            @error(xs)
            @error(workspace)
            rethrow()
        else
            # @error e
            return nothing
        end
    end
end

function try_evaluate_program(p, xs, workspace)
    try_run_function(run_analyzed_with_arguments, [p, xs, workspace])
end

function try_run_block(sc::SolutionContext, block::ProgramBlock, fixed_branches, target_output)
    inputs = []
    for _ in 1:sc.example_count
        push!(inputs, Dict())
    end
    for var_id in block.input_vars
        fixed_branch_id = fixed_branches[var_id]
        entry = sc.entries[sc.branch_entries[fixed_branch_id]]
        for (i, input) in enumerate(entry.values)
            inputs[i][var_id] = input
        end
    end

    out_branch_id = target_output[block.output_var]
    expected_output = sc.entries[sc.branch_entries[out_branch_id]]
    out_matcher = get_matching_seq(expected_output)

    bm = Strict
    outs = []
    for (xs, matcher) in zip(inputs, out_matcher)
        out_value = try
            try_evaluate_program(block.analized_p, [], xs)
        catch e
            @error xs
            @error block.p
            rethrow()
        end
        if isnothing(out_value)
            return NoMatch, []
        end
        m = matcher(out_value)
        if m == NoMatch
            return NoMatch, []
        else
            bm = min(bm, m)
        end
        push!(outs, out_value)
    end
    new_out_branches, is_new_next_block, allow_fails, next_blocks, set_explained =
        value_updates(sc, block, target_output, outs, fixed_branches)
    return bm, new_out_branches, is_new_next_block, allow_fails, next_blocks, set_explained
end

function try_run_block(sc::SolutionContext, block::ReverseProgramBlock, fixed_branches, target_output)
    inputs = []
    for var_id in block.input_vars
        fixed_branch_id = fixed_branches[var_id]
        entry = sc.entries[sc.branch_entries[fixed_branch_id]]
        push!(inputs, entry.values)
    end
    bm = Strict
    out_matchers = []
    out_branches = []

    for var_id in block.output_vars
        out_branch_id = target_output[var_id]
        push!(out_branches, out_branch_id)
        expected_output = sc.entries[sc.branch_entries[out_branch_id]]
        out_matcher = get_matching_seq(expected_output)
        push!(out_matchers, out_matcher)
    end

    outs = []
    input_vals = zip(inputs...)

    for (xs, matchers) in zip(input_vals, zip(out_matchers...))
        out_values = try
            try_run_function(block.reverse_program, xs)
        catch e
            @error xs
            @error block.p
            rethrow()
        end
        if isnothing(out_values)
            return NoMatch, []
        end
        for (out_value, matcher) in zip(out_values, matchers)
            m = matcher(out_value)
            if m == NoMatch
                return NoMatch, []
            else
                bm = min(bm, m)
            end
        end
        push!(outs, out_values)
    end
    new_out_branches, is_new_next_block, allow_fails, next_blocks, set_explained =
        value_updates(sc, block, target_output, outs, fixed_branches)

    return bm, new_out_branches, is_new_next_block, allow_fails, next_blocks, set_explained
end

function try_run_block(sc::SolutionContext, block::WrapEitherBlock, fixed_branches, target_output)
    inputs = []
    main_block = block.main_block
    for var_id in main_block.input_vars
        fixed_branch_id = fixed_branches[var_id]
        entry = sc.entries[sc.branch_entries[fixed_branch_id]]
        push!(inputs, entry.values)
    end
    bm = Strict
    out_matchers = []
    out_branches = []

    for var_id in main_block.output_vars
        out_branch_id = target_output[var_id]
        push!(out_branches, out_branch_id)
        expected_output = sc.entries[sc.branch_entries[out_branch_id]]
        out_matcher = get_matching_seq(expected_output)
        push!(out_matchers, out_matcher)
    end

    outs = []
    input_vals = zip(inputs...)

    for xs in input_vals
        out_values = try
            try_run_function(main_block.reverse_program, xs)
        catch e
            @error xs
            @error main_block.p
            rethrow()
        end
        if isnothing(out_values)
            return NoMatch, []
        end
        push!(outs, out_values)
    end
    targets = Dict(out_var => collect(values) for (out_var, values) in zip(main_block.output_vars, zip(outs...)))
    fixer_branch_id = fixed_branches[block.input_vars[2]]
    fixer_entry = sc.entries[sc.branch_entries[fixer_branch_id]]

    fixed_hashes =
        [_get_fixed_hashes(options, value) for (options, value) in zip(targets[block.fixer_var], fixer_entry.values)]

    fixed_values = Dict()
    for (var_id, target_values) in targets
        if var_id == block.fixer_var
            fixed_values[var_id] = fixer_entry.values
        else
            fixed_values[var_id] = _fix_option_hashes(fixed_hashes, target_values)
        end
        out_branch_id = target_output[var_id]
        expected_output = sc.entries[sc.branch_entries[out_branch_id]]
        out_matcher = get_matching_seq(expected_output)
        for (out_value, matcher) in zip(fixed_values[var_id], out_matcher)
            m = matcher(out_value)
            if m == NoMatch
                return NoMatch, []
            else
                bm = min(bm, m)
            end
        end
    end
    outputs = collect(zip([fixed_values[v_id] for v_id in block.output_vars]...))
    new_out_branches, is_new_next_block, allow_fails, next_blocks, set_explained =
        value_updates(sc, block, target_output, outputs, fixed_branches)

    return bm, new_out_branches, is_new_next_block, allow_fails, next_blocks, set_explained
end

function try_run_block_with_downstream(
    sc::SolutionContext,
    block_id,
    fixed_branches,
    target_output,
    is_new_block,
    created_paths,
)
    if sc.verbose
        @info "Running $block_id $(sc.blocks[block_id]) with inputs $fixed_branches and output $target_output"
    end
    # @info fixed_branches
    block = sc.blocks[block_id]
    result = try_run_block(sc, block, fixed_branches, target_output)
    # @info result
    if isnothing(result) || result[1] == NoMatch
        return NoMatch
    else
        bm, out_branches, is_new_next_block, allow_fails, next_blocks, set_explained = result
        # @info target_output
        # @info out_branches

        # @info "Is new block $is_new_block is new next block $is_new_next_block set explained $set_explained"

        block_created_paths =
            get_new_paths_for_block(sc, block_id, is_new_block, created_paths, out_branches, fixed_branches)
        new_paths = merge(created_paths, block_created_paths)

        if is_new_block
            _save_block_branch_connections(sc, block_id, block, fixed_branches, Int[b_id for (_, b_id) in out_branches])
        end
        if is_new_block || set_explained
            update_complexity_factors_known(sc, block, fixed_branches, out_branches)
        end

        for (b_id, downstream_branches, downstream_target) in next_blocks
            next_block = sc.blocks[b_id]
            if !have_valid_paths(sc, [downstream_branches[v_id] for v_id in next_block.input_vars])
                continue
            end
            down_match = try_run_block_with_downstream(
                sc,
                b_id,
                downstream_branches,
                downstream_target,
                is_new_next_block,
                new_paths,
            )
            if down_match == NoMatch
                if allow_fails
                    continue
                else
                    return NoMatch
                end
            else
                bm = min(down_match, bm)
            end
        end

        return bm
    end
end

function add_new_block(sc::SolutionContext, block_id, inputs, target_output)
    # assert_context_consistency(sc)
    if sc.verbose
        @info "Adding block $block_id $(sc.blocks[block_id]) $inputs $target_output"
    end
    block = sc.blocks[block_id]
    update_prev_follow_vars(sc, block)
    if all(sc.branch_is_explained[branch_id] for (var_id, branch_id) in inputs)
        if length(inputs) > 1
            error("Not implemented, fix active constraints")
        end
        best_match = try_run_block_with_downstream(sc, block_id, inputs, target_output, true, Dict())
        # assert_context_consistency(sc)
        if best_match == NoMatch
            return nothing
        else
            if sc.verbose
                @info "Inserted block $block_id"
            end
            result = update_context(sc)
            assert_context_consistency(sc)
            return result
        end
    else
        _save_block_branch_connections(sc, block_id, block, inputs, Int[b_id for (_, b_id) in target_output])
        if all(sc.branch_is_unknown[branch_id] for (var_id, branch_id) in inputs)
            update_complexity_factors_unknown(sc, inputs, target_output[block.output_var])
        else
            # error("Not implemented")
        end
        if sc.verbose
            @info "Inserted block $block_id"
        end
        result = update_context(sc)
        assert_context_consistency(sc)
        return result
    end
end

include("extract_solution.jl")

struct HitResult
    hit_program::String
    hit_prior::Any
    hit_likelihood::Any
    hit_time::Any
end

Base.hash(r::HitResult, h::UInt64) = hash(r.hit_program, h)
Base.:(==)(r1::HitResult, r2::HitResult) = r1.hit_program == r2.hit_program

function enqueue_updates(sc::SolutionContext, g)
    assert_context_consistency(sc)
    new_unknown_branches = Set(get_new_values(sc.branch_is_unknown))
    new_explained_branches = Set(get_new_values(sc.branch_is_not_copy))
    updated_factors_unknown_branches = Set(get_new_values(sc.unknown_complexity_factors))
    updated_factors_explained_branches = Set(get_new_values(sc.explained_complexity_factors))
    for branch_id in updated_factors_unknown_branches
        if in(branch_id, new_unknown_branches)
            enqueue_unknown_var(sc, branch_id, g)
        else
            update_branch_priority(sc, branch_id, false)
        end
    end
    for branch_id in union(updated_factors_explained_branches, new_explained_branches)
        if !sc.branch_is_not_copy[branch_id]
            continue
        end
        if !haskey(sc.branch_queues_explained, branch_id)
            enqueue_known_var(sc, branch_id, g)
        else
            update_branch_priority(sc, branch_id, true)
        end
    end
    assert_context_consistency(sc)
end

function enumeration_iteration_finished_input(sc, bp)
    state = bp.state
    if bp.reverse
        # @info "Try get reversed for $bp"
        abstractor_results = create_reversed_block(sc, state.skeleton, state.context, bp.output_var, state.cost)
        return abstractor_results
    else
        arg_types = [sc.types[reduce(any, sc.branch_types[branch_id, :])] for (_, branch_id) in bp.input_vars]
        p_type = arrow(arg_types..., return_of_type(bp.request))
        new_block = ProgramBlock(
            state.skeleton,
            p_type,
            state.cost,
            [v_id for (v_id, _) in bp.input_vars],
            bp.output_var[1],
            false,
        )
        new_block_id = push!(sc.blocks, new_block)
        input_branches = Dict(var_id => branch_id for (var_id, branch_id) in bp.input_vars)
        target_output = Dict(bp.output_var[1] => bp.output_var[2])
        return [(new_block_id, input_branches, target_output)]
    end
end

function enumeration_iteration_finished_output(sc::SolutionContext, bp::BlockPrototype)
    state = bp.state
    is_reverse = is_reversible(state.skeleton)
    if is_reverse
        # @info "Try get reversed for $bp"
        abstractor_results = try_get_reversed_inputs(sc, state.skeleton, state.context, bp.output_var[2], state.cost)
        if !isnothing(abstractor_results)
            p, input_vars = abstractor_results
        else
            return
        end
    elseif isnothing(bp.input_vars)
        p, new_vars = capture_free_vars(sc, state.skeleton, state.context)
        input_vars = []
        output_branch_id = bp.output_var[2]
        min_path_cost = sc.unknown_min_path_costs[output_branch_id] + state.cost
        complexity_factor = sc.unknown_complexity_factors[output_branch_id]
        for (var_id, t) in new_vars
            t_id = push!(sc.types, t)
            entry = NoDataEntry(t_id)
            entry_index = push!(sc.entries, entry)
            branch_id = increment!(sc.branches_count)
            sc.branch_entries[branch_id] = entry_index
            sc.branch_vars[branch_id] = var_id
            sc.branch_types[branch_id, t_id] = t_id
            sc.branch_is_unknown[branch_id] = true
            sc.branch_unknown_from_output[branch_id] = sc.branch_unknown_from_output[output_branch_id]
            sc.unknown_min_path_costs[branch_id] = min_path_cost
            sc.unknown_complexity_factors[branch_id] = complexity_factor

            push!(input_vars, (var_id, branch_id, t_id))
        end
        constrained_branches = [b_id for (_, b_id, t_id) in input_vars if is_polymorphic(sc.types[t_id])]
        constrained_vars = [v_id for (v_id, _, t_id) in input_vars if is_polymorphic(sc.types[t_id])]
        if length(constrained_branches) >= 2
            context_id = push!(sc.constraint_contexts, state.context)
            new_constraint_id = increment!(sc.constraints_count)
            # @info "Added new constraint with type only $new_constraint_id"
            sc.constrained_branches[constrained_branches, new_constraint_id] = constrained_vars
            sc.constrained_vars[constrained_vars, new_constraint_id] = constrained_branches
            sc.constrained_contexts[new_constraint_id] = context_id
        end
    else
        p = state.skeleton
        input_vars =
            [(var_id, branch_id, reduce(any, sc.branch_types[branch_id, :])) for (var_id, branch_id) in bp.input_vars]
    end
    arg_types = [sc.types[v[3]] for v in input_vars]
    if isempty(arg_types)
        p_type = return_of_type(bp.request)
    else
        p_type = arrow(arg_types..., return_of_type(bp.request))
    end
    input_branches = Dict(var_id => branch_id for (var_id, branch_id, _) in input_vars)
    new_block =
        ProgramBlock(p, p_type, state.cost, [var_id for (var_id, _, _) in input_vars], bp.output_var[1], is_reverse)
    block_id = push!(sc.blocks, new_block)
    return [(block_id, input_branches, Dict(bp.output_var[1] => bp.output_var[2]))]
end

function enumeration_iteration_finished(sc::SolutionContext, finalizer, g, bp::BlockPrototype, br_id)
    if sc.branch_is_unknown[br_id]
        new_block_result = enumeration_iteration_finished_output(sc, bp)
    else
        new_block_result = enumeration_iteration_finished_input(sc, bp)
    end
    ok = true
    if !isnothing(new_block_result)
        for (new_block_id, input_branches, target_output) in new_block_result
            new_solution_paths = add_new_block(sc, new_block_id, input_branches, target_output)
            if !isnothing(new_solution_paths)
                # @info "Got results $new_solution_paths"
                for solution_path in new_solution_paths
                    solution, cost = extract_solution(sc, solution_path)
                    # @info "Got solution $solution with cost $cost"
                    finalizer(solution, cost)
                end
            else
                ok = false
                break
            end
        end
    else
        ok = false
    end
    return ok
end

function enumeration_iteration(
    run_context,
    sc::SolutionContext,
    finalizer,
    maxFreeParameters,
    g,
    q,
    bp::BlockPrototype,
    br_id,
    is_explained,
)
    if is_reversible(bp.state.skeleton) || state_finished(bp.state)
        if sc.verbose
            @info "Checking finished $bp"
        end
        if is_block_loops(sc, bp)
            # @info "Block $bp creates a loop"
            ok = false
        else
            ok = @run_with_timeout run_context["program_timeout"] run_context["redis"] enumeration_iteration_finished(
                sc,
                finalizer,
                g,
                bp,
                br_id,
            )
            if isnothing(ok)
                ok = false
            end
        end
        if ok
            enqueue_updates(sc, g)
            sc.total_number_of_enumerated_programs += 1
            save_changes!(sc)
        else
            drop_changes!(sc)
        end
    else
        for child in block_state_successors(maxFreeParameters, g, bp.state)
            _, new_request = apply_context(child.context, bp.request)
            q[BlockPrototype(child, new_request, bp.input_vars, bp.output_var, bp.reverse)] = child.cost
        end
    end
    update_branch_priority(sc, br_id, is_explained)
end

function enumerate_for_task(run_context, g::ContextualGrammar, type_weights, task, maximum_frontier, verbose = false)
    #    Returns, for each task, (program,logPrior) as well as the total number of enumerated programs
    enumeration_timeout = get_enumeration_timeout(run_context["timeout"])
    run_context["timeout_checker"] = () -> enumeration_timed_out(enumeration_timeout)

    sc = create_starting_context(task, type_weights, verbose)

    # Store the hits in a priority queue
    # We will only ever maintain maximumFrontier best solutions
    hits = PriorityQueue()

    maxFreeParameters = 2

    start_time = time()

    assert_context_consistency(sc)
    enqueue_updates(sc, g)
    save_changes!(sc)
    assert_context_consistency(sc)

    finalizer = function (solution, cost)
        ll = task.log_likelihood_checker(task, solution)
        if !isnothing(ll) && !isinf(ll)
            dt = time() - start_time
            res = HitResult(join(show_program(solution, false)), -cost, ll, dt)
            if haskey(hits, res)
                # @warn "Duplicated solution $solution"
            else
                hits[res] = -cost + ll
            end
            while length(hits) > maximum_frontier
                dequeue!(hits)
            end
        end
    end

    from_input = true

    while (!(enumeration_timed_out(enumeration_timeout))) &&
              (!isempty(sc.pq_input) || !isempty(sc.pq_output)) &&
              length(hits) < maximum_frontier
        from_input = !from_input
        pq = from_input ? sc.pq_input : sc.pq_output
        if isempty(pq)
            continue
        end
        (br_id, is_explained), pr = peek(pq)
        q = (is_explained ? sc.branch_queues_explained : sc.branch_queues_unknown)[br_id]
        bp = dequeue!(q)
        enumeration_iteration(run_context, sc, finalizer, maxFreeParameters, g, q, bp, br_id, is_explained)
    end

    @info(collect(keys(hits)))

    (collect(keys(hits)), sc.total_number_of_enumerated_programs)
end


using DataStructures

get_enumeration_timeout(timeout)::Float64 = time() + timeout
enumeration_timed_out(timeout)::Bool = time() > timeout

get_argument_requests(::Index, argument_types, cg) = [cg.variable_context for at in argument_types]
get_argument_requests(::FreeVar, argumet_types, cg) = []
get_argument_requests(::SetConst, argumet_types, cg) = []
get_argument_requests(candidate, argument_types, cg) = cg.contextual_library[candidate]

struct WrongPath <: Exception end

function follow_path(skeleton::Apply, path)
    if isempty(path)
        skeleton
    elseif isa(path[1], LeftTurn)
        follow_path(skeleton.f, view(path, 2:length(path)))
    elseif isa(path[1], RightTurn)
        follow_path(skeleton.x, view(path, 2:length(path)))
    else
        throw(WrongPath())
    end
end

function follow_path(skeleton::Abstraction, path)
    if isempty(path)
        skeleton
    elseif isa(path[1], ArgTurn)
        follow_path(skeleton.b, view(path, 2:length(path)))
    else
        throw(WrongPath())
    end
end

follow_path(skeleton::Hole, path) =
    if isempty(path)
        skeleton
    else
        throw(WrongPath())
    end

follow_path(skeleton::Program, path) =
    if isempty(path)
        skeleton
    else
        throw(WrongPath())
    end

path_environment(path) = reverse(Tp[t.type for t in path if isa(t, ArgTurn)])

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
    (1, "car", "cons"),
    (1, "car", "empty"),
    (1, "car", "repeat"),
    (1, "cdr", "cons"),
    (1, "cdr", "empty"),
    (2, "-", "0"),
    (1, "+", "+"),
    (1, "*", "*"),
    (1, "empty?", "cons"),
    (1, "empty?", "empty"),
    (1, "zero?", "0"),
    (1, "zero?", "1"),
    (1, "zero?", "-1"),
    #  bootstrap target
    (2, "map", "empty"),
    (2, "fold", "empty"),
    (2, "index", "empty"),
    (2, "index", "repeat"),
    (3, "index2", "repeat_grid"),
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
has_index(p::Hole, i) = p.candidates_filter.max_index >= i
has_index(p::Primitive, i) = false
has_index(p::Invented, i) = false
has_index(p::Apply, i) = has_index(p.f, i) || has_index(p.x, i)
has_index(p::FreeVar, i) = false
has_index(p::Abstraction, i) = has_index(p.b, i + 1)

new_free_vars_count(p::FreeVar) = isnothing(p.var_id) ? 1 : 0
new_free_vars_count(p::Abstraction) = new_free_vars_count(p.b)
new_free_vars_count(p::Apply) = new_free_vars_count(p.f) + new_free_vars_count(p.x)
new_free_vars_count(p) = 0

subprograms_equal(p1, p2, var_shift) = p1 == p2
subprograms_equal(p1::Apply, p2::Apply, var_shift) =  # TODO: new free vars count can be optimized
    subprograms_equal(p1.f, p2.f, var_shift) && subprograms_equal(p1.x, p2.x, var_shift + new_free_vars_count(p1.f))

subprograms_equal(p1::Abstraction, p2::Abstraction, var_shift) = subprograms_equal(p1.b, p2.b, var_shift)

function subprograms_equal(p1::FreeVar, p2::FreeVar, var_shift)
    if !isnothing(p1.var_id)
        return p1.var_id == p2.var_id
    end
    if !isnothing(p2.var_id)
        return p2.var_id == "r$(var_shift + 1)"
    end
    return false
end

state_violates_symmetry(p::Abstraction, var_shift = 0)::Bool =
    state_violates_symmetry(p.b, var_shift) || !has_index(p.b, 0)

function state_violates_symmetry(p::Apply, var_shift = 0)::Bool
    (f, a) = application_parse(p)
    if f == every_primitive["rev_fix_param"]
        if isa(a[1], FreeVar) || isa(a[1], Index)
            return true
        end
        if isa(a[3], Abstraction)
            a[3] = a[3].b
        end
    end
    if state_violates_symmetry(f, var_shift)
        return true
    end
    if f == every_primitive["eq?"] && _has_no_holes(a[1]) && _has_no_holes(a[2])
        if subprograms_equal(a[1], a[2], var_shift)
            return true
        end
    end
    if f == every_primitive["if"] && _has_no_holes(a[2]) && _has_no_holes(a[3])
        cond_var_shift = new_free_vars_count(a[1])
        if subprograms_equal(a[2], a[3], var_shift + cond_var_shift)
            return true
        end
    end
    var_shift += new_free_vars_count(f)
    for (n, x) in enumerate(a)
        if state_violates_symmetry(x, var_shift) || violates_symmetry(f, x, n)
            return true
        end
        var_shift += new_free_vars_count(x)
    end
    return false
end
state_violates_symmetry(::Program, var_shift = 0)::Bool = false

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

    context = state.context
    context, request = apply_context(context, request)
    if isarrow(request)
        return [
            EnumerationState(
                modify_skeleton(
                    state.skeleton,
                    (Abstraction(
                        Hole(
                            request.arguments[2],
                            current_hole.grammar,
                            CustomArgChecker(
                                current_hole.candidates_filter.should_be_reversible,
                                current_hole.candidates_filter.max_index + 1,
                                current_hole.candidates_filter.can_have_free_vars,
                                current_hole.candidates_filter.checker_function,
                            ),
                            current_hole.possible_values,
                        ),
                    )),
                    state.path,
                ),
                context,
                vcat(state.path, [ArgTurn(request.arguments[1])]),
                state.cost,
                state.free_parameters,
            ),
        ]
    else
        environment = path_environment(state.path)
        candidates = unifying_expressions(environment, context, current_hole, state.skeleton, state.path)

        states = map(candidates) do (candidate, argument_types, context, ll)
            if isa(candidate, Abstraction)
                new_free_parameters = 0
                application_template = Apply(
                    candidate,
                    Hole(argument_types[1], cg.no_context, current_hole.candidates_filter, nothing),
                )
                new_skeleton = modify_skeleton(state.skeleton, application_template, state.path)
                new_path = vcat(state.path, [LeftTurn(), ArgTurn(argument_types[1])])
            else
                new_free_parameters = number_of_free_parameters(candidate)
                argument_requests = get_argument_requests(candidate, argument_types, cg)

                if isempty(argument_types)
                    new_skeleton = modify_skeleton(state.skeleton, candidate, state.path)
                    new_path = unwind_path(state.path, new_skeleton)
                else
                    application_template = candidate
                    custom_arg_checkers = _get_custom_arg_checkers(candidate)
                    custom_checkers_args_count = length(custom_arg_checkers)
                    for i in 1:length(argument_types)
                        if i > custom_checkers_args_count
                            arg_checker = current_hole.candidates_filter
                        else
                            arg_checker = combine_arg_checkers(current_hole.candidates_filter, custom_arg_checkers[i])
                        end

                        application_template = Apply(
                            application_template,
                            Hole(argument_types[i], argument_requests[i], arg_checker, nothing),
                        )
                    end
                    new_skeleton = modify_skeleton(state.skeleton, application_template, state.path)
                    new_path = vcat(state.path, [LeftTurn() for _ in 2:length(argument_types)], [RightTurn()])
                end
            end
            return EnumerationState(
                new_skeleton,
                context,
                new_path,
                state.cost + ll,
                state.free_parameters + new_free_parameters,
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

capture_free_vars(sc::SolutionContext, p::Program, context) = _capture_free_vars(sc, p, context, [])

_capture_free_vars(sc::SolutionContext, p::Program, context, captured_vars) = p, captured_vars

function _capture_free_vars(sc::SolutionContext, p::Apply, context, captured_vars)
    new_f, captured_vars = _capture_free_vars(sc, p.f, context, captured_vars)
    new_x, captured_vars = _capture_free_vars(sc, p.x, context, captured_vars)
    Apply(new_f, new_x), captured_vars
end

function _capture_free_vars(sc::SolutionContext, p::Abstraction, context, captured_vars)
    new_b, new_vars = _capture_free_vars(sc, p.b, context, captured_vars)
    Abstraction(new_b), new_vars
end

function _capture_free_vars(sc::SolutionContext, p::Hole, context, captured_vars)
    _, t = apply_context(context, p.t)
    var_id = create_next_var(sc)
    push!(captured_vars, (var_id, t))
    FreeVar(t, var_id), captured_vars
end

function _capture_free_vars(sc::SolutionContext, p::FreeVar, context, captured_vars)
    if isnothing(p.var_id)
        _, t = apply_context(context, p.t)
        var_id = create_next_var(sc)
        push!(captured_vars, (var_id, t))
    else
        i = parse(Int, p.var_id[2:end])
        var_id, t = captured_vars[i]
    end
    FreeVar(t, var_id), captured_vars
end

function check_reversed_program_forward(p, vars, inputs, expected_output)
    if any(isa(v, EitherOptions) for v in inputs)
        either_val = first(v for v in inputs if isa(v, EitherOptions))
        hashes = keys(either_val.options)
        for (i, h) in enumerate(hashes)
            if i > 10
                break
            end
            inps = [fix_option_hashes([h], v) for v in inputs]
            exp_out = fix_option_hashes([h], expected_output)
            check_reversed_program_forward(p, vars, inps, exp_out)
        end
    elseif any(isa(v, PatternWrapper) for v in inputs)
        inps = [isa(v, PatternWrapper) ? v.value : v for v in inputs]
        check_reversed_program_forward(p, vars, inps, expected_output)
    else
        output = try
            try_evaluate_program(p, [], Dict(v_id => v for ((v_id, _), v) in zip(vars, inputs)))
        catch e
            if isa(e, InterruptException)
                rethrow()
            end
            @error(p)
            @error(vars)
            @error inputs
            @error expected_output
            @error e
            error("Can't run reversed program forward")
        end
        if output != expected_output
            @error(p)
            @error(vars)
            @error inputs
            @error output
            @error expected_output
            # error("Can't run reversed program forward")
        end
    end
end

function try_get_reversed_values(sc::SolutionContext, p::Program, context, path, output_branch_id, cost, is_known)
    out_entry = sc.entries[sc.branch_entries[output_branch_id]]

    new_p, new_vars = capture_free_vars(sc, p, context)
    new_vars_count = length(new_vars)

    calculated_values = DefaultDict(() -> [])
    for value in out_entry.values
        calculated_value = try_run_function(run_in_reverse, [new_p, value])
        if length(calculated_value) != new_vars_count
            @warn p
            @warn new_p
            @warn new_vars
            @warn value
            @warn calculated_value
        end
        # check_reversed_program_forward(new_p, new_vars, calculated_value, value)
        for (k, v) in calculated_value
            push!(calculated_values[k], v)
        end
    end

    new_entries = []
    has_abductibles = false

    for (var_id, t) in new_vars
        vals = calculated_values[var_id]
        complexity_summary = get_complexity_summary(vals, t)
        t_id = push!(sc.types, t)
        if any(isa(value, EitherOptions) for value in vals)
            new_entry = EitherEntry(t_id, vals, complexity_summary, get_complexity(sc, complexity_summary))
        elseif any(isa(value, PatternWrapper) for value in vals)
            new_entry = PatternEntry(t_id, vals, complexity_summary, get_complexity(sc, complexity_summary))
        elseif any(isa(value, AbductibleValue) for value in vals)
            has_abductibles = true
            new_entry = AbductibleEntry(t_id, vals, complexity_summary, get_complexity(sc, complexity_summary))
        else
            new_entry = ValueEntry(t_id, vals, complexity_summary, get_complexity(sc, complexity_summary))
        end
        if new_entry == out_entry
            throw(EnumerationException())
        end
        push!(new_entries, (var_id, new_entry))
    end

    complexity_factor = (is_known ? sc.explained_complexity_factors : sc.unknown_complexity_factors)[output_branch_id]
    if !has_abductibles
        complexity_factor -= out_entry.complexity - sum(entry.complexity for (_, entry) in new_entries; init = 0.0)
    end

    new_branches = []
    either_branch_ids = UInt64[]
    either_var_ids = UInt64[]
    abductible_branch_ids = UInt64[]
    abductible_var_ids = UInt64[]

    if is_known
        out_related_complexity_branches = get_connected_from(sc.related_explained_complexity_branches, output_branch_id)
    else
        out_related_complexity_branches = get_connected_from(sc.related_unknown_complexity_branches, output_branch_id)
    end

    for (var_id, entry) in new_entries
        entry_index = push!(sc.entries, entry)
        branch_id = increment!(sc.branches_count)
        sc.branch_entries[branch_id] = entry_index
        sc.branch_vars[branch_id] = var_id
        sc.branch_types[branch_id, entry.type_id] = true
        if is_known
            sc.explained_min_path_costs[branch_id] = cost + sc.explained_min_path_costs[output_branch_id]
            sc.explained_complexity_factors[branch_id] = complexity_factor
            sc.unused_explained_complexities[branch_id] = entry.complexity
            sc.added_upstream_complexities[branch_id] = sc.added_upstream_complexities[output_branch_id]
            sc.related_explained_complexity_branches[branch_id, out_related_complexity_branches] = true
        else
            sc.branch_is_unknown[branch_id] = true
            sc.branch_unknown_from_output[branch_id] = sc.branch_unknown_from_output[output_branch_id]
            sc.unknown_min_path_costs[branch_id] = cost + sc.unknown_min_path_costs[output_branch_id]
            sc.unknown_complexity_factors[branch_id] = complexity_factor
            sc.unmatched_complexities[branch_id] = entry.complexity
            sc.related_unknown_complexity_branches[branch_id, out_related_complexity_branches] = true
        end
        sc.complexities[branch_id] = entry.complexity

        if isa(entry, EitherEntry)
            push!(either_branch_ids, branch_id)
            push!(either_var_ids, var_id)
        elseif isa(entry, AbductibleEntry)
            push!(abductible_branch_ids, branch_id)
            push!(abductible_var_ids, var_id)
        end

        push!(new_branches, (var_id, branch_id, entry.type_id))
    end

    if length(new_branches) > 1
        for (_, branch_id, _) in new_branches
            inds = [b_id for (_, b_id, _) in new_branches if b_id != branch_id]
            if is_known
                sc.related_explained_complexity_branches[branch_id, inds] = true
            else
                sc.related_unknown_complexity_branches[branch_id, inds] = true
            end
        end
    end
    if length(either_branch_ids) >= 1
        active_constraints = keys(get_connected_from(sc.constrained_branches, output_branch_id))
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

    return new_p, new_branches, either_var_ids, abductible_var_ids, either_branch_ids, abductible_branch_ids
end

function try_get_reversed_inputs(sc, p::Program, context, path, output_branch_id, cost)
    new_p, inputs, _, _, _, _ = try_get_reversed_values(sc, p, context, path, output_branch_id, cost, false)
    return new_p, inputs
end

function _fill_holes(p::Hole, context)
    new_context, t = apply_context(context, p.t)
    FreeVar(t, nothing), new_context
end
function _fill_holes(p::Apply, context)
    new_f, new_context = _fill_holes(p.f, context)
    new_x, new_context = _fill_holes(p.x, new_context)
    Apply(new_f, new_x), new_context
end
function _fill_holes(p::Abstraction, context)
    new_b, new_context = _fill_holes(p.b, context)
    Abstraction(new_b), new_context
end
_fill_holes(p::Program, context) = p, context

function create_wrapping_program_prototype(
    sc::SolutionContext,
    p,
    cost,
    input_var,
    input_branch,
    output_vars,
    var_id::UInt64,
    branch_id,
    input_type,
    context,
    cg::ContextualGrammar,
)
    var_ind = findfirst(v_info -> v_info[1] == var_id, output_vars)

    unknown_type_id = [t_id for (v_id, _, t_id) in output_vars if v_id == var_id][1]

    g = cg.no_context

    candidate_functions = unifying_expressions(
        Tp[],
        context,
        Hole(input_type, g, CustomArgChecker(true, -1, false, nothing), nothing),
        Hole(input_type, g, CustomArgChecker(true, -1, false, nothing), nothing),
        [],
    )

    wrapper, arg_types, new_context, wrap_cost =
        first(v for v in candidate_functions if v[1] == every_primitive["rev_fix_param"])

    unknown_type = sc.types[unknown_type_id]
    new_context = unify(new_context, unknown_type, arg_types[2])
    new_context, fixer_type = apply_context(new_context, arg_types[3])

    unknown_entry = sc.entries[sc.branch_entries[branch_id]]
    custom_arg_checkers = _get_custom_arg_checkers(wrapper)
    filled_p, new_context = _fill_holes(p, new_context)

    wrapped_p = Apply(
        Apply(Apply(wrapper, filled_p), FreeVar(unknown_type, "r$var_ind")),
        Hole(fixer_type, cg.contextual_library[wrapper][3], custom_arg_checkers[3], unknown_entry.values),
    )

    state = EnumerationState(
        wrapped_p,
        new_context,
        [RightTurn()],
        cost + wrap_cost + 0.001,
        number_of_free_parameters(filled_p),
    )

    new_bp = BlockPrototype(state, input_type, nothing, (input_var, input_branch), true)
    return new_bp
end

function create_reversed_block(
    sc::SolutionContext,
    p::Program,
    context,
    path,
    input_var::Tuple{UInt64,UInt64},
    cost,
    input_type,
    g,
)
    new_p, output_vars, either_var_ids, abductible_var_ids, either_branch_ids, abductible_branch_ids =
        try_get_reversed_values(sc, p, context, path, input_var[2], cost, true)
    if isempty(output_vars)
        throw(EnumerationException())
    end
    block = ReverseProgramBlock(new_p, cost, [input_var[1]], [v_id for (v_id, _, _) in output_vars])
    if isempty(either_var_ids) && isempty(abductible_var_ids)
        block_id = push!(sc.blocks, block)
        return [(
            block_id,
            Dict{UInt64,UInt64}(input_var[1] => input_var[2]),
            Dict{UInt64,UInt64}(v_id => b_id for (v_id, b_id, _) in output_vars),
        )],
        []
    else
        unfinished_prototypes = []
        for (var_id, branch_id) in
            Iterators.flatten([zip(either_var_ids, either_branch_ids), zip(abductible_var_ids, abductible_branch_ids)])
            push!(
                unfinished_prototypes,
                create_wrapping_program_prototype(
                    sc,
                    p,
                    cost,
                    input_var[1],
                    input_var[2],
                    output_vars,
                    var_id,
                    branch_id,
                    input_type,
                    context,
                    g,
                ),
            )
        end
        drop_changes!(sc, sc.transaction_depth - 1)
        start_transaction!(sc, sc.transaction_depth + 1)
        return [], unfinished_prototypes
    end
end

function try_run_function(f::Function, xs)
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
            @error f
            @error(xs)
            rethrow()
        else
            # @error e
            throw(EnumerationException())
        end
    end
end

function try_evaluate_program(p, xs, workspace)
    try_run_function(run_with_arguments, [p, xs, workspace])
end

function _update_block_type(block_type, input_types)
    if !is_polymorphic(block_type)
        return block_type
    end
    context, block_type = instantiate(block_type, empty_context)
    for (arg_type, inp_type) in zip(arguments_of_type(block_type), input_types)
        context, inp_type = instantiate(inp_type, context)
        context = unify(context, arg_type, inp_type)
    end
    context, block_type = apply_context(context, block_type)
    return block_type
end

function try_run_block(
    sc::SolutionContext,
    block::ProgramBlock,
    block_id,
    fixed_branches,
    target_output,
    is_new_block,
    created_paths,
)
    inputs = []
    for _ in 1:sc.example_count
        push!(inputs, Dict())
    end
    input_types = []
    has_non_consts = false
    for var_id in block.input_vars
        fixed_branch_id = fixed_branches[var_id]
        if sc.branch_is_not_const[fixed_branch_id]
            has_non_consts = true
        end
        entry = sc.entries[sc.branch_entries[fixed_branch_id]]
        push!(input_types, sc.types[entry.type_id])
        for i in 1:sc.example_count
            inputs[i][var_id] = entry.values[i]
        end
    end
    if !has_non_consts && length(block.input_vars) > 0
        if sc.verbose
            @info "Aborting $block_id $(block.p) because all inputs are const"
        end
        throw(EnumerationException())
    end

    out_branch_id = target_output[block.output_var]
    expected_output = sc.entries[sc.branch_entries[out_branch_id]]

    outs = []
    for i in 1:sc.example_count
        xs = inputs[i]
        out_value = try
            try_evaluate_program(block.p, [], xs)
        catch e
            if !isa(e, EnumerationException)
                @error e
                @error xs
                @error block.p
            end
            rethrow()
        end
        if isnothing(out_value) || !match_at_index(expected_output, i, out_value)
            if sc.verbose
                if isnothing(out_value)
                    @info "Got nothing for $(block.p) $xs"
                else
                    @info "Can't match $out_value for $(block.p) with $expected_output at $i"
                end
            end
            throw(EnumerationException())
        end
        push!(outs, out_value)
    end
    return value_updates(
        sc,
        block,
        block_id,
        _update_block_type(block.type, input_types),
        target_output,
        outs,
        fixed_branches,
        is_new_block,
        created_paths,
    )
end

function try_run_block(
    sc::SolutionContext,
    block::ReverseProgramBlock,
    block_id,
    fixed_branches,
    target_output,
    is_new_block,
    created_paths,
)
    inputs = []

    for _ in 1:sc.example_count
        push!(inputs, [])
    end
    for var_id in block.input_vars
        fixed_branch_id = fixed_branches[var_id]
        entry = sc.entries[sc.branch_entries[fixed_branch_id]]
        for i in 1:sc.example_count
            push!(inputs[i], entry.values[i])
        end
    end

    out_entries = Dict(var_id => sc.entries[sc.branch_entries[target_output[var_id]]] for var_id in block.output_vars)

    outs = DefaultDict(() -> [])

    for i in 1:sc.example_count
        xs = inputs[i]
        out_values = try
            try_run_function(run_in_reverse, vcat([block.p], xs))
        catch e
            @error xs
            @error block.p
            rethrow()
        end
        if isnothing(out_values)
            throw(EnumerationException())
        end
        for (v_id, v) in out_values
            if !match_at_index(out_entries[v_id], i, v)
                throw(EnumerationException())
            end
            push!(outs[v_id], v)
        end
    end
    return value_updates(
        sc,
        block,
        block_id,
        target_output,
        [outs[v_id] for v_id in block.output_vars],
        fixed_branches,
        is_new_block,
        created_paths,
    )
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
        inputs = Dict(
            var_id => (
                fixed_branches[var_id],
                sc.branch_entries[fixed_branches[var_id]],
                sc.types[sc.entries[sc.branch_entries[fixed_branches[var_id]]].type_id],
                sc.branch_is_not_const[fixed_branches[var_id]],
                sc.entries[sc.branch_entries[fixed_branches[var_id]]],
            ) for var_id in sc.blocks[block_id].input_vars
        )
        outputs = Dict(
            var_id => (
                br_id,
                sc.branch_entries[br_id],
                sc.types[sc.entries[sc.branch_entries[br_id]].type_id],
                sc.entries[sc.branch_entries[br_id]],
            ) for (var_id, br_id) in target_output
        )
        @info "Running $block_id $(sc.blocks[block_id]) with inputs $inputs and output $outputs"
    end
    # @info fixed_branches
    block = sc.blocks[block_id]

    out_branches, is_new_next_block, allow_fails, next_blocks, set_explained, block_created_paths =
        try_run_block(sc, block, block_id, fixed_branches, target_output, is_new_block, created_paths)
    # @info target_output
    # @info out_branches

    if sc.verbose
        @info "Is new block $is_new_block is new next block $is_new_next_block set explained $set_explained"
        @info "Created paths for $block_id: $block_created_paths"
        @info "Next blocks: $next_blocks"
    end
    new_paths = merge(created_paths, block_created_paths)

    if is_new_block
        _save_block_branch_connections(sc, block_id, block, fixed_branches, UInt64[b_id for (_, b_id) in out_branches])
    end
    if is_new_block || set_explained
        update_complexity_factors_known(sc, block, fixed_branches, out_branches)
    end

    for (b_id, downstream_branches, downstream_target) in next_blocks
        next_block = sc.blocks[b_id]
        if !have_valid_paths(sc, [downstream_branches[v_id] for v_id in next_block.input_vars])
            continue
        end
        if allow_fails
            transaction(sc) do
                try_run_block_with_downstream(
                    sc,
                    b_id,
                    downstream_branches,
                    downstream_target,
                    is_new_next_block,
                    new_paths,
                )
            end
        else
            try_run_block_with_downstream(
                sc,
                b_id,
                downstream_branches,
                downstream_target,
                is_new_next_block,
                new_paths,
            )
        end
    end
end

function add_new_block(sc::SolutionContext, block_id, inputs, target_output)
    # assert_context_consistency(sc)
    if sc.verbose
        @info "Adding block $block_id $(sc.blocks[block_id]) $inputs $target_output"
    end
    update_prev_follow_vars(sc, block_id)
    if all(sc.branch_is_explained[branch_id] for (var_id, branch_id) in inputs)
        if length(inputs) > 1
            error("Not implemented, fix active constraints")
        end
        try_run_block_with_downstream(sc, block_id, inputs, target_output, true, Dict())
        # assert_context_consistency(sc)
    else
        block = sc.blocks[block_id]
        _save_block_branch_connections(sc, block_id, block, inputs, UInt64[b_id for (_, b_id) in target_output])
        if all(sc.branch_is_unknown[branch_id] for (var_id, branch_id) in inputs)
            update_complexity_factors_unknown(sc, inputs, target_output[block.output_var])
        else
            # error("Not implemented")
        end
    end
    if sc.verbose
        @info "Inserted block $block_id"
    end
    result = update_context(sc)
    assert_context_consistency(sc)
    return result
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
        elseif haskey(sc.branch_queues_unknown, branch_id)
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

function enumeration_iteration_finished_input(sc, bp, g)
    state = bp.state
    if bp.reverse
        # @info "Try get reversed for $bp"
        return create_reversed_block(
            sc,
            state.skeleton,
            state.context,
            state.path,
            bp.output_var,
            state.cost,
            return_of_type(bp.request),
            g,
        )
    else
        arg_types =
            [sc.types[first(get_connected_from(sc.branch_types, branch_id))] for (_, branch_id) in bp.input_vars]
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
        input_branches = Dict{UInt64,UInt64}(var_id => branch_id for (var_id, branch_id) in bp.input_vars)
        target_output = Dict{UInt64,UInt64}(bp.output_var[1] => bp.output_var[2])
        return [(new_block_id, input_branches, target_output)], []
    end
end

function enumeration_iteration_finished_output(sc::SolutionContext, bp::BlockPrototype)
    state = bp.state
    is_reverse = is_reversible(state.skeleton)
    output_branch_id = bp.output_var[2]
    output_entry = sc.entries[sc.branch_entries[output_branch_id]]
    if is_reverse &&
       !isa(output_entry, AbductibleEntry) &&
       !(isa(output_entry, PatternEntry) && all(v == PatternWrapper(any_object) for v in output_entry.values))
        # @info "Try get reversed for $bp"
        p, input_vars =
            try_get_reversed_inputs(sc, state.skeleton, state.context, state.path, bp.output_var[2], state.cost)
    elseif isnothing(bp.input_vars)
        p, new_vars = capture_free_vars(sc, state.skeleton, state.context)
        input_vars = []
        min_path_cost = sc.unknown_min_path_costs[output_branch_id] + state.cost
        complexity_factor = sc.unknown_complexity_factors[output_branch_id]
        for (var_id, t) in new_vars
            t_id = push!(sc.types, t)
            entry = NoDataEntry(t_id)
            entry_index = push!(sc.entries, entry)
            branch_id = increment!(sc.branches_count)
            sc.branch_entries[branch_id] = entry_index
            sc.branch_vars[branch_id] = var_id
            sc.branch_types[branch_id, t_id] = true
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
        input_vars = [
            (var_id, branch_id, first(get_connected_from(sc.branch_types, branch_id))) for
            (var_id, branch_id) in bp.input_vars
        ]
    end
    arg_types = [sc.types[v[3]] for v in input_vars]
    if isempty(arg_types)
        p_type = return_of_type(bp.request)
    else
        p_type = arrow(arg_types..., return_of_type(bp.request))
    end
    input_branches = Dict{UInt64,UInt64}(var_id => branch_id for (var_id, branch_id, _) in input_vars)
    new_block =
        ProgramBlock(p, p_type, state.cost, [var_id for (var_id, _, _) in input_vars], bp.output_var[1], is_reverse)
    block_id = push!(sc.blocks, new_block)
    return [(block_id, input_branches, Dict{UInt64,UInt64}(bp.output_var[1] => bp.output_var[2]))], []
end

function enumeration_iteration_finished(sc::SolutionContext, finalizer, g, bp::BlockPrototype, br_id)
    if sc.branch_is_unknown[br_id]
        new_block_result, unfinished_prototypes = enumeration_iteration_finished_output(sc, bp)
    else
        new_block_result, unfinished_prototypes = enumeration_iteration_finished_input(sc, bp, g)
    end
    for (new_block_id, input_branches, target_output) in new_block_result
        new_solution_paths = add_new_block(sc, new_block_id, input_branches, target_output)
        # @info "Got results $new_solution_paths"
        for solution_path in new_solution_paths
            solution, cost = extract_solution(sc, solution_path)
            # @info "Got solution $solution with cost $cost"
            finalizer(solution, cost)
        end
    end

    return unfinished_prototypes
end

function enumeration_iteration(
    run_context,
    sc::SolutionContext,
    finalizer,
    maxFreeParameters::Int,
    g::ContextualGrammar,
    q,
    bp::BlockPrototype,
    br_id::UInt64,
    is_explained::Bool,
)
    sc.iterations_count += 1
    if (is_reversible(bp.state.skeleton) && !isa(sc.entries[sc.branch_entries[br_id]], AbductibleEntry)) ||
       state_finished(bp.state)
        if sc.verbose
            @info "Checking finished $bp"
        end
        transaction(sc) do
            if is_block_loops(sc, bp)
                # @info "Block $bp creates a loop"
                throw(EnumerationException())
            end
            # enumeration_iteration_finished(sc, finalizer, g, bp, br_id)
            unfinished_prototypes = @run_with_timeout run_context "program_timeout" enumeration_iteration_finished(
                sc,
                finalizer,
                g,
                bp,
                br_id,
            )
            if isnothing(unfinished_prototypes)
                throw(EnumerationException())
            end
            for new_bp in unfinished_prototypes
                if sc.verbose
                    @info "Enqueing $new_bp"
                end
                q[new_bp] = new_bp.state.cost
            end
            enqueue_updates(sc, g)
            if isempty(unfinished_prototypes)
                sc.total_number_of_enumerated_programs += 1
            end
        end
    else
        if sc.verbose
            @info "Checking unfinished $bp"
        end
        for child in block_state_successors(maxFreeParameters, g, bp.state)
            _, new_request = apply_context(child.context, bp.request)
            new_bp = BlockPrototype(child, new_request, bp.input_vars, bp.output_var, bp.reverse)
            if sc.verbose
                @info "Enqueing $new_bp"
            end
            q[new_bp] = child.cost
        end
    end
    update_branch_priority(sc, br_id, is_explained)
end

function enumerate_for_task(
    run_context,
    g::ContextualGrammar,
    type_weights::Dict{String,Any},
    task::Task,
    maximum_frontier::Int,
    timeout::Int,
    verbose::Bool = false,
    need_export::Bool = false,
)
    #    Returns, for each task, (program,logPrior) as well as the total number of enumerated programs
    enumeration_timeout = get_enumeration_timeout(timeout)

    sc = create_starting_context(task, type_weights, verbose)

    # Store the hits in a priority queue
    # We will only ever maintain maximumFrontier best solutions
    hits = PriorityQueue{HitResult,Float64}()

    maxFreeParameters = 10

    start_time = time()

    assert_context_consistency(sc)
    enqueue_updates(sc, g)
    save_changes!(sc, 0)
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
        (br_id, is_explained) = draw(pq)
        q = (is_explained ? sc.branch_queues_explained : sc.branch_queues_unknown)[br_id]
        bp = dequeue!(q)
        enumeration_iteration(run_context, sc, finalizer, maxFreeParameters, g, q, bp, br_id, is_explained)
    end

    log_results(sc, hits)
    if need_export
        export_solution_context(sc, task)
    end

    (collect(keys(hits)), sc.total_number_of_enumerated_programs)
end

function log_results(sc, hits)
    @info(collect(keys(hits)))

    if sc.verbose
        @info "Branches with incoming paths $(length(sc.incoming_paths.values_stack[1]))"
        @info "Total incoming paths $(sum(length(v) for v in values(sc.incoming_paths.values_stack[1])))"
        @info "Incoming paths counts $([length(v) for v in values(sc.incoming_paths.values_stack[1])])"
        @info "Entries for incoming paths "
        for (br_id, v) in sc.incoming_paths.values_stack[1]
            @info (
                length(v),
                length(unique(v)),
                br_id,
                sc.branch_vars[br_id],
                sc.branch_entries[br_id],
                sc.entries[sc.branch_entries[br_id]],
                [sc.blocks[b_id] for (_, b_id) in get_connected_from(sc.branch_incoming_blocks, br_id)],
            )
            if length(v) != length(unique(v))
                @warn "Incoming paths for branch $br_id"
                @warn v
            end
        end
        @info "Total incoming paths length $(sum(sum(length(path.main_path) + length(path.side_vars) for path in paths; init=0) for paths in values(sc.incoming_paths.values_stack[1]); init=0))"
    end

    @info "Iterations count $(sc.iterations_count)"
    @info "Total number of valid blocks $(sc.total_number_of_enumerated_programs)"
end

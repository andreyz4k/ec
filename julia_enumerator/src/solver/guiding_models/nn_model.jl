
using Flux

struct NNGuidingModel
    model::Any
end

function NNGuidingModel()
    return NNGuidingModel(nothing)
end

function _extract_program_blocks(p::LetRevClause, blocks)
    push!(blocks, (p.inp_var_id, p.v, true))
    return _extract_program_blocks(p.b, blocks)
end

function _extract_program_blocks(p::LetClause, blocks)
    push!(blocks, (p.var_id, p.v, false))
    return _extract_program_blocks(p.b, blocks)
end

function _extract_program_blocks(p::FreeVar, blocks)
    return blocks
end

function _extract_program_blocks(p, blocks)
    push!(blocks, ("output", p, false))
    return blocks
end

function extract_program_blocks(program_str)
    p = parse_program(program_str)
    return _extract_program_blocks(p, [])
end

mutable struct LikelihoodSummary
    uses::Dict
    normalizers::Dict
    constant::Float64
end

function LikelihoodSummary()
    return LikelihoodSummary(Dict(), Dict(), 0.0)
end

function _build_likelihood_summary(
    grammar,
    full_p,
    request,
    p::SetConst,
    context,
    environment,
    checker,
    path,
    locations,
    var_types,
    summary,
)
    return context, summary
end

function _build_likelihood_summary(
    grammar,
    full_p,
    request,
    p,
    context,
    environment,
    checker,
    path,
    locations,
    var_types,
    summary,
)
    if isarrow(request)
        if !isa(p, Abstraction)
            error("Expected abstraction, got $p")
        end
        return _build_likelihood_summary(
            grammar,
            full_p,
            request.arguments[2],
            p.b,
            context,
            vcat([request.arguments[1]], environment),
            step_arg_checker(checker, ArgTurn(request.arguments[1])),
            vcat(path, [ArgTurn(request.arguments[1])]),
            locations,
            var_types,
            summary,
        )
    end

    f, xs = application_parse(p)

    candidates = []
    next_requests = nothing

    if length(path) >= 2 && isa(path[end], ArgTurn) && isa(path[end-1], LeftTurn)
        in_lambda_wrapper = true
    else
        in_lambda_wrapper = false
    end

    for (i, p) in enumerate(grammar)
        if in_lambda_wrapper && p != every_primitive["rev_fix_param"]
            continue
        end

        for (f, ind) in locations
            if violates_symmetry(f, p, ind)
                continue
            end
        end

        if !checker(p, full_p, path)
            continue
        end

        if might_unify(return_of_type(p.t), request)
            new_context, t = instantiate(p.t, context)
            new_context = unify(new_context, return_of_type(t), request)
            if isnothing(new_context)
                continue
            end
            push!(candidates, i)
            if p == f
                summary.uses[i] = get(summary.uses, i, 0) + 1

                (new_context, t) = apply_context(new_context, t)
                next_requests = (arguments_of_type(t), new_context)
            end
        end
    end

    grammar_length = length(grammar)

    if !isempty(candidates)
        lambda_context, arg_type = instantiate(t0, context)
        lambda_context, lambda_type = apply_context(lambda_context, request)
        push!(candidates, grammar_length + 2)

        if isa(f, Abstraction)
            summary.uses[grammar_length+2] = get(summary.uses, grammar_length + 2, 0) + 1
            next_requests = ([lambda_type, arg_type], lambda_context)
        end
    end

    if !in_lambda_wrapper
        variable_candidates = 0
        is_index = false
        for (j, t) in enumerate(environment)
            p = Index(j - 1)
            if !checker(p, full_p, path)
                continue
            end
            (new_context, t) = apply_context(context, t)
            return_type = return_of_type(t)
            if might_unify(return_type, request)
                new_context = unify(new_context, return_type, request)
                if isnothing(new_context)
                    continue
                end
                variable_candidates += 1

                if p == f
                    is_index = true
                    summary.uses[grammar_length+1] = get(summary.uses, grammar_length + 1, 0) + 1

                    (new_context, t) = apply_context(new_context, t)
                    next_requests = (arguments_of_type(t), new_context)
                end
            end
        end
        if variable_candidates > 0
            push!(candidates, grammar_length + 1)
            if is_index
                summary.constant -= log(variable_candidates)
            end
        end
    end

    if checker.can_have_free_vars
        free_var_candidates = 0
        is_free_var = false

        for (var_id, t) in var_types
            (new_context, t) = apply_context(context, t)
            return_type = return_of_type(t)
            if might_unify(return_type, request)
                new_context = unify(new_context, return_type, request)
                if isnothing(new_context)
                    continue
                end
                free_var_candidates += 1
                if isa(f, FreeVar) && f.var_id == var_id
                    (new_context, t) = apply_context(new_context, t)
                    var_types[f.var_id] = t
                    is_free_var = true
                    next_requests = ([], new_context)
                end
            end
        end

        if !isa(full_p, FreeVar)
            p = FreeVar(request, nothing, isempty(locations) ? nothing : locations[1])
            if checker(p, full_p, path)
                free_var_candidates += 1
                if isa(f, FreeVar) && !haskey(var_types, f.var_id)
                    var_types[f.var_id] = request
                    is_free_var = true
                    next_requests = ([], context)
                end
            end
        end

        if free_var_candidates > 0
            push!(candidates, grammar_length + 3)
            if is_free_var
                summary.uses[grammar_length+3] = get(summary.uses, grammar_length + 3, 0) + 1
                summary.constant -= log(free_var_candidates)
            end
        end
    end

    if isnothing(next_requests)
        error("$f is not in possible candidates for $request")
    end

    summary.normalizers[candidates] = get(summary.normalizers, candidates, 0) + 1

    arg_types = next_requests[1]
    context = next_requests[2]

    if isa(f, Abstraction)
        context, summary = _build_likelihood_summary(
            grammar,
            full_p,
            arg_types[1],
            f.b,
            context,
            vcat([arg_types[2]], environment),
            step_arg_checker(checker, ArgTurn(arg_types[2])),
            vcat(path, [LeftTurn(), ArgTurn(arg_types[2])]),
            locations,
            var_types,
            summary,
        )
        return _build_likelihood_summary(
            grammar,
            full_p,
            arg_types[2],
            xs[1],
            context,
            environment,
            checker,
            vcat(path, [RightTurn()]),
            [],
            var_types,
            summary,
        )
    end

    if !isempty(arg_types)
        custom_arg_checkers = _get_custom_arg_checkers(f)
        custom_checkers_args_count = length(custom_arg_checkers)

        for (i, (arg_type, x)) in enumerate(zip(arg_types, xs))
            current_checker = step_arg_checker(checker, (f, i))

            if i > custom_checkers_args_count || isnothing(custom_arg_checkers[i])
                arg_checker = current_checker
            else
                arg_checker = combine_arg_checkers(current_checker, custom_arg_checkers[i])
            end

            context, summary = _build_likelihood_summary(
                grammar,
                full_p,
                arg_type,
                x,
                context,
                environment,
                arg_checker,
                vcat(path, [LeftTurn() for _ in i+1:length(xs)], [RightTurn()]),
                [(f, i)],
                var_types,
                summary,
            )
        end
    end
    return context, summary
end

function build_likelihood_summary(grammar, request, p, is_reversed)
    summary = LikelihoodSummary()
    context, request = instantiate(request, empty_context)
    return _build_likelihood_summary(
        grammar,
        p,
        request,
        p,
        context,
        [],
        CombinedArgChecker([SimpleArgChecker(is_reversed, -1, true)]),
        [],
        [],
        Dict(),
        summary,
    )[2]
end

function expand_traces(all_traces)
    output = []
    for (grammar, gr_traces) in values(all_traces)
        for (task_name, traces) in gr_traces
            for (hit, cost) in traces
                outputs = hit.trace_values["output"]
                inputs = [v for (k, v) in hit.trace_values if isa(k, String) && k != "output"]

                blocks = extract_program_blocks(hit.hit_program)
                for (var_id, p, is_rev) in blocks
                    trace_val = hit.trace_values[var_id]
                    summary = build_likelihood_summary(grammar, trace_val[1], p, is_rev)
                    push!(output, (grammar, inputs, outputs, trace_val, is_rev, summary))
                end
            end
        end
    end
    return output
end

function update_guiding_model(guiding_model::NNGuidingModel, grammar, traces)
    return guiding_model
end


struct Grammar
    log_variable::Float64
    log_lambda::Float64
    library::Vector{Tuple{Program,Tp,Float64}}
    continuation_type::Union{Tp,Nothing}
end

struct ContextualGrammar
    no_context::Grammar
    variable_context::Grammar
    contextual_library::Dict{Program,Vector{Grammar}}
end

function deserialize_grammar(payload)
    log_variable = payload["logVariable"]
    log_lambda = payload["logLambda"]

    productions = map(payload["productions"]) do p
        source = p["expression"]
        expression = parse_program(source)
        program_type = try
            closed_inference(expression)
        catch e
            if isa(e, UnificationFailure)
                error("Could not type $source")
            else
                rethrow()
            end
        end
        log_probability = p["logProbability"]
        (expression, program_type, log_probability)
    end

    continuation_type = try
        deserialize_type(payload["continuationType"])
    catch e
        if isa(e, InterruptException)
            @warn "Interrupted"
            rethrow()
        end
        nothing
    end

    #  Successfully parsed the grammar
    Grammar(log_variable, log_lambda, productions, continuation_type)
end

function make_dummy_contextual(g::Grammar)
    contextual_library = Dict(e => [g for _ in arguments_of_type(t)] for (e, t, _) in g.library)
    cg = ContextualGrammar(g, g, contextual_library)
    prune_contextual_grammar(cg)
end

function _prune(expression, gs)
    t = closed_inference(expression)
    argument_types = arguments_of_type(t)

    map(zip(argument_types, gs)) do (arg_type, g)
        argument_type = return_of_type(arg_type)
        filtered_library = filter(g.library) do (_, child_type, _)
            child_type = return_of_type(child_type)
            try
                k, child_type = instantiate(child_type, empty_context)
                k, argument_type = instantiate(argument_type, k)
                unify(k, child_type, argument_type)
                return true
            catch e
                if isa(e, UnificationFailure)
                    return false
                else
                    rethrow()
                end
            end
        end
        Grammar(g.log_variable, g.log_lambda, filtered_library, g.continuation_type)
    end
end

function prune_contextual_grammar(g::ContextualGrammar)
    ContextualGrammar(g.no_context, g.variable_context, Dict(e => _prune(e, gs) for (e, gs) in g.contextual_library))
end

function deserialize_contextual_grammar(payload)
    no_context = deserialize_grammar(payload["noParent"])
    variable_context = deserialize_grammar(payload["variableParent"])
    contextual_library = Dict(map(payload["productions"]) do production
        source = production["program"]
        expression = parse_program(source)
        children = map(deserialize_grammar, production["arguments"])
        (expression, children)
    end)
    grammar = ContextualGrammar(no_context, variable_context, contextual_library)
    prune_contextual_grammar(grammar)
end

function lse(l::Vector{Float64})::Float64
    if length(l) == 0
        error("LSE: Empty sequence")
    elseif length(l) == 1
        return l[1]
    end
    largest = maximum(l)
    return largest + log(sum(exp(z - largest) for z in l))
end

function _get_free_var_types(p::FreeVar)
    if isnothing(p.var_id)
        return [p.t]
    else
        return []
    end
end

function _get_free_var_types(p::Apply)
    return vcat(_get_free_var_types(p.f), _get_free_var_types(p.x))
end

function _get_free_var_types(p::Abstraction)
    return _get_free_var_types(p.b)
end

function _get_free_var_types(p::Program)
    return []
end

function unifying_expressions(
    environment::Vector{Tp},
    context,
    current_hole::Hole,
    skeleton,
    path,
)::Vector{Tuple{Program,Vector{Tp},Context,Float64}}
    #  given a grammar environment requested type and typing context,
    #    what are all of the possible leaves that we might use?
    #    These could be productions in the grammar or they could be variables.
    #    Yields a sequence of:
    #    (leaf, argument types, context with leaf return type unified with requested type, normalized log likelihood)
    request = current_hole.t
    g = current_hole.grammar
    candidates_filter = current_hole.candidates_filter
    checker_function = candidates_filter.checker_function

    if length(path) >= 2 && isa(path[end], ArgTurn) && isa(path[end-1], LeftTurn)
        in_lambda_wrapper = true
    else
        in_lambda_wrapper = false
    end

    if in_lambda_wrapper
        variable_candidates = []
    else
        variable_candidates = collect(skipmissing(map(enumerate(environment)) do (j, t)
            if (j - 1) > candidates_filter.max_index
                return missing
            end
            p = Index(j - 1)
            if !isnothing(checker_function) && !checker_function(p, skeleton, path)
                return missing
            end
            ll = g.log_variable
            (new_context, t) = apply_context(context, t)
            return_type = return_of_type(t)
            if might_unify(return_type, request)
                try
                    new_context = unify(new_context, return_type, request)
                    (new_context, t) = apply_context(new_context, t)
                    return (p, arguments_of_type(t), new_context, ll)
                catch e
                    if isa(e, UnificationFailure)
                        return missing
                    else
                        rethrow()
                    end
                end
            else
                return missing
            end
        end))

        # if !isnothing(g.continuation_type) && !isempty(variable_candidates)
        #     terminal_indices = [get_index_value(p) for (p, t, _, _) in variable_candidates if isempty(t)]
        #     if !isempty(terminal_indices)
        #         smallest_terminal_index = minimum(terminal_indices)
        #         filter!(
        #             ((p, t, _, _) -> !is_index(p) || !isempty(t) || get_index_value(p) == smallest_terminal_index),
        #             variable_candidates,
        #         )
        #     end
        # end

        nv = log(length(variable_candidates))
        variable_candidates =
            Tuple{Program,Vector{Tp},Context,Float64}[(p, t, k, ll - nv) for (p, t, k, ll) in variable_candidates]
    end

    grammar_candidates = collect(
        Tuple{Program,Vector{Tp},Context,Float64},
        skipmissing(map(g.library) do (p, t, ll)
            try
                if in_lambda_wrapper && p != every_primitive["rev_fix_param"]
                    return missing
                end
                if candidates_filter.should_be_reversible && !is_reversible(p)
                    return missing
                end
                if !isnothing(checker_function) && !checker_function(p, skeleton, path)
                    return missing
                end

                if !might_unify(return_of_type(t), request)
                    return missing
                else
                    new_context, t = instantiate(t, context)
                    new_context = unify(new_context, return_of_type(t), request)
                    (new_context, t) = apply_context(new_context, t)
                    return (p, arguments_of_type(t), new_context, ll)
                end
            catch e
                if isa(e, UnificationFailure)
                    return missing
                else
                    rethrow()
                end
            end
        end),
    )

    if !isempty(grammar_candidates)
        lambda_context, arg_type = instantiate(t0, context)
        lambda_context, lambda_type = apply_context(lambda_context, request)
        lambda_candidates = [(
            Abstraction(
                Hole(
                    lambda_type,
                    g,
                    CustomArgChecker(
                        candidates_filter.should_be_reversible,
                        candidates_filter.max_index + 1,
                        candidates_filter.can_have_free_vars,
                        candidates_filter.checker_function,
                    ),
                    nothing,
                ),
            ),
            [arg_type],
            lambda_context,
            g.log_lambda,
        )]
    else
        lambda_candidates = []
    end

    candidates = vcat(variable_candidates, grammar_candidates, lambda_candidates)
    if !isempty(candidates)
        z = lse([ll for (_, _, _, ll) in candidates])
        candidates = Tuple{Program,Vector{Tp},Context,Float64}[(p, t, k, z - ll) for (p, t, k, ll) in candidates]
    end

    if candidates_filter.can_have_free_vars
        if !isa(skeleton, Hole)
            p = FreeVar(request, nothing)
            if isnothing(checker_function) || checker_function(p, skeleton, path)
                push!(candidates, (p, [], context, 0.001))
            end
        end

        for (i, t) in enumerate(_get_free_var_types(skeleton))
            (new_context, t) = apply_context(context, t)
            return_type = return_of_type(t)
            if might_unify(return_type, request)
                try
                    new_context = unify(new_context, return_type, request)
                    (new_context, t) = apply_context(new_context, t)
                    p = FreeVar(t, "r$i")
                    if isnothing(checker_function) || checker_function(p, skeleton, path)
                        push!(candidates, (p, [], new_context, 0.001))
                    end
                catch e
                    if isa(e, UnificationFailure)
                        continue
                    else
                        rethrow()
                    end
                end
            end
        end
    end

    if !isnothing(current_hole.possible_values)
        possible_values = current_hole.possible_values
        const_candidates = _const_options(possible_values[1])
        for i in 2:length(possible_values)
            const_candidates = filter(c -> _match_value(possible_values[i], c), const_candidates)
            if isempty(const_candidates)
                break
            end
        end
        for candidate in const_candidates
            p = SetConst(request, candidate)
            # if (isnothing(candidates_filter) && !current_hole.should_be_reversible) ||
            #    (!isnothing(candidates_filter) && candidates_filter(p, skeleton, path))
            if isnothing(checker_function) || checker_function(p, skeleton, path)
                push!(candidates, (p, [], context, 0.001))
            end
        end
    end

    return candidates
end

function following_expressions(g::Grammar, request)
    candidates = collect(Iterators.flatten(map(g.library) do (p, t, ll)
        output = []
        for (i, a_type) in enumerate(arguments_of_type(t))
            if might_unify(a_type, request)
                context, new_t = instantiate(t, empty_context)
                context = unify(context, arguments_of_type(new_t)[i], request)
                context, new_t = apply_context(context, new_t)
                push!(output, (p, new_t, context, ll, i))
            end
        end
        output
    end))
    if isempty(candidates)
        return []
    end
    z = lse([ll for (_, _, _, ll, _) in candidates])
    return [(p, t, k, z - ll, i) for (p, t, k, ll, i) in candidates]
end

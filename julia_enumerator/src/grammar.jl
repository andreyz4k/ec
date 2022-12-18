
struct Grammar
    log_variable::Float64
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
    catch
        nothing
    end

    #  Successfully parsed the grammar
    Grammar(log_variable, productions, continuation_type)
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
        Grammar(g.log_variable, filtered_library, g.continuation_type)
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


function unifying_expressions(
    g::Grammar,
    environment::Vector{Tp},
    request::Tp,
    context,
    abstractors_only,
)::Vector{Tuple{Program,Vector{Tp},Context,Float64}}
    #  given a grammar environment requested type and typing context,
    #    what are all of the possible leaves that we might use?
    #    These could be productions in the grammar or they could be variables.
    #    Yields a sequence of:
    #    (leaf, argument types, context with leaf return type unified with requested type, normalized log likelihood)

    if abstractors_only
        variable_candidates = []
    else
        variable_candidates = collect(skipmissing(map(enumerate(environment)) do (j, t)
            p = Index(j - 1)
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

        if !isnothing(g.continuation_type) && !isempty(variable_candidates)
            terminal_indices = [get_index_value(p) for (p, t, _, _) in variable_candidates if isempty(t)]
            if !isempty(terminal_indices)
                smallest_terminal_index = minimum(terminal_indices)
                filter!(
                    ((p, t, _, _) -> !is_index(p) || !isempty(t) || get_index_value(p) == smallest_terminal_index),
                    variable_candidates,
                )
            end
        end

        nv = log(length(variable_candidates))
        variable_candidates = [(p, t, k, ll - nv) for (p, t, k, ll) in variable_candidates]
    end

    grammar_candidates = collect(skipmissing(map(g.library) do (p, t, ll)
        try
            if abstractors_only && !haskey(all_abstractors, p)
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
    end))

    candidates = vcat(variable_candidates, grammar_candidates)
    if isempty(candidates)
        return []
    end
    z = lse([ll for (_, _, _, ll) in candidates])
    return [(p, t, k, z - ll) for (p, t, k, ll) in candidates]
end

function following_expressions(g::Grammar, request)
    candidates = collect(flatten(map(g.library) do (p, t, ll)
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

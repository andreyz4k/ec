
using Flux
using NNlib

using Metal

alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789[](){},.;#?_+-*\$=> "

d_gr = 64
d_in = 64
d_out = 64
d_val = 64

d_state_in = d_gr + d_in + d_out + d_val + 1
d_state_h = 128
d_state_out = 64

d_dec_h = 64

struct GrammarEncoder
    model::Any
end

function GrammarEncoder()
    return GrammarEncoder(LSTM(length(alphabet), d_gr))
end

function (m::GrammarEncoder)(f_embs)
    hcat([
        begin
            Flux.reset!(m.model)
            [m.model(x) for x in f_emb][end]
        end for f_emb in f_embs
    ]...)
end

Flux.@layer GrammarEncoder

struct InputEncoder
    model::Any
end

function InputEncoder()
    return InputEncoder(LSTM(length(alphabet), d_in))
end

function (m::InputEncoder)(x_embs)
    embs = hcat([
        begin
            Flux.reset!(m.model)
            [m.model(x) for x in x_emb][end]
        end for x_emb in x_embs
    ]...)
    logsumexp(embs, dims = 2)
end

Flux.@layer InputEncoder

struct OutputEncoder
    model::Any
end

function OutputEncoder()
    return OutputEncoder(LSTM(length(alphabet), d_out))
end

function (m::OutputEncoder)(y_emb)
    Flux.reset!(m.model)
    [m.model(y) for y in y_emb][end]
end

Flux.@layer OutputEncoder

struct ValueEncoder
    model::Any
end

function ValueEncoder()
    return ValueEncoder(LSTM(length(alphabet), d_val))
end

function (m::ValueEncoder)(v_emb)
    Flux.reset!(m.model)
    [m.model(v) for v in v_emb][end]
end

Flux.@layer ValueEncoder

struct NNGuidingModel
    grammar_encoder::GrammarEncoder
    input_encoder::InputEncoder
    output_encoder::OutputEncoder
    value_encoder::ValueEncoder
    state_processor::Chain
    decoder::Chain
end

function NNGuidingModel()
    grammar_encoder = GrammarEncoder()
    input_encoder = InputEncoder()
    output_encoder = OutputEncoder()
    value_encoder = ValueEncoder()
    state_processor = Chain(Dense(d_state_in, d_state_h, relu), Dense(d_state_h, d_state_out, relu)) |> gpu
    decoder = Chain(Dense(d_state_out + d_gr, d_dec_h, relu), Dense(d_dec_h, 1)) |> gpu
    return NNGuidingModel(grammar_encoder, input_encoder, output_encoder, value_encoder, state_processor, decoder)
end

function (m::NNGuidingModel)(inps)
    f_embs, x_embs, y_embs, v_embs, is_reversed = inps
    f_emb = m.grammar_encoder(f_embs) |> gpu
    gr_embs = logsumexp(f_emb, dims = 2)

    x_emb = m.input_encoder(x_embs) |> gpu
    y_emb = m.output_encoder(y_embs) |> gpu
    v_emb = m.value_encoder(v_embs) |> gpu
    state_emb = vcat(gr_embs, x_emb, y_emb, v_emb, is_reversed)
    state = m.state_processor(state_emb)
    return m.decoder(vcat(upsample_nearest(reshape(state, size(state, 1), 1), (1, size(f_emb, 2))), f_emb))
end

Flux.@layer NNGuidingModel

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
    constant::Float32
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

function _preprocess_summary(summary::LikelihoodSummary, grammar_length)
    uses = zeros(Float32, grammar_length)
    for (i, count) in summary.uses
        uses[i] = count
    end
    mask = fill(-Inf32, length(summary.normalizers), grammar_length)
    N = zeros(Float32, length(summary.normalizers))
    for (i, (norm_set, count)) in enumerate(summary.normalizers)
        N[i] = count
        mask[i, norm_set] .= 0
    end
    return (uses, mask, N, summary.constant)
end

function build_likelihood_summary(grammar, request, p, is_reversed)
    summary = LikelihoodSummary()
    context, request = instantiate(request, empty_context)
    _, summary = _build_likelihood_summary(
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
    )
    return _preprocess_summary(summary, length(grammar) + 3)
end

using Flux: onehot
tokenise(s) = [onehot(c, alphabet) for c in string(s)]

function expand_traces(all_traces)
    output = []
    for (grammar, gr_traces) in values(all_traces)
        grammar_emb = vcat([tokenise(p) for p in grammar], [tokenise("\$0"), tokenise("lambda"), tokenise("\$v1")])
        for (task_name, traces) in gr_traces
            for (hit, cost) in traces
                outputs = tokenise(hit.trace_values["output"])
                inputs = [tokenise(v) for (k, v) in hit.trace_values if isa(k, String) && k != "output"]

                blocks = extract_program_blocks(hit.hit_program)
                for (var_id, p, is_rev) in blocks
                    trace_val = hit.trace_values[var_id]
                    summary = build_likelihood_summary(grammar, trace_val[1], p, is_rev)
                    push!(output, ((grammar_emb, inputs, outputs, tokenise(trace_val), is_rev), summary))
                end
            end
        end
    end
    return output
end

function loss(result, summary)
    uses, mask, N, constant = summary
    uses = uses |> gpu
    mask = mask |> gpu
    N = N |> gpu
    constant = constant |> gpu
    # result = result |> gpu
    numenator = sum(result .* uses) + constant

    z = (mask .+ repeat(result, size(mask, 1), 1))
    z = logsumexp(z, dims = 2)
    denominator = sum(N .* z)
    return denominator - numenator
end

using ProgressMeter

function update_guiding_model(guiding_model::NNGuidingModel, traces)
    train_set = expand_traces(traces)

    opt_state = Flux.setup(Adam(0.001, (0.9, 0.999), 1e-8), guiding_model)

    @showprogress for data in train_set
        # Unpack this element (for supervised training):
        input, summary = data

        # Calculate the gradient of the objective
        # with respect to the parameters within the model:
        grads = Flux.gradient(guiding_model) do m
            result = m(input)
            loss(result, summary)
        end

        # Update the parameters so as to reduce the objective,
        # according the chosen optimisation rule:
        Flux.update!(opt_state, guiding_model, grads[1])
    end

    return guiding_model
end

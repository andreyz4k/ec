
using Flux
using NNlib

using Transformers

# alphabet = collect("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789[](){},.;#?_+-*\$=> ")

d_emb = 384

d_state_in = d_emb * 4 + 1
d_state_h = 512
d_state_out = 384

d_dec_h = 64
head_num = 4

using Transformers.TextEncoders

vocab = vcat(
    ["pr_$n" for (n, p) in every_primitive],
    [string(i) for i in 0:9],
    ["i$i" for i in 0:9],
    ["v$i" for i in 0:9],
    [" $i" for i in 0:9],
    ["c$i" for i in 0:9],
    [
        "(",
        ")",
        "\$",
        "\$v",
        "lambda",
        "inp",
        "SetConst",
        "#",
        "[",
        "]",
        ";",
        ",",
        "any_object",
        "[[",
        "]]",
        "{",
        "}",
        "EitherOptions(",
        "PatternWrapper(",
        "AbductibleValue(",
    ],
)

tokenize(p::Primitive) = ["pr_$p"]
tokenize(p::Abstraction) = vcat(["(", "lambda"], tokenize(p.b), [")"])
tokenize(p::Index) = vcat(["\$"], ["i$s" for s in split(string(p), "")])
function tokenize(p::FreeVar)
    if isa(p.var_id, String)
        if startswith(p.var_id, "inp")
            vcat(["\$v", "inp"], ["v$s" for s in split(string(p), "")[4:end]])
        else
            error("Unknown free var id: $(p.var_id)")
        end
    else
        vcat(["\$v"], ["v$s" for s in split(string(p), "")])
    end
end
tokenize(p::Apply) = vcat(["("], tokenize(p.f), tokenize(p.x), [")"])
tokenize(p::SetConst) = vcat(["SetConst"], tokenize(p.t, p.value))
tokenize(p::Invented) = vcat(["#"], tokenize(p.b))

function tokenize(t::Tp, v::Int)
    if t == tint
        chars = split(string(v), "")
        return vcat([" $(chars[1])"], chars[2:end])
    elseif t == tcolor
        return ["c$v"]
    else
        error("Unknown type for int: $t")
    end
end
tokenize(t, v::AnyObject) = ["any_object"]

function tokenize(t, v::Vector, is_top = false)
    tokens = ["["]
    for (i, x) in enumerate(v)
        if i > 1
            push!(tokens, ",")
        end
        if is_top
            append!(tokens, tokenize(t, x))
        else
            append!(tokens, tokenize(t.arguments[1], x))
        end
    end
    push!(tokens, "]")
    return tokens
end

function tokenize(t, v::Set, is_top = false)
    tokens = ["{"]
    for (i, x) in enumerate(v)
        if i > 1
            push!(tokens, ",")
        end
        if is_top
            append!(tokens, tokenize(t, x))
        else
            append!(tokens, tokenize(t.arguments[1], x))
        end
    end
    push!(tokens, "}")
    return tokens
end

function tokenize(t::TypeConstructor, v::Matrix)
    tokens = ["[["]
    for i in 1:size(v, 1)
        if i > 1
            push!(tokens, ";")
        end
        for j in 1:size(v, 2)
            if j > 1
                push!(tokens, ",")
            end
            append!(tokens, tokenize(t.arguments[1], v[i, j]))
        end
    end
    push!(tokens, "]]")
    return tokens
end
tokenize(t::TypeConstructor, v::Tuple) =
    vcat(["("], tokenize(t.arguments[1], v[1]), [","], tokenize(t.arguments[2], v[2]), [")"])

function tokenize(t, v::EitherOptions)
    tokens = ["EitherOptions("]
    for (i, (_, x)) in enumerate(v.options)
        if i > 1
            push!(tokens, ",")
        end
        append!(tokens, tokenize(t, x))
    end
    push!(tokens, ")")
    return tokens
end
tokenize(t, v::PatternWrapper) = vcat(["PatternWrapper("], tokenize(t, v.value), [")"])
tokenize(t, v::AbductibleValue) = vcat(["AbductibleValue("], tokenize(t, v.value), [")"])

annotate_objects(x) = TextEncoders.TextEncodeBase.Sentence(x)
annotate_objects(x::Vector) = TextEncoders.TextEncodeBase.Batch{TextEncoders.TextEncodeBase.Sentence}(x)

Base.isempty(::Program) = false
struct ExpCoderTokenization <: TextEncoders.AbstractTokenization end

TextEncoders.TextEncodeBase.splittability(::ExpCoderTokenization, w::TextEncoders.TextEncodeBase.Sentence) =
    TextEncoders.TextEncodeBase.Splittable()
TextEncoders.TextEncodeBase.splittability(::ExpCoderTokenization, ::TextEncoders.TextEncodeBase.Batch) =
    TextEncoders.TextEncodeBase.Splittable()

function TextEncoders.TextEncodeBase.splitting(::ExpCoderTokenization, s::TextEncoders.TextEncodeBase.Batch)
    s.x
end
function TextEncoders.TextEncodeBase.splitting(::ExpCoderTokenization, x::TextEncoders.TextEncodeBase.Sentence)
    val = TextEncoders.TextEncodeBase.getvalue(x)
    if isa(val, Program)
        tokens = tokenize(val)
    elseif isa(val, Tuple)
        tokens = tokenize(val..., true)
    elseif isa(val, Dict)
        tokens = vcat([tokenize(v..., true) for (_, v) in val]...)
    elseif isa(val, String)
        tokens = [val]
    else
        error("Unknown type for tokenization: $val")
    end
    tokens = [TextEncoders.TextEncodeBase.Token(t) for t in tokens]
    return tokens
end

TextEncoders.TextEncodeBase.wrap(::ExpCoderTokenization, b::TextEncoders.TextEncodeBase.Batch{S}, x) where {S} =
    S(x, TextEncoders.TextEncodeBase.getmeta(b))
TextEncoders.TextEncodeBase.wrap(::ExpCoderTokenization, t::TextEncoders.TextEncodeBase.TokenStage) = t

struct Embedder
    embedder::Any
    encoder::Any
end

using Transformers.HuggingFace

using Transformers.Layers

function Embedder()
    embedder = Chain(
        Layers.CompositeEmbedding(
            token = Embed(d_emb, length(vocab) + 4),
            position = Layers.ApplyEmbed(.+, SinCosPositionEmbed(d_emb)),
            segment = Layers.ApplyEmbed(.+, Embed(d_emb, 2), Transformers.HuggingFace.bert_ones_like),
        ),
        Layers.DropoutLayer(LayerNorm(d_emb, ϵ = 1.0e-12), nothing),
    )
    encoder = Transformer(TransformerBlock, 2, head_num, d_emb, d_emb ÷ head_num, d_emb)

    return Embedder(embedder, encoder)
end

function (e::Embedder)(inputs)
    @time embs = e.embedder(inputs)
    @time outputs = e.encoder(embs)
    while any(isnan, outputs.hidden_state)
        @info "NaN detected in encoder output, retrying"
        @time outputs = e.encoder(embs)
    end

    @time pooled = outputs.hidden_state[:, 1, :]

    return pooled
end

function Base.show(io::IO, e::Embedder)
    print(io, "Embedder(", e.embedder, ", ", e.encoder, ", ", e.pooler, ")")
end
Flux.@layer Embedder

struct GrammarEncoder end

function (m::GrammarEncoder)(func_encodings)
    grammar_encoding = sum(func_encodings, dims = 2) ./ size(func_encodings, 2)

    return grammar_encoding
end

Flux.@layer GrammarEncoder

struct NNGuidingModel
    tokenizer::Any
    embedder::Embedder
    grammar_encoder::GrammarEncoder

    state_processor::Chain
    decoder::Chain

    contextual_cache::Dict
end

function NNGuidingModel()
    tokenizer = TransformerTextEncoder(ExpCoderTokenization(), vocab)
    tokenizer = TextEncoders.set_annotate(_ -> solver.annotate_objects, tokenizer)
    embedder = Embedder() |> todevice
    grammar_encoder = GrammarEncoder() |> todevice
    state_processor =
        Chain(
            Dense(d_state_in, d_state_h, relu),
            Dense(d_state_h, d_state_h, relu),
            Dense(d_state_h, d_state_out, relu),
        ) |> todevice
    decoder = Chain(Dense(d_state_out + d_emb, d_dec_h, relu), Dense(d_dec_h, 1)) |> todevice
    return NNGuidingModel(tokenizer, embedder, grammar_encoder, state_processor, decoder, Dict())
end

function (m::NNGuidingModel)(input_batch)
    grammar_tokens, input_tokens, output_tokens, trace_val_tokens, is_reversed = input_batch
    @time grammar_func_encodings = m.embedder(grammar_tokens)
    @time input_encodings = m.embedder(input_tokens)
    @time output_encodings = m.embedder(output_tokens)
    @time trace_val_encodings = m.embedder(trace_val_tokens)

    grammar_encodings = m.grammar_encoder(grammar_func_encodings)

    state_emb = vcat(
        repeat(grammar_encodings, 1, size(input_encodings, 2)),
        input_encodings,
        output_encodings,
        trace_val_encodings,
        is_reversed,
    )
    state = m.state_processor(state_emb)
    broadcasted_state =
        repeat(reshape(state, size(state, 1), 1, size(state)[2:end]...), 1, size(grammar_func_encodings, 2))
    broadcasted_f_emb = repeat(grammar_func_encodings, 1, 1, size(state, 2))
    result = m.decoder(vcat(broadcasted_state, broadcasted_f_emb))
    return reshape(result, size(result)[2:end]...)
end

function _preprocess_input_batch(m::NNGuidingModel, batch)
    grammar, inputs, outputs, trace_val, is_reversed = batch
    grammar_tokens = Transformers.encode(m.tokenizer, grammar)
    input_tokens = Transformers.encode(m.tokenizer, inputs)
    output_tokens = Transformers.encode(m.tokenizer, outputs)
    trace_val_tokens = Transformers.encode(m.tokenizer, trace_val)
    return (grammar_tokens, input_tokens, output_tokens, trace_val_tokens, is_reversed)
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
    mask = fill(-Inf32, grammar_length, length(summary.normalizers))
    N = zeros(Float32, length(summary.normalizers))
    for (i, (norm_set, count)) in enumerate(summary.normalizers)
        N[i] = count
        mask[norm_set, i] .= 0
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

using Flux: DataLoader

function lookup(e, x::NamedTuple{name}) where {name}
    xt = Tuple(x)
    return NamedTuple{name}((TextEncoders.lookup(getfield(e, :vocab), xt[1]), Base.tail(xt)...))
end

struct DataBlock
    grammar::Any
    values::Any
    labels::Any
end

Base.length(d::DataBlock) = length(d.values)

function Base.getindex(d::DataBlock, i::Int)
    inputs, outputs, trace_val, is_rev = d.values[i]

    is_rev_shaped = [is_rev]
    uses, mask, N, constant = d.labels[i]
    constant = [constant]
    return ((d.grammar, inputs, outputs, trace_val, is_rev_shaped), (uses, mask, N, constant))
end

function Base.getindex(d::DataBlock, i)
    inputs, outputs, trace_val, is_rev = zip(d.values[i]...)

    is_rev_shaped = reshape(collect(is_rev), 1, :)
    uses, mask, N, constant = zip(d.labels[i]...)
    uses = hcat(uses...)
    max_norm_count = maximum(length, N)
    merged_mask = zeros(Float32, length(d.grammar), max_norm_count, length(N))
    merged_N = zeros(Float32, max_norm_count, length(N))
    for (i, counts) in enumerate(N)
        merged_N[1:length(counts), i] = counts
        merged_mask[:, 1:length(counts), i] = mask[i]
    end

    constant = reshape(collect(constant), 1, :)

    return (
        (d.grammar, collect(inputs), collect(outputs), collect(trace_val), is_rev_shaped),
        (uses, merged_mask, merged_N, constant),
    )
end

function expand_traces(all_traces, batch_size = 1)
    groups = []

    for (grammar, gr_traces) in values(all_traces)
        full_grammar = vcat(grammar, [Index(0), "lambda", FreeVar(t0, UInt64(1), nothing)])

        X_data = []
        summaries = []
        for (task_name, traces) in gr_traces
            for (hit, cost) in traces
                inputs = Dict(k => v for (k, v) in hit.trace_values if isa(k, String) && k != "output")

                blocks = extract_program_blocks(hit.hit_program)
                for (var_id, p, is_rev) in blocks
                    trace_val = hit.trace_values[var_id]
                    summary = build_likelihood_summary(grammar, trace_val[1], p, is_rev)
                    if isempty(summary[2])
                        continue
                    end
                    push!(X_data, (inputs, hit.trace_values["output"], trace_val, is_rev))
                    push!(summaries, summary)
                end
            end
        end
        if !isempty(X_data)
            push!(groups, DataLoader(DataBlock(full_grammar, X_data, summaries), batchsize = batch_size))
        end
    end
    return groups
end

using Statistics
function loss(result, summary)
    uses, mask, N, constant = summary
    uses = uses
    mask = mask
    N = N
    constant = constant

    numenator = sum(result .* uses, dims = 1) .+ constant

    z = (mask .+ repeat(reshape(result, size(result, 1), 1, size(result)[2:end]...), 1, size(mask, 2), 1))
    z = logsumexp(z, dims = 1)
    z = reshape(z, size(z)[2:end]...)

    denominator = sum(N .* z, dims = 1)

    return mean(denominator .- numenator)
end

using ProgressMeter

function update_guiding_model(guiding_model::NNGuidingModel, traces)
    train_set = expand_traces(traces, 16)
    if isempty(train_set)
        return guiding_model
    end

    opt_state = Flux.setup(Adam(0.001, (0.9, 0.999), 1e-8), guiding_model)

    train_set_size = sum(length, train_set)
    epochs = 10
    for e in 1:epochs
        p = Progress(train_set_size)
        losses = Float32[]

        for (i, data_group) in enumerate(train_set)
            for (j, batch) in enumerate(data_group)
                # Unpack this element (for supervised training):
                inputs, summaries = batch
                inputs = _preprocess_input_batch(guiding_model, inputs) |> todevice
                summaries = summaries |> todevice

                # Calculate the gradient of the objective
                # with respect to the parameters within the model:
                loss_val, grads = Flux.withgradient(guiding_model) do m
                    result = m(inputs)
                    loss(result, summaries)
                end
                push!(losses, loss_val)

                if !isfinite(loss_val)
                    @warn "loss is $loss_val on item $i $j"
                else
                    # Update the parameters so as to reduce the objective,
                    # according the chosen optimisation rule:
                    Flux.update!(opt_state, guiding_model, grads[1])
                end
                next!(p, showvalues = [("loss", loss_val)])
            end
        end
        finish!(p)
        @info "Average loss for epoch $e: $(mean(losses))"
    end

    return guiding_model
end

function _grammar_with_weights(grammar::Grammar, production_scores, log_variable, log_lambda, log_free_var)
    productions = Tuple{Program,Tp,Float64}[(p, t, production_scores[p]) for (p, t, _) in grammar.library]
    return Grammar(log_variable, log_lambda, log_free_var, productions, nothing)
end

function generate_grammar(sc::SolutionContext, guiding_model::NNGuidingModel, grammar, entry_id, is_known)
    full_grammar = vcat(grammar, [Index(0), "lambda", FreeVar(t0, UInt64(1), nothing)])
    inputs = Dict()
    for (var_id, name) in sc.input_keys
        # Using var id as branch id because they are the same for input variables
        entry = sc.entries[sc.branch_entries[var_id]]
        inputs[name] = (sc.types[entry.type_id], entry.values)
    end
    output_entry = sc.entries[sc.branch_entries[sc.target_branch_id]]
    output = (sc.types[output_entry.type_id], output_entry.values)

    val_entry = sc.entries[entry_id]
    trace_val = (sc.types[val_entry.type_id], val_entry.values)

    model_inputs = (full_grammar, inputs, output, trace_val, [is_known])
    # @info model_inputs
    @time begin
        preprocessed_inputs = _preprocess_input_batch(guiding_model, model_inputs) |> todevice
        result = guiding_model(preprocessed_inputs) |> cpu
    end

    log_variable = result[end-2]
    log_lambda = result[end-1]
    log_free_var = result[end]
    if !haskey(guiding_model.contextual_cache, grammar)
        productions = Tuple{Program,Tp,Float64}[(p, p.t, result[i]) for (i, p) in enumerate(grammar)]
        g = Grammar(log_variable, log_lambda, log_free_var, productions, nothing)
        guiding_model.contextual_cache[grammar] = make_dummy_contextual(g)
        return guiding_model.contextual_cache[grammar]
    else
        prototype = guiding_model.contextual_cache[grammar]
        production_scores = Dict{Program,Float64}(p => result[i] for (i, p) in enumerate(grammar))
        return ContextualGrammar(
            _grammar_with_weights(prototype.no_context, production_scores, log_variable, log_lambda, log_free_var),
            _grammar_with_weights(prototype.no_context, production_scores, log_variable, log_lambda, log_free_var),
            Dict(
                p => [
                    _grammar_with_weights(g, production_scores, log_variable, log_lambda, log_free_var) for
                    g in grammars
                ] for (p, grammars) in prototype.contextual_library
            ),
        )
    end
end


function load_sampling_payload(payload)
    g = deserialize_grammar(payload["DSL"])
    grammar = make_dummy_contextual(g)
    request = parse_type(payload["request"])
    max_depth = payload["max_depth"]
    max_block_depth = payload["max_block_depth"]
    max_attempts = payload["max_attempts"]
    timeout = payload["timeout"]
    program_timeout = payload["program_timeout"]
    return grammar, request, max_depth, max_block_depth, max_attempts, timeout, program_timeout
end

function run_sampling_process(run_context, payload)
    grammar, request, max_depth, max_block_depth, max_attempts, timeout, program_timeout =
        load_sampling_payload(payload)
    run_context["timeout"] = program_timeout
    program, examples = sample_program(grammar, request, max_depth, max_block_depth, max_attempts, timeout, run_context)
    if isnothing(program)
        result = Dict("program" => nothing, "task" => Dict("request" => string(request), "examples" => examples))
    else
        result =
            Dict("program" => string(program), "task" => Dict("request" => string(request), "examples" => examples))
    end
    @info "Result: $result"
    return result
end

struct SamplingVarCounter
    counts::Vector{UInt64}
end

function create_next_var(sc::SamplingVarCounter)
    sc.counts[end] += 1
    return sc.counts[end]
end

function sample_program(grammar, request, max_depth, max_block_depth, max_attempts, timeout, run_context)
    input_types = arguments_of_type(request)
    var_counter = SamplingVarCounter([length(input_types) + 1])

    if !isempty(examples_counts)
        examples_count = rand(examples_counts)
    else
        examples_count = 5
    end
    input_block_attempts = DefaultDict(() -> 0)

    input_keys = Dict(UInt64(i) => var_name for (i, (var_name, _)) in enumerate(input_types))

    failed_input_blocks = Set{Any}()
    output_var = UInt64(length(input_types) + 1)
    try
        return sample_input_program(
            grammar,
            [(0, UInt64(i), var_type) for (i, (var_name, var_type)) in enumerate(input_types)],
            [],
            Dict(),
            [],
            Dict(var_name => [] for var_name in keys(input_keys)),
            input_block_attempts,
            failed_input_blocks,
            output_var,
            return_of_type(request),
            input_keys,
            time(),
            [0.0],
            max_depth,
            max_block_depth,
            max_attempts,
            timeout,
            run_context,
            var_counter,
            examples_count,
        )
    catch e
        if isa(e, SamplingError) || isa(e, TimeoutException)
            return nothing, nothing
        end
        rethrow()
    end
end

function sample_distribution(d)
    """
    Expects d to be a list of tuples
    The first element should be the probability
    If the tuples are of length 2 then it returns the second element
    Otherwise it returns the suffix tuple
    """

    z = float(sum(t[4] for t in d))
    # if z == 0.0
    #     @error "sampleDistribution: z = 0"
    #     @error d
    # end
    r = rand() * z
    u = 0.0
    for (i, t) in enumerate(d)
        p = t[4]
        # This extra condition is needed for floating-point bullshit
        if r <= u + p || i == length(d)
            return t[1:3]
        end
        u += p
    end
    error("sampleDistribution: should not reach here")
end

struct SamplingError <: Exception end
struct SamplingBlockError <: Exception
    p::Any
end

struct TimeoutException <: Exception end
struct NeedsWrapping <: Exception end

function _sample_wrapping_block(
    grammar,
    block,
    inp_type,
    out_vars,
    context,
    filled_vars,
    block_attempts,
    failed_blocks,
    max_block_depth,
    max_attempts,
    run_context,
    examples_count,
)
    # @info "Creating wrapper prototypes for $(block.p)"
    calculated_input_values, calculated_output_values, fixer_vars = try
        ok = @run_with_timeout run_context "timeout" begin
            # @info "Trying to evaluate program: $(block.p)"
            # @info "params: $(Dict(var_ind => filled_vars[var_ind] for var_ind in block.output_vars))"

            calculated_input_values = [
                try_evaluate_program(
                    block.p,
                    [],
                    Dict(var_ind => filled_vars[var_ind][2][j] for var_ind in block.output_vars),
                ) for j in 1:examples_count
            ]
            # @info "calculated_input_values: $calculated_input_values"

            calculated_output_values = DefaultDict{UInt64,Any}(() -> [])
            fixer_vars = Set()

            for j in 1:examples_count
                calculated_outputs = try_run_function(run_in_reverse, [block.p, calculated_input_values[j]])
                # @info "calculated_outputs: $calculated_outputs"
                for var_ind in block.output_vars
                    push!(calculated_output_values[var_ind], calculated_outputs[var_ind])
                    if isa(calculated_outputs[var_ind], AbductibleValue) ||
                       isa(calculated_outputs[var_ind], EitherOptions)
                        push!(fixer_vars, var_ind)
                    end
                end
            end
            true
        end
        if isnothing(ok)
            # @info "Timeout"
            throw(SamplingBlockError(block))
        end
        calculated_input_values, calculated_output_values, fixer_vars
    catch e
        if isa(e, EnumerationException)
            # @info "Error while running program"
            block_attempts[block.p] += 1
            if block_attempts[block.p] > max_attempts
                # @info "Too many attempts"
                throw(SamplingBlockError(block))
            end
            throw(SamplingError())
        else
            rethrow()
        end
    end
    # @info "Calculated input values: $calculated_input_values"
    # @info "Calculated output values: $calculated_output_values"
    # @info "Fixer vars: $fixer_vars"
    wrapper_prototypes = []
    for fixer_var in fixer_vars
        var_ind = findfirst(v_info -> v_info[1] == fixer_var, out_vars)
        unknown_type = out_vars[var_ind][2]

        candidate_functions = unifying_expressions(
            Tp[],
            context,
            Hole(inp_type, grammar.no_context, CustomArgChecker(true, -1, false, nothing), nothing),
            Hole(inp_type, grammar.no_context, CustomArgChecker(true, -1, false, nothing), nothing),
            [],
        )

        wrapper, arg_types, context, wrap_cost =
            first(v for v in candidate_functions if v[1] == every_primitive["rev_fix_param"])

        context = unify(context, unknown_type, arg_types[2])
        context, fixer_type = apply_context(context, arg_types[3])

        custom_arg_checkers = _get_custom_arg_checkers(wrapper)

        wrapped_p = Apply(
            Apply(Apply(wrapper, block.p), FreeVar(unknown_type, fixer_var)),
            Hole(
                fixer_type,
                grammar.contextual_library[wrapper][3],
                custom_arg_checkers[3],
                calculated_output_values[fixer_var],
            ),
        )
        push!(wrapper_prototypes, (wrapped_p, context))
    end
    # @info "wrapper_prototypes: $wrapper_prototypes"

    i = 0
    local_failed_blocks = Set{Any}()
    while i < max_attempts
        i += 1
        try
            skeleton, context = rand(wrapper_prototypes)
            path = [RightTurn()]
            while true
                if is_reversible(skeleton) || (!isa(skeleton, Hole) && isempty(path))
                    break
                end
                skeleton, path, context =
                    _sampling_input_program_iteration(skeleton, path, context, max_block_depth, grammar)
            end
            # @info "Sampled wrapper: $skeleton"

            if check_failed_block(skeleton, block.output_vars, failed_blocks) || in(skeleton, local_failed_blocks)
                # @info "Failed block $skeleton"
                throw(SamplingError())
            end

            try
                ok = @run_with_timeout run_context "timeout" begin
                    # @info "Trying to evaluate program: $skeleton"
                    # @info "params: $(Dict(var_ind => filled_vars[var_ind] for var_ind in block.output_vars))"

                    for j in 1:examples_count
                        calculated_outputs = try_run_function(run_in_reverse, [skeleton, calculated_input_values[j]])
                        # @info "calculated_outputs: $calculated_outputs"
                        for var_ind in block.output_vars
                            if isa(calculated_outputs[var_ind], AbductibleValue) ||
                               isa(calculated_outputs[var_ind], EitherOptions)
                                # @info "Got abductible or either value"
                                throw(SamplingError())
                            end

                            if calculated_outputs[var_ind] != filled_vars[var_ind][2][j]
                                # @info "outputs don't match"
                                throw(SamplingError())
                            end
                        end
                    end
                    true
                end
                if isnothing(ok)
                    # @info "Timeout"
                    throw(SamplingBlockError(ReverseProgramBlock(skeleton, 0.0, block.input_vars, block.output_vars)))
                end
                # @info "Wrapper $skeleton is good"
                return ReverseProgramBlock(skeleton, 0.0, block.input_vars, block.output_vars), calculated_input_values

            catch e
                # @info e
                if e isa SamplingError || (e isa SamplingBlockError && e.p == skeleton) || isa(e, EnumerationException)
                    push!(local_failed_blocks, skeleton)
                end
                if (e isa SamplingBlockError && e.p == skeleton)
                    save_failed_block(skeleton, block.output_vars, failed_blocks)
                    throw(SamplingError())
                elseif isa(e, EnumerationException)
                    # @info "Error while running program"
                    block_attempts[skeleton] += 1
                    if block_attempts[skeleton] > max_attempts
                        # @info "Too many attempts"
                        save_failed_block(skeleton, block.output_vars, failed_blocks)
                    end
                    throw(SamplingError())
                else
                    rethrow()
                end
            end

        catch e
            if e isa SamplingError
                # @info "Sampling error"
                continue
            end
            rethrow()
        end
    end

    throw(SamplingBlockError(block))
end

function sample_input_program(
    grammar,
    vars_to_fill,
    prev_blocks,
    filled_vars,
    filled_blocks,
    var_prev_blocks,
    block_attempts,
    failed_blocks,
    output_var,
    output_type,
    input_keys,
    start_time,
    output_sampling_time,
    max_depth,
    max_block_depth,
    max_attempts,
    timeout,
    run_context,
    var_counter,
    examples_count,
)
    if time() - output_sampling_time[1] - start_time > timeout
        # @info "Timeout $(output_sampling_time[1]) $(time() - output_sampling_time[1] - start_time)"
        throw(TimeoutException())
    end
    if isempty(vars_to_fill)
        # @info "input_blocks: $filled_blocks"
        # @info "input_vars: $filled_vars"
        # @info "input_vars_prev_blocks: $var_prev_blocks"
        # @info "failed blocks $failed_blocks"

        output_block_attempts = DefaultDict(() -> 0)
        input_var_types = Set([v[1] for v in values(filled_vars)])
        # @info "input_var_types: $input_var_types"

        out_sampling_start_time = time()
        try
            return sample_output_program(
                grammar,
                [(0, output_var, output_type, true)],
                [],
                filled_vars,
                reverse(filled_blocks),
                output_block_attempts,
                Dict(output_var => Set{Any}()),
                input_var_types,
                Set(filled_blocks),
                Set(),
                filled_vars,
                var_prev_blocks,
                Dict(),
                output_var,
                input_keys,
                max_depth,
                max_block_depth,
                max_attempts,
                out_sampling_start_time,
                timeout,
                run_context,
                var_counter,
                examples_count,
            )
        catch e
            if isa(e, TimeoutException)
                err_block = filled_blocks[1]
                non_terminal_vars = Set()
                for block in filled_blocks
                    if all(!in(v, non_terminal_vars) for v in block.output_vars)
                        err_block = block
                    end
                    union!(non_terminal_vars, block.input_vars)
                end
                # @info "Timeout $(filled_blocks)"
                # @info "Timeout $(err_block)"
                throw(SamplingBlockError(err_block))
            else
                rethrow()
            end
        finally
            output_sampling_time[1] += time() - out_sampling_start_time
        end
    end
    depth, var_name, var_type = vars_to_fill[end]
    i = 0
    while i < max_attempts
        r = rand() * max_depth
        if r < depth || isa(var_type, TypeVariable)
            try
                var_values = generate_var_values(var_type, examples_count)
                # @info "var_values: $var_values"
                new_filled_vars = merge(filled_vars, Dict(var_name => (var_type, var_values)))
                # @info "new_filled_vars: $new_filled_vars"

                new_prev_blocks = []
                new_filled_blocks = []
                for (block, inp_type, out_vars, context) in Iterators.reverse(prev_blocks)
                    if check_failed_block(block.p, block.output_vars, failed_blocks)
                        # @info "Block $block is in failed blocks"
                        throw(SamplingBlockError(block))
                    end
                    if all(haskey(new_filled_vars, v) for v in block.output_vars)
                        try
                            ok = @run_with_timeout run_context "timeout" begin
                                # @info "Trying to evaluate program: $(block.p)"
                                # @info "params: $(Dict(var_ind => new_filled_vars[var_ind] for var_ind in block.output_vars))"

                                calculated_input_values = [
                                    try_evaluate_program(
                                        block.p,
                                        [],
                                        Dict(
                                            var_ind => new_filled_vars[var_ind][2][j] for var_ind in block.output_vars
                                        ),
                                    ) for j in 1:examples_count
                                ]
                                # @info "calculated_input_values: $calculated_input_values"

                                for j in 1:examples_count
                                    calculated_outputs =
                                        try_run_function(run_in_reverse, [block.p, calculated_input_values[j]])
                                    # @info "calculated_outputs: $calculated_outputs"
                                    for var_ind in block.output_vars
                                        if isa(calculated_outputs[var_ind], AbductibleValue) ||
                                           isa(calculated_outputs[var_ind], EitherOptions)
                                            # @info "Got abductible or either value"
                                            throw(NeedsWrapping())
                                        end

                                        if calculated_outputs[var_ind] != new_filled_vars[var_ind][2][j]
                                            # @info "outputs don't match"
                                            throw(SamplingError())
                                        end
                                    end
                                end
                                new_filled_vars[block.input_vars[1]] = (inp_type, calculated_input_values)
                                push!(new_filled_blocks, block)
                                true
                            end
                            if isnothing(ok)
                                # @info "Timeout"
                                throw(SamplingBlockError(block))
                            end
                        catch e
                            if isa(e, EnumerationException)
                                # @info "Error while running program"
                                block_attempts[block.p] += 1
                                if block_attempts[block.p] > max_attempts
                                    # @info "Too many attempts"
                                    throw(SamplingBlockError(block))
                                end
                                throw(SamplingError())
                            elseif isa(e, NeedsWrapping)
                                # @info "Needs wrapping"
                                wrapped_block, calculated_input_values = _sample_wrapping_block(
                                    grammar,
                                    block,
                                    inp_type,
                                    out_vars,
                                    context,
                                    new_filled_vars,
                                    block_attempts,
                                    failed_blocks,
                                    max_block_depth,
                                    max_attempts,
                                    run_context,
                                    examples_count,
                                )
                                new_filled_vars[block.input_vars[1]] = (inp_type, calculated_input_values)
                                push!(new_filled_blocks, wrapped_block)
                            else
                                rethrow()
                            end
                        end
                    else
                        push!(new_prev_blocks, (block, inp_type, out_vars, context))
                    end
                end
                reverse!(new_prev_blocks)

                return sample_input_program(
                    grammar,
                    vars_to_fill[1:end-1],
                    new_prev_blocks,
                    new_filled_vars,
                    vcat(filled_blocks, new_filled_blocks),
                    var_prev_blocks,
                    block_attempts,
                    failed_blocks,
                    output_var,
                    output_type,
                    input_keys,
                    start_time,
                    output_sampling_time,
                    max_depth,
                    max_block_depth,
                    max_attempts,
                    timeout,
                    run_context,
                    var_counter,
                    examples_count,
                )
            catch e
                if e isa SamplingError
                    i += 1
                else
                    rethrow()
                end
            end
        else
            push!(var_counter.counts, var_counter.counts[end])
            try
                new_p, new_vars, context, inp_type =
                    _sample_input_program(grammar, var_type, max_block_depth, var_counter, failed_blocks)
                new_block = ReverseProgramBlock(new_p, 0.0, [var_name], [v_name for (v_name, _) in new_vars])

                sampling_result = try
                    sample_input_program(
                        grammar,
                        vcat(vars_to_fill[1:end-1], [(depth + 1, v_name, v_type) for (v_name, v_type) in new_vars]),
                        vcat(prev_blocks, [(new_block, inp_type, new_vars, context)]),
                        filled_vars,
                        filled_blocks,
                        merge(
                            var_prev_blocks,
                            Dict(v_name => vcat(var_prev_blocks[var_name], [new_block]) for (v_name, _) in new_vars),
                        ),
                        block_attempts,
                        failed_blocks,
                        output_var,
                        output_type,
                        input_keys,
                        start_time,
                        output_sampling_time,
                        max_depth,
                        max_block_depth,
                        max_attempts,
                        timeout,
                        run_context,
                        var_counter,
                        examples_count,
                    )
                catch e
                    if e isa SamplingError || (
                        e isa SamplingBlockError && (
                            e.p == new_block || (
                                application_parse(e.p.p)[1] == every_primitive["rev_fix_param"] &&
                                application_parse(e.p.p)[2][1] == new_p &&
                                e.p.input_vars == new_block.input_vars &&
                                e.p.output_vars == new_block.output_vars
                            )
                        )
                    )
                        save_failed_block(new_p, new_vars, failed_blocks)
                    end
                    if (
                        e isa SamplingBlockError && (
                            e.p == new_block || (
                                application_parse(e.p.p)[1] == every_primitive["rev_fix_param"] &&
                                application_parse(e.p.p)[2][1] == new_p &&
                                e.p.input_vars == new_block.input_vars &&
                                e.p.output_vars == new_block.output_vars
                            )
                        )
                    )
                        # @info "Checking failed blocks $failed_blocks"
                        # @info "Filled blocks $filled_blocks"
                        # @info "Prev blocks $prev_blocks"
                        for block in Iterators.flatten([filled_blocks, (b for (b, _) in prev_blocks)])
                            if check_failed_block(block.p, block.output_vars, failed_blocks)
                                # @info "Block $block is in failed blocks"
                                throw(SamplingBlockError(block))
                            end
                        end

                        throw(SamplingError())
                    else
                        rethrow()
                    end
                end

                var_counter.counts[end-1] = var_counter.counts[end]
                pop!(var_counter.counts)
                return sampling_result
            catch e
                if e isa SamplingError || e isa SamplingBlockError
                    pop!(var_counter.counts)
                end
                if e isa SamplingError
                    i += 1
                else
                    rethrow()
                end
            end
        end
    end
    throw(SamplingError())
end

using Random

function _check_complete_blocks(
    prev_blocks,
    new_filled_vars,
    new_filled_blocks,
    block_attempts,
    max_attempts,
    run_context,
    examples_count,
)
    new_prev_blocks = []

    for block in Iterators.reverse(prev_blocks)
        # if p in failed_blocks
        #     @info "Block $p is in failed blocks"
        #     throw(SamplingBlockError(p))
        # end
        if all(haskey(new_filled_vars, v) for v in block.input_vars)
            try
                ok = @run_with_timeout run_context "timeout" begin
                    # @info "Trying to evaluate program: $block"
                    # @info "params: $(Dict(var_ind => new_filled_vars[var_ind] for var_ind in block.input_vars))"

                    calculated_output_values = [
                        try_evaluate_program(
                            block.p,
                            [],
                            Dict(var_ind => new_filled_vars[var_ind][2][j] for var_ind in block.input_vars),
                        ) for j in 1:examples_count
                    ]
                    # @info "calculated_output_values: $calculated_output_values"

                    if block.is_reversible
                        for j in 1:examples_count
                            calculated_inputs = try_run_function(run_in_reverse, [block.p, calculated_output_values[j]])
                            # @info "calculated_inputs: $calculated_inputs"

                            fixing_hashes = Set()
                            for var_ind in block.input_vars
                                expected_value = fix_option_hashes(fixing_hashes, calculated_inputs[var_ind])
                                if !_match_value(expected_value, new_filled_vars[var_ind][2][j])
                                    # @info "inputs don't match $(expected_value) $(new_filled_vars[var_ind][2][j])"
                                    throw(SamplingError())
                                end
                                union!(fixing_hashes, get_fixed_hashes(expected_value, new_filled_vars[var_ind][2][j]))
                            end
                        end
                    end

                    new_filled_vars[block.output_var] = (block.type, calculated_output_values)
                    push!(new_filled_blocks, block)
                    true
                end
                if isnothing(ok)
                    # @info "Timeout"
                    throw(SamplingError())
                end
            catch e
                if isa(e, EnumerationException)
                    # @info "Error while running program"
                    block_attempts[block] += 1
                    if block_attempts[block] > max_attempts
                        # @info "Too many attempts"
                        throw(SamplingBlockError(block))
                    end
                    throw(SamplingError())
                else
                    rethrow()
                end
            end
        else
            push!(new_prev_blocks, block)
        end
    end
    reverse!(new_prev_blocks)
    return new_prev_blocks
end

function sample_output_program(
    grammar,
    vars_to_fill,
    prev_blocks,
    filled_vars,
    filled_blocks,
    block_attempts,
    failed_blocks,
    input_var_types,
    unused_input_blocks,
    unused_output_blocks,
    input_vars,
    input_vars_prev_blocks,
    output_var_next_blocks,
    output_var,
    input_keys,
    max_depth,
    max_block_depth,
    max_attempts,
    start_time,
    timeout,
    run_context,
    var_counter,
    examples_count,
)
    if time() - start_time > timeout
        # @info "Timeout"
        throw(TimeoutException())
    end

    new_filled_blocks = []
    filled_vars = copy(filled_vars)
    prev_blocks = _check_complete_blocks(
        prev_blocks,
        filled_vars,
        new_filled_blocks,
        block_attempts,
        max_attempts,
        run_context,
        examples_count,
    )

    filled_blocks = vcat(filled_blocks, new_filled_blocks)

    if isempty(vars_to_fill)
        if !isempty(unused_input_blocks)
            # @info "Unused input blocks: $unused_input_blocks"
            # @info "Filled blocks: $filled_blocks"
            for block in reverse(filled_blocks)
                if isempty(block.input_vars)
                    # @info "Marking block $block as failed"
                    throw(SamplingBlockError(block))
                end
            end
            for block in reverse(filled_blocks)
                if isa(block.p, FreeVar)
                    # @info "Marking block $block as failed"
                    throw(SamplingBlockError(block))
                end
            end
            @assert false
        end
        # @info "filled_blocks: $filled_blocks"

        output = filled_blocks[end].p
        for block in view(filled_blocks, length(filled_blocks)-1:-1:1)
            output = block_to_let(block, output)
        end
        # for block in reverse(input_blocks)
        #     output = block_to_let(block, output)
        # end
        # @info "output: $output"
        output = alpha_substitution(output, Dict{UInt64,Any}(), UInt64(1), input_keys)[1]
        # @info "output: $output"
        examples = []
        for i in 1:examples_count
            example = Dict{String,Any}(
                "output" => filled_vars[output_var][2][i],
                "inputs" => Dict{String,Any}(name => filled_vars[k][2][i] for (k, name) in input_keys),
            )
            push!(examples, example)
        end
        # @info "examples: $examples"

        for example in examples
            if !_test_one_example(output, example["inputs"], example["output"])
                @info "Example failed for $output: $example"
                throw(SamplingError())
            end
        end

        return output, examples
    end

    i = 0
    value_options = Dict()

    while i < max_attempts
        depth, var_name, var_type, has_data = rand(vars_to_fill)
        push!(var_counter.counts, var_counter.counts[end])

        try
            r = rand() * max_depth

            if !has_data || r < depth
                if !haskey(value_options, var_name)
                    value_options[var_name] = Set{Any}([
                        FreeVar(v_type, v_name) for (v_name, (v_type, v_data)) in input_vars if v_type == var_type
                    ])
                    if has_data && isempty(unused_input_blocks) && isempty(unused_output_blocks)
                        union!(
                            value_options[var_name],
                            [SetConst(var_type, generate_const_var_value(var_type)) for _ in 1:5],
                        )
                    end
                end

                if isempty(value_options[var_name])
                    # @info "Can't find a value for $var_name"
                    throw(SamplingError())
                end

                new_p = rand(value_options[var_name])

                if new_p in failed_blocks[var_name]
                    # @info "Failed block $new_p"
                    throw(SamplingError())
                end

                if isa(new_p, FreeVar)
                    new_unused_input_blocks = setdiff(unused_input_blocks, input_vars_prev_blocks[new_p.var_id])
                    inp_vars = [new_p.var_id]
                    if haskey(output_var_next_blocks, var_name)
                        new_unused_output_blocks = copy(unused_output_blocks)
                        delete!(new_unused_output_blocks, output_var_next_blocks[var_name])
                    else
                        new_unused_output_blocks = unused_output_blocks
                    end
                else
                    new_unused_input_blocks = unused_input_blocks
                    new_unused_output_blocks = unused_output_blocks
                    inp_vars = []
                end
                new_block = ProgramBlock(new_p, var_type, 0.0, inp_vars, var_name, false)

                new_vars = []
                new_failed_blocks = failed_blocks
                new_output_var_next_blocks = output_var_next_blocks
            else
                new_p, new_vars, return_type = _sample_output_program(
                    grammar,
                    var_type,
                    max_block_depth,
                    var_counter,
                    input_var_types,
                    failed_blocks[var_name],
                )
                inp_vars = [v_name for (v_name, _, _) in new_vars]
                new_block = ProgramBlock(new_p, return_type, 0.0, inp_vars, var_name, is_reversible(new_p))
                new_unused_input_blocks = unused_input_blocks
                new_unused_output_blocks = copy(unused_output_blocks)
                if haskey(output_var_next_blocks, var_name)
                    delete!(new_unused_output_blocks, output_var_next_blocks[var_name])
                end
                push!(new_unused_output_blocks, new_block)
                new_output_var_next_blocks =
                    merge(output_var_next_blocks, Dict(v_name => new_block for v_name in inp_vars))

                new_failed_blocks = merge(failed_blocks, Dict(v_name => Set{Any}() for v_name in inp_vars))
            end

            sampling_result = try
                sample_output_program(
                    grammar,
                    vcat(
                        [vs for vs in vars_to_fill if vs[2] != var_name],
                        [(depth + 1, v_name, v_type, v_has_data) for (v_name, v_type, v_has_data) in new_vars],
                    ),
                    vcat(prev_blocks, [new_block]),
                    filled_vars,
                    filled_blocks,
                    block_attempts,
                    new_failed_blocks,
                    input_var_types,
                    new_unused_input_blocks,
                    new_unused_output_blocks,
                    input_vars,
                    input_vars_prev_blocks,
                    new_output_var_next_blocks,
                    output_var,
                    input_keys,
                    max_depth,
                    max_block_depth,
                    max_attempts,
                    start_time,
                    timeout,
                    run_context,
                    var_counter,
                    examples_count,
                )
            catch e
                if e isa SamplingError || (e isa SamplingBlockError && e.p == new_block)
                    push!(failed_blocks[var_name], new_block.p)
                    if isa(new_block.p, FreeVar) || isa(new_block.p, SetConst)
                        delete!(value_options[var_name], new_block.p)
                    end
                end
                if (e isa SamplingBlockError && e.p == new_block)
                    throw(SamplingError())
                else
                    rethrow()
                end
            end

            var_counter.counts[end-1] = var_counter.counts[end]
            pop!(var_counter.counts)
            return sampling_result
        catch e
            if e isa SamplingError || e isa SamplingBlockError || e isa TimeoutException
                pop!(var_counter.counts)
            end
            if e isa SamplingError
                i += 1
            else
                rethrow()
            end
        end
    end
    throw(SamplingError())
end

function normalize_program(p::Abstraction, vars_map)
    return Abstraction(normalize_program(p.b, vars_map))
end

function normalize_program(p::Apply, vars_map)
    return Apply(normalize_program(p.f, vars_map), normalize_program(p.x, vars_map))
end

function normalize_program(p::FreeVar, vars_map)
    return FreeVar(p.t, vars_map[p.var_id])
end

function normalize_program(p, vars_map)
    return p
end

function save_failed_block(p, vars, failed_blocks)
    vars_map = Dict(v_name => UInt64(i) for (i, (v_name, _)) in enumerate(vars))
    norm_p = normalize_program(p, vars_map)
    # @info "Saving failed block $norm_p"
    push!(failed_blocks, norm_p)
end

function check_failed_block(p, vars, failed_blocks)
    vars_map = Dict(v_name => UInt64(i) for (i, v_name) in enumerate(vars))
    norm_p = normalize_program(p, vars_map)
    return norm_p in failed_blocks
end

function _sampling_input_program_iteration(skeleton, path, context, max_depth, grammar)
    current_hole = follow_path(skeleton, path)
    if !isa(current_hole, Hole)
        error("Error during following path")
    end
    request = current_hole.t
    context, request = apply_context(context, request)
    # @info skeleton
    if isarrow(request)
        skeleton = modify_skeleton(
            skeleton,
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
            path,
        )
        path = vcat(path, [ArgTurn(request.arguments[1])])
    else
        environment = path_environment(path)
        candidates = unifying_expressions(environment, context, current_hole, skeleton, path)
        depth = length([1 for turn in path if !isa(turn, ArgTurn)])
        if depth >= max_depth
            # @info string(candidates)
            candidates = filter!(x -> isempty(x[2]), candidates)
        end
        while true
            # @info string(candidates)
            if isempty(candidates)
                # @info "No candidates"
                throw(SamplingError())
            end
            candidate, argument_types, context = sample_distribution(candidates)
            # @info candidate

            if isa(candidate, Abstraction)
                application_template = Apply(
                    candidate,
                    Hole(argument_types[1], grammar.no_context, current_hole.candidates_filter, nothing),
                )
                new_skeleton = modify_skeleton(skeleton, application_template, path)
                new_path = vcat(path, [LeftTurn(), ArgTurn(argument_types[1])])
            else
                argument_requests = get_argument_requests(candidate, argument_types, grammar)

                if isempty(argument_types)
                    new_skeleton = modify_skeleton(skeleton, candidate, path)
                    new_path = unwind_path(path, skeleton)
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
                    new_skeleton = modify_skeleton(skeleton, application_template, path)
                    new_path = vcat(path, [LeftTurn() for _ in 2:length(argument_types)], [RightTurn()])
                end
            end
            if !state_violates_symmetry(new_skeleton)
                skeleton = new_skeleton
                path = new_path
                break
            else
                filter!(x -> x[1] != candidate, candidates)
            end
        end
    end
    return skeleton, path, context
end

function _sample_input_program(grammar, return_type, max_depth, var_counter, failed_blocks)
    context, return_type = instantiate(return_type, empty_context)
    path = []
    skeleton = Hole(return_type, grammar.no_context, CustomArgChecker(true, -1, true, nothing), nothing)
    while true
        if is_reversible(skeleton) || (!isa(skeleton, Hole) && isempty(path))
            break
        end
        skeleton, path, context = _sampling_input_program_iteration(skeleton, path, context, max_depth, grammar)
    end
    # @info "Sampled program: $skeleton"
    new_p, new_vars = capture_free_vars(var_counter, skeleton, context)
    # @info "Sampled program with free vars: $new_p"
    # @info "Free vars: $new_vars"
    if isempty(new_vars)
        throw(SamplingError())
    end
    # @info "Failed blocks $failed_blocks"
    if check_failed_block(new_p, [v_name for (v_name, _) in new_vars], failed_blocks)
        # @info "Failed block $new_p"
        throw(SamplingError())
    end
    return new_p, new_vars, context, return_type
end

function _sample_output_program(grammar, return_type, max_depth, var_counter, input_var_types, failed_blocks)
    context, return_type = instantiate(return_type, empty_context)
    path = []
    skeleton = Hole(return_type, grammar.no_context, CustomArgChecker(false, -1, true, nothing), nothing)
    while true
        if is_reversible(skeleton) || (!isa(skeleton, Hole) && isempty(path))
            break
        end
        current_hole = follow_path(skeleton, path)
        if !isa(current_hole, Hole)
            error("Error during following path")
        end
        request = current_hole.t
        context, request = apply_context(context, request)
        # @info skeleton
        if isarrow(request)
            skeleton = modify_skeleton(
                skeleton,
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
                path,
            )
            path = vcat(path, [ArgTurn(request.arguments[1])])
        else
            environment = path_environment(path)
            candidates = unifying_expressions(environment, context, current_hole, skeleton, path)
            depth = length([1 for turn in path if !isa(turn, ArgTurn)])
            if depth >= max_depth
                # @info string(candidates)
                candidates = filter!(x -> isempty(x[2]), candidates)
            end
            while true
                # @info string(candidates)
                if isempty(candidates)
                    throw(SamplingError())
                end
                candidate, argument_types, context = sample_distribution(candidates)
                # @info candidate

                if isa(candidate, Abstraction)
                    application_template = Apply(
                        candidate,
                        Hole(argument_types[1], grammar.no_context, current_hole.candidates_filter, nothing),
                    )
                    new_skeleton = modify_skeleton(skeleton, application_template, path)
                    new_path = vcat(path, [LeftTurn(), ArgTurn(argument_types[1])])
                else
                    argument_requests = get_argument_requests(candidate, argument_types, grammar)

                    if isempty(argument_types)
                        new_skeleton = modify_skeleton(skeleton, candidate, path)
                        new_path = unwind_path(path, skeleton)
                    else
                        application_template = candidate
                        custom_arg_checkers = _get_custom_arg_checkers(candidate)
                        custom_checkers_args_count = length(custom_arg_checkers)
                        for i in 1:length(argument_types)
                            if i > custom_checkers_args_count
                                arg_checker = current_hole.candidates_filter
                            else
                                arg_checker =
                                    combine_arg_checkers(current_hole.candidates_filter, custom_arg_checkers[i])
                            end

                            application_template = Apply(
                                application_template,
                                Hole(argument_types[i], argument_requests[i], arg_checker, nothing),
                            )
                        end
                        new_skeleton = modify_skeleton(skeleton, application_template, path)
                        new_path = vcat(path, [LeftTurn() for _ in 2:length(argument_types)], [RightTurn()])
                    end
                end
                if !state_violates_symmetry(new_skeleton)
                    skeleton = new_skeleton
                    path = new_path
                    break
                else
                    filter!(x -> x[1] != candidate, candidates)
                end
            end
        end
    end
    # @info "Sampled program: $skeleton"
    new_p, new_vars = capture_free_vars(var_counter, skeleton, context)
    # @info "Sampled program with free vars: $new_p"
    # @info "Free vars: $new_vars"

    if !is_reversible(skeleton)
        for (_, v_type) in new_vars
            if !in(v_type, input_var_types)
                # @info "Output var type $v_type is not in input var types $input_var_types"
                throw(SamplingError())
            end
        end
        new_vars = [(v_name, v_type, false) for (v_name, v_type) in new_vars]
    else
        new_vars = [(v_name, v_type, true) for (v_name, v_type) in new_vars]
    end

    if new_p in failed_blocks
        # @info "Failed block $new_p"
        throw(SamplingError())
    end
    context, return_type = apply_context(context, return_type)
    return new_p, new_vars, return_type
end

function _generate_random_var_values(var_type::TypeVariable, examples_count)
    return [any_object for _ in 1:examples_count]
end

function _generate_random_var_values(var_type::TypeConstructor, examples_count)
    if var_type == tint
        return rand(1:20, examples_count)
    end
    if var_type == tcolor
        return rand(0:9, examples_count)
    end
    if var_type == tbool
        return rand(Bool, examples_count)
    end
    if var_type.name == "list"
        lengths = rand(1:20, examples_count)
        return [_generate_random_var_values(var_type.arguments[1], l) for l in lengths]
    end
    if var_type.name == "tuple2"
        return collect(zip([_generate_random_var_values(t, examples_count) for t in var_type.arguments]...))
    end
    if var_type.name == "set"
        lengths = rand(1:20, examples_count)
        return [Set(_generate_random_var_values(var_type.arguments[1], l)) for l in lengths]
    end
    if var_type.name == "grid"
        heights = rand(1:20, examples_count)
        widths = rand(1:20, examples_count)
        return [
            hcat([_generate_random_var_values(var_type.arguments[1], h) for _ in 1:w]...) for
            (h, w) in zip(heights, widths)
        ]
    end
end

function generate_var_values(var_type, examples_count)
    r = rand()
    if r < 0.45 && !isempty(multi_value_cache[examples_count][var_type])
        return [_wrap_wildcard(v) for v in select_random(multi_value_cache[examples_count][var_type])]
    end
    if r < 0.9 && !isempty(single_value_cache[var_type])
        return [_wrap_wildcard(select_random(single_value_cache[var_type])) for _ in 1:examples_count]
    end
    return [_wrap_wildcard(v) for v in _generate_random_var_values(var_type, examples_count)]
end

function generate_const_var_value(var_type)
    if rand() < 0.95 && !isempty(single_value_cache[var_type])
        return _wrap_wildcard(select_random(single_value_cache[var_type]))
    end
    return _wrap_wildcard(_generate_random_var_values(var_type, 1)[1])
end

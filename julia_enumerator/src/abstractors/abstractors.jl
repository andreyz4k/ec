
all_abstractors = Dict{Program,Tuple{Vector,Any}}()

function _is_reversible(p::Primitive)
    if haskey(all_abstractors, p)
        all_abstractors[p][1]
    else
        nothing
    end
end

function _is_reversible(p::Apply)
    rev_f = _is_reversible(p.f)
    if !isnothing(rev_f)
        if isempty(rev_f)
            if isa(p.x, Hole)
                if !isarrow(p.x.t)
                    return rev_f
                else
                    return nothing
                end
            end
            if isa(p.x, Index) || isa(p.x, FreeVar)
                return rev_f
            end
            if isa(p.x, Abstraction) || isa(p.x, Apply)
                return _is_reversible(p.x)
            end
        else
            checker = rev_f[end][1]
            if checker(p.x)
                return view(rev_f, 1:length(rev_f)-1)
            else
                return nothing
            end
        end
    end
    nothing
end

_is_reversible(p::Invented) = _is_reversible(p.b)
_is_reversible(p::Abstraction) = _is_reversible(p.b)

_is_reversible(p::Program) = nothing

is_reversible(p::Program)::Bool = !isnothing(_is_reversible(p))

struct SkipArg end

function _merge_options_paths(path1, path2)
    i = 1
    j = 1
    result = []
    while i <= length(path1) || j <= length(path2)
        if i > length(path1)
            push!(result, path2[j])
            j += 1
        elseif j > length(path2)
            push!(result, path1[i])
            i += 1
        elseif path1[i] == path2[j]
            push!(result, path1[i])
            i += 1
            j += 1
        else
            push!(result, path1[i])
            i += 1
        end
    end
    return result
end

function _intersect_values(
    old_v,
    v,
    predicted_arguments,
    filled_indices,
    filled_vars,
    new_args,
    new_filled_indices,
    new_filled_vars,
)
    if old_v != v
        error("Can't intersect values")
    end
    return predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars
end

function _intersect_values(
    old_v::AbductibleValue,
    v,
    predicted_arguments,
    filled_indices,
    filled_vars,
    new_args,
    new_filled_indices,
    new_filled_vars,
)
    return predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars
end

function _intersect_values(
    old_v::AbductibleValue,
    v::EitherOptions,
    predicted_arguments,
    filled_indices,
    filled_vars,
    new_args,
    new_filled_indices,
    new_filled_vars,
)
    return predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars
end

function _intersect_values(
    old_v::EitherOptions,
    v::EitherOptions,
    predicted_arguments,
    filled_indices,
    filled_vars,
    new_args,
    new_filled_indices,
    new_filled_vars,
)
    if old_v == v
        return predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars
    end
    old_options = Set(_const_options(old_v))
    new_options = Set(_const_options(v))
    common_options = intersect(old_options, new_options)
    paths = []
    for op in common_options
        old_op_fixed_hashes = Set()
        new_op_fixed_hashes = Set()
        try
            while true
                old_op_fixed_hashes_ = get_fixed_hashes(old_v, op, new_op_fixed_hashes)

                new_op_fixed_hashes_ = get_fixed_hashes(v, op, old_op_fixed_hashes_)
                if old_op_fixed_hashes_ == old_op_fixed_hashes && new_op_fixed_hashes_ == new_op_fixed_hashes
                    break
                end
                old_op_fixed_hashes = old_op_fixed_hashes_
                new_op_fixed_hashes = new_op_fixed_hashes_
            end
            old_op_hashes_paths = get_hashes_paths(old_v, op, new_op_fixed_hashes)

            new_op_hashes_paths = get_hashes_paths(v, op, old_op_fixed_hashes)

            for old_path in old_op_hashes_paths
                for new_path in new_op_hashes_paths
                    push!(paths, _merge_options_paths(old_path, new_path))
                end
            end
        catch
        end
    end
    predicted_arguments = [remap_options_hashes(paths, arg) for arg in predicted_arguments]
    filled_indices = Dict(i => remap_options_hashes(paths, v) for (i, v) in filled_indices)
    filled_vars = Dict(k => remap_options_hashes(paths, v) for (k, v) in filled_vars)

    new_args = [remap_options_hashes(paths, arg) for arg in new_args]
    new_filled_indices = Dict(i => remap_options_hashes(paths, v) for (i, v) in new_filled_indices)
    new_filled_vars = Dict(k => remap_options_hashes(paths, v) for (k, v) in new_filled_vars)

    return predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars
end

function _intersect_values(
    old_v::EitherOptions,
    v,
    predicted_arguments,
    filled_indices,
    filled_vars,
    new_args,
    new_filled_indices,
    new_filled_vars,
)
    fixed_hashes = get_fixed_hashes(old_v, v)

    predicted_arguments = [fix_option_hashes(fixed_hashes, arg) for arg in predicted_arguments]
    filled_indices = Dict(i => fix_option_hashes(fixed_hashes, v) for (i, v) in filled_indices)
    filled_vars = Dict(k => fix_option_hashes(fixed_hashes, v) for (k, v) in filled_vars)
    return predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars
end

function _intersect_values(
    old_v,
    v::EitherOptions,
    predicted_arguments,
    filled_indices,
    filled_vars,
    new_args,
    new_filled_indices,
    new_filled_vars,
)
    new_args, new_filled_indices, new_filled_vars, predicted_arguments, filled_indices, filled_vars = _intersect_values(
        v,
        old_v,
        new_args,
        new_filled_indices,
        new_filled_vars,
        predicted_arguments,
        filled_indices,
        filled_vars,
    )
    return predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars
end

function _intersect_values(
    predicted_arguments,
    filled_indices,
    filled_vars,
    new_args,
    new_filled_indices,
    new_filled_vars,
)
    for (i, v) in new_filled_indices
        if haskey(filled_indices, i) && filled_indices[i] != v
            predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
                _intersect_values(
                    filled_indices[i],
                    v,
                    predicted_arguments,
                    filled_indices,
                    filled_vars,
                    new_args,
                    new_filled_indices,
                    new_filled_vars,
                )
        end
    end
    for (k, v) in new_filled_vars
        if haskey(filled_vars, k) && filled_vars[k] != v
            predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
                _intersect_values(
                    filled_vars[k],
                    v,
                    predicted_arguments,
                    filled_indices,
                    filled_vars,
                    new_args,
                    new_filled_indices,
                    new_filled_vars,
                )
        end
    end
    return predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    calculated_output, new_args, new_filled_indices, new_filled_vars =
        all_abstractors[p][2](output, arguments, calculated_arguments)
    predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars = _intersect_values(
        predicted_arguments,
        filled_indices,
        filled_vars,
        new_args,
        new_filled_indices,
        new_filled_vars,
    )
    if !isempty(new_filled_indices)
        filled_indices = merge(filled_indices, new_filled_indices)
    end
    if !isempty(new_filled_vars)
        filled_vars = merge(filled_vars, new_filled_vars)
    end

    return calculated_output, vcat(predicted_arguments, reverse(new_args)), filled_indices, filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output::AbductibleValue,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    # @info "Running in reverse $p $output $arguments $calculated_arguments $predicted_arguments $filled_indices $filled_vars"
    return output,
    vcat(predicted_arguments, [output for _ in 1:length(arguments_of_type(p.t))]),
    filled_indices,
    filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output::EitherOptions,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    output_options = Dict()
    arguments_options = Dict[]
    filled_indices_options = DefaultDict(() -> Dict())
    filled_vars_options = DefaultDict(() -> Dict())
    for (h, val) in output.options
        fixed_hashes = Set([h])
        # op_calculated_arguments = [fix_option_hashes(fixed_hashes, v) for v in calculated_arguments]
        op_predicted_arguments = [fix_option_hashes(fixed_hashes, v) for v in predicted_arguments]
        op_filled_indices = Dict(i => fix_option_hashes(fixed_hashes, v) for (i, v) in filled_indices)
        op_filled_vars = Dict(k => fix_option_hashes(fixed_hashes, v) for (k, v) in filled_vars)

        calculated_output, new_args, new_filled_indices, new_filled_vars = _run_in_reverse(
            p,
            val,
            arguments,
            calculated_arguments,
            op_predicted_arguments,
            op_filled_indices,
            op_filled_vars,
        )

        predicted_arguments_op, filled_indices_op, filled_vars_op, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(
                op_predicted_arguments,
                op_filled_indices,
                op_filled_vars,
                new_args,
                new_filled_indices,
                new_filled_vars,
            )

        if isempty(arguments_options)
            for _ in 1:(length(new_args))
                push!(arguments_options, Dict())
            end
        end
        output_options[h] = calculated_output

        for i in 1:length(new_args)
            arguments_options[i][h] = new_args[i]
        end
        for (i, v) in filled_indices_op
            filled_indices_options[i][h] = v
        end
        for (k, v) in filled_vars_op
            filled_vars_options[k][h] = v
        end
        for (i, v) in new_filled_indices
            filled_indices_options[i][h] = v
        end
        for (k, v) in new_filled_vars
            filled_vars_options[k][h] = v
        end
    end

    out_args = []
    out_filled_indices = Dict()
    out_filled_vars = Dict()

    for args_options in arguments_options
        if allequal(values(args_options))
            push!(out_args, first(values(args_options)))
        elseif any(out == output for out in values(args_options))
            push!(out_args, output)
        else
            push!(out_args, EitherOptions(args_options))
        end
    end
    for (i, v) in filled_indices_options
        if allequal(values(v))
            out_filled_indices[i] = first(values(v))
        elseif any(out == output for out in values(v))
            out_filled_indices[i] = output
        else
            out_filled_indices[i] = EitherOptions(v)
        end
    end
    for (k, v) in filled_vars_options
        if allequal(values(v))
            out_filled_vars[k] = first(values(v))
        elseif any(out == output for out in values(v))
            out_filled_vars[k] = output
        else
            out_filled_vars[k] = EitherOptions(v)
        end
    end
    return EitherOptions(output_options), out_args, out_filled_indices, out_filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output::PatternWrapper,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    calculated_output, new_args, new_filled_indices, new_filled_vars = _run_in_reverse(
        p,
        output.value,
        arguments,
        calculated_arguments,
        predicted_arguments,
        filled_indices,
        filled_vars,
    )

    predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars = _intersect_values(
        predicted_arguments,
        filled_indices,
        filled_vars,
        new_args,
        new_filled_indices,
        new_filled_vars,
    )
    if !isempty(new_filled_indices)
        filled_indices = merge(filled_indices, new_filled_indices)
    end
    if !isempty(new_filled_vars)
        filled_vars = merge(filled_vars, new_filled_vars)
    end

    results = []
    for out in new_args
        push!(results, _wrap_wildcard(out))
    end
    return _wrap_wildcard(calculated_output), results, filled_indices, filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output::Union{Nothing,AnyObject},
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    try
        calculated_output, new_args, new_filled_indices, new_filled_vars =
            all_abstractors[p][2](output, arguments, calculated_arguments)
        predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(
                predicted_arguments,
                filled_indices,
                filled_vars,
                new_args,
                new_filled_indices,
                new_filled_vars,
            )
        if !isempty(new_filled_indices)
            filled_indices = merge(filled_indices, new_filled_indices)
        end
        if !isempty(new_filled_vars)
            filled_vars = merge(filled_vars, new_filled_vars)
        end
        return calculated_output, vcat(predicted_arguments, reverse(new_args)), filled_indices, filled_vars
    catch e
        if isa(e, MethodError)
            return output,
            vcat(predicted_arguments, [output for _ in 1:length(arguments_of_type(p.t))]),
            filled_indices,
            filled_vars
        else
            rethrow()
        end
    end
end

function _run_in_reverse(
    p::Apply,
    output::AbductibleValue,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    # @info "Running in reverse $p $output $arguments $calculated_arguments $predicted_arguments $filled_indices $filled_vars"
    env = Any[nothing for _ in 1:maximum(keys(filled_indices); init = 0)]
    for (i, v) in filled_indices
        env[end-i] = v
    end
    try
        calculated_output = p(env, filled_vars)
        # @info calculated_output
        if calculated_output isa Function
            error("Function output")
        end
        return calculated_output, predicted_arguments, filled_indices, filled_vars
    catch e
        if e isa InterruptException
            rethrow()
        end
        return @invoke _run_in_reverse(
            p::Apply,
            output::Any,
            arguments,
            calculated_arguments,
            predicted_arguments,
            filled_indices,
            filled_vars,
        )
    end
end

function _run_in_reverse(
    p::Apply,
    output,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    push!(arguments, p.x)
    push!(calculated_arguments, missing)
    calculated_output, predicted_arguments_, filled_indices, filled_vars =
        _run_in_reverse(p.f, output, arguments, calculated_arguments, predicted_arguments, filled_indices, filled_vars)
    pop!(arguments)
    pop!(calculated_arguments)
    arg_target = pop!(predicted_arguments_)
    if arg_target isa SkipArg
        return calculated_output, predicted_arguments_, filled_indices, filled_vars
    end
    arg_calculated_output, predicted_arguments_, filled_indices, filled_vars = _run_in_reverse(
        p.x,
        arg_target,
        arguments,
        calculated_arguments,
        predicted_arguments_,
        filled_indices,
        filled_vars,
    )
    # while arg_calculated_output != arg_target
    if arg_target isa AbductibleValue && arg_calculated_output != arg_target
        # @info "arg_target $arg_target"
        # @info "arg_calculated_output $arg_calculated_output"
        push!(arguments, p.x)
        push!(calculated_arguments, arg_calculated_output)
        calculated_output, predicted_arguments_, filled_indices, filled_vars = _run_in_reverse(
            p.f,
            output,
            arguments,
            calculated_arguments,
            predicted_arguments,
            filled_indices,
            filled_vars,
        )
        pop!(arguments)
        pop!(calculated_arguments)
        arg_target = pop!(predicted_arguments_)
        if arg_target isa SkipArg
            return calculated_output, predicted_arguments_, filled_indices, filled_vars
        end
        arg_calculated_output, predicted_arguments_, filled_indices, filled_vars = _run_in_reverse(
            p.x,
            arg_target,
            arguments,
            calculated_arguments,
            predicted_arguments_,
            filled_indices,
            filled_vars,
        )
        # @info "arg_target2 $arg_target"
        # @info "arg_calculated_output2 $arg_calculated_output"
    end
    return calculated_output, predicted_arguments_, filled_indices, filled_vars
end

function _run_in_reverse(
    p::FreeVar,
    output,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    if haskey(filled_vars, p.var_id)
        predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(predicted_arguments, filled_indices, filled_vars, [], Dict(), Dict(p.var_id => output))
        filled_vars = merge(filled_vars, new_filled_vars)
    else
        filled_vars[p.var_id] = output
    end
    return filled_vars[p.var_id], predicted_arguments, filled_indices, filled_vars
end

function _run_in_reverse(
    p::FreeVar,
    output::AbductibleValue,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    if !haskey(filled_vars, p.var_id)
        filled_vars[p.var_id] = output
    end
    return filled_vars[p.var_id], predicted_arguments, filled_indices, filled_vars
end

function _run_in_reverse(
    p::Index,
    output,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    if haskey(filled_indices, p.n)
        predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(predicted_arguments, filled_indices, filled_vars, [], Dict(p.n => output), Dict())
        filled_indices = merge(filled_indices, new_filled_indices)
    else
        filled_indices[p.n] = output
    end
    return filled_indices[p.n], predicted_arguments, filled_indices, filled_vars
end

function _run_in_reverse(
    p::Index,
    output::AbductibleValue,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    if !haskey(filled_indices, p.n)
        filled_indices[p.n] = output
    end
    return filled_indices[p.n], predicted_arguments, filled_indices, filled_vars
end

function _run_in_reverse(
    p::Invented,
    output,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    return _run_in_reverse(
        p.b,
        output,
        arguments,
        calculated_arguments,
        predicted_arguments,
        filled_indices,
        filled_vars,
    )
end

function _run_in_reverse(
    p::Abstraction,
    output,
    arguments,
    calculated_arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    calculated_output, predicted_arguments, filled_indices, filled_vars =
        _run_in_reverse(p.b, output, arguments, calculated_arguments, predicted_arguments, filled_indices, filled_vars)
    push!(predicted_arguments, filled_indices[0])
    delete!(filled_indices, 0)
    return output, predicted_arguments, Dict(i - 1 => v for (i, v) in filled_indices), filled_vars
end

function _run_in_reverse(p::Program, output)
    return _run_in_reverse(p, output, [], [], [], Dict(), Dict())
end

function run_in_reverse(p::Program, output)
    return _run_in_reverse(p, output, [], [], [], Dict(), Dict())[4]
end

_has_wildcard(v::PatternWrapper) = true
_has_wildcard(v) = false
_has_wildcard(v::AnyObject) = true
_has_wildcard(v::Vector) = any(_has_wildcard, v)
_has_wildcard(v::Tuple) = any(_has_wildcard, v)
_has_wildcard(v::Set) = any(_has_wildcard, v)

_wrap_wildcard(p::PatternWrapper) = p

function _wrap_wildcard(v)
    if _has_wildcard(v)
        return PatternWrapper(v)
    else
        return v
    end
end

function _wrap_wildcard(v::EitherOptions)
    options = Dict()
    for (h, op) in v.options
        options[h] = _wrap_wildcard(op)
    end
    return EitherOptions(options)
end

macro define_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        all_abstractors[prim] = [], ((v, _, _) -> (v, $(esc(reverse_function))(v), Dict(), Dict()))
    end
end

macro define_abductible_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        all_abstractors[prim] = [], ((v, _, args) -> (v, $(esc(reverse_function))(v, args), Dict(), Dict()))
    end
end

macro define_custom_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        all_abstractors[prim] = $(esc(reverse_function))
    end
end

_has_no_holes(p::Hole) = false
_has_no_holes(p::Apply) = _has_no_holes(p.f) && _has_no_holes(p.x)
_has_no_holes(p::Abstraction) = _has_no_holes(p.b)
_has_no_holes(p::Program) = true

_is_reversible_subfunction(p) = is_reversible(p) && _has_no_holes(p)

_is_possible_subfunction(p::Index, from_input, skeleton, path) = p.n != 0 || !isa(path[end], ArgTurn)
_is_possible_subfunction(p::Primitive, from_input, skeleton, path) = !from_input || haskey(all_abstractors, p)
_is_possible_subfunction(p::Invented, from_input, skeleton, path) = !from_input || is_reversible(p)
_is_possible_subfunction(p::FreeVar, from_input, skeleton, path) = true

__get_var_indices(p::Index) = [p.n]
__get_var_indices(p::FreeVar) = [-1]
__get_var_indices(p::Primitive) = []
__get_var_indices(p::Invented) = []
__get_var_indices(p::Apply) = vcat(__get_var_indices(p.f), __get_var_indices(p.x))
__get_var_indices(p::Abstraction) = [((i > 0) ? (i - 1) : i) for i in __get_var_indices(p.b) if (i > 0 || i == -1)]

function _has_external_vars(f)
    return !isempty(__get_var_indices(f))
end

function _calculate_dependent_vars(p::Invented, inputs, output, arguments, updates)
    return _calculate_dependent_vars(p.b, inputs, output, arguments, updates)
end

function _calculate_dependent_vars(p::FreeVar, inputs, output::Nothing, arguments, updates)
    return inputs[p.var_id], updates
end

function _calculate_dependent_vars(p::FreeVar, inputs, output, arguments, updates)
    if inputs[p.var_id] isa AbductibleValue
        updates[p.var_id] = output
        return output, updates
    end
    return inputs[p.var_id], updates
end

function _calculate_dependent_vars(p::Apply, inputs, output, arguments, updates)
    arg, updates = _calculate_dependent_vars(p.x, inputs, nothing, arguments, updates)
    push!(arguments, (p.x, arg))
    res = _calculate_dependent_vars(p.f, inputs, output, arguments, updates)
    pop!(arguments)
    return res
end

function _calculate_dependent_vars(p::Primitive, inputs, output::Nothing, arguments, updates)
    c = p.code
    i = 0
    while c isa Function
        if arguments[end-i][2] isa AbductibleValue
            return AbductibleValue(nothing, _ -> nothing), updates
        end
        c = c(arguments[end-i][2])
        i += 1
    end
    return c, updates
end

function _abduct_value(generator, output, known_input)
    return generator(output, known_input)
end

function _abduct_value(generator, output::Union{Nothing,AnyObject}, known_input)
    try
        return generator(output, known_input)
    catch e
        if isa(e, MethodError)
            return output
        else
            rethrow()
        end
    end
end

function _abduct_value(generator, output::EitherOptions, known_input)
    return EitherOptions(Dict(h => _abduct_value(generator, o, known_input) for (h, o) in output.options))
end

function _calculate_dependent_vars(p::Primitive, inputs, output, arguments, updates)
    rev_args = [Index(0) for _ in arguments]
    rev_p = _get_reversed_program(p, rev_args)
    rev_inputs = rev_p(output)
    fixer_value = nothing
    abductible_value = nothing
    abductible_program = nothing
    abductible_index = nothing
    for i in 1:length(rev_inputs)
        if rev_inputs[i] isa AbductibleValue
            if !isa(arguments[end-i+1][2], AbductibleValue)
                fixer_value = arguments[end-i+1][2]
            else
                abductible_program = arguments[end-i+1][1]
                abductible_value = rev_inputs[i]
                abductible_index = i
            end
        else
            _, updates = _calculate_dependent_vars(
                arguments[end-i+1][1],
                inputs,
                rev_inputs[i],
                arguments[i+1:length(arguments)],
                updates,
            )
        end
    end
    if fixer_value !== nothing && abductible_value !== nothing && abductible_program !== nothing
        _, updates = _calculate_dependent_vars(
            abductible_program,
            inputs,
            _abduct_value(abductible_value.generator, output, fixer_value),
            arguments[abductible_index+1:length(arguments)],
            updates,
        )
    end
    return output, updates
end

function calculate_dependent_vars(p, inputs, output)
    updated_inputs = _run_in_reverse(p, output, [], [], [], Dict(), inputs)[4]
    # @info updated_inputs
    return Dict(k => v for (k, v) in updated_inputs if !haskey(inputs, k) || inputs[k] != v)
end

include("repeat.jl")
include("cons.jl")
include("map.jl")
include("concat.jl")
include("range.jl")
include("rows.jl")
include("select.jl")
include("elements.jl")
include("zip.jl")
include("reverse.jl")
include("fold.jl")
include("tuple.jl")
include("adjoin.jl")
include("groupby.jl")
include("cluster.jl")
include("bool.jl")
include("int.jl")

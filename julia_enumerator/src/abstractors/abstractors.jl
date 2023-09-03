
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

function _get_reversed_program(p::Primitive, arguments)
    return all_abstractors[p][2](arguments)
end

function _get_reversed_program(p::Invented, arguments)
    _get_reversed_program(p.b, arguments)
end

noop(a)::Vector{Any} = [a]

function _get_reversed_program(p::Hole, arguments)
    return noop
end

function _get_reversed_program(p::FreeVar, arguments)
    return noop
end

function _get_reversed_program(p::Index, arguments)
    return noop
end

function _get_reversed_program(p::Apply, arguments)
    push!(arguments, p.x)
    reversed_f = _get_reversed_program(p.f, arguments)
    return reversed_f
end

function _get_reversed_program(p::Abstraction, arguments)
    # Only used in invented functions
    rev_f = _get_reversed_program(p.b, arguments)
    rev_a = _get_reversed_program(pop!(arguments), arguments)
    # TODO: Properly use rev_a
    return rev_f
end

function get_reversed_program(p::Program)
    return _get_reversed_program(p, [])
end

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

function _run_in_reverse(p::Primitive, output, arguments, predicted_arguments, filled_indices, filled_vars)
    new_args, new_filled_indices, new_filled_vars = all_abstractors[p][2](output, arguments)
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

    return vcat(predicted_arguments, reverse(new_args)), filled_indices, filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output::AbductibleValue,
    arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    return vcat(predicted_arguments, [output for _ in 1:length(arguments_of_type(p.t))]), filled_indices, filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output::EitherOptions,
    arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    arguments_options = Dict[]
    filled_indices_options = DefaultDict(() -> Dict())
    filled_vars_options = DefaultDict(() -> Dict())
    for (h, val) in output.options
        new_args, new_filled_indices, new_filled_vars = all_abstractors[p][2](val, arguments)
        fixed_hashes = Set([h])

        predicted_arguments_op, filled_indices_op, filled_vars_op, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(
                [fix_option_hashes(fixed_hashes, v) for v in predicted_arguments],
                Dict(i => fix_option_hashes(fixed_hashes, v) for (i, v) in filled_indices),
                Dict(k => fix_option_hashes(fixed_hashes, v) for (k, v) in filled_vars),
                new_args,
                new_filled_indices,
                new_filled_vars,
            )

        if isempty(arguments_options)
            for _ in 1:(length(predicted_arguments)+length(new_args))
                push!(arguments_options, Dict())
            end
        end
        for i in 1:length(predicted_arguments)
            arguments_options[i][h] = predicted_arguments_op[i]
        end
        for i in 1:length(new_args)
            arguments_options[end-i+1][h] = new_args[i]
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
    return out_args, out_filled_indices, out_filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output::PatternWrapper,
    arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    new_args, new_filled_indices, new_filled_vars = all_abstractors[p][2](output.value, arguments)

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
    return vcat(predicted_arguments, reverse(results)), filled_indices, filled_vars
end

function _run_in_reverse(
    p::Primitive,
    output::Union{Nothing,AnyObject},
    arguments,
    predicted_arguments,
    filled_indices,
    filled_vars,
)
    try
        new_args, new_filled_indices, new_filled_vars = all_abstractors[p][2](output, arguments)
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
        return vcat(predicted_arguments, reverse(new_args)), filled_indices, filled_vars
    catch e
        if isa(e, MethodError)
            return vcat(predicted_arguments, [output for _ in 1:length(arguments_of_type(p.t))]),
            filled_indices,
            filled_vars
        else
            rethrow()
        end
    end
end

function _run_in_reverse(p::Apply, output, arguments, predicted_arguments, filled_indices, filled_vars)
    push!(arguments, p.x)
    predicted_arguments, filled_indices, filled_vars =
        _run_in_reverse(p.f, output, arguments, predicted_arguments, filled_indices, filled_vars)
    pop!(arguments)
    arg_target = pop!(predicted_arguments)
    return _run_in_reverse(p.x, arg_target, arguments, predicted_arguments, filled_indices, filled_vars)
end

function _run_in_reverse(p::FreeVar, output, arguments, predicted_arguments, filled_indices, filled_vars)
    if haskey(filled_vars, p.var_id)
        predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(predicted_arguments, filled_indices, filled_vars, [], Dict(), Dict(p.var_id => output))
        filled_vars = merge(filled_vars, new_filled_vars)
    else
        filled_vars[p.var_id] = output
    end
    return predicted_arguments, filled_indices, filled_vars
end

function _run_in_reverse(p::Index, output, arguments, predicted_arguments, filled_indices, filled_vars)
    if haskey(filled_indices, p.n)
        predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(predicted_arguments, filled_indices, filled_vars, [], Dict(p.n => output), Dict())
        filled_indices = merge(filled_indices, new_filled_indices)
    else
        filled_indices[p.n] = output
    end
    return predicted_arguments, filled_indices, filled_vars
end

function _run_in_reverse(p::Invented, output, arguments, predicted_arguments, filled_indices, filled_vars)
    return _run_in_reverse(p.b, output, arguments, predicted_arguments, filled_indices, filled_vars)
end

function _run_in_reverse(p::Abstraction, output, arguments, predicted_arguments, filled_indices, filled_vars)
    predicted_arguments, filled_indices, filled_vars =
        _run_in_reverse(p.b, output, arguments, predicted_arguments, filled_indices, filled_vars)
    push!(predicted_arguments, filled_indices[0])
    delete!(filled_indices, 0)
    return predicted_arguments, Dict(i - 1 => v for (i, v) in filled_indices), filled_vars
end

function _run_in_reverse(p::Program, output)
    return _run_in_reverse(p, output, [], [], Dict(), Dict())
end

function run_in_reverse(p::Program, output)
    return _run_in_reverse(p, output, [], [], Dict(), Dict())[3]
end

function _reverse_eithers(_reverse_function, value)
    hashes = []
    outputs = Vector{Any}[]
    for (h, val) in value.options
        outs = _reverse_function(val)
        if isempty(outputs)
            for _ in 1:length(outs)
                push!(outputs, [])
            end
        end
        push!(hashes, h)
        for i in 1:length(outs)
            push!(outputs[i], outs[i])
        end
    end
    results = []
    for values in outputs
        if allequal(values)
            push!(results, values[1])
        elseif any(out == value for out in values)
            push!(results, value)
        else
            options = Dict(hashes[i] => values[i] for i in 1:length(hashes))
            push!(results, EitherOptions(options))
        end
    end
    return results
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

function _reverse_pattern(_reverse_function, value)
    outputs = _reverse_function(value.value)

    results = []
    for out in outputs
        push!(results, _wrap_wildcard(out))
    end
    return results
end

function _reverse_abductible(_reverse_function, value, n)
    results = [value for _ in 1:n]
    return results
end

function generic_reverse(rev_function, n)
    function _generic_reverse(arguments)
        rev_functions = []
        for _ in 1:n
            rev_a = _get_reversed_program(pop!(arguments), arguments)
            push!(rev_functions, rev_a)
        end
        function _reverse_function(value)::Vector{Any}
            rev_results = rev_function(value)
            return vcat([rev_functions[i](rev_results[i]) for i in 1:n]...)
        end
        function _reverse_function(value::Union{Nothing,AnyObject})::Vector{Any}
            try
                rev_results = rev_function(value)
                return vcat([rev_functions[i](rev_results[i]) for i in 1:n]...)
            catch e
                if isa(e, MethodError)
                    return vcat([rev_functions[i](value) for i in 1:n]...)
                else
                    rethrow()
                end
            end
        end
        function _reverse_function(value::EitherOptions)::Vector{Any}
            _reverse_eithers(_reverse_function, value)
        end
        function _reverse_function(value::PatternWrapper)::Vector{Any}
            _reverse_pattern(_reverse_function, value)
        end
        function _reverse_function(value::AbductibleValue)::Vector{Any}
            _reverse_abductible(_reverse_function, value, n)
        end
        return _reverse_function
    end
    return _generic_reverse
end

macro define_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        # local rev = generic_reverse($(esc(reverse_function)), length(arguments_of_type(prim.t)))
        all_abstractors[prim] = [], ((v, _) -> ($(esc(reverse_function))(v), Dict(), Dict()))
    end
end

macro define_custom_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        local out = $(esc(reverse_function))
        all_abstractors[prim] = out
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

function _get_var_indices(f, n)
    raw_indices_mapping = __get_var_indices(f)
    external_vars = 0
    for i in raw_indices_mapping
        if i == -1 || i > n - 1
            external_vars += 1
        end
    end
    indices_mapping = []
    marked_external = 0
    for i in raw_indices_mapping
        if i == -1 || i > n - 1
            marked_external += 1
            push!(indices_mapping, marked_external)
        else
            push!(indices_mapping, external_vars + n - i)
        end
    end
    return indices_mapping, external_vars
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
    _, updates = _calculate_dependent_vars(p, inputs, output, [], Dict())
    return updates
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

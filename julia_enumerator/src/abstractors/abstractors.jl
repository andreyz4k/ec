
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

mutable struct ReverseRunContext
    arguments::Vector
    predicted_arguments::Vector
    calculated_arguments::Vector
    filled_indices::Dict
    filled_vars::Dict
end

ReverseRunContext() = ReverseRunContext([], [], [], Dict(), Dict())

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
        error("Can't intersect values $old_v and $v")
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

function _run_in_reverse(p::Primitive, output, context)
    calculated_output, new_context = all_abstractors[p][2](output, context)
    context.predicted_arguments,
    context.filled_indices,
    context.filled_vars,
    new_args,
    new_filled_indices,
    new_filled_vars = _intersect_values(
        context.predicted_arguments,
        context.filled_indices,
        context.filled_vars,
        new_context.predicted_arguments,
        new_context.filled_indices,
        new_context.filled_vars,
    )
    if !isempty(new_filled_indices)
        merge!(context.filled_indices, new_filled_indices)
    end
    if !isempty(new_filled_vars)
        merge!(context.filled_vars, new_filled_vars)
    end
    context.predicted_arguments = vcat(context.predicted_arguments, reverse(new_args))

    return calculated_output, context
end

function _run_in_reverse(p::Primitive, output::AbductibleValue, context)
    # @info "Running in reverse $p $output $arguments $calculated_arguments $predicted_arguments $filled_indices $filled_vars"
    for _ in 1:length(arguments_of_type(p.t))
        push!(context.predicted_arguments, output)
    end
    return output, context
end

function _run_in_reverse(p::Primitive, output::EitherOptions, context)
    output_options = Dict()
    arguments_options = Dict[]
    filled_indices_options = DefaultDict(() -> Dict())
    filled_vars_options = DefaultDict(() -> Dict())
    for (h, val) in output.options
        fixed_hashes = Set([h])
        # op_calculated_arguments = [fix_option_hashes(fixed_hashes, v) for v in calculated_arguments]
        op_predicted_arguments = [fix_option_hashes(fixed_hashes, v) for v in context.predicted_arguments]
        op_filled_indices = Dict(i => fix_option_hashes(fixed_hashes, v) for (i, v) in context.filled_indices)
        op_filled_vars = Dict(k => fix_option_hashes(fixed_hashes, v) for (k, v) in context.filled_vars)

        calculated_output, new_context = _run_in_reverse(
            p,
            val,
            ReverseRunContext(
                context.arguments,
                op_predicted_arguments,
                context.calculated_arguments,
                op_filled_indices,
                op_filled_vars,
            ),
        )

        predicted_arguments_op, filled_indices_op, filled_vars_op, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(
                op_predicted_arguments,
                op_filled_indices,
                op_filled_vars,
                new_context.predicted_arguments,
                new_context.filled_indices,
                new_context.filled_vars,
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
    return EitherOptions(output_options),
    ReverseRunContext(context.arguments, out_args, context.calculated_arguments, out_filled_indices, out_filled_vars)
end

function _run_in_reverse(p::Primitive, output::PatternWrapper, context)
    calculated_output, new_context = _run_in_reverse(p, output.value, context)

    context.predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
        _intersect_values(
            context.predicted_arguments,
            context.filled_indices,
            context.filled_vars,
            new_context.predicted_arguments,
            new_context.filled_indices,
            new_context.filled_vars,
        )
    if !isempty(new_filled_indices)
        context.filled_indices = merge(filled_indices, new_filled_indices)
    end
    if !isempty(new_filled_vars)
        context.filled_vars = merge(filled_vars, new_filled_vars)
    end

    for out in reverse(new_args)
        push!(context.predicted_arguments, _wrap_wildcard(out))
    end
    return _wrap_wildcard(calculated_output), context
end

function _run_in_reverse(p::Primitive, output::Union{Nothing,AnyObject}, context)
    try
        calculated_output, new_context = all_abstractors[p][2](output, context)
        predicted_arguments, filled_indices, filled_vars, new_args, new_filled_indices, new_filled_vars =
            _intersect_values(
                context.predicted_arguments,
                context.filled_indices,
                context.filled_vars,
                new_context.predicted_arguments,
                new_context.filled_indices,
                new_context.filled_vars,
            )
        if !isempty(new_filled_indices)
            context.filled_indices = merge(filled_indices, filled_indices)
        end
        if !isempty(new_filled_vars)
            context.filled_vars = merge(filled_vars, filled_vars)
        end
        context.predicted_arguments = vcat(predicted_arguments, reverse(new_args))
        return calculated_output, context
    catch e
        if isa(e, MethodError)
            context.predicted_arguments =
                vcat(context.predicted_arguments, [output for _ in 1:length(arguments_of_type(p.t))])
            return output, context
        else
            rethrow()
        end
    end
end

function _run_in_reverse(p::Apply, output::AbductibleValue, context)
    # @info "Running in reverse $p $output $arguments $calculated_arguments $predicted_arguments $filled_indices $filled_vars"
    env = Any[nothing for _ in 1:maximum(keys(context.filled_indices); init = 0)]
    for (i, v) in context.filled_indices
        env[end-i] = v
    end
    try
        calculated_output = p(env, context.filled_vars)
        # @info calculated_output
        if calculated_output isa Function
            error("Function output")
        end
        return calculated_output, context
    catch e
        if e isa InterruptException
            rethrow()
        end
        return @invoke _run_in_reverse(p::Apply, output::Any, context)
    end
end

function _run_in_reverse(p::Apply, output, context)
    push!(context.arguments, p.x)
    push!(context.calculated_arguments, missing)
    original_predicted_arguments = copy(context.predicted_arguments)
    calculated_output, context = _run_in_reverse(p.f, output, context)
    pop!(context.arguments)
    pop!(context.calculated_arguments)
    arg_target = pop!(context.predicted_arguments)
    if arg_target isa SkipArg
        return calculated_output, context
    end
    arg_calculated_output, context = _run_in_reverse(p.x, arg_target, context)
    # while arg_calculated_output != arg_target
    if arg_target isa AbductibleValue && arg_calculated_output != arg_target
        # @info "arg_target $arg_target"
        # @info "arg_calculated_output $arg_calculated_output"
        push!(context.arguments, p.x)
        push!(context.calculated_arguments, arg_calculated_output)
        context.predicted_arguments = original_predicted_arguments
        calculated_output, context = _run_in_reverse(p.f, output, context)
        pop!(context.arguments)
        pop!(context.calculated_arguments)
        arg_target = pop!(context.predicted_arguments)
        if arg_target isa SkipArg
            return calculated_output, context
        end
        arg_calculated_output, context = _run_in_reverse(p.x, arg_target, context)
        # @info "arg_target2 $arg_target"
        # @info "arg_calculated_output2 $arg_calculated_output"
    end
    return calculated_output, context
end

function _run_in_reverse(p::FreeVar, output, context)
    if haskey(context.filled_vars, p.var_id)
        context.predicted_arguments,
        context.filled_indices,
        filled_vars,
        new_args,
        new_filled_indices,
        new_filled_vars = _intersect_values(
            context.predicted_arguments,
            context.filled_indices,
            context.filled_vars,
            [],
            Dict(),
            Dict(p.var_id => output),
        )
        context.filled_vars = merge(filled_vars, new_filled_vars)
    else
        context.filled_vars[p.var_id] = output
    end
    return context.filled_vars[p.var_id], context
end

function _run_in_reverse(p::FreeVar, output::AbductibleValue, context)
    if !haskey(context.filled_vars, p.var_id)
        context.filled_vars[p.var_id] = output
    end
    return context.filled_vars[p.var_id], context
end

function _run_in_reverse(p::Index, output, context)
    if haskey(context.filled_indices, p.n)
        context.predicted_arguments,
        filled_indices,
        context.filled_vars,
        new_args,
        new_filled_indices,
        new_filled_vars = _intersect_values(
            context.predicted_arguments,
            context.filled_indices,
            context.filled_vars,
            [],
            Dict(p.n => output),
            Dict(),
        )
        context.filled_indices = merge(filled_indices, new_filled_indices)
    else
        context.filled_indices[p.n] = output
    end
    return context.filled_indices[p.n], context
end

function _run_in_reverse(p::Index, output::AbductibleValue, context)
    if !haskey(context.filled_indices, p.n)
        context.filled_indices[p.n] = output
    end
    return context.filled_indices[p.n], context
end

function _run_in_reverse(p::Invented, output, context)
    return _run_in_reverse(p.b, output, context)
end

function _run_in_reverse(p::Abstraction, output, context::ReverseRunContext)
    context.filled_indices = Dict{Int64,Any}(i + 1 => v for (i, v) in context.filled_indices)
    if !ismissing(context.calculated_arguments[end])
        context.filled_indices[0] = context.calculated_arguments[end]
    end
    pop!(context.calculated_arguments)
    calculated_output, context = _run_in_reverse(p.b, output, context)
    push!(context.predicted_arguments, context.filled_indices[0])
    push!(context.calculated_arguments, calculated_output)

    context.filled_indices = Dict{Int64,Any}(i - 1 => v for (i, v) in context.filled_indices if i > 0)
    return output, context
end

function _run_in_reverse(p::Program, output)
    return _run_in_reverse(p, output, ReverseRunContext())
end

function run_in_reverse(p::Program, output)
    return _run_in_reverse(p, output, ReverseRunContext())[2].filled_vars
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
        all_abstractors[prim] = [],
        (
            (v, ctx) -> (
                v,
                ReverseRunContext(ctx.arguments, $(esc(reverse_function))(v), ctx.calculated_arguments, Dict(), Dict()),
            )
        )
    end
end

macro define_abductible_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        all_abstractors[prim] = [],
        (
            (v, ctx) -> (
                v,
                ReverseRunContext(
                    ctx.arguments,
                    $(esc(reverse_function))(v, ctx.calculated_arguments),
                    ctx.calculated_arguments,
                    Dict(),
                    Dict(),
                ),
            )
        )
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

function calculate_dependent_vars(p, inputs, output)
    context = ReverseRunContext([], [], [], Dict(), copy(inputs))
    updated_inputs = _run_in_reverse(p, output, context)[2].filled_vars
    return Dict(
        k => v for (k, v) in updated_inputs if (!haskey(inputs, k) || inputs[k] != v) && !isa(v, AbductibleValue)
    )
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

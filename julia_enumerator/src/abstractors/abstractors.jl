
all_abstractors = Dict{Program,Tuple{Vector,Any}}()

function _get_custom_arg_checkers(p::Primitive)
    if haskey(all_abstractors, p)
        [c[2] for c in all_abstractors[p][1]]
    else
        []
    end
end

_get_custom_arg_checkers(p::Index) = []
_get_custom_arg_checkers(p::FreeVar) = []

function _get_custom_arg_checkers(p::Invented)
    checkers, indices_checkers = __get_custom_arg_chekers(p, nothing, Dict())
    @assert isempty(indices_checkers)
    return checkers
end

function __get_custom_arg_chekers(p::Primitive, checker::Nothing, indices_checkers::Dict)
    if haskey(all_abstractors, p)
        all_abstractors[p][1], indices_checkers
    else
        [], indices_checkers
    end
end

function __get_custom_arg_chekers(p::Primitive, checker, indices_checkers::Dict)
    arg_count = length(arguments_of_type(p.t))
    if haskey(all_abstractors, p)
        custom_checkers = all_abstractors[p][1]
        out_checkers = []
        for c in custom_checkers
            if c[2] == checker
                push!(out_checkers, c[2])
            else
                combined = (args...) -> c[2](args...) && checker(args...)
                push!(out_checkers, combined)
            end
        end
        for _ in 1:arg_count-length(custom_checkers)
            push!(out_checkers, checker)
        end
        out_checkers, indices_checkers
    else
        [checker for _ in 1:arg_count], indices_checkers
    end
end

function __get_custom_arg_chekers(p::Invented, checker, indices_checkers::Dict)
    return __get_custom_arg_chekers(p.b, checker, indices_checkers)
end

function __get_custom_arg_chekers(p::Apply, checker, indices_checkers::Dict)
    checkers, indices_checkers = __get_custom_arg_chekers(p.f, checker, indices_checkers)
    if !isempty(checkers)
        _, indices_checkers = __get_custom_arg_chekers(p.x, checkers[1], indices_checkers)
    else
        _, indices_checkers = __get_custom_arg_chekers(p.x, nothing, indices_checkers)
    end
    return checkers[2:end], indices_checkers
end

function __get_custom_arg_chekers(p::Index, checker::Nothing, indices_checkers::Dict)
    return [], indices_checkers
end

function __get_custom_arg_chekers(p::Index, checker, indices_checkers::Dict)
    if haskey(indices_checkers, p.n)
        if indices_checkers[p.n] == checker
            return [], indices_checkers
        else
            combined = (args...) -> indices_checkers[p.n](args...) && checker(args...)
            indices_checkers[p.n] = combined
            return [], indices_checkers
        end
    else
        indices_checkers[p.n] = checker
        return [], indices_checkers
    end
end

function __get_custom_arg_chekers(p::Abstraction, checker::Nothing, indices_checkers::Dict)
    chekers, indices_checkers = __get_custom_arg_chekers(p.b, checker, Dict(i + 1 => c for (i, c) in indices_checkers))
    if haskey(indices_checkers, 0)
        out_checkers = vcat([indices_checkers[0]], chekers)
    elseif !isempty(chekers)
        out_checkers = vcat([nothing], chekers)
    else
        out_checkers = []
    end
    return out_checkers, Dict(i - 1 => c for (i, c) in indices_checkers if i > 0)
end

_fill_args(p::Program, environment) = p
_fill_args(p::Invented, environment) = _fill_args(p.b, environment)
_fill_args(p::Apply, environment) = Apply(_fill_args(p.f, environment), _fill_args(p.x, environment))
_fill_args(p::Abstraction, environment) = Abstraction(_fill_args(p.b, Dict(i + 1 => c for (i, c) in environment)))

function _fill_args(p::Index, environment)
    if haskey(environment, p.n)
        return environment[p.n]
    else
        return p
    end
end

function _is_reversible(p::Primitive, environment, args)
    if haskey(all_abstractors, p)
        [c[1] for c in all_abstractors[p][1]]
    else
        nothing
    end
end

function _is_reversible(p::Apply, environment, args)
    checkers = _is_reversible(p.f, environment, vcat(args, [p.x]))
    if isnothing(checkers)
        return nothing
    end
    filled_x = _fill_args(p.x, environment)
    if isempty(checkers)
        if isa(filled_x, Hole)
            if !isarrow(filled_x.t)
                return checkers
            else
                return nothing
            end
        end
        if isa(filled_x, Index) || isa(filled_x, FreeVar)
            return checkers
        end
        checker = is_reversible
    else
        checker = checkers[1]
        if isnothing(checker)
            checker = is_reversible
        end
    end
    if !checker(filled_x)
        return nothing
    else
        return view(checkers, 2:length(checkers))
    end
end

_is_reversible(p::Invented, environment, args) = _is_reversible(p.b, environment, args)

function _is_reversible(p::Abstraction, environment, args)
    environment = Dict(i + 1 => c for (i, c) in environment)
    if !isempty(args)
        environment[0] = args[end]
    end
    return _is_reversible(p.b, environment, view(args, 1:length(args)-1))
end

_is_reversible(p::Program, environment, args) = nothing

is_reversible(p::Program)::Bool = !isnothing(_is_reversible(p, Dict(), []))

struct SkipArg end

mutable struct ReverseRunContext
    arguments::Vector{Any}
    predicted_arguments::Vector{Any}
    calculated_arguments::Vector{Any}
    filled_indices::Dict{Int64,Any}
    filled_vars::Dict{UInt64,Any}
end

ReverseRunContext() = ReverseRunContext([], [], [], Dict(), Dict())

struct UnifyError <: Exception end

_unify_values(v1, v2::AnyObject, check_pattern) = v1
_unify_values(v1::AnyObject, v2, check_pattern) = v2
_unify_values(v1::AnyObject, v2::AnyObject, check_pattern) = v2

_unify_values(v1::PatternWrapper, v2, check_pattern) = _wrap_wildcard(_unify_values(v1.value, v2, true))
_unify_values(v1, v2::PatternWrapper, check_pattern) = _wrap_wildcard(_unify_values(v1, v2.value, true))
_unify_values(v1::PatternWrapper, v2::PatternWrapper, check_pattern) =
    _wrap_wildcard(_unify_values(v1.value, v2.value, true))

_unify_values(v1::PatternWrapper, v2::AnyObject, check_pattern) = v1
_unify_values(v1::AnyObject, v2::PatternWrapper, check_pattern) = v2

_unify_values(v1::AbductibleValue, v2, check_pattern) = _wrap_abductible(_unify_values(v1.value, v2, true))
_unify_values(v1, v2::AbductibleValue, check_pattern) = _wrap_abductible(_unify_values(v1, v2.value, true))
_unify_values(v1::AbductibleValue, v2::AbductibleValue, check_pattern) =
    _wrap_abductible(_unify_values(v1.value, v2.value, true))

_unify_values(v1::AbductibleValue, v2::AnyObject, check_pattern) = v1
_unify_values(v1::AnyObject, v2::AbductibleValue, check_pattern) = v2

_unify_values(v1::AbductibleValue, v2::PatternWrapper, check_pattern) =
    _wrap_abductible(_unify_values(v1.value, v2.value, true))
_unify_values(v1::PatternWrapper, v2::AbductibleValue, check_pattern) =
    _wrap_abductible(_unify_values(v1.value, v2.value, true))

function _unify_values(v1::EitherOptions, v2::PatternWrapper, check_pattern)
    @invoke _unify_values(v1::EitherOptions, v2::Any, check_pattern)
end

function _unify_values(v1::EitherOptions, v2::AbductibleValue, check_pattern)
    @invoke _unify_values(v1::EitherOptions, v2::Any, check_pattern)
end

function _unify_values(v1::EitherOptions, v2, check_pattern)
    options = Dict()
    for (h, v) in v1.options
        try
            options[h] = _unify_values(v, v2, check_pattern)
        catch e
            if isa(e, InterruptException)
                rethrow()
            end
        end
    end
    return EitherOptions(options)
end

function _unify_values(v1::PatternWrapper, v2::EitherOptions, check_pattern)
    @invoke _unify_values(v1::Any, v2::EitherOptions, check_pattern)
end

function _unify_values(v1::AbductibleValue, v2::EitherOptions, check_pattern)
    @invoke _unify_values(v1::Any, v2::EitherOptions, check_pattern)
end

function _unify_values(v1, v2::EitherOptions, check_pattern)
    options = Dict()
    for (h, v) in v2.options
        try
            options[h] = _unify_values(v1, v, check_pattern)
        catch e
            if isa(e, InterruptException)
                rethrow()
            end
        end
    end
    return EitherOptions(options)
end

function _unify_values(v1::EitherOptions, v2::EitherOptions, check_pattern)
    options = Dict()
    for (h, v) in v1.options
        if haskey(v2.options, h)
            options[h] = _unify_values(v, v2.options[h], check_pattern)
        end
    end
    return EitherOptions(options)
end

function _unify_values(v1, v2, check_pattern)
    if v1 == v2
        return v1
    end
    throw(UnifyError())
end

function _unify_values(v1::Array, v2::Array, check_pattern)
    if length(v1) != length(v2)
        throw(UnifyError())
    end
    if v1 == v2
        return v1
    end
    if !check_pattern
        throw(UnifyError())
    end
    return [_unify_values(v1[i], v2[i], check_pattern) for i in 1:length(v1)]
end

function _unify_values(v1::Tuple, v2::Tuple, check_pattern)
    if length(v1) != length(v2)
        throw(UnifyError())
    end
    if v1 == v2
        return v1
    end
    if !check_pattern
        throw(UnifyError())
    end
    return tuple((_unify_values(v1[i], v2[i], check_pattern) for i in 1:length(v1))...)
end

function _unify_values(v1::Set, v2::Set, check_pattern)
    if length(v1) != length(v2)
        throw(UnifyError())
    end
    if v1 == v2
        return v1
    end
    if !check_pattern
        throw(UnifyError())
    end
    options = []
    f_v = first(v1)
    if in(f_v, v2)
        rest = _unify_values(v1 - Set([f_v]), v2 - Set([f_v]), check_pattern)
        if isa(rest, EitherOptions)
            for (h, v) in rest.options
                push!(options, union(Set([f_v]), v))
            end
        else
            push!(rest, f_v)
            return rest
        end
    else
        for v in v2
            try
                unified_v = _unify_values(f_v, v, check_pattern)
                rest = _unify_values(v1 - Set([f_v]), v2 - Set([v]), check_pattern)
                if isa(rest, EitherOptions)
                    for (h, val) in rest.options
                        push!(options, union(Set([unified_v]), val))
                    end
                else
                    push!(options, union(Set([unified_v]), rest))
                end
            catch e
                if isa(e, InterruptException)
                    rethrow()
                end
            end
        end
    end
    if isempty(options)
        throw(UnifyError())
    elseif length(options) == 1
        return options[1]
    else
        return EitherOptions(Dict(rand(UInt64) => option for option in options))
    end
end

function _preprocess_options(args_options, output)
    if any(isa(out, AbductibleValue) for out in values(args_options))
        abd = first(out for out in values(args_options) if isa(out, AbductibleValue))
        for (h, val) in args_options
            if !isa(val, AbductibleValue) && abd.value == val
                args_options[h] = abd
            end
        end
    end
    return EitherOptions(args_options)
end

function _run_in_reverse(p, output, context, splitter::EitherOptions)
    # @info "Running in reverse $p $output $context"
    output_options = Dict()
    arguments_options = Dict[]
    filled_indices_options = DefaultDict(() -> Dict())
    filled_vars_options = DefaultDict(() -> Dict())
    for (h, _) in splitter.options
        fixed_hashes = Set([h])
        op_calculated_arguments = [fix_option_hashes(fixed_hashes, v) for v in context.calculated_arguments]
        op_predicted_arguments = [fix_option_hashes(fixed_hashes, v) for v in context.predicted_arguments]
        op_filled_indices = Dict(i => fix_option_hashes(fixed_hashes, v) for (i, v) in context.filled_indices)
        op_filled_vars = Dict(k => fix_option_hashes(fixed_hashes, v) for (k, v) in context.filled_vars)

        try
            calculated_output, new_context = _run_in_reverse(
                p,
                fix_option_hashes(fixed_hashes, output),
                ReverseRunContext(
                    context.arguments,
                    op_predicted_arguments,
                    op_calculated_arguments,
                    op_filled_indices,
                    op_filled_vars,
                ),
            )

            if isempty(arguments_options)
                for _ in 1:(length(new_context.predicted_arguments))
                    push!(arguments_options, Dict())
                end
            end
            output_options[h] = calculated_output

            for i in 1:length(new_context.predicted_arguments)
                arguments_options[i][h] = new_context.predicted_arguments[i]
            end
            for (i, v) in new_context.filled_indices
                filled_indices_options[i][h] = v
            end
            for (k, v) in new_context.filled_vars
                filled_vars_options[k][h] = v
            end
        catch e
            if isa(e, InterruptException) || isa(e, MethodError)
                rethrow()
            end
            # bt = catch_backtrace()
            # @error "Got error" exception = (e, bt)
        end
    end

    out_args = []
    out_filled_indices = Dict()
    out_filled_vars = Dict()

    # @info arguments_options
    for args_options in arguments_options
        push!(out_args, _preprocess_options(args_options, output))
    end
    for (i, v) in filled_indices_options
        out_filled_indices[i] = _preprocess_options(v, output)
    end
    for (k, v) in filled_vars_options
        out_filled_vars[k] = _preprocess_options(v, output)
    end
    out_context = ReverseRunContext(
        context.arguments,
        out_args,
        context.calculated_arguments,
        out_filled_indices,
        out_filled_vars,
    )
    # @info "Output options $output_options"
    # @info "Output context $out_context"
    return EitherOptions(output_options), out_context
end

function _run_in_reverse(p, output::EitherOptions, context)
    return _run_in_reverse(p, output, context, output)
end

function _run_in_reverse(p, output, context)
    for (i, v) in context.filled_indices
        if isa(v, EitherOptions)
            return _run_in_reverse(p, output, context, v)
        end
    end
    for (k, v) in context.filled_vars
        if isa(v, EitherOptions)
            return _run_in_reverse(p, output, context, v)
        end
    end
    return __run_in_reverse(p, output, context)
end

function __run_in_reverse(p::Primitive, output, context)
    # @info "Running in reverse $p $output $context"
    return all_abstractors[p][2](output, context)
end

function __run_in_reverse(p::Primitive, output::AbductibleValue, context)
    # @info "Running in reverse $p $output $context"
    try
        calculated_output, new_context = all_abstractors[p][2](output, context)
        new_context.predicted_arguments = [_wrap_abductible(arg) for arg in new_context.predicted_arguments]
        return _wrap_abductible(calculated_output), new_context
    catch e
        if isa(e, InterruptException)
            rethrow()
        end
        results = []
        for i in length(arguments_of_type(p.t))-1:-1:0
            if ismissing(context.calculated_arguments[end-i])
                push!(results, AbductibleValue(any_object))
            else
                push!(results, context.calculated_arguments[end-i])
            end
        end
        return output,
        ReverseRunContext(
            context.arguments,
            vcat(context.predicted_arguments, results),
            context.calculated_arguments,
            context.filled_indices,
            context.filled_vars,
        )
    end
end

function __run_in_reverse(p::Primitive, output::PatternWrapper, context)
    # @info "Running in reverse $p $output $context"
    calculated_output, new_context = __run_in_reverse(p, output.value, context)

    new_context.predicted_arguments = [_wrap_wildcard(arg) for arg in new_context.predicted_arguments]

    return _wrap_wildcard(calculated_output), new_context
end

function __run_in_reverse(p::Primitive, output::Union{Nothing,AnyObject}, context)
    # @info "Running in reverse $p $output $context"
    try
        return all_abstractors[p][2](output, context)
    catch e
        # @info e
        # bt = catch_backtrace()
        # @error e exception = (e, bt)
        if isa(e, MethodError)
            return output,
            ReverseRunContext(
                context.arguments,
                vcat(context.predicted_arguments, [output for _ in 1:length(arguments_of_type(p.t))]),
                context.calculated_arguments,
                context.filled_indices,
                context.filled_vars,
            )
        else
            rethrow()
        end
    end
end

function __run_in_reverse(p::Apply, output::AbductibleValue, context)
    # @info "Running in reverse $p $output $context"
    env = Any[nothing for _ in 1:maximum(keys(context.filled_indices); init = -1)+1]
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
        return @invoke __run_in_reverse(p::Apply, output::Any, context)
    end
end

function _precalculate_arg(p, context)
    env = Any[missing for _ in 1:maximum(keys(context.filled_indices); init = -1)+1]
    for (i, v) in context.filled_indices
        env[end-i] = v
    end
    try
        # @info "Precalculating $p with $env and $(context.filled_vars)"
        calculated_output = p(env, context.filled_vars)
        # @info calculated_output
        if isa(calculated_output, Function) ||
           isa(calculated_output, AbductibleValue) ||
           isa(calculated_output, PatternWrapper)
            return missing
        end
        return calculated_output
    catch e
        if e isa InterruptException
            rethrow()
        end
        return missing
    end
end

function __run_in_reverse(p::Apply, output, context)
    # @info "Running in reverse $p $output $context"
    precalculated_arg = _precalculate_arg(p.x, context)
    # @info "Precalculated arg for $(p.x) is $precalculated_arg"
    calculated_output, arg_context = _run_in_reverse(
        p.f,
        output,
        ReverseRunContext(
            vcat(context.arguments, [p.x]),
            context.predicted_arguments,
            vcat(context.calculated_arguments, [precalculated_arg]),
            context.filled_indices,
            context.filled_vars,
        ),
    )
    pop!(arg_context.arguments)
    pop!(arg_context.calculated_arguments)
    arg_target = pop!(arg_context.predicted_arguments)
    if arg_target isa SkipArg
        return calculated_output, arg_context
    end
    arg_calculated_output, out_context = _run_in_reverse(p.x, arg_target, arg_context)

    # @info "arg_target $arg_target"
    # @info "arg_calculated_output $arg_calculated_output"
    if arg_calculated_output != arg_target
        # if arg_target isa AbductibleValue && arg_calculated_output != arg_target
        calculated_output, arg_context = _run_in_reverse(
            p.f,
            calculated_output,
            ReverseRunContext(
                vcat(context.arguments, [p.x]),
                context.predicted_arguments,
                vcat(context.calculated_arguments, [arg_calculated_output]),
                out_context.filled_indices,
                out_context.filled_vars,
            ),
        )
        pop!(arg_context.arguments)
        pop!(arg_context.calculated_arguments)
        arg_target = pop!(arg_context.predicted_arguments)
        if arg_target isa SkipArg
            return calculated_output, arg_context
        end
        arg_calculated_output, out_context = _run_in_reverse(p.x, arg_target, arg_context)
        # @info "arg_target2 $arg_target"
        # @info "arg_calculated_output2 $arg_calculated_output"
    end
    # @info "Calculated output for $p $calculated_output"
    return calculated_output, out_context
end

function __run_in_reverse(p::FreeVar, output, context)
    # @info "Running in reverse $p $output $context"
    if haskey(context.filled_vars, p.var_id)
        context.filled_vars[p.var_id] = _unify_values(context.filled_vars[p.var_id], output, false)
    else
        context.filled_vars[p.var_id] = output
    end
    # @info context
    return context.filled_vars[p.var_id], context
end

function __run_in_reverse(p::Index, output, context)
    # @info "Running in reverse $p $output $context"
    if haskey(context.filled_indices, p.n)
        context.filled_indices[p.n] = _unify_values(context.filled_indices[p.n], output, false)
    else
        context.filled_indices[p.n] = output
    end
    # @info context
    return context.filled_indices[p.n], context
end

function __run_in_reverse(p::Invented, output, context)
    return __run_in_reverse(p.b, output, context)
end

function __run_in_reverse(p::Abstraction, output, context::ReverseRunContext)
    # @info "Running in reverse $p $output $context"
    in_filled_indices = Dict{Int64,Any}(i + 1 => v for (i, v) in context.filled_indices)
    if !ismissing(context.calculated_arguments[end])
        in_filled_indices[0] = context.calculated_arguments[end]
    end
    calculated_output, out_context = _run_in_reverse(
        p.b,
        output,
        ReverseRunContext(
            context.arguments,
            context.predicted_arguments,
            context.calculated_arguments[1:end-1],
            in_filled_indices,
            context.filled_vars,
        ),
    )
    push!(out_context.predicted_arguments, out_context.filled_indices[0])
    push!(out_context.calculated_arguments, calculated_output)

    out_context.filled_indices = Dict{Int64,Any}(i - 1 => v for (i, v) in out_context.filled_indices if i > 0)
    return output, out_context
end

function run_in_reverse(p::Program, output)
    # @info p
    computed_output, context = _run_in_reverse(p, output, ReverseRunContext())
    if computed_output != output
        error("Output mismatch $computed_output != $output")
    end
    return context.filled_vars
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

_unwrap_abductible(v::AbductibleValue) = _unwrap_abductible(v.value)
_unwrap_abductible(v::PatternWrapper) = _unwrap_abductible(v.value)
function _unwrap_abductible(v::Array)
    res = [_unwrap_abductible(v) for v in v]
    return reshape(res, size(v))
end
_unwrap_abductible(v::Tuple) = tuple((_unwrap_abductible(v) for v in v)...)
_unwrap_abductible(v::Set) = Set([_unwrap_abductible(v) for v in v])
_unwrap_abductible(v) = v

_wrap_abductible(v::AbductibleValue) = v

function _wrap_abductible(v)
    if _has_wildcard(v)
        return AbductibleValue(_unwrap_abductible(v))
    else
        return v
    end
end

function _wrap_abductible(v::EitherOptions)
    options = Dict()
    for (h, op) in v.options
        options[h] = _wrap_abductible(op)
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
                ReverseRunContext(
                    ctx.arguments,
                    vcat(ctx.predicted_arguments, reverse($(esc(reverse_function))(v))),
                    ctx.calculated_arguments,
                    ctx.filled_indices,
                    ctx.filled_vars,
                ),
            )
        )
    end
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg)
    if i == n
        return f(value, calculated_arguments)
    else
        return _generic_abductible_reverse(f, n, value, calculated_arguments, i + 1, calculated_arguments[end-i])
    end
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg::EitherOptions)
    outputs = Dict()
    for (h, v) in calculated_arg.options
        new_args = [fix_option_hashes(Set([h]), v) for v in calculated_arguments]
        outputs[h] = _generic_abductible_reverse(f, n, value, new_args, 1, new_args[end])
    end
    results = [EitherOptions(Dict(h => v[j] for (h, v) in outputs)) for j in 1:n]
    # @info results
    return results
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg::PatternWrapper)
    new_args =
        [j == length(calculated_arguments) - i + 1 ? arg.value : arg for (j, arg) in enumerate(calculated_arguments)]
    results = _generic_abductible_reverse(f, n, value, new_args, i, calculated_arg.value)
    return [_wrap_wildcard(r) for r in results]
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg::AbductibleValue)
    new_args =
        [j == length(calculated_arguments) - i + 1 ? arg.value : arg for (j, arg) in enumerate(calculated_arguments)]
    results = _generic_abductible_reverse(f, n, value, new_args, i, calculated_arg.value)
    return [_wrap_abductible(r) for r in results]
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg::Union{AnyObject,Nothing})
    try
        if i == n
            return f(value, calculated_arguments)
        else
            return _generic_abductible_reverse(f, n, value, calculated_arguments, i + 1, calculated_arguments[end-i])
        end
    catch e
        if isa(e, InterruptException)
            rethrow()
        end
        # @info e
        new_args = [
            j == (length(calculated_arguments) - i + 1) ? missing : calculated_arguments[j] for
            j in 1:length(calculated_arguments)
        ]
        # @info calculated_arguments
        # @info new_args
        if i == n
            return f(value, new_args)
        else
            return _generic_abductible_reverse(f, n, value, new_args, i + 1, new_args[end-i])
        end
    end
end

function _generic_abductible_reverse(f, n, value, calculated_arguments)
    # @info "Running in reverse $f $n $value $calculated_arguments"
    result = _generic_abductible_reverse(f, n, value, calculated_arguments, 1, calculated_arguments[end])
    # @info "Reverse result $result"
    return result
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
                    vcat(
                        ctx.predicted_arguments,
                        reverse(
                            _generic_abductible_reverse(
                                $(esc(reverse_function)),
                                length(arguments_of_type($(esc(t)))),
                                v,
                                ctx.calculated_arguments,
                            ),
                        ),
                    ),
                    ctx.calculated_arguments,
                    ctx.filled_indices,
                    ctx.filled_vars,
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

_get_var_indices(p::Index) = [p.n]
_get_var_indices(p::FreeVar) = [-Int64(p.var_id)]
_get_var_indices(p::Primitive) = []
_get_var_indices(p::Invented) = []
_get_var_indices(p::Apply) = vcat(_get_var_indices(p.f), _get_var_indices(p.x))
_get_var_indices(p::Abstraction) = [((i > 0) ? (i - 1) : i) for i in _get_var_indices(p.b) if i != 0]

function _has_external_vars(f)
    return !isempty(_get_var_indices(f))
end

function calculate_dependent_vars(p, inputs, output)
    context = ReverseRunContext([], [], [], Dict(), copy(inputs))
    updated_inputs = _run_in_reverse(p, output, context)[2].filled_vars
    return Dict(
        k => v for (k, v) in updated_inputs if (!haskey(inputs, k) || inputs[k] != v) # && !isa(v, AbductibleValue)
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
include("rev_fix_param.jl")

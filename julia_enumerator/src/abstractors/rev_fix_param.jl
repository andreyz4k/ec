
# _is_fixable_param(p::Index) = true
# _is_fixable_param(p::FreeVar) = true
_is_fixable_param(p) = true

function _is_possible_fixable_param(p::Index, skeleton, path)
    return has_index(follow_path(skeleton, vcat(path[begin:end-1], [LeftTurn(), RightTurn()])), p.n)
end
_is_possible_fixable_param(p, skeleton, path) = false

function _get_free_vars(p::FreeVar)
    return [p]
end

function _get_free_vars(p::Apply)
    return vcat(_get_free_vars(p.f), _get_free_vars(p.x))
end
_get_free_vars(p::Abstraction) = _get_free_vars(p.b)
_get_free_vars(p::Program) = []

function _is_possible_fixable_param(p::FreeVar, skeleton, path)
    if isnothing(p.var_id)
        return false
    end
    body_free_vars = _get_free_vars(follow_path(skeleton, path[begin:end-1]))
    unfixed_free_vars = filter(v -> isnothing(v.var_id), body_free_vars)
    all_free_vars = _get_free_var_types(skeleton)
    index_shift = length(all_free_vars) - length(unfixed_free_vars)
    if in(p, body_free_vars)
        return true
    end
    i = parse(Int, p.var_id[2:end])
    if i > index_shift
        return true
    end
    return false
end

function reverse_fix_param()
    function _reverse_fix_param(value, context)
        # @info "Running reverse fix param for $value in context $context"
        body = context.arguments[end]
        param = context.arguments[end-1]
        fixer = context.arguments[end-2]
        fixer_value = try_evaluate_program(fixer, [value], Dict())
        if isa(fixer_value, EitherOptions) || isa(fixer_value, PatternWrapper) || isa(fixer_value, AbductibleValue)
            error("Fixer value cannot be wildcard")
        end
        if isa(param, Index)
            if haskey(context.filled_indices, param.n) && context.filled_indices[param.n] !== fixer_value
                error("Index $(param.n) is already filled with $(context.filled_indices[param.n])")
            end
            filled_indices = copy(context.filled_indices)
            filled_indices[param.n] = fixer_value
            filled_vars = context.filled_vars
        elseif isa(param, FreeVar)
            if haskey(context.filled_vars, param.var_id) && context.filled_vars[param.var_id] !== fixer_value
                error("Variable $(param.var_id) is already filled with $(context.filled_vars[param.var_id])")
            end
            filled_vars = copy(context.filled_vars)
            filled_vars[param.var_id] = fixer_value
            filled_indices = context.filled_indices
        else
            error("Invalid param type $(param)")
        end

        calculated_output, arg_context = _run_in_reverse(
            body,
            value,
            ReverseRunContext(
                context.arguments[begin:end-3],
                context.predicted_arguments,
                context.calculated_arguments[begin:end-3],
                filled_indices,
                filled_vars,
            ),
        )
        return calculated_output,
        ReverseRunContext(
            context.arguments,
            vcat(arg_context.predicted_arguments, [SkipArg(), SkipArg(), SkipArg()]),
            context.calculated_arguments,
            arg_context.filled_indices,
            arg_context.filled_vars,
        )
    end
    return [
        (_is_reversible_subfunction, CustomArgChecker(true, nothing, nothing, nothing)),
        (_is_fixable_param, CustomArgChecker(nothing, nothing, nothing, _is_possible_fixable_param)),
        (_has_no_holes, CustomArgChecker(false, -1, false, nothing)),
    ],
    _reverse_fix_param
end

@define_custom_reverse_primitive(
    "rev_fix_param",
    arrow(t0, t1, arrow(t0, t1), t0),
    (body -> (param -> (fixer -> body))),
    reverse_fix_param()
)


_is_fixable_param(p::Index) = true
_is_fixable_param(p::FreeVar) = true
_is_fixable_param(p) = false

_is_possible_fixable_param(p::Index, from_input, skeleton, path) = true
_is_possible_fixable_param(p, from_input, skeleton, path) = false

#TODO: filter only used indices and vars
function _is_possible_fixable_param(p::FreeVar, from_input, skeleton, path)
    if isnothing(p.var_id)
        return false
    end
    # @info "Checking if $p is fixable"
    # @info "skeleton: $skeleton"
    # @info "path: $path"
    return true
end

_is_possible_fixer(p::Primitive, from_input, skeleton, path) = true
_is_possible_fixer(p::FreeVar, from_input, skeleton, path) = false
_is_possible_fixer(p::Index, from_input, skeleton, path) = p.n == 0
_is_possible_fixer(p::Invented, from_input, skeleton, path) = true

function reverse_fix_param()
    function _reverse_fix_param(value, context)
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
                context.predicted_arguments[begin:end-3],
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
        (_is_reversible_subfunction, _is_possible_subfunction),
        (_is_fixable_param, _is_possible_fixable_param),
        (_has_no_holes, _is_possible_fixer),
    ],
    _reverse_fix_param
end

@define_custom_reverse_primitive(
    "rev_fix_param",
    arrow(t0, t1, arrow(t0, t1), t0),
    (body -> (param -> (fixer -> body))),
    reverse_fix_param()
)

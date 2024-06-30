
function rev_select(base, others)
    result = copy(base)
    for i in 1:length(others)
        if others[i] !== nothing
            result[i] = others[i]
        end
    end
    return result
end

function _is_reversible_selector(p::Index, is_top_index)
    if is_top_index
        return 0
    end
    if p.n == 0
        return 1
    else
        return 2
    end
end

_is_reversible_selector(p::Primitive, is_top_index) = 2
_is_reversible_selector(p::Invented, is_top_index) = 2
_is_reversible_selector(p::Program, is_top_index) = 0

# TODO: define rules for lambdas in selector

function _is_reversible_selector(p::Apply, is_top_index)
    if is_top_index
        if isa(p.x, Hole)
            if isa(p.f, Apply) && p.f.f == every_primitive["eq?"]
                return _is_reversible_selector(p.f.x, false)
            else
                return 0
            end
        else
            return min(_is_reversible_selector(p.f, false), _is_reversible_selector(p.x, false))
        end
    else
        if isa(p.x, Hole)
            return 0
        else
            return min(_is_reversible_selector(p.f, false), _is_reversible_selector(p.x, false))
        end
    end
end

is_reversible_selector(p::Abstraction) = _is_reversible_selector(p.b, true) == 1
is_reversible_selector(p::Program) = false

struct IsPossibleSelector <: ArgChecker
    should_be_reversible::Bool
    max_index::Union{Int64,Nothing}
    can_have_free_vars::Union{Bool,Nothing}
    step_to_eq::Int64
    IsPossibleSelector(max_index, can_have_free_vars, step_to_eq) =
        new(false, max_index, can_have_free_vars, step_to_eq)
end

Base.:(==)(c1::IsPossibleSelector, c2::IsPossibleSelector) =
    c1.should_be_reversible == c2.should_be_reversible &&
    c1.max_index == c2.max_index &&
    c1.can_have_free_vars == c2.can_have_free_vars &&
    c1.step_to_eq == c2.step_to_eq

Base.hash(c::IsPossibleSelector, h::UInt64) =
    hash(c.should_be_reversible, hash(c.max_index, hash(c.can_have_free_vars, hash(c.step_to_eq, h))))

(c::IsPossibleSelector)(p::Primitive, skeleton, path) = true
(c::IsPossibleSelector)(p::Invented, skeleton, path) = true
(c::IsPossibleSelector)(p::Index, skeleton, path) = c.step_to_eq > 1

function (c::IsPossibleSelector)(p::FreeVar, skeleton, path)
    return true
end

function step_arg_checker(c::IsPossibleSelector, arg::ArgTurn)
    return IsPossibleSelector(isnothing(c.max_index) ? 0 : c.max_index + 1, false, c.step_to_eq == 0 ? 1 : 3)
end

function step_arg_checker(c::IsPossibleSelector, arg)
    if c.step_to_eq == 1 && arg == (every_primitive["eq?"], 2)
        return IsPossibleSelector(nothing, nothing, 2)
    end
    if isnothing(c.can_have_free_vars)
        return IsPossibleSelector(0, false, 3)
    end
    return IsPossibleSelector(c.max_index, false, 3)
end

function step_arg_checker(c::IsPossibleSelector, arg::Index)
    return nothing
end

function reverse_rev_select()
    function _reverse_rev_select(value, context)
        f_info = context.arguments[end]
        f = f_info.p

        if isa(f, Abstraction) &&
           isa(f.b, Apply) &&
           (isa(f.b.x, FreeVar) || isa(f.b.x, Index)) &&
           isa(f.b.f, Apply) &&
           f.b.f.f == every_primitive["eq?"]
            options_selector = Dict()
            options_base = Dict()
            options_others = Dict()
            checked_options = Set()

            selector = Abstraction(f.b.f.x)

            for i in 1:length(value)
                selector_option = try_evaluate_program(selector, [value[i]], Dict())
                if in(selector_option, checked_options)
                    continue
                end
                push!(checked_options, selector_option)
                results_base = Array{Any}(undef, size(value)...)
                results_others = Array{Any}(undef, size(value)...)
                for j in 1:length(value)
                    if try_evaluate_program(selector, [value[j]], Dict()) == selector_option
                        results_base[j] = value[j]
                        results_others[j] = nothing
                    else
                        results_base[j] = any_object
                        results_others[j] = value[j]
                    end
                end
                option_hash = rand(UInt64)
                options_selector[option_hash] = selector_option
                options_base[option_hash] = PatternWrapper(results_base)
                options_others[option_hash] = results_others
            end

            if length(options_selector) < 2
                error("All elements are equal according to selector")
            end

            out_selector = EitherOptions(options_selector)
            out_base = EitherOptions(options_base)
            out_others = EitherOptions(options_others)

            success, _, out_context = _run_in_reverse(
                f_info.b_info.x_info,
                out_selector,
                ReverseRunContext(
                    context.arguments,
                    vcat(context.predicted_arguments, [out_others, out_base, SkipArg()]),
                    context.calculated_arguments,
                    context.filled_indices,
                    context.filled_vars,
                ),
            )

            return success, value, out_context
        else
            results_base = Array{Any}(undef, size(value)...)
            results_others = Array{Any}(undef, size(value)...)
            for i in 1:length(value)
                if try_evaluate_program(f, [value[i]], Dict())
                    results_base[i] = value[i]
                    results_others[i] = nothing
                else
                    results_base[i] = any_object
                    results_others[i] = value[i]
                end
            end
            if all(v == results_others[1] for v in results_others)
                return false, value, context
                # error("All elements are equal according to selector")
            end
            return true,
            value,
            ReverseRunContext(
                context.arguments,
                vcat(context.predicted_arguments, [results_others, PatternWrapper(results_base), SkipArg()]),
                context.calculated_arguments,
                context.filled_indices,
                context.filled_vars,
            )
        end
    end
    return [(is_reversible_selector, IsPossibleSelector(-1, false, 0))], _reverse_rev_select
end

@define_custom_reverse_primitive(
    "rev_select",
    arrow(arrow(t0, tbool), tlist(t0), tlist(t0), tlist(t0)),
    (f -> (base -> (others -> rev_select(base, others)))),
    reverse_rev_select()
)

@define_custom_reverse_primitive(
    "rev_select_grid",
    arrow(arrow(t0, tbool), tgrid(t0), tgrid(t0), tgrid(t0)),
    (f -> (base -> (others -> rev_select(base, others)))),
    reverse_rev_select()
)

function rev_select_set(base, others)
    result = union(base, others)
    if length(result) != length(base) + length(others)
        error("Losing data on union")
    end
    return result
end

function reverse_rev_select_set()
    function _reverse_rev_select(value, context)
        f_info = context.arguments[end]
        f = f_info.p

        if isa(f, Abstraction) &&
           isa(f.b, Apply) &&
           (isa(f.b.x, FreeVar) || isa(f.b.x, Index)) &&
           isa(f.b.f, Apply) &&
           f.b.f.f == every_primitive["eq?"]
            options_selector = Dict()
            options_base = Dict()
            options_others = Dict()
            checked_options = Set()

            selector = Abstraction(f.b.f.x)

            for val in value
                selector_option = try_evaluate_program(selector, [val], Dict())
                if in(selector_option, checked_options)
                    continue
                end
                push!(checked_options, selector_option)
                results_base = Set()
                results_others = Set()
                for v in value
                    if try_evaluate_program(selector, [v], Dict()) == selector_option
                        push!(results_base, v)
                    else
                        push!(results_others, v)
                    end
                end

                option_hash = rand(UInt64)
                options_selector[option_hash] = selector_option
                options_base[option_hash] = results_base
                options_others[option_hash] = results_others
            end

            if length(options_selector) < 2
                return false, value, context
                # error("All elements are equal according to selector")
            end

            out_selector = EitherOptions(options_selector)
            out_base = EitherOptions(options_base)
            out_others = EitherOptions(options_others)

            success, _, out_context = _run_in_reverse(
                f_info.b_info.x_info,
                out_selector,
                ReverseRunContext(
                    context.arguments,
                    vcat(context.predicted_arguments, [out_others, out_base, SkipArg()]),
                    context.calculated_arguments,
                    context.filled_indices,
                    context.filled_vars,
                ),
            )

            return success, value, out_context
        else
            results_base = Set()
            results_others = Set()
            for v in value
                if try_evaluate_program(f, [v], Dict())
                    push!(results_base, v)
                else
                    push!(results_others, v)
                end
            end
            if isempty(results_base) || isempty(results_others)
                return false, value, context
                # error("All elements are equal according to selector")
            end
            return true,
            value,
            ReverseRunContext(
                context.arguments,
                vcat(context.predicted_arguments, [results_others, results_base, SkipArg()]),
                context.calculated_arguments,
                context.filled_indices,
                context.filled_vars,
            )
        end
    end
    return [(is_reversible_selector, IsPossibleSelector(-1, false, 0))], _reverse_rev_select
end

@define_custom_reverse_primitive(
    "rev_select_set",
    arrow(arrow(t0, tbool), tset(t0), tset(t0), tset(t0)),
    (f -> (base -> (others -> rev_select_set(base, others)))),
    reverse_rev_select_set()
)

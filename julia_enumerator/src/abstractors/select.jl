
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

_is_possible_selector(p::Primitive, from_input, skeleton, path) = true
_is_possible_selector(p::Invented, from_input, skeleton, path) = true
_is_possible_selector(p::Index, from_input, skeleton, path) = p.n != 0 || !isa(path[end], ArgTurn)

function _is_possible_selector(p::FreeVar, from_input, skeleton, path)
    if skeleton isa Abstraction &&
       skeleton.b isa Apply &&
       skeleton.b.f isa Apply &&
       skeleton.b.f.f == every_primitive["eq?"] &&
       length(path) == 2 &&
       path[2] == RightTurn()
        return true
    end
    return false
end

function reverse_rev_select()
    function _reverse_rev_select(arguments)
        f = pop!(arguments)
        rev_base = _get_reversed_program(pop!(arguments), arguments)
        rev_others = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_rev_select(value)::Vector{Any}
            if isa(f, Abstraction) &&
               isa(f.b, Apply) &&
               isa(f.b.x, Hole) &&
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
                    option_hash = hash((selector_option, results_base, results_others))
                    options_selector[option_hash] = selector_option
                    options_base[option_hash] = results_base
                    options_others[option_hash] = results_others
                end

                if length(options_selector) < 2
                    error("All elements are equal according to selector")
                end

                out_selector = EitherOptions(options_selector)
                out_base = EitherOptions(options_base)
                out_others = EitherOptions(options_others)

                return vcat([out_selector], rev_base(out_base), rev_others(out_others))
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
                    error("All elements are equal according to selector")
                end
                return vcat(rev_base(results_base), rev_others(results_others))
            end
        end

        function __reverse_rev_select(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_rev_select, value)
        end

        return __reverse_rev_select
    end
    return [(is_reversible_selector, _is_possible_selector)], _reverse_rev_select
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
    function _reverse_rev_select(arguments)
        f = pop!(arguments)
        rev_base = _get_reversed_program(pop!(arguments), arguments)
        rev_others = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_rev_select(value)::Vector{Any}
            if isa(f, Abstraction) &&
               isa(f.b, Apply) &&
               isa(f.b.x, Hole) &&
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
                    results_base = Set()
                    results_others = Set()
                    for v in value
                        if try_evaluate_program(selector, [v], Dict()) == selector_option
                            push!(results_base, v)
                        else
                            push!(results_others, v)
                        end
                    end

                    option_hash = hash((selector_option, results_base, results_others))
                    options_selector[option_hash] = selector_option
                    options_base[option_hash] = results_base
                    options_others[option_hash] = results_others
                end

                if length(options_selector) < 2
                    error("All elements are equal according to selector")
                end

                out_selector = EitherOptions(options_selector)
                out_base = EitherOptions(options_base)
                out_others = EitherOptions(options_others)

                return vcat([out_selector], rev_base(out_base), rev_others(out_others))
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
                    error("All elements are equal according to selector")
                end
                return vcat(rev_base(results_base), rev_others(results_others))
            end
        end

        function __reverse_rev_select(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_rev_select, value)
        end

        return __reverse_rev_select
    end
    return [(is_reversible_selector, _is_possible_selector)], _reverse_rev_select
end

@define_custom_reverse_primitive(
    "rev_select_set",
    arrow(arrow(t0, tbool), tset(t0), tset(t0), tset(t0)),
    (f -> (base -> (others -> rev_select_set(base, others)))),
    reverse_rev_select_set()
)

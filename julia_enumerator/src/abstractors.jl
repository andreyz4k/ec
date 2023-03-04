
all_abstractors = Dict{Program,Tuple{Vector,Any}}()

struct AnyObject end
any_object = AnyObject()

function _is_reversible(p::Primitive, in_invented)
    if haskey(all_abstractors, p)
        all_abstractors[p][1]
    else
        nothing
    end
end

function _is_reversible(p::Apply, in_invented)
    rev_f = _is_reversible(p.f, in_invented)
    if !isnothing(rev_f)
        if isempty(rev_f)
            if isa(p.x, Hole)
                if !isarrow(p.x.t)
                    return rev_f
                else
                    return nothing
                end
            end
            if isa(p.x, Index)
                if in_invented
                    return rev_f
                else
                    return nothing
                end
            end
            if isa(p.x, Abstraction) || isa(p.x, Apply)
                return _is_reversible(p.x, in_invented)
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

_is_reversible(p::Invented, in_invented) = _is_reversible(p.b, true)
_is_reversible(p::Abstraction, in_invented) = _is_reversible(p.b, in_invented)

_is_reversible(p::Program, in_invented) = nothing

is_reversible(p::Program)::Bool = !isnothing(_is_reversible(p, false))

function _get_reversed_filled_program(p::Primitive, arguments)
    return all_abstractors[p][2](arguments)
end

function _get_reversed_filled_program(p::Invented, arguments)
    repls_b, rev_b = _get_reversed_filled_program(p.b, arguments)
    # if !isempty(repls_b)
    #     @info repls_b
    #     @info p.b
    #     error("Incorrect filling in invented function")
    # end
    return repls_b, rev_b
end
noop(a)::Vector{Any} = [a]
function _get_reversed_filled_program(p::Hole, arguments)
    return [FreeVar(p.t, nothing)], noop
end

function _get_reversed_filled_program(p::Index, arguments)
    return [], noop
end

function _get_reversed_filled_program(p::Apply, arguments)
    push!(arguments, p.x)
    replacements, reversed_f = _get_reversed_filled_program(p.f, arguments)
    return replacements, reversed_f
end

function _get_reversed_filled_program(p::Abstraction, arguments)
    # Only used in invented functions
    replacements_f, rev_f = _get_reversed_filled_program(p.b, arguments)
    replacements_a, rev_a = _get_reversed_filled_program(pop!(arguments), arguments)
    # TODO: Properly use rev_a
    return vcat(replacements_f, replacements_a), rev_f
end

function get_reversed_filled_program(p::Program, context, path)
    replacements, rev_p = _get_reversed_filled_program(p, [])
    fill_p = p

    for repl in replacements
        current_hole = follow_path(fill_p, path)
        request = current_hole.t
        environment = path_environment(path)
        if repl isa Index
            t = environment[repl.n+1]
        elseif repl isa FreeVar
            t = repl.t
        else
            error("Incorrect replacement")
        end
        (context, t) = apply_context(context, t)
        return_type = return_of_type(t)

        context = unify(context, return_type, request)
        (context, t) = apply_context(context, t)

        fill_p = modify_skeleton(fill_p, repl, path)
        path = unwind_path(path, fill_p)
    end
    if !isempty(path)
        error("Incorrect filling")
    end

    return fill_p, rev_p, context
end

function generic_reverse(rev_function, n)
    function _generic_reverse(arguments)
        replacements = []
        rev_functions = []
        for _ in 1:n
            replacements_a, rev_a = _get_reversed_filled_program(pop!(arguments), arguments)
            append!(replacements, replacements_a)
            push!(rev_functions, rev_a)
        end
        function _reverse_function(value)::Vector{Any}
            rev_results = rev_function(value)
            return vcat([rev_functions[i](rev_results[i]) for i in 1:n]...)
        end
        function _reverse_function(value::EitherOptions)::Vector{Any}
            hashes = []
            outputs = [[] for _ in 1:n]
            for (h, val) in value.options
                outs = _reverse_function(val)
                push!(hashes, h)
                for i in 1:n
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
        return replacements, _reverse_function
    end
    return _generic_reverse
end

macro define_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        local out = generic_reverse($(esc(reverse_function)), length(arguments_of_type(prim.t)))
        all_abstractors[prim] = [], out
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

function reverse_repeat(value)::Vector{Any}
    template_item = first(v for v in value if v !== any_object)
    if any(v != template_item && v != any_object for v in value)
        error("Elements are not equal")
    end
    return [template_item, length(value)]
end

@define_reverse_primitive "repeat" arrow(t0, tint, tlist(t0)) (x -> (n -> fill(x, n))) reverse_repeat

function reverse_repeat_grid(value)::Vector{Any}
    template_item = first(v for v in value if v !== any_object)
    if any(v != template_item && v != any_object for v in value)
        error("Elements are not equal")
    end
    x, y = size(value)
    return [template_item, x, y]
end

@define_reverse_primitive "repeat_grid" arrow(t0, tint, tint, tgrid(t0)) (x -> (n -> (m -> fill(x, n, m)))) reverse_repeat_grid

function reverse_cons(value)::Vector{Any}
    if isempty(value)
        error("List is empty")
    end
    return [value[1], value[2:end]]
end

@define_reverse_primitive "cons" arrow(t0, tlist(t0), tlist(t0)) (x -> (y -> vcat([x], y))) reverse_cons

_count_holes(p::Hole) = 1
_count_holes(p::Apply) = _count_holes(p.f) + _count_holes(p.x)
_count_holes(p::Abstraction) = _count_holes(p.b)
_count_holes(p::Program) = 0

function _count_holes(p::Primitive)
    if p.name == "map"
        return -1
    elseif p.name == "map2"
        return -2
    else
        return 0
    end
end

_is_reversible_mapper(n) = p -> is_reversible(p) && _count_holes(p) == n

function reverse_map(n)
    function _reverse_map(arguments)
        f = pop!(arguments)
        for _ in 1:n
            f = f.b
        end
        replacements_f, rev_f = _get_reversed_filled_program(f, arguments)
        rev_f = _rmapper(rev_f, n)

        replacements = []
        i = n - 1
        for repl in replacements_f
            if repl isa FreeVar
                push!(replacements, Index(i))
                i -= 1
                if i < -1
                    error("Too many free variables")
                end
            else
                push!(replacements, repl)
            end
        end

        rev_xs = []
        for _ in 1:n
            repls_x, rev_x = _get_reversed_filled_program(pop!(arguments), arguments)
            append!(replacements, repls_x)
            push!(rev_xs, rev_x)
        end

        function __reverse_map(value)::Vector{Any}
            output_options = Set([[[] for _ in 1:n]])
            for values in map(rev_f, value)
                if any(v isa EitherOptions for v in values)
                    child_options = Dict()
                    non_eithers = []
                    for v in values
                        if v isa EitherOptions
                            if isempty(child_options)
                                for (h, val) in v.options
                                    child_options[h] = vcat(non_eithers, [val])
                                end
                            else
                                for (h, val) in v.options
                                    push!(child_options[h], val)
                                end
                            end
                        else
                            if isempty(child_options)
                                push!(non_eithers, v)
                            else
                                for (h, option) in child_options
                                    push!(option, v)
                                end
                            end
                        end
                    end

                    new_options = Set()
                    for output_option in output_options
                        for (h, option) in child_options
                            new_option = []
                            for i in 1:n
                                push!(new_option, copy(output_option[i]))
                                push!(new_option[i], option[i])
                            end
                            push!(new_options, new_option)
                            if length(new_options) > 100
                                error("Too many options")
                            end
                        end
                    end
                    output_options = new_options
                else
                    for (i, v) in enumerate(values)
                        for option in output_options
                            push!(option[i], v)
                        end
                    end
                end
            end
            if length(output_options) == 1
                result = first(output_options)
            else
                hashed_options = Dict(hash(option) => option for option in output_options)
                result = []
                for i in 1:n
                    push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
                end
            end
            return vcat([rev_xs[i](result[i]) for i in 1:n]...)
        end

        function __reverse_map(value::EitherOptions)::Vector{Any}
            hashes = []
            outputs = Vector{Any}[]
            for (h, val) in value.options
                outs = __reverse_map(val)
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

        return replacements, __reverse_map
    end

    return [(_is_reversible_mapper(n), nothing)], _reverse_map
end

function _rmapper(f, n)
    __mapper(x::Union{AnyObject,Nothing}) = [x for _ in 1:n]
    __mapper(x) = f(x)

    return __mapper
end

function _mapper(f)
    __mapper(x::Union{AnyObject,Nothing}) = x
    __mapper(x) = f(x)

    return __mapper
end

function _mapper2(f)
    __mapper(x, y) = f(x)(y)
    __mapper(x::Nothing, y) = x
    __mapper(x, y::Nothing) = y
    __mapper(x::Nothing, y::Nothing) = x
    __mapper(x::AnyObject, y) = x
    __mapper(x, y::AnyObject) = y
    __mapper(x::AnyObject, y::AnyObject) = x
    __mapper(x::AnyObject, y::Nothing) = y
    __mapper(x::Nothing, y::AnyObject) = x

    return __mapper
end

@define_custom_reverse_primitive(
    "map",
    arrow(arrow(t0, t1), tlist(t0), tlist(t1)),
    (f -> (xs -> map(_mapper(f), xs))),
    reverse_map(1)
)

@define_custom_reverse_primitive(
    "map2",
    arrow(arrow(t0, t1, t2), tlist(t0), tlist(t1), tlist(t2)),
    (f -> (xs -> (ys -> map(((x, y),) -> _mapper2(f)(x, y), zip(xs, ys))))),
    reverse_map(2)
)

@define_custom_reverse_primitive(
    "map_grid",
    arrow(arrow(t0, t1), tgrid(t0), tgrid(t1)),
    (f -> (xs -> map(_mapper(f), xs))),
    reverse_map(1)
)

@define_custom_reverse_primitive(
    "map2_grid",
    arrow(arrow(t0, t1, t2), tgrid(t0), tgrid(t1), tgrid(t2)),
    (f -> (xs -> (ys -> map(((x, y),) -> _mapper2(f)(x, y), zip(xs, ys))))),
    reverse_map(2)
)

function reverse_concat(value)::Vector{Any}
    options_h = Dict()
    options_t = Dict()
    for i in range(0, length(value))
        h, t = value[1:i], value[i+1:end]
        option_hash = hash((h, t))
        options_h[option_hash] = h
        options_t[option_hash] = t
    end
    out_h = if isempty(options_h)
        error("No valid options")
    elseif length(options_h) == 1
        first(options_h)[2]
    else
        EitherOptions(options_h)
    end
    out_t = if isempty(options_t)
        error("No valid options")
    elseif length(options_t) == 1
        first(options_t)[2]
    else
        EitherOptions(options_t)
    end
    return [out_h, out_t]
end

@define_reverse_primitive "concat" arrow(tlist(t0), tlist(t0), tlist(t0)) (a -> (b -> vcat(a, b))) reverse_concat

function reverse_range(value)::Vector{Any}
    for (i, v) in enumerate(value)
        if v != i - 1
            error("Invalid value")
        end
    end
    return [length(value) - 1]
end

@define_reverse_primitive "range" arrow(tint, tlist(tint)) (n -> collect(0:n-1)) reverse_range

function reverse_rows_to_grid(value)::Vector{Any}
    [[value[i, :] for i in (1:size(value, 1))]]
end

@define_reverse_primitive(
    "rows_to_grid",
    arrow(tlist(tlist(t0)), tgrid(t0)),
    (rs -> vcat([permutedims(r) for r in rs]...)),
    reverse_rows_to_grid
)

function reverse_columns_to_grid(value)::Vector{Any}
    [[value[:, i] for i in (1:size(value, 2))]]
end

@define_reverse_primitive(
    "columns_to_grid",
    arrow(tlist(tlist(t0)), tgrid(t0)),
    (cs -> hcat(cs...)),
    reverse_columns_to_grid
)

function reverse_rows(value)::Vector{Any}
    [vcat([permutedims(r) for r in value]...)]
end

function reverse_columns(value)::Vector{Any}
    [hcat(value...)]
end

@define_reverse_primitive(
    "rows",
    arrow(tgrid(t0), tlist(tlist(t0))),
    (g -> [g[i, :] for i in (1:size(g, 1))]),
    reverse_rows
)

@define_reverse_primitive(
    "columns",
    arrow(tgrid(t0), tlist(tlist(t0))),
    (g -> [g[:, i] for i in (1:size(g, 2))]),
    reverse_columns
)

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

function _is_possible_selector(p::Index, is_top_index)
    if is_top_index
        return 0
    end
    if p.n == 0
        return 1
    else
        return 2
    end
end

_is_possible_selector(p::Primitive, is_top_index) = 2
_is_possible_selector(p::Invented, is_top_index) = 2
_is_possible_selector(p::Hole, is_top_index) = 1
_is_possible_selector(p::Program, is_top_index) = 0

function _is_possible_selector(p::Apply, is_top_index)
    if is_top_index && isa(p.f, Apply) && p.f.f == every_primitive["eq?"]
        if isa(p.x, Hole)
            return _is_possible_selector(p.f.x, false)
        else
            return 0
        end
    else
        return min(_is_possible_selector(p.f, false), _is_possible_selector(p.x, false))
    end
end

is_possible_selector(p::Abstraction) = _is_possible_selector(p.b, true) == 1
is_possible_selector(p::Hole) = true
is_possible_selector(p::Program) = false

fill_selector(p::Hole) = [FreeVar(p.t, nothing)]
fill_selector(p::Program) = []
fill_selector(p::Apply) = vcat(fill_selector(p.f), fill_selector(p.x))
fill_selector(p::Abstraction) = fill_selector(p.b)

function reverse_rev_select(name)
    function _reverse_rev_select(arguments)
        f = pop!(arguments)
        replacements = fill_selector(f)
        has_hole = length(replacements) == 1
        if length(replacements) > 1
            error("Selector has multiple holes")
        end

        repls_base, rev_base = _get_reversed_filled_program(pop!(arguments), arguments)
        repls_others, rev_others = _get_reversed_filled_program(pop!(arguments), arguments)
        append!(replacements, repls_base, repls_others)

        function __reverse_rev_select(value)::Vector{Any}
            if !has_hole
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
            elseif isa(f, Abstraction) &&
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
                error("Can't reverse rev_select with selector $f")
            end
        end

        function __reverse_rev_select(value::EitherOptions)::Vector{Any}
            hashes = []
            outputs = Vector{Any}[]
            for (h, val) in value.options
                outs = __reverse_rev_select(val)
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

        return replacements, __reverse_rev_select
    end
    return [(is_reversible_selector, is_possible_selector)], _reverse_rev_select
end

@define_custom_reverse_primitive(
    "rev_select",
    arrow(arrow(t0, tbool), tlist(t0), tlist(t0), tlist(t0)),
    (f -> (base -> (others -> rev_select(base, others)))),
    reverse_rev_select("rev_select")
)

@define_custom_reverse_primitive(
    "rev_select_grid",
    arrow(arrow(t0, tbool), tgrid(t0), tgrid(t0), tgrid(t0)),
    (f -> (base -> (others -> rev_select(base, others)))),
    reverse_rev_select("rev_select_grid")
)

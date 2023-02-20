
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
            if isa(p.x, Index)
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

function _get_reversed_filled_program(p::Primitive, arguments)
    return all_abstractors[p][2](arguments)
end

function _get_reversed_filled_program(p::Invented, arguments)
    filled_b, rev_b, updated_args, filled_types = _get_reversed_filled_program(p.b, arguments)
    if filled_b != p.b
        @info filled_b
        @info p.b
        error("Incorrect filling in invented function")
    end
    return p, rev_b, updated_args, filled_types
end
noop(a)::Vector{Any} = [a]
function _get_reversed_filled_program(p::Hole, arguments)
    return FreeVar(p.t, nothing), noop, [], [p.t]
end

function _get_reversed_filled_program(p::Index, arguments)
    return p, noop, [], []
end

function _get_reversed_filled_program(p::Apply, arguments)
    push!(arguments, p.x)
    filled_f, reversed_f, updated_args, filled_f_types = _get_reversed_filled_program(p.f, arguments)
    new_filled_x = pop!(updated_args)
    return Apply(filled_f, new_filled_x), reversed_f, updated_args, filled_f_types
end

function _get_reversed_filled_program(p::Abstraction, arguments)
    res = _get_reversed_filled_program(p.b, arguments)
    fill_f, rev_f, updated_args, filled_types = res
    filled_a, rev_a, _, filled_a_types = _get_reversed_filled_program(pop!(arguments), arguments)
    pushfirst!(updated_args, filled_a)
    return Abstraction(fill_f), rev_f, updated_args, vcat(filled_types, filled_a_types)
end

function get_reversed_filled_program(p::Program)
    fill_p, rev_p, _, _ = _get_reversed_filled_program(p, [])
    return fill_p, rev_p
end

function generic_reverse2(prim, rev_function)
    function _generic_reverse(arguments)
        filled_a, rev_a, _, filled_a_types = _get_reversed_filled_program(pop!(arguments), arguments)
        filled_b, rev_b, _, filled_b_types = _get_reversed_filled_program(pop!(arguments), arguments)
        function _reverse_function(value)::Vector{Any}
            r_a, r_b = rev_function(value)
            return vcat(rev_a(r_a), rev_b(r_b))
        end
        function _reverse_function(value::EitherOptions)::Vector{Any}
            hashes = []
            outputs = [[], []]
            for (h, val) in value.options
                outs = _reverse_function(val)
                push!(hashes, h)
                for i in 1:2
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
        return prim, _reverse_function, [filled_b, filled_a], vcat(filled_a_types, filled_b_types)
    end
    return _generic_reverse
end

function generic_reverse1(prim, rev_function)
    function _generic_reverse(arguments)
        a = pop!(arguments)
        filled_a, rev_a, _, filled_a_types = _get_reversed_filled_program(a, arguments)
        function _reverse_function(value)::Vector{Any}
            r_a = rev_function(value)
            return rev_a(r_a[1])
        end
        function _reverse_function(value::EitherOptions)::Vector{Any}
            hashes = []
            outputs = []
            for (h, val) in value.options
                outs = _reverse_function(val)
                push!(hashes, h)
                push!(outputs, outs[1])
            end
            if allequal(outputs)
                return [outputs[1]]
            elseif any(out == value for out in outputs)
                return [value]
            else
                options = Dict(hashes[i] => outputs[i] for i in 1:length(hashes))
                return [EitherOptions(options)]
            end
        end
        return prim, _reverse_function, [filled_a], filled_a_types
    end
    return _generic_reverse
end

macro define_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        if length(arguments_of_type(prim.t)) == 1
            local out = generic_reverse1(prim, $(esc(reverse_function)))
        elseif length(arguments_of_type(prim.t)) == 2
            local out = generic_reverse2(prim, $(esc(reverse_function)))
        end
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
    if any(v != value[1] for v in value)
        error("Elements are not equal")
    end
    return [value[1], length(value)]
end

@define_reverse_primitive "repeat" arrow(t0, tint, tlist(t0)) (x -> (n -> fill(x, n))) reverse_repeat

function reverse_cons(value)::Vector{Any}
    if isempty(value)
        error("List is empty")
    end
    return [value[1], value[2:end]]
end

@define_reverse_primitive "cons" arrow(t0, tlist(t0), tlist(t0)) (x -> (y -> vcat([x], y))) reverse_cons

function _replace_free_vars(p::FreeVar, replacements)
    popfirst!(replacements)
end

function _replace_free_vars(p::Apply, replacements)
    new_f = _replace_free_vars(p.f, replacements)
    new_x = _replace_free_vars(p.x, replacements)
    Apply(new_f, new_x)
end

_replace_free_vars(p::Abstraction, replacements) = Abstraction(_replace_free_vars(p.b, replacements))
_replace_free_vars(p::Program, replacements) = p

function map_function_replacement(map_f, filled_types)
    if length(filled_types) == 1
        replacements = [Index(0)]
    elseif length(filled_types) == 2
        replacements =
            [Apply(every_primitive["tuple2_first"], Index(0)), Apply(every_primitive["tuple2_second"], Index(0))]
    end
    return _replace_free_vars(map_f, replacements), filled_types
end

function reverse_map(name, type, zip_primitive)
    function zip_free_vars(filled_hole, filled_types)
        if length(filled_types) == 2
            return filled_hole, [filled_types[2]]
        elseif length(filled_types) == 3
            return (
                Apply(
                    Apply(zip_primitive, FreeVar(type(filled_types[1]), nothing)),
                    FreeVar(type(filled_types[2]), nothing),
                ),
                [type(filled_types[1]), type(filled_types[2])],
            )
        end
    end

    function _reverse_map(arguments)
        fill_f, rev_f, _, filled_types_f = _get_reversed_filled_program(pop!(arguments).b, arguments)
        fill_f = Abstraction(fill_f)
        fill_x, rev_x, _, filled_types_x = _get_reversed_filled_program(pop!(arguments), arguments)
        function __reverse_map(value)::Vector{Any}
            output_options = Set([[[] for _ in filled_types_f]])
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
                            for i in 1:length(filled_types_f)
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
                return first(output_options)
            else
                hashed_options = Dict(hash(option) => option for option in output_options)
                result = []
                for i in 1:length(filled_types_f)
                    push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
                end
                return result
            end
        end

        function __reverse_map(value::EitherOptions)::Vector{Any}
            hashes = []
            outputs = [[] for _ in filled_types_f]
            for (h, val) in value.options
                outs = __reverse_map(val)
                push!(hashes, h)
                for i in 1:length(filled_types_f)
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
        new_f, _ = map_function_replacement(fill_f, filled_types_f)
        filled_types = vcat(filled_types_f, filled_types_x)
        new_x, filled_types = zip_free_vars(fill_x, filled_types)
        return every_primitive[name], __reverse_map, [new_x, new_f], filled_types
    end

    return [], _reverse_map
end

@define_custom_reverse_primitive(
    "map",
    arrow(arrow(t0, t1), tlist(t0), tlist(t1)),
    (f -> (xs -> map(f, xs))),
    reverse_map("map", tlist, every_primitive["zip2"])
)

@define_custom_reverse_primitive(
    "map_grid",
    arrow(arrow(t0, t1), tgrid(t0), tgrid(t1)),
    (f -> (xs -> map(f, xs))),
    reverse_map("map_grid", tgrid, every_primitive["zip_grid2"])
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

fill_selector(p::Hole) = FreeVar(p.t, nothing)
fill_selector(p::Apply) = Apply(fill_selector(p.f), fill_selector(p.x))
fill_selector(p::Abstraction) = Abstraction(fill_selector(p.b))
fill_selector(p::Program) = p

function reverse_rev_select(name)
    function _reverse_rev_select(arguments)
        f = pop!(arguments)
        fill_f = fill_selector(f)
        fill_base, rev_base, _, filled_types_base = _get_reversed_filled_program(pop!(arguments), arguments)
        fill_others, rev_others, _, filled_types_others = _get_reversed_filled_program(pop!(arguments), arguments)
        function __reverse_rev_select(value)::Vector{Any}
            if f == fill_f
                results_base = Array{Any}(undef, size(value)...)
                results_others = Array{Any}(undef, size(value)...)
                for i in 1:length(value)
                    if try_evaluate_program(fill_f, [value[i]], Dict())
                        results_base[i] = value[i]
                        results_others[i] = nothing
                    else
                        results_base[i] = nothing
                        results_others[i] = value[i]
                    end
                end
                if all(v == results_base[1] for v in results_base)
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
                            results_base[j] = nothing
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
            num_outputs = length(filled_types_base) + length(filled_types_others)
            if f != fill_f
                num_outputs += 1
            end
            outputs = [[] for _ in 1:num_outputs]
            for (h, val) in value.options
                outs = __reverse_rev_select(val)
                push!(hashes, h)
                for i in 1:num_outputs
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

        return every_primitive[name],
        __reverse_rev_select,
        [fill_others, fill_base, fill_f],
        vcat(filled_types_base, filled_types_others)
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

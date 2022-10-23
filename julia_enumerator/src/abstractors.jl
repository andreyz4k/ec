
all_abstractors = Dict{Program,Any}()

function is_reversible(p::Primitive)
    return haskey(all_abstractors, p)
end

function is_reversible(p::Apply)
    if is_reversible(p.f)
        if isa(p.x, Hole)
            return !isarrow(p.x.t)
        end
        if isa(p.x, Abstraction)
            return is_reversible(p.x.b)
        end
    end
    false
end

is_reversible(p::Invented) = is_reversible(p.b)

function is_reversible(p::Program)
    false
end

function _get_reversed_filled_program(p::Primitive)
    return all_abstractors[p]
end

noop(a) = (a,)
function _get_reversed_filled_program(p::Hole)
    return FreeVar(p.t, nothing), noop, [p.t]
end

function _get_reversed_filled_program(p::Apply)
    reversed_f = _get_reversed_filled_program(p.f)
    return reversed_f(p.x)
end

function _get_reversed_filled_program(p::Abstraction)
    fill_f, rev_f, filled_types = _get_reversed_filled_program(p.b)
    return Abstraction(fill_f), rev_f, filled_types
end

function get_reversed_filled_program(p::Program)
    fill_p, rev_p, _ = _get_reversed_filled_program(p)
    return fill_p, rev_p
end

function generic_reverse2(prim, rev_function)
    function _generic_reverse(a, b)
        fill_a, rev_a, filled_types_a = _get_reversed_filled_program(a)
        fill_b, rev_b, filled_types_b = _get_reversed_filled_program(b)
        function _reverse_function(value)
            r_a, r_b = rev_function(value)
            return rev_a(r_a)..., rev_b(r_b)...
        end
        return Apply(Apply(prim, fill_a), fill_b), _reverse_function, vcat(filled_types_a, filled_types_b)
    end
    return _generic_reverse
end

function generic_reverse1(prim, rev_function)
    function _generic_reverse(a)
        fill_a, rev_a, filled_types_a = _get_reversed_filled_program(a)
        function _reverse_function(value)
            r_a, = rev_function(value)
            return rev_a(r_a)
        end
        return Apply(prim, fill_a), _reverse_function, filled_types_a
    end
    return _generic_reverse
end

macro define_reverse_primitive(name, reverse_function)
    return quote
        local n = $(esc(name))
        local prim = every_primitive[n]
        if length(arguments_of_type(prim.t)) == 1
            local reversed_func = generic_reverse1(prim, $(esc(reverse_function)))
            local out = a -> reversed_func(a)
        elseif length(arguments_of_type(prim.t)) == 2
            local reversed_func = generic_reverse2(prim, $(esc(reverse_function)))
            local out = a -> b -> reversed_func(a, b)
        end
        all_abstractors[prim] = out
    end
end

macro define_custom_reverse_primitive(name, reverse_function)
    return quote
        local n = $(esc(name))
        local prim = every_primitive[n]
        if length(arguments_of_type(prim.t)) == 2
            local out = a -> b -> $(esc(reverse_function))(a, b)
        end
        all_abstractors[prim] = out
    end
end

function reverse_repeat(value)
    if any(v != value[1] for v in value)
        error("Elements are not equal")
    end
    return value[1], length(value)
end

@define_reverse_primitive "repeat" reverse_repeat

function reverse_cons(value)
    if isempty(value)
        error("List is empty")
    end
    return value[1], value[2:end]
end

@define_reverse_primitive "cons" reverse_cons

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

function zip_free_vars(filled_hole, filled_types)
    if length(filled_types) == 2
        return filled_hole, [filled_types[2]]
    elseif length(filled_types) == 3
        return (
            Apply(
                Apply(every_primitive["zip2"], FreeVar(tlist(filled_types[1]), nothing)),
                FreeVar(tlist(filled_types[2]), nothing),
            ),
            [tlist(filled_types[1]), tlist(filled_types[2])],
        )
    end
end

function reverse_map(f, x)
    fill_f, rev_f, filled_types_f = _get_reversed_filled_program(f)
    fill_x, rev_x, filled_types_x = _get_reversed_filled_program(x)
    function _reverse_map(value)
        results = tuple([[] for _ in filled_types_f]...)
        for values in map(rev_f, value)
            for (i, v) in enumerate(values)
                push!(results[i], v)
            end
        end
        return results
    end
    new_f, _ = map_function_replacement(fill_f, filled_types_f)
    filled_types = vcat(filled_types_f, filled_types_x)
    new_x, filled_types = zip_free_vars(fill_x, filled_types)
    return Apply(Apply(every_primitive["map"], new_f), new_x), _reverse_map, filled_types
end

@define_custom_reverse_primitive "map" reverse_map

function reverse_concat(value)
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
    return out_h, out_t
end

@define_reverse_primitive "concat" reverse_concat

function reverse_range(value)
    for (i, v) in enumerate(value)
        if v != i - 1
            error("Invalid value")
        end
    end
    return (length(value) - 1,)
end

@define_reverse_primitive "range" reverse_range


all_abstractors = Dict{Program,Any}()

function is_reversible(p::Primitive)
    return haskey(all_abstractors, p)
end

function is_reversible(p::Apply)
    if is_reversible(p.f)
        if isa(p.x, Hole)
            return !isarrow(p.x.t)
        end
        if isa(p.x, Index)
            return true
        end
        if isa(p.x, Abstraction) || isa(p.x, Apply)
            return is_reversible(p.x)
        end
    end
    false
end

is_reversible(p::Invented) = is_reversible(p.b)
is_reversible(p::Abstraction) = is_reversible(p.b)

is_reversible(p::Program) = false

function _get_reversed_filled_program(p::Primitive, arguments)
    return all_abstractors[p](arguments)
end

function _get_reversed_filled_program(p::Invented, arguments)
    filled_b, rev_b, updated_args, filled_types = _get_reversed_filled_program(p.b, arguments)
    if filled_b != p.b
        error("Incorrect filling in invented function")
    end
    return p, rev_b, updated_args, filled_types
end
noop(a) = (a,)
function _get_reversed_filled_program(p::Hole, arguments)
    return FreeVar(p.t, nothing), noop, arguments, [p.t]
end

function _get_reversed_filled_program(p::Index, arguments)
    return p, noop, arguments, []
end

function _get_reversed_filled_program(p::Apply, arguments)
    filled_x, reversed_x, _, filled_x_types = _get_reversed_filled_program(p.x, arguments)
    push!(arguments, (filled_x, reversed_x, filled_x_types))
    filled_f, reversed_f, updated_args, filled_f_types = _get_reversed_filled_program(p.f, arguments)
    new_filled_x, _, new_filled_x_types = pop!(updated_args)
    pop!(arguments)
    return Apply(filled_f, new_filled_x), reversed_f, updated_args, vcat(filled_f_types, new_filled_x_types)
end

function _get_reversed_filled_program(p::Abstraction, arguments)
    res = _get_reversed_filled_program(p.b, arguments)
    fill_f, rev_f, updated_args, filled_types = res
    return Abstraction(fill_f), rev_f, updated_args, filled_types
end

function get_reversed_filled_program(p::Program)
    fill_p, rev_p, _, _ = _get_reversed_filled_program(p, [])
    return fill_p, rev_p
end

function generic_reverse2(prim, rev_function)
    function _generic_reverse(arguments)
        fill_a, rev_a, filled_types_a = arguments[end]
        fill_b, rev_b, filled_types_b = arguments[end-1]
        function _reverse_function(value)
            r_a, r_b = rev_function(value)
            return rev_a(r_a)..., rev_b(r_b)...
        end
        return prim, _reverse_function, copy(arguments), []
    end
    return _generic_reverse
end

function generic_reverse1(prim, rev_function)
    function _generic_reverse(arguments)
        fill_a, rev_a, filled_types_a = arguments[end]
        function _reverse_function(value)
            r_a, = rev_function(value)
            return rev_a(r_a)
        end
        return prim, _reverse_function, copy(arguments), []
    end
    return _generic_reverse
end

macro define_reverse_primitive(name, reverse_function)
    return quote
        local n = $(esc(name))
        local prim = every_primitive[n]
        if length(arguments_of_type(prim.t)) == 1
            local out = generic_reverse1(prim, $(esc(reverse_function)))
        elseif length(arguments_of_type(prim.t)) == 2
            local out = generic_reverse2(prim, $(esc(reverse_function)))
        end
        all_abstractors[prim] = out
    end
end

macro define_custom_reverse_primitive(name, reverse_function)
    return quote
        local n = $(esc(name))
        local prim = every_primitive[n]
        if length(arguments_of_type(prim.t)) == 2
            local out = $(esc(reverse_function))
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
        fill_f, rev_f, filled_types_f = arguments[end]
        fill_x, rev_x, filled_types_x = arguments[end-1]
        function __reverse_map(value)
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
        updated_args = arguments[begin:end-2]
        push!(updated_args, (new_x, rev_x, filled_types))
        push!(updated_args, (new_f, rev_f, []))
        return every_primitive[name], __reverse_map, updated_args, []
    end

    return _reverse_map
end

@define_custom_reverse_primitive "map" reverse_map("map", tlist, every_primitive["zip2"])
@define_custom_reverse_primitive "map_grid" reverse_map("map_grid", tgrid, every_primitive["zip_grid2"])

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

function reverse_rows_to_grid(value)
    ([value[i, :] for i in (1:size(value, 1))],)
end

@define_reverse_primitive "rows_to_grid" reverse_rows_to_grid

function reverse_columns_to_grid(value)
    ([value[:, i] for i in (1:size(value, 2))],)
end

@define_reverse_primitive "columns_to_grid" reverse_columns_to_grid

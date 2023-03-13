
all_abstractors = Dict{Program,Tuple{Vector,Any}}()

struct AnyObject end
any_object = AnyObject()

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

function _get_reversed_program(p::Primitive, arguments)
    return all_abstractors[p][2](arguments)
end

function _get_reversed_program(p::Invented, arguments)
    _get_reversed_program(p.b, arguments)
end

noop(a)::Vector{Any} = [a]

function _get_reversed_program(p::Hole, arguments)
    return noop
end

function _get_reversed_program(p::Index, arguments)
    return noop
end

function _get_reversed_program(p::Apply, arguments)
    push!(arguments, p.x)
    reversed_f = _get_reversed_program(p.f, arguments)
    return reversed_f
end

function _get_reversed_program(p::Abstraction, arguments)
    # Only used in invented functions
    rev_f = _get_reversed_program(p.b, arguments)
    rev_a = _get_reversed_program(pop!(arguments), arguments)
    # TODO: Properly use rev_a
    return rev_f
end

function get_reversed_program(p::Program)
    return _get_reversed_program(p, [])
end

function _reverse_eithers(_reverse_function, value)
    hashes = []
    outputs = Vector{Any}[]
    for (h, val) in value.options
        outs = _reverse_function(val)
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

function generic_reverse(rev_function, n)
    function _generic_reverse(arguments)
        rev_functions = []
        for _ in 1:n
            rev_a = _get_reversed_program(pop!(arguments), arguments)
            push!(rev_functions, rev_a)
        end
        function _reverse_function(value)::Vector{Any}
            rev_results = rev_function(value)
            return vcat([rev_functions[i](rev_results[i]) for i in 1:n]...)
        end
        function _reverse_function(value::EitherOptions)::Vector{Any}
            _reverse_eithers(_reverse_function, value)
        end
        return _reverse_function
    end
    return _generic_reverse
end

macro define_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        local rev = generic_reverse($(esc(reverse_function)), length(arguments_of_type(prim.t)))
        all_abstractors[prim] = [], rev
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

_has_no_holes(p::Hole) = false
_has_no_holes(p::Apply) = _has_no_holes(p.f) && _has_no_holes(p.x)
_has_no_holes(p::Abstraction) = _has_no_holes(p.b)
_has_no_holes(p::Program) = true

_is_reversible_mapper(p) = is_reversible(p) && _has_no_holes(p)

_is_possible_mapper(p::Index, from_input, skeleton, path) = p.n != 0 || !isa(path[end], ArgTurn)
_is_possible_mapper(p::Primitive, from_input, skeleton, path) = !from_input || haskey(all_abstractors, p)
_is_possible_mapper(p::Invented, from_input, skeleton, path) = !from_input || is_reversible(p)
_is_possible_mapper(p::FreeVar, from_input, skeleton, path) = !from_input

_walk_mapper(p::Index) = [p.n]
_walk_mapper(p::Primitive) = []
_walk_mapper(p::Invented) = []
_walk_mapper(p::Apply) = vcat(_walk_mapper(p.f), _walk_mapper(p.x))
_walk_mapper(p::Abstraction) = [i - 1 for i in _walk_mapper(p.b) if i > 0]

function reverse_map(n)
    function _reverse_map(arguments)
        f = pop!(arguments)
        for _ in 1:n
            f = f.b
        end
        rev_f = _get_reversed_program(f, arguments)
        rev_f = _rmapper(rev_f, n)

        indices_mapping = _walk_mapper(f)

        rev_xs = []
        for _ in 1:n
            rev_x = _get_reversed_program(pop!(arguments), arguments)
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
                            filled_indices = Dict{Int,Any}()
                            for i in 1:n
                                mapped_i = n - indices_mapping[i]
                                if haskey(filled_indices, mapped_i)
                                    if filled_indices[mapped_i] != option[i]
                                        error("Filling the same index with different values")
                                    end
                                else
                                    filled_indices[mapped_i] = option[i]
                                    push!(new_option, copy(output_option[mapped_i]))
                                    push!(new_option[mapped_i], option[i])
                                end
                            end
                            push!(new_options, new_option)
                            if length(new_options) > 100
                                error("Too many options")
                            end
                        end
                    end
                    output_options = new_options
                else
                    filled_indices = Dict{Int,Any}()
                    for (i, v) in enumerate(values)
                        mapped_i = n - indices_mapping[i]
                        if haskey(filled_indices, mapped_i)
                            if filled_indices[mapped_i] != v
                                error("Filling the same index with different values")
                            end
                        else
                            filled_indices[mapped_i] = v
                            for option in output_options
                                push!(option[mapped_i], v)
                            end
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
            _reverse_eithers(__reverse_map, value)
        end

        return __reverse_map
    end

    return [(_is_reversible_mapper, _is_possible_mapper)], _reverse_map
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

function list_elements(value)
    elements = []
    n = length(value)
    for i in 1:n
        val = value[i]
        if val !== nothing
            push!(elements, (i, val))
        end
    end
    return [elements, n]
end

function collect_elements(elements, len)
    output = Array{Any}(nothing, len)
    for (i, el) in elements
        output[i] = el
    end
    return output
end

function grid_elements(value)
    elements = []
    n, m = size(value)
    for i in 1:n
        for j in 1:m
            val = value[i, j]
            if val !== nothing
                push!(elements, ((i, j), val))
            end
        end
    end
    return [elements, n, m]
end

function collect_grid_elements(elements, len1, len2)
    output = Array{Any}(nothing, len1, len2)
    for ((i, j), el) in elements
        output[i, j] = el
    end
    return output
end

@define_reverse_primitive(
    "rev_list_elements",
    arrow(tlist(ttuple2(tint, t0)), tint, tlist(t0)),
    (elements -> (len -> collect_elements(elements, len))),
    list_elements
)
@define_reverse_primitive(
    "rev_grid_elements",
    arrow(tlist(ttuple2(ttuple2(tint, tint), t0)), tint, tint, tgrid(t0)),
    (elements -> (height -> (width -> collect_grid_elements(elements, height, width)))),
    grid_elements
)

function reverse_zip2(values)
    values1 = Array{Any}(undef, size(values))
    values2 = Array{Any}(undef, size(values))
    for i in eachindex(values)
        values1[i] = values[i][1]
        values2[i] = values[i][2]
    end
    return [values1, values2]
end

function zip2(values1, values2)
    values = Array{Any}(undef, size(values1))
    for i in eachindex(values)
        values[i] = (values1[i], values2[i])
    end
    return values
end

@define_reverse_primitive(
    "zip2",
    arrow(tlist(t0), tlist(t1), tlist(ttuple2(t0, t1))),
    (a -> (b -> zip2(a, b))),
    reverse_zip2
)
@define_reverse_primitive(
    "zip_grid2",
    arrow(tgrid(t0), tgrid(t1), tgrid(ttuple2(t0, t1))),
    (a -> (b -> zip2(a, b))),
    reverse_zip2
)

@define_reverse_primitive("reverse", arrow(tlist(t0), tlist(t0)), (a -> reverse(a)), (a -> [reverse(a)]),)

function rev_fold(f, init, acc)
    rev_f = _get_reversed_program(f.p.b.b, [])
    outs = []
    while acc != init
        out, acc = rev_f(acc)
        push!(outs, out)
    end
    return reverse(outs)
end

_is_possible_init(p::Primitive, from_input, skeleton, path) = true
_is_possible_init(p::FreeVar, from_input, skeleton, path) = false
_is_possible_init(p::Index, from_input, skeleton, path) = true
_is_possible_init(p::Invented, from_input, skeleton, path) = true

_is_possible_folder(p::Index, from_input, skeleton, path) = true
_is_possible_folder(p::Primitive, from_input, skeleton, path) = haskey(all_abstractors, p)
_is_possible_folder(p::Invented, from_input, skeleton, path) = is_reversible(p)
_is_possible_folder(p::FreeVar, from_input, skeleton, path) = false

function reverse_rev_fold()
    function _reverse_rev_fold(arguments)
        f = pop!(arguments)

        init = pop!(arguments)
        rev_x = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_rev_fold(value)::Vector{Any}
            acc = run_with_arguments(init, [], Dict())
            for val in value
                acc = run_with_arguments(f, [val, acc], Dict())
            end
            return rev_x(acc)
        end

        function __reverse_rev_fold(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_rev_fold, value)
        end

        return __reverse_rev_fold
    end
    return [(_has_no_holes, _is_possible_init), (_is_reversible_mapper, _is_possible_folder)], _reverse_rev_fold
end

@define_custom_reverse_primitive(
    "rev_fold",
    arrow(arrow(t0, t1, t1), t1, t1, tlist(t0)),
    (f -> (init -> (acc -> rev_fold(f, init, acc)))),
    reverse_rev_fold()
)

function reverse_fold()
    function _reverse_fold(arguments)
        f = pop!(arguments)
        rev_f = _get_reversed_program(f.b.b, [])

        indices_mapping = _walk_mapper(f.b.b)

        rev_itr = _get_reversed_program(pop!(arguments), arguments)
        rev_init = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_fold(value)::Vector{Any}
            options_itr = Dict()
            options_init = Dict()
            itr = []
            acc = value

            h = hash((itr, acc))
            options_itr[h] = itr
            options_init[h] = acc

            while length(options_itr) < 100
                try
                    rev_values = rev_f(acc)

                    filled_indices = Dict{Int,Any}()
                    for (i, v) in enumerate(rev_values)
                        mapped_i = 2 - indices_mapping[i]
                        if haskey(filled_indices, mapped_i)
                            if filled_indices[mapped_i] != v
                                error("Filling the same index with different values")
                            end
                        else
                            filled_indices[mapped_i] = v
                        end
                    end

                    new_acc = filled_indices[2]
                    if new_acc == acc
                        break
                    end
                    itr = vcat(itr, [filled_indices[1]])
                    acc = new_acc

                    h = hash((itr, acc))
                    options_itr[h] = itr
                    options_init[h] = acc
                catch
                    break
                end
            end

            out_itr = if length(options_itr) == 1
                first(options_itr)[2]
            else
                EitherOptions(options_itr)
            end
            out_init = if length(options_init) == 1
                first(options_init)[2]
            else
                EitherOptions(options_init)
            end
            return vcat(rev_itr(out_itr), rev_init(out_init))
        end

        function __reverse_fold(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_fold, value)
        end

        return __reverse_fold
    end

    return [(_is_reversible_mapper, _is_possible_mapper)], _reverse_fold
end

@define_custom_reverse_primitive(
    "fold",
    arrow(arrow(t0, t1, t1), tlist(t0), t1, t1),
    (op -> (itr -> (init -> foldr((v, acc) -> op(v)(acc), itr, init = init)))),
    reverse_fold()
)

function reverse_fold_grid(dim)
    function _reverse_fold(arguments)
        f = pop!(arguments)
        rev_f = _get_reversed_program(f.b.b, [])
        indices_mapping = _walk_mapper(f.b.b)

        rev_grid = _get_reversed_program(pop!(arguments), arguments)
        rev_inits = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_fold(value)::Vector{Any}
            options_grid = Dict()
            options_inits = Dict()
            if dim == 1
                grid = Array{Any}(undef, length(value), 0)
            else
                grid = Array{Any}(undef, 0, length(value))
            end
            acc = value

            h = hash((grid, acc))
            options_grid[h] = grid
            options_inits[h] = acc

            while length(options_grid) < 100
                try
                    new_line = []
                    new_acc = []
                    for item in acc
                        rev_values = rev_f(item)

                        filled_indices = Dict{Int,Any}()
                        for (i, v) in enumerate(rev_values)
                            mapped_i = 2 - indices_mapping[i]
                            if haskey(filled_indices, mapped_i)
                                if filled_indices[mapped_i] != v
                                    error("Filling the same index with different values")
                                end
                            else
                                filled_indices[mapped_i] = v
                            end
                        end

                        push!(new_line, filled_indices[1])
                        push!(new_acc, filled_indices[2])
                    end
                    if new_acc == acc
                        break
                    end
                    if dim == 1
                        grid = hcat(grid, new_line)
                    else
                        grid = vcat(grid, new_line')
                    end
                    acc = new_acc

                    h = hash((grid, acc))
                    options_grid[h] = grid
                    options_inits[h] = acc
                catch
                    break
                end
            end

            out_grid = if length(options_grid) == 1
                first(options_grid)[2]
            else
                EitherOptions(options_grid)
            end
            out_inits = if length(options_inits) == 1
                first(options_inits)[2]
            else
                EitherOptions(options_inits)
            end
            return vcat(rev_grid(out_grid), rev_inits(out_inits))
        end

        function __reverse_fold(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_fold, value)
        end

        return __reverse_fold
    end

    return [(_is_reversible_mapper, _is_possible_mapper)], _reverse_fold
end

@define_custom_reverse_primitive(
    "fold_h",
    arrow(arrow(t0, t1, t1), tgrid(t0), tlist(t1), tlist(t1)),
    (
        op -> (
            grid -> (
                inits ->
                    [foldr((v, acc) -> op(v)(acc), view(grid, i, :), init = inits[i]) for i in 1:size(grid, 1)]
            )
        )
    ),
    reverse_fold_grid(1)
)
@define_custom_reverse_primitive(
    "fold_v",
    arrow(arrow(t0, t1, t1), tgrid(t0), tlist(t1), tlist(t1)),
    (
        op -> (
            grid -> (
                inits ->
                    [foldr((v, acc) -> op(v)(acc), view(grid, :, i), init = inits[i]) for i in 1:size(grid, 2)]
            )
        )
    ),
    reverse_fold_grid(2)
)

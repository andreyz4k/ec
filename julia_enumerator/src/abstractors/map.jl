
function reverse_map(n, is_set = false)
    function _reverse_map(arguments)
        f = pop!(arguments)
        for _ in 1:n
            f = f.b
        end
        rev_f = _get_reversed_program(f, arguments)
        rev_f = _rmapper(rev_f, n)

        indices_mapping, external_vars = _get_var_indices(f, n)

        rev_xs = []
        for _ in 1:n
            rev_x = _get_reversed_program(pop!(arguments), arguments)
            push!(rev_xs, rev_x)
        end

        function __reverse_map(value)::Vector{Any}
            if is_set
                output_options =
                    Set{Vector{Any}}([vcat(Any[nothing for _ in 1:external_vars], Any[Set() for _ in 1:n])])
            else
                output_options = Set{Vector{Any}}([vcat(Any[nothing for _ in 1:external_vars], Any[[] for _ in 1:n])])
            end

            first_item = true
            for v in value
                values = rev_f(v)
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
                            new_option = copy(output_option)
                            filled_indices = Dict{Int,Any}()
                            good_option = true
                            for i in 1:length(option)
                                mapped_i = indices_mapping[i]
                                if haskey(filled_indices, mapped_i)
                                    if filled_indices[mapped_i] != option[i]
                                        good_option = false
                                        break
                                    end
                                else
                                    filled_indices[mapped_i] = option[i]
                                    if mapped_i > external_vars
                                        new_option[mapped_i] = copy(new_option[mapped_i])
                                        push!(new_option[mapped_i], option[i])
                                    elseif first_item
                                        new_option[mapped_i] = option[i]
                                    elseif new_option[mapped_i] != option[i]
                                        good_option = false
                                        break
                                    end
                                end
                            end
                            if good_option
                                push!(new_options, new_option)
                                if length(new_options) > 100
                                    error("Too many options")
                                end
                            end
                        end
                    end
                    if isempty(new_options)
                        error("No valid options found")
                    end
                    output_options = new_options
                else
                    filled_indices = Dict{Int,Any}()
                    for (i, v) in enumerate(values)
                        mapped_i = indices_mapping[i]
                        if haskey(filled_indices, mapped_i)
                            if filled_indices[mapped_i] != v
                                error("Filling the same index with different values")
                            end
                        else
                            filled_indices[mapped_i] = v
                            for option in output_options
                                if mapped_i > external_vars
                                    push!(option[mapped_i], v)
                                elseif first_item
                                    option[mapped_i] = v
                                elseif option[mapped_i] != v
                                    error("Filling the same external index with different values")
                                end
                            end
                        end
                    end
                end
                first_item = false
            end
            if is_set
                for option in output_options
                    for val in option[external_vars+1:end]
                        if length(val) != length(value)
                            error("Losing data on map")
                        end
                    end
                end
            end
            if length(output_options) == 1
                result = first(output_options)
            else
                hashed_options = Dict(hash(option) => option for option in output_options)
                result = []
                for i in 1:(external_vars+n)
                    push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
                end
            end
            return vcat(result[1:external_vars], [rev_xs[i](result[i+external_vars]) for i in 1:n]...)
        end

        function __reverse_map(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_map, value)
        end

        return __reverse_map
    end

    return [(_is_reversible_subfunction, _is_possible_subfunction)], _reverse_map
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

function map_set(f, xs)
    result = Set([_mapper(f)(x) for x in xs])
    if length(result) != length(xs)
        error("Losing data on map")
    end
    return result
end

@define_custom_reverse_primitive(
    "map_set",
    arrow(arrow(t0, t1), tset(t0), tset(t1)),
    (f -> (xs -> map_set(f, xs))),
    reverse_map(1, true)
)

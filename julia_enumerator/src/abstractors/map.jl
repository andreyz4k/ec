
function reverse_map(n)
    function _reverse_map(arguments)
        f = pop!(arguments)
        for _ in 1:n
            f = f.b
        end
        rev_f = _get_reversed_program(f, arguments)
        rev_f = _rmapper(rev_f, n)

        indices_mapping = _get_var_indices(f)

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

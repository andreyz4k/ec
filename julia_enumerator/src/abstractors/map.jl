function unfold_options(args::Vector, indices::Dict, vars::Dict)
    if all(x -> !isa(x, EitherOptions), args) && all(x -> !isa(x, EitherOptions), values(vars))
        return [(args, indices, vars)]
    end
    result = []
    for item in Iterators.flatten([args, values(indices), values(vars)])
        if isa(item, EitherOptions)
            for (h, val) in item.options
                new_args = [fix_option_hashes([h], v) for v in args]
                new_indices = Dict(k => fix_option_hashes([h], v) for (k, v) in indices)
                new_vars = Dict(k => fix_option_hashes([h], v) for (k, v) in vars)
                append!(result, unfold_options(new_args, new_indices, new_vars))
            end
            return result
        end
    end
    return result
end

function _rev_dep_map(rev_dep_mapper)
    function __rev_dep_map(output, param)
        result = []
        for (out, fixer) in zip(output, param)
            push!(result, _abduct_value(rev_dep_mapper, out, fixer))
        end

        return result
    end
    return __rev_dep_map
end

function reverse_map(n, is_set = false)
    function _reverse_map(value, arguments, calculated_arguments)
        f = arguments[end]

        has_external_vars = _has_external_vars(f)

        if is_set
            output_options = Set{Tuple{Vector{Any},Dict,Dict}}([(Any[Set() for _ in 1:n], Dict(), Dict())])
        else
            output_options = Set{Tuple{Vector{Any},Dict,Dict}}([(Any[[] for _ in 1:n], Dict(), Dict())])
        end

        first_item = true
        for item in value
            calculated_item, predicted_arguments, filled_indices, filled_vars = _run_in_reverse(f, item)

            new_options = Set()
            if any(v isa EitherOptions for v in predicted_arguments) ||
               any(v isa EitherOptions for v in values(filled_indices)) ||
               any(v isa EitherOptions for v in values(filled_vars))
                child_options = unfold_options(predicted_arguments, filled_indices, filled_vars)

                for output_option in output_options
                    for (option_args, option_indices, option_vars) in child_options
                        if !isempty(option_indices)
                            new_option_indices = copy(output_option[2])
                        else
                            new_option_indices = output_option[2]
                        end
                        if !isempty(option_vars)
                            new_option_vars = copy(output_option[3])
                        else
                            new_option_vars = output_option[3]
                        end

                        good_option = true
                        for (k, v) in option_indices
                            if !haskey(new_option_indices, k)
                                new_option_indices[k] = v
                            elseif new_option_indices[k] != v
                                good_option = false
                                break
                            end
                        end
                        if !good_option
                            continue
                        end
                        for (k, v) in option_vars
                            if !haskey(new_option_vars, k)
                                new_option_vars[k] = v
                            elseif new_option_vars[k] != v
                                good_option = false
                                break
                            end
                        end
                        if !good_option
                            continue
                        end
                        new_option_args = [copy(arg) for arg in output_option[1]]
                        for (i, v) in enumerate(option_args)
                            push!(new_option_args[i], v)
                        end

                        push!(new_options, (new_option_args, new_option_indices, new_option_vars))
                        if length(new_options) > 100
                            error("Too many options")
                        end
                    end
                end

            else
                for option in output_options
                    good_option = true
                    for (k, v) in filled_indices
                        if !haskey(option[2], k)
                            option[2][k] = v
                        elseif option[2][k] != v
                            good_option = false
                            break
                        end
                    end
                    if !good_option
                        continue
                    end
                    for (k, v) in filled_vars
                        if !haskey(option[3], k)
                            option[3][k] = v
                        elseif option[3][k] != v
                            good_option = false
                            break
                        end
                    end
                    if !good_option
                        continue
                    end
                    for (i, v) in enumerate(predicted_arguments)
                        push!(option[1][i], v)
                    end
                    push!(new_options, option)
                end
            end
            first_item = false
            if isempty(new_options)
                error("No valid options found")
            end
            output_options = new_options
        end

        if first_item && has_external_vars
            error("Couldn't fill external variables")
        end
        if is_set
            for option in output_options
                for val in option[1]
                    if length(val) != length(value)
                        error("Losing data on map")
                    end
                end
            end
        end
        if length(output_options) == 1
            result_arguments, result_indices, result_vars = first(output_options)
        else
            hashed_options = Dict(rand(UInt64) => option for option in output_options)
            result_arguments = []
            result_indices = Dict()
            result_vars = Dict()
            for i in 1:n
                push!(result_arguments, EitherOptions(Dict(h => option[1][i] for (h, option) in hashed_options)))
            end
            for (k, v) in first(output_options)[2]
                result_indices[k] = EitherOptions(Dict(h => option[2][k] for (h, option) in hashed_options))
            end
            for (k, v) in first(output_options)[3]
                result_vars[k] = EitherOptions(Dict(h => option[3][k] for (h, option) in hashed_options))
            end
        end
        for i in 1:n
            if !isa(result_arguments[i], EitherOptions) && any(v isa AbductibleValue for v in result_arguments[i])
                if is_set
                    error("Abducting values for sets is not supported")
                else
                    result_arguments[i] = AbductibleValue(
                        [v.value for v in result_arguments[i]],
                        _rev_dep_map(first(result_arguments[i]).generator),
                    )
                end
            end
        end
        return value, vcat([SkipArg()], reverse(result_arguments)), result_indices, result_vars
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

function unfold_options(args::Vector, indices::Dict, vars::Dict)
    if all(x -> !isa(x, EitherOptions), args)
        return [(args, indices, vars)]
    end
    result = []
    for item in args
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

function reverse_map(n, is_set = false)
    function _reverse_map(value, context)
        f = context.arguments[end]

        external_indices = _get_var_indices(f)

        if is_set
            output_options = Set{Tuple{Vector{Any},Dict,Dict}}([(
                Any[Set() for _ in 1:n],
                context.filled_indices,
                context.filled_vars,
            )])
        else
            output_options = Set{Tuple{Vector{Any},Dict,Dict}}([(
                Any[Any[] for _ in 1:n],
                context.filled_indices,
                context.filled_vars,
            )])
        end

        calculated_value = []
        for (i, item) in enumerate(value)
            calculated_arguments = []
            for j in 1:n
                if !ismissing(context.calculated_arguments[end-j])
                    push!(calculated_arguments, context.calculated_arguments[end-j][i])
                else
                    push!(calculated_arguments, missing)
                end
            end

            new_options = Set()
            for output_option in output_options
                # @info "Output option $output_option"
                calculated_item, new_context = try
                    _run_in_reverse(
                        f,
                        item,
                        ReverseRunContext(
                            [],
                            [],
                            reverse(calculated_arguments),
                            copy(output_option[2]),
                            copy(output_option[3]),
                        ),
                    )
                catch e
                    if isa(e, InterruptException) || isa(e, MethodError)
                        rethrow()
                    end
                    # @info e
                    continue
                end
                # @info "Calculated item $calculated_item"
                # @info "New context $new_context"
                push!(calculated_value, calculated_item)

                child_options =
                    unfold_options(new_context.predicted_arguments, new_context.filled_indices, new_context.filled_vars)

                for (option_args, option_indices, option_vars) in child_options
                    # @info output_option
                    # @info option_args
                    # @info option_indices
                    # @info option_vars

                    new_option_args = Any[copy(arg) for arg in output_option[1]]
                    for (i, v) in enumerate(option_args)
                        push!(new_option_args[i], v)
                    end

                    push!(new_options, (new_option_args, option_indices, option_vars))
                    if length(new_options) > 100
                        error("Too many options")
                    end
                end
            end
            if isempty(new_options)
                error("No valid options found")
            end
            output_options = new_options
        end

        # @info "Output options $output_options"
        # @info "External indices $external_indices"
        filter!(output_options) do option
            for i in external_indices
                if i >= 0
                    if !haskey(option[2], i)
                        return false
                    end
                else
                    if !haskey(option[3], UInt64(-i))
                        return false
                    end
                end
            end
            return true
        end
        # @info "Output options $output_options"
        if isempty(output_options)
            error("No valid options found")
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
            result_arguments = Any[]
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
                    result_arguments[i] = AbductibleValue([v.value for v in result_arguments[i]],)
                end
            end
        end

        return calculated_value,
        ReverseRunContext(
            context.arguments,
            vcat([SkipArg()], reverse(result_arguments)),
            context.calculated_arguments,
            result_indices,
            result_vars,
        )
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

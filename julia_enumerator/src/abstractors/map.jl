
function unfold_options(args::Vector)
    if all(x -> !isa(x, EitherOptions), args)
        return [args]
    end
    result = []
    for item in args
        if isa(item, EitherOptions)
            for (h, val) in item.options
                new_args = [fix_option_hashes([h], v) for v in args]
                append!(result, unfold_options(new_args))
            end
            return result
        end
    end
    return result
end

function reshape_arg(arg, is_set, dims)
    has_abductible = any(v isa AbductibleValue for v in arg)

    if is_set
        result = Set([isa(v, AbductibleValue) ? v.value : v for v in arg])
        if length(result) != length(arg)
            error("Losing data on map")
        end
    else
        result = reshape([isa(v, AbductibleValue) ? v.value : v for v in arg], dims)
    end
    if has_abductible
        return AbductibleValue(result)
    else
        return result
    end
end

function unfold_map_options(calculated_arguments, indices, vars, is_set, dims)
    for (k, item) in Iterators.flatten((indices, vars))
        if isa(item, EitherOptions)
            result_options = Dict()
            for (h, val) in item.options
                new_args = [[fix_option_hashes([h], v) for v in args] for args in calculated_arguments]
                new_indices = Dict(k => fix_option_hashes([h], v) for (k, v) in indices)
                new_vars = Dict(k => fix_option_hashes([h], v) for (k, v) in vars)
                result_options[h] = unfold_map_options(new_args, new_indices, new_vars, is_set, dims)
            end
            return [
                EitherOptions(Dict(h => op[i] for (h, op) in result_options)) for i in 1:length(calculated_arguments[1])
            ]
        end
    end
    options = [[[] for _ in 1:length(calculated_arguments[1])]]
    for args in calculated_arguments
        new_options = []
        point_options = unfold_options(args)
        for option in options
            for point_option in point_options
                new_option = [vcat(option[i], [point_option[i]]) for i in 1:length(option)]
                push!(new_options, new_option)
            end
        end
        options = new_options
    end
    hashed_options = Dict(rand(UInt64) => option for option in options)
    result = [
        EitherOptions(Dict(h => reshape_arg(option[i], is_set, dims) for (h, option) in hashed_options)) for
        i in 1:length(calculated_arguments[1])
    ]
    return result
end

function reverse_map(n, is_set = false)
    function _reverse_map(value, context)
        f = context.arguments[end]

        external_indices = _get_var_indices(f)

        filled_indices = context.filled_indices
        filled_vars = context.filled_vars

        # @info "Reversing map with $f"
        need_recompute = true

        computed_outputs = Any[]
        calculated_value = []

        while need_recompute
            need_recompute = false
            calculated_value = []
            computed_outputs = Any[]

            for (i, item) in enumerate(value)
                # @info "Item $item"
                calculated_arguments = []
                for j in 1:n
                    if !ismissing(context.calculated_arguments[end-j])
                        push!(calculated_arguments, context.calculated_arguments[end-j][i])
                    else
                        push!(calculated_arguments, missing)
                    end
                end

                calculated_item, new_context = _run_in_reverse(
                    f,
                    item,
                    ReverseRunContext([], [], reverse(calculated_arguments), copy(filled_indices), copy(filled_vars)),
                )

                # @info "Calculated item $calculated_item"
                # @info "New context $new_context"

                if (!isempty(filled_indices) && filled_indices != new_context.filled_indices) ||
                   (!isempty(filled_vars) && filled_vars != new_context.filled_vars)
                    need_recompute = true
                    # @info "Need recompute"
                    # @info "Filled indices $filled_indices"
                    # @info "Filled vars $filled_vars"
                    filled_indices = new_context.filled_indices
                    filled_vars = new_context.filled_vars
                    break
                end

                filled_indices = new_context.filled_indices
                filled_vars = new_context.filled_vars

                push!(calculated_value, calculated_item)

                push!(computed_outputs, new_context.predicted_arguments)
            end
        end

        # @info "Computed outputs $computed_outputs"
        # @info "External indices $external_indices"

        for i in external_indices
            if i >= 0
                if !haskey(filled_indices, i)
                    error("Missing index $i")
                end
            else
                if !haskey(filled_vars, UInt64(-i))
                    error("Missing var $(-i)")
                end
            end
        end

        computed_outputs =
            unfold_map_options(computed_outputs, filled_indices, filled_vars, is_set, is_set ? nothing : size(value))
        # @info "Computed outputs $computed_outputs"
        # @info "filled_indices $filled_indices"
        # @info "filled_vars $filled_vars"

        # @info "Calculated value $calculated_value"
        if is_set
            calculated_value = Set(calculated_value)
        else
            calculated_value = reshape(calculated_value, size(value))
        end

        return calculated_value,
        ReverseRunContext(
            context.arguments,
            vcat(context.predicted_arguments, computed_outputs, [SkipArg()]),
            context.calculated_arguments,
            filled_indices,
            filled_vars,
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

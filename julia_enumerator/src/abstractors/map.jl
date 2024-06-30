
function unfold_options(args::Vector, out)
    if all(x -> !isa(x, EitherOptions), args)
        return [(args, out)]
    end
    result = []
    for item in args
        if isa(item, EitherOptions)
            for (h, val) in item.options
                new_args = [fix_option_hashes([h], v) for v in args]
                new_out = fix_option_hashes([h], out)
                res = unfold_options(new_args, new_out)
                append!(result, res)
            end
            return result
        end
    end
    return [(result, out)]
end

function reshape_arg(arg, is_set, dims)
    has_abductible = any(v isa AbductibleValue for v in arg)
    has_pattern = any(v isa PatternWrapper for v in arg)

    if is_set
        result = Set([isa(v, AbductibleValue) || isa(v, PatternWrapper) ? v.value : v for v in arg])
        if length(result) != length(arg)
            if has_abductible
                result = any_object
            else
                error("Losing data on map with $arg and $result")
            end
        end
    else
        result = reshape([isa(v, AbductibleValue) || isa(v, PatternWrapper) ? v.value : v for v in arg], dims)
    end
    if has_abductible
        return AbductibleValue(result)
    elseif has_pattern
        return PatternWrapper(result)
    else
        return result
    end
end

function unfold_map_options(output_options, dims)
    all_options = Set()
    for output_option in output_options
        predicted_arguments = output_option[1]

        options = [([[] for _ in 1:length(predicted_arguments[1])], [])]
        for (item_args, item_out) in zip(predicted_arguments, output_option[2])
            # @info "Item args $item_args"
            # @info "Item out $item_out"
            new_options = []
            item_options = unfold_options(item_args, item_out)
            # @info "Item options $item_options"
            for option in options
                for (point_option, out_option) in item_options
                    new_option = (
                        [vcat(option[1][i], [point_option[i]]) for i in 1:length(option[1])],
                        vcat(option[2], [out_option]),
                    )
                    push!(new_options, new_option)
                end
            end
            options = new_options
        end
        hashed_options = Dict(rand(UInt64) => option for option in options)
        option_args = [
            EitherOptions(Dict(h => reshape_arg(option[1][i], false, dims) for (h, option) in hashed_options)) for
            i in 1:length(predicted_arguments[1])
        ]
        option_output = EitherOptions(Dict(h => reshape_arg(option[2], false, dims) for (h, option) in hashed_options))
        push!(all_options, (option_args, option_output, output_option[3], output_option[4]))
    end
    if length(all_options) == 1
        return first(all_options)
    else
        hashed_out_options = Dict(rand(UInt64) => option for option in all_options)
        result_args = [
            EitherOptions(Dict(h => option[1][i] for (h, option) in hashed_out_options)) for
            i in 1:length(first(all_options)[1])
        ]
        result_output = EitherOptions(Dict(h => option[2] for (h, option) in hashed_out_options))
        result_indices = Dict(
            k => EitherOptions(Dict(h => option[3][k] for (h, option) in hashed_out_options)) for
            (k, _) in first(all_options)[3]
        )
        result_vars = Dict(
            k => EitherOptions(Dict(h => option[4][k] for (h, option) in hashed_out_options)) for
            (k, _) in first(all_options)[4]
        )
        return result_args, result_output, result_indices, result_vars
    end
end

function _unfold_item_options(calculated_arguments, indices, vars)
    for (k, item) in Iterators.flatten((indices, vars))
        if isa(item, EitherOptions)
            results = Set()
            for (h, val) in item.options
                new_args = [fix_option_hashes([h], arg) for arg in calculated_arguments]
                new_indices = Dict(k => fix_option_hashes([h], v) for (k, v) in indices)
                new_vars = Dict(k => fix_option_hashes([h], v) for (k, v) in vars)
                union!(results, _unfold_item_options(new_args, new_indices, new_vars))
            end
            return results
        end
    end
    return Set([(calculated_arguments, indices, vars)])
end

function _can_be_output_map_option(option, context, external_indices, external_vars)
    for i in external_indices
        if !haskey(option[3], i)
            return false
        end
    end
    for i in external_vars
        if !haskey(option[4], i)
            return false
        end
    end
    return true
end

function reverse_map(n)
    function _reverse_map(value, context)
        f = context.arguments[end]

        # @info "Reversing map with $f"
        options_queue = Queue{UInt64}()
        options_queue_dict = Dict()
        visited = Set{UInt64}()
        output_options = Set()
        starting_option = ([], [], context.filled_indices, context.filled_vars)
        h = hash(starting_option)
        enqueue!(options_queue, h)
        options_queue_dict[h] = starting_option

        while !isempty(options_queue)
            h = dequeue!(options_queue)
            option = options_queue_dict[h]
            delete!(options_queue_dict, h)

            # @info "Option $option"
            push!(visited, h)
            i = length(option[1]) + 1
            item = value[i]

            # @info "Item $item"

            calculated_arguments = []
            for j in 1:n
                if !ismissing(context.calculated_arguments[end-j])
                    if isnothing(context.calculated_arguments[end-j])
                        return false, value, context
                        # error("Expected argument is nothing for non-nothing output value")
                    end
                    push!(calculated_arguments, context.calculated_arguments[end-j][i])
                else
                    push!(calculated_arguments, missing)
                end
            end

            success, calculated_item, new_context = _run_in_reverse(
                f,
                item,
                ReverseRunContext([], [], reverse(calculated_arguments), copy(option[3]), copy(option[4])),
            )

            if !success
                continue
            end

            # @info "Calculated item $calculated_item"
            # @info "New context $new_context"

            for (option_args, option_indices, option_vars) in _unfold_item_options(
                new_context.predicted_arguments,
                new_context.filled_indices,
                new_context.filled_vars,
            )
                # @info "Unfolded option $option_args"
                # @info "Unfolded indices $option_indices"
                # @info "Unfolded vars $option_vars"
                if !isempty(option[3]) || !isempty(option[4])
                    need_reset = false
                    for (k, v) in option_indices
                        if haskey(option[3], k) && option[3][k] != v
                            need_reset = true
                            break
                        end
                    end
                    for (k, v) in option_vars
                        if haskey(option[4], k) && option[4][k] != v
                            need_reset = true
                            break
                        end
                    end
                    if need_reset
                        # @info "Need reset"
                        new_option = ([], [], option_indices, option_vars)
                        # @info new_option
                        new_h = hash(new_option)
                        if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                            enqueue!(options_queue, new_h)
                            options_queue_dict[new_h] = new_option
                        end

                        continue
                    end
                end
                new_option =
                    (vcat(option[1], [option_args]), vcat(option[2], [calculated_item]), option_indices, option_vars)
                # @info new_option

                if i == length(value)
                    if _can_be_output_map_option(new_option, context, f.indices, f.var_ids)
                        push!(output_options, new_option)
                        # @info "Inserted output option $new_option"
                    end
                else
                    new_h = hash(new_option)
                    if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                        enqueue!(options_queue, new_h)
                        options_queue_dict[new_h] = new_option
                    end
                end
            end
        end
        # @info "Output options $output_options"
        if length(output_options) == 0
            return false, value, context
        else
            computed_outputs, calculated_value, filled_indices, filled_vars = try
                unfold_map_options(output_options, size(value))
            catch e
                if isa(e, TooManyOptionsException)
                    return false, value, context
                end
                rethrow()
            end
        end

        # @info "Computed outputs $computed_outputs"
        # @info "filled_indices $filled_indices"
        # @info "filled_vars $filled_vars"

        # @info "Calculated value $calculated_value"

        return true,
        calculated_value,
        ReverseRunContext(
            context.arguments,
            vcat(context.predicted_arguments, computed_outputs, [SkipArg()]),
            context.calculated_arguments,
            filled_indices,
            filled_vars,
        )
    end

    return [(_is_reversible_subfunction, IsPossibleSubfunction())], _reverse_map
end

function unfold_map_set_options(output_options)
    all_options = Set()
    for output_option in output_options
        predicted_arguments = output_option[1]
        if isa(predicted_arguments, AbductibleValue)
            push!(all_options, ([predicted_arguments], output_option[2], output_option[3], output_option[4]))
        else
            options = Set([([[]], [])])
            for (item_args, item_out) in zip(predicted_arguments, output_option[2])
                # @info "Item args $item_args"
                # @info "Item out $item_out"
                new_options = Set()
                item_options = unfold_options([item_args], item_out)
                # @info "Item options $item_options"
                for option in options
                    for (point_option, out_option) in item_options
                        new_option = (
                            [vcat(option[1][i], [point_option[i]]) for i in 1:length(option[1])],
                            vcat(option[2], [out_option]),
                        )
                        push!(new_options, new_option)
                    end
                end
                options = new_options
            end
            hashed_options = Dict(rand(UInt64) => option for option in options)
            option_args =
                [EitherOptions(Dict(h => reshape_arg(option[1][1], true, nothing) for (h, option) in hashed_options))]
            option_output =
                EitherOptions(Dict(h => reshape_arg(option[2], true, nothing) for (h, option) in hashed_options))
            push!(all_options, (option_args, option_output, output_option[3], output_option[4]))
        end
    end
    if length(all_options) == 1
        return first(all_options)
    else
        hashed_out_options = Dict(rand(UInt64) => option for option in all_options)
        result_args = [
            EitherOptions(Dict(h => option[1][i] for (h, option) in hashed_out_options)) for
            i in 1:length(first(all_options)[1])
        ]
        result_output = EitherOptions(Dict(h => option[2] for (h, option) in hashed_out_options))
        result_indices = Dict(
            k => EitherOptions(Dict(h => option[3][k] for (h, option) in hashed_out_options)) for
            (k, _) in first(all_options)[3]
        )
        result_vars = Dict(
            k => EitherOptions(Dict(h => option[4][k] for (h, option) in hashed_out_options)) for
            (k, _) in first(all_options)[4]
        )
        return result_args, result_output, result_indices, result_vars
    end
end

function reverse_map_set()
    function _reverse_map(value, context)
        f = context.arguments[end]

        # @info "Reversing map with $f"
        options_queue = Queue{UInt64}()
        options_queue_dict = Dict()
        visited = Set{UInt64}()
        output_options = Set()
        if isnothing(context.calculated_arguments[end-1])
            error("Expected argument is nothing for non-nothing output value")
        end
        starting_option =
            (Set(), Set(), context.filled_indices, context.filled_vars, context.calculated_arguments[end-1], value)
        h = hash(starting_option)
        enqueue!(options_queue, h)
        options_queue_dict[h] = starting_option

        while !isempty(options_queue)
            h = dequeue!(options_queue)
            option = options_queue_dict[h]
            delete!(options_queue_dict, h)

            # @info "Option $option"
            push!(visited, h)
            item = first(option[6])

            # @info "Item $item"

            if ismissing(option[5])
                calculated_argument_options = [missing]
            else
                calculated_argument_options = option[5]
            end

            for calculated_arg_option in calculated_argument_options
                success, calculated_item, new_context = _run_in_reverse(
                    f,
                    item,
                    ReverseRunContext([], [], [calculated_arg_option], copy(option[3]), copy(option[4])),
                )

                if !success
                    continue
                end

                # @info "Calculated item $calculated_item"
                # @info "New context $new_context"

                for (option_args, option_indices, option_vars) in _unfold_item_options(
                    new_context.predicted_arguments,
                    new_context.filled_indices,
                    new_context.filled_vars,
                )
                    # @info "Unfolded option $option_args"
                    # @info "Unfolded indices $option_indices"
                    # @info "Unfolded vars $option_vars"
                    if !isempty(option[3]) || !isempty(option[4])
                        need_reset = false
                        for (k, v) in option_indices
                            if haskey(option[3], k) && option[3][k] != v
                                need_reset = true
                                break
                            end
                        end
                        for (k, v) in option_vars
                            if haskey(option[4], k) && option[4][k] != v
                                need_reset = true
                                break
                            end
                        end
                        if need_reset
                            # @info "Need reset"
                            new_option =
                                (Set(), Set(), option_indices, option_vars, context.calculated_arguments[end-1], value)
                            # @info new_option
                            new_h = hash(new_option)
                            if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                                enqueue!(options_queue, new_h)
                                options_queue_dict[new_h] = new_option
                            end

                            continue
                        end
                    end
                    if in(option_args[1], option[1])
                        if isa(option_args[1], AbductibleValue)
                            new_option =
                                (AbductibleValue(any_object), value, option_indices, option_vars, option[5], option[6])
                            if _can_be_output_map_option(new_option, context, f.indices, f.var_ids)
                                push!(output_options, new_option)
                                # @info "Inserted output option $new_option"
                            end
                        end
                        continue
                    end

                    new_option = (
                        union(option[1], [option_args[1]]),
                        union(option[2], [calculated_item]),
                        option_indices,
                        option_vars,
                        ismissing(option[5]) ? missing : setdiff(option[5], [calculated_arg_option]),
                        setdiff(option[6], [item]),
                    )
                    # @info new_option

                    if isempty(new_option[6])
                        if _can_be_output_map_option(new_option, context, f.indices, f.var_ids)
                            push!(output_options, new_option)
                            # @info "Inserted output option $new_option"
                        end
                    else
                        new_h = hash(new_option)
                        if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                            enqueue!(options_queue, new_h)
                            options_queue_dict[new_h] = new_option
                        end
                    end
                end
            end
        end
        # @info "Output options $output_options"
        if length(output_options) == 0
            return false, value, context
        else
            computed_outputs, calculated_value, filled_indices, filled_vars = try
                unfold_map_set_options(output_options)
            catch e
                if isa(e, TooManyOptionsException)
                    return false, value, context
                end
                rethrow()
            end
        end

        # @info "Computed outputs $computed_outputs"
        # @info "filled_indices $filled_indices"
        # @info "filled_vars $filled_vars"

        # @info "Calculated value $calculated_value"

        return true,
        calculated_value,
        ReverseRunContext(
            context.arguments,
            vcat(context.predicted_arguments, computed_outputs, [SkipArg()]),
            context.calculated_arguments,
            filled_indices,
            filled_vars,
        )
    end

    return [(_is_reversible_subfunction, IsPossibleSubfunction())], _reverse_map
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
    reverse_map_set()
)

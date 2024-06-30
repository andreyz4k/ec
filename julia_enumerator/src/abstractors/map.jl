
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

function unfold_map_value(items, dims)
    options = [([], [])]
    for item in items
        new_options = []
        for (op_path, prev_items) in options
            op_item = _follow_path(item.value, op_path, 1)[2]
            for (v, path) in all_path_options(op_item)
                full_path = vcat(op_path, path)
                push!(new_options, (full_path, vcat(prev_items, [v])))
            end
        end
        options = new_options
    end

    result_tree = Dict()
    result_paths = []
    for (path, items) in options
        if isempty(path)
            return reshape_arg(items, false, dims)
        end
        push!(result_paths, path)

        cur_tree = result_tree
        for p in path[1:end-1]
            if !haskey(cur_tree, p)
                cur_tree[p] = Dict()
            end
            cur_tree = cur_tree[p]
        end
        cur_tree[path[end]] = reshape_arg(items, false, dims)
    end

    return _build_eithers(result_tree, [], result_paths)
end

function reverse_map(f, value, paths, ctx, arg_count)
    f = ctx.arguments[end]

    # @info "Reversing map with $f"

    calculated_args_groups = Dict()
    if all(!isa(ctx.calculated_arguments[end-i], EitherOptions) for i in 1:arg_count-1)
        calculated_args_groups[(
            [
                ismissing(ctx.calculated_arguments[end-i]) ? missing : ctx.calculated_arguments[end-i].value for
                i in 1:arg_count-1
            ],
            Dict(i => v.value for (i, v) in ctx.filled_indices),
            Dict(i => v.value for (i, v) in ctx.filled_vars),
        )] = paths
    else
        for path in paths
            calculated_args = [
                ismissing(ctx.calculated_arguments[end-i]) ? missing :
                _follow_path(ctx.calculated_arguments[end-i].value, path, 1)[2] for i in 1:arg_count-1
            ]
            filled_indices = Dict(i => _follow_path(v.value, path, 1)[2] for (i, v) in ctx.filled_indices)
            filled_vars = Dict(i => _follow_path(v.value, path, 1)[2] for (i, v) in ctx.filled_vars)
            gr = (calculated_args, filled_indices, filled_vars)
            if !haskey(calculated_args_groups, gr)
                calculated_args_groups[gr] = []
            end
            push!(calculated_args_groups[gr], path)
        end
    end

    output_results = []
    failed_paths = []

    for ((calculated_args, f_indices, f_vars), paths_group) in calculated_args_groups
        calc_arg_groups = [([], [])]
        for i in 1:arg_count-1
            if ismissing(calculated_args[i])
                for (calc_path, args) in calc_arg_groups
                    push!(args, missing)
                end
                continue
            end
            new_arg_groups = []
            for (calc_path, args) in calc_arg_groups
                calc_arg = _follow_path(calculated_args[i], calc_path, 1)[2]

                for (v, path) in all_path_options(calc_arg)
                    full_path = vcat(calc_path, path)

                    push!(new_arg_groups, (full_path, vcat(args, [v])))
                end
            end
            calc_arg_groups = new_arg_groups
        end

        simple_values = false
        value_tree = Dict()
        arg_trees = [Dict() for _ in 1:arg_count-1]
        indices_trees = Dict()
        vars_trees = Dict()
        result_paths = []

        for (calc_path, calc_args) in calc_arg_groups
            calculated_value = []
            predicted_arguments = []

            filled_indices = Dict(i => ValueContainer(_follow_path(v, calc_path, 1)[2]) for (i, v) in f_indices)
            filled_vars = Dict(i => ValueContainer(_follow_path(v, calc_path, 1)[2]) for (i, v) in f_vars)

            good_option = true
            for (i, item) in enumerate(value)
                calculated_arguments = []
                for arg in calc_args
                    if !ismissing(arg)
                        if isnothing(arg)
                            error("Expected argument is nothing for non-nothing output value")
                        end
                        push!(calculated_arguments, ValueContainer(arg[i]))
                    else
                        push!(calculated_arguments, missing)
                    end
                end

                @info "Running in reverse $(f.p) with $item and $calculated_arguments"
                # @info "Previous values $calculated_value"
                # @info "Previous predicted arguments $predicted_arguments"
                # @info "Previous indices $filled_indices"
                @info "Previous vars $filled_vars"

                calculated_item, new_context = try
                    _run_in_reverse2(
                        f,
                        ValueContainer(item),
                        ReverseRunContext(
                            vcat(calculated_value, predicted_arguments),
                            [],
                            [],
                            reverse(calculated_arguments),
                            filled_indices,
                            filled_vars,
                        ),
                    )
                catch e
                    if isa(e, InterruptException)
                        rethrow()
                    end
                    bt = catch_backtrace()
                    @error "Got error in map" exception = (e, bt)
                    good_option = false
                    break
                end

                # @info "Got calculated item $calculated_item"
                calculated_value = new_context.upstream_outputs[1:i-1]
                predicted_arguments = new_context.upstream_outputs[i:end]
                # @info "Updated values $calculated_value"
                # @info "Updated predicted arguments $predicted_arguments"
                @info "New predicted arguments $(new_context.predicted_arguments)"

                push!(calculated_value, calculated_item)
                append!(predicted_arguments, new_context.predicted_arguments)
                filled_indices = new_context.filled_indices
                filled_vars = new_context.filled_vars
                # @info "New indices $filled_indices"
                @info "New vars $filled_vars"
            end
            if !good_option
                continue
            end

            calculated_value = unfold_map_value(calculated_value, size(value))
            predicted_arguments = [
                unfold_map_value(view(predicted_arguments, i:(arg_count-1):length(predicted_arguments)), size(value)) for i in 1:arg_count-1
            ]

            if isempty(calc_path)
                result_args = predicted_arguments
                result_value = calculated_value
                result_indices = filled_indices
                result_vars = filled_vars
                simple_values = true
                break
            end

            push!(result_paths, calc_path)
            for i in 1:arg_count-1
                cur_tree = arg_trees[i]
                for p in calc_path[1:end-1]
                    if !haskey(cur_tree, p)
                        cur_tree[p] = Dict()
                    end
                    cur_tree = cur_tree[p]
                end
                cur_tree[calc_path[end]] = predicted_arguments[i]
            end

            cur_tree = value_tree
            for p in calc_path[1:end-1]
                if !haskey(cur_tree, p)
                    cur_tree[p] = Dict()
                end
                cur_tree = cur_tree[p]
            end
            cur_tree[calc_path[end]] = calculated_value

            for (i, v) in filled_indices
                if !haskey(indices_trees, i)
                    indices_trees[i] = Dict()
                end
                cur_tree = indices_trees[i]
                for p in calc_path[1:end-1]
                    if !haskey(cur_tree, p)
                        cur_tree[p] = Dict()
                    end
                    cur_tree = cur_tree[p]
                end
                cur_tree[calc_path[end]] = v.value
            end

            for (i, v) in filled_vars
                if !haskey(vars_trees, i)
                    vars_trees[i] = Dict()
                end
                cur_tree = vars_trees[i]
                for p in calc_path[1:end-1]
                    if !haskey(cur_tree, p)
                        cur_tree[p] = Dict()
                    end
                    cur_tree = cur_tree[p]
                end
                cur_tree[calc_path[end]] = v.value
            end
        end

        if !simple_values
            if isempty(result_paths)
                append!(failed_paths, paths_group)
                continue
            end
            result_args = [_build_eithers(arg_trees[i], [], result_paths) for i in 1:arg_count-1]
            result_value = _build_eithers(value_tree, [], result_paths)
            result_indices = Dict(i => _build_eithers(t, [], result_paths) for (i, t) in indices_trees)
            result_vars = Dict(i => _build_eithers(t, [], result_paths) for (i, t) in vars_trees)
        end

        push!(output_results, (paths_group, vcat([SkipArg()], reverse(result_args)), result_indices, result_vars))
    end

    return output_results, failed_paths

    # try
    #     h = dequeue!(options_queue)
    #     option = options_queue_dict[h]
    #     delete!(options_queue_dict, h)

    #     # @info "Option $option"
    #     push!(visited, h)
    #     i = length(option[1]) + 1
    #     item = value[i]

    #     # @info "Item $item"

    #     calculated_arguments = []
    #     for j in 1:arg_count-1
    #         if !ismissing(ctx.calculated_arguments[end-j])
    #             if isnothing(ctx.calculated_arguments[end-j])
    #                 error("Expected argument is nothing for non-nothing output value")
    #             end
    #             push!(calculated_arguments, ctx.calculated_arguments[end-j][i])
    #         else
    #             push!(calculated_arguments, missing)
    #         end
    #     end

    #     calculated_item, new_context = _run_in_reverse2(
    #         f,
    #         item,
    #         ReverseRunContext([], [], reverse(calculated_arguments), copy(option[3]), copy(option[4])),
    #     )

    #     # @info "Calculated item $calculated_item"
    #     # @info "New context $new_context"

    #     for (option_args, option_indices, option_vars) in
    #         _unfold_item_options(new_context.predicted_arguments, new_context.filled_indices, new_context.filled_vars)
    #         # @info "Unfolded option $option_args"
    #         # @info "Unfolded indices $option_indices"
    #         # @info "Unfolded vars $option_vars"
    #         if !isempty(option[3]) || !isempty(option[4])
    #             need_reset = false
    #             for (k, v) in option_indices
    #                 if haskey(option[3], k) && option[3][k] != v
    #                     need_reset = true
    #                     break
    #                 end
    #             end
    #             for (k, v) in option_vars
    #                 if haskey(option[4], k) && option[4][k] != v
    #                     need_reset = true
    #                     break
    #                 end
    #             end
    #             if need_reset
    #                 # @info "Need reset"
    #                 new_option = ([], [], option_indices, option_vars)
    #                 # @info new_option
    #                 new_h = hash(new_option)
    #                 if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
    #                     enqueue!(options_queue, new_h)
    #                     options_queue_dict[new_h] = new_option
    #                 end

    #                 continue
    #             end
    #         end
    #         new_option =
    #             (vcat(option[1], [option_args]), vcat(option[2], [calculated_item]), option_indices, option_vars)
    #         # @info new_option

    #         if i == length(value)
    #             if _can_be_output_map_option(new_option, ctx, f.indices, f.var_ids)
    #                 push!(output_options, new_option)
    #                 # @info "Inserted output option $new_option"
    #             end
    #         else
    #             new_h = hash(new_option)
    #             if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
    #                 enqueue!(options_queue, new_h)
    #                 options_queue_dict[new_h] = new_option
    #             end
    #         end
    #     end
    # catch e
    #     if isa(e, InterruptException)
    #         rethrow()
    #     end
    #     # bt = catch_backtrace()
    #     # @error "Got error" exception = (e, bt)
    #     if isempty(options_queue) && isempty(output_options)
    #         rethrow()
    #     else
    #         continue
    #     end
    # end
    # # @info "Output options $output_options"
    # if length(output_options) == 0
    #     error("No output options")
    # else
    #     computed_outputs, calculated_value, filled_indices, filled_vars =
    #         unfold_map_options(output_options, size(value))
    # end

    # # @info "Computed outputs $computed_outputs"
    # # @info "filled_indices $filled_indices"
    # # @info "filled_vars $filled_vars"

    # # @info "Calculated value $calculated_value"

    # return calculated_value,
    # ReverseRunContext(
    #     context.arguments,
    #     vcat(context.predicted_arguments, computed_outputs, [SkipArg()]),
    #     context.calculated_arguments,
    #     filled_indices,
    #     filled_vars,
    # )
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
        last_error = nothing

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
                try
                    calculated_item, new_context = _run_in_reverse(
                        f,
                        item,
                        ReverseRunContext([], [], [calculated_arg_option], copy(option[3]), copy(option[4])),
                    )

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
                                new_option = (
                                    Set(),
                                    Set(),
                                    option_indices,
                                    option_vars,
                                    context.calculated_arguments[end-1],
                                    value,
                                )
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
                                new_option = (
                                    AbductibleValue(any_object),
                                    value,
                                    option_indices,
                                    option_vars,
                                    option[5],
                                    option[6],
                                )
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
                catch e
                    if isa(e, InterruptException)
                        rethrow()
                    end
                    # bt = catch_backtrace()
                    # @error "Got error" exception = (e, bt)
                    last_error = e
                    continue
                end
            end
        end
        # @info "Output options $output_options"
        if length(output_options) == 0
            if !isnothing(last_error)
                throw(last_error)
            end
            error("No output options")
        else
            computed_outputs, calculated_value, filled_indices, filled_vars = unfold_map_set_options(output_options)
        end

        # @info "Computed outputs $computed_outputs"
        # @info "filled_indices $filled_indices"
        # @info "filled_vars $filled_vars"

        # @info "Calculated value $calculated_value"

        return calculated_value,
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
    [(_is_reversible_subfunction, IsPossibleSubfunction())],
    reverse_map
)

@define_custom_reverse_primitive(
    "map2",
    arrow(arrow(t0, t1, t2), tlist(t0), tlist(t1), tlist(t2)),
    (f -> (xs -> (ys -> map(((x, y),) -> _mapper2(f)(x, y), zip(xs, ys))))),
    [(_is_reversible_subfunction, IsPossibleSubfunction())],
    reverse_map
)

@define_custom_reverse_primitive(
    "map_grid",
    arrow(arrow(t0, t1), tgrid(t0), tgrid(t1)),
    (f -> (xs -> map(_mapper(f), xs))),
    [(_is_reversible_subfunction, IsPossibleSubfunction())],
    reverse_map
)

@define_custom_reverse_primitive(
    "map2_grid",
    arrow(arrow(t0, t1, t2), tgrid(t0), tgrid(t1), tgrid(t2)),
    (f -> (xs -> (ys -> map(((x, y),) -> _mapper2(f)(x, y), zip(xs, ys))))),
    [(_is_reversible_subfunction, IsPossibleSubfunction())],
    reverse_map
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
    [(_is_reversible_subfunction, IsPossibleSubfunction())],
    reverse_map_set
)

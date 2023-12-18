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

function rev_fold(f, init, acc)
    outs = []
    while acc != init
        calculated_acc, context =
            _run_in_reverse(f.p, acc, ReverseRunContext([], [], Any[missing, missing], Dict(), Dict()))
        if !isempty(context.filled_indices) || !isempty(context.filled_vars)
            error("Can't have external indices or vars in rev_fold")
        end
        acc, out = context.predicted_arguments
        if out isa EitherOptions
            error("Can't have eithers in rev_fold")
        end
        if out isa AbductibleValue
            error("Can't have abductible values in rev_fold")
        end
        push!(outs, out)
    end
    return reverse(outs)
end

function rev_fold_set(f, init, acc)
    output_options = Set()
    queue = Set([(acc, Set())])
    visited = Set()

    while !isempty(queue)
        acc, outs = pop!(queue)
        calculated_acc, context =
            _run_in_reverse(f.p, acc, ReverseRunContext([], [], Any[missing, missing], Dict(), Dict()))
        if !isempty(context.filled_indices) || !isempty(context.filled_vars)
            error("Can't have external indices or vars in rev_fold")
        end
        new_acc, out = context.predicted_arguments
        if out isa AbductibleValue
            error("Can't have abductible values in rev_fold")
        end
        push!(visited, (acc, outs))
        if out isa EitherOptions
            for (h, val) in out.options
                new_outs = union(outs, [val])
                new_acc_op = new_acc.options[h]
                if new_acc_op == init
                    push!(output_options, new_outs)
                else
                    if (new_acc_op, new_outs) ∉ visited
                        push!(queue, (new_acc_op, new_outs))
                    end
                end
            end
        else
            new_outs = union(outs, [out])
            if new_acc == init
                push!(output_options, new_outs)
            else
                if (new_acc, new_outs) ∉ visited
                    push!(queue, (new_acc, new_outs))
                end
            end
        end
    end
    if length(output_options) != 1
        error("Incorrect number of return options")
    end

    return first(output_options)
end

function reverse_rev_fold()
    function _reverse_rev_fold(value, context)
        f = context.arguments[end]

        init = context.arguments[end-1]

        acc = run_with_arguments(init, [], Dict())
        for val in value
            acc = run_with_arguments(f, [val, acc], Dict())
        end
        return value,
        ReverseRunContext(
            context.arguments,
            vcat(context.predicted_arguments, [acc, SkipArg(), SkipArg()]),
            context.calculated_arguments,
            context.filled_indices,
            context.filled_vars,
        )
    end
    return [
        (_is_reversible_subfunction, CustomArgChecker(true, -1, false, nothing)),
        (_has_no_holes, CustomArgChecker(false, -1, false, nothing)),
    ],
    _reverse_rev_fold
end

@define_custom_reverse_primitive(
    "rev_fold",
    arrow(arrow(t0, t1, t1), t1, t1, tlist(t0)),
    (f -> (init -> (acc -> rev_fold(f, init, acc)))),
    reverse_rev_fold()
)

@define_custom_reverse_primitive(
    "rev_fold_set",
    arrow(arrow(t0, t1, t1), t1, t1, tset(t0)),
    (f -> (init -> (acc -> rev_fold_set(f, init, acc)))),
    reverse_rev_fold()
)

function _can_be_output_option(option, context, external_indices)
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
    if !ismissing(context.calculated_arguments[end-2])
        try
            _unify_values(option[1][2], context.calculated_arguments[end-2], false)
        catch e
            if isa(e, UnifyError)
                return false
            end
            rethrow()
        end
    end
    return true
end

function _insert_output_option(output_options, option, is_set)
    itr, _ = option[1]
    if !isa(itr, AbductibleValue)
        has_abductible = any(isa(v, AbductibleValue) for v in itr)
        has_pattern = any(isa(v, PatternWrapper) for v in itr)
        if !has_abductible && !has_pattern
            push!(output_options, option[1:3])
        else
            new_itr = [isa(v, AbductibleValue) || isa(v, PatternWrapper) ? v.value : v for v in itr]
            if is_set
                new_itr = Set(new_itr)
            end
            if has_abductible
                new_itr = AbductibleValue(new_itr)
            else
                new_itr = PatternWrapper(new_itr)
            end
            push!(output_options, [[new_itr, option[1][2]], option[2], option[3]])
            # @info "Inserted output option $([[new_itr, option[1][2]], option[2], option[3]])"
        end
    else
        push!(output_options, option[1:3])
        # @info "Inserted output option $(option[1:3])"
    end
end

function reverse_fold(is_set = false)
    function _reverse_fold(value, context)
        f = context.arguments[end]

        external_indices = _get_var_indices(f)

        output_options = Set()
        visited = Set()
        options_queue = Queue{UInt64}()
        options_queue_dict = Dict()
        if is_set
            starting_itr = Set()
        else
            starting_itr = []
        end
        if !ismissing(context.calculated_arguments[end-1])
            calc_arg_data = context.calculated_arguments[end-1]
        else
            calc_arg_data = missing
        end
        acc = value

        if !ismissing(context.calculated_arguments[end-2])
            starting_option = (
                [starting_itr, acc],
                context.filled_indices,
                context.filled_vars,
                calc_arg_data,
                context.calculated_arguments[end-2],
            )
            h = hash(starting_option)
            enqueue!(options_queue, h)
            options_queue_dict[h] = starting_option
        end

        starting_option = ([starting_itr, acc], context.filled_indices, context.filled_vars, calc_arg_data, missing)
        h = hash(starting_option)
        enqueue!(options_queue, h)
        options_queue_dict[h] = starting_option

        if _can_be_output_option(starting_option, context, external_indices)
            _insert_output_option(output_options, starting_option, is_set)
        end

        while length(output_options) < 80 && !isempty(options_queue)
            try
                h = dequeue!(options_queue)
                option = options_queue_dict[h]
                delete!(options_queue_dict, h)

                # @info "Option $option"
                push!(visited, h)

                itr, acc = option[1]

                if isa(acc, AbductibleValue)
                    continue
                end

                calculated_arguments = []
                push!(calculated_arguments, option[5])
                if !ismissing(option[4])
                    push!(calculated_arguments, first(option[4]))
                else
                    push!(calculated_arguments, missing)
                end
                calculated_acc, new_context = _run_in_reverse(
                    f,
                    acc,
                    ReverseRunContext([], [], calculated_arguments, copy(option[2]), copy(option[3])),
                )
                # @info "Calculated acc $calculated_acc"
                # @info "New context $new_context"

                for (option_args, option_indices, option_vars) in
                    unfold_options(new_context.predicted_arguments, new_context.filled_indices, new_context.filled_vars)
                    # @info "Original option $option"
                    # @info option_args
                    # @info option_indices
                    # @info option_vars
                    new_acc_op = option_args[1]
                    # if is_set && new_acc_op == acc
                    #     continue
                    # end

                    if !isempty(option[2]) || !isempty(option[3])
                        need_reset = false
                        for (k, v) in option_indices
                            if haskey(option[2], k) && option[2][k] != v
                                need_reset = true
                                break
                            end
                        end
                        for (k, v) in option_vars
                            if haskey(option[3], k) && option[3][k] != v
                                need_reset = true
                                break
                            end
                        end

                        if need_reset
                            # @info "Need reset"
                            if !ismissing(context.calculated_arguments[end-2])
                                new_option = (
                                    [starting_itr, value],
                                    option_indices,
                                    option_vars,
                                    calc_arg_data,
                                    context.calculated_arguments[end-2],
                                )
                                # @info new_option
                                new_h = hash(new_option)
                                if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                                    enqueue!(options_queue, new_h)
                                    options_queue_dict[new_h] = new_option
                                end
                            end
                            new_option = ([starting_itr, value], option_indices, option_vars, calc_arg_data, missing)
                            # @info new_option
                            new_h = hash(new_option)
                            if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                                enqueue!(options_queue, new_h)
                                options_queue_dict[new_h] = new_option
                            end

                            continue
                        end
                    end

                    new_item = option_args[2]

                    if isa(new_acc_op, AbductibleValue)
                        if !ismissing(context.calculated_arguments[end-2])
                            op = [
                                [AbductibleValue(any_object), context.calculated_arguments[end-2]],
                                option_indices,
                                option_vars,
                            ]
                        else
                            op = [[AbductibleValue(any_object), new_acc_op], option_indices, option_vars]
                        end
                        _insert_output_option(output_options, op, is_set)

                        if length(output_options) >= 100
                            break
                        end
                        if !ismissing(context.calculated_arguments[end-2])
                            continue
                        end
                    end

                    if is_set
                        if in(new_item, itr)
                            continue
                        end
                        new_itr = union(itr, [new_item])

                        if !ismissing(option[4])
                            new_calc_arg_data = setdiff(option[4], [calculated_arguments[end-2]])
                        else
                            new_calc_arg_data = missing
                        end
                    else
                        new_itr = vcat(itr, [new_item])
                        if !ismissing(option[4])
                            new_calc_arg_data = view(option[4], 2:length(option[4]))
                        else
                            new_calc_arg_data = missing
                        end
                    end
                    if !ismissing(context.calculated_arguments[end-2]) && ismissing(option[5])
                        new_option = (
                            [new_itr, new_acc_op],
                            option_indices,
                            option_vars,
                            new_calc_arg_data,
                            context.calculated_arguments[end-2],
                        )
                        # @info new_option

                        new_h = hash(new_option)
                        if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                            enqueue!(options_queue, new_h)
                            options_queue_dict[new_h] = new_option
                        end
                    end

                    new_option = ([new_itr, new_acc_op], option_indices, option_vars, new_calc_arg_data, option[5])
                    # @info new_option

                    new_h = hash(new_option)
                    if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                        enqueue!(options_queue, new_h)
                        options_queue_dict[new_h] = new_option
                        if _can_be_output_option(new_option, context, external_indices)
                            _insert_output_option(output_options, new_option, is_set)
                            if length(output_options) >= 100
                                break
                            end
                        end
                    end
                end

            catch e
                if isa(e, InterruptException)
                    rethrow()
                end
                # bt = catch_backtrace()
                # @error "Got error" exception = (e, bt)
                continue
            end
        end
        # @info "Options $output_options"

        if length(output_options) == 0
            error("No valid options found")
        elseif length(output_options) == 1
            result_arguments, result_indices, result_vars = first(output_options)
        else
            hashed_options = Dict(rand(UInt64) => option for option in output_options)
            result_arguments = []
            result_indices = Dict()
            result_vars = Dict()
            for i in 1:2
                push!(result_arguments, EitherOptions(Dict(h => option[1][i] for (h, option) in hashed_options)))
            end
            for (k, v) in first(output_options)[2]
                result_indices[k] = EitherOptions(Dict(h => option[2][k] for (h, option) in hashed_options))
            end
            for (k, v) in first(output_options)[3]
                result_vars[k] = EitherOptions(Dict(h => option[3][k] for (h, option) in hashed_options))
            end
        end
        return value,
        ReverseRunContext(
            context.arguments,
            vcat(context.predicted_arguments, reverse(result_arguments), [SkipArg()]),
            context.calculated_arguments,
            result_indices,
            result_vars,
        )
    end

    return [(_is_reversible_subfunction, CustomArgChecker(nothing, nothing, nothing, _is_possible_subfunction))],
    _reverse_fold
end

@define_custom_reverse_primitive(
    "fold",
    arrow(arrow(t0, t1, t1), tlist(t0), t1, t1),
    (op -> (itr -> (init -> foldr((v, acc) -> op(v)(acc), itr, init = init)))),
    reverse_fold()
)
# @define_custom_reverse_primitive(
#     "fold_set",
#     arrow(arrow(t0, tset(t1), tset(t1)), tset(t0), tset(t1), tset(t1)),
#     (op -> (itr -> (init -> reduce((acc, v) -> op(v)(acc), itr, init = init)))),
#     reverse_fold(true)
# )
@define_custom_reverse_primitive(
    "fold_set",
    arrow(arrow(t0, t1, t1), tset(t0), t1, t1),
    (op -> (itr -> (init -> reduce((acc, v) -> op(v)(acc), itr, init = init)))),
    reverse_fold(true)
)

function _insert_output_option_grid(output_options, option)
    grid, acc = option[1]
    if !isa(grid, AbductibleValue)
        has_abductible = any(isa(v, AbductibleValue) for v in grid)
        has_pattern = any(isa(v, PatternWrapper) for v in grid)
        if !has_abductible && !has_pattern
            new_grid = grid
        else
            new_grid = [isa(v, AbductibleValue) || isa(v, PatternWrapper) ? v.value : v for v in grid]
            new_grid = reshape(new_grid, size(grid))
            if has_abductible
                new_grid = AbductibleValue(new_grid)
            else
                new_grid = PatternWrapper(new_grid)
            end
        end
    else
        new_grid = grid
    end
    if !isa(acc, AbductibleValue)
        has_abductible = any(isa(v, AbductibleValue) for v in acc)
        has_pattern = any(isa(v, PatternWrapper) for v in acc)
        if !has_abductible && !has_pattern
            new_acc = acc
        else
            new_acc = [isa(v, AbductibleValue) || isa(v, PatternWrapper) ? v.value : v for v in acc]
            if has_abductible
                new_acc = AbductibleValue(new_acc)
            else
                new_acc = PatternWrapper(new_acc)
            end
        end
    else
        new_acc = acc
    end
    push!(output_options, [[new_grid, new_acc], option[2], option[3]])
    # @info "Inserted output option $([[new_grid, new_acc], option[2], option[3]])"
end

function reverse_fold_grid(dim)
    function _reverse_fold(value, context)
        f = context.arguments[end]

        external_indices = _get_var_indices(f)

        output_options = Set()
        visited = Set()
        options_queue = Queue{UInt64}()
        options_queue_dict = Dict()

        if dim == 1
            starting_grid = Array{Any}(undef, length(value), 0)
        else
            starting_grid = Array{Any}(undef, 0, length(value))
        end
        acc = value

        if !ismissing(context.calculated_arguments[end-2])
            starting_option =
                ([starting_grid, acc], context.filled_indices, context.filled_vars, context.calculated_arguments[end-2])
            h = hash(starting_option)
            enqueue!(options_queue, h)
            options_queue_dict[h] = starting_option
        end

        starting_option = ([starting_grid, acc], context.filled_indices, context.filled_vars, missing)
        h = hash(starting_option)
        enqueue!(options_queue, h)
        options_queue_dict[h] = starting_option

        if _can_be_output_option(starting_option, context, external_indices)
            _insert_output_option_grid(output_options, starting_option)
        end

        if !ismissing(context.calculated_arguments[end-2])
            max_inner_loop_options = 100
        else
            max_inner_loop_options = 100
        end

        while length(output_options) < 80 && length(options_queue) > 0
            try
                h = dequeue!(options_queue)
                option = options_queue_dict[h]
                delete!(options_queue_dict, h)
                # @info "Option $option"
                push!(visited, h)

                grid, acc = option[1]
                indices = option[2]
                vars = option[3]

                if any(isa(v, AbductibleValue) for v in acc)
                    continue
                end

                new_options = [([[], []], indices, vars)]

                for (i, item) in enumerate(acc)
                    calculated_arguments = []
                    if !ismissing(option[4])
                        push!(calculated_arguments, option[4][i])
                    else
                        push!(calculated_arguments, missing)
                    end
                    if !ismissing(context.calculated_arguments[end-1])
                        if dim == 1
                            push!(calculated_arguments, context.calculated_arguments[end-1][i, size(grid, 2)+1])
                        else
                            push!(calculated_arguments, context.calculated_arguments[end-1][size(grid, 1)+1, i])
                        end
                    else
                        push!(calculated_arguments, missing)
                    end
                    next_options = []
                    for (new_args, new_indices, new_vars) in new_options
                        calculated_acc, new_context = _run_in_reverse(
                            f,
                            item,
                            ReverseRunContext([], [], calculated_arguments, copy(new_indices), copy(new_vars)),
                        )
                        # @info "Calculated acc $calculated_acc"
                        # @info "New context $new_context"

                        for (option_args, option_indices, option_vars) in unfold_options(
                            new_context.predicted_arguments,
                            new_context.filled_indices,
                            new_context.filled_vars,
                        )
                            new_acc_op = option_args[1]
                            if !isempty(new_indices) || !isempty(new_vars)
                                need_reset = false

                                for (k, v) in option_indices
                                    if haskey(new_indices, k) && new_indices[k] != v
                                        need_reset = true
                                        break
                                    end
                                end
                                for (k, v) in option_vars
                                    if haskey(new_vars, k) && new_vars[k] != v
                                        need_reset = true
                                        break
                                    end
                                end
                                if need_reset
                                    # @info "Need reset"
                                    new_option = ([starting_grid, value], option_indices, option_vars, missing)
                                    # @info new_option
                                    new_h = hash(new_option)
                                    if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                                        enqueue!(options_queue, new_h)
                                        options_queue_dict[new_h] = new_option
                                    end

                                    if !ismissing(context.calculated_arguments[end-2])
                                        new_option = (
                                            [starting_grid, value],
                                            option_indices,
                                            option_vars,
                                            context.calculated_arguments[end-2],
                                        )
                                        # @info new_option
                                        new_h = hash(new_option)
                                        if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                                            enqueue!(options_queue, new_h)
                                            options_queue_dict[new_h] = new_option
                                        end
                                    end
                                    continue
                                end
                            end

                            acc_option = vcat(new_args[1], [new_acc_op])
                            line_option = vcat(new_args[2], [option_args[2]])
                            push!(next_options, ([acc_option, line_option], option_indices, option_vars))

                            if length(next_options) > max_inner_loop_options
                                break
                            end
                        end
                        if length(next_options) > max_inner_loop_options
                            break
                        end
                    end
                    # @info "Next options $next_options"

                    new_options = next_options
                end
                for (new_args, new_indices, new_vars) in new_options
                    new_acc, new_line = new_args

                    if any(isa(v, AbductibleValue) for v in new_line) || any(isa(v, AbductibleValue) for v in new_acc)
                        if !ismissing(context.calculated_arguments[end-2])
                            op = [
                                [AbductibleValue(any_object), context.calculated_arguments[end-2]],
                                new_indices,
                                new_vars,
                            ]
                            _insert_output_option_grid(output_options, op)
                        else
                            if any(isa(v, AbductibleValue) for v in new_acc)
                                acc_op = AbductibleValue([isa(v, AbductibleValue) ? v.value : v for v in new_acc])
                            else
                                acc_op = new_acc
                            end
                            op = [[AbductibleValue(any_object), acc_op], new_indices, new_vars]
                            _insert_output_option_grid(output_options, op)
                            op = [
                                [AbductibleValue(any_object), AbductibleValue([any_object for _ in new_acc])],
                                new_indices,
                                new_vars,
                            ]
                            _insert_output_option_grid(output_options, op)
                        end
                        if length(output_options) >= 100
                            break
                        end
                        if !ismissing(context.calculated_arguments[end-2])
                            continue
                        end
                    end

                    if dim == 1
                        new_grid = hcat(grid, new_line)
                    else
                        new_grid = vcat(grid, new_line')
                    end

                    if !ismissing(context.calculated_arguments[end-2]) && ismissing(option[4])
                        new_option = ([new_grid, new_acc], new_indices, new_vars, context.calculated_arguments[end-2])
                        # @info "New option $new_option"

                        new_h = hash(new_option)
                        if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                            enqueue!(options_queue, new_h)
                            options_queue_dict[new_h] = new_option
                        end
                    end

                    new_option = ([new_grid, new_acc], new_indices, new_vars, option[4])
                    # @info "New option $new_option"
                    new_h = hash(new_option)
                    if !haskey(options_queue_dict, new_h) && !in(new_h, visited)
                        enqueue!(options_queue, new_h)
                        options_queue_dict[new_h] = new_option
                        if _can_be_output_option(new_option, context, external_indices)
                            _insert_output_option_grid(output_options, new_option)

                            if length(output_options) >= 100
                                break
                            end
                        end
                    end
                end
            catch e
                if isa(e, InterruptException)
                    rethrow()
                end
                continue
            end
        end
        if length(output_options) == 0
            error("No valid options found")
        elseif length(output_options) == 1
            result_arguments, result_indices, result_vars = first(output_options)
        else
            hashed_options = Dict(rand(UInt64) => option for option in output_options)
            result_arguments = []
            result_indices = Dict()
            result_vars = Dict()
            for i in 1:2
                push!(result_arguments, EitherOptions(Dict(h => option[1][i] for (h, option) in hashed_options)))
            end
            for (k, v) in first(output_options)[2]
                result_indices[k] = EitherOptions(Dict(h => option[2][k] for (h, option) in hashed_options))
            end
            for (k, v) in first(output_options)[3]
                result_vars[k] = EitherOptions(Dict(h => option[3][k] for (h, option) in hashed_options))
            end
        end

        return value,
        ReverseRunContext(
            context.arguments,
            vcat(context.predicted_arguments, reverse(result_arguments), [SkipArg()]),
            context.calculated_arguments,
            result_indices,
            result_vars,
        )
    end

    return [(_is_reversible_subfunction, CustomArgChecker(nothing, nothing, nothing, _is_possible_subfunction))],
    _reverse_fold
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

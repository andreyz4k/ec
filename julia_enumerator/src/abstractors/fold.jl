
function rev_fold(f, init, acc)
    outs = []
    while acc != init
        predicted_arguments, filled_indices, filled_vars = _run_in_reverse(f.p, acc)
        if !isempty(filled_indices) || !isempty(filled_vars)
            error("Can't have external indices or vars in rev_fold")
        end
        acc, out = predicted_arguments
        if out isa EitherOptions
            error("Can't have eithers in rev_fold")
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
        predicted_arguments, filled_indices, filled_vars = _run_in_reverse(f.p, acc)
        if !isempty(filled_indices) || !isempty(filled_vars)
            error("Can't have external indices or vars in rev_fold")
        end
        new_acc, out = predicted_arguments
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

_is_possible_init(p::Primitive, from_input, skeleton, path) = true
_is_possible_init(p::FreeVar, from_input, skeleton, path) = false
_is_possible_init(p::Index, from_input, skeleton, path) = true
_is_possible_init(p::Invented, from_input, skeleton, path) = true

_is_possible_folder(p::Index, from_input, skeleton, path) = true
_is_possible_folder(p::Primitive, from_input, skeleton, path) = haskey(all_abstractors, p)
_is_possible_folder(p::Invented, from_input, skeleton, path) = is_reversible(p)
_is_possible_folder(p::FreeVar, from_input, skeleton, path) = false

function reverse_rev_fold()
    function _reverse_rev_fold(value, arguments)
        f = arguments[end]

        init = arguments[end-1]

        acc = run_with_arguments(init, [], Dict())
        for val in value
            acc = run_with_arguments(f, [val, acc], Dict())
        end
        return [SkipArg(), SkipArg(), acc], Dict(), Dict()
    end
    return [(_has_no_holes, _is_possible_init), (_is_reversible_subfunction, _is_possible_folder)], _reverse_rev_fold
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

function reverse_fold(is_set = false)
    function _reverse_fold(value, arguments)
        f = arguments[end]

        has_external_vars = _has_external_vars(f)

        options = Dict()
        if is_set
            itr = Set()
        else
            itr = []
        end
        acc = value

        h = rand(UInt64)
        options[h] = ([itr, acc], Dict(), Dict())

        options_queue = Set([h])

        while length(options) < 100 && length(options_queue) > 0
            try
                h = pop!(options_queue)
                option = options[h]

                itr, acc = option[1]

                if isempty(option[2]) && isempty(option[3]) && has_external_vars
                    delete!(options, h)
                end

                predicted_arguments, filled_indices, filled_vars = _run_in_reverse(f, acc)

                for (option_args, option_indices, option_vars) in
                    unfold_options(predicted_arguments, filled_indices, filled_vars)
                    new_acc_op = option_args[1]
                    if new_acc_op == acc
                        continue
                    end

                    if !isempty(option_indices)
                        new_option_indices = copy(option[2])
                    else
                        new_option_indices = option[2]
                    end
                    if !isempty(option_vars)
                        new_option_vars = copy(option[3])
                    else
                        new_option_vars = option[3]
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

                    if is_set
                        new_itr = union(itr, [option_args[2]])
                        if new_itr == itr
                            continue
                        end
                    else
                        new_itr = vcat(itr, [option_args[2]])
                    end
                    new_option = ([new_itr, new_acc_op], new_option_indices, new_option_vars)

                    new_h = hash(new_option)
                    if !haskey(options, new_h)
                        options[new_h] = new_option
                        push!(options_queue, new_h)
                    end
                end

            catch e
                if isa(e, InterruptException)
                    rethrow()
                end
                continue
            end
        end

        if length(options) == 0
            error("No valid options found")
        elseif length(options) == 1
            result_arguments, result_indices, result_vars = first(options)[2]
        else
            hashed_options = Dict(rand(UInt64) => option for (h, option) in options)
            result_arguments = []
            result_indices = Dict()
            result_vars = Dict()
            for i in 1:2
                push!(result_arguments, EitherOptions(Dict(h => option[1][i] for (h, option) in hashed_options)))
            end
            for (k, v) in first(options)[2][2]
                result_indices[k] = EitherOptions(Dict(h => option[2][k] for (h, option) in hashed_options))
            end
            for (k, v) in first(options)[2][3]
                result_vars[k] = EitherOptions(Dict(h => option[3][k] for (h, option) in hashed_options))
            end
        end
        return vcat([SkipArg()], result_arguments), result_indices, result_vars
    end

    return [(_is_reversible_subfunction, _is_possible_subfunction)], _reverse_fold
end

@define_custom_reverse_primitive(
    "fold",
    arrow(arrow(t0, t1, t1), tlist(t0), t1, t1),
    (op -> (itr -> (init -> foldr((v, acc) -> op(v)(acc), itr, init = init)))),
    reverse_fold()
)
@define_custom_reverse_primitive(
    "fold_set",
    arrow(arrow(t0, tset(t1), tset(t1)), tset(t0), tset(t1), tset(t1)),
    (op -> (itr -> (init -> reduce((acc, v) -> op(v)(acc), itr, init = init)))),
    reverse_fold(true)
)

function reverse_fold_grid(dim)
    function _reverse_fold(value, arguments)
        f = arguments[end]

        has_external_vars = _has_external_vars(f)

        options = Dict()
        if dim == 1
            grid = Array{Any}(undef, length(value), 0)
        else
            grid = Array{Any}(undef, 0, length(value))
        end
        acc = value

        op = ([grid, acc], Dict(), Dict())
        h = hash(op)
        options[h] = op

        options_queue = Set([h])

        while length(options) < 100 && length(options_queue) > 0
            try
                h = pop!(options_queue)
                option = options[h]

                grid, acc = option[1]
                indices = option[2]
                vars = option[3]

                if isempty(option[2]) && isempty(option[3]) && has_external_vars
                    delete!(options, h)
                end

                new_options = [([[], []], indices, vars)]

                for item in acc
                    predicted_arguments, filled_indices, filled_vars = _run_in_reverse(f, item)

                    next_options = []
                    for (option_args, option_indices, option_vars) in
                        unfold_options(predicted_arguments, filled_indices, filled_vars)
                        new_acc_op = option_args[1]
                        for (new_args, new_indices, new_vars) in new_options
                            if !isempty(option_indices) && isempty(new_indices)
                                new_option_indices = copy(option_indices)
                            else
                                new_option_indices = new_indices
                            end
                            if !isempty(option_vars) && isempty(new_vars)
                                new_option_vars = copy(option_vars)
                            else
                                new_option_vars = new_vars
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

                            acc_option = vcat(new_args[1], [new_acc_op])
                            line_option = vcat(new_args[2], [option_args[2]])
                            push!(next_options, ([acc_option, line_option], new_option_indices, new_option_vars))

                            if length(next_options) > 100
                                break
                            end
                        end
                        if length(next_options) > 100
                            break
                        end
                    end

                    new_options = next_options
                end
                for i in 1:length(new_options)
                    new_args, new_indices, new_vars = new_options[i]
                    new_acc = new_args[1]
                    if new_acc == acc
                        continue
                    end
                    new_line = new_args[2]
                    if dim == 1
                        new_grid = hcat(grid, new_line)
                    else
                        new_grid = vcat(grid, new_line')
                    end

                    op = ([new_grid, new_acc], new_indices, new_vars)
                    new_h = hash(op)
                    if !haskey(options, new_h)
                        options[new_h] = op
                        push!(options_queue, new_h)
                    end
                end
            catch e
                if isa(e, InterruptException)
                    rethrow()
                end
                continue
            end
        end
        if length(options) == 0
            error("No valid options found")
        elseif length(options) == 1
            result_arguments, result_indices, result_vars = first(options)[2]
        else
            hashed_options = Dict(rand(UInt64) => option for (h, option) in options)
            result_arguments = []
            result_indices = Dict()
            result_vars = Dict()
            for i in 1:2
                push!(result_arguments, EitherOptions(Dict(h => option[1][i] for (h, option) in hashed_options)))
            end
            for (k, v) in first(options)[2][2]
                result_indices[k] = EitherOptions(Dict(h => option[2][k] for (h, option) in hashed_options))
            end
            for (k, v) in first(options)[2][3]
                result_vars[k] = EitherOptions(Dict(h => option[3][k] for (h, option) in hashed_options))
            end
        end

        return vcat([SkipArg()], result_arguments), result_indices, result_vars
    end

    return [(_is_reversible_subfunction, _is_possible_subfunction)], _reverse_fold
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

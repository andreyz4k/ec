
function rev_fold(f, init, acc)
    rev_f = _get_reversed_program(f.p.b.b, [])
    outs = []
    while acc != init
        out, acc = rev_f(acc)
        if out isa EitherOptions
            error("Can't have eithers in rev_fold")
        end
        push!(outs, out)
    end
    return reverse(outs)
end

function rev_fold_set(f, init, acc)
    rev_f = _get_reversed_program(f.p.b.b, [])
    output_options = Set()
    queue = Set([(acc, Set())])
    visited = Set()

    while !isempty(queue)
        acc, outs = pop!(queue)
        out, new_acc = rev_f(acc)
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
    function _reverse_fold(arguments)
        f = pop!(arguments)
        rev_f = _get_reversed_program(f.b.b, [])

        indices_mapping, external_vars = _get_var_indices(f.b.b, 2)

        rev_itr = _get_reversed_program(pop!(arguments), arguments)
        rev_init = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_fold(value)::Vector{Any}
            options = Dict()
            if is_set
                itr = Set()
            else
                itr = []
            end
            acc = value

            h = hash([itr, acc])
            options[h] = [itr, acc]

            options_queue = Set([h])

            while length(options) < 100 && length(options_queue) > 0
                try
                    h = pop!(options_queue)
                    option = options[h]
                    if external_vars > 0
                        if length(option) == 2
                            itr, acc = option
                            delete!(options, h)
                            first_call = true
                        else
                            itr = option[end-1]
                            acc = option[end]
                            first_call = false
                        end
                    else
                        itr, acc = option
                        first_call = false
                    end

                    rev_values = rev_f(acc)

                    filled_indices = Dict{Int,Any}()
                    for (i, v) in enumerate(rev_values)
                        mapped_i = indices_mapping[i]
                        if haskey(filled_indices, mapped_i)
                            if filled_indices[mapped_i] != v
                                error("Filling the same index with different values")
                            end
                        else
                            filled_indices[mapped_i] = v
                        end
                    end

                    new_acc = filled_indices[external_vars+2]

                    if isa(new_acc, EitherOptions)
                        for (h_op, new_acc_op) in new_acc.options
                            if new_acc_op == acc
                                continue
                            end

                            if first_call
                                ext_vals = [filled_indices[i].options[h_op] for i in 1:external_vars]
                            else
                                good_option = true
                                for i in 1:external_vars
                                    if filled_indices[i].options[h_op] != option[i]
                                        good_option = false
                                        break
                                    end
                                end
                                if !good_option
                                    continue
                                end
                                ext_vals = option[1:external_vars]
                            end

                            if is_set
                                new_itr = union(itr, [filled_indices[external_vars+1].options[h_op]])
                            else
                                new_itr = vcat(itr, [filled_indices[external_vars+1].options[h_op]])
                            end
                            new_option = vcat(ext_vals, [new_itr, new_acc_op])

                            new_h = hash(new_option)
                            if !haskey(options, new_h)
                                options[new_h] = new_option
                                push!(options_queue, new_h)
                            end
                        end
                    else
                        if new_acc == acc
                            continue
                        end

                        if first_call
                            ext_vals = [filled_indices[i] for i in 1:external_vars]
                        else
                            for i in 1:external_vars
                                if filled_indices[i] != option[i]
                                    error("External value changed")
                                end
                            end
                            ext_vals = option[1:external_vars]
                        end

                        if is_set
                            new_itr = union(itr, [filled_indices[external_vars+1]])
                        else
                            new_itr = vcat(itr, [filled_indices[external_vars+1]])
                        end
                        new_option = vcat(ext_vals, [new_itr, new_acc])

                        new_h = hash(new_option)
                        if !haskey(options, new_h)
                            options[new_h] = new_option
                            push!(options_queue, new_h)
                        end
                    end

                catch
                    continue
                end
            end

            if length(options) == 0
                error("No valid options found")
            elseif length(options) == 1
                result = first(options)[2]
            else
                result = []
                for i in 1:(external_vars+2)
                    push!(result, EitherOptions(Dict(h => option[i] for (h, option) in options)))
                end
            end

            return vcat(result[1:external_vars], rev_itr(result[end-1]), rev_init(result[end]))
        end

        function __reverse_fold(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_fold, value)
        end

        return __reverse_fold
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
    arrow(arrow(t0, t1, t1), tset(t0), t1, t1),
    (op -> (itr -> (init -> foldr((v, acc) -> op(v)(acc), itr, init = init)))),
    reverse_fold(true)
)

function reverse_fold_grid(dim)
    function _reverse_fold(arguments)
        f = pop!(arguments)
        rev_f = _get_reversed_program(f.b.b, [])
        indices_mapping, external_vars = _get_var_indices(f.b.b, 2)

        rev_grid = _get_reversed_program(pop!(arguments), arguments)
        rev_inits = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_fold(value)::Vector{Any}
            options = Dict()
            if dim == 1
                grid = Array{Any}(undef, length(value), 0)
            else
                grid = Array{Any}(undef, 0, length(value))
            end
            acc = value

            h = hash([grid, acc])
            options[h] = [grid, acc]

            options_queue = Set([h])

            while length(options) < 100 && length(options_queue) > 0
                try
                    h = pop!(options_queue)
                    option = options[h]
                    ext_vals = []
                    if external_vars > 0
                        if length(option) == 2
                            grid, acc = option
                            delete!(options, h)
                            first_call = true
                        else
                            grid = option[end-1]
                            acc = option[end]
                            ext_vals = option[1:external_vars]
                            first_call = false
                        end
                    else
                        grid, acc = option
                        first_call = false
                    end

                    new_options = [vcat(ext_vals, [[], []])]

                    for item in acc
                        rev_values = rev_f(item)

                        filled_indices = Dict{Int,Any}()
                        for (i, v) in enumerate(rev_values)
                            mapped_i = indices_mapping[i]
                            if haskey(filled_indices, mapped_i)
                                if filled_indices[mapped_i] != v
                                    error("Filling the same index with different values")
                                end
                            else
                                filled_indices[mapped_i] = v
                            end
                        end

                        new_acc_item = filled_indices[external_vars+2]

                        next_options = []
                        if isa(new_acc_item, EitherOptions)
                            for (h_op, new_acc_op) in new_acc_item.options
                                for new_option in new_options
                                    if first_call
                                        ext_vals = [filled_indices[i].options[h_op] for i in 1:external_vars]
                                    else
                                        good_option = true
                                        for i in 1:external_vars
                                            if filled_indices[i].options[h_op] != new_option[i]
                                                good_option = false
                                                break
                                            end
                                        end
                                        if !good_option
                                            continue
                                        end
                                        ext_vals = new_option[1:external_vars]
                                    end

                                    acc_option = vcat(new_option[end], [new_acc_op])
                                    line_option =
                                        vcat(new_option[end-1], [filled_indices[external_vars+1].options[h_op]])
                                    push!(next_options, vcat(ext_vals, [line_option, acc_option]))

                                    if length(next_options) > 100
                                        break
                                    end
                                end
                                if length(next_options) > 100
                                    break
                                end
                            end
                        else
                            for new_option in new_options
                                if first_call
                                    ext_vals = [filled_indices[i] for i in 1:external_vars]
                                else
                                    good_option = true
                                    for i in 1:external_vars
                                        if filled_indices[i] != new_option[i]
                                            good_option = false
                                            break
                                        end
                                    end
                                    if !good_option
                                        continue
                                    end
                                    ext_vals = new_option[1:external_vars]
                                end
                                line_option = new_option[end-1]
                                acc_option = new_option[end]
                                push!(line_option, filled_indices[external_vars+1])
                                push!(acc_option, new_acc_item)
                                push!(next_options, vcat(ext_vals, [line_option, acc_option]))
                            end
                        end
                        new_options = next_options
                    end
                    for i in 1:length(new_options)
                        new_option = new_options[i]
                        new_acc = new_option[end]
                        if new_acc == acc
                            continue
                        end
                        new_line = new_option[end-1]
                        if dim == 1
                            new_grid = hcat(grid, new_line)
                        else
                            new_grid = vcat(grid, new_line')
                        end

                        op = vcat(new_option[1:external_vars], [new_grid, new_acc])
                        new_h = hash(op)
                        if !haskey(options, new_h)
                            options[new_h] = op
                            push!(options_queue, new_h)
                        end
                    end
                catch
                    continue
                end
            end
            if length(options) == 0
                error("No valid options found")
            elseif length(options) == 1
                result = first(options)[2]
            else
                result = []
                for i in 1:(external_vars+2)
                    push!(result, EitherOptions(Dict(h => option[i] for (h, option) in options)))
                end
            end

            return vcat(result[1:external_vars], rev_grid(result[end-1]), rev_inits(result[end]))
        end

        function __reverse_fold(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_fold, value)
        end

        return __reverse_fold
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

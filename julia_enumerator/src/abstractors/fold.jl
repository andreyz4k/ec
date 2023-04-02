
function rev_fold(f, init, acc)
    rev_f = _get_reversed_program(f.p.b.b, [])
    outs = []
    while acc != init
        out, acc = rev_f(acc)
        push!(outs, out)
    end
    return reverse(outs)
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

function reverse_fold()
    function _reverse_fold(arguments)
        f = pop!(arguments)
        rev_f = _get_reversed_program(f.b.b, [])

        indices_mapping = _get_var_indices(f.b.b)

        rev_itr = _get_reversed_program(pop!(arguments), arguments)
        rev_init = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_fold(value)::Vector{Any}
            options_itr = Dict()
            options_init = Dict()
            itr = []
            acc = value

            h = hash((itr, acc))
            options_itr[h] = itr
            options_init[h] = acc

            options_queue = Set([h])

            while length(options_itr) < 100 && length(options_queue) > 0
                try
                    h = pop!(options_queue)
                    acc = options_init[h]

                    rev_values = rev_f(acc)

                    filled_indices = Dict{Int,Any}()
                    for (i, v) in enumerate(rev_values)
                        mapped_i = 2 - indices_mapping[i]
                        if haskey(filled_indices, mapped_i)
                            if filled_indices[mapped_i] != v
                                error("Filling the same index with different values")
                            end
                        else
                            filled_indices[mapped_i] = v
                        end
                    end

                    new_acc = filled_indices[2]
                    itr = options_itr[h]

                    if isa(new_acc, EitherOptions)
                        for (h_op, new_acc_op) in new_acc.options
                            if new_acc_op == acc
                                continue
                            end
                            new_itr = vcat(itr, [filled_indices[1].options[h_op]])

                            new_h = hash((new_itr, new_acc_op))
                            if !haskey(options_itr, new_h)
                                options_itr[new_h] = new_itr
                                options_init[new_h] = new_acc_op
                                push!(options_queue, new_h)
                            end
                        end
                    else
                        if new_acc == acc
                            continue
                        end
                        new_itr = vcat(itr, [filled_indices[1]])

                        new_h = hash((new_itr, new_acc))
                        if !haskey(options_itr, new_h)
                            options_itr[new_h] = new_itr
                            options_init[new_h] = new_acc
                            push!(options_queue, new_h)
                        end
                    end

                catch
                    continue
                end
            end

            out_itr = if length(options_itr) == 1
                first(options_itr)[2]
            else
                EitherOptions(options_itr)
            end
            out_init = if length(options_init) == 1
                first(options_init)[2]
            else
                EitherOptions(options_init)
            end
            return vcat(rev_itr(out_itr), rev_init(out_init))
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

function reverse_fold_grid(dim)
    function _reverse_fold(arguments)
        f = pop!(arguments)
        rev_f = _get_reversed_program(f.b.b, [])
        indices_mapping = _get_var_indices(f.b.b)

        rev_grid = _get_reversed_program(pop!(arguments), arguments)
        rev_inits = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_fold(value)::Vector{Any}
            options_grid = Dict()
            options_inits = Dict()
            if dim == 1
                grid = Array{Any}(undef, length(value), 0)
            else
                grid = Array{Any}(undef, 0, length(value))
            end
            acc = value

            h = hash((grid, acc))
            options_grid[h] = grid
            options_inits[h] = acc

            options_queue = Set([h])

            while length(options_grid) < 100 && length(options_queue) > 0
                try
                    h = pop!(options_queue)
                    acc = options_inits[h]
                    grid = options_grid[h]

                    new_line_options = [[]]
                    new_acc_options = [[]]
                    for item in acc
                        rev_values = rev_f(item)

                        filled_indices = Dict{Int,Any}()
                        for (i, v) in enumerate(rev_values)
                            mapped_i = 2 - indices_mapping[i]
                            if haskey(filled_indices, mapped_i)
                                if filled_indices[mapped_i] != v
                                    error("Filling the same index with different values")
                                end
                            else
                                filled_indices[mapped_i] = v
                            end
                        end

                        new_acc_item = filled_indices[2]

                        if isa(new_acc_item, EitherOptions)
                            next_acc_options = []
                            next_line_options = []
                            for (h_op, new_acc_op) in new_acc_item.options
                                for i in 1:length(new_acc_options)
                                    acc_option = new_acc_options[i]
                                    line_option = new_line_options[i]
                                    push!(next_acc_options, vcat(acc_option, [new_acc_op]))
                                    push!(next_line_options, vcat(line_option, [filled_indices[1].options[h_op]]))
                                    if length(next_acc_options) > 100
                                        break
                                    end
                                end
                                if length(next_acc_options) > 100
                                    break
                                end
                            end
                            new_acc_options = next_acc_options
                            new_line_options = next_line_options
                        else
                            for line_option in new_line_options
                                push!(line_option, filled_indices[1])
                            end
                            for acc_option in new_acc_options
                                push!(acc_option, new_acc_item)
                            end
                        end
                    end
                    for i in 1:length(new_acc_options)
                        new_acc = new_acc_options[i]
                        if new_acc == acc
                            continue
                        end
                        new_line = new_line_options[i]
                        if dim == 1
                            new_grid = hcat(grid, new_line)
                        else
                            new_grid = vcat(grid, new_line')
                        end
                        new_h = hash((new_grid, new_acc))
                        if !haskey(options_grid, new_h)
                            options_grid[new_h] = new_grid
                            options_inits[new_h] = new_acc
                            push!(options_queue, new_h)
                        end
                    end
                catch
                    continue
                end
            end

            out_grid = if length(options_grid) == 1
                first(options_grid)[2]
            else
                EitherOptions(options_grid)
            end
            out_inits = if length(options_inits) == 1
                first(options_inits)[2]
            else
                EitherOptions(options_inits)
            end
            return vcat(rev_grid(out_grid), rev_inits(out_inits))
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

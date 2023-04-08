
function rev_greedy_cluster(f, item, groups)
    result = Set()
    item_group = Set([item])
    for group in groups
        if f(item)(group)
            union!(item_group, group)
        else
            push!(result, group)
        end
    end
    push!(result, item_group)
    return result
end

_is_possible_key_extractor(p::Primitive, from_input, skeleton, path) = true
_is_possible_key_extractor(p::Invented, from_input, skeleton, path) = true
_is_possible_key_extractor(p::Index, from_input, skeleton, path) = true
_is_possible_key_extractor(p::FreeVar, from_input, skeleton, path) = false

function reverse_rev_greedy_clusterr()
    function _reverse_rev_greedy_cluster(arguments)
        f = pop!(arguments)
        grouper = f([], Dict())

        rev_item = _get_reversed_program(pop!(arguments), arguments)
        rev_groups = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_rev_greedy_cluster(groups)::Vector{Any}
            output_options = []
            for group in groups
                for v in group
                    new_groups = copy(groups)
                    delete!(new_groups, group)

                    rem_groups = Set()
                    for val in group
                        if val != v
                            rem_groups = rev_greedy_cluster(grouper, val, rem_groups)
                        end
                    end

                    union!(new_groups, rem_groups)
                    push!(output_options, (v, new_groups))
                end
            end
            if length(output_options) == 0
                error("Groups are empty")
            elseif length(output_options) == 1
                result = first(output_options)
            else
                hashed_options = Dict(hash(option) => option for option in output_options)
                result = []
                for i in 1:2
                    push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
                end
            end
            return vcat(rev_item(result[1]), rev_groups(result[2]))
        end

        function __reverse_rev_greedy_cluster(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_rev_greedy_cluster, value)
        end

        return __reverse_rev_greedy_cluster
    end
    return [(_has_no_holes, _is_possible_key_extractor)], _reverse_rev_greedy_cluster
end

@define_custom_reverse_primitive(
    "rev_greedy_cluster",
    arrow(arrow(t0, tset(t0), tbool), t0, tset(tset(t0)), tset(tset(t0))),
    (f -> (item -> (grs -> rev_greedy_cluster(f, item, grs)))),
    reverse_rev_greedy_clusterr()
)


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

function reverse_rev_greedy_cluster()
    function _reverse_rev_greedy_cluster(groups, arguments)
        f = arguments[end]
        grouper = f([], Dict())

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
            r = first(output_options)
            result = [SkipArg(), r[1], r[2]]
        else
            hashed_options = Dict(rand(UInt64) => option for option in output_options)
            result = Any[SkipArg()]
            for i in 1:2
                push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
            end
        end
        return result, Dict(), Dict()
    end
    return [(_has_no_holes, _is_possible_key_extractor)], _reverse_rev_greedy_cluster
end

@define_custom_reverse_primitive(
    "rev_greedy_cluster",
    arrow(arrow(t0, tset(t0), tbool), t0, tset(tset(t0)), tset(tset(t0))),
    (f -> (item -> (grs -> rev_greedy_cluster(f, item, grs)))),
    reverse_rev_greedy_cluster()
)

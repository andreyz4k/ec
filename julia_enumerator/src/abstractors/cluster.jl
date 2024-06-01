
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
    function _reverse_rev_greedy_cluster(groups, context)
        f = context.arguments[end]
        grouper = f([], Dict())

        if isempty(groups)
            error("Groups are empty")
        end
        group = first(groups)
        selected_value = first(group)

        new_groups = copy(groups)
        delete!(new_groups, group)

        rem_groups = Set()
        for val in group
            if val != selected_value
                rem_groups = rev_greedy_cluster(grouper, val, rem_groups)
            end
        end

        union!(new_groups, rem_groups)

        return groups,
        ReverseRunContext(
            context.arguments,
            vcat(context.predicted_arguments, [new_groups, selected_value, SkipArg()]),
            context.calculated_arguments,
            context.filled_indices,
            context.filled_vars,
        )
    end
    return [(_has_no_holes, SimpleArgChecker(false, -1, false))], _reverse_rev_greedy_cluster
end

# This function is meant to be used with fold
@define_custom_reverse_primitive(
    "rev_greedy_cluster",
    arrow(arrow(t0, tset(t0), tbool), t0, tset(tset(t0)), tset(tset(t0))),
    (f -> (item -> (grs -> rev_greedy_cluster(f, item, grs)))),
    reverse_rev_greedy_cluster()
)

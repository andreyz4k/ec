
function rev_groupby(f, item, groups)
    key = f(item)
    result = Set()
    matched = false
    for (k, values) in groups
        if k == key
            matched = true
            push!(result, (k, union(values, [item])))
        else
            push!(result, (k, values))
        end
    end
    if !matched
        push!(result, (key, Set([item])))
    end
    return result
end

_is_possible_key_extractor(p::Primitive, from_input, skeleton, path) = true
_is_possible_key_extractor(p::Invented, from_input, skeleton, path) = true
_is_possible_key_extractor(p::Index, from_input, skeleton, path) = true
_is_possible_key_extractor(p::FreeVar, from_input, skeleton, path) = false

function reverse_rev_groupby()
    function _reverse_rev_groupby(arguments)
        f = pop!(arguments)
        rev_item = _get_reversed_program(pop!(arguments), arguments)
        rev_groups = _get_reversed_program(pop!(arguments), arguments)

        function __reverse_rev_groupby(groups)::Vector{Any}
            output_options = []
            for (k, values) in groups
                for v in values
                    new_groups = copy(groups)
                    delete!(new_groups, (k, values))
                    new_values = copy(values)
                    delete!(new_values, v)
                    if !isempty(new_values)
                        push!(new_groups, (k, new_values))
                    end
                    push!(output_options, (v, new_groups))
                end
            end
            if length(output_options) == 0
                error("Groups are empty")
            elseif length(output_options) == 1
                result = first(output_options)
            else
                hashed_options = Dict(rand(UInt64) => option for option in output_options)
                result = []
                for i in 1:2
                    push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
                end
            end
            return vcat(rev_item(result[1]), rev_groups(result[2]))
        end

        function __reverse_rev_groupby(value::EitherOptions)::Vector{Any}
            _reverse_eithers(__reverse_rev_groupby, value)
        end

        function __reverse_rev_groupby(value::PatternWrapper)::Vector{Any}
            _reverse_pattern(__reverse_rev_groupby, value)
        end

        return __reverse_rev_groupby
    end
    return [(_has_no_holes, _is_possible_key_extractor)], _reverse_rev_groupby
end

@define_custom_reverse_primitive(
    "rev_groupby",
    arrow(arrow(t0, t1), t0, tset(ttuple2(t1, tset(t0))), tset(ttuple2(t1, tset(t0)))),
    (f -> (item -> (grs -> rev_groupby(f, item, grs)))),
    reverse_rev_groupby()
)

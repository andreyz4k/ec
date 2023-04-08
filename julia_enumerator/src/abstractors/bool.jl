
@define_reverse_primitive "not" arrow(tbool, tbool) (x -> !x) (x -> [!x])

function reverse_and(value)
    if value
        return [true, true]
    else
        output_options = [[false, true], [true, false], [false, false]]
        hashed_options = Dict(hash(option) => option for option in output_options)
        result = []
        for i in 1:2
            push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
        end
        return result
    end
end

@define_reverse_primitive "and" arrow(tbool, tbool, tbool) (a -> (b -> a && b)) reverse_and

function reverse_or(value)
    if value
        output_options = [[false, true], [true, false], [true, true]]
        hashed_options = Dict(hash(option) => option for option in output_options)
        result = []
        for i in 1:2
            push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
        end
        return result
    else
        return [false, false]
    end
end

@define_reverse_primitive "or" arrow(tbool, tbool, tbool) (a -> (b -> a || b)) reverse_or

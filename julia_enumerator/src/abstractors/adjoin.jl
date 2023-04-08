
function reverse_adjoin(value)::Vector{Any}
    if isempty(value)
        error("Set is empty")
    end
    options = Dict()
    for v in value
        option = [v, setdiff(value, [v])]
        options[hash(option)] = option
    end
    if length(options) == 1
        result = first(options)[2]
    else
        result = []
        for i in 1:2
            push!(result, EitherOptions(Dict(h => option[i] for (h, option) in options)))
        end
    end
    return result
end

@define_reverse_primitive "adjoin" arrow(t0, tset(t0), tset(t0)) (x -> (y -> union(y, [x]))) reverse_adjoin

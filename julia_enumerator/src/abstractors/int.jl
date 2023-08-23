function reverse_abs(value)
    if value == 0
        return [0]
    elseif value < 0
        error("Negative absolute value")
    else
        return [EitherOptions(Dict(rand(UInt64) => value, rand(UInt64) => -value))]
    end
end

@define_reverse_primitive "abs" arrow(tint, tint) abs reverse_abs

function _rev_dep_plus(sum_value::Int64, x::Int64)
    return sum_value - x
end

function reverse_plus(value)
    return [AbductibleValue(any_object, _rev_dep_plus), AbductibleValue(any_object, _rev_dep_plus)]
end

@define_reverse_primitive "+" arrow(tint, tint, tint) (a -> (b -> a + b)) reverse_plus
# @define_primitive "+" arrow(tint, tint, tint) (a -> (b -> a + b))

function reverse_mult(value)
    options = []
    if value > 0
        upper = floor(Int64, sqrt(value))
    else
        upper = floor(Int64, sqrt(-value))
    end
    for i in 1:upper
        if value % i == 0
            push!(options, [i, value ÷ i])
            push!(options, [value ÷ i, i])
        end
    end
    if length(options) == 0
        # @info "No options for rev mult for value $value"
        error("No factors")
    elseif length(options) == 1
        return options[1]
    else
        hashed_options = Dict(rand(UInt64) => option for option in options)
        result = []
        for i in 1:2
            push!(result, EitherOptions(Dict(h => option[i] for (h, option) in hashed_options)))
        end
        return result
    end
end

@define_reverse_primitive "*" arrow(tint, tint, tint) (a -> (b -> a * b)) reverse_mult
# @define_primitive "*" arrow(tint, tint, tint) (a -> (b -> a * b))

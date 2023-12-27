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

function reverse_plus(value, calculated_arguments)
    # @info "Reverse plus"
    # @info value
    # @info calculated_arguments
    if calculated_arguments[end] !== missing && calculated_arguments[end] !== any_object
        if calculated_arguments[end-1] !== missing && calculated_arguments[end-1] !== any_object
            if value - calculated_arguments[end] != calculated_arguments[end-1]
                error("Calculated arguments $(calculated_arguments[end-1:end]) don't add up to value $value")
            else
                return [calculated_arguments[end], calculated_arguments[end-1]]
            end
        else
            return [calculated_arguments[end], value - calculated_arguments[end]]
        end
    elseif calculated_arguments[end-1] !== missing && calculated_arguments[end-1] !== any_object
        return [value - calculated_arguments[end-1], calculated_arguments[end-1]]
    end

    return [AbductibleValue(any_object), AbductibleValue(any_object)]
end

@define_abductible_reverse_primitive "+" arrow(tint, tint, tint) (a -> (b -> a + b)) reverse_plus
# @define_primitive "+" arrow(tint, tint, tint) (a -> (b -> a + b))

function reverse_minus(value, calculated_arguments)
    # @info "Reverse minus"
    # @info value
    # @info calculated_arguments
    if calculated_arguments[end] !== missing && calculated_arguments[end] !== any_object
        if calculated_arguments[end-1] !== missing && calculated_arguments[end-1] !== any_object
            if value != calculated_arguments[end] - calculated_arguments[end-1]
                error("Calculated arguments $(calculated_arguments[end-1:end]) don't add up to value $value")
            else
                return [calculated_arguments[end], calculated_arguments[end-1]]
            end
        else
            return [calculated_arguments[end], calculated_arguments[end] - value]
        end
    elseif calculated_arguments[end-1] !== missing && calculated_arguments[end-1] !== any_object
        return [value + calculated_arguments[end-1], calculated_arguments[end-1]]
    end

    return [AbductibleValue(any_object), AbductibleValue(any_object)]
end

@define_abductible_reverse_primitive "-" arrow(tint, tint, tint) (a -> (b -> a - b)) reverse_minus
# @define_primitive("-", arrow(tint, tint, tint), (a -> (b -> a - b)))

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
            push!(options, [-i, -(value ÷ i)])
            if abs(i) != abs(value ÷ i)
                push!(options, [value ÷ i, i])
                push!(options, [-(value ÷ i), -i])
            end
        end
    end
    if value == 0
        push!(options, [0, PatternWrapper(any_object)])
        push!(options, [PatternWrapper(any_object), 0])
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

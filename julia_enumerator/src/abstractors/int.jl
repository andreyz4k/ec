function reverse_abs(value)
    if value == 0
        return [0]
    elseif value < 0
        error("Negative absolute value")
    else
        return [EitherOptions(Dict(hash(value) => value, hash(-value) => -value))]
    end
end

@define_reverse_primitive "abs" arrow(tint, tint) abs reverse_abs

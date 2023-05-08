
function reverse_range(value)::Vector{Any}
    for (i, v) in enumerate(value)
        if v != i - 1
            error("Invalid value")
        end
    end
    return [length(value)]
end

@define_reverse_primitive "range" arrow(tint, tlist(tint)) (n -> collect(0:n-1)) reverse_range

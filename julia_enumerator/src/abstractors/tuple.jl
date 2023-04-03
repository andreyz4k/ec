function reverse_tuple2(value)::Vector{Any}
    if length(value) != 2
        error("Tuple must have length 2")
    end
    return [value[1], value[2]]
end

@define_reverse_primitive "tuple2" arrow(t0, t1, ttuple2(t0, t1)) (x -> (y -> (x, y))) reverse_tuple2

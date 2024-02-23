function reverse_tuple2(value)::Vector{Any}
    if length(value) != 2
        error("Tuple must have length 2")
    end
    return Any[value[1], value[2]]
end

@define_reverse_primitive "tuple2" arrow(t0, t1, ttuple2(t0, t1)) (x -> (y -> (x, y))) reverse_tuple2

function reverse_tuple2_first(value)
    return [PatternWrapper((value, any_object))]
end

@define_reverse_primitive "tuple2_first" arrow(ttuple2(t0, t1), t0) (t -> t[1]) reverse_tuple2_first

function reverse_tuple2_second(value)
    return [PatternWrapper((any_object, value))]
end

@define_reverse_primitive "tuple2_second" arrow(ttuple2(t0, t1), t1) (t -> t[2]) reverse_tuple2_second

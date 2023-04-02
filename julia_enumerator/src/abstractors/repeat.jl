
function reverse_repeat(value)::Vector{Any}
    template_item = first(v for v in value if v !== any_object)
    if any(v != template_item && v != any_object for v in value)
        error("Elements are not equal")
    end
    return [template_item, length(value)]
end

@define_reverse_primitive "repeat" arrow(t0, tint, tlist(t0)) (x -> (n -> fill(x, n))) reverse_repeat

function reverse_repeat_grid(value)::Vector{Any}
    template_item = first(v for v in value if v !== any_object)
    if any(v != template_item && v != any_object for v in value)
        error("Elements are not equal")
    end
    x, y = size(value)
    return [template_item, x, y]
end

@define_reverse_primitive "repeat_grid" arrow(t0, tint, tint, tgrid(t0)) (x -> (n -> (m -> fill(x, n, m)))) reverse_repeat_grid

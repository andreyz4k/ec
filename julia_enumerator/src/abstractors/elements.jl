
function list_elements(value)
    elements = Set()
    n = length(value)
    for i in 1:n
        val = value[i]
        if val !== nothing
            push!(elements, (i, val))
        end
    end
    return [elements, n]
end

function collect_elements(elements, len)
    output = Array{Any}(nothing, len)
    for (i, el) in elements
        output[i] = el
    end
    return output
end

function grid_elements(value)
    elements = Set()
    n, m = size(value)
    for i in 1:n
        for j in 1:m
            val = value[i, j]
            if val !== nothing
                push!(elements, ((i, j), val))
            end
        end
    end
    return [elements, n, m]
end

function collect_grid_elements(elements, len1, len2)
    output = Array{Any}(nothing, len1, len2)
    for ((i, j), el) in elements
        output[i, j] = el
    end
    return output
end

@define_reverse_primitive(
    "rev_list_elements",
    arrow(tset(ttuple2(tint, t0)), tint, tlist(t0)),
    (elements -> (len -> collect_elements(elements, len))),
    list_elements
)
@define_reverse_primitive(
    "rev_grid_elements",
    arrow(tset(ttuple2(ttuple2(tint, tint), t0)), tint, tint, tgrid(t0)),
    (elements -> (height -> (width -> collect_grid_elements(elements, height, width)))),
    grid_elements
)

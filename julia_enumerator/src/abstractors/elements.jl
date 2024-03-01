
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
    if nothing in elements
        error("Can't have nothing in elements set")
    end
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
    if nothing in elements
        error("Can't have nothing in elements set")
    end
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

function reverse_collect(value)
    result = Set(value)
    if length(result) != length(value)
        error("Duplicate elements")
    end
    return [result]
end

@define_reverse_primitive("collect", arrow(tset(t0), tlist(t0)), collect, reverse_collect)

function reverse_empty(value)
    if isempty(value)
        return []
    else
        error("Expected empty object")
    end
end

@define_reverse_primitive("empty", tlist(t0), [], reverse_empty)
@define_reverse_primitive("empty_set", tset(t0), Set(), reverse_empty)

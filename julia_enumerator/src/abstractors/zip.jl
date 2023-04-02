
function reverse_zip2(values)
    values1 = Array{Any}(undef, size(values))
    values2 = Array{Any}(undef, size(values))
    for i in eachindex(values)
        values1[i] = values[i][1]
        values2[i] = values[i][2]
    end
    return [values1, values2]
end

function zip2(values1, values2)
    values = Array{Any}(undef, size(values1))
    for i in eachindex(values)
        values[i] = (values1[i], values2[i])
    end
    return values
end

@define_reverse_primitive(
    "zip2",
    arrow(tlist(t0), tlist(t1), tlist(ttuple2(t0, t1))),
    (a -> (b -> zip2(a, b))),
    reverse_zip2
)
@define_reverse_primitive(
    "zip_grid2",
    arrow(tgrid(t0), tgrid(t1), tgrid(ttuple2(t0, t1))),
    (a -> (b -> zip2(a, b))),
    reverse_zip2
)

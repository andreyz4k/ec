
function reverse_rows_to_grid(value)::Vector{Any}
    [[value[i, :] for i in (1:size(value, 1))]]
end

@define_reverse_primitive(
    "rows_to_grid",
    arrow(tlist(tlist(t0)), tgrid(t0)),
    (rs -> vcat([permutedims(r) for r in rs]...)),
    reverse_rows_to_grid
)

function reverse_columns_to_grid(value)::Vector{Any}
    [[value[:, i] for i in (1:size(value, 2))]]
end

@define_reverse_primitive(
    "columns_to_grid",
    arrow(tlist(tlist(t0)), tgrid(t0)),
    (cs -> hcat(cs...)),
    reverse_columns_to_grid
)

function reverse_rows(value)::Vector{Any}
    [vcat([permutedims(r) for r in value]...)]
end

function reverse_columns(value)::Vector{Any}
    [hcat(value...)]
end

@define_reverse_primitive(
    "rows",
    arrow(tgrid(t0), tlist(tlist(t0))),
    (g -> [g[i, :] for i in (1:size(g, 1))]),
    reverse_rows
)

@define_reverse_primitive(
    "columns",
    arrow(tgrid(t0), tlist(tlist(t0))),
    (g -> [g[:, i] for i in (1:size(g, 2))]),
    reverse_columns
)

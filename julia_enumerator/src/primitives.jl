
function _unfold(is_end, ext_item, next_state, state)
    acc = []
    while !is_end(state)
        push!(acc, ext_item(state))
        state = next_state(state)
    end
    acc
end

_is_prime(n) = in(
    n,
    Set([
        2,
        3,
        5,
        7,
        11,
        13,
        17,
        19,
        23,
        29,
        31,
        37,
        41,
        43,
        47,
        53,
        59,
        61,
        67,
        71,
        73,
        79,
        83,
        89,
        97,
        101,
        103,
        107,
        109,
        113,
        127,
        131,
        137,
        139,
        149,
        151,
        157,
        163,
        167,
        173,
        179,
        181,
        191,
        193,
        197,
        199,
    ]),
)

@define_primitive(
    "unfold",
    arrow(arrow(t0, tbool), arrow(t0, t1), arrow(t0, t0), t0, tlist(t1)),
    (is_end -> (ext_item -> (next_state -> (state -> _unfold(is_end, ext_item, next_state, state))))),
)
@define_primitive("index", arrow(tint, tlist(t0), t0), (j -> (l -> l[j])))
@define_primitive("index2", arrow(tint, tint, tgrid(t0), t0), (i -> (j -> (l -> l[i, j]))))
@define_primitive("tuple2_first", arrow(ttuple2(t0, t1), t0), (t -> t[1]))
@define_primitive("tuple2_second", arrow(ttuple2(t0, t1), t1), (t -> t[2]))
@define_primitive("length", arrow(tlist(t0), tint), length)
@define_primitive("height", arrow(tgrid(t0), tint), (g -> size(g, 1)))
@define_primitive("width", arrow(tgrid(t0), tint), (g -> size(g, 2)))

# built-ins
@define_primitive("if", arrow(tbool, t0, t0, t0), (c -> (t -> (f -> c ? t : f))))
@define_primitive("+", arrow(tint, tint, tint), (a -> (b -> a + b)))
@define_primitive("-", arrow(tint, tint, tint), (a -> (b -> a - b)))
@define_primitive("empty", tlist(t0), [])
@define_primitive("car", arrow(tlist(t0), t0), (l -> l[1]))
@define_primitive("cdr", arrow(tlist(t0), tlist(t0)), (l -> isempty(l) ? error("Empty list") : l[2:end]))
@define_primitive("empty?", arrow(tlist(t0), tbool), isempty)

[@define_primitive(string(j), tint, j) for j in 0:1]

@define_primitive("*", arrow(tint, tint, tint), (a -> (b -> a * b)))
@define_primitive("mod", arrow(tint, tint, tint), (a -> (b -> a % b)))
@define_primitive("gt?", arrow(tint, tint, tbool), (a -> (b -> a > b)))
@define_primitive("eq?", arrow(t0, t0, tbool), (a -> (b -> a == b)))
@define_primitive("is-prime", arrow(tint, tbool), _is_prime)
@define_primitive("is-square", arrow(tint, tbool), (n -> floor(sqrt(n))^2 == n))

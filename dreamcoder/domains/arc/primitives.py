from functools import reduce
import math
from dreamcoder.program import Primitive
from dreamcoder.type import arrow, baseType, tlist, t0, t1, tint, tbool


tcolor = baseType("color")


def _map(f):
    return lambda l: list(map(f, l))


def _fold(l):
    return lambda x0: lambda f: reduce(lambda a, x: f(x)(a), l[::-1], x0)


def _range(n):
    if n < 100:
        return list(range(n))
    raise ValueError()


def _if(c):
    return lambda t: lambda f: t if c else f


def _addition(x):
    return lambda y: x + y


def _subtraction(x):
    return lambda y: x - y


def _multiplication(x):
    return lambda y: x * y


def _cons(x):
    return lambda y: [x] + y


def _car(x):
    return x[0]


def _cdr(x):
    return x[1:]


def _isEmpty(x):
    return x == []


def _eq(x):
    return lambda y: x == y


def _gt(x):
    return lambda y: x > y


def _index(j):
    return lambda l: l[j]


def _mod(x):
    return lambda y: x % y


def _isPrime(n):
    return n in {
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
    }


def _isSquare(n):
    return int(math.sqrt(n)) ** 2 == n


def _unfold(x):
    return lambda p: lambda h: lambda n: __unfold(p, h, n, x)


class RecursionDepthExceeded(Exception):
    pass


def __unfold(p, f, n, x, recursion_limit=50):
    if recursion_limit <= 0:
        raise RecursionDepthExceeded()
    if p(x):
        return []
    return [f(x)] + __unfold(p, f, n, n(x), recursion_limit - 1)


def _repeat(x):
    return lambda n: [x] * n


def _concat(a):
    return lambda b: a + b


def basePrimitives():
    """These are the primitives that we hope to learn from the bootstrapping procedure"""
    return [
        Primitive("map", arrow(arrow(t0, t1), tlist(t0), tlist(t1)), _map, is_reversible=True),
        Primitive("unfold", arrow(t0, arrow(t0, tbool), arrow(t0, t1), arrow(t0, t0), tlist(t1)), _unfold),
        Primitive("range", arrow(tint, tlist(tint)), _range, is_reversible=True),
        Primitive("index", arrow(tint, tlist(t0), t0), _index),
        Primitive("fold", arrow(tlist(t0), t1, arrow(t0, t1, t1), t1), _fold),
        Primitive("length", arrow(tlist(t0), tint), len),
        Primitive("if", arrow(tbool, t0, t0, t0), _if),
        Primitive("+", arrow(tint, tint, tint), _addition),
        Primitive("-", arrow(tint, tint, tint), _subtraction),
        Primitive("empty", tlist(t0), []),
        Primitive("cons", arrow(t0, tlist(t0), tlist(t0)), _cons, is_reversible=True),
        Primitive("car", arrow(tlist(t0), t0), _car),
        Primitive("cdr", arrow(tlist(t0), tlist(t0)), _cdr),
        Primitive("empty?", arrow(tlist(t0), tbool), _isEmpty),
        Primitive("*", arrow(tint, tint, tint), _multiplication),
        Primitive("mod", arrow(tint, tint, tint), _mod),
        Primitive("gt?", arrow(tint, tint, tbool), _gt),
        Primitive("eq?", arrow(t0, t0, tbool), _eq),
        Primitive("is-prime", arrow(tint, tbool), _isPrime),
        Primitive("is-square", arrow(tint, tbool), _isSquare),
        Primitive("repeat", arrow(t0, tint, tlist(t0)), _repeat, is_reversible=True),
        Primitive("concat", arrow(tlist(t0), tlist(t0), tlist(t0)), _concat, is_reversible=True),
    ] + [Primitive(str(j), tint, j) for j in range(2)]
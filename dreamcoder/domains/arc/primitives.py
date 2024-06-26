from functools import reduce
import math
import sys
from dreamcoder.program import (
    Application,
    ArgChecker,
    Hole,
    Primitive,
    Invented,
    Index,
    FreeVariable,
    Abstraction,
    SimpleArgChecker,
)
from dreamcoder.type import (
    TypeConstructor,
    arrow,
    baseType,
    tlist,
    t0,
    t1,
    t2,
    tint,
    tbool,
)


tcolor = baseType("color")
tcoord = baseType("coord")


def tgrid(t):
    return TypeConstructor("grid", [t])


def ttuple2(t1, t2):
    return TypeConstructor("tuple2", [t1, t2])


def ttuple3(t1, t2, t3):
    return TypeConstructor("tuple3", [t1, t2, t3])


def tset(t):
    return TypeConstructor("set", [t])


def _map(f):
    return lambda l: list(map(f, l))


def _map_grid(f):
    return lambda g: [list(map(f, l)) for l in g]


def _fold(f):
    return lambda l: lambda x0: reduce(lambda a, x: f(x)(a), l[::-1], x0)


def _fold_h(f):
    return lambda g: lambda xs0: [
        reduce(lambda a, x: f(x)(a), l[::-1], x0) for (l, x0) in zip(g, xs0)
    ]


def _fold_v(f):
    return lambda g: lambda xs0: [
        reduce(lambda a, x: f(x)(a), l[::-1], x0) for (l, x0) in zip(zip(*g), xs0)
    ]


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


def _index2(i):
    return lambda j: lambda l: l[i][j]


def _width(g):
    return len(g[0])


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


def _unfold(p):
    return lambda h: lambda n: lambda x: __unfold(p, h, n, x)


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


def _rows_to_grid(rs):
    return rs


def _rows(rs):
    return rs


def _columns_to_grid(cs):
    return [list(l) for l in zip(*cs)]


def _columns(cs):
    return [list(l) for l in zip(*cs)]


def _not(x):
    return not x


def _and(x):
    return lambda y: x and y


def _or(x):
    return lambda y: x or y


def _any(f):
    return lambda l: any(f(x) for x in l)


def _all(f):
    return lambda l: all(f(x) for x in l)


def __is_reversible_selector(p, is_top_index):
    if isinstance(p, Primitive) or isinstance(p, Invented):
        return 2
    if isinstance(p, Index):
        if is_top_index:
            return 0
        if p.i == 0:
            return 1
        return 2
    if isinstance(p, Application):
        if is_top_index:
            if isinstance(p.x, Hole):
                if isinstance(p.f, Application) and p.f.f == Primitive.GLOBALS["eq?"]:
                    return __is_reversible_selector(p.f.x, False)
                return 0
            else:
                return min(
                    __is_reversible_selector(p.f, False),
                    __is_reversible_selector(p.x, False),
                )
        else:
            if isinstance(p.x, Hole):
                return 0
            return min(
                __is_reversible_selector(p.f, False),
                __is_reversible_selector(p.x, False),
            )
    if isinstance(p, Abstraction):
        return __is_reversible_selector(p.body, True) == 1
    return 0


def _is_reversible_selector(p):
    if isinstance(p, Abstraction):
        return __is_reversible_selector(p.body, True) == 1
    return False


def _has_no_holes(p):
    if isinstance(p, Hole):
        return False
    if isinstance(p, Application):
        return _has_no_holes(p.f) and _has_no_holes(p.x)
    if isinstance(p, Abstraction):
        return _has_no_holes(p.body)
    return True


def _is_reversible_subfunction(p):
    return p.is_reversible and _has_no_holes(p)


def _is_fixable_param(p):
    return True
    return isinstance(p, Index) or isinstance(p, FreeVariable)


class IsPossibleReversibleSubfunction(ArgChecker):
    def __init__(self):
        super().__init__(None, None, None)

    def __eq__(self, value) -> bool:
        return isinstance(value, IsPossibleReversibleSubfunction)

    def __repr__(self) -> str:
        return "IsPossibleReversibleSubfunction()"

    def __call__(self, p):
        return True

    def step_arg_checker(self, arg):
        if isinstance(arg, Index):
            return None
        return self


class IsPossibleFixableParam(ArgChecker):
    def __init__(self):
        super().__init__(None, None, None)

    def __eq__(self, value) -> bool:
        return isinstance(value, IsPossibleFixableParam)

    def __repr__(self) -> str:
        return "IsPossibleFixableParam()"

    def __call__(self, p):
        # TODO: this is not a real algorithm, just a placeholder
        if isinstance(p, Index) or isinstance(p, FreeVariable):
            return True
        return False

    def step_arg_checker(self, arg):
        return None


class IsPossibleSubfunction(ArgChecker):
    def __init__(self):
        super().__init__(None, None, None)

    def __eq__(self, value) -> bool:
        return isinstance(value, IsPossibleSubfunction)

    def __repr__(self) -> str:
        return "IsPossibleSubfunction()"

    def __call__(self, p):
        if isinstance(p, Index) and p.i == 0:
            return False
        return True

    def step_arg_checker(self, arg):
        if isinstance(arg, Abstraction):
            return self
        return None


class IsPossibleSelector(ArgChecker):
    def __init__(self, max_index, can_have_free_vars, step_to_eq):
        super().__init__(False, max_index, can_have_free_vars)
        self.step_to_eq = step_to_eq

    def __eq__(self, value) -> bool:
        return (
            isinstance(value, IsPossibleSelector)
            and self.step_to_eq == value.step_to_eq
            and super().__eq__(value)
        )

    def __repr__(self) -> str:
        return f"IsPossibleSelector({self.max_index}, {self.can_have_free_vars}, {self.step_to_eq})"

    def __hash__(self) -> int:
        return super().__hash__() + hash(self.step_to_eq)

    def __call__(self, p):
        if isinstance(p, Index):
            return self.step_to_eq > 1
        return True

    def step_arg_checker(self, arg):
        if isinstance(arg, Abstraction):
            return IsPossibleSelector(
                self.max_index + 1 if self.max_index is not None else 0,
                False,
                1 if self.step_to_eq == 0 else 3,
            )
        if isinstance(arg, Index):
            return None
        if self.step_to_eq == 1 and arg == (Primitive.GLOBALS["eq?"], 1):
            return IsPossibleSelector(None, None, 2)
        if self.can_have_free_vars is None:
            return IsPossibleSelector(0, False, 3)
        return IsPossibleSelector(self.max_index, False, 3)


def basePrimitives():
    return [
        Primitive(
            "rev_fix_param",
            arrow(t0, t1, arrow(t0, t1), t0),
            None,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleReversibleSubfunction()),
                (_is_fixable_param, IsPossibleFixableParam()),
                (_has_no_holes, SimpleArgChecker(False, -1, False)),
            ],
        ),
        Primitive(
            "map",
            arrow(arrow(t0, t1), tlist(t0), tlist(t1)),
            _map,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive(
            "map_set",
            arrow(arrow(t0, t1), tset(t0), tset(t1)),
            _map,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive(
            "map_grid",
            arrow(arrow(t0, t1), tgrid(t0), tgrid(t1)),
            _map_grid,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive(
            "map2",
            arrow(arrow(t0, t1, t2), tlist(t0), tlist(t1), tlist(t2)),
            _map,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive(
            "map2_grid",
            arrow(arrow(t0, t1, t2), tgrid(t0), tgrid(t1), tgrid(t2)),
            _map_grid,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive(
            "unfold",
            arrow(arrow(t0, tbool), arrow(t0, t1), arrow(t0, t0), t0, tlist(t1)),
            _unfold,
        ),
        Primitive("range", arrow(tint, tlist(tint)), _range, is_reversible=True),
        Primitive("index", arrow(tint, tlist(t0), t0), _index),
        Primitive("index2", arrow(tint, tint, tgrid(t0), t0), _index2),
        Primitive(
            "fold",
            arrow(arrow(t0, t1, t1), tlist(t0), t1, t1),
            _fold,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive(
            "fold_set",
            arrow(arrow(t0, t1, t1), tset(t0), t1, t1),
            _fold,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive(
            "fold_h",
            arrow(arrow(t0, t1, t1), tgrid(t0), tlist(t1), tlist(t1)),
            _fold_h,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive(
            "fold_v",
            arrow(arrow(t0, t1, t1), tgrid(t0), tlist(t1), tlist(t1)),
            _fold_v,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, IsPossibleSubfunction())
            ],
        ),
        Primitive("length", arrow(tlist(t0), tint), len),
        Primitive("height", arrow(tgrid(t0), tint), len),
        Primitive("width", arrow(tgrid(t0), tint), _width),
        Primitive("if", arrow(tbool, t0, t0, t0), _if),
        Primitive("+", arrow(tint, tint, tint), _addition, is_reversible=True),
        Primitive("-", arrow(tint, tint, tint), _subtraction, is_reversible=True),
        Primitive("empty", tlist(t0), [], is_reversible=True),
        Primitive("cons", arrow(t0, tlist(t0), tlist(t0)), _cons, is_reversible=True),
        Primitive("car", arrow(tlist(t0), t0), _car),
        Primitive("cdr", arrow(tlist(t0), tlist(t0)), _cdr),
        Primitive("empty?", arrow(tlist(t0), tbool), _isEmpty),
        Primitive("*", arrow(tint, tint, tint), _multiplication, is_reversible=True),
        Primitive("mod", arrow(tint, tint, tint), _mod),
        Primitive("gt?", arrow(tint, tint, tbool), _gt),
        Primitive("eq?", arrow(t0, t0, tbool), _eq),
        Primitive("is-prime", arrow(tint, tbool), _isPrime),
        Primitive("is-square", arrow(tint, tbool), _isSquare),
        Primitive("repeat", arrow(t0, tint, tlist(t0)), _repeat, is_reversible=True),
        Primitive(
            "repeat_grid", arrow(t0, tint, tint, tgrid(t0)), None, is_reversible=True
        ),
        Primitive(
            "concat",
            arrow(tlist(t0), tlist(t0), tlist(t0)),
            _concat,
            is_reversible=True,
        ),
        Primitive(
            "rows", arrow(tgrid(t0), tlist(tlist(t0))), _rows, is_reversible=True
        ),
        Primitive(
            "columns", arrow(tgrid(t0), tlist(tlist(t0))), _columns, is_reversible=True
        ),
        Primitive(
            "rows_to_grid",
            arrow(tlist(tlist(t0)), tgrid(t0)),
            _rows_to_grid,
            is_reversible=True,
        ),
        Primitive(
            "columns_to_grid",
            arrow(tlist(tlist(t0)), tgrid(t0)),
            _columns_to_grid,
            is_reversible=True,
        ),
        Primitive(
            "rev_select",
            arrow(arrow(t0, tbool), tlist(t0), tlist(t0), tlist(t0)),
            None,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_selector, IsPossibleSelector(-1, False, 0))
            ],
        ),
        Primitive(
            "rev_select_set",
            arrow(arrow(t0, tbool), tset(t0), tset(t0), tset(t0)),
            None,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_selector, IsPossibleSelector(-1, False, 0))
            ],
        ),
        Primitive(
            "rev_select_grid",
            arrow(arrow(t0, tbool), tgrid(t0), tgrid(t0), tgrid(t0)),
            None,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_selector, IsPossibleSelector(-1, False, 0))
            ],
        ),
        Primitive(
            "rev_list_elements",
            arrow(tset(ttuple2(tint, t0)), tint, tlist(t0)),
            None,
            is_reversible=True,
        ),
        Primitive(
            "rev_grid_elements",
            arrow(tset(ttuple2(ttuple2(tint, tint), t0)), tint, tint, tgrid(t0)),
            None,
            is_reversible=True,
        ),
        Primitive(
            "zip2",
            arrow(tlist(t0), tlist(t1), tlist(ttuple2(t0, t1))),
            None,
            is_reversible=True,
        ),
        Primitive(
            "zip_grid2",
            arrow(tgrid(t0), tgrid(t1), tgrid(ttuple2(t0, t1))),
            None,
            is_reversible=True,
        ),
        Primitive("tuple2", arrow(t0, t1, ttuple2(t0, t1)), None, is_reversible=True),
        Primitive("tuple2_first", arrow(ttuple2(t0, t1), t0), None, is_reversible=True),
        Primitive(
            "tuple2_second", arrow(ttuple2(t0, t1), t1), None, is_reversible=True
        ),
        Primitive("reverse", arrow(tlist(t0), tlist(t0)), None, is_reversible=True),
        Primitive(
            "rev_fold",
            arrow(arrow(t0, t1, t1), t1, t1, tlist(t0)),
            None,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, SimpleArgChecker(True, -1, False)),
                (_has_no_holes, SimpleArgChecker(False, -1, False)),
            ],
        ),
        Primitive(
            "rev_fold_set",
            arrow(arrow(t0, t1, t1), t1, t1, tset(t0)),
            None,
            is_reversible=True,
            custom_args_checkers=[
                (_is_reversible_subfunction, SimpleArgChecker(True, -1, False)),
                (_has_no_holes, SimpleArgChecker(False, -1, False)),
            ],
        ),
        Primitive("list_to_set", arrow(tlist(t0), tset(t0)), None),
        Primitive("adjoin", arrow(t0, tset(t0), tset(t0)), None, is_reversible=True),
        Primitive("empty_set", tset(t0), None, is_reversible=True),
        Primitive(
            "rev_groupby",
            arrow(
                arrow(t0, t1),
                t0,
                tset(ttuple2(t1, tset(t0))),
                tset(ttuple2(t1, tset(t0))),
            ),
            None,
            is_reversible=True,
            custom_args_checkers=[(_has_no_holes, SimpleArgChecker(False, -1, False))],
        ),
        Primitive(
            "rev_greedy_cluster",
            arrow(arrow(t0, tset(t0), tbool), t0, tset(tset(t0)), tset(tset(t0))),
            None,
            is_reversible=True,
            custom_args_checkers=[(_has_no_holes, SimpleArgChecker(False, -1, False))],
        ),
        Primitive("not", arrow(tbool, tbool), _not, is_reversible=True),
        Primitive("and", arrow(tbool, tbool, tbool), _and, is_reversible=True),
        Primitive("or", arrow(tbool, tbool, tbool), _or, is_reversible=True),
        Primitive("all", arrow(arrow(t0, tbool), tlist(t0), tbool), _all),
        Primitive("any", arrow(arrow(t0, tbool), tlist(t0), tbool), _any),
        Primitive("all_set", arrow(arrow(t0, tbool), tset(t0), tbool), _all),
        Primitive("any_set", arrow(arrow(t0, tbool), tset(t0), tbool), _any),
        Primitive("abs", arrow(tint, tint), abs, is_reversible=True),
        Primitive("max_int", tint, sys.maxsize),
        Primitive("min_int", tint, -sys.maxsize - 1),
        Primitive("collect", arrow(tset(t0), tlist(t0)), list, is_reversible=True),
    ] + [Primitive(str(j), tint, j, is_reversible=True) for j in range(2)]

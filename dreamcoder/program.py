# -*- coding: utf-8 -*-

from dreamcoder.type import *
from dreamcoder.utilities import *

from time import time
import math


class InferenceFailure(Exception):
    pass


class ShiftFailure(Exception):
    pass


class RunFailure(Exception):
    pass


class Program(object):
    def __repr__(self):
        return str(self)

    def __ne__(self, o):
        return not (self == o)

    def __str__(self):
        return self.show(False)

    def canHaveType(self, t):
        try:
            context, actualType = self.inferType(Context.EMPTY, [], {})
            context, t = t.instantiate(context)
            context.unify(t, actualType)
            return True
        except UnificationFailure as e:
            return False

    def betaNormalForm(self):
        n = self
        while True:
            np = n.betaReduce()
            if np is None:
                return n
            n = np

    def infer(self):
        try:
            return self.inferType(Context.EMPTY, [], {})[1].canonical()
        except UnificationFailure as e:
            raise InferenceFailure(self, e)

    def uncurry(self):
        t = self.infer()
        a = len(t.functionArguments())
        e = self
        existingAbstractions = 0
        while e.isAbstraction:
            e = e.body
            existingAbstractions += 1
        newAbstractions = a - existingAbstractions
        assert newAbstractions >= 0

        # e is the body stripped of abstractions. we are going to pile
        # some more lambdas at the front, so free variables in e
        # (which were bound to the stripped abstractions) need to be
        # shifted by the number of abstractions that we will be adding
        e = e.shift(newAbstractions)

        for n in reversed(range(newAbstractions)):
            e = Application(e, Index(n))
        for _ in range(a):
            e = Abstraction(e)

        assert (
            self.infer() == e.infer()
        ), "FATAL: uncurry has a bug. %s : %s, but uncurried to %s : %s" % (
            self,
            self.infer(),
            e,
            e.infer(),
        )
        return e

    def wellTyped(self):
        try:
            self.infer()
            return True
        except InferenceFailure:
            return False

    def runWithArguments(self, xs):
        f = self.evaluate([])
        for x in xs:
            f = f(x)
        return f

    def applicationParses(self):
        yield self, []

    def applicationParse(self):
        return self, []

    @property
    def closed(self):
        for surroundingAbstractions, child in self.walk():
            if isinstance(child, FragmentVariable):
                return False
            if isinstance(child, Index) and child.free(surroundingAbstractions):
                return False
        return True

    @property
    def numberOfFreeVariables(expression):
        n = 0
        for surroundingAbstractions, child in expression.walk():
            # Free variable
            if isinstance(child, Index) and child.free(surroundingAbstractions):
                n = max(n, child.i - surroundingAbstractions + 1)
        return n

    def freeVariables(self):
        for surroundingAbstractions, child in self.walk():
            if child.isIndex and child.i >= surroundingAbstractions:
                yield child.i - surroundingAbstractions

    @property
    def is_reversible(self):
        return self._is_reversible({}, []) is not None

    def _is_reversible(self, environment, args):
        return None

    def fill_args(self, environment):
        return self

    @property
    def isIndex(self):
        return False

    @property
    def isUnion(self):
        return False

    @property
    def isApplication(self):
        return False

    @property
    def isAbstraction(self):
        return False

    @property
    def isPrimitive(self):
        return False

    @property
    def isInvented(self):
        return False

    @property
    def isHole(self):
        return False

    @property
    def isFreeVariable(self):
        return False

    @property
    def isLetClause(self):
        return False

    @property
    def isLetRevClause(self):
        return False

    @property
    def isWrapEither(self):
        return False

    @property
    def isConst(self):
        return False

    @staticmethod
    def parse(s):
        s = parseSExpression(s)

        # eprint(s)
        def p(e):
            if isinstance(e, list):
                if e[0] == "#":
                    assert len(e) == 2
                    return Invented(p(e[1]))
                if e[0] == "lambda":
                    assert len(e) == 2
                    return Abstraction(p(e[1]))
                if e[0] == "let":
                    if e[-3][0] == "rev":
                        return LetRevClause(
                            [v[1:] for v in e[1:-4]],
                            e[-3][1][1:],
                            p(e[-3][3]),
                            p(e[-1]),
                        )
                    elif e[-3][0] == "wrap":
                        return WrapEither(
                            [v[1:] for v in e[1:-4]],
                            e[-3][1][-3][1][1:],
                            e[-3][1][-1][1][1:],
                            p(e[-3][1][-3][-1]),
                            p(e[-3][1][-1][-1]),
                            p(e[-1]),
                        )
                    else:
                        return LetClause(
                            e[1][0][1:], Type.fromstring(e[1][1]), p(e[3]), p(e[5])
                        )
                if e[0] == "Const":
                    return Constant(Type.fromstring(e[1]), e[2])
                f = p(e[0])
                for x in e[1:]:
                    f = Application(f, p(x))
                return f
            assert isinstance(e, str)
            if e[0] == "$":
                try:
                    return Index(int(e[1:]))
                except ValueError:
                    return FreeVariable(e[1:])
            if e == "FREE_VAR":
                return FreeVariable(None)
            if e in Primitive.GLOBALS:
                return Primitive.GLOBALS[e]
            if e == "??" or e == "?":
                return FragmentVariable.single
            if e == "<HOLE>":
                return Hole.single
            raise ParseFailure((s, e))

        return p(s)

    @staticmethod
    def _parse(s, n):
        while n < len(s) and s[n].isspace():
            n += 1
        for p in [
            Application,
            Abstraction,
            Index,
            Invented,
            FragmentVariable,
            Hole,
            Primitive,
        ]:
            try:
                return p._parse(s, n)
            except ParseFailure:
                continue
        raise ParseFailure(s)

    # parser helpers
    @staticmethod
    def parseConstant(s, n, *constants):
        for constant in constants:
            try:
                for i, c in enumerate(constant):
                    if i + n >= len(s) or s[i + n] != c:
                        raise ParseFailure(s)
                return n + len(constant)
            except ParseFailure:
                continue
        raise ParseFailure(s)

    @staticmethod
    def parseHumanReadable(s):
        s = parseSExpression(s)

        def p(s, environment):
            if isinstance(s, list) and s[0] in ["lambda", "\\"]:
                assert isinstance(s[1], list) and len(s) == 3
                newEnvironment = list(reversed(s[1])) + environment
                e = p(s[2], newEnvironment)
                for _ in s[1]:
                    e = Abstraction(e)
                return e
            if isinstance(s, list):
                a = p(s[0], environment)
                for x in s[1:]:
                    a = Application(a, p(x, environment))
                return a
            for j, v in enumerate(environment):
                if s == v:
                    return Index(j)
            if s in Primitive.GLOBALS:
                return Primitive.GLOBALS[s]
            assert False, f"could not parse {s}"

        return p(s, [])


class Application(Program):
    """Function application"""

    def __init__(self, f, x):
        self.f = f
        self.x = x
        self.hashCode = None
        self.isConditional = (
            (not isinstance(f, int))
            and f.isApplication
            and f.f.isApplication
            and f.f.f.isPrimitive
            and f.f.f.name == "if"
        )
        if self.isConditional:
            self.falseBranch = x
            self.trueBranch = f.x
            self.branch = f.f.x
        else:
            self.falseBranch = None
            self.trueBranch = None
            self.branch = None

    def fill_args(self, environment):
        return Application(self.f.fill_args(environment), self.x.fill_args(environment))

    def _is_reversible(self, environment, args):
        checkers = self.f._is_reversible(environment, args + [self.x])
        if checkers is None:
            return None
        filled_x = self.x.fill_args(environment)
        if not checkers:
            if isinstance(filled_x, Hole):
                if filled_x.t.isArrow():
                    return checkers
                return None
            elif isinstance(filled_x, Index) or isinstance(filled_x, FreeVariable):
                return checkers
            checker = None
        else:
            checker = checkers[0]

        if checker is None:
            res = filled_x.is_reversible
        else:
            res = checker(filled_x)
        if res:
            return checkers[1:]
        return None

    def _get_custom_arg_checkers(self, checker, indices_checkers):
        checkers, indices_checkers = self.f._get_custom_arg_checkers(
            checker, indices_checkers
        )
        if checkers:
            _, indices_checkers = self.x._get_custom_arg_checkers(
                checkers[0], indices_checkers
            )
        else:
            _, indices_checkers = self.x._get_custom_arg_checkers(
                None, indices_checkers
            )
        return checkers[1:], indices_checkers

    def betaReduce(self):
        # See if either the function or the argument can be reduced
        f = self.f.betaReduce()
        if f is not None:
            return Application(f, self.x)
        x = self.x.betaReduce()
        if x is not None:
            return Application(self.f, x)

        # Neither of them could be reduced. Is this not a redex?
        if not self.f.isAbstraction:
            return None

        # Perform substitution
        b = self.f.body
        v = self.x
        return b.substitute(Index(0), v.shift(1)).shift(-1)

    def isBetaLong(self):
        return (
            (not self.f.isAbstraction) and self.f.isBetaLong() and self.x.isBetaLong()
        )

    def freeVariables(self):
        return self.f.freeVariables() | self.x.freeVariables()

    def clone(self):
        return Application(self.f.clone(), self.x.clone())

    def annotateTypes(self, context, environment):
        self.f.annotateTypes(context, environment)
        self.x.annotateTypes(context, environment)
        r = context.makeVariable()
        context.unify(arrow(self.x.annotatedType, r), self.f.annotatedType)
        self.annotatedType = r.applyMutable(context)

    @property
    def isApplication(self):
        return True

    def __eq__(self, other):
        return (
            isinstance(other, Application) and self.f == other.f and self.x == other.x
        )

    def __hash__(self):
        if self.hashCode is None:
            self.hashCode = hash((hash(self.f), hash(self.x)))
        return self.hashCode

    """Because Python3 randomizes the hash function, we need to never pickle the hash"""

    def __getstate__(self):
        return (
            self.f,
            self.x,
            self.isConditional,
            self.falseBranch,
            self.trueBranch,
            self.branch,
        )

    def __setstate__(self, state):
        try:
            (
                self.f,
                self.x,
                self.isConditional,
                self.falseBranch,
                self.trueBranch,
                self.branch,
            ) = state
        except ValueError:
            # backward compatibility
            assert "x" in state
            assert "f" in state
            f = state["f"]
            x = state["x"]
            self.f = f
            self.x = x
            self.isConditional = (
                (not isinstance(f, int))
                and f.isApplication
                and f.f.isApplication
                and f.f.f.isPrimitive
                and f.f.f.name == "if"
            )
            if self.isConditional:
                self.falseBranch = x
                self.trueBranch = f.x
                self.branch = f.f.x
            else:
                self.falseBranch = None
                self.trueBranch = None
                self.branch = None

        self.hashCode = None

    def visit(self, visitor, *arguments, **keywords):
        return visitor.application(self, *arguments, **keywords)

    def show(self, isFunction):
        if isFunction:
            return "%s %s" % (self.f.show(True), self.x.show(False))
        else:
            return "(%s %s)" % (self.f.show(True), self.x.show(False))

    def evaluate(self, environment):
        if self.isConditional:
            if self.branch.evaluate(environment):
                return self.trueBranch.evaluate(environment)
            else:
                return self.falseBranch.evaluate(environment)
        else:
            return self.f.evaluate(environment)(self.x.evaluate(environment))

    def inferType(self, context, environment, freeVariables):
        (context, ft) = self.f.inferType(context, environment, freeVariables)
        (context, xt) = self.x.inferType(context, environment, freeVariables)
        (context, returnType) = context.makeVariable()
        context = context.unify(ft, arrow(xt, returnType))
        return (context, returnType.apply(context))

    def applicationParses(self):
        yield self, []
        for f, xs in self.f.applicationParses():
            yield f, xs + [self.x]

    def applicationParse(self):
        f, xs = self.f.applicationParse()
        return f, xs + [self.x]

    def shift(self, offset, depth=0):
        return Application(self.f.shift(offset, depth), self.x.shift(offset, depth))

    def substitute(self, old, new):
        if self == old:
            return new
        return Application(self.f.substitute(old, new), self.x.substitute(old, new))

    def walkUncurried(self, d=0):
        yield d, self
        f, xs = self.applicationParse()
        yield from f.walkUncurried(d)
        for x in xs:
            yield from x.walkUncurried(d)

    def walk(self, surroundingAbstractions=0):
        yield surroundingAbstractions, self
        yield from self.f.walk(surroundingAbstractions)
        yield from self.x.walk(surroundingAbstractions)

    def size(self):
        return self.f.size() + self.x.size()

    @staticmethod
    def _parse(s, n):
        while n < len(s) and s[n].isspace():
            n += 1
        if n == len(s) or s[n] != "(":
            raise ParseFailure(s)
        n += 1

        xs = []
        while True:
            x, n = Program._parse(s, n)
            xs.append(x)
            while n < len(s) and s[n].isspace():
                n += 1
            if n == len(s):
                raise ParseFailure(s)
            if s[n] == ")":
                n += 1
                break
        e = xs[0]
        for x in xs[1:]:
            e = Application(e, x)
        return e, n


class Index(Program):
    """
    deBruijn index: https://en.wikipedia.org/wiki/De_Bruijn_index
    These indices encode variables.
    """

    def __init__(self, i):
        self.i = i

    def show(self, isFunction):
        return "$%d" % self.i

    def __eq__(self, o):
        return isinstance(o, Index) and o.i == self.i

    def __hash__(self):
        return self.i

    def _get_custom_arg_checkers(self, checker, indices_checkers):
        if checker is None:
            return [], indices_checkers
        if self.i in indices_checkers:
            if checker == indices_checkers[self.i]:
                return [], indices_checkers
            combined = lambda p, from_input, path: checker(
                p, from_input, path
            ) and indices_checkers[self.i](p, from_input, path)
            indices_checkers[self.i] = combined
            return [], indices_checkers
        indices_checkers[self.i] = checker
        return [], indices_checkers

    def fill_args(self, environment):
        if self.i in environment:
            return environment[self.i]
        return self

    def visit(self, visitor, *arguments, **keywords):
        return visitor.index(self, *arguments, **keywords)

    def evaluate(self, environment):
        return environment[self.i]

    def inferType(self, context, environment, freeVariables):
        if self.bound(len(environment)):
            return (context, environment[self.i].apply(context))
        else:
            i = self.i - len(environment)
            if i in freeVariables:
                return (context, freeVariables[i].apply(context))
            context, variable = context.makeVariable()
            freeVariables[i] = variable
            return (context, variable)

    def clone(self):
        return Index(self.i)

    def annotateTypes(self, context, environment):
        self.annotatedType = environment[self.i].applyMutable(context)

    def shift(self, offset, depth=0):
        # bound variable
        if self.bound(depth):
            return self
        else:  # free variable
            i = self.i + offset
            if i < 0:
                raise ShiftFailure()
            return Index(i)

    def betaReduce(self):
        return None

    def isBetaLong(self):
        return True

    def freeVariables(self):
        return {self.i}

    def substitute(self, old, new):
        if old == self:
            return new
        else:
            return self

    def walk(self, surroundingAbstractions=0):
        yield surroundingAbstractions, self

    def walkUncurried(self, d=0):
        yield d, self

    def size(self):
        return 1

    def free(self, surroundingAbstractions):
        """Is this index a free variable, given that it has surroundingAbstractions lambda's around it?"""
        return self.i >= surroundingAbstractions

    def bound(self, surroundingAbstractions):
        """Is this index a bound variable, given that it has surroundingAbstractions lambda's around it?"""
        return self.i < surroundingAbstractions

    @property
    def isIndex(self):
        return True

    @staticmethod
    def _parse(s, n):
        while n < len(s) and s[n].isspace():
            n += 1
        if n == len(s) or s[n] != "$":
            raise ParseFailure(s)
        n += 1
        j = ""
        while n < len(s) and s[n].isdigit():
            j += s[n]
            n += 1
        if j == "":
            raise ParseFailure(s)
        return Index(int(j)), n


class Abstraction(Program):
    """Lambda abstraction. Creates a new function."""

    def __init__(self, body):
        self.body = body
        self.hashCode = None

    def _is_reversible(self, environment, args):
        environment = {i + 1: c for (i, c) in environment.items()}
        if args:
            environment[0] = args[-1]
        return self.body._is_reversible(environment, args[:-1])

    def fill_args(self, environment):
        return Abstraction(
            self.body.fill_args({i + 1: c for (i, c) in environment.items()})
        )

    def _get_custom_arg_checkers(self, checker, indices_checkers):
        checkers, indices_checkers = self.body._get_custom_arg_checkers(
            checker, {i + 1: c for (i, c) in indices_checkers.items()}
        )
        if 0 in indices_checkers:
            out_checkers = [indices_checkers[0]] + checkers
        elif checkers:
            out_checkers = [None] + checkers
        else:
            out_checkers = []
        return out_checkers, {i - 1: c for (i, c) in indices_checkers.items() if i > 0}

    @property
    def isAbstraction(self):
        return True

    def __eq__(self, o):
        return isinstance(o, Abstraction) and o.body == self.body

    def __hash__(self):
        if self.hashCode is None:
            self.hashCode = hash((hash(self.body),))
        return self.hashCode

        """Because Python3 randomizes the hash function, we need to never pickle the hash"""

    def __getstate__(self):
        return self.body

    def __setstate__(self, state):
        self.body = state
        self.hashCode = None

    def isBetaLong(self):
        return self.body.isBetaLong()

    def freeVariables(self):
        return {f - 1 for f in self.body.freeVariables() if f > 0}

    def visit(self, visitor, *arguments, **keywords):
        return visitor.abstraction(self, *arguments, **keywords)

    def clone(self):
        return Abstraction(self.body.clone())

    def annotateTypes(self, context, environment):
        v = context.makeVariable()
        self.body.annotateTypes(context, [v] + environment)
        self.annotatedType = arrow(v.applyMutable(context), self.body.annotatedType)

    def show(self, isFunction):
        return "(lambda %s)" % (self.body.show(False))

    def evaluate(self, environment):
        return lambda x: self.body.evaluate([x] + environment)

    def betaReduce(self):
        b = self.body.betaReduce()
        if b is None:
            return None
        return Abstraction(b)

    def inferType(self, context, environment, freeVariables):
        (context, argumentType) = context.makeVariable()
        (context, returnType) = self.body.inferType(
            context, [argumentType] + environment, freeVariables
        )
        return (context, arrow(argumentType, returnType).apply(context))

    def shift(self, offset, depth=0):
        return Abstraction(self.body.shift(offset, depth + 1))

    def substitute(self, old, new):
        if self == old:
            return new
        old = old.shift(1)
        new = new.shift(1)
        return Abstraction(self.body.substitute(old, new))

    def walk(self, surroundingAbstractions=0):
        yield surroundingAbstractions, self
        yield from self.body.walk(surroundingAbstractions + 1)

    def walkUncurried(self, d=0):
        yield d, self
        yield from self.body.walkUncurried(d + 1)

    def size(self):
        return self.body.size()

    @staticmethod
    def _parse(s, n):
        n = Program.parseConstant(s, n, "(\\", "(lambda", "(\u03bb")

        while n < len(s) and s[n].isspace():
            n += 1

        b, n = Program._parse(s, n)
        while n < len(s) and s[n].isspace():
            n += 1
        n = Program.parseConstant(s, n, ")")
        return Abstraction(b), n


class Primitive(Program):
    GLOBALS = {}

    def __init__(self, name, ty, value, is_reversible=False, custom_args_checkers=None):
        self.tp = ty
        self.name = name
        self.value = value
        self.isreversible = is_reversible
        self.custom_args_checkers = custom_args_checkers or []
        if name not in Primitive.GLOBALS:
            Primitive.GLOBALS[name] = self

    def get_custom_arg_checkers(self):
        return [c[1] for c in self.custom_args_checkers]

    def _get_custom_arg_checkers(self, checker, indices_checkers):
        if checker is None:
            return self.custom_args_checkers, indices_checkers
        arg_count = len(self.tp.functionArguments())
        if self.isreversible:
            custom_checkers = self.custom_args_checkers
            out_checkers = []
            for c in custom_checkers:
                if c[1] == checker:
                    out_checkers.append(c[1])
                else:
                    combined = lambda p, from_input, path: checker(
                        p, from_input, path
                    ) and c[1](p, from_input, path)
                    out_checkers.append(combined)
            for _ in range(arg_count - len(custom_checkers)):
                out_checkers.append(checker)
            return out_checkers, indices_checkers
        return [checker] * arg_count, indices_checkers

    def _is_reversible(self, environment, args):
        if self.isreversible:
            return [c[0] for c in self.custom_args_checkers]
        return None

    @property
    def isPrimitive(self):
        return True

    def __eq__(self, o):
        return isinstance(o, Primitive) and o.name == self.name

    def __hash__(self):
        return hash(self.name)

    def visit(self, visitor, *arguments, **keywords):
        return visitor.primitive(self, *arguments, **keywords)

    def show(self, isFunction):
        return self.name

    def clone(self):
        return Primitive(self.name, self.tp, self.value)

    def annotateTypes(self, context, environment):
        self.annotatedType = self.tp.instantiateMutable(context)

    def evaluate(self, environment):
        return self.value

    def betaReduce(self):
        return None

    def isBetaLong(self):
        return True

    def freeVariables(self):
        return set()

    def inferType(self, context, environment, freeVariables):
        return self.tp.instantiate(context)

    def shift(self, offset, depth=0):
        return self

    def substitute(self, old, new):
        if self == old:
            return new
        else:
            return self

    def walk(self, surroundingAbstractions=0):
        yield surroundingAbstractions, self

    def walkUncurried(self, d=0):
        yield d, self

    def size(self):
        return 1

    @staticmethod
    def _parse(s, n):
        while n < len(s) and s[n].isspace():
            n += 1
        name = []
        while n < len(s) and not s[n].isspace() and s[n] not in "()":
            name.append(s[n])
            n += 1
        name = "".join(name)
        if name in Primitive.GLOBALS:
            return Primitive.GLOBALS[name], n
        raise ParseFailure(s)

    # TODO(@mtensor): needs to be fixed to handle both pickling lambda functions and unpickling in general.
    # def __getstate__(self):
    #     return self.name

    # def __setstate__(self, state):
    #     #for backwards compatibility:
    #     if type(state) == dict:
    #         self.__dict__ = state
    #     else:
    #         p = Primitive.GLOBALS[state]
    #         self.__init__(p.name, p.tp, p.value)


class Invented(Program):
    """New invented primitives"""

    def __init__(self, body):
        self.body = body
        self.tp = self.body.infer()
        self.hashCode = None

    def _is_reversible(self, environment, args):
        return self.body._is_reversible(environment, args)

    def fill_args(self, environment):
        return self.body.fill_args(environment)

    def get_custom_arg_checkers(self):
        return self._get_custom_arg_checkers(None, {})[0]

    def _get_custom_arg_checkers(self, checker, indices_checkers):
        return self.body._get_custom_arg_checkers(checker, indices_checkers)

    @property
    def isInvented(self):
        return True

    def show(self, isFunction):
        return "#%s" % (self.body.show(False))

    def visit(self, visitor, *arguments, **keywords):
        return visitor.invented(self, *arguments, **keywords)

    def __eq__(self, o):
        return isinstance(o, Invented) and o.body == self.body

    def __hash__(self):
        if self.hashCode is None:
            self.hashCode = hash((0, hash(self.body)))
        return self.hashCode

    """Because Python3 randomizes the hash function, we need to never pickle the hash"""

    def __getstate__(self):
        return self.body, self.tp

    def __setstate__(self, state):
        self.body, self.tp = state
        self.hashCode = None

    def clone(self):
        return Invented(self.body)

    def annotateTypes(self, context, environment):
        self.annotatedType = self.tp.instantiateMutable(context)

    def evaluate(self, e):
        return self.body.evaluate([])

    def betaReduce(self):
        return self.body

    def isBetaLong(self):
        return True

    def freeVariables(self):
        return set()

    def inferType(self, context, environment, freeVariables):
        return self.tp.instantiate(context)

    def shift(self, offset, depth=0):
        return self

    def substitute(self, old, new):
        if self == old:
            return new
        else:
            return self

    def walk(self, surroundingAbstractions=0):
        yield surroundingAbstractions, self

    def walkUncurried(self, d=0):
        yield d, self

    def size(self):
        return 1

    @staticmethod
    def _parse(s, n):
        while n < len(s) and s[n].isspace():
            n += 1
        if n < len(s) and s[n] == "#":
            n += 1
            b, n = Program._parse(s, n)
            return Invented(b), n

        raise ParseFailure(s)


class FragmentVariable(Program):
    def __init__(self):
        pass

    def show(self, isFunction):
        return "??"

    def __eq__(self, o):
        return isinstance(o, FragmentVariable)

    def __hash__(self):
        return 42

    def visit(self, visitor, *arguments, **keywords):
        return visitor.fragmentVariable(self, *arguments, **keywords)

    def evaluate(self, e):
        raise Exception("Attempt to evaluate fragment variable")

    def betaReduce(self):
        raise Exception("Attempt to beta reduce fragment variable")

    def inferType(self, context, environment, freeVariables):
        return context.makeVariable()

    def shift(self, offset, depth=0):
        raise Exception("Attempt to shift fragment variable")

    def substitute(self, old, new):
        if self == old:
            return new
        else:
            return self

    def match(self, context, expression, holes, variableBindings, environment=[]):
        surroundingAbstractions = len(environment)
        try:
            context, variable = context.makeVariable()
            holes.append((variable, expression.shift(-surroundingAbstractions)))
            return context, variable
        except ShiftFailure:
            raise MatchFailure()

    def walk(self, surroundingAbstractions=0):
        yield surroundingAbstractions, self

    def walkUncurried(self, d=0):
        yield d, self

    def size(self):
        return 1

    @staticmethod
    def _parse(s, n):
        while n < len(s) and s[n].isspace():
            n += 1
        n = Program.parseConstant(s, n, "??", "?")
        return FragmentVariable.single, n


FragmentVariable.single = FragmentVariable()


class Hole(Program):
    def __init__(self):
        pass

    def show(self, isFunction):
        return "<HOLE>"

    @property
    def isHole(self):
        return True

    def __eq__(self, o):
        return isinstance(o, Hole)

    def __hash__(self):
        return 42

    def evaluate(self, e):
        raise Exception("Attempt to evaluate hole")

    def betaReduce(self):
        raise Exception("Attempt to beta reduce hole")

    def inferType(self, context, environment, freeVariables):
        return context.makeVariable()

    def shift(self, offset, depth=0):
        raise Exception("Attempt to shift fragment variable")

    def walk(self, surroundingAbstractions=0):
        yield surroundingAbstractions, self

    def walkUncurried(self, d=0):
        yield d, self

    def size(self):
        return 1

    @staticmethod
    def _parse(s, n):
        while n < len(s) and s[n].isspace():
            n += 1
        n = Program.parseConstant(s, n, "<HOLE>")
        return Hole.single, n


Hole.single = Hole()


class LetClause(Program):
    def __init__(self, var_name, var_type, var_def, body):
        self.var_name = var_name
        self.var_type = var_type
        self.var_def = var_def
        self.body = body
        self.hashCode = None

    def show(self, isFunction):
        return "let $%s::%s = %s in %s" % (
            self.var_name,
            self.var_type.show(False),
            self.var_def.show(False),
            self.body.show(False),
        )

    def __eq__(self, __o) -> bool:
        return (
            isinstance(__o, LetClause)
            and self.var_name == __o.var_name
            and self.var_type == __o.var_type
            and self.var_def == __o.var_def
            and self.body == __o.body
        )

    def __hash__(self):
        if self.hashCode is None:
            self.hashCode = hash(
                (
                    hash(self.var_name),
                    hash(self.var_type),
                    hash(self.var_def),
                    hash(self.body),
                )
            )
        return self.hashCode

    """Because Python3 randomizes the hash function, we need to never pickle the hash"""

    def __getstate__(self):
        return self.var_name, self.var_type, self.var_def, self.body

    def __setstate__(self, state):
        self.var_name, self.var_type, self.var_def, self.body = state
        self.hashCode = None

    @property
    def isLetClause(self):
        return True


class LetRevClause(Program):
    def __init__(self, var_names, inp_var_name, vars_def, body):
        self.var_names = var_names
        self.inp_var_name = inp_var_name
        self.vars_def = vars_def
        self.body = body
        self.hashCode = None

    def show(self, isFunction):
        return "let %s = rev($%s = %s) in %s" % (
            ", ".join(f"${v}" for v in self.var_names),
            self.inp_var_name,
            self.vars_def.show(False),
            self.body.show(False),
        )

    def __eq__(self, __o) -> bool:
        return (
            isinstance(__o, LetRevClause)
            and self.var_names == __o.var_names
            and self.inp_var_name == __o.inp_var_name
            and self.vars_def == __o.vars_def
            and self.body == __o.body
        )

    def __hash__(self):
        if self.hashCode is None:
            self.hashCode = hash(
                (
                    hash(tuple(self.var_names)),
                    hash(self.inp_var_name),
                    hash(self.vars_def),
                    hash(self.body),
                )
            )
        return self.hashCode

    """Because Python3 randomizes the hash function, we need to never pickle the hash"""

    def __getstate__(self):
        return self.var_names, self.inp_var_name, self.vars_def, self.body

    def __setstate__(self, state):
        self.var_names, self.inp_var_name, self.vars_def, self.body = state
        self.hashCode = None

    @property
    def isLetRevClause(self):
        return True


class WrapEither(Program):
    def __init__(
        self, var_names, inp_var_name, fixer_var_name, vars_def, fixer_var, body
    ):
        self.var_names = var_names
        self.inp_var_name = inp_var_name
        self.fixer_var_name = fixer_var_name
        self.vars_def = vars_def
        self.fixer_var = fixer_var
        self.body = body
        self.hashCode = None

    def show(self, isFunction):
        vars_list = ", ".join(f"${v}" for v in self.var_names)
        return (
            f"let {vars_list} = wrap(let {vars_list} = rev(${self.inp_var_name} = {self.vars_def.show(False)});"
            + f" let ${self.fixer_var_name} = {self.fixer_var.show(False)}) in {self.body.show(False)}"
        )

    def __eq__(self, __o) -> bool:
        return (
            isinstance(__o, WrapEither)
            and self.var_names == __o.var_names
            and self.inp_var_name == __o.inp_var_name
            and self.fixer_var_name == __o.fixer_var_name
            and self.vars_def == __o.vars_def
            and self.fixer_var == __o.fixer_var
            and self.body == __o.body
        )

    def __hash__(self):
        if self.hashCode is None:
            self.hashCode = hash(
                (
                    hash(tuple(self.var_names)),
                    hash(self.inp_var_name),
                    hash(self.fixer_var_name),
                    hash(self.vars_def),
                    hash(self.fixer_var),
                    hash(self.body),
                )
            )
        return self.hashCode

    """Because Python3 randomizes the hash function, we need to never pickle the hash"""

    def __getstate__(self):
        return (
            self.var_names,
            self.inp_var_name,
            self.fixer_var_name,
            self.vars_def,
            self.fixer_var,
            self.body,
        )

    def __setstate__(self, state):
        (
            self.var_names,
            self.inp_var_name,
            self.fixer_var_name,
            self.vars_def,
            self.fixer_var,
            self.body,
        ) = state
        self.hashCode = None

    @property
    def isWrapEither(self):
        return True


class FreeVariable(Program):
    def __init__(self, name):
        self.name = name

    def show(self, isFunction):
        if self.name is not None:
            return "$" + self.name
        else:
            return "FREE_VAR"

    def __eq__(self, __o) -> bool:
        return isinstance(__o, FreeVariable) and self.name == __o.name

    def __hash__(self) -> int:
        return hash(self.name)

    @property
    def isFreeVariable(self):
        return True


class Constant(Program):
    def __init__(self, tp, value):
        self.tp = tp
        self.value = value
        self.hashCode = None

    def show(self, isFunction):
        return f"Const({self.tp.show(False)}, {self.value})"

    def __eq__(self, __o) -> bool:
        return (
            isinstance(__o, Constant) and self.tp == __o.tp and self.value == __o.value
        )

    def __hash__(self):
        if self.hashCode is None:
            self.hashCode = hash(self.value)

        return self.hashCode

    """Because Python3 randomizes the hash function, we need to never pickle the hash"""

    def __getstate__(self):
        return self.tp, self.value

    def __setstate__(self, state):
        self.tp, self.value = state
        self.hashCode = None

    @property
    def isConst(self):
        return True


class ShareVisitor(object):
    def __init__(self):
        self.primitiveTable = {}
        self.inventedTable = {}
        self.indexTable = {}
        self.applicationTable = {}
        self.abstractionTable = {}

    def invented(self, e):
        body = e.body.visit(self)
        i = id(body)
        if i in self.inventedTable:
            return self.inventedTable[i]
        new = Invented(body)
        self.inventedTable[i] = new
        return new

    def primitive(self, e):
        if e.name in self.primitiveTable:
            return self.primitiveTable[e.name]
        self.primitiveTable[e.name] = e
        return e

    def index(self, e):
        if e.i in self.indexTable:
            return self.indexTable[e.i]
        self.indexTable[e.i] = e
        return e

    def application(self, e):
        f = e.f.visit(self)
        x = e.x.visit(self)
        fi = id(f)
        xi = id(x)
        i = (fi, xi)
        if i in self.applicationTable:
            return self.applicationTable[i]
        new = Application(f, x)
        self.applicationTable[i] = new
        return new

    def abstraction(self, e):
        body = e.body.visit(self)
        i = id(body)
        if i in self.abstractionTable:
            return self.abstractionTable[i]
        new = Abstraction(body)
        self.abstractionTable[i] = new
        return new

    def execute(self, e):
        return e.visit(self)


class Mutator:
    """Perform local mutations to an expr, yielding the expr and the
    description length distance from the original program"""

    def __init__(self, grammar, fn):
        """Fn yields (expression, loglikelihood) from a type and loss.
        Therefore, loss+loglikelihood is the distance from the original program."""
        self.fn = fn
        self.grammar = grammar
        self.history = []

    def enclose(self, expr):
        for h in self.history[::-1]:
            expr = h(expr)
        return expr

    def invented(self, e, tp, env, is_lhs=False):
        deleted_ll = self.logLikelihood(tp, e, env)
        for expr, replaced_ll in self.fn(tp, deleted, is_left_application=is_lhs):
            yield self.enclose(expr), deleted_ll + replaced_ll

    def primitive(self, e, tp, env, is_lhs=False):
        deleted_ll = self.logLikelihood(tp, e, env)
        for expr, replaced_ll in self.fn(tp, deleted_ll, is_left_application=is_lhs):
            yield self.enclose(expr), deleted_ll + replaced_ll

    def index(self, e, tp, env, is_lhs=False):
        # yield from ()
        deleted_ll = self.logLikelihood(tp, e, env)  # self.grammar.logVariable
        for expr, replaced_ll in self.fn(tp, deleted_ll, is_left_application=is_lhs):
            yield self.enclose(expr), deleted_ll + replaced_ll

    def application(self, e, tp, env, is_lhs=False):
        self.history.append(lambda expr: Application(expr, e.x))
        f_tp = arrow(e.x.infer(), tp)
        yield from e.f.visit(self, f_tp, env, is_lhs=True)
        self.history[-1] = lambda expr: Application(e.f, expr)
        x_tp = inferArg(tp, e.f.infer())
        yield from e.x.visit(self, x_tp, env)
        self.history.pop()
        deleted_ll = self.logLikelihood(tp, e, env)
        for expr, replaced_ll in self.fn(tp, deleted_ll, is_left_application=is_lhs):
            yield self.enclose(expr), deleted_ll + replaced_ll

    def abstraction(self, e, tp, env, is_lhs=False):
        self.history.append(lambda expr: Abstraction(expr))
        yield from e.body.visit(self, tp.arguments[1], [tp.arguments[0]] + env)
        self.history.pop()
        deleted_ll = self.logLikelihood(tp, e, env)
        for expr, replaced_ll in self.fn(tp, deleted_ll, is_left_application=is_lhs):
            yield self.enclose(expr), deleted_ll + replaced_ll

    def execute(self, e, tp):
        yield from e.visit(self, tp, [])

    def logLikelihood(self, tp, e, env):
        summary = None
        try:
            _, summary = self.grammar.likelihoodSummary(
                Context.EMPTY, env, tp, e, silent=True
            )
        except AssertionError as err:
            # print(f"closedLikelihoodSummary failed on tp={tp}, e={e}, error={err}")
            pass
        if summary is not None:
            return summary.logLikelihood(self.grammar)
        else:
            tmpE, depth = e, 0
            while isinstance(tmpE, Abstraction):
                depth += 1
                tmpE = tmpE.body
            to_introduce = len(tp.functionArguments()) - depth
            if to_introduce == 0:
                # print(f"HIT NEGATIVEINFINITY, tp={tp}, e={e}")
                return NEGATIVEINFINITY
            for i in reversed(range(to_introduce)):
                e = Application(e, Index(i))
            for _ in range(to_introduce):
                e = Abstraction(e)
            return self.logLikelihood(tp, e, env)


class RegisterPrimitives(object):
    def invented(self, e):
        e.body.visit(self)

    def primitive(self, e):
        if e.name not in Primitive.GLOBALS:
            Primitive(e.name, e.tp, e.value)

    def index(self, e):
        pass

    def application(self, e):
        e.f.visit(self)
        e.x.visit(self)

    def abstraction(self, e):
        e.body.visit(self)

    @staticmethod
    def register(e):
        e.visit(RegisterPrimitives())


class PrettyVisitor(object):
    def __init__(self, Lisp=False):
        self.Lisp = Lisp
        self.numberOfVariables = 0
        self.freeVariables = {}

        self.variableNames = ["x", "y", "z", "u", "v", "w"]
        self.variableNames += [chr(ord("a") + j) for j in range(20)]
        self.toplevel = True

    def makeVariable(self):
        v = self.variableNames[self.numberOfVariables]
        self.numberOfVariables += 1
        return v

    def invented(self, e, environment, isFunction, isAbstraction):
        s = e.body.visit(self, [], isFunction, isAbstraction)
        return s

    def primitive(self, e, environment, isVariable, isAbstraction):
        return e.name

    def index(self, e, environment, isVariable, isAbstraction):
        if e.i < len(environment):
            return environment[e.i]
        else:
            i = e.i - len(environment)
            if i in self.freeVariables:
                return self.freeVariables[i]
            else:
                v = self.makeVariable()
                self.freeVariables[i] = v
                return v

    def application(self, e, environment, isFunction, isAbstraction):
        self.toplevel = False
        s = "%s %s" % (
            e.f.visit(self, environment, True, False),
            e.x.visit(self, environment, False, False),
        )
        if isFunction:
            return s
        else:
            return "(" + s + ")"

    def abstraction(self, e, environment, isFunction, isAbstraction):
        toplevel = self.toplevel
        self.toplevel = False
        if not self.Lisp:
            # Invent a new variable
            v = self.makeVariable()
            body = e.body.visit(self, [v] + environment, False, True)
            if not e.body.isAbstraction:
                body = "." + body
            body = v + body
            if not isAbstraction:
                body = "λ" + body
            if not toplevel:
                body = "(%s)" % body
            return body
        else:
            child = e
            newVariables = []
            while child.isAbstraction:
                newVariables = [self.makeVariable()] + newVariables
                child = child.body
            body = child.visit(self, newVariables + environment, False, True)
            body = "(λ (%s) %s)" % (" ".join(reversed(newVariables)), body)
            return body


def prettyProgram(e, Lisp=False):
    return e.visit(PrettyVisitor(Lisp=Lisp), [], False, False)


class EtaExpandFailure(Exception):
    pass


class EtaLongVisitor(object):
    """Converts an expression into eta-longform"""

    def __init__(self, request=None):
        self.request = request
        self.context = None

    def makeLong(self, e, request):
        if request.isArrow():
            # eta expansion
            return Abstraction(Application(e.shift(1), Index(0)))
        return None

    def abstraction(self, e, request, environment):
        if not request.isArrow():
            raise EtaExpandFailure()

        return Abstraction(
            e.body.visit(
                self, request.arguments[1], [request.arguments[0]] + environment
            )
        )

    def _application(self, e, request, environment):
        l = self.makeLong(e, request)
        if l is not None:
            return l.visit(self, request, environment)

        f, xs = e.applicationParse()

        if f.isIndex:
            ft = environment[f.i].applyMutable(self.context)
        elif f.isInvented or f.isPrimitive:
            ft = f.tp.instantiateMutable(self.context)
        else:
            assert False, "Not in beta long form: %s" % e

        self.context.unify(request, ft.returns())
        ft = ft.applyMutable(self.context)

        xt = ft.functionArguments()
        if len(xs) != len(xt):
            raise EtaExpandFailure()

        returnValue = f
        for x, t in zip(xs, xt):
            t = t.applyMutable(self.context)
            returnValue = Application(returnValue, x.visit(self, t, environment))
        return returnValue

    # This procedure works by recapitulating the generative process
    # applications indices and primitives are all generated identically

    def application(self, e, request, environment):
        return self._application(e, request, environment)

    def index(self, e, request, environment):
        return self._application(e, request, environment)

    def primitive(self, e, request, environment):
        return self._application(e, request, environment)

    def invented(self, e, request, environment):
        return self._application(e, request, environment)

    def execute(self, e):
        assert len(e.freeVariables()) == 0

        if self.request is None:
            eprint("WARNING: request not specified for etaexpansion")
            self.request = e.infer()
        self.context = MutableContext()
        el = e.visit(self, self.request, [])
        self.context = None
        # assert el.infer().canonical() == e.infer().canonical(), \
        #     f"Types are not preserved by ETA expansion: {e} : {e.infer().canonical()} vs {el} : {el.infer().canonical()}"
        return el


class StripPrimitiveVisitor:
    """Replaces all primitives .value's w/ None. Does not destructively modify anything"""

    def invented(self, e):
        return Invented(e.body.visit(self))

    def primitive(self, e):
        return Primitive(e.name, e.tp, None)

    def application(self, e):
        return Application(e.f.visit(self), e.x.visit(self))

    def abstraction(self, e):
        return Abstraction(e.body.visit(self))

    def index(self, e):
        return e


class ReplacePrimitiveValueVisitor:
    """Intended to be used after StripPrimitiveVisitor.
    Replaces all primitive.value's with their corresponding entry in Primitive.GLOBALS
    """

    def invented(self, e):
        return Invented(e.body.visit(self))

    def primitive(self, e):
        return Primitive(e.name, e.tp, Primitive.GLOBALS[e.name].value)

    def application(self, e):
        return Application(e.f.visit(self), e.x.visit(self))

    def abstraction(self, e):
        return Abstraction(e.body.visit(self))

    def index(self, e):
        return e


def strip_primitive_values(e):
    return e.visit(StripPrimitiveVisitor())


def unstrip_primitive_values(e):
    return e.visit(ReplacePrimitiveValueVisitor())


# from luke
class TokeniseVisitor(object):
    def invented(self, e):
        return [e.body]

    def primitive(self, e):
        return [e.name]

    def index(self, e):
        return ["$" + str(e.i)]

    def application(self, e):
        return ["("] + e.f.visit(self) + e.x.visit(self) + [")"]

    def abstraction(self, e):
        return ["(_lambda"] + e.body.visit(self) + [")_lambda"]


def tokeniseProgram(e):
    return e.visit(TokeniseVisitor())


def untokeniseProgram(l):
    lookup = {"(_lambda": "(lambda", ")_lambda": ")"}
    s = " ".join(lookup.get(x, x) for x in l)
    return Program.parse(s)


if __name__ == "__main__":
    from dreamcoder.domains.arithmetic.arithmeticPrimitives import *

    e = Program.parse(
        "(#(lambda (?? (+ 1 $0))) (lambda (?? (+ 1 $0))) (lambda (?? (+ 1 $0))) - * (+ +))"
    )
    eprint(e)

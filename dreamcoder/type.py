import re
from typing import Dict

from dreamcoder.utilities import ParseFailure


class UnificationFailure(Exception):
    pass


class Occurs(UnificationFailure):
    pass


class Type(object):
    def __str__(self):
        return self.show(True)

    def __repr__(self):
        return str(self)

    @staticmethod
    def fromjson(j):
        if "index" in j:
            return TypeVariable(j["index"])
        if "constructor" in j:
            return TypeConstructor(j["constructor"], [Type.fromjson(a) for a in j["arguments"]])
        assert False

    @staticmethod
    def _parse_type_expression(s):
        s = s.strip()

        def parse_arg_list(n):
            l = []
            while s[n] != ")":
                e, n = parse_type(n)
                if l and isinstance(e, dict):
                    l[0] = dict(l[0], **e)
                else:
                    l.append(e)
            n += 1
            return l, n

        def parse_type(n):
            while n <= len(s) and s[n].isspace():
                n += 1
            if n == len(s):
                raise ParseFailure(s)

            name = []
            while n < len(s) and not s[n].isspace() and s[n] not in ":()[],":
                name.append(s[n])
                n += 1
            name = "".join(name)
            t = name
            key = None
            if n == len(s) or s[n] == ")":
                return name, n
            if s[n] == ":":
                key = name
                n += 1
                if s[n] == "(":
                    n += 1
                    arg, n = parse_type(n)
                    n += 1
                    t = arg
                else:
                    name = []
                    while n < len(s) and not s[n].isspace() and s[n] not in ":()[],":
                        name.append(s[n])
                        n += 1
                    name = "".join(name)
                    t = name
            if s[n] == "(":
                n += 1
                args_list, n = parse_arg_list(n)
                t = [name, args_list]
                if n == len(s) or s[n] == ")":
                    return t, n
            if s[n] == ",":
                n += 1
                if key:
                    return {key: t}, n
                return t, n
            if s[n].isspace() and n + 2 < len(s) and s[n + 1 : n + 3] == ARROW:
                n += 3
                cont, n = parse_type(n)
                if key:
                    t = {key: t}
                    if isinstance(cont, list) and cont[0] == ARROW and isinstance(cont[1], dict):
                        t = dict(t, **cont[1])
                        cont = cont[2]
                    return [ARROW, t, cont], n
                return [ARROW, t, cont], n
            raise ParseFailure(s)

        e, n = parse_type(0)
        if n == len(s):
            return e
        raise ParseFailure(s)

    @classmethod
    def fromstring(cls, s):
        exp = cls._parse_type_expression(s)

        def p(e):
            if isinstance(e, str):
                m = re.match(r"t(\d+)$", e)
                if m:
                    return TypeVariable(int(m.group(1)))
                return TypeConstructor(e, [])

            if isinstance(e, list):
                if len(e) == 2:
                    name, args = e
                    if len(args) == 2 and isinstance(args[0], dict):
                        return TypeNamedArgsConstructor(name, {k: p(a) for (k, a) in args[0].items()}, p(args[1]))
                    return TypeConstructor(name, [p(arg) for arg in args])
                if e[0] == ARROW:
                    if isinstance(e[1], dict):
                        return TypeNamedArgsConstructor(ARROW, {k: p(a) for (k, a) in e[1].items()}, p(e[2]))
                    return TypeConstructor(ARROW, [p(e[1]), p(e[2])])
            raise ParseFailure(s)

        return p(exp)


class TypeConstructor(Type):
    def __init__(self, name, arguments):
        self.name = name
        self.arguments = arguments
        self.isPolymorphic = any(a.isPolymorphic for a in arguments)

    def makeDummyMonomorphic(self, mapping=None):
        mapping = mapping if mapping is not None else {}
        return TypeConstructor(self.name, [a.makeDummyMonomorphic(mapping) for a in self.arguments])

    def __eq__(self, other):
        return (
            isinstance(other, TypeConstructor)
            and self.name == other.name
            and all(x == y for x, y in zip(self.arguments, other.arguments))
        )

    def __hash__(self):
        return hash((self.name,) + tuple(self.arguments))

    def __ne__(self, other):
        return not (self == other)

    def show(self, isReturn):
        if self.name == ARROW:
            if isReturn:
                return "%s %s %s" % (self.arguments[0].show(False), ARROW, self.arguments[1].show(True))
            else:
                return "(%s %s %s)" % (self.arguments[0].show(False), ARROW, self.arguments[1].show(True))
        elif self.arguments == []:
            return self.name
        else:
            return "%s(%s)" % (self.name, ", ".join(x.show(True) for x in self.arguments))

    def json(self):
        return {"constructor": self.name, "arguments": [a.json() for a in self.arguments]}

    def isArrow(self):
        return self.name == ARROW

    def functionArguments(self):
        if self.name == ARROW:
            xs = self.arguments[1].functionArguments()
            return [self.arguments[0]] + xs
        return []

    def returns(self):
        if self.name == ARROW:
            return self.arguments[1].returns()
        else:
            return self

    def apply(self, context):
        if not self.isPolymorphic:
            return self
        return TypeConstructor(self.name, [x.apply(context) for x in self.arguments])

    def applyMutable(self, context):
        if not self.isPolymorphic:
            return self
        return TypeConstructor(self.name, [x.applyMutable(context) for x in self.arguments])

    def occurs(self, v):
        if not self.isPolymorphic:
            return False
        return any(x.occurs(v) for x in self.arguments)

    def negateVariables(self):
        return TypeConstructor(self.name, [a.negateVariables() for a in self.arguments])

    def instantiate(self, context, bindings=None):
        if not self.isPolymorphic:
            return context, self
        if bindings is None:
            bindings = {}
        newArguments = []
        for x in self.arguments:
            (context, x) = x.instantiate(context, bindings)
            newArguments.append(x)
        return (context, TypeConstructor(self.name, newArguments))

    def instantiateMutable(self, context, bindings=None):
        if not self.isPolymorphic:
            return self
        if bindings is None:
            bindings = {}
        newArguments = []
        return TypeConstructor(self.name, [x.instantiateMutable(context, bindings) for x in self.arguments])

    def canonical(self, bindings=None):
        if not self.isPolymorphic:
            return self
        if bindings is None:
            bindings = {}
        return TypeConstructor(self.name, [x.canonical(bindings) for x in self.arguments])


class TypeNamedArgsConstructor(Type):
    def __init__(self, name, arguments: Dict[str, Type], output: Type):
        self.name = name
        self.arguments = arguments
        self.output = output
        self.isPolymorphic = any(a.isPolymorphic for a in arguments.values()) or output.isPolymorphic

    def makeDummyMonomorphic(self, mapping=None):
        mapping = mapping if mapping is not None else {}
        return TypeNamedArgsConstructor(
            self.name,
            {k: a.makeDummyMonomorphic(mapping) for (k, a) in self.arguments.items()},
            self.output.makeDummyMonomorphic(mapping),
        )

    def __eq__(self, other):
        return (
            isinstance(other, TypeNamedArgsConstructor)
            and self.name == other.name
            and all(x == other.arguments[k] for k, x in self.arguments.items())
            and self.output == other.output
        )

    def __hash__(self):
        return hash((self.name,) + tuple(self.arguments.items()) + (self.output,))

    def __ne__(self, other):
        return not (self == other)

    def show(self, isReturn):
        if self.name == ARROW:
            args_str = f" {ARROW} ".join([f"{k}:{a.show(False)}" for (k, a) in self.arguments.items()])
            if isReturn:
                return f"{args_str} {ARROW} {self.output.show(True)}"
            else:
                return f"({args_str} {ARROW} {self.output.show(True)})"
        elif self.arguments == {}:
            return f"{self.name}({self.output.show(True)})"
        else:
            args_str = f", ".join([f"{k}:{a.show(False)}" for (k, a) in self.arguments.items()])
            return f"{self.name}({args_str}, {self.output.show(True)})"

    def json(self):
        return {
            "constructor": self.name,
            "arguments": {k: a.json() for k, a in self.arguments.items()},
            "output": self.output.json(),
        }

    def isArrow(self):
        return self.name == ARROW

    def functionArguments(self):
        if self.name == ARROW:
            xs = self.output.functionArguments()
            return list(self.arguments.items()) + xs
        return []

    def returns(self):
        if self.name == ARROW:
            return self.output.returns()
        else:
            return self

    def apply(self, context):
        if not self.isPolymorphic:
            return self
        return TypeNamedArgsConstructor(
            self.name, {k: x.apply(context) for k, x in self.arguments.items()}, self.output.apply(context)
        )

    def applyMutable(self, context):
        if not self.isPolymorphic:
            return self
        return TypeNamedArgsConstructor(
            self.name,
            {k: x.applyMutable(context) for k, x in self.arguments.items()},
            self.output.applyMutable(context),
        )

    def occurs(self, v):
        if not self.isPolymorphic:
            return False
        return any(x.occurs(v) for x in self.arguments.values()) or self.output.occurs(v)

    def negateVariables(self):
        return TypeNamedArgsConstructor(
            self.name, {k: a.negateVariables() for k, a in self.arguments.items()}, self.output.negateVariables()
        )

    def instantiate(self, context, bindings=None):
        if not self.isPolymorphic:
            return context, self
        if bindings is None:
            bindings = {}
        new_arguments = {}
        for k, x in self.arguments.items():
            (context, new_x) = x.instantiate(context, bindings)
            new_arguments[k] = new_x
        (context, new_output) = self.output.instantiate(context, bindings)
        return (context, TypeNamedArgsConstructor(self.name, new_arguments, new_output))

    def instantiateMutable(self, context, bindings=None):
        if not self.isPolymorphic:
            return self
        if bindings is None:
            bindings = {}
        return TypeNamedArgsConstructor(
            self.name,
            {k: x.instantiateMutable(context, bindings) for k, x in self.arguments.items()},
            self.output.instantiateMutable(context, bindings),
        )

    def canonical(self, bindings=None):
        if not self.isPolymorphic:
            return self
        if bindings is None:
            bindings = {}
        return TypeNamedArgsConstructor(
            self.name, {k: x.canonical(bindings) for k, x in self.arguments.items()}, self.output.canonical(bindings)
        )


class TypeVariable(Type):
    def __init__(self, j):
        assert isinstance(j, int)
        self.v = j
        self.isPolymorphic = True

    def makeDummyMonomorphic(self, mapping=None):
        mapping = mapping if mapping is not None else {}
        if self.v not in mapping:
            mapping[self.v] = TypeConstructor(f"dummy_type_{len(mapping)}", [])
        return mapping[self.v]

    def __eq__(self, other):
        return isinstance(other, TypeVariable) and self.v == other.v

    def __ne__(self, other):
        return not (self.v == other.v)

    def __hash__(self):
        return self.v

    def show(self, _):
        return "t%d" % self.v

    def json(self):
        return {"index": self.v}

    def returns(self):
        return self

    def isArrow(self):
        return False

    def functionArguments(self):
        return []

    def apply(self, context):
        for v, t in context.substitution:
            if v == self.v:
                return t.apply(context)
        return self

    def applyMutable(self, context):
        s = context.substitution[self.v]
        if s is None:
            return self
        new = s.applyMutable(context)
        context.substitution[self.v] = new
        return new

    def occurs(self, v):
        return v == self.v

    def instantiate(self, context, bindings=None):
        if bindings is None:
            bindings = {}
        if self.v in bindings:
            return (context, bindings[self.v])
        new = TypeVariable(context.nextVariable)
        bindings[self.v] = new
        context = Context(context.nextVariable + 1, context.substitution)
        return (context, new)

    def instantiateMutable(self, context, bindings=None):
        if bindings is None:
            bindings = {}
        if self.v in bindings:
            return bindings[self.v]
        new = context.makeVariable()
        bindings[self.v] = new
        return new

    def canonical(self, bindings=None):
        if bindings is None:
            bindings = {}
        if self.v in bindings:
            return bindings[self.v]
        new = TypeVariable(len(bindings))
        bindings[self.v] = new
        return new

    def negateVariables(self):
        return TypeVariable(-1 - self.v)


class Context(object):
    def __init__(self, nextVariable=0, substitution=[]):
        self.nextVariable = nextVariable
        self.substitution = substitution

    def extend(self, j, t):
        return Context(self.nextVariable, [(j, t)] + self.substitution)

    def makeVariable(self):
        return (Context(self.nextVariable + 1, self.substitution), TypeVariable(self.nextVariable))

    def unify(self, t1, t2):
        t1 = t1.apply(self)
        t2 = t2.apply(self)
        if t1 == t2:
            return self
        # t1&t2 are not equal
        if not t1.isPolymorphic and not t2.isPolymorphic:
            raise UnificationFailure(t1, t2)

        if isinstance(t1, TypeVariable):
            if t2.occurs(t1.v):
                raise Occurs()
            return self.extend(t1.v, t2)
        if isinstance(t2, TypeVariable):
            if t1.occurs(t2.v):
                raise Occurs()
            return self.extend(t2.v, t1)
        if t1.name != t2.name:
            raise UnificationFailure(t1, t2)
        k = self
        for x, y in zip(t2.arguments, t1.arguments):
            k = k.unify(x, y)
        return k

    def __str__(self):
        return "Context(next = %d, {%s})" % (
            self.nextVariable,
            ", ".join("t%d ||> %s" % (k, v.apply(self)) for k, v in self.substitution),
        )

    def __repr__(self):
        return str(self)


class MutableContext(object):
    def __init__(self):
        self.substitution = []

    def extend(self, i, t):
        assert self.substitution[i] is None
        self.substitution[i] = t

    def makeVariable(self):
        self.substitution.append(None)
        return TypeVariable(len(self.substitution) - 1)

    def unify(self, t1, t2):
        t1 = t1.applyMutable(self)
        t2 = t2.applyMutable(self)

        if t1 == t2:
            return

        # t1&t2 are not equal
        if not t1.isPolymorphic and not t2.isPolymorphic:
            raise UnificationFailure(t1, t2)

        if isinstance(t1, TypeVariable):
            if t2.occurs(t1.v):
                raise Occurs()
            self.extend(t1.v, t2)
            return
        if isinstance(t2, TypeVariable):
            if t1.occurs(t2.v):
                raise Occurs()
            self.extend(t2.v, t1)
            return
        if t1.name != t2.name:
            raise UnificationFailure(t1, t2)

        for x, y in zip(t2.arguments, t1.arguments):
            self.unify(x, y)


class TypeWeights(object):
    def __init__(self, weights):
        self.weights = weights

    def json(self):
        return self.weights

    def __str__(self) -> str:
        return str(self.weights)


Context.EMPTY = Context(0, [])


def canonicalTypes(ts):
    bindings = {}
    return [t.canonical(bindings) for t in ts]


def instantiateTypes(context, ts):
    bindings = {}
    newTypes = []
    for t in ts:
        context, t = t.instantiate(context, bindings)
        newTypes.append(t)
    return context, newTypes


def baseType(n):
    return TypeConstructor(n, [])


tint = baseType("int")
treal = baseType("real")
tbool = baseType("bool")
tboolean = tbool  # alias
tcharacter = baseType("char")


def tlist(t):
    return TypeConstructor("list", [t])


def tpair(a, b):
    return TypeConstructor("pair", [a, b])


def tmaybe(t):
    return TypeConstructor("maybe", [t])


tstr = tlist(tcharacter)
t0 = TypeVariable(0)
t1 = TypeVariable(1)
t2 = TypeVariable(2)

# regex types
tpregex = baseType("pregex")

ARROW = "->"


def arrow(*arguments):
    if len(arguments) == 1:
        return arguments[0]
    return TypeConstructor(ARROW, [arguments[0], arrow(*arguments[1:])])


def inferArg(tp, tcaller):
    ctx, tp = tp.instantiate(Context.EMPTY)
    ctx, tcaller = tcaller.instantiate(ctx)
    ctx, targ = ctx.makeVariable()
    ctx = ctx.unify(tcaller, arrow(targ, tp))
    return targ.apply(ctx)


def guess_type(xs):
    """
    Return a TypeConstructor corresponding to x's python type.
    Raises an exception if the type cannot be guessed.
    """
    if all(isinstance(x, bool) for x in xs):
        return tbool
    elif all(isinstance(x, int) for x in xs):
        return tint
    elif all(isinstance(x, str) for x in xs):
        return tstr
    elif all(isinstance(x, list) for x in xs):
        return tlist(guess_type([y for ys in xs for y in ys]))
    else:
        raise ValueError("cannot guess type from {}".format(xs))


def guess_arrow_type(examples):
    a = len(examples[0][0])
    input_types = []
    for n in range(a):
        input_types.append(guess_type([xs[n] for xs, _ in examples]))
    output_type = guess_type([y for _, y in examples])
    return arrow(*(input_types + [output_type]))


def canUnify(t1, t2):
    k = MutableContext()
    t1 = t1.instantiateMutable(k)
    t2 = t2.instantiateMutable(k)
    try:
        k.unify(t1, t2)
        return True
    except UnificationFailure:
        return False

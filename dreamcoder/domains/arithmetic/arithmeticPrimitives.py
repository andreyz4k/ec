from dreamcoder.program import Primitive, Curried
from dreamcoder.type import *


def _addition(x):
    return lambda y: x + y


def _subtraction(x):
    return lambda y: x - y


def _division(x):
    return lambda y: x / y


subtraction = Primitive(
    "-", arrow(tint, arrow(tint, tint)), _subtraction, is_reversible=True
)
real_subtraction = Primitive("-.", arrow(treal, treal, treal), _subtraction)
addition = Primitive(
    "+", arrow(tint, arrow(tint, tint)), Curried(_addition), is_reversible=True
)
real_addition = Primitive("+.", arrow(treal, treal, treal), _addition)


def _multiplication(x):
    return lambda y: x * y


multiplication = Primitive(
    "*", arrow(tint, arrow(tint, tint)), _multiplication, is_reversible=True
)
real_multiplication = Primitive("*.", arrow(treal, treal, treal), _multiplication)
real_division = Primitive("/.", arrow(treal, treal, treal), _division)


def _power(a):
    return lambda b: a**b


real_power = Primitive("power", arrow(treal, treal, treal), _power)

k1 = Primitive("1", tint, 1, is_reversible=True)
k_negative1 = Primitive("negative_1", tint, -1)
k0 = Primitive("0", tint, 0, is_reversible=True)
for n in range(2, 10):
    Primitive(str(n), tint, n, is_reversible=True)

f1 = Primitive("1.", treal, 1.0)
f0 = Primitive("0.", treal, 0)
real = Primitive("REAL", treal, None)
fpi = Primitive("pi", treal, 3.14)

import pytest
from dreamcoder.type import Type

types = [
    "t0",
    "t1",
    "int",
    "list(int)",
    "tuple(int, int)",
    "int -> int",
    "int -> int -> int",
    "list(int) -> list(int)",
    "list(int) -> list(int) -> list(int)",
    "list(int) -> (int -> bool) -> list(bool)",
    "inp0:list(int) -> list(int)",
    "inp0:list(int) -> inp1:list(int) -> list(int)",
    "f:(list(int) -> int) -> inp1:list(int) -> list(int)",
    "obj(cells:list(tuple(int, int)), kind)",
    "obj(cells:list(tuple(int, int)), pivot:bool, kind)",
    "obj(f:(int -> int), cells:list(tuple(int, int)), kind)",
    "obj(int -> int, list(tuple(int, int)), kind)",
]


@pytest.mark.parametrize("type_str", types)
def test_type_parsing(type_str):
    t = Type.fromstring(type_str)
    assert t.show(True) == type_str

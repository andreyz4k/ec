import pytest
from dreamcoder.domains.list.listPrimitives import bootstrapTarget_extra, julia
from dreamcoder.domains.arc.primitives import basePrimitives, tgrid, tcolor
from dreamcoder.grammar import Grammar
from dreamcoder.program import Program
from dreamcoder.task import NamedVarsTask, Task
from dreamcoder.type import ARROW, TypeNamedArgsConstructor, tlist, tint, arrow


@pytest.fixture(scope="module")
def base_grammar():
    prims = bootstrapTarget_extra()
    return Grammar.uniform(prims)


@pytest.fixture(scope="module")
def julia_grammar():
    prims = julia()
    return Grammar.uniform(prims)


@pytest.fixture(scope="module")
def base_task():
    return NamedVarsTask(
        Task(
            name="drop-k with k=1",
            request=arrow(tlist(tint), tlist(tint)),
            examples=[
                (([15, 1],), [1]),
                (([15, 8, 10, 1, 14, 1, 3],), [8, 10, 1, 14, 1, 3]),
                (([6, 8, 8, 1, 9],), [8, 8, 1, 9]),
                (([11, 2, 10, 10],), [2, 10, 10]),
                (([13, 2],), [2]),
                (([4, 7, 11, 4, 2, 5, 13, 5],), [7, 11, 4, 2, 5, 13, 5]),
                (([12, 0],), [0]),
                (([0, 1, 2, 7, 16, 3],), [1, 2, 7, 16, 3]),
                (([16, 2, 1, 12, 1, 11, 15],), [2, 1, 12, 1, 11, 15]),
                (([9, 9, 15],), [9, 15]),
                (([6, 4, 15, 0],), [4, 15, 0]),
                (([5, 16, 16, 9],), [16, 16, 9]),
                (([8],), []),
                (([16],), []),
                (([3, 13],), [13]),
            ],
        )
    )


def sample_programs():
    programs = [
        (
            "(cdr $inp0)",
            {
                "inp0": {
                    "list": 15,
                    "int": 58,
                },
                "out": {
                    "list": 15,
                    "int": 43,
                },
            },
            -2.302585092994046,
        ),
        (
            "let $v1::bool = (eq? $inp0 $inp0) in let $v2::list(int) = (cdr $inp0) in (if $v1 $v2 empty)",
            {
                "inp0": {
                    "list": 15,
                    "int": 58,
                },
                "out": {
                    "list": 15,
                    "int": 43,
                },
                "v1": {
                    "bool": 15,
                },
                "v2": {
                    "list": 15,
                    "int": 43,
                },
            },
            -9.104979856318357,
        ),
        (
            "let $v1::bool = (eq? $inp0 $inp0) in let $v2::int, $v3::list(int) = rev($inp0 = (cons $v2 $v3)) in (if $v1 $v3 empty)",
            {
                "inp0": {
                    "list": 15,
                    "int": 58,
                },
                "out": {
                    "list": 15,
                    "int": 43,
                },
                "v1": {
                    "bool": 15,
                },
                "v2": {
                    "int": 15,
                },
                "v3": {
                    "list": 15,
                    "int": 43,
                },
            },
            -7.901007051992421,
        ),
        (
            "let $v1::int, $v2::list(int) = rev($inp0 = (cons $v1 $v2)) in $v2",
            {
                "inp0": {
                    "list": 15,
                    "int": 58,
                },
                "out": {
                    "list": 15,
                    "int": 43,
                },
                "v1": {
                    "int": 15,
                },
                "v2": {
                    "list": 15,
                    "int": 43,
                },
            },
            -1.0986122886681098,
        ),
        (
            "let $v1::int = Const(int, 0) in let $v2::list(int) = (map (lambda $0) $inp0) in (cons $v1 $v2)",
            {
                "inp0": {
                    "list": 15,
                    "int": 58,
                },
                "out": {
                    "list": 15,
                    "int": 43,
                },
                "v1": {
                    "int": 15,
                },
                "v2": {
                    "list": 15,
                    "int": 43,
                },
            },
            -7.090076835776092,
        ),
    ]
    return programs


@pytest.mark.parametrize("program, complexities, expected_likelihood", sample_programs())
def test_program_likelihood(base_grammar, base_task, program, complexities, expected_likelihood):
    p = Program.parse(program)
    print(base_task.request)
    print(p)
    likelihood = base_grammar.logLikelihood(base_task.request, p)
    print(likelihood)
    assert likelihood == expected_likelihood


def sample_wrapper_programs():
    programs = [
        {
            "program": "let $v1::list(int) = Const(list(int), Any[]) in let $v2::list(int), $v3::list(int) = wrap(let $v2, $v3 = rev($inp0 = (concat $v2 $v3)); let $v2 = $v1) in let $v4::list(int) = Const(list(int), Any[]) in let $v5::list(int) = Const(list(int), Any[1]) in let $v6::list(int) = (concat $v4 $v5) in (concat $v3 $v6)",
            "time": 14.128462791442871,
            "logLikelihood": 0.0,
            "logPrior": -6.579251212010101,
        },
        {
            "program": "let $v1::list(int), $v2::list(int) = wrap(let $v1, $v2 = rev($inp0 = (concat $v1 $v2)); let $v2 = $inp0) in let $v3::list(int) = Const(list(int), Any[]) in let $v4::list(int) = Const(list(int), Any[1]) in let $v5::list(int) = (concat $v3 $v4) in (concat $v2 $v5)",
            "time": 14.270664930343628,
            "logLikelihood": 0.0,
            "logPrior": -6.579251212010101,
        },
        {
            "program": "let $v1::list(int) = Const(list(int), Any[]) in let $v2::list(int), $v3::list(int) = wrap(let $v2, $v3 = rev($inp0 = (concat $v2 $v3)); let $v3 = $v1) in let $v4::list(int) = Const(list(int), Any[]) in let $v5::list(int) = Const(list(int), Any[1]) in let $v6::list(int) = (concat $v4 $v5) in (concat $v2 $v6)",
            "time": 14.286531925201416,
            "logLikelihood": 0.0,
            "logPrior": -6.579251212010101,
        },
        {
            "program": "let $v1::list(int), $v2::list(int) = wrap(let $v1, $v2 = rev($inp0 = (concat $v1 $v2)); let $v1 = $inp0) in let $v3::list(int) = Const(list(int), Any[]) in let $v4::list(int) = Const(list(int), Any[1]) in let $v5::list(int) = (concat $v3 $v4) in (concat $v1 $v5)",
            "time": 14.27908992767334,
            "logLikelihood": 0.0,
            "logPrior": -6.579251212010101,
        },
        {
            "program": "let $v1::list(int) = Const(list(int), Any[]) in let $v2::list(int) = Const(list(int), Any[1]) in let $v3::list(int) = (concat $v1 $v2) in (concat $inp0 $v3)",
            "time": 13.979617834091187,
            "logLikelihood": 0.0,
            "logPrior": -4.969813299576001,
        },
        {
            "program": "let $v1::list(int), $v2::list(int) = wrap(let $v1, $v2 = rev($inp0 = (concat $v1 $v2)); let $v2 = $inp0) in let $v3::list(int) = Const(list(int), Any[1]) in (concat $v2 $v3)",
            "time": 13.207619905471802,
            "logLikelihood": 0.0,
            "logPrior": -4.0943445622221,
        },
        {
            "program": "let $v1::list(int) = Const(list(int), Any[]) in let $v2::list(int), $v3::list(int) = wrap(let $v2, $v3 = rev($inp0 = (concat $v2 $v3)); let $v2 = $v1) in let $v4::list(int) = Const(list(int), Any[1]) in (concat $v3 $v4)",
            "time": 12.554029941558838,
            "logLikelihood": 0.0,
            "logPrior": -4.0943445622221,
        },
        {
            "program": "let $v1::list(int), $v2::list(int) = wrap(let $v1, $v2 = rev($inp0 = (concat $v1 $v2)); let $v1 = $inp0) in let $v3::list(int) = Const(list(int), Any[1]) in (concat $v1 $v3)",
            "time": 13.738729000091553,
            "logLikelihood": 0.0,
            "logPrior": -4.0943445622221,
        },
        {
            "program": "let $v1::list(int) = Const(list(int), Any[]) in let $v2::list(int), $v3::list(int) = wrap(let $v2, $v3 = rev($inp0 = (concat $v2 $v3)); let $v3 = $v1) in let $v4::list(int) = Const(list(int), Any[1]) in (concat $v2 $v4)",
            "time": 13.747699975967407,
            "logLikelihood": 0.0,
            "logPrior": -4.0943445622221,
        },
        {
            "program": "let $v1::list(int) = Const(list(int), Any[1]) in (concat $inp0 $v1)",
            "time": 4.126955986022949,
            "logLikelihood": 0.0,
            "logPrior": -2.4849066497880004,
        },
        {
            "program": "let $v1::int, $v2::list(int) = rev($inp0 = (cons $v1 $v2)) in let $v3::list(int) = Const(list(int), Any[]) in let $v4::list(int), $v5::list(int) = rev($v3 = (concat $v4 $v5)) in let $v6::int = (+ $v1 (length $v4)) in let $v7::list(int) = (cdr $v2) in (cons $v6 $v7)",
            "time": 9.622529983520508,
            "logLikelihood": 0.0,
            "logPrior": -12.984479670040942,
        },
    ]
    return programs


@pytest.mark.parametrize("solution", sample_wrapper_programs())
def test_parsing_wrap(julia_grammar, solution):
    program_str = solution["program"]
    print(program_str)
    p = Program.parse(program_str)
    print(p.show(False))
    request = TypeNamedArgsConstructor(
        ARROW,
        {"inp0": tlist(tint)},
        tlist(tint),
    )
    likelihood = julia_grammar.logLikelihood(request, p)
    print(likelihood)
    assert likelihood == solution["logPrior"]


@pytest.fixture(scope="module")
def arc_grammar():
    prims = basePrimitives()
    return Grammar.uniform(prims)


def sample_arc_programs():
    programs = [
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (rows_to_grid $v1)) in let $v2::grid(color) = rev($v1 = (columns $v2)) in let $v3::list(color), $v4::list(list(color)) = rev($v1 = (cons $v3 $v4)) in let $v5::color, $v6::list(color) = rev($v3 = (cons $v5 $v6)) in let $v7::color, $v8::list(color) = rev($v6 = (cons $v7 $v8)) in let $v9::list(color), $v10::list(color) = wrap(let $v9, $v10 = rev($v6 = (concat $v9 $v10)); let $v10 = $v8) in let $v11::color, $v12::int = rev($v10 = (repeat $v11 $v12)) in (car (repeat $v2 $v12))",
            "time": 3.1087260246276855,
            "logLikelihood": 0.0,
            "logPrior": -16.62114108740535,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (rows_to_grid $v1)) in let $v2::grid(color) = rev($v1 = (columns $v2)) in let $v3::list(color), $v4::list(list(color)) = rev($v1 = (cons $v3 $v4)) in let $v5::color, $v6::list(color) = rev($v3 = (cons $v5 $v6)) in let $v7::list(color) = (cdr $v6) in let $v8::color, $v9::int = rev($v7 = (repeat $v8 $v9)) in (car (repeat $v2 $v9))",
            "time": 3.1089580059051514,
            "logLikelihood": 0.0,
            "logPrior": -16.110315463639356,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (rows_to_grid $v1)) in let $v2::grid(color) = rev($v1 = (columns $v2)) in let $v3::list(color), $v4::list(list(color)) = rev($v1 = (cons $v3 $v4)) in let $v5::list(color) = (cdr $v3) in let $v6::color, $v7::list(color) = rev($v5 = (cons $v6 $v7)) in let $v8::color, $v9::int = rev($v7 = (repeat $v8 $v9)) in (car (repeat $v2 $v9))",
            "time": 2.7325570583343506,
            "logLikelihood": 0.0,
            "logPrior": -16.110315463639356,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (columns_to_grid $v1)) in let $v2::grid(color) = rev($v1 = (rows $v2)) in let $v3::list(list(color)) = rev($inp0 = (rows_to_grid $v3)) in let $v4::list(color), $v5::list(list(color)) = rev($v3 = (cons $v4 $v5)) in let $v6::color, $v7::list(color) = rev($v4 = (cons $v6 $v7)) in let $v8::color, $v9::list(color) = rev($v7 = (cons $v8 $v9)) in let $v10::color, $v11::int = rev($v9 = (repeat $v10 $v11)) in (car (repeat $v2 $v11))",
            "time": 2.2313830852508545,
            "logLikelihood": 0.0,
            "logPrior": -16.397997536091136,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (rows_to_grid $v1)) in let $v2::grid(color) = rev($v1 = (columns $v2)) in let $v3::list(color), $v4::list(list(color)) = rev($v1 = (cons $v3 $v4)) in let $v5::color, $v6::list(color) = rev($v3 = (cons $v5 $v6)) in let $v7::color, $v8::list(color) = rev($v6 = (cons $v7 $v8)) in let $v9::color, $v10::int = rev($v8 = (repeat $v9 $v10)) in (car (repeat $v2 $v10))",
            "time": 2.2469329833984375,
            "logLikelihood": 0.0,
            "logPrior": -15.011703174971247,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (rows_to_grid $v1)) in let $v2::grid(color) = rev($v1 = (rows $v2)) in let $v3::list(list(color)) = rev($v2 = (rows_to_grid $v3)) in (columns_to_grid $v3)",
            "time": 1.890024185180664,
            "logLikelihood": 0.0,
            "logPrior": -6.915723448631313,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (rows_to_grid $v1)) in (columns_to_grid $v1)",
            "time": 1.7431960105895996,
            "logLikelihood": 0.0,
            "logPrior": -3.58351893845611,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (columns_to_grid $v1)) in (rows_to_grid $v1)",
            "time": 1.2298321723937988,
            "logLikelihood": 0.0,
            "logPrior": -3.58351893845611,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (rows_to_grid $v1)) in let $v2::grid(color) = rev($v1 = (columns $v2)) in $v2",
            "time": 1.8264191150665283,
            "logLikelihood": 0.0,
            "logPrior": -3.332204510175204,
        },
        {
            "program": "let $v1::list(list(color)) = rev($inp0 = (columns_to_grid $v1)) in let $v2::grid(color) = rev($v1 = (rows $v2)) in $v2",
            "time": 1.820842981338501,
            "logLikelihood": 0.0,
            "logPrior": -3.332204510175204,
        },
    ]
    return programs


@pytest.mark.parametrize("solution", sample_arc_programs())
def test_parsing_arc(arc_grammar, solution):
    program_str = solution["program"]
    print(program_str)
    p = Program.parse(program_str)
    print(p.show(False))
    request = TypeNamedArgsConstructor(
        ARROW,
        {"inp0": tgrid(tcolor)},
        tgrid(tcolor),
    )
    likelihood = arc_grammar.logLikelihood(request, p)
    print(likelihood)
    assert likelihood == solution["logPrior"]

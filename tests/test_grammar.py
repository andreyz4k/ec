import pytest
from dreamcoder.domains.list.listPrimitives import bootstrapTarget_extra, julia
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
            "let $v1 = (eq? $inp0 $inp0) in let $v2 = (cdr $inp0) in (if $v1 $v2 empty)",
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
            # -10.021270588192511,
            -9.104979856318357,
        ),
        (
            "let $v1 = (eq? $inp0 $inp0) in let $v2, $v3 = rev($inp0 = (cons $v2 $v3)) in (if $v1 $v3 empty)",
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
            -9.104979856318357,
            # -8.006367567650248,
        ),
        (
            "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in $v2",
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
            -2.302585092994046,
            # -0.6931471805599453,
        ),
        (
            "let $v1 = Const(int, 0) in let $v2 = (map (lambda $0) $inp0) in (cons $v1 $v2)",
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
            "program": "let $v1 = Const(list(int), Any[]) in let $v2, $v3 = wrap(let $v2, $v3 = rev($inp0 = (concat $v2 $v3)); let $v2 = $v1) in let $v4 = Const(list(int), Any[]) in let $v5 = Const(list(int), Any[1]) in let $v6 = (concat $v4 $v5) in (concat $v3 $v6)",
            "time": 14.128462791442871,
            "logLikelihood": 0.0,
            # "logPrior": -6.356107660695891,
            "logPrior": -7.4547199493640015,
        },
        {
            "program": "let $v1, $v2 = wrap(let $v1, $v2 = rev($inp0 = (concat $v1 $v2)); let $v2 = $inp0) in let $v3 = Const(list(int), Any[]) in let $v4 = Const(list(int), Any[1]) in let $v5 = (concat $v3 $v4) in (concat $v2 $v5)",
            "time": 14.270664930343628,
            "logLikelihood": 0.0,
            # "logPrior": -6.356107660695891,
            "logPrior": -7.4547199493640015,
        },
        {
            "program": "let $v1 = Const(list(int), Any[]) in let $v2, $v3 = wrap(let $v2, $v3 = rev($inp0 = (concat $v2 $v3)); let $v3 = $v1) in let $v4 = Const(list(int), Any[]) in let $v5 = Const(list(int), Any[1]) in let $v6 = (concat $v4 $v5) in (concat $v2 $v6)",
            "time": 14.286531925201416,
            "logLikelihood": 0.0,
            # "logPrior": -6.356107660695891,
            "logPrior": -7.4547199493640015,
        },
        {
            "program": "let $v1, $v2 = wrap(let $v1, $v2 = rev($inp0 = (concat $v1 $v2)); let $v1 = $inp0) in let $v3 = Const(list(int), Any[]) in let $v4 = Const(list(int), Any[1]) in let $v5 = (concat $v3 $v4) in (concat $v1 $v5)",
            "time": 14.27908992767334,
            "logLikelihood": 0.0,
            # "logPrior": -6.356107660695891,
            "logPrior": -7.4547199493640015,
        },
        {
            "program": "let $v1 = Const(list(int), Any[]) in let $v2 = Const(list(int), Any[1]) in let $v3 = (concat $v1 $v2) in (concat $inp0 $v3)",
            "time": 13.979617834091187,
            "logLikelihood": 0.0,
            "logPrior": -4.969813299576001,
        },
        {
            "program": "let $v1, $v2 = wrap(let $v1, $v2 = rev($inp0 = (concat $v1 $v2)); let $v2 = $inp0) in let $v3 = Const(list(int), Any[1]) in (concat $v2 $v3)",
            "time": 13.207619905471802,
            "logLikelihood": 0.0,
            # "logPrior": -3.8712010109078907,
            "logPrior": -4.969813299576001,
        },
        {
            "program": "let $v1 = Const(list(int), Any[]) in let $v2, $v3 = wrap(let $v2, $v3 = rev($inp0 = (concat $v2 $v3)); let $v2 = $v1) in let $v4 = Const(list(int), Any[1]) in (concat $v3 $v4)",
            "time": 12.554029941558838,
            "logLikelihood": 0.0,
            # "logPrior": -3.8712010109078907,
            "logPrior": -4.969813299576001,
        },
        {
            "program": "let $v1, $v2 = wrap(let $v1, $v2 = rev($inp0 = (concat $v1 $v2)); let $v1 = $inp0) in let $v3 = Const(list(int), Any[1]) in (concat $v1 $v3)",
            "time": 13.738729000091553,
            "logLikelihood": 0.0,
            # "logPrior": -3.8712010109078907,
            "logPrior": -4.969813299576001,
        },
        {
            "program": "let $v1 = Const(list(int), Any[]) in let $v2, $v3 = wrap(let $v2, $v3 = rev($inp0 = (concat $v2 $v3)); let $v3 = $v1) in let $v4 = Const(list(int), Any[1]) in (concat $v2 $v4)",
            "time": 13.747699975967407,
            "logLikelihood": 0.0,
            # "logPrior": -3.8712010109078907,
            "logPrior": -4.969813299576001,
        },
        {
            "program": "let $v1 = Const(list(int), Any[1]) in (concat $inp0 $v1)",
            "time": 4.126955986022949,
            "logLikelihood": 0.0,
            "logPrior": -2.4849066497880004,
        },
        {
            "program": "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3 = Const(list(int), Any[]) in let $v4, $v5 = rev($v3 = (concat $v4 $v5)) in let $v6 = (+ $v1 (length $v4)) in let $v7 = (cdr $v2) in (cons $v6 $v7)",
            "time": 9.622529983520508,
            "logLikelihood": 0.0,
            "logPrior": -14.735417144748743,
            # "logPrior": -12.538192567412523,
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

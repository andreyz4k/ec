import pytest
from dreamcoder.domains.list.listPrimitives import bootstrapTarget_extra, julia
from dreamcoder.domains.arc.primitives import (
    basePrimitives,
    tgrid,
    tcolor,
    tset,
    ttuple2,
)
from dreamcoder.grammar import Grammar
from dreamcoder.program import Program
from dreamcoder.task import NamedVarsTask, Task
from dreamcoder.type import ARROW, Type, TypeNamedArgsConstructor, tlist, tint, arrow


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
    return NamedVarsTask.from_task(
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
            -3.8113960764294212,
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
            -16.25416570997799,
        ),
        (
            "let $v1::bool = (eq? $inp0 $inp0) in let $v2, $v3 = rev($inp0 = (cons $v2 $v3)) in (if $v1 $v3 empty)",
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
            -16.154605816716817,
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
            -4.1175342213829556,
        ),
    ]
    return programs


@pytest.mark.parametrize(
    "program, complexities, expected_likelihood", sample_programs()
)
def test_program_likelihood(
    base_grammar, base_task, program, complexities, expected_likelihood
):
    p = Program.parse(program)
    print(base_task.request)
    print(p)
    likelihood = base_grammar.logLikelihood(base_task.request, p)
    print(likelihood)
    assert likelihood == expected_likelihood


def test_program_likelihood2(julia_grammar):
    program = "let $v1, $v2 = rev($inp0 = (repeat $v1 $v2)) in (gt? (rev_fix_param (- 0 $v2) $v2 (lambda (- $0 $0))) 1)"
    p = Program.parse(program)
    request = Type.fromstring("inp0:list(int) -> bool")
    print(p)
    likelihood = julia_grammar.logLikelihood(request, p)
    print(likelihood)
    assert likelihood == -29.584370594022218


def sample_wrapper_programs():
    programs = [
        {
            "program": "let $v2, $v3 = rev($inp0 = (rev_fix_param (concat $v2 $v3) $v2 (lambda Const(list(int), Any[])))) in let $v4::list(int) = Const(list(int), Any[]) in let $v5::list(int) = Const(list(int), Any[1]) in let $v6::list(int) = (concat $v4 $v5) in (concat $v3 $v6)",
            "time": 14.128462791442871,
            "logLikelihood": 0.0,
            "logPrior": -16.351702894203257,
        },
        {
            "program": "let $v1, $v2 = rev($inp0 = (rev_fix_param (concat $v1 $v2) $v2 (lambda $0))) in let $v3::list(int) = Const(list(int), Any[]) in let $v4::list(int) = Const(list(int), Any[1]) in let $v5::list(int) = (concat $v3 $v4) in (concat $v2 $v5)",
            "time": 14.270664930343628,
            "logLikelihood": 0.0,
            "logPrior": -19.61171248841022,
        },
        {
            "program": "let $v2, $v3 = rev($inp0 = (rev_fix_param (concat $v2 $v3) $v3 (lambda Const(list(int), Any[])))) in let $v4::list(int) = Const(list(int), Any[]) in let $v5::list(int) = Const(list(int), Any[1]) in let $v6::list(int) = (concat $v4 $v5) in (concat $v2 $v6)",
            "time": 14.286531925201416,
            "logLikelihood": 0.0,
            "logPrior": -16.351702894203257,
        },
        {
            "program": "let $v1, $v2 = rev($inp0 = (rev_fix_param (concat $v1 $v2) $v1 (lambda $0))) in let $v3::list(int) = Const(list(int), Any[]) in let $v4::list(int) = Const(list(int), Any[1]) in let $v5::list(int) = (concat $v3 $v4) in (concat $v1 $v5)",
            "time": 14.27908992767334,
            "logLikelihood": 0.0,
            "logPrior": -19.61171248841022,
        },
        {
            "program": "let $v1::list(int) = Const(list(int), Any[]) in let $v2::list(int) = Const(list(int), Any[1]) in let $v3::list(int) = (concat $v1 $v2) in (concat $inp0 $v3)",
            "time": 13.979617834091187,
            "logLikelihood": 0.0,
            "logPrior": -9.003599420506244,
        },
        {
            "program": "let $v1, $v2 = rev($inp0 = (rev_fix_param (concat $v1 $v2) $v2 (lambda $0))) in let $v3::list(int) = Const(list(int), Any[1]) in (concat $v2 $v3)",
            "time": 13.207619905471802,
            "logLikelihood": 0.0,
            "logPrior": -15.109912778157096,
        },
        {
            "program": "let $v2, $v3 = rev($inp0 = (rev_fix_param (concat $v2 $v3) $v2 (lambda Const(list(int), Any[])))) in let $v4::list(int) = Const(list(int), Any[1]) in (concat $v3 $v4)",
            "time": 12.554029941558838,
            "logLikelihood": 0.0,
            "logPrior": -11.849903183950133,
        },
        {
            "program": "let $v1, $v2 = rev($inp0 = (rev_fix_param (concat $v1 $v2) $v1 (lambda $0))) in let $v3::list(int) = Const(list(int), Any[1]) in (concat $v1 $v3)",
            "time": 13.738729000091553,
            "logLikelihood": 0.0,
            "logPrior": -15.109912778157096,
        },
        {
            "program": "let $v2, $v3 = rev($inp0 = (rev_fix_param (concat $v2 $v3) $v3 (lambda Const(list(int), Any[])))) in let $v4::list(int) = Const(list(int), Any[1]) in (concat $v2 $v4)",
            "time": 13.747699975967407,
            "logLikelihood": 0.0,
            "logPrior": -11.849903183950133,
        },
        {
            "program": "let $v1::list(int) = Const(list(int), Any[1]) in (concat $inp0 $v1)",
            "time": 4.126955986022949,
            "logLikelihood": 0.0,
            "logPrior": -4.501799710253122,
        },
        {
            "program": "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3::list(int) = Const(list(int), Any[]) in let $v4, $v5 = rev($v3 = (concat $v4 $v5)) in let $v6::int = (+ $v1 (length $v4)) in let $v7::list(int) = (cdr $v2) in (cons $v6 $v7)",
            "time": 9.622529983520508,
            "logLikelihood": 0.0,
            "logPrior": -24.36878865053818,
        },
        {
            "program": "let $v1, $v2 = rev($inp0 = (cons $v1 $v2)) in let $v3::int = (car $v2) in let $v5, $v6 = rev($v1 = (rev_fix_param (+ $v5 $v6) $v5 (lambda Const(int, 1)))) in let $v7::int = (- (length $inp0) $v5) in let $v8::int = Const(int, 1) in let $v9::int = (+ $v7 $v8) in (repeat $v3 $v9)",
            "time": 12.727571964263916,
            "logLikelihood": 0.0,
            "logPrior": -31.90963593302679,
        },
        {
            "program": "let $v1::int = Const(int, -5) in let $v3, $v4 = rev($inp0 = (rev_fix_param (map (lambda (* $v3 $0)) $v4) $v3 (lambda Const(int, -1)))) in let $v5::int = (* $v1 $v3) in let $v8, $v9 = rev($inp0 = (rev_fix_param (concat $v8 $v9) $v9 (lambda (cdr $0)))) in let $v10::int = (- $v5 (length $v8)) in (cons $v10 $inp0)",
            "time": 1.8824760913848877,
            "logLikelihood": 0.0,
            "logPrior": -44.06436625591094,
        },
    ]
    return programs


@pytest.mark.parametrize("solution", sample_wrapper_programs())
def test_parsing_wrap(julia_grammar, solution):
    program_str = solution["program"]
    print(program_str)
    p = Program.parse(program_str)
    print(p.show(False))
    assert p.show(False) == program_str
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
            "program": "let $v1 = rev($inp0 = (rows_to_grid $v1)) in let $v2 = rev($v1 = (columns $v2)) in let $v3, $v4 = rev($v1 = (cons $v3 $v4)) in let $v5, $v6 = rev($v3 = (cons $v5 $v6)) in let $v9, $v10 = rev($v6 = (rev_fix_param (concat $v9 $v10) $v10 (lambda (cdr $0)))) in let $v11, $v12 = rev($v10 = (repeat $v11 $v12)) in (car (repeat $v2 $v12))",
            "time": 3.1087260246276855,
            "logLikelihood": 0.0,
            "logPrior": -47.02184524322146,
        },
        {
            "program": "let $v1 = rev($inp0 = (rows_to_grid $v1)) in let $v2 = rev($v1 = (columns $v2)) in let $v3, $v4 = rev($v1 = (cons $v3 $v4)) in let $v5, $v6 = rev($v3 = (cons $v5 $v6)) in let $v7::list(color) = (cdr $v6) in let $v8, $v9 = rev($v7 = (repeat $v8 $v9)) in (car (repeat $v2 $v9))",
            "time": 3.1089580059051514,
            "logLikelihood": 0.0,
            "logPrior": -35.41358480948317,
        },
        {
            "program": "let $v1 = rev($inp0 = (rows_to_grid $v1)) in let $v2 = rev($v1 = (columns $v2)) in let $v3, $v4 = rev($v1 = (cons $v3 $v4)) in let $v5::list(color) = (cdr $v3) in let $v6, $v7 = rev($v5 = (cons $v6 $v7)) in let $v8, $v9 = rev($v7 = (repeat $v8 $v9)) in (car (repeat $v2 $v9))",
            "time": 2.7325570583343506,
            "logLikelihood": 0.0,
            "logPrior": -35.41358480948317,
        },
        {
            "program": "let $v1 = rev($inp0 = (columns_to_grid $v1)) in let $v2 = rev($v1 = (rows $v2)) in let $v3 = rev($inp0 = (rows_to_grid $v3)) in let $v4, $v5 = rev($v3 = (cons $v4 $v5)) in let $v6, $v7 = rev($v4 = (cons $v6 $v7)) in let $v8, $v9 = rev($v7 = (cons $v8 $v9)) in let $v10, $v11 = rev($v9 = (repeat $v10 $v11)) in (car (repeat $v2 $v11))",
            "time": 2.2313830852508545,
            "logLikelihood": 0.0,
            "logPrior": -39.50783276591865,
        },
        {
            "program": "let $v1 = rev($inp0 = (rows_to_grid $v1)) in let $v2 = rev($v1 = (columns $v2)) in let $v3, $v4 = rev($v1 = (cons $v3 $v4)) in let $v5, $v6 = rev($v3 = (cons $v5 $v6)) in let $v7, $v8 = rev($v6 = (cons $v7 $v8)) in let $v9, $v10 = rev($v8 = (repeat $v9 $v10)) in (car (repeat $v2 $v10))",
            "time": 2.2469329833984375,
            "logLikelihood": 0.0,
            "logPrior": -35.3456200608494,
        },
        {
            "program": "let $v1 = rev($inp0 = (rows_to_grid $v1)) in let $v2 = rev($v1 = (rows $v2)) in let $v3 = rev($v2 = (rows_to_grid $v3)) in (columns_to_grid $v3)",
            "time": 1.890024185180664,
            "logLikelihood": 0.0,
            "logPrior": -16.9054879097354,
        },
        {
            "program": "let $v1 = rev($inp0 = (rows_to_grid $v1)) in (columns_to_grid $v1)",
            "time": 1.7431960105895996,
            "logLikelihood": 0.0,
            "logPrior": -8.581062499596893,
        },
        {
            "program": "let $v1 = rev($inp0 = (columns_to_grid $v1)) in (rows_to_grid $v1)",
            "time": 1.2298321723937988,
            "logLikelihood": 0.0,
            "logPrior": -8.581062499596893,
        },
        {
            "program": "let $v1 = rev($inp0 = (rows_to_grid $v1)) in let $v2 = rev($v1 = (columns $v2)) in $v2",
            "time": 1.8264191150665283,
            "logLikelihood": 0.0,
            "logPrior": -8.911696300975652,
        },
        {
            "program": "let $v1 = rev($inp0 = (columns_to_grid $v1)) in let $v2 = rev($v1 = (rows $v2)) in $v2",
            "time": 1.820842981338501,
            "logLikelihood": 0.0,
            "logPrior": -8.911696300975652,
        },
        {
            "program": "let $v1, $v2, $v3 = rev($inp0 = (rev_fix_param (rev_select_grid (lambda (eq? $0 $v1)) $v2 $v3) $v1 (lambda Const(color, 0)))) in \
let $v4, $v5, $v6 = rev($v2 = (repeat_grid $v4 $v5 $v6)) in \
let $v7, $v8, $v9 = rev($v3 = (rev_grid_elements $v7 $v8 $v9)) in \
let $v10 = rev($v7 = (rev_fold_set (lambda (lambda (rev_greedy_cluster (lambda (lambda (any_set (lambda (and (not (gt? (abs (- (tuple2_first (tuple2_first $0)) (tuple2_first (tuple2_first $2)))) 1)) (not (gt? (abs (- (tuple2_second (tuple2_first $0)) (tuple2_second (tuple2_first $2)))) 1)))) $0))) $1 $0))) empty_set $v10)) in \
let $v11 = rev($v10 = (map_set (lambda (map_set (lambda (tuple2 $0 (tuple2_second $1))) (tuple2_first $0))) $v11)) in \
let $v12 = rev($v11 = (map_set (lambda (tuple2 ((lambda ((lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first $0) (tuple2_first $1)) (+ (tuple2_second $0) (tuple2_second $1)))) $1) $0 (lambda (tuple2 (fold (lambda (lambda (if (gt? $0 $1) $1 $0))) (map (lambda (tuple2_first $0)) (collect $0)) max_int) (fold (lambda (lambda (if (gt? $0 $1) $1 $0))) (map (lambda (tuple2_second $0)) (collect $0)) max_int))))) (tuple2_first (tuple2_first $1)))) (tuple2_second (tuple2_first $0))) (tuple2_second $0))) $v12)) in \
let $v13, $v14, $v15 = rev($v12 = (rev_fix_param (rev_select_set (lambda (eq? (tuple2_second (tuple2_first $0)) $v13)) $v14 $v15) $v13 (lambda Const(set(tuple2(int, int)), Set([(0, 0), (0, 2), (2, 0), (1, 1), (0, 1), (2, 2), (2, 1)]))))) in \
let $v16::int = Const(int, 1) in \
let $v17::set(tuple2(tuple2(tuple2(int, int), set(tuple2(int, int))), color)) = (map_set (lambda (tuple2 (tuple2 (tuple2 (+ (tuple2_first (tuple2_first (tuple2_first $0))) $v16) (tuple2_second (tuple2_first (tuple2_first $0)))) (tuple2_second (tuple2_first $0))) (tuple2_second $0))) $v14) in \
let $v18::set(tuple2(tuple2(tuple2(int, int), set(tuple2(int, int))), color)) = (rev_select_set (lambda (eq? (tuple2_second (tuple2_first $0)) $v13)) $v17 $v15) in \
let $v19::set(tuple2(set(tuple2(int, int)), color)) = (map_set (lambda (tuple2 ((lambda ((lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first $0) (tuple2_first $1)) (+ (tuple2_second $0) (tuple2_second $1)))) $1) $0 (lambda (tuple2 (fold (lambda (lambda (if (gt? $0 $1) $1 $0))) (map (lambda (tuple2_first $0)) (collect $0)) max_int) (fold (lambda (lambda (if (gt? $0 $1) $1 $0))) (map (lambda (tuple2_second $0)) (collect $0)) max_int))))) (tuple2_first (tuple2_first $1)))) (tuple2_second (tuple2_first $0))) (tuple2_second $0))) $v18) in \
let $v20::set(set(tuple2(tuple2(int, int), color))) = (map_set (lambda (map_set (lambda (tuple2 $0 (tuple2_second $1))) (tuple2_first $0))) $v19) in \
let $v21::set(tuple2(tuple2(int, int), color)) = (rev_fold_set (lambda (lambda (rev_greedy_cluster (lambda (lambda (any_set (lambda (and (not (gt? (abs (- (tuple2_first (tuple2_first $0)) (tuple2_first (tuple2_first $2)))) 1)) (not (gt? (abs (- (tuple2_second (tuple2_first $0)) (tuple2_second (tuple2_first $2)))) 1)))) $0))) $1 $0))) empty_set $v20) in \
let $v22::grid(color) = (rev_grid_elements $v21 $v8 $v9) in \
let $v23::grid(color) = (repeat_grid $v4 $v5 $v6) in \
(rev_select_grid (lambda (eq? $0 $v1)) $v23 $v22)",
            "time": 1.820842981338501,
            "logLikelihood": 0.0,
            "logPrior": -767.261094215083,
        },
        {
            "program": "let $v1 = rev($inp0 = (tuple2_first $v1)) in let $v2::grid(color) = (tuple2_first $v1) in let $v3::list(t1) = Const(list(t1), Main.solver.PatternWrapper([any_object, any_object, any_object, any_object, any_object, any_object, any_object, any_object, any_object, any_object, any_object, any_object, any_object, any_object, any_object])) in let $v4::t0 = (reverse $v3) in let $v5::tuple2(t0, grid(color)) = (tuple2 $v4 $v2) in let $v6::grid(color) = (tuple2_second $v5) in let $v7::list(list(color)) = (rows $v6) in (rows_to_grid $v7)",
            "time": 1.820842981338501,
            "logLikelihood": 0.0,
            "logPrior": -31.404177758695795,
        },
    ]
    return programs


@pytest.mark.parametrize("solution", sample_arc_programs())
def test_parsing_arc(arc_grammar, solution):
    program_str = solution["program"]
    print(program_str)
    p = Program.parse(program_str)
    print(p.show(False))
    assert p.show(False) == program_str
    request = TypeNamedArgsConstructor(
        ARROW,
        {"inp0": tgrid(tcolor)},
        tgrid(tcolor),
    )
    likelihood = arc_grammar.logLikelihood(request, p)
    print(likelihood)
    assert likelihood == solution["logPrior"]


def sample_lambda_wrapper_programs():
    programs = [
        {
            "program": "((lambda ((lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first $0) (tuple2_first $1)) (+ (tuple2_second $0) (tuple2_second $1)))) $1) $0 (lambda (tuple2 (fold (lambda (lambda (if (gt? $0 $1) $1 $0))) (map (lambda (tuple2_first $0)) (collect $0)) max_int) (fold (lambda (lambda (if (gt? $0 $1) $1 $0))) (map (lambda (tuple2_second $0)) (collect $0)) max_int))))) (tuple2_first $inp0))) (tuple2_second $inp0))",
            "time": 3.1087260246276855,
            "logLikelihood": 0.0,
            "logPrior": -162.42083505541854,
            "request": TypeNamedArgsConstructor(
                ARROW,
                {"inp0": ttuple2(ttuple2(tint, tint), tset(ttuple2(tint, tint)))},
                tset(ttuple2(tint, tint)),
            ),
        },
        {
            "program": "let $v1 = rev($inp0 = ((lambda ((lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first $0) (tuple2_first $1)) (+ (tuple2_second $0) (tuple2_second $1)))) $1) $0 (lambda (tuple2 (fold (lambda (lambda (if (gt? $0 $1) $1 $0))) (map (lambda (tuple2_first $0)) (collect $0)) max_int) (fold (lambda (lambda (if (gt? $0 $1) $1 $0))) (map (lambda (tuple2_second $0)) (collect $0)) max_int))))) (tuple2_first $v1))) (tuple2_second $v1))) in $v1",
            "time": 3.1087260246276855,
            "logLikelihood": 0.0,
            "logPrior": -162.09228447034852,
            "request": TypeNamedArgsConstructor(
                ARROW,
                {"inp0": tset(ttuple2(tint, tint))},
                ttuple2(ttuple2(tint, tint), tset(ttuple2(tint, tint))),
            ),
        },
    ]
    return programs


@pytest.mark.parametrize("solution", sample_lambda_wrapper_programs())
def test_parsing_lambda_wrappers(arc_grammar, solution):
    program_str = solution["program"]
    print(program_str)
    p = Program.parse(program_str)
    print(p.show(False))
    assert p.show(False) == program_str

    likelihood = arc_grammar.logLikelihood(solution["request"], p)
    print(likelihood)
    assert likelihood == solution["logPrior"]

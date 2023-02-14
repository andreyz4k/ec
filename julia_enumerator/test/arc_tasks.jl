
using Test

using JSON
using solver: load_problems, enumerate_for_task

@testset "Arc tasks" begin
    sample_payload = Dict{String,Any}(
        "DSL" => Dict{String,Any}(
            "logVariable" => 0.16101400554180145,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => -0.24745267629623413,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.026026399806141853,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.10340426117181778,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "t0 -> (t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3219979405403137,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.16545234620571136,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.01821419596672058,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.10827741771936417,
                    "expression" => "fold",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t1 -> (t0 -> t1 -> t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.20805110037326813,
                    "expression" => "fold_h",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> list(t1) -> (t0 -> t1 -> t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.030056603252887726,
                    "expression" => "fold_v",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> list(t1) -> (t0 -> t1 -> t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5987176895141602,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.37945106625556946,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.26536065340042114,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.30715078115463257,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.09580466151237488,
                    "expression" => "+",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2077680230140686,
                    "expression" => "-",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.39517727494239807,
                    "expression" => "empty",
                    "is_reversible" => false,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.24876078963279724,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.21121810376644135,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.7765527963638306,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1657254993915558,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5649275183677673,
                    "expression" => "*",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.29441311955451965,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.09284287691116333,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5850135087966919,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.12005873024463654,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.161600261926651,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.15995901823043823,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3666248917579651,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.03589197248220444,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3978639245033264,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1571362018585205,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.18729381263256073,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.24096974730491638,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2926778495311737,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.46768778562545776,
                    "expression" => "0",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.11917536705732346,
                    "expression" => "1",
                    "is_reversible" => false,
                    "type" => "int",
                ),
            ],
        ),
        "type_weights" => Dict{String,Any}(
            "int" => 1.0,
            "list" => 1.0,
            "color" => 1.0,
            "bool" => 1.0,
            "float" => 1.0,
            "grid" => 1.0,
        ),
        "programTimeout" => 3.0,
        "timeout" => 40,
        "verbose" => false,
        "shatter" => 10,
    )

    function create_task(task_dict)
        result = copy(sample_payload)
        result["task"] = task_dict
        result["name"] = task_dict["name"]
        return result
    end

    function create_arc_task(filename)
        arc_task = JSON.parsefile("../../dreamcoder/domains/arc/ARC/data/training/" * filename)
        task_dict = Dict{String,Any}(
            "name" => filename,
            "maximumFrontier" => 10,
            "extras" => 5,
            "request" => Dict{String,Any}(
                "arguments" => Dict{String,Any}(
                    "inp0" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "color")],
                        "constructor" => "grid",
                    ),
                ),
                "output" => Dict{String,Any}(
                    "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "color")],
                    "constructor" => "grid",
                ),
                "constructor" => "->",
            ),
            "specialTask" => "arc",
        )
        task_dict["examples"] = Any[
            Dict{String,Any}("inputs" => Dict{String,Any}("inp0" => example["input"]), "output" => example["output"]) for example in arc_task["train"]
        ]
        task_dict["test_examples"] = Any[
            Dict{String,Any}("inputs" => Dict{String,Any}("inp0" => example["input"]), "output" => example["output"]) for example in arc_task["test"]
        ]
        return create_task(task_dict)
    end

    @testset "a85d4709.json" begin
        payload = create_arc_task("a85d4709.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) == 0
        @test number_enumerated >= 1
        @test number_enumerated < 5000
    end

    @testset "5c2c9af4.json" begin
        payload = create_arc_task("5c2c9af4.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) == 0
        @test number_enumerated >= 1
        @test number_enumerated < 5000
    end

    @testset "23581191.json" begin
        payload = create_arc_task("23581191.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) == 0
        @test number_enumerated >= 1
        @test number_enumerated < 10000
    end

    @testset "4258a5f9.json" begin
        payload = create_arc_task("4258a5f9.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) == 0
        @test number_enumerated >= 1
        @test number_enumerated < 10000
    end

    @testset "f25ffba3.json" begin
        payload = create_arc_task("f25ffba3.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) == 0
        @test number_enumerated >= 1
        @test number_enumerated < 10000
    end

    @testset "74dd1130.json" begin
        payload = create_arc_task("74dd1130.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) >= 8
        @test number_enumerated >= 1
        @test number_enumerated < 2000
    end

    @testset "7837ac64.json" begin
        payload = create_arc_task("7837ac64.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) == 0
        @test number_enumerated >= 1
        @test number_enumerated < 10000
    end
end

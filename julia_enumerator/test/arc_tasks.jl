
using Test

using JSON
using solver: load_problems, enumerate_for_task

@testset "Arc tasks" begin
    sample_payload = Dict{String,Any}(
        "DSL" => Dict{String,Any}(
            "logVariable" => 0.004643052816390991,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => 0.08516222983598709,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.007101915776729584,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5722317695617676,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "t0 -> (t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.04759052395820618,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4778462052345276,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.16173744201660156,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4394384026527405,
                    "expression" => "fold",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t1 -> (t0 -> t1 -> t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.36862489581108093,
                    "expression" => "fold_h",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> list(t1) -> (t0 -> t1 -> t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05522885173559189,
                    "expression" => "fold_v",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> list(t1) -> (t0 -> t1 -> t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2832038700580597,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2645815908908844,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.43067336082458496,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3024436831474304,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.08787669241428375,
                    "expression" => "+",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.21282225847244263,
                    "expression" => "-",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0012596286833286285,
                    "expression" => "empty",
                    "is_reversible" => false,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.19104759395122528,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5415846705436707,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.27894705533981323,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.13995766639709473,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.7610877156257629,
                    "expression" => "*",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.09879685938358307,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2819819450378418,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.06551016867160797,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.22693437337875366,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1811308115720749,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.20824111998081207,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5051954388618469,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.28117895126342773,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.07839452475309372,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.14351551234722137,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.13544370234012604,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.14936356246471405,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3992577791213989,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.19241996109485626,
                    "expression" => "0",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3595008850097656,
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
        @test number_enumerated < 10000
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

    @testset "6fa7a44f.json" begin
        payload = create_arc_task("6fa7a44f.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) > 0
        @test number_enumerated >= 1
        @test number_enumerated < 10000
    end

    @testset "c9e6f938.json" begin
        payload = create_arc_task("c9e6f938.json")
        @info payload["name"]
        for prod in payload["DSL"]["productions"]
            prod["logProbability"] = 0.0
        end
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) > 0
        @test number_enumerated >= 1
        @test number_enumerated < 10000
    end

    @testset "bbc9ae5d.json" begin
        payload = create_arc_task("bbc9ae5d.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated =
            @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
        @test length(solutions) == 0
        @test number_enumerated >= 1
        @test number_enumerated < 10000
    end
end

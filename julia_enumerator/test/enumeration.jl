
using Test

using solver: load_problems, enumerate_for_task

@testset "Enumeration" begin
    sample_payload = Dict{String,Any}(
        "DSL" => Dict{String,Any}(
            "logVariable" => 0.0,
            "logFreeVar" => 3.0,
            "logLambda" => -3.0,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "empty",
                    "is_reversible" => false,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "0",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "1",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.0,
                    "expression" => "rev_fix_param",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
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
            "tuple2" => 1.0,
            "tuple3" => 1.0,
            "coord" => 1.0,
            "set" => 1.0,
        ),
        "programTimeout" => 3.0,
        "timeout" => 30,
        "verbose" => false,
        "shatter" => 10,
    )

    function create_task(task_dict)
        result = deepcopy(sample_payload)
        result["task"] = task_dict
        result["name"] = task_dict["name"]
        return result
    end

    @testset "try_enumerate add-k with k=1" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "add-k with k=1",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[4, 5, 5, 14, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 4, 4, 13, 6]),
                    ),
                    Dict{String,Any}("output" => Any[], "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}(
                        "output" => Any[1, 3, 13, 3, 12, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 2, 12, 2, 11, 0]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[5, 13, 16],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 12, 15]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[16, 3, 17, 3, 6, 16, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 2, 16, 2, 5, 15, 6]),
                    ),
                    Dict{String,Any}("output" => Any[9, 14, 7], "inputs" => Dict{String,Any}("inp0" => Any[8, 13, 6])),
                    Dict{String,Any}(
                        "output" => Any[1, 12, 8, 10, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 11, 7, 9, 3]),
                    ),
                    Dict{String,Any}("output" => Any[10, 11, 5], "inputs" => Dict{String,Any}("inp0" => Any[9, 10, 4])),
                    Dict{String,Any}(
                        "output" => Any[10, 2, 14, 11, 14],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 1, 13, 10, 13]),
                    ),
                    Dict{String,Any}("output" => Any[10, 7], "inputs" => Dict{String,Any}("inp0" => Any[9, 6])),
                    Dict{String,Any}("output" => Any[], "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}(
                        "output" => Any[8, 10, 9, 2, 13, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 9, 8, 1, 12, 3]),
                    ),
                    Dict{String,Any}("output" => Any[5, 15, 2], "inputs" => Dict{String,Any}("inp0" => Any[4, 14, 1])),
                    Dict{String,Any}("output" => Any[7, 3, 14], "inputs" => Dict{String,Any}("inp0" => Any[6, 2, 13])),
                    Dict{String,Any}("output" => Any[15], "inputs" => Dict{String,Any}("inp0" => Any[14])),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 0
        @test number_enumerated < 20000
    end

    @testset "try_enumerate empty" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "empty",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 3])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[0])),
                    Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[1, 1, 2, 1])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[7, 7, 3, 2])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[10, 10, 6, 13, 4])),
                    Dict{String,Any}(
                        "output" => false,
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 7, 16, 11, 10, 3, 15]),
                    ),
                    Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[4])),
                    Dict{String,Any}(
                        "output" => false,
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 0, 14, 0, 2, 12]),
                    ),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[12, 15])),
                    Dict{String,Any}(
                        "output" => false,
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 16, 2, 5, 15, 6, 7]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> bool",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated < 20000
    end

    @testset "try_enumerate append-index-k with k=5" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "append-index-k with k=5",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[11, 9, 15, 7, 2, 3, 11, 7, 1, 2, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 9, 15, 7, 2, 3, 11, 7, 1, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[11, 9, 16, 5, 5, 16, 11, 9, 5],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 9, 16, 5, 5, 16, 11, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[12, 12, 3, 2, 14, 15, 10, 11, 4, 11, 15, 2, 14],
                        "inputs" => Dict{String,Any}("inp0" => Any[12, 12, 3, 2, 14, 15, 10, 11, 4, 11, 15, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[4, 6, 1, 7, 1, 13, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 6, 1, 7, 1, 13]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[8, 16, 5, 13, 14, 12, 6, 0, 14],
                        "inputs" => Dict{String,Any}("inp0" => Any[8, 16, 5, 13, 14, 12, 6, 0]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[9, 11, 8, 0, 7, 8, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 11, 8, 0, 7, 8]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[12, 4, 7, 10, 13, 3, 14, 4, 12, 4, 13],
                        "inputs" => Dict{String,Any}("inp0" => Any[12, 4, 7, 10, 13, 3, 14, 4, 12, 4]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 12, 0, 0, 15, 9, 9, 9, 2, 15],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 12, 0, 0, 15, 9, 9, 9, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[12, 5, 6, 5, 15, 2, 10, 7, 7, 2, 13, 10, 15],
                        "inputs" => Dict{String,Any}("inp0" => Any[12, 5, 6, 5, 15, 2, 10, 7, 7, 2, 13, 10]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[13, 0, 16, 8, 9, 10, 16, 7, 9],
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 0, 16, 8, 9, 10, 16, 7]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[16, 15, 7, 8, 2, 5, 14, 15, 8, 8, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[16, 15, 7, 8, 2, 5, 14, 15, 8, 8]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[7, 7, 5, 15, 2, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 7, 5, 15, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[13, 2, 13, 16, 1, 3, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 2, 13, 16, 1, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[6, 4, 15, 14, 7, 12, 3, 0, 4, 16, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 4, 15, 14, 7, 12, 3, 0, 4, 16]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15, 15, 9, 4, 2, 2, 14, 13, 5, 4, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 15, 9, 4, 2, 2, 14, 13, 5, 4]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 2
        @test number_enumerated < 10000
    end

    @testset "try_enumerate len" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "len",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}("output" => 3, "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 3])),
                    Dict{String,Any}("output" => 1, "inputs" => Dict{String,Any}("inp0" => Any[0])),
                    Dict{String,Any}("output" => 4, "inputs" => Dict{String,Any}("inp0" => Any[1, 1, 2, 1])),
                    Dict{String,Any}("output" => 2, "inputs" => Dict{String,Any}("inp0" => Any[2, 9])),
                    Dict{String,Any}("output" => 1, "inputs" => Dict{String,Any}("inp0" => Any[0])),
                    Dict{String,Any}(
                        "output" => 7,
                        "inputs" => Dict{String,Any}("inp0" => Any[10, 14, 8, 2, 12, 10, 3]),
                    ),
                    Dict{String,Any}("output" => 0, "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}("output" => 2, "inputs" => Dict{String,Any}("inp0" => Any[2, 7])),
                    Dict{String,Any}("output" => 5, "inputs" => Dict{String,Any}("inp0" => Any[13, 11, 10, 12, 13])),
                    Dict{String,Any}("output" => 1, "inputs" => Dict{String,Any}("inp0" => Any[15])),
                    Dict{String,Any}("output" => 5, "inputs" => Dict{String,Any}("inp0" => Any[5, 6, 2, 8, 9])),
                    Dict{String,Any}("output" => 0, "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}("output" => 1, "inputs" => Dict{String,Any}("inp0" => Any[3])),
                    Dict{String,Any}("output" => 3, "inputs" => Dict{String,Any}("inp0" => Any[7, 14, 11])),
                    Dict{String,Any}("output" => 6, "inputs" => Dict{String,Any}("inp0" => Any[15, 15, 0, 1, 3, 16])),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> int",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated <= 10000
    end

    @testset "try_enumerate is-mod-k with k=1" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "is-mod-k with k=1",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => true,
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 7, 16, 11, 10, 3, 15]),
                    ),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[4])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[6, 0, 14, 0, 2, 12])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[0, 6, 4, 12, 15])),
                    Dict{String,Any}(
                        "output" => true,
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 16, 2, 5, 15, 6, 7]),
                    ),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[6, 11, 0, 11, 7, 9])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[9, 10, 4])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[1, 13, 10, 13])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[6, 1, 13, 7])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[1, 12, 3])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[14, 1])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[2, 13, 3])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[14, 13, 12, 6])),
                    Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[6, 14, 7])),
                    Dict{String,Any}(
                        "output" => true,
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 14, 7, 1, 0, 11, 0]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> bool",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 5
        @test number_enumerated <= 10000
    end

    @testset "prepend-k with k=0" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "prepend-k with k=0",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[0, 12, 0, 1, 9, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[12, 0, 1, 9, 4]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 9, 10, 8],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 10, 8]),
                    ),
                    Dict{String,Any}("output" => Any[0], "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}(
                        "output" => Any[0, 5, 11, 9, 0, 7, 1, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 11, 9, 0, 7, 1, 7]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 14, 0, 3],
                        "inputs" => Dict{String,Any}("inp0" => Any[14, 0, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 6, 9, 8, 16, 1, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 9, 8, 16, 1, 2]),
                    ),
                    Dict{String,Any}("output" => Any[0, 16, 11], "inputs" => Dict{String,Any}("inp0" => Any[16, 11])),
                    Dict{String,Any}(
                        "output" => Any[0, 8, 0, 16, 10, 7, 12, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[8, 0, 16, 10, 7, 12, 10]),
                    ),
                    Dict{String,Any}("output" => Any[0, 12, 4], "inputs" => Dict{String,Any}("inp0" => Any[12, 4])),
                    Dict{String,Any}("output" => Any[0, 1], "inputs" => Dict{String,Any}("inp0" => Any[1])),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 5, 13, 1, 3],
                        "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 5, 13, 1, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 6, 8, 0, 11],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 8, 0, 11]),
                    ),
                    Dict{String,Any}("output" => Any[0, 16], "inputs" => Dict{String,Any}("inp0" => Any[16])),
                    Dict{String,Any}(
                        "output" => Any[0, 4, 14, 11, 0],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 14, 11, 0]),
                    ),
                    Dict{String,Any}("output" => Any[0, 5], "inputs" => Dict{String,Any}("inp0" => Any[5])),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated <= 10000
    end

    @testset "remove empty lists" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "remove empty lists",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[Any[false, false, false], Any[false], Any[true], Any[true]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[false, false, false], Any[false], Any[true], Any[true]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[false, true, false], Any[true, false, false], Any[true, false]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[false, true, false], Any[], Any[true, false, false], Any[true, false]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[false], Any[true, true, true], Any[true]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[false], Any[], Any[true, true, true], Any[true]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[true, false], Any[true, false], Any[true, true, false]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[], Any[true, false], Any[true, false], Any[true, true, false]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[false], Any[false, false], Any[true, true, true]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[false], Any[], Any[false, false], Any[true, true, true]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[false, true, true], Any[false, true], Any[true, false]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[false, true, true], Any[], Any[false, true], Any[true, false]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[
                            Any[false, false, false],
                            Any[false, true, true],
                            Any[false, false, true],
                            Any[false, true],
                        ],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[
                                Any[false, false, false],
                                Any[false, true, true],
                                Any[false, false, true],
                                Any[false, true],
                            ],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[true, true], Any[true], Any[true, true]],
                        "inputs" =>
                            Dict{String,Any}("inp0" => Any[Any[true, true], Any[true], Any[true, true], Any[]]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[true, true], Any[true, false], Any[false]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[], Any[true, true], Any[true, false], Any[false]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[true], Any[true, true, false], Any[false, true]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[true], Any[], Any[true, true, false], Any[false, true]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[true, true, true], Any[true, false]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[true, true, true], Any[], Any[true, false], Any[]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[true, true, false], Any[false], Any[false, true, false]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[], Any[true, true, false], Any[false], Any[false, true, false]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[false], Any[true, false, true], Any[false, true, false], Any[false]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[false], Any[true, false, true], Any[false, true, false], Any[false]],
                        ),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[false, false], Any[false], Any[false]],
                        "inputs" =>
                            Dict{String,Any}("inp0" => Any[Any[false, false], Any[false], Any[], Any[false]]),
                    ),
                    Dict{String,Any}(
                        "output" =>
                            Any[Any[false, false, true], Any[true, true], Any[true], Any[false, true, true]],
                        "inputs" => Dict{String,Any}(
                            "inp0" => Any[Any[false, false, true], Any[true, true], Any[true], Any[false, true, true]],
                        ),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(list(bool)) -> list(list(bool))",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) == 0
        @test number_enumerated >= 2000
    end

    @testset "prepend-index-k with k=3" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "prepend-index-k with k=3",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[9, 15, 12, 9, 14, 7, 9],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 12, 9, 14, 7, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[1, 7, 8, 1, 6, 16, 11],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 8, 1, 6, 16, 11]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[1, 11, 3, 1, 8, 15, 7, 7, 14, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 3, 1, 8, 15, 7, 7, 14, 1]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15, 9, 11, 15, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 11, 15, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[6, 11, 3, 6],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 3, 6]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[5, 6, 8, 5, 6, 10, 3],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 8, 5, 6, 10, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[8, 4, 3, 8, 13, 2, 12, 6, 9, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 3, 8, 13, 2, 12, 6, 9, 1]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[13, 3, 15, 13, 1, 8, 13, 9, 6],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 15, 13, 1, 8, 13, 9, 6]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 6, 3, 0, 5, 4, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 3, 0, 5, 4, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15, 6, 10, 15, 8, 14, 3, 4, 16, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 10, 15, 8, 14, 3, 4, 16, 1]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[5, 5, 10, 5, 16],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 10, 5, 16]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 8, 14, 3, 5, 11],
                        "inputs" => Dict{String,Any}("inp0" => Any[8, 14, 3, 5, 11]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 11, 10, 3, 14, 0, 5],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 10, 3, 14, 0, 5]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[14, 15, 6, 14, 4, 12, 0, 15],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 6, 14, 4, 12, 0, 15]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[6, 13, 16, 6, 9, 16, 6, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 16, 6, 9, 16, 6, 10]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) > 0
        @test number_enumerated <= 20000
    end

    @testset "range +1 maximum list" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "range +1 maximum list",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 8]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 9, 9, 5, 5]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 0, 6, 7]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 10, 5]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 9, 1]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[10, 8, 0]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 9, 3, 0, 5]),
                    ),
                    Dict{String,Any}("output" => Any[0, 1, 2, 3], "inputs" => Dict{String,Any}("inp0" => Any[3, 0])),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[10, 0]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 1, 5]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 8, 0]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6],
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 2, 6]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5, 6, 7, 8],
                        "inputs" => Dict{String,Any}("inp0" => Any[8, 0]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 2, 3, 4, 5],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 5, 3, 4]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) == 0
        @test number_enumerated >= 600
    end

    @testset "drop-k with k=5" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "drop-k with k=5",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[7, 2, 11, 14, 6, 7, 11],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 6, 2, 1, 7, 7, 2, 11, 14, 6, 7, 11]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[11, 15, 11, 2, 7, 8],
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 1, 12, 11, 6, 11, 15, 11, 2, 7, 8]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[5, 6, 0, 6, 3, 16],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 10, 1, 4, 3, 5, 6, 0, 6, 3, 16]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[16, 12, 9, 2, 7, 13],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 10, 1, 5, 6, 16, 12, 9, 2, 7, 13]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 15, 11, 11, 14],
                        "inputs" => Dict{String,Any}("inp0" => Any[1, 8, 14, 3, 14, 3, 15, 11, 11, 14]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[9, 9, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[14, 2, 8, 4, 1, 9, 9, 4]),
                    ),
                    Dict{String,Any}("output" => Any[], "inputs" => Dict{String,Any}("inp0" => Any[4, 14, 0, 12, 7])),
                    Dict{String,Any}(
                        "output" => Any[12],
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 9, 16, 2, 7, 12]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 8, 0, 13],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 8, 7, 16, 13, 3, 8, 0, 13]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[6, 2, 11, 4, 11],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 15, 0, 1, 8, 6, 2, 11, 4, 11]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0, 4, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 16, 16, 16, 6, 0, 4, 7]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[9, 1, 13, 4, 8, 6],
                        "inputs" => Dict{String,Any}("inp0" => Any[16, 7, 3, 14, 4, 9, 1, 13, 4, 8, 6]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[5],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 13, 16, 12, 4, 5]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[11, 9],
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 11, 10, 7, 13, 11, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[7, 11],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 15, 3, 15, 7, 7, 11]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) > 0
        @test number_enumerated <= 20000
    end

    @testset "product" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "product",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}("output" => 6, "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 3])),
                    Dict{String,Any}("output" => 0, "inputs" => Dict{String,Any}("inp0" => Any[0])),
                    Dict{String,Any}("output" => 2, "inputs" => Dict{String,Any}("inp0" => Any[1, 1, 2, 1])),
                    Dict{String,Any}("output" => 105, "inputs" => Dict{String,Any}("inp0" => Any[7, 15])),
                    Dict{String,Any}("output" => 105, "inputs" => Dict{String,Any}("inp0" => Any[15, 7])),
                    Dict{String,Any}("output" => 891, "inputs" => Dict{String,Any}("inp0" => Any[11, 9, 9])),
                    Dict{String,Any}("output" => 84, "inputs" => Dict{String,Any}("inp0" => Any[7, 1, 6, 2])),
                    Dict{String,Any}("output" => 6, "inputs" => Dict{String,Any}("inp0" => Any[6])),
                    Dict{String,Any}(
                        "output" => 743424,
                        "inputs" => Dict{String,Any}("inp0" => Any[8, 6, 8, 11, 11, 16]),
                    ),
                    Dict{String,Any}(
                        "output" => 483840,
                        "inputs" => Dict{String,Any}("inp0" => Any[10, 6, 8, 4, 6, 6, 7]),
                    ),
                    Dict{String,Any}("output" => 0, "inputs" => Dict{String,Any}("inp0" => Any[16, 1, 14, 0, 12])),
                    Dict{String,Any}(
                        "output" => 0,
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 4, 11, 12, 15, 5, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => 3243240,
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 5, 6, 11, 6, 13, 14]),
                    ),
                    Dict{String,Any}("output" => 1755, "inputs" => Dict{String,Any}("inp0" => Any[3, 1, 5, 9, 13])),
                    Dict{String,Any}("output" => 34320, "inputs" => Dict{String,Any}("inp0" => Any[3, 10, 8, 13, 11])),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> int",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) == 0
        @test number_enumerated >= 600
    end

    @testset "keep gt 3" begin
        payload = Dict{String,Any}(
            "DSL" => Dict{String,Any}(
                "logVariable" => -0.03174869831458027,
                "logFreeVar" => 3.0,
                "logLambda" => -3.0,
                "productions" => Any[
                    Dict{String,Any}(
                        "logProbability" => -1.4821678103968758,
                        "expression" => "#(lambda (car (cdr \$0)))",
                        "is_reversible" => false,
                        "type" => "list(t0) -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -2.068082438146603,
                        "expression" => "map",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.5939351955059275,
                        "expression" => "unfold",
                        "is_reversible" => false,
                        "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -2.050563671737442,
                        "expression" => "range",
                        "is_reversible" => true,
                        "type" => "int -> list(int)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.5840159945493908,
                        "expression" => "index",
                        "is_reversible" => false,
                        "type" => "int -> list(t0) -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -2.3058577296714104,
                        "expression" => "fold",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.7955641328246412,
                        "expression" => "length",
                        "is_reversible" => false,
                        "type" => "list(t0) -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.9136493444752092,
                        "expression" => "if",
                        "is_reversible" => false,
                        "type" => "bool -> t0 -> t0 -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.009857755313718,
                        "expression" => "+",
                        "is_reversible" => true,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.0129600998058055,
                        "expression" => "-",
                        "is_reversible" => false,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.5742454266676211,
                        "expression" => "empty",
                        "is_reversible" => false,
                        "type" => "list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.36056316028468416,
                        "expression" => "cons",
                        "is_reversible" => true,
                        "type" => "t0 -> list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.5549269243844543,
                        "expression" => "car",
                        "is_reversible" => false,
                        "type" => "list(t0) -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1856590085931913,
                        "expression" => "cdr",
                        "is_reversible" => false,
                        "type" => "list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.06539517097987257,
                        "expression" => "empty?",
                        "is_reversible" => false,
                        "type" => "list(t0) -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.0121675288239347,
                        "expression" => "0",
                        "is_reversible" => false,
                        "type" => "int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.9721603656086466,
                        "expression" => "1",
                        "is_reversible" => false,
                        "type" => "int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.9524741560775674,
                        "expression" => "*",
                        "is_reversible" => true,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.0137108423558923,
                        "expression" => "mod",
                        "is_reversible" => false,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.09705276526600581,
                        "expression" => "gt?",
                        "is_reversible" => false,
                        "type" => "int -> int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.09703497568480257,
                        "expression" => "eq?",
                        "is_reversible" => false,
                        "type" => "t0 -> t0 -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.03260332440026348,
                        "expression" => "is-prime",
                        "is_reversible" => false,
                        "type" => "int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.09553399447374034,
                        "expression" => "is-square",
                        "is_reversible" => false,
                        "type" => "int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.5694639516571502,
                        "expression" => "repeat",
                        "is_reversible" => true,
                        "type" => "t0 -> int -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.3252577197198105,
                        "expression" => "concat",
                        "is_reversible" => true,
                        "type" => "list(t0) -> list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 1.0,
                        "expression" => "rev_fix_param",
                        "is_reversible" => true,
                        "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                    ),
                ],
            ),
            "type_weights" => Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "keep gt 3",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}("output" => Any[], "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 3, 2, 2])),
                    Dict{String,Any}("output" => Any[6], "inputs" => Dict{String,Any}("inp0" => Any[1, 0, 0, 6, 0])),
                    Dict{String,Any}("output" => Any[6, 6], "inputs" => Dict{String,Any}("inp0" => Any[6, 0, 0, 6, 3])),
                    Dict{String,Any}(
                        "output" => Any[5, 5, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 2, 0, 5, 4]),
                    ),
                    Dict{String,Any}("output" => Any[5], "inputs" => Dict{String,Any}("inp0" => Any[3, 5, 0, 0, 0])),
                    Dict{String,Any}("output" => Any[6, 5], "inputs" => Dict{String,Any}("inp0" => Any[3, 1, 6, 0, 5])),
                    Dict{String,Any}(
                        "output" => Any[6, 4, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 3, 6, 4, 4]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[5, 5, 5],
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 5, 5, 3, 5]),
                    ),
                    Dict{String,Any}("output" => Any[6, 5], "inputs" => Dict{String,Any}("inp0" => Any[3, 6, 2, 3, 5])),
                    Dict{String,Any}(
                        "output" => Any[4, 5, 6],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 5, 6, 2, 1]),
                    ),
                    Dict{String,Any}("output" => Any[6, 4], "inputs" => Dict{String,Any}("inp0" => Any[0, 0, 6, 4, 0])),
                    Dict{String,Any}("output" => Any[4, 4], "inputs" => Dict{String,Any}("inp0" => Any[3, 1, 0, 4, 4])),
                    Dict{String,Any}(
                        "output" => Any[5, 6, 5],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 6, 5, 2, 3]),
                    ),
                    Dict{String,Any}("output" => Any[6], "inputs" => Dict{String,Any}("inp0" => Any[0, 6, 3, 3, 0])),
                    Dict{String,Any}("output" => Any[6, 5], "inputs" => Dict{String,Any}("inp0" => Any[6, 2, 5, 3, 2])),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
            "name" => "keep gt 3",
            "programTimeout" => 3.0,
            "timeout" => 20,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) == 0
        @test number_enumerated >= 600
    end

    @testset "modulo-k with k=5" begin
        payload = Dict{String,Any}(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "logFreeVar" => 3.0,
                "logLambda" => -3.0,
                "productions" => Any[
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "map",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "unfold",
                        "is_reversible" => false,
                        "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "range",
                        "is_reversible" => true,
                        "type" => "int -> list(int)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "index",
                        "is_reversible" => false,
                        "type" => "int -> list(t0) -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "fold",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "length",
                        "is_reversible" => false,
                        "type" => "list(t0) -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "if",
                        "is_reversible" => false,
                        "type" => "bool -> t0 -> t0 -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "+",
                        "is_reversible" => true,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "-",
                        "is_reversible" => false,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "empty",
                        "is_reversible" => false,
                        "type" => "list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "cons",
                        "is_reversible" => true,
                        "type" => "t0 -> list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "car",
                        "is_reversible" => false,
                        "type" => "list(t0) -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "cdr",
                        "is_reversible" => false,
                        "type" => "list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "empty?",
                        "is_reversible" => false,
                        "type" => "list(t0) -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "0",
                        "is_reversible" => false,
                        "type" => "int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "1",
                        "is_reversible" => false,
                        "type" => "int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "*",
                        "is_reversible" => true,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "mod",
                        "is_reversible" => false,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "gt?",
                        "is_reversible" => false,
                        "type" => "int -> int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "eq?",
                        "is_reversible" => false,
                        "type" => "t0 -> t0 -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "is-prime",
                        "is_reversible" => false,
                        "type" => "int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "is-square",
                        "is_reversible" => false,
                        "type" => "int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "repeat",
                        "is_reversible" => true,
                        "type" => "t0 -> int -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "concat",
                        "is_reversible" => true,
                        "type" => "list(t0) -> list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 1.0,
                        "expression" => "rev_fix_param",
                        "is_reversible" => true,
                        "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                    ),
                ],
            ),
            "type_weights" => Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "modulo-k with k=5",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}("output" => Any[0], "inputs" => Dict{String,Any}("inp0" => Any[15])),
                    Dict{String,Any}("output" => Any[0], "inputs" => Dict{String,Any}("inp0" => Any[10])),
                    Dict{String,Any}("output" => Any[], "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}(
                        "output" => Any[0, 1, 0, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 6, 0, 9]),
                    ),
                    Dict{String,Any}("output" => Any[2, 0], "inputs" => Dict{String,Any}("inp0" => Any[7, 15])),
                    Dict{String,Any}("output" => Any[], "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}("output" => Any[1], "inputs" => Dict{String,Any}("inp0" => Any[11])),
                    Dict{String,Any}("output" => Any[3], "inputs" => Dict{String,Any}("inp0" => Any[13])),
                    Dict{String,Any}("output" => Any[2], "inputs" => Dict{String,Any}("inp0" => Any[7])),
                    Dict{String,Any}(
                        "output" => Any[2, 2, 3, 0, 3, 0, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 2, 13, 0, 13, 5, 2]),
                    ),
                    Dict{String,Any}("output" => Any[2, 1, 2], "inputs" => Dict{String,Any}("inp0" => Any[2, 6, 12])),
                    Dict{String,Any}("output" => Any[0, 0], "inputs" => Dict{String,Any}("inp0" => Any[0, 10])),
                    Dict{String,Any}(
                        "output" => Any[2, 4, 0, 1, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 4, 0, 1, 11]),
                    ),
                    Dict{String,Any}("output" => Any[], "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}(
                        "output" => Any[1, 2, 1, 1, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 2, 16, 6, 4]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
            "name" => "modulo-k with k=5",
            "programTimeout" => 3.0,
            "timeout" => 40,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) == 0
        @test number_enumerated >= 600
    end

    @testset "prepend-k with k=3" begin
        payload = Dict{String,Any}(
            "DSL" => Dict{String,Any}(
                "logVariable" => -0.16180989146232605,
                "logFreeVar" => 3.0,
                "logLambda" => -3.0,
                "productions" => Any[
                    Dict{String,Any}(
                        "logProbability" => -0.17757169902324677,
                        "expression" => "map",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.20333440601825714,
                        "expression" => "unfold",
                        "is_reversible" => false,
                        "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.37100377678871155,
                        "expression" => "range",
                        "is_reversible" => true,
                        "type" => "int -> list(int)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.12165754288434982,
                        "expression" => "index",
                        "is_reversible" => false,
                        "type" => "int -> list(t0) -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.11216159164905548,
                        "expression" => "fold",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.2667142450809479,
                        "expression" => "length",
                        "is_reversible" => false,
                        "type" => "list(t0) -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.08669699728488922,
                        "expression" => "if",
                        "is_reversible" => false,
                        "type" => "bool -> t0 -> t0 -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.06585580110549927,
                        "expression" => "+",
                        "is_reversible" => true,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.3420185148715973,
                        "expression" => "-",
                        "is_reversible" => false,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.043512050062417984,
                        "expression" => "empty",
                        "is_reversible" => false,
                        "type" => "list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.456709623336792,
                        "expression" => "cons",
                        "is_reversible" => true,
                        "type" => "t0 -> list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.374737411737442,
                        "expression" => "car",
                        "is_reversible" => false,
                        "type" => "list(t0) -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.12529146671295166,
                        "expression" => "cdr",
                        "is_reversible" => false,
                        "type" => "list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.6556612849235535,
                        "expression" => "empty?",
                        "is_reversible" => false,
                        "type" => "list(t0) -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.09510736167430878,
                        "expression" => "0",
                        "is_reversible" => false,
                        "type" => "int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.20059284567832947,
                        "expression" => "1",
                        "is_reversible" => false,
                        "type" => "int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.1867990344762802,
                        "expression" => "*",
                        "is_reversible" => true,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.17349091172218323,
                        "expression" => "mod",
                        "is_reversible" => false,
                        "type" => "int -> int -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.02229311130940914,
                        "expression" => "gt?",
                        "is_reversible" => false,
                        "type" => "int -> int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.20750512182712555,
                        "expression" => "eq?",
                        "is_reversible" => false,
                        "type" => "t0 -> t0 -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.32782310247421265,
                        "expression" => "is-prime",
                        "is_reversible" => false,
                        "type" => "int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.03512703627347946,
                        "expression" => "is-square",
                        "is_reversible" => false,
                        "type" => "int -> bool",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.13425014913082123,
                        "expression" => "repeat",
                        "is_reversible" => true,
                        "type" => "t0 -> int -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0797867625951767,
                        "expression" => "concat",
                        "is_reversible" => true,
                        "type" => "list(t0) -> list(t0) -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 1.0,
                        "expression" => "rev_fix_param",
                        "is_reversible" => true,
                        "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                    ),
                ],
            ),
            "type_weights" => Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "prepend-k with k=3",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[3, 16, 4, 10, 12, 5, 11],
                        "inputs" => Dict{String,Any}("inp0" => Any[16, 4, 10, 12, 5, 11]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 13, 8, 9, 4, 0],
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 8, 9, 4, 0]),
                    ),
                    Dict{String,Any}("output" => Any[3, 0, 6], "inputs" => Dict{String,Any}("inp0" => Any[0, 6])),
                    Dict{String,Any}(
                        "output" => Any[3, 5, 3, 0, 3, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 3, 0, 3, 7]),
                    ),
                    Dict{String,Any}("output" => Any[3, 6, 0], "inputs" => Dict{String,Any}("inp0" => Any[6, 0])),
                    Dict{String,Any}("output" => Any[3], "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}(
                        "output" => Any[3, 2, 5, 9, 14, 14],
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 5, 9, 14, 14]),
                    ),
                    Dict{String,Any}("output" => Any[3, 7], "inputs" => Dict{String,Any}("inp0" => Any[7])),
                    Dict{String,Any}("output" => Any[3], "inputs" => Dict{String,Any}("inp0" => Any[])),
                    Dict{String,Any}(
                        "output" => Any[3, 13, 14, 10, 10, 14, 14],
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 14, 10, 10, 14, 14]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 0, 2, 11, 9, 3],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 2, 11, 9, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 11, 14, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 14, 7]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 9, 14, 2, 5, 12, 10, 3],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 14, 2, 5, 12, 10, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 10, 0, 8, 0],
                        "inputs" => Dict{String,Any}("inp0" => Any[10, 0, 8, 0]),
                    ),
                    Dict{String,Any}("output" => Any[3, 14, 11], "inputs" => Dict{String,Any}("inp0" => Any[14, 11])),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
            "name" => "prepend-k with k=3",
            "programTimeout" => 3.0,
            "timeout" => 20,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) > 0
        @test number_enumerated < 6000
    end
end


using Test

using solver: load_problems, enumerate_for_task

@testset "Inventions" begin
    @testset "a85d4709.json" begin
        payload = Dict{String,Any}(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "productions" => Any[
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "map",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "map_grid",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "unfold",
                        "is_reversible" => false,
                        "type" => "t0 -> (t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> list(t1)",
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
                        "expression" => "index2",
                        "is_reversible" => false,
                        "type" => "int -> int -> grid(t0) -> t0",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "fold",
                        "is_reversible" => false,
                        "type" => "list(t0) -> t1 -> (t0 -> t1 -> t1) -> t1",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "fold_h",
                        "is_reversible" => false,
                        "type" => "grid(t0) -> list(t1) -> (t0 -> t1 -> t1) -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "fold_v",
                        "is_reversible" => false,
                        "type" => "grid(t0) -> list(t1) -> (t0 -> t1 -> t1) -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "length",
                        "is_reversible" => false,
                        "type" => "list(t0) -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "height",
                        "is_reversible" => false,
                        "type" => "grid(t0) -> int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "width",
                        "is_reversible" => false,
                        "type" => "grid(t0) -> int",
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
                        "is_reversible" => false,
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
                        "expression" => "*",
                        "is_reversible" => false,
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
                        "logProbability" => 0.0,
                        "expression" => "rows_to_grid",
                        "is_reversible" => true,
                        "type" => "list(list(t0)) -> grid(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "columns_to_grid",
                        "is_reversible" => true,
                        "type" => "list(list(t0)) -> grid(t0)",
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
            "task" => Dict{String,Any}(
                "name" => "a85d4709.json",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[Any[3, 3, 3], Any[4, 4, 4], Any[2, 2, 2]],
                        "inputs" => Dict{String,Any}("inp0" => Any[Any[0, 0, 5], Any[0, 5, 0], Any[5, 0, 0]]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[3, 3, 3], Any[3, 3, 3], Any[3, 3, 3]],
                        "inputs" => Dict{String,Any}("inp0" => Any[Any[0, 0, 5], Any[0, 0, 5], Any[0, 0, 5]]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[2, 2, 2], Any[4, 4, 4], Any[2, 2, 2]],
                        "inputs" => Dict{String,Any}("inp0" => Any[Any[5, 0, 0], Any[0, 5, 0], Any[5, 0, 0]]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[Any[4, 4, 4], Any[3, 3, 3], Any[4, 4, 4]],
                        "inputs" => Dict{String,Any}("inp0" => Any[Any[0, 5, 0], Any[0, 0, 5], Any[0, 5, 0]]),
                    ),
                ],
                "test_examples" => Any[Dict{String,Any}(
                    "output" => Any[Any[3, 3, 3], Any[2, 2, 2], Any[4, 4, 4]],
                    "inputs" => Dict{String,Any}("inp0" => Any[Any[0, 0, 5], Any[5, 0, 0], Any[0, 5, 0]]),
                )],
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
            ),
            "name" => "a85d4709.json",
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
            verbose,
        )
        @test length(solutions) == 0
        @test number_enumerated >= 1
        @test number_enumerated < 1000
    end
end


using Test

using solver: load_problems, enumerate_for_task, RedisContext
import Redis

@testset "Abstractors tasks" begin
    @testset "Repeat" begin
        payload = Dict(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "productions" => Any[
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "map"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "unfold"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "range"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "index"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "fold"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "length"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "if"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "+"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "-"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "cons"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "car"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "cdr"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "0"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "1"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "*"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "mod"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "gt?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "eq?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "is-prime"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "is-square"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "repeat"),
                ],
            ),
            "type_weights" => Dict{String,Any}("list" => 1.0, "int" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "invert repeated",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[4, 4, 4, 4, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 5, 5, 5]),
                    ),
                    Dict{String,Any}("output" => Any[1, 1, 1, 1, 1, 1], "inputs" => Dict{String,Any}("inp0" => Any[6])),
                    Dict{String,Any}("output" => Any[3, 3], "inputs" => Dict{String,Any}("inp0" => Any[2, 2, 2])),
                ],
                "test_examples" => Any[],
                "request" => Dict{String,Any}(
                    "arguments" => Dict{String,Any}(
                        "inp0" => Dict{String,Any}(
                            "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                            "constructor" => "list",
                        ),
                    ),
                    "output" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                        "constructor" => "list",
                    ),
                    "constructor" => "->",
                ),
            ),
            "name" => "invert repeated",
            "programTimeout" => 1,
            "timeout" => 40,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict(
                "redis" => RedisContext(Redis.RedisConnection(db = 2)),
                "program_timeout" => program_timeout,
                "timeout" => timeout,
            ),
            g,
            type_weights,
            task,
            maximum_frontier,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated >= 1
        @test number_enumerated < 1000
    end

    @testset "Find const" begin
        payload = Dict(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "productions" => Any[
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "map"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "unfold"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "range"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "index"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "fold"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "length"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "if"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "+"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "-"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "cons"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "car"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "cdr"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "0"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "1"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "*"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "mod"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "gt?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "eq?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "is-prime"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "is-square"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "repeat"),
                ],
            ),
            "type_weights" => Dict{String,Any}("list" => 1.0, "int" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "find const",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[4, 4, 4, 4, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 5, 5, 5]),
                    ),
                    Dict{String,Any}("output" => Any[1, 1, 1, 1, 1], "inputs" => Dict{String,Any}("inp0" => Any[6])),
                    Dict{String,Any}(
                        "output" => Any[3, 3, 3, 3, 3],
                        "inputs" => Dict{String,Any}("inp0" => Any[2, 2, 2]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => Dict{String,Any}(
                    "arguments" => Dict{String,Any}(
                        "inp0" => Dict{String,Any}(
                            "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                            "constructor" => "list",
                        ),
                    ),
                    "output" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                        "constructor" => "list",
                    ),
                    "constructor" => "->",
                ),
            ),
            "name" => "find const",
            "programTimeout" => 1,
            "timeout" => 20,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict(
                "redis" => RedisContext(Redis.RedisConnection(db = 2)),
                "program_timeout" => program_timeout,
                "timeout" => timeout,
            ),
            g,
            type_weights,
            task,
            maximum_frontier,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated >= 10
        @test number_enumerated <= 1000
    end

    @testset "Use eithers" begin
        payload = Dict(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "productions" => Any[
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "map"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "unfold"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "range"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "index"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "fold"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "length"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "if"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "+"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "-"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "cons"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "car"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "cdr"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "0"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "1"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "*"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "mod"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "gt?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "eq?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "is-prime"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "is-square"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "repeat"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "concat"),
                ],
            ),
            "type_weights" => Dict{String,Any}("list" => 1.0, "int" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "use eithers",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 3, 4, 5]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[4, 2, 4, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 2, 4]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 3, 3, 8, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 3, 3, 8]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => Dict{String,Any}(
                    "arguments" => Dict{String,Any}(
                        "inp0" => Dict{String,Any}(
                            "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                            "constructor" => "list",
                        ),
                    ),
                    "output" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                        "constructor" => "list",
                    ),
                    "constructor" => "->",
                ),
            ),
            "name" => "use eithers",
            "programTimeout" => 1,
            "timeout" => 20,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict(
                "redis" => RedisContext(Redis.RedisConnection(db = 2)),
                "program_timeout" => program_timeout,
                "timeout" => timeout,
            ),
            g,
            type_weights,
            task,
            maximum_frontier,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated >= 10
        @test number_enumerated <= 1000
    end

    @testset "Use eithers 2" begin
        payload = Dict(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "productions" => Any[
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "map"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "unfold"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "range"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "index"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "fold"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "length"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "if"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "+"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "-"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "cons"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "car"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "cdr"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "0"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "1"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "*"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "mod"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "gt?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "eq?"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "is-prime"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "is-square"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "repeat"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "concat"),
                ],
            ),
            "type_weights" => Dict{String,Any}("list" => 1.0, "int" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "use eithers",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[1, 2, 3, 4, 5, 5, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 3, 4, 5]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[4, 2, 4, 3, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 2, 4]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 3, 3, 8, 4, 6, 7, 8, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 3, 3, 8]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => Dict{String,Any}(
                    "arguments" => Dict{String,Any}(
                        "inp0" => Dict{String,Any}(
                            "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                            "constructor" => "list",
                        ),
                    ),
                    "output" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                        "constructor" => "list",
                    ),
                    "constructor" => "->",
                ),
            ),
            "name" => "use eithers",
            "programTimeout" => 1,
            "timeout" => 80,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict(
                "redis" => RedisContext(Redis.RedisConnection(db = 2)),
                "program_timeout" => program_timeout,
                "timeout" => timeout,
            ),
            g,
            type_weights,
            task,
            maximum_frontier,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated >= 10
        @test number_enumerated <= 1000
    end
end

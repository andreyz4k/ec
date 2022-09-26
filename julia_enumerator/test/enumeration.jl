
using Test

using solver: load_problems, enumerate_for_task, RedisContext
import Redis

@testset "Enumeration" begin
    payload1 = Dict(
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
                Dict{String,Any}("output" => Any[5, 13, 16], "inputs" => Dict{String,Any}("inp0" => Any[4, 12, 15])),
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
        "name" => "add-k with k=1",
        "programTimeout" => 1,
        "timeout" => 20,
        "verbose" => false,
        "shatter" => 10,
    )

    payload2 = Dict{String,Any}(
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
                Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[6, 0, 14, 0, 2, 12])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[])),
                Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[12, 15])),
                Dict{String,Any}("output" => false, "inputs" => Dict{String,Any}("inp0" => Any[2, 16, 2, 5, 15, 6, 7])),
            ],
            "test_examples" => Any[],
            "request" => Dict{String,Any}(
                "arguments" => Dict{String,Any}(
                    "inp0" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                        "constructor" => "list",
                    ),
                ),
                "output" => Dict{String,Any}("arguments" => Any[], "constructor" => "bool"),
                "constructor" => "->",
            ),
        ),
        "name" => "empty",
        "programTimeout" => 1,
        "timeout" => 20,
        "verbose" => false,
        "shatter" => 10,
    )
    payload3 = Dict{String,Any}(
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
        "name" => "append-index-k with k=5",
        "programTimeout" => 1,
        "timeout" => 20,
        "verbose" => false,
        "shatter" => 10,
    )

    payload4 = Dict{String,Any}(
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
            "name" => "len",
            "maximumFrontier" => 10,
            "examples" => Any[
                Dict{String,Any}("output" => 3, "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 3])),
                Dict{String,Any}("output" => 1, "inputs" => Dict{String,Any}("inp0" => Any[0])),
                Dict{String,Any}("output" => 4, "inputs" => Dict{String,Any}("inp0" => Any[1, 1, 2, 1])),
                Dict{String,Any}("output" => 2, "inputs" => Dict{String,Any}("inp0" => Any[2, 9])),
                Dict{String,Any}("output" => 1, "inputs" => Dict{String,Any}("inp0" => Any[0])),
                Dict{String,Any}("output" => 7, "inputs" => Dict{String,Any}("inp0" => Any[10, 14, 8, 2, 12, 10, 3])),
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
            "request" => Dict{String,Any}(
                "arguments" => Dict{String,Any}(
                    "inp0" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                        "constructor" => "list",
                    ),
                ),
                "output" => Dict{String,Any}("arguments" => Any[], "constructor" => "int"),
                "constructor" => "->",
            ),
        ),
        "name" => "len",
        "programTimeout" => 1,
        "timeout" => 20,
        "verbose" => false,
        "shatter" => 10,
    )

    payload5 = Dict{String,Any}(
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
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[2, 16, 2, 5, 15, 6, 7])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[6, 11, 0, 11, 7, 9])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[9, 10, 4])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[1, 13, 10, 13])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[6, 1, 13, 7])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[1, 12, 3])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[14, 1])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[2, 13, 3])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[14, 13, 12, 6])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[6, 14, 7])),
                Dict{String,Any}("output" => true, "inputs" => Dict{String,Any}("inp0" => Any[13, 14, 7, 1, 0, 11, 0])),
            ],
            "test_examples" => Any[],
            "request" => Dict{String,Any}(
                "arguments" => Dict{String,Any}(
                    "inp0" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "int")],
                        "constructor" => "list",
                    ),
                ),
                "output" => Dict{String,Any}("arguments" => Any[], "constructor" => "bool"),
                "constructor" => "->",
            ),
        ),
        "name" => "is-mod-k with k=1",
        "programTimeout" => 1,
        "timeout" => 20,
        "verbose" => false,
        "shatter" => 10,
    )

    payload6 = Dict{String,Any}(
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
            ],
        ),
        "type_weights" => Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0),
        "task" => Dict{String,Any}(
            "name" => "prepend-k with k=0",
            "maximumFrontier" => 10,
            "examples" => Any[
                Dict{String,Any}(
                    "output" => Any[0, 12, 0, 1, 9, 4],
                    "inputs" => Dict{String,Any}("inp0" => Any[12, 0, 1, 9, 4]),
                ),
                Dict{String,Any}("output" => Any[0, 9, 10, 8], "inputs" => Dict{String,Any}("inp0" => Any[9, 10, 8])),
                Dict{String,Any}("output" => Any[0], "inputs" => Dict{String,Any}("inp0" => Any[])),
                Dict{String,Any}(
                    "output" => Any[0, 5, 11, 9, 0, 7, 1, 7],
                    "inputs" => Dict{String,Any}("inp0" => Any[5, 11, 9, 0, 7, 1, 7]),
                ),
                Dict{String,Any}("output" => Any[0, 14, 0, 3], "inputs" => Dict{String,Any}("inp0" => Any[14, 0, 3])),
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
        "name" => "prepend-k with k=0",
        "programTimeout" => 1.0,
        "timeout" => 20,
        "verbose" => false,
        "shatter" => 10,
    )

    payload7 = Dict{String,Any}(
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
            ],
        ),
        "type_weights" => Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0),
        "task" => Dict{String,Any}(
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
                    "inputs" => Dict{String,Any}("inp0" => Any[Any[false], Any[], Any[true, true, true], Any[true]]),
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
                    "inputs" => Dict{String,Any}("inp0" => Any[Any[true, true], Any[true], Any[true, true], Any[]]),
                ),
                Dict{String,Any}(
                    "output" => Any[Any[true, true], Any[true, false], Any[false]],
                    "inputs" => Dict{String,Any}("inp0" => Any[Any[], Any[true, true], Any[true, false], Any[false]]),
                ),
                Dict{String,Any}(
                    "output" => Any[Any[true], Any[true, true, false], Any[false, true]],
                    "inputs" => Dict{String,Any}(
                        "inp0" => Any[Any[true], Any[], Any[true, true, false], Any[false, true]],
                    ),
                ),
                Dict{String,Any}(
                    "output" => Any[Any[true, true, true], Any[true, false]],
                    "inputs" => Dict{String,Any}("inp0" => Any[Any[true, true, true], Any[], Any[true, false], Any[]]),
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
                    "inputs" => Dict{String,Any}("inp0" => Any[Any[false, false], Any[false], Any[], Any[false]]),
                ),
                Dict{String,Any}(
                    "output" => Any[Any[false, false, true], Any[true, true], Any[true], Any[false, true, true]],
                    "inputs" => Dict{String,Any}(
                        "inp0" => Any[Any[false, false, true], Any[true, true], Any[true], Any[false, true, true]],
                    ),
                ),
            ],
            "test_examples" => Any[],
            "request" => Dict{String,Any}(
                "arguments" => Dict{String,Any}(
                    "inp0" => Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}(
                            "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "bool")],
                            "constructor" => "list",
                        )],
                        "constructor" => "list",
                    ),
                ),
                "output" => Dict{String,Any}(
                    "arguments" => Any[Dict{String,Any}(
                        "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "bool")],
                        "constructor" => "list",
                    )],
                    "constructor" => "list",
                ),
                "constructor" => "->",
            ),
        ),
        "name" => "remove empty lists",
        "programTimeout" => 1.0,
        "timeout" => 20,
        "verbose" => false,
        "shatter" => 10,
    )

    # @testset "full loading" begin
    #     task, maximum_frontier, g, _mfp, _nc, timeout, _verbose, program_timeout = load_problems(payload1)
    # end

    @testset "try_enumerate add-k with k=1" begin
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload1)
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
        @test length(solutions) == 0
        @test number_enumerated > 50
    end

    @testset "try_enumerate empty" begin
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload2)
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
        @test length(solutions) >= 8
        @test number_enumerated >= 600
        @test number_enumerated < 1000
    end

    @testset "try_enumerate append-index-k with k=5" begin
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload3)
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
        @test length(solutions) == 0
        @test number_enumerated > 10
        @test number_enumerated < 1000
    end

    @testset "try_enumerate len" begin
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload4)
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
        @test length(solutions) >= 5
        @test number_enumerated >= 100
        @test number_enumerated <= 1000
    end

    @testset "try_enumerate is-mod-k with k=1" begin
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload5)
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
        @test length(solutions) >= 5
        @test number_enumerated >= 100
        @test number_enumerated <= 1000
    end

    @testset "prepend-k with k=0" begin
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload6)
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
        @test number_enumerated <= 2000
    end

    @testset "remove empty lists" begin
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload7)
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
        @test length(solutions) == 0
        @test number_enumerated >= 100
        @test number_enumerated <= 2000
    end
end

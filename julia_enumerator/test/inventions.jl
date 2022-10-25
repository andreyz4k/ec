
using Test

using solver: load_problems, enumerate_for_task

@testset "Inventions" begin
    @testset "slice-k-n with k=2 and n=1" begin
        payload = Dict{String,Any}(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "productions" => Any[
                    Dict{String,Any}(
                        "logProbability" => -1.0052030244719696,
                        "expression" => "#(lambda (repeat (car \$0)))",
                    ),
                    Dict{String,Any}("logProbability" => -1.1838572807461039, "expression" => "map"),
                    Dict{String,Any}("logProbability" => -1.1838572807461039, "expression" => "unfold"),
                    Dict{String,Any}("logProbability" => -1.151067457923113, "expression" => "range"),
                    Dict{String,Any}("logProbability" => -1.2171832600950525, "expression" => "index"),
                    Dict{String,Any}("logProbability" => -1.289518413628755, "expression" => "fold"),
                    Dict{String,Any}("logProbability" => -0.15480969927313604, "expression" => "length"),
                    Dict{String,Any}("logProbability" => -1.289518413628755, "expression" => "if"),
                    Dict{String,Any}("logProbability" => -0.2798682255709619, "expression" => "+"),
                    Dict{String,Any}("logProbability" => -0.28075781620381113, "expression" => "-"),
                    Dict{String,Any}("logProbability" => -1.1829561919230245, "expression" => "empty"),
                    Dict{String,Any}("logProbability" => -0.6393550838729674, "expression" => "cons"),
                    Dict{String,Any}("logProbability" => -1.1873062388074977, "expression" => "car"),
                    Dict{String,Any}("logProbability" => -1.10830595095433, "expression" => "cdr"),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty?"),
                    Dict{String,Any}("logProbability" => -0.28075781620381113, "expression" => "0"),
                    Dict{String,Any}("logProbability" => -0.2746779886310846, "expression" => "1"),
                    Dict{String,Any}("logProbability" => -0.2804706638162737, "expression" => "*"),
                    Dict{String,Any}("logProbability" => -0.28075781620381113, "expression" => "mod"),
                    Dict{String,Any}("logProbability" => -0.039175630977758225, "expression" => "gt?"),
                    Dict{String,Any}("logProbability" => -0.039175630977758225, "expression" => "eq?"),
                    Dict{String,Any}("logProbability" => -0.039175630977758225, "expression" => "is-prime"),
                    Dict{String,Any}("logProbability" => -0.039175630977758225, "expression" => "is-square"),
                    Dict{String,Any}("logProbability" => -1.123559515428262, "expression" => "repeat"),
                    Dict{String,Any}("logProbability" => -0.40787379882733443, "expression" => "concat"),
                ],
            ),
            "type_weights" => Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "slice-k-n with k=2 and n=1",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[13],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 13, 15, 7, 10]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[7],
                        "inputs" => Dict{String,Any}("inp0" => Any[16, 7, 12, 11, 14, 6, 9, 14, 0, 5]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[13],
                        "inputs" => Dict{String,Any}("inp0" => Any[7, 13, 3, 4, 8, 16, 5, 1]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 15, 0, 9, 9, 15, 15, 3, 4]),
                    ),
                    Dict{String,Any}("output" => Any[12], "inputs" => Dict{String,Any}("inp0" => Any[11, 12, 4, 5, 2])),
                    Dict{String,Any}(
                        "output" => Any[2],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 2, 4, 4, 4, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15],
                        "inputs" => Dict{String,Any}("inp0" => Any[5, 15, 15, 13, 6]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 0, 4, 12, 0, 3, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[0],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 0, 3, 0, 11, 2, 1, 0, 8, 1, 15]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[1],
                        "inputs" => Dict{String,Any}("inp0" => Any[16, 1, 14, 11, 16, 4]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15],
                        "inputs" => Dict{String,Any}("inp0" => Any[16, 15, 9, 11, 12]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15],
                        "inputs" => Dict{String,Any}("inp0" => Any[13, 15, 13, 6, 16, 2]),
                    ),
                    Dict{String,Any}("output" => Any[10], "inputs" => Dict{String,Any}("inp0" => Any[12, 10, 1, 9, 6])),
                    Dict{String,Any}("output" => Any[6], "inputs" => Dict{String,Any}("inp0" => Any[2, 6, 5, 5, 2])),
                    Dict{String,Any}("output" => Any[0], "inputs" => Dict{String,Any}("inp0" => Any[9, 0, 16, 9, 10])),
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
            "name" => "slice-k-n with k=2 and n=1",
            "programTimeout" => 1,
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
        @test length(solutions) >= 1
        @test number_enumerated >= 1
        @test number_enumerated < 1000
    end
end

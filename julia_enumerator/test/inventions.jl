using solver: load_problems, enumerate_for_task

@testset "Inventions" begin
    @testcase_log "slice-k-n with k=2 and n=1" begin
        payload = Dict{String,Any}(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "logFreeVar" => 3.0,
                "logLambda" => -3.0,
                "productions" => Any[
                    Dict{String,Any}(
                        "logProbability" => -1.0052030244719696,
                        "expression" => "#(lambda (repeat (car \$0)))",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1838572807461039,
                        "expression" => "map",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1838572807461039,
                        "expression" => "unfold",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.151067457923113,
                        "expression" => "range",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.2171832600950525,
                        "expression" => "index",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.289518413628755,
                        "expression" => "fold",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.15480969927313604,
                        "expression" => "length",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.289518413628755,
                        "expression" => "if",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.2798682255709619,
                        "expression" => "+",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.28075781620381113,
                        "expression" => "-",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1829561919230245,
                        "expression" => "empty",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.6393550838729674,
                        "expression" => "cons",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1873062388074977,
                        "expression" => "car",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.10830595095433,
                        "expression" => "cdr",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty?", "is_reversible" => false),
                    Dict{String,Any}(
                        "logProbability" => -0.28075781620381113,
                        "expression" => "0",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.2746779886310846,
                        "expression" => "1",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.2804706638162737,
                        "expression" => "*",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.28075781620381113,
                        "expression" => "mod",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.039175630977758225,
                        "expression" => "gt?",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.039175630977758225,
                        "expression" => "eq?",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.039175630977758225,
                        "expression" => "is-prime",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.039175630977758225,
                        "expression" => "is-square",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.123559515428262,
                        "expression" => "repeat",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.40787379882733443,
                        "expression" => "concat",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => 4.0,
                        "expression" => "rev_fix_param",
                        "is_reversible" => true,
                        "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                    ),
                ],
            ),
            "type_weights" =>
                Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0, "any" => 1.0),
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
                "request" => "inp0:list(int) -> list(int)",
            ),
            "name" => "slice-k-n with k=2 and n=1",
            "programTimeout" => 1,
            "timeout" => 40,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, hyperparameters, _mfp, _nc, timeout, verbose, program_timeout =
            load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            hyperparameters,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated < 1000
    end

    @testcase_log "Invented abstractor" begin
        payload = Dict{String,Any}(
            "DSL" => Dict{String,Any}(
                "logVariable" => 0.0,
                "logFreeVar" => 3.0,
                "logLambda" => -3.0,
                "productions" => Any[
                    Dict{String,Any}(
                        "logProbability" => -1.0052030244719696,
                        "expression" => "#(lambda (repeat (car \$0)))",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.0052030244719696,
                        "expression" => "#(lambda (lambda (repeat (cons \$0 \$1))))",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1838572807461039,
                        "expression" => "map",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1838572807461039,
                        "expression" => "unfold",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.151067457923113,
                        "expression" => "range",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.2171832600950525,
                        "expression" => "index",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.289518413628755,
                        "expression" => "fold",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.15480969927313604,
                        "expression" => "length",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.289518413628755,
                        "expression" => "if",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.2798682255709619,
                        "expression" => "+",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.28075781620381113,
                        "expression" => "-",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1829561919230245,
                        "expression" => "empty",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.6393550838729674,
                        "expression" => "cons",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.1873062388074977,
                        "expression" => "car",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.10830595095433,
                        "expression" => "cdr",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}("logProbability" => 0.0, "expression" => "empty?", "is_reversible" => false),
                    Dict{String,Any}(
                        "logProbability" => -0.28075781620381113,
                        "expression" => "0",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.2746779886310846,
                        "expression" => "1",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.2804706638162737,
                        "expression" => "*",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.28075781620381113,
                        "expression" => "mod",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.039175630977758225,
                        "expression" => "gt?",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.039175630977758225,
                        "expression" => "eq?",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.039175630977758225,
                        "expression" => "is-prime",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.039175630977758225,
                        "expression" => "is-square",
                        "is_reversible" => false,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -1.123559515428262,
                        "expression" => "repeat",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => -0.40787379882733443,
                        "expression" => "concat",
                        "is_reversible" => true,
                    ),
                    Dict{String,Any}(
                        "logProbability" => 4.0,
                        "expression" => "rev_fix_param",
                        "is_reversible" => true,
                        "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                    ),
                ],
            ),
            "type_weights" =>
                Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0, "any" => 1.0),
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
                "request" => "inp0:list(int) -> list(int)",
            ),
            "name" => "slice-k-n with k=2 and n=1",
            "programTimeout" => 1,
            "timeout" => 40,
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, hyperparameters, _mfp, _nc, timeout, verbose, program_timeout =
            load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            hyperparameters,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated < 1000
    end

    @testcase_log "Invented abstractors 2" begin
        payload = Dict{String,Any}(
            "DSL" => Dict{String,Any}(
                "logFreeVar" => 0.0,
                "logVariable" => 0.0,
                "logLambda" => 0.0,
                "productions" => Any[
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
                        "expression" => "map",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "fold",
                        "is_reversible" => true,
                        "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "rev_fix_param",
                        "is_reversible" => true,
                        "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
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
                        "is_reversible" => true,
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
                        "is_reversible" => true,
                        "type" => "int",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0.0,
                        "expression" => "1",
                        "is_reversible" => true,
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
                        "logProbability" => 0,
                        "expression" => "#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2)))))",
                        "is_reversible" => true,
                        "type" => "list(t0) -> t0 -> t0 -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0,
                        "expression" => "#(lambda (repeat \$0 Const(int, 1)))",
                        "is_reversible" => false,
                        "type" => "t0 -> list(t0)",
                    ),
                    Dict{String,Any}(
                        "logProbability" => 0,
                        "expression" => "#(lambda (lambda (- \$0 (- \$0 \$1))))",
                        "is_reversible" => true,
                        "type" => "int -> int -> int",
                    ),
                ],
            ),
            "type_weights" => Dict{String,Any}("int" => 1.0, "list" => 1.0, "bool" => 1.0, "float" => 1.0),
            "task" => Dict{String,Any}(
                "name" => "append-index-k with k=3",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[0, 13, 12, 12, 12],
                        "inputs" => Dict{String,Any}("inp0" => Any[0, 13, 12, 12]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[6, 8, 2, 6, 7, 14, 9, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 8, 2, 6, 7, 14, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[6, 15, 6, 15, 5, 13, 6],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 15, 6, 15, 5, 13]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15, 13, 7, 2, 4, 10, 7],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 13, 7, 2, 4, 10]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[1, 2, 1, 7, 12, 15, 12, 13, 11, 4, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 1, 7, 12, 15, 12, 13, 11, 4]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[9, 5, 2, 15, 8, 1, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[9, 5, 2, 15, 8, 1]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 13, 5, 7, 4, 3, 3, 5],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 13, 5, 7, 4, 3, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[6, 14, 12, 4, 4, 15, 3, 1, 4, 12],
                        "inputs" => Dict{String,Any}("inp0" => Any[6, 14, 12, 4, 4, 15, 3, 1, 4]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[14, 2, 10, 6, 7, 9, 14, 2, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[14, 2, 10, 6, 7, 9, 14, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[11, 11, 2, 9, 2],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 11, 2, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[8, 6, 13, 11, 15, 2, 13],
                        "inputs" => Dict{String,Any}("inp0" => Any[8, 6, 13, 11, 15, 2]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[15, 0, 13, 10, 7, 1, 14, 5, 10, 10, 13],
                        "inputs" => Dict{String,Any}("inp0" => Any[15, 0, 13, 10, 7, 1, 14, 5, 10, 10]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[11, 0, 12, 10, 15, 13, 12],
                        "inputs" => Dict{String,Any}("inp0" => Any[11, 0, 12, 10, 15, 13]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[14, 10, 10, 14, 14, 2, 9, 10],
                        "inputs" => Dict{String,Any}("inp0" => Any[14, 10, 10, 14, 14, 2, 9]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[12, 7, 16, 14, 16],
                        "inputs" => Dict{String,Any}("inp0" => Any[12, 7, 16, 14]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
            "name" => "append-index-k with k=3",
            "programTimeout" => 3.0,
            "timeout" => 20,
            "queue" => "tasks",
            "verbose" => false,
            "shatter" => 10,
        )
        task, maximum_frontier, g, type_weights, hyperparameters, _mfp, _nc, timeout, verbose, program_timeout =
            load_problems(payload)
        solutions, number_enumerated = @time enumerate_for_task(
            Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
            g,
            type_weights,
            hyperparameters,
            task,
            maximum_frontier,
            timeout,
            verbose,
        )
        @test length(solutions) >= 1
        @test number_enumerated < 1000
    end
end

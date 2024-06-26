
using solver: load_problems, enumerate_for_task

@testset "Abstractors tasks" begin
    sample_payload = Dict{String,Any}(
        "DSL" => Dict{String,Any}(
            "logVariable" => 0.0,
            "logFreeVar" => 3.0,
            "logLambda" => -10.0,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
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
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
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
                    "expression" => "empty_set",
                    "is_reversible" => false,
                    "type" => "set(t0)",
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
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
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
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
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
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t1) -> grid(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "rev_groupby",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> t0 -> set(tuple2(t1, set(t0))) -> set(tuple2(t1, set(t0)))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "rev_greedy_cluster",
                    "is_reversible" => true,
                    "type" => "(t0 -> set(t0) -> bool) -> t0 -> set(set(t0)) -> set(set(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "not",
                    "is_reversible" => true,
                    "type" => "bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "and",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "or",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "all",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "any",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "all_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "any_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "abs",
                    "is_reversible" => true,
                    "type" => "int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 4.0,
                    "expression" => "rev_fix_param",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "max_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "min_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0,
                    "expression" => "collect",
                    "is_reversible" => true,
                    "type" => "set(t0) -> list(t0)",
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
            "any" => 1.0,
        ),
        "programTimeout" => 3.0,
        "timeout" => 40,
        "verbose" => false,
        "shatter" => 10,
    )

    function create_task(task_dict)
        result = deepcopy(sample_payload)
        result["task"] = task_dict
        result["name"] = task_dict["name"]
        return result
    end

    @testcase_log "Repeat" begin
        payload = create_task(
            Dict{String,Any}(
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
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        for prod_dict in payload["DSL"]["productions"]
            if prod_dict["expression"] == "repeat"
                prod_dict["logProbability"] = 3.0
            end
        end
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

    @testcase_log "Find const" begin
        payload = create_task(
            Dict{String,Any}(
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
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        for prod_dict in payload["DSL"]["productions"]
            if prod_dict["expression"] == "repeat"
                prod_dict["logProbability"] = 2.0
            end
            if prod_dict["expression"] == "rev_fix_param"
                prod_dict["logProbability"] = 0.0
            end
        end
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
        @test number_enumerated <= 2000
    end

    @testcase_log "Use eithers" begin
        payload = create_task(
            Dict{String,Any}(
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
                "request" => "inp0:list(int) -> list(int)",
            ),
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
        @test number_enumerated <= 15000
    end

    @testcase_log "Use eithers 2" begin
        payload = create_task(
            Dict{String,Any}(
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
                "request" => "inp0:list(int) -> list(int)",
            ),
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
        @test number_enumerated <= 10000
    end

    @testcase_log "Use eithers from input" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "use eithers",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[1, 2, 3, 4, 5],
                        "inputs" => Dict{String,Any}("inp0" => Any[1, 2, 3, 4, 5, 10, 9, 8, 7]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[4, 2, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 2, 4, 10, 9, 8, 7]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[3, 3, 3, 8],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 3, 3, 8, 10, 9, 8, 7]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
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
        @test number_enumerated <= 10000
    end

    # powers_options = [1.0, 2.0, 3.0, 4.0, 5.0]
    # complexity_options = [1.0]

    # @testcase "Replace background $cost_power $complexity_power $block_cost_power $any_complexity" for cost_power in
    #                                                                                                    powers_options,
    #     complexity_power in powers_options,
    #     block_cost_power in powers_options,
    #     list_complexity in complexity_options,
    #     set_complexity in complexity_options,
    #     tuple2_complexity in complexity_options,
    #     any_complexity in [0.0, 0.1, 0.5, 1.0, 2.0, 3.0]

    #     hyperparameters = Dict{String,Any}(
    #         "path_cost_power" => cost_power,
    #         "complexity_power" => complexity_power,
    #         "block_cost_power" => block_cost_power,
    #     )
    #     type_weights = Dict{String,Any}(
    #         "int" => 1.0,
    #         "list" => list_complexity,
    #         "color" => 1.0,
    #         "bool" => 1.0,
    #         "float" => 1.0,
    #         "grid" => 1.0,
    #         "tuple2" => tuple2_complexity,
    #         "tuple3" => 1.0,
    #         "coord" => 1.0,
    #         "set" => set_complexity,
    #         "any" => any_complexity,
    #     )

    @testcase_log "Replace background" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "replace background",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}(
                        "output" => Any[1, 2, 1, 4, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 2, 3, 4, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[4, 2, 4, 1, 1, 1],
                        "inputs" => Dict{String,Any}("inp0" => Any[4, 2, 4, 3, 3, 3]),
                    ),
                    Dict{String,Any}(
                        "output" => Any[1, 5, 2, 6, 1, 1, 4],
                        "inputs" => Dict{String,Any}("inp0" => Any[3, 5, 2, 6, 3, 3, 4]),
                    ),
                ],
                "test_examples" => Any[],
                "request" => "inp0:list(int) -> list(int)",
            ),
        )
        payload["DSL"]["logVariable"] = 4.0
        for prod_dict in payload["DSL"]["productions"]
            if prod_dict["expression"] == "repeat" ||
               prod_dict["expression"] == "eq?" ||
               prod_dict["expression"] == "rev_select" ||
               prod_dict["expression"] == "rev_fix_param"
                prod_dict["logProbability"] = 4.0
            end
        end
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
            # true,
        )
        @test length(solutions) >= 1
        @test number_enumerated <= 20000
    end
    # end
end

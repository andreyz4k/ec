using JSON
using solver: load_problems, enumerate_for_task

@testset "Arc tasks" begin
    sample_payload = Dict{String,Any}(
        "DSL" => Dict{String,Any}(
            "logVariable" => 0.18440093100070953,
            "logFreeVar" => 3.0,
            "logLambda" => -3.0,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => 0.26229602098464966,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.17433375120162964,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.020587414503097534,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.25952717661857605,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.7479397058486938,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.09426483511924744,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.31616055965423584,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.24963818490505219,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.6580096483230591,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.24903573095798492,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.043374061584472656,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05344507470726967,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.01714884489774704,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.024114713072776794,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.33626657724380493,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.36573341488838196,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.01316140592098236,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0700928121805191,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.18608686327934265,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05018486827611923,
                    "expression" => "empty",
                    "is_reversible" => false,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05018486827611923,
                    "expression" => "empty_set",
                    "is_reversible" => false,
                    "type" => "set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.26301681995391846,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.26301681995391846,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11566320061683655,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.4045564830303192,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.04355373978614807,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.21377874910831451,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.4629265069961548,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.28995591402053833,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.20868434011936188,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3835919499397278,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.26428088545799255,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.27473536133766174,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.20100094377994537,
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1020718663930893,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3644667863845825,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.08203943073749542,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.34513404965400696,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.302104651927948,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0025863386690616608,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0025863386690616608,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3118687868118286,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3658756911754608,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.16821910440921783,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.19650761783123016,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.04930289089679718,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.04608079418540001,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.04608079418540001,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.7565436363220215,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.24813920259475708,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.39079853892326355,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3027239739894867,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.05734211206436157,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
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
                    "logProbability" => 0.15116432309150696,
                    "expression" => "0",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0043089985847473145,
                    "expression" => "1",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.0,
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

    function create_arc_task(filename, dir = "ARC/data/training/")
        arc_task = JSON.parsefile("../../dreamcoder/domains/arc/" * dir * filename)
        task_dict = Dict{String,Any}(
            "name" => filename,
            "maximumFrontier" => 10,
            "extras" => 5,
            "request" => "inp0:grid(color) -> grid(color)",
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

    @testcase_log "a85d4709.json" begin
        payload = create_arc_task("a85d4709.json")
        @info payload["name"]
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
        @test length(solutions) == 0
        @test number_enumerated >= 1000
    end

    @testcase_log "5c2c9af4.json" begin
        payload = create_arc_task("5c2c9af4.json")
        @info payload["name"]
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
        @test length(solutions) == 0
        @test number_enumerated >= 1500
    end

    @testcase_log "23581191.json" begin
        payload = create_arc_task("23581191.json")
        @info payload["name"]
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
        @test length(solutions) == 0
        @test number_enumerated >= 2000
    end

    @testcase_log "4258a5f9.json" begin
        payload = create_arc_task("4258a5f9.json")
        @info payload["name"]
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
        @test length(solutions) == 0
        @test number_enumerated >= 1000
    end

    @testcase_log "f25ffba3.json" begin
        payload = create_arc_task("f25ffba3.json")
        @info payload["name"]
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
        @test length(solutions) == 0
        @test number_enumerated >= 1000
    end

    @testcase_log "74dd1130.json" begin
        payload = create_arc_task("74dd1130.json")
        payload["DSL"] = Dict{String,Any}(
            "logFreeVar" => 0.0,
            "logVariable" => 0.13056975603103638,
            "logLambda" => 0.0,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => 0.19568924605846405,
                    "expression" => "rev_fix_param",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.027658693492412567,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.23283877968788147,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.03701348602771759,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5748467445373535,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11541789770126343,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.14602366089820862,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.36934584379196167,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.10598685592412949,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.11677655577659607,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2207450568675995,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1677042543888092,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.12983891367912292,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4314330816268921,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3136741518974304,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3567688465118408,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.7988244891166687,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2871095836162567,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.16608723998069763,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.08104187995195389,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.24168792366981506,
                    "expression" => "empty",
                    "is_reversible" => true,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.09875724464654922,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.34120839834213257,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.29691261053085327,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.485686719417572,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.36099618673324585,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5080875158309937,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.015803754329681396,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1618868112564087,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.06386598944664001,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0771864801645279,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4588533043861389,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.12400469183921814,
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.09133487939834595,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2758467197418213,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2519418001174927,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.13150739669799805,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3175426125526428,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.48631465435028076,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2080480456352234,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.05786772072315216,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4194464087486267,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.17600752413272858,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2870781123638153,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07235664129257202,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t1) -> grid(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11107661575078964,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.09757266193628311,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.01833958923816681,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.22101598978042603,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.11861817538738251,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07899481058120728,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.08762955665588379,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2344331592321396,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3238257169723511,
                    "expression" => "empty_set",
                    "is_reversible" => true,
                    "type" => "set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.023169441148638725,
                    "expression" => "rev_groupby",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> t0 -> set(tuple2(t1, set(t0))) -> set(tuple2(t1, set(t0)))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.37937015295028687,
                    "expression" => "rev_greedy_cluster",
                    "is_reversible" => true,
                    "type" => "(t0 -> set(t0) -> bool) -> t0 -> set(set(t0)) -> set(set(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.12758007645606995,
                    "expression" => "not",
                    "is_reversible" => true,
                    "type" => "bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.18643711507320404,
                    "expression" => "and",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1242520809173584,
                    "expression" => "or",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.08657313138246536,
                    "expression" => "all",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.16754098236560822,
                    "expression" => "any",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.25964221358299255,
                    "expression" => "all_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.04540534317493439,
                    "expression" => "any_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3880871534347534,
                    "expression" => "abs",
                    "is_reversible" => true,
                    "type" => "int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4607189893722534,
                    "expression" => "max_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.06060907244682312,
                    "expression" => "min_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.13055525720119476,
                    "expression" => "collect",
                    "is_reversible" => true,
                    "type" => "set(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.09714295715093613,
                    "expression" => "0",
                    "is_reversible" => true,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.06472329050302505,
                    "expression" => "1",
                    "is_reversible" => true,
                    "type" => "int",
                ),
            ],
        )
        @info payload["name"]
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
        @test length(solutions) >= 4
        @test number_enumerated < 10000
    end

    @testcase_log "7837ac64.json" begin
        payload = create_arc_task("7837ac64.json")
        @info payload["name"]
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
        @test length(solutions) == 0
        @test number_enumerated >= 1500
    end

    @testcase_log "6fa7a44f.json" begin
        payload = create_arc_task("6fa7a44f.json")
        @info payload["name"]
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
        @test length(solutions) > 0
        @test number_enumerated < 10000
    end

    @testcase_log "c9e6f938.json" begin
        payload = create_arc_task("c9e6f938.json")
        @info payload["name"]
        for prod in payload["DSL"]["productions"]
            if prod["expression"] != "rev_fix_param"
                prod["logProbability"] = 0.0
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
        @test length(solutions) > 0
        @test number_enumerated < 15000
    end

    @testcase_log "bbc9ae5d.json" begin
        payload = create_arc_task("bbc9ae5d.json")
        @info payload["name"]
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
        @test length(solutions) == 0
        @test number_enumerated >= 1000
    end

    @testcase_log "63613498.json" begin
        payload = create_arc_task("63613498.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, hyperparameters, _mfp, _nc, timeout, verbose, program_timeout =
            load_problems(payload)
        # verbose = true
        # timeout = 600
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
        @test length(solutions) == 0
        @test number_enumerated >= 2000
    end

    @testcase_log "d8c310e9.json" begin
        payload = create_arc_task("d8c310e9.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, hyperparameters, _mfp, _nc, timeout, verbose, program_timeout =
            load_problems(payload)
        # verbose = true
        # timeout = 600
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
        @test length(solutions) == 0
        @test number_enumerated >= 1000
    end

    @testcase_log "d06dbe63.json" begin
        payload = create_arc_task("d06dbe63.json")
        @info payload["name"]
        payload["DSL"]["logVariable"] = 0.0
        for d in payload["DSL"]["productions"]
            if d["expression"] != "rev_fix_param"
                d["logProbability"] = 0.0
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
        @test length(solutions) == 0
        @test number_enumerated >= 3000
    end

    @testcase_log "017c7c7b.json" begin
        payload = create_arc_task("017c7c7b.json")
        @info payload["name"]
        payload["DSL"]["logVariable"] = 0.0
        for d in payload["DSL"]["productions"]
            if d["expression"] != "rev_fix_param"
                d["logProbability"] = 0.0
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
        @test length(solutions) == 0
        @test number_enumerated >= 3000
    end

    @testcase_log "90c28cc7.json" begin
        payload = create_arc_task("90c28cc7.json")
        @info payload["name"]
        payload["DSL"] = Dict{String,Any}(
            "logVariable" => -0.1470305323600769,
            "logFreeVar" => 3.0,
            "logLambda" => -3.0,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => -0.16881588101387024,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.25931161642074585,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4925287365913391,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.18569040298461914,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0755251795053482,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5362246036529541,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2909930348396301,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.31873294711112976,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1803460270166397,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.03119467943906784,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4513780474662781,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.003251451998949051,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.32271361351013184,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.010576754808425903,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.04662089794874191,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.44141703844070435,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2139398753643036,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.13687890768051147,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3017200827598572,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.09566254913806915,
                    "expression" => "empty",
                    "is_reversible" => false,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.023701228201389313,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4516500234603882,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07319386303424835,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.22334522008895874,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2757069170475006,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05093861743807793,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.15926919877529144,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.19624638557434082,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2940804362297058,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5020074844360352,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.19406159222126007,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.41538429260253906,
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2902928292751312,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.035506345331668854,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.48586875200271606,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.15304088592529297,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.05445796996355057,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.6645252704620361,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07274571061134338,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.04600080847740173,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.6456637382507324,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.24719026684761047,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.07228969037532806,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2407141476869583,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t1) -> grid(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.24065333604812622,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1713692843914032,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3272753357887268,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.23884005844593048,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11140652000904083,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05768594145774841,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.15642637014389038,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.10428757965564728,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.46397799253463745,
                    "expression" => "empty_set",
                    "is_reversible" => false,
                    "type" => "set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.6705434322357178,
                    "expression" => "rev_groupby",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> t0 -> set(tuple2(t1, set(t0))) -> set(tuple2(t1, set(t0)))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.027076035737991333,
                    "expression" => "rev_greedy_cluster",
                    "is_reversible" => true,
                    "type" => "(t0 -> set(t0) -> bool) -> t0 -> set(set(t0)) -> set(set(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.22472700476646423,
                    "expression" => "not",
                    "is_reversible" => true,
                    "type" => "bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.21362434327602386,
                    "expression" => "and",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.010394498705863953,
                    "expression" => "or",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.31736278533935547,
                    "expression" => "all",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.34341609477996826,
                    "expression" => "any",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3697168529033661,
                    "expression" => "all_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.293144166469574,
                    "expression" => "any_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.10808463394641876,
                    "expression" => "abs",
                    "is_reversible" => true,
                    "type" => "int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.03666456416249275,
                    "expression" => "0",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.010524004697799683,
                    "expression" => "1",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.0,
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
        @test length(solutions) == 0
        @test number_enumerated >= 1000
    end

    @testcase_log "80af3007.json" begin
        payload = create_arc_task("80af3007.json")
        @info payload["name"]
        payload["DSL"] = Dict{String,Any}(
            "logVariable" => -0.1470305323600769,
            "logFreeVar" => 3.0,
            "logLambda" => -3.0,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => -0.16881588101387024,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.25931161642074585,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4925287365913391,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.18569040298461914,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0755251795053482,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5362246036529541,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2909930348396301,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.31873294711112976,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1803460270166397,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.03119467943906784,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4513780474662781,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.003251451998949051,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.32271361351013184,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.010576754808425903,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.04662089794874191,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.44141703844070435,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2139398753643036,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.13687890768051147,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3017200827598572,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.09566254913806915,
                    "expression" => "empty",
                    "is_reversible" => false,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.023701228201389313,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4516500234603882,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07319386303424835,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.22334522008895874,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2757069170475006,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05093861743807793,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.15926919877529144,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.19624638557434082,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2940804362297058,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5020074844360352,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.19406159222126007,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.41538429260253906,
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2902928292751312,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.035506345331668854,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.48586875200271606,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.15304088592529297,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.05445796996355057,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.6645252704620361,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07274571061134338,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.04600080847740173,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.6456637382507324,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.24719026684761047,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.07228969037532806,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2407141476869583,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t1) -> grid(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.24065333604812622,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1713692843914032,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3272753357887268,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.23884005844593048,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11140652000904083,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05768594145774841,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.15642637014389038,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.10428757965564728,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.46397799253463745,
                    "expression" => "empty_set",
                    "is_reversible" => false,
                    "type" => "set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.6705434322357178,
                    "expression" => "rev_groupby",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> t0 -> set(tuple2(t1, set(t0))) -> set(tuple2(t1, set(t0)))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.027076035737991333,
                    "expression" => "rev_greedy_cluster",
                    "is_reversible" => true,
                    "type" => "(t0 -> set(t0) -> bool) -> t0 -> set(set(t0)) -> set(set(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.22472700476646423,
                    "expression" => "not",
                    "is_reversible" => true,
                    "type" => "bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.21362434327602386,
                    "expression" => "and",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.010394498705863953,
                    "expression" => "or",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.31736278533935547,
                    "expression" => "all",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.34341609477996826,
                    "expression" => "any",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3697168529033661,
                    "expression" => "all_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.293144166469574,
                    "expression" => "any_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.10808463394641876,
                    "expression" => "abs",
                    "is_reversible" => true,
                    "type" => "int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.03666456416249275,
                    "expression" => "0",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.010524004697799683,
                    "expression" => "1",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.0,
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
        @test length(solutions) == 0
        @test number_enumerated >= 3000
    end

    @testcase_log "6a1e5592.json" begin
        payload = create_arc_task("6a1e5592.json")
        payload["DSL"] = Dict{String,Any}(
            "logVariable" => 0.11757951974868774,
            "logFreeVar" => 3.0,
            "logLambda" => -3.0,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => -0.14920374751091003,
                    "expression" => "rev_fix_param",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.22555723786354065,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3721669912338257,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.343523234128952,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5139976143836975,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.16321849822998047,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2341202199459076,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.17406690120697021,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5488288402557373,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4738664925098419,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.4406723380088806,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3349599540233612,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.08230067044496536,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5621746182441711,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.025621742010116577,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.02655257284641266,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07909157872200012,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.13159878551959991,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.29203855991363525,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.06708367168903351,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.76283198595047,
                    "expression" => "empty",
                    "is_reversible" => false,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.4808342456817627,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0543583407998085,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.16438798606395721,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.039353951811790466,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2735013961791992,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.198007732629776,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.6649982929229736,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0719628781080246,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11204414069652557,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.15075215697288513,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.44234317541122437,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.6542041301727295,
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3698766529560089,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.15270553529262543,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.09238337725400925,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.04443696513772011,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11335305869579315,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.13997429609298706,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.06586775183677673,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2629527449607849,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.12107181549072266,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.14485105872154236,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.4370531439781189,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.03831832855939865,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t1) -> grid(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1550624966621399,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.20972201228141785,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.025891413912177086,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1343633234500885,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.11344335228204727,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.10087767243385315,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.17858588695526123,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2506965398788452,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3153345584869385,
                    "expression" => "empty_set",
                    "is_reversible" => false,
                    "type" => "set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.7741934061050415,
                    "expression" => "rev_groupby",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> t0 -> set(tuple2(t1, set(t0))) -> set(tuple2(t1, set(t0)))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1313222497701645,
                    "expression" => "rev_greedy_cluster",
                    "is_reversible" => true,
                    "type" => "(t0 -> set(t0) -> bool) -> t0 -> set(set(t0)) -> set(set(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.18257468938827515,
                    "expression" => "not",
                    "is_reversible" => true,
                    "type" => "bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.25743627548217773,
                    "expression" => "and",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.36083704233169556,
                    "expression" => "or",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3036617636680603,
                    "expression" => "all",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.10103894770145416,
                    "expression" => "any",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4470073878765106,
                    "expression" => "all_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.057065531611442566,
                    "expression" => "any_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.39332807064056396,
                    "expression" => "abs",
                    "is_reversible" => true,
                    "type" => "int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07389692962169647,
                    "expression" => "max_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.45735955238342285,
                    "expression" => "min_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.014421507716178894,
                    "expression" => "collect",
                    "is_reversible" => true,
                    "type" => "set(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11396943032741547,
                    "expression" => "0",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.16639654338359833,
                    "expression" => "1",
                    "is_reversible" => false,
                    "type" => "int",
                ),
            ],
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
        @test length(solutions) == 0
        @test number_enumerated >= 300
    end

    @testcase_log "77352326.json" begin
        payload = create_arc_task("77352326.json", "sortOfARC/")
        payload["DSL"] = Dict{String,Any}(
            "logFreeVar" => 0.0,
            "logVariable" => 0.3263143301010132,
            "logLambda" => 0.0,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => -0.26009663939476013,
                    "expression" => "rev_fix_param",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5106646418571472,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.05265367031097412,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.19276094436645508,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.33183038234710693,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1419844627380371,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.21597525477409363,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.16166384518146515,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3061349093914032,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.07610253244638443,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.646217942237854,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.19072723388671875,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.11397601664066315,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5652339458465576,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2681933641433716,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2903901934623718,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2667853832244873,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2669607698917389,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.21574783325195312,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3594146966934204,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.20972324907779694,
                    "expression" => "empty",
                    "is_reversible" => true,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1095760390162468,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.17027275264263153,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1449996680021286,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.22954635322093964,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2977787256240845,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.8057296872138977,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.38684606552124023,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.376747190952301,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.31760290265083313,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0940081924200058,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3111276924610138,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.23550884425640106,
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.43426579236984253,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5637559294700623,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.1135353222489357,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.10652853548526764,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.005080468952655792,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2542416453361511,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.7583125829696655,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.19957420229911804,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5662212371826172,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.21633177995681763,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.38265013694763184,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.06507925689220428,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t1) -> grid(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.36707258224487305,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3899320662021637,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.0015176162123680115,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2700403928756714,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.21556152403354645,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2102193683385849,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.2428511679172516,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.3955332040786743,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.027274534106254578,
                    "expression" => "empty_set",
                    "is_reversible" => true,
                    "type" => "set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.0021641552448272705,
                    "expression" => "rev_groupby",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> t0 -> set(tuple2(t1, set(t0))) -> set(tuple2(t1, set(t0)))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2714475691318512,
                    "expression" => "rev_greedy_cluster",
                    "is_reversible" => true,
                    "type" => "(t0 -> set(t0) -> bool) -> t0 -> set(set(t0)) -> set(set(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.02452974021434784,
                    "expression" => "not",
                    "is_reversible" => true,
                    "type" => "bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4067993462085724,
                    "expression" => "and",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.2539457082748413,
                    "expression" => "or",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3339998424053192,
                    "expression" => "all",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5056955218315125,
                    "expression" => "any",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4993366599082947,
                    "expression" => "all_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.38480138778686523,
                    "expression" => "any_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.1552448868751526,
                    "expression" => "abs",
                    "is_reversible" => true,
                    "type" => "int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.30245423316955566,
                    "expression" => "max_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.04224035143852234,
                    "expression" => "min_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.15396639704704285,
                    "expression" => "collect",
                    "is_reversible" => true,
                    "type" => "set(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.4184340834617615,
                    "expression" => "0",
                    "is_reversible" => true,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.24294883012771606,
                    "expression" => "1",
                    "is_reversible" => true,
                    "type" => "int",
                ),
            ],
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
        @test length(solutions) == 0
        @test number_enumerated >= 300
    end

    @testcase_log "0f39a9d9.json" begin
        payload = create_arc_task("0f39a9d9.json", "sortOfARC/")
        payload["DSL"] = Dict{String,Any}(
            "logFreeVar" => 48.05488586425781,
            "logVariable" => 45.09019470214844,
            "logLambda" => -5.512786388397217,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => -4.4848408699035645,
                    "expression" => "rev_fix_param",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.427365779876709,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.417635679244995,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.68174934387207,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.849295139312744,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.187074184417725,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.759178638458252,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.9904186725616455,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.3583803176879883,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.677355766296387,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.0401177406311035,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.753006935119629,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.417627811431885,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.808785438537598,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.8323252201080322,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.922137975692749,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.334958076477051,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.29662561416626,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.15322494506836,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.710867881774902,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 11.911661148071289,
                    "expression" => "empty",
                    "is_reversible" => true,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.223567962646484,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -1.79932701587677,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.67533540725708,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.007132053375244,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.7484312057495117,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.54411506652832,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.4160571098327637,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.3807601928710938,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.6409010887145996,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.063720464706421,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.562422275543213,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.28338623046875,
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.921088933944702,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 42.875667572021484,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.2726688385009766,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.26898193359375,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.003082275390625,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.151334762573242,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.8944969177246094,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.91925573348999,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.939056873321533,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.283382415771484,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.026844710111618042,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.05003274977207184,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t1) -> grid(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.642088413238525,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.728720188140869,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.28397798538208,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.13727951049805,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.764488697052002,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.5884809494018555,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.139751434326172,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.59086275100708,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.408057451248169,
                    "expression" => "empty_set",
                    "is_reversible" => true,
                    "type" => "set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.737311840057373,
                    "expression" => "rev_groupby",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> t0 -> set(tuple2(t1, set(t0))) -> set(tuple2(t1, set(t0)))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5638431906700134,
                    "expression" => "rev_greedy_cluster",
                    "is_reversible" => true,
                    "type" => "(t0 -> set(t0) -> bool) -> t0 -> set(set(t0)) -> set(set(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.9442758560180664,
                    "expression" => "not",
                    "is_reversible" => true,
                    "type" => "bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.59445571899414,
                    "expression" => "and",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.6363189220428467,
                    "expression" => "or",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.4170656204223633,
                    "expression" => "all",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -1.83354651927948,
                    "expression" => "any",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.3267600536346436,
                    "expression" => "all_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.43378829956055,
                    "expression" => "any_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.4392521381378174,
                    "expression" => "abs",
                    "is_reversible" => true,
                    "type" => "int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.21498441696167,
                    "expression" => "max_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.430281639099121,
                    "expression" => "min_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.790950775146484,
                    "expression" => "collect",
                    "is_reversible" => true,
                    "type" => "set(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.67546272277832,
                    "expression" => "0",
                    "is_reversible" => true,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.9687013626098633,
                    "expression" => "1",
                    "is_reversible" => true,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.09053421020508,
                    "expression" => "#(lambda (lambda (rev_fold_set (lambda (lambda (rev_greedy_cluster \$2 \$1 \$0))) empty_set (map_set (lambda (map_set (lambda (tuple2 \$0 (tuple2_second \$1))) (tuple2_first \$0))) (map_set (lambda (tuple2 ((lambda ((lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first \$0) (tuple2_first \$1)) (+ (tuple2_second \$0) (tuple2_second \$1)))) \$1) \$0 (lambda (tuple2 (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_first \$0)) (collect \$0)) max_int) (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_second \$0)) (collect \$0)) max_int))))) (tuple2_first (tuple2_first \$1)))) (tuple2_second (tuple2_first \$0))) (tuple2_second \$0))) \$1)))))",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(tuple2(int, int), set(tuple2(int, int))), t0)) -> (tuple2(tuple2(int, int), t0) -> set(tuple2(tuple2(int, int), t0)) -> bool) -> set(tuple2(tuple2(int, int), t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.19208908081055,
                    "expression" => "#(lambda (lambda (lambda (rev_select_set (lambda (eq? (tuple2_second (tuple2_first \$0)) \$1)) (map_set (lambda (tuple2 (tuple2 (tuple2 (+ (tuple2_first (tuple2_first (tuple2_first \$0))) Const(int, 1)) (tuple2_second (tuple2_first (tuple2_first \$0)))) (tuple2_second (tuple2_first \$0))) (tuple2_second \$0))) \$1) \$2))))",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(tuple2(int, t0), t1), t2)) -> set(tuple2(tuple2(tuple2(int, t0), t1), t2)) -> t1 -> set(tuple2(tuple2(tuple2(int, t0), t1), t2))",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.7846436500549316,
                    "expression" => "#(lambda (lambda (lambda (abs (- (\$1 (tuple2_first \$0)) (\$1 (tuple2_first \$2)))))))",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> (t0 -> int) -> tuple2(t0, t2) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.06684494018555,
                    "expression" => "#(lambda (columns_to_grid (reverse (columns (rows_to_grid \$0)))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.38026809692383,
                    "expression" => "#(lambda (rows_to_grid (reverse \$0)))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.85282516479492,
                    "expression" => "#(lambda (not (gt? \$0 1)))",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 21.52988624572754,
                    "expression" => "#(lambda (lambda (rows_to_grid (concat \$0 \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.19121170043945,
                    "expression" => "#(lambda (lambda (lambda (rev_fix_param (rev_select_set (lambda (eq? (tuple2_second (tuple2_first \$0)) \$3)) \$0 \$1) \$2 (lambda Const(set(tuple2(int, int)), Set([(0, 0), (0, 2), (2, 0), (1, 1), (0, 1), (2, 2), (2, 1)])))))))",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, int)) -> set(tuple2(tuple2(t0, set(tuple2(int, int))), t1)) -> set(tuple2(tuple2(t0, set(tuple2(int, int))), t1)) -> set(tuple2(tuple2(t0, set(tuple2(int, int))), t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.4210031032562256,
                    "expression" => "#(lambda (columns_to_grid (concat \$0 (reverse \$0))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.853553771972656,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (lambda (abs (- (\$1 (tuple2_first \$0)) (\$1 (tuple2_first \$2))))))) \$0 (lambda (tuple2_first \$0)) \$1)))",
                    "is_reversible" => true,
                    "type" => "tuple2(tuple2(int, t0), t1) -> tuple2(tuple2(int, t0), t2) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.85343933105469,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (lambda (abs (- (\$1 (tuple2_first \$0)) (\$1 (tuple2_first \$2))))))) \$0 (lambda (tuple2_second \$0)) \$1)))",
                    "is_reversible" => true,
                    "type" => "tuple2(tuple2(t0, int), t1) -> tuple2(tuple2(t0, int), t2) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.58976745605469,
                    "expression" => "#(lambda (lambda (lambda (rev_select_grid (lambda (eq? \$0 \$1)) \$1 \$2))))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0) -> t0 -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.786739349365234,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) \$0 (reverse \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 42.03545379638672,
                    "expression" => "#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.54703903198242,
                    "expression" => "#(lambda (#(lambda (lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) \$0 (reverse \$1)))) \$0 \$0))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.58977127075195,
                    "expression" => "#(lambda (lambda (lambda (rev_fix_param (#(lambda (lambda (lambda (rev_select_grid (lambda (eq? \$0 \$1)) \$1 \$2)))) \$0 \$1 \$2) \$2 (lambda Const(color, 0))))))",
                    "is_reversible" => true,
                    "type" => "color -> grid(color) -> grid(color) -> grid(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.88749694824219,
                    "expression" => "#(lambda (rows_to_grid (columns \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.13601303100586,
                    "expression" => "#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.56547927856445,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) \$0 (reverse \$1)))) (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$1 \$0) (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$0 \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.94345474243164,
                    "expression" => "#(lambda (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns \$0))) (rows_to_grid \$0)))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 43.74740219116211,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$0 (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> list(list(t0)) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.03434753417969,
                    "expression" => "#(lambda (#(lambda (#(lambda (lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) \$0 (reverse \$1)))) \$0 \$0)) (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$0 \$0)))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 23.36907196044922,
                    "expression" => "#(lambda (lambda (lambda (rows_to_grid (#(lambda (lambda (lambda (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$0 (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$1 \$2))))) \$2 \$0 (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$1 \$2))))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.573234558105469,
                    "expression" => "#(lambda (lambda (lambda (\$0 (\$1 \$2) (\$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "t0 -> (t0 -> t1) -> (t1 -> t1 -> t2) -> t2",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.73984909057617,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (lambda (rows_to_grid (#(lambda (lambda (lambda (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$0 (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$1 \$2))))) \$2 \$0 (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$1)))) \$1 \$2)))))) \$0 \$1 \$1)))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.577850341796875,
                    "expression" => "#(lambda (#(lambda (columns_to_grid (concat \$0 (reverse \$0)))) (columns \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.95268630981445,
                    "expression" => "#(lambda (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns \$0))) (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns \$0))) \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.36724090576172,
                    "expression" => "#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> t0 -> t0 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.54823303222656,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 (tuple2_first \$1) \$2))))",
                    "is_reversible" => true,
                    "type" => "t0 -> tuple2(t0, t1) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.965179443359375,
                    "expression" => "#(lambda (lambda (#(lambda (rows_to_grid (reverse \$0))) (cons \$0 \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.36848449707031,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns \$0))) (rows_to_grid \$0))) (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 43.389015197753906,
                    "expression" => "#(lambda (concat \$0 \$0))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.437782287597656,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) Const(list(color), Int64[]) \$0 \$1)))",
                    "is_reversible" => true,
                    "type" => "color -> color -> list(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.36848449707031,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns \$0))) (rows_to_grid \$0))) (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 44.84197235107422,
                    "expression" => "#(lambda (lambda (lambda (rows_to_grid (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 46.112545013427734,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) Const(list(color), Int64[]) \$0 \$1))) (car \$0) \$1)))",
                    "is_reversible" => false,
                    "type" => "color -> list(color) -> list(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.61225509643555,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (lambda (#(lambda (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns \$0))) (rows_to_grid \$0))) (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 \$1 \$2))))) \$0 \$1 Const(list(list(color)), Vector{Int64}[]))))",
                    "is_reversible" => true,
                    "type" => "list(color) -> list(color) -> grid(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.54823303222656,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 (tuple2_first \$1) \$2))))",
                    "is_reversible" => true,
                    "type" => "t0 -> tuple2(t0, t1) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 45.36848449707031,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns \$0))) (rows_to_grid \$0))) (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(list(t0)) -> grid(t0)",
                ),
            ],
        )
        task, maximum_frontier, g, type_weights, hyperparameters, _mfp, _nc, timeout, verbose, program_timeout =
            load_problems(payload)
        # timeout = 300
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
        @test length(solutions) == 0
        @test number_enumerated >= 300
    end

    @testcase_log "d07ae81c.json" begin
        payload = create_arc_task("d07ae81c.json")
        payload["DSL"] = Dict{String,Any}(
            "logFreeVar" => 4.210286617279053,
            "logVariable" => 2.4047508239746094,
            "logLambda" => -6.987171649932861,
            "productions" => Any[
                Dict{String,Any}(
                    "logProbability" => -6.938011646270752,
                    "expression" => "rev_fix_param",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> (t0 -> t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.983212471008301,
                    "expression" => "map",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> list(t0) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.001254081726074,
                    "expression" => "map_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> set(t0) -> set(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.8940653800964355,
                    "expression" => "map_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> grid(t0) -> grid(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.523049831390381,
                    "expression" => "map2",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> list(t0) -> list(t1) -> list(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.998284816741943,
                    "expression" => "map2_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t2) -> grid(t0) -> grid(t1) -> grid(t2)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.663481712341309,
                    "expression" => "unfold",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> (t0 -> t1) -> (t0 -> t0) -> t0 -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -1.1714290380477905,
                    "expression" => "range",
                    "is_reversible" => true,
                    "type" => "int -> list(int)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.507535934448242,
                    "expression" => "index",
                    "is_reversible" => false,
                    "type" => "int -> list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -8.139780044555664,
                    "expression" => "index2",
                    "is_reversible" => false,
                    "type" => "int -> int -> grid(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -7.433315277099609,
                    "expression" => "fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> list(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -7.143001079559326,
                    "expression" => "fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> set(t0) -> t1 -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.682707786560059,
                    "expression" => "fold_h",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -7.012338638305664,
                    "expression" => "fold_v",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> grid(t0) -> list(t1) -> list(t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.174902439117432,
                    "expression" => "length",
                    "is_reversible" => false,
                    "type" => "list(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.206169128417969,
                    "expression" => "height",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -7.00161600112915,
                    "expression" => "width",
                    "is_reversible" => false,
                    "type" => "grid(t0) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.856771945953369,
                    "expression" => "if",
                    "is_reversible" => false,
                    "type" => "bool -> t0 -> t0 -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.5791050791740417,
                    "expression" => "+",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.577991485595703,
                    "expression" => "-",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.9231936931610107,
                    "expression" => "empty",
                    "is_reversible" => true,
                    "type" => "list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.4964511394500732,
                    "expression" => "cons",
                    "is_reversible" => true,
                    "type" => "t0 -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.553989410400391,
                    "expression" => "car",
                    "is_reversible" => false,
                    "type" => "list(t0) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -7.047621726989746,
                    "expression" => "cdr",
                    "is_reversible" => false,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.3741164207458496,
                    "expression" => "empty?",
                    "is_reversible" => false,
                    "type" => "list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.544501304626465,
                    "expression" => "*",
                    "is_reversible" => true,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.364431381225586,
                    "expression" => "mod",
                    "is_reversible" => false,
                    "type" => "int -> int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.337493419647217,
                    "expression" => "gt?",
                    "is_reversible" => false,
                    "type" => "int -> int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.256502628326416,
                    "expression" => "eq?",
                    "is_reversible" => false,
                    "type" => "t0 -> t0 -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.391485214233398,
                    "expression" => "is-prime",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.070953845977783,
                    "expression" => "is-square",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -1.8255560398101807,
                    "expression" => "repeat",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.9259942770004272,
                    "expression" => "repeat_grid",
                    "is_reversible" => true,
                    "type" => "t0 -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.05077200382947922,
                    "expression" => "concat",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.27031010389328003,
                    "expression" => "rows",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.94770747423172,
                    "expression" => "columns",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.6475334167480469,
                    "expression" => "rows_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.097764492034912,
                    "expression" => "columns_to_grid",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.734226703643799,
                    "expression" => "rev_select",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> list(t0) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.173499584197998,
                    "expression" => "rev_select_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> set(t0) -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.763171195983887,
                    "expression" => "rev_select_grid",
                    "is_reversible" => true,
                    "type" => "(t0 -> bool) -> grid(t0) -> grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.11726099252700806,
                    "expression" => "rev_list_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, t0)) -> int -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.4662749767303467,
                    "expression" => "rev_grid_elements",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(int, int), t0)) -> int -> int -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5999318957328796,
                    "expression" => "zip2",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t1) -> list(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.6224709153175354,
                    "expression" => "zip_grid2",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t1) -> grid(tuple2(t0, t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.427278995513916,
                    "expression" => "tuple2",
                    "is_reversible" => true,
                    "type" => "t0 -> t1 -> tuple2(t0, t1)",
                ),
                Dict{String,Any}(
                    "logProbability" => -2.173940658569336,
                    "expression" => "tuple2_first",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t0",
                ),
                Dict{String,Any}(
                    "logProbability" => -1.6877954006195068,
                    "expression" => "tuple2_second",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> t1",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.4258594512939453,
                    "expression" => "reverse",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -7.509891033172607,
                    "expression" => "rev_fold",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.9483642578125,
                    "expression" => "rev_fold_set",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1 -> t1) -> t1 -> t1 -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.748763084411621,
                    "expression" => "list_to_set",
                    "is_reversible" => false,
                    "type" => "list(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.273045539855957,
                    "expression" => "adjoin",
                    "is_reversible" => true,
                    "type" => "t0 -> set(t0) -> set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.0026040077209473,
                    "expression" => "empty_set",
                    "is_reversible" => true,
                    "type" => "set(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.071271896362305,
                    "expression" => "rev_groupby",
                    "is_reversible" => true,
                    "type" => "(t0 -> t1) -> t0 -> set(tuple2(t1, set(t0))) -> set(tuple2(t1, set(t0)))",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.506991446018219,
                    "expression" => "rev_greedy_cluster",
                    "is_reversible" => true,
                    "type" => "(t0 -> set(t0) -> bool) -> t0 -> set(set(t0)) -> set(set(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.2272000312805176,
                    "expression" => "not",
                    "is_reversible" => true,
                    "type" => "bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 4.845263481140137,
                    "expression" => "and",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.371472120285034,
                    "expression" => "or",
                    "is_reversible" => true,
                    "type" => "bool -> bool -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.063954830169678,
                    "expression" => "all",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.795092821121216,
                    "expression" => "any",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> list(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.3248844146728516,
                    "expression" => "all_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 5.20543909072876,
                    "expression" => "any_set",
                    "is_reversible" => false,
                    "type" => "(t0 -> bool) -> set(t0) -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.514819622039795,
                    "expression" => "abs",
                    "is_reversible" => true,
                    "type" => "int -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.373778343200684,
                    "expression" => "max_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -5.840609550476074,
                    "expression" => "min_int",
                    "is_reversible" => false,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -1.7864583730697632,
                    "expression" => "collect",
                    "is_reversible" => true,
                    "type" => "set(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.447747230529785,
                    "expression" => "0",
                    "is_reversible" => true,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.197281837463379,
                    "expression" => "1",
                    "is_reversible" => true,
                    "type" => "int",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.468907356262207,
                    "expression" => "#(lambda (lambda (rev_fold_set (lambda (lambda (rev_greedy_cluster \$3 \$1 \$0))) empty_set (map_set (lambda (map_set (lambda (tuple2 \$0 (tuple2_second \$1))) (tuple2_first \$0))) (map_set (lambda (tuple2 ((lambda ((lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first \$0) (tuple2_first \$1)) (+ (tuple2_second \$0) (tuple2_second \$1)))) \$1) \$0 (lambda (tuple2 (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_first \$0)) (collect \$0)) max_int) (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_second \$0)) (collect \$0)) max_int))))) (tuple2_first (tuple2_first \$1)))) (tuple2_second (tuple2_first \$0))) (tuple2_second \$0))) \$0)))))",
                    "is_reversible" => true,
                    "type" => "(tuple2(tuple2(int, int), t0) -> set(tuple2(tuple2(int, int), t0)) -> bool) -> set(tuple2(tuple2(tuple2(int, int), set(tuple2(int, int))), t0)) -> set(tuple2(tuple2(int, int), t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.382676124572754,
                    "expression" => "#(lambda (lambda (lambda (rev_select_set (lambda (eq? (tuple2_second (tuple2_first \$0)) \$1)) (map_set (lambda (tuple2 (tuple2 (tuple2 (+ (tuple2_first (tuple2_first (tuple2_first \$0))) Const(int, 1)) (tuple2_second (tuple2_first (tuple2_first \$0)))) (tuple2_second (tuple2_first \$0))) (tuple2_second \$0))) \$1) \$2))))",
                    "is_reversible" => true,
                    "type" => "set(tuple2(tuple2(tuple2(int, t0), t1), t2)) -> set(tuple2(tuple2(tuple2(int, t0), t1), t2)) -> t1 -> set(tuple2(tuple2(tuple2(int, t0), t1), t2))",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.152088165283203,
                    "expression" => "#(lambda (rows_to_grid (reverse \$0)))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -6.364397048950195,
                    "expression" => "#(lambda (lambda (lambda (abs (- (\$2 (tuple2_first \$0)) (\$2 (tuple2_first \$1)))))))",
                    "is_reversible" => true,
                    "type" => "(t0 -> int) -> tuple2(t0, t1) -> tuple2(t0, t2) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.26383036375045776,
                    "expression" => "#(lambda (lambda (rows_to_grid (concat \$0 \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.6644562482833862,
                    "expression" => "#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns (#(lambda (rows_to_grid (reverse \$0))) \$0))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 5.758904933929443,
                    "expression" => "#(lambda (not (gt? \$0 1)))",
                    "is_reversible" => false,
                    "type" => "int -> bool",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.7431526184082031,
                    "expression" => "#(lambda (columns_to_grid (concat \$0 (reverse \$0))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.3968544006347656,
                    "expression" => "#(lambda (lambda (lambda (rev_fix_param (rev_select_set (lambda (eq? (tuple2_second (tuple2_first \$0)) \$3)) \$0 \$1) \$2 (lambda Const(set(tuple2(int, int)), Set([(0, 0), (0, 2), (2, 0), (1, 1), (0, 1), (2, 2), (2, 1)])))))))",
                    "is_reversible" => true,
                    "type" => "set(tuple2(int, int)) -> set(tuple2(tuple2(t0, set(tuple2(int, int))), t1)) -> set(tuple2(tuple2(t0, set(tuple2(int, int))), t1)) -> set(tuple2(tuple2(t0, set(tuple2(int, int))), t1))",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.3758389949798584,
                    "expression" => "#(lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$0))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.4295623302459717,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (lambda (abs (- (\$2 (tuple2_first \$0)) (\$2 (tuple2_first \$1))))))) (lambda (tuple2_first \$0)) \$0 \$1)))",
                    "is_reversible" => true,
                    "type" => "tuple2(tuple2(int, t0), t1) -> tuple2(tuple2(int, t0), t2) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.4673371315002441,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (lambda (abs (- (\$2 (tuple2_first \$0)) (\$2 (tuple2_first \$1))))))) (lambda (tuple2_second \$0)) \$0 \$1)))",
                    "is_reversible" => true,
                    "type" => "tuple2(tuple2(t0, int), t1) -> tuple2(tuple2(t0, int), t2) -> int",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.7729018926620483,
                    "expression" => "#(lambda (lambda (lambda (rev_select_grid (lambda (eq? \$0 \$1)) \$1 \$2))))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0) -> t0 -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.7531962394714355,
                    "expression" => "#(lambda (rows_to_grid (columns \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.9696881771087646,
                    "expression" => "#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) \$0 \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> list(list(t0))",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.772963047027588,
                    "expression" => "#(lambda (lambda (lambda (rev_fix_param (#(lambda (lambda (lambda (rev_select_grid (lambda (eq? \$0 \$1)) \$1 \$2)))) \$0 \$1 \$2) \$2 (lambda Const(color, 0))))))",
                    "is_reversible" => true,
                    "type" => "color -> grid(color) -> grid(color) -> grid(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.0685086250305176,
                    "expression" => "#(lambda (columns_to_grid (reverse \$0)))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.5034117698669434,
                    "expression" => "#(lambda (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns (#(lambda (rows_to_grid (reverse \$0))) \$0)))) (columns \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.596003532409668,
                    "expression" => "#(lambda (lambda (#(lambda (columns_to_grid (concat \$0 (reverse \$0)))) (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) \$0 \$1)))) \$0 \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.1363236904144287,
                    "expression" => "#(lambda (#(lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$0)) (rows \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.1701338291168213,
                    "expression" => "#(lambda (#(lambda (columns_to_grid (concat \$0 (reverse \$0)))) (columns \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.2527344226837158,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (#(lambda (lambda (columns (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) \$0 \$1)))) \$0 \$1) \$2))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(list(t0)) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.4830232858657837,
                    "expression" => "#(lambda (#(lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$0)) (columns \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 2.1492257118225098,
                    "expression" => "#(lambda (#(lambda (#(lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$0)) (columns \$0))) (#(lambda (#(lambda (#(lambda (lambda (rows_to_grid (concat \$0 \$1)))) (reverse \$0) \$0)) (columns \$0))) \$0)))",
                    "is_reversible" => true,
                    "type" => "grid(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.8871207237243652,
                    "expression" => "#(lambda (#(lambda (#(lambda (#(lambda (rows_to_grid (reverse \$0))) (columns (#(lambda (rows_to_grid (reverse \$0))) \$0)))) (columns \$0))) (#(lambda (rows_to_grid (reverse \$0))) \$0)))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.6988493800163269,
                    "expression" => "#(lambda (concat \$0 \$0))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.37931180000305176,
                    "expression" => "#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> t0 -> t0 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.6701009273529053,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 (tuple2_second (tuple2_second \$1)) \$2))))",
                    "is_reversible" => true,
                    "type" => "t0 -> tuple2(t1, tuple2(t2, t0)) -> list(t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.3798781633377075,
                    "expression" => "#(lambda (lambda (lambda (columns_to_grid (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> list(t0) -> list(list(t0)) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.1906237602233887,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) Const(list(color), Any[]) \$0 \$1)))",
                    "is_reversible" => true,
                    "type" => "color -> color -> list(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => -3.4164633750915527,
                    "expression" => "#(lambda (lambda (cons (tuple2_first \$0) \$1)))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> tuple2(t0, t1) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.5419832468032837,
                    "expression" => "#(lambda (lambda (reverse (cons \$0 \$1))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> t0 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.2779970169067383,
                    "expression" => "#(lambda (lambda (cons (tuple2_second \$0) \$1)))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> tuple2(t1, t0) -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -1.8830676078796387,
                    "expression" => "#(lambda (lambda (#(lambda (lambda (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) Const(list(color), Any[]) \$0 \$1))) \$0 (tuple2_second \$1))))",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, color) -> color -> list(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => -0.3792995512485504,
                    "expression" => "#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2)))))",
                    "is_reversible" => true,
                    "type" => "list(t0) -> t0 -> t0 -> list(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => -4.042369365692139,
                    "expression" => "#(lambda (cons \$0 Const(list(color), Any[])))",
                    "is_reversible" => true,
                    "type" => "color -> list(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.8623709678649902,
                    "expression" => "#(lambda (lambda (#(lambda (rows_to_grid (reverse \$0))) (cons \$0 \$1))))",
                    "is_reversible" => true,
                    "type" => "list(list(t0)) -> list(t0) -> grid(t0)",
                ),
                Dict{String,Any}(
                    "logProbability" => 1.0447031259536743,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (lambda (lambda (columns_to_grid (#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2))))) \$0 \$1 \$2))))) (#(lambda (lambda (cons (tuple2_second \$0) \$1))) (#(lambda (lambda (cons (tuple2_second \$0) \$1))) Const(list(color), Any[]) \$0) \$1) \$2 Const(list(list(color)), Vector{Any}[])))))",
                    "is_reversible" => true,
                    "type" => "list(color) -> tuple2(t0, color) -> tuple2(t1, color) -> grid(color)",
                ),
                Dict{String,Any}(
                    "logProbability" => 0.6743289828300476,
                    "expression" => "#(lambda (lambda (lambda (#(lambda (lambda (cons (tuple2_first \$0) \$1))) (#(lambda (lambda (cons (tuple2_second \$0) \$1))) \$0 \$1) \$2))))",
                    "is_reversible" => true,
                    "type" => "tuple2(t0, t1) -> tuple2(t2, t0) -> list(t0) -> list(t0)",
                ),
            ],
        )
        task, maximum_frontier, g, type_weights, hyperparameters, _mfp, _nc, timeout, verbose, program_timeout =
            load_problems(payload)
        # timeout = 300
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
        @test length(solutions) == 0
        @test number_enumerated >= 300
    end

    # @testset "8731374e.json" begin
    #     payload = create_arc_task("8731374e.json")
    #     @info payload["name"]
    #     task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
    #     solutions, number_enumerated = @time enumerate_for_task(
    #         Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout),
    #         g,
    #         type_weights,
    #         task,
    #         maximum_frontier,
    #         timeout,
    #         verbose,
    #     )
    #     @test length(solutions) == 0
    #     @test number_enumerated >= 1
    #     @test number_enumerated < 10000
    # end
end

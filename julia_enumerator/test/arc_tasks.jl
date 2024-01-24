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
        @test number_enumerated >= 1000
    end

    @testcase_log "5c2c9af4.json" begin
        payload = create_arc_task("5c2c9af4.json")
        @info payload["name"]
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
        @test number_enumerated >= 1500
    end

    @testcase_log "23581191.json" begin
        payload = create_arc_task("23581191.json")
        @info payload["name"]
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
        @test number_enumerated >= 3000
    end

    @testcase_log "4258a5f9.json" begin
        payload = create_arc_task("4258a5f9.json")
        @info payload["name"]
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
        @test number_enumerated >= 1000
    end

    @testcase_log "f25ffba3.json" begin
        payload = create_arc_task("f25ffba3.json")
        @info payload["name"]
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
        @test length(solutions) >= 4
        @test number_enumerated < 10000
    end

    @testcase_log "7837ac64.json" begin
        payload = create_arc_task("7837ac64.json")
        @info payload["name"]
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
        @test number_enumerated >= 1500
    end

    @testcase_log "6fa7a44f.json" begin
        payload = create_arc_task("6fa7a44f.json")
        @info payload["name"]
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
        @test number_enumerated < 15000
    end

    @testcase_log "bbc9ae5d.json" begin
        payload = create_arc_task("bbc9ae5d.json")
        @info payload["name"]
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
        @test number_enumerated >= 1000
    end

    @testcase_log "63613498.json" begin
        payload = create_arc_task("63613498.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        # verbose = true
        # timeout = 600
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
        @test number_enumerated >= 3000
    end

    @testcase_log "d8c310e9.json" begin
        payload = create_arc_task("d8c310e9.json")
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        # verbose = true
        # timeout = 600
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


sample_payload = Dict{String,Any}(
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
            Dict{String,Any}("logProbability" => 0.0, "expression" => "0", "is_reversible" => false, "type" => "int"),
            Dict{String,Any}("logProbability" => 0.0, "expression" => "1", "is_reversible" => false, "type" => "int"),
        ],
    ),
    "type_weights" =>
        Dict{String,Any}("int" => 1.0, "list" => 1.0, "color" => 1.0, "bool" => 1.0, "float" => 1.0, "grid" => 1.0),
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
    arc_task = JSON.parsefile(filename)
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
        Dict{String,Any}("inputs" => Dict{String,Any}("inp0" => example["input"]), "output" => example["output"])
        for example in arc_task["train"]
    ]
    task_dict["test_examples"] = Any[
        Dict{String,Any}("inputs" => Dict{String,Any}("inp0" => example["input"]), "output" => example["output"])
        for example in arc_task["test"]
    ]
    return create_task(task_dict)
end

function run_tests(is_start)
    payloads = Any[
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
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
        ),
        create_task(
            Dict{String,Any}(
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
        ),
    ]

    #get files in directory
    files = readdir("dreamcoder/domains/arc/ARC/data/training", join = true)

    if is_start
        payloads = [create_arc_task(file) for file in files[1:3]]
        # payloads = vcat(payloads[1:2], arc_payloads)
    else
        payloads = [create_arc_task(file) for file in files[4:15]]
        # payloads = payloads[3:end]
    end

    for payload in payloads
        @info payload["name"]
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        @time enumerate_for_task(g, type_weights, task, maximum_frontier, timeout, verbose)
    end
end


using Test

# if false
#     include("../src/solver.jl")
# end
using solver:
    load_problems,
    parse_program,
    ProgramBlock,
    ReverseProgramBlock,
    LetClause,
    LetRevClause,
    t0,
    is_reversible,
    FreeVar,
    Apply,
    Abstraction,
    Hole,
    Primitive,
    Invented,
    create_starting_context,
    enqueue_updates,
    save_changes!,
    enumeration_iteration,
    state_finished,
    get_connected_from,
    get_connected_to,
    show_program,
    HitResult,
    BlockPrototype,
    application_parse,
    every_primitive

using DataStructures

@testset "Reachable solutions" begin
    sample_payload = Dict{String,Any}(
        "DSL" => Dict{String,Any}(
            "logVariable" => 3.0,
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
                    "logProbability" => 3.0,
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
                    "logProbability" => 3.0,
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
                    "logProbability" => 3.0,
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
                    "logProbability" => 0.0,
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
                    "is_reversible" => false,
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

    sample_payload2 = Dict{String,Any}(
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
                    "logProbability" => 0.0,
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

    function create_task(task_dict, sample_payload = sample_payload)
        result = copy(sample_payload)
        result["task"] = task_dict
        result["name"] = task_dict["name"]
        return result
    end

    _used_vars(p::FreeVar) = [p.var_id]
    _used_vars(p::Apply) = vcat(_used_vars(p.f), _used_vars(p.x))
    _used_vars(p::Abstraction) = _used_vars(p.b)
    _used_vars(::Any) = []

    function _extract_blocks(task, target_program, verbose = false)
        vars_mapping = Dict{Any,UInt64}()
        vars_from_input = Set{Any}()
        for (arg, _) in task.task_type.arguments
            vars_mapping[arg] = length(vars_mapping) + 1
            push!(vars_from_input, arg)
        end
        vars_mapping["out"] = length(vars_mapping) + 1
        copied_vars = 0
        blocks = []
        p = target_program
        while true
            if verbose
                @info p
                @info vars_mapping
                @info blocks
                @info vars_from_input
                @info copied_vars
            end
            if p isa LetClause
                vars = _used_vars(p.v)
                if verbose
                    @info p.v
                    @info vars
                end
                in_vars = []
                for v in vars
                    if !haskey(vars_mapping, v)
                        vars_mapping[v] = length(vars_mapping) + copied_vars + 1
                        push!(in_vars, vars_mapping[v])
                    elseif v in vars_from_input
                        copied_vars += 1
                        push!(in_vars, length(vars_mapping) + copied_vars)
                        copy_block = ProgramBlock(
                            FreeVar(t0, vars_mapping[v]),
                            t0,
                            0.0,
                            [vars_mapping[v]],
                            length(vars_mapping) + copied_vars,
                            false,
                        )
                        push!(blocks, copy_block)
                    else
                        push!(in_vars, vars_mapping[v])
                    end
                end
                if !haskey(vars_mapping, p.var_id)
                    vars_mapping[p.var_id] = length(vars_mapping) + copied_vars + 1
                end
                bl = ProgramBlock(p.v, t0, 0.0, in_vars, vars_mapping[p.var_id], is_reversible(p.v))
                push!(blocks, bl)
                p = p.b
            elseif p isa LetRevClause
                if !haskey(vars_mapping, p.inp_var_id)
                    vars_mapping[p.inp_var_id] = length(vars_mapping) + copied_vars + 1
                end
                for v in p.var_ids
                    if !haskey(vars_mapping, v)
                        vars_mapping[v] = length(vars_mapping) + copied_vars + 1
                    end
                    if p.inp_var_id in vars_from_input
                        push!(vars_from_input, v)
                    end
                end

                bl = ReverseProgramBlock(p.v, 0.0, [vars_mapping[p.inp_var_id]], [vars_mapping[v] for v in p.var_ids])
                push!(blocks, bl)
                p = p.b
            elseif p isa FreeVar
                in_var = vars_mapping[p.var_id]
                bl = ProgramBlock(FreeVar(t0, in_var), t0, 0.0, [in_var], vars_mapping["out"], false)
                push!(blocks, bl)
                break
            else
                vars = _used_vars(p)
                in_vars = []
                for v in vars
                    if !haskey(vars_mapping, v)
                        vars_mapping[v] = length(vars_mapping) + copied_vars + 1
                        push!(in_vars, vars_mapping[v])
                    elseif v in vars_from_input
                        copied_vars += 1
                        push!(in_vars, length(vars_mapping) + copied_vars)
                        copy_block = ProgramBlock(
                            FreeVar(t0, vars_mapping[v]),
                            t0,
                            0.0,
                            [vars_mapping[v]],
                            length(vars_mapping) + copied_vars,
                            false,
                        )
                        push!(blocks, copy_block)
                    else
                        push!(in_vars, vars_mapping[v])
                    end
                end
                bl = ProgramBlock(p, t0, 0.0, in_vars, vars_mapping["out"], is_reversible(p))
                push!(blocks, bl)
                break
            end
        end
        return blocks, vars_mapping
    end

    function _block_can_be_next(bl::ProgramBlock, vars_mapping)
        if bl.p isa FreeVar
            return haskey(vars_mapping, bl.output_var) && haskey(vars_mapping, bl.input_vars[1])
        end
        return haskey(vars_mapping, bl.output_var)
    end

    function _block_can_be_next(bl::ReverseProgramBlock, vars_mapping)
        return haskey(vars_mapping, bl.input_vars[1])
    end

    function is_on_path(bp::BlockPrototype, bl::ProgramBlock, vars_mapping, verbose = false)
        if !isa(bp.state.skeleton, FreeVar)
            return false
        end
        if !isa(bl.p, FreeVar)
            return false
        end
        if verbose
            @info "Check on path"
            @info bl.output_var
            @info vars_mapping[bl.output_var]
            @info bp.output_var
        end
        if vars_mapping[bl.output_var] != bp.output_var[1]
            return false
        end
        if haskey(vars_mapping, bl.p.var_id)
            bp.state.skeleton.var_id == vars_mapping[bl.p.var_id]
        else
            true
        end
    end

    is_on_path(prot::Hole, p) = true
    is_on_path(prot::Apply, p::Apply) = is_on_path(prot.f, p.f) && is_on_path(prot.x, p.x)
    is_on_path(prot::Abstraction, p::Abstraction) = is_on_path(prot.b, p.b)
    is_on_path(prot, p) = prot == p
    is_on_path(prot::FreeVar, p::FreeVar) = true

    function _get_entries(sc, vars_mapping, branches)
        result = Dict()
        for (original_var, mapped_var) in vars_mapping
            if !haskey(branches, mapped_var)
                continue
            end
            branch_id = branches[mapped_var]
            entry = sc.entries[sc.branch_entries[branch_id]]
            result[original_var] = entry
        end
        return result
    end

    function _fetch_branches_children(sc, branches)
        result = Dict()
        for (var_id, branch_id) in branches
            while !isempty(get_connected_from(sc.branch_children, branch_id))
                branch_id = first(get_connected_from(sc.branch_children, branch_id))
            end
            result[var_id] = branch_id
        end
        return result
    end

    function _simulate_block_search(
        sc,
        bl::ProgramBlock,
        rem_blocks,
        branches,
        branches_history,
        vars_mapping,
        g,
        run_context,
        finalizer,
        mfp,
        verbose,
    )
        if verbose
            @info "Simulating block search for $bl"
        end
        if bl.p isa FreeVar
            is_explained = true
            branch_id = branches[vars_mapping[bl.input_vars[1]]]
        else
            is_explained = false
            branch_id = branches[vars_mapping[bl.output_var]]
        end
        if !haskey((is_explained ? sc.branch_queues_explained : sc.branch_queues_unknown), branch_id)
            if verbose
                @info "Queue is empty"
            end
            return Set(), Set([(_get_entries(sc, vars_mapping, branches), bl)])
        end
        q = (is_explained ? sc.branch_queues_explained : sc.branch_queues_unknown)[branch_id]
        not_on_path = Set()
        @test !isempty(q)
        while !isempty(q)
            (bp, p) = peek(q)
            bp = dequeue!(q)
            if verbose
                @info bp
            end
            if (!isa(bp.state.skeleton, FreeVar) && is_on_path(bp.state.skeleton, bl.p)) ||
               is_on_path(bp, bl, vars_mapping, verbose)
                if verbose
                    @info "on path"
                end
                out_branch_id = branches[vars_mapping[bl.output_var]]
                while !isempty(get_connected_from(sc.branch_children, out_branch_id))
                    if verbose
                        @info "Out branch id $out_branch_id"
                        @info "Children $(get_connected_from(sc.branch_children, out_branch_id))"
                    end
                    out_branch_id = first(get_connected_from(sc.branch_children, out_branch_id))
                end
                enumeration_iteration(run_context, sc, finalizer, mfp, g, q, bp, branch_id, is_explained)
                if is_reversible(bp.state.skeleton) || state_finished(bp.state)
                    if verbose
                        @info "found end"
                        @info "Out branch id $out_branch_id"
                    end

                    for (bp_, p_) in not_on_path
                        q[bp_] = p_
                    end

                    in_blocks = get_connected_from(sc.branch_incoming_blocks, out_branch_id)
                    if verbose
                        @info "in_blocks: $in_blocks"
                    end
                    if isempty(in_blocks)
                        children = get_connected_from(sc.branch_children, out_branch_id)
                        if verbose
                            @info "children: $children"
                            @info sc.branch_children
                        end
                        if isempty(children)
                            if verbose
                                @info "Can't add block"
                            end
                            return Set(), Set([(_get_entries(sc, vars_mapping, branches), bl)])
                        end
                        @test length(children) == 1
                        child_id = first(children)
                        in_blocks = get_connected_from(sc.branch_incoming_blocks, child_id)
                    end
                    @test !isempty(in_blocks)
                    if verbose
                        @info "in_blocks: $in_blocks"
                    end
                    created_block_id = first(values(in_blocks))
                    created_block = sc.blocks[created_block_id]
                    if verbose
                        @info "created_block: $created_block"
                    end

                    updated_branches = copy(branches)
                    created_block_copy_id = first(keys(in_blocks))
                    in_branches = keys(get_connected_to(sc.branch_outgoing_blocks, created_block_copy_id))
                    for in_branch in in_branches
                        updated_branches[sc.branch_vars[in_branch]] = in_branch
                    end
                    out_branches = keys(get_connected_to(sc.branch_incoming_blocks, created_block_copy_id))
                    for out_branch in out_branches
                        updated_branches[sc.branch_vars[out_branch]] = out_branch
                    end
                    updated_branches = _fetch_branches_children(sc, updated_branches)
                    if verbose
                        @info "updated_branches: $updated_branches"
                    end

                    updated_vars_mapping = copy(vars_mapping)
                    for (original_var, new_var) in zip(bl.input_vars, created_block.input_vars)
                        if !haskey(updated_vars_mapping, original_var)
                            updated_vars_mapping[original_var] = new_var
                        end
                    end
                    if verbose
                        @info "updated_vars_mapping: $updated_vars_mapping"
                    end
                    updated_history = vcat(branches_history, [(branches, bl)])
                    return _check_reachable(
                        sc,
                        rem_blocks,
                        updated_vars_mapping,
                        updated_branches,
                        updated_history,
                        g,
                        run_context,
                        finalizer,
                        mfp,
                        verbose,
                    )
                end
            else
                push!(not_on_path, (bp, p))
                if verbose
                    @info "not on path"
                end
            end
        end
        if verbose
            @info "Failed to find block"
        end
        return Set(), Set([(_get_entries(sc, vars_mapping, branches), bl)])
    end

    function _simulate_block_search(
        sc,
        bl::ReverseProgramBlock,
        rem_blocks,
        branches,
        branches_history,
        vars_mapping,
        g,
        run_context,
        finalizer,
        mfp,
        verbose,
    )
        if verbose
            @info "Simulating block search for $bl"
        end
        in_branch_id = branches[vars_mapping[bl.input_vars[1]]]
        is_explained = true
        if !haskey((is_explained ? sc.branch_queues_explained : sc.branch_queues_unknown), in_branch_id)
            if verbose
                @info "Queue is empty"
            end
            return Set(), Set([(_get_entries(sc, vars_mapping, branches), bl)])
        end
        q = (is_explained ? sc.branch_queues_explained : sc.branch_queues_unknown)[in_branch_id]

        block_main_func, block_main_func_args = application_parse(bl.p)
        if verbose
            @info "block_main_func: $block_main_func"
            @info "block_main_func_args: $block_main_func_args"
        end
        if block_main_func == every_primitive["rev_fix_param"]
            wrapped_func = block_main_func_args[1]
        else
            wrapped_func = nothing
        end

        @test !isempty(q)
        while !isempty(q)
            bp = dequeue!(q)
            if verbose
                @info bp
            end
            if is_on_path(bp.state.skeleton, bl.p) ||
               (wrapped_func !== nothing && is_on_path(bp.state.skeleton, wrapped_func))
                if verbose
                    @info "on path"
                end
                enumeration_iteration(run_context, sc, finalizer, mfp, g, q, bp, in_branch_id, is_explained)
                if !(wrapped_func !== nothing && is_on_path(bp.state.skeleton, wrapped_func)) &&
                   (is_reversible(bp.state.skeleton) || state_finished(bp.state))
                    if verbose
                        @info "found end"
                    end
                    out_blocks = get_connected_from(sc.branch_outgoing_blocks, in_branch_id)
                    if isempty(out_blocks)
                        children = get_connected_from(sc.branch_children, in_branch_id)
                        @test length(children) == 1
                        child_id = first(children)
                        out_blocks = get_connected_from(sc.branch_outgoing_blocks, child_id)
                    end
                    @test !isempty(out_blocks)
                    if verbose
                        @info "out_blocks: $out_blocks"
                    end
                    created_block_id = first(values(out_blocks))
                    created_block = sc.blocks[created_block_id]
                    if verbose
                        @info "created_block: $created_block"
                    end

                    updated_branches = copy(branches)
                    created_block_copy_id = first(keys(out_blocks))
                    out_branches = keys(get_connected_to(sc.branch_incoming_blocks, created_block_copy_id))
                    for out_branch in out_branches
                        updated_branches[sc.branch_vars[out_branch]] = out_branch
                    end
                    updated_branches = _fetch_branches_children(sc, updated_branches)
                    if verbose
                        @info "updated_branches: $updated_branches"
                    end

                    updated_vars_mapping = copy(vars_mapping)
                    for (original_var, new_var) in zip(bl.output_vars, created_block.output_vars)
                        if !haskey(updated_vars_mapping, original_var)
                            updated_vars_mapping[original_var] = new_var
                        end
                    end
                    if verbose
                        @info "updated_vars_mapping: $updated_vars_mapping"
                    end
                    updated_history = vcat(branches_history, [(branches, bl)])
                    return _check_reachable(
                        sc,
                        rem_blocks,
                        updated_vars_mapping,
                        updated_branches,
                        updated_history,
                        g,
                        run_context,
                        finalizer,
                        mfp,
                        verbose,
                    )
                end
            else
                if verbose
                    @info "not on path"
                end
            end
        end
        if verbose
            @info "Failed to find block"
        end
        return Set(), Set([(_get_entries(sc, vars_mapping, branches), bl)])
    end

    function _check_reachable(
        sc,
        blocks,
        vars_mapping,
        branches,
        branches_history,
        g,
        run_context,
        finalizer,
        mfp,
        verbose,
    )
        checked_any = false
        if isempty(blocks)
            if verbose
                @info "Found all blocks"
            end
            return Set([Set([(_get_entries(sc, vars_mapping, brs), bl) for (brs, bl) in branches_history])]), Set()
        end
        successful = Set()
        failed = Set()
        if verbose
            @info "Checking blocks $blocks"
        end
        for bl in blocks
            if _block_can_be_next(bl, vars_mapping)
                checked_any = true
                sc_next = deepcopy(sc)
                s, f = _simulate_block_search(
                    sc_next,
                    bl,
                    Any[b for b in blocks if b != bl],
                    branches,
                    branches_history,
                    vars_mapping,
                    g,
                    run_context,
                    finalizer,
                    mfp,
                    verbose,
                )
                union!(successful, s)
                union!(failed, f)
            end
        end
        if verbose
            @info "checked_any: $checked_any"
            @info "blocks: $blocks"
        end
        @test checked_any
        return successful, failed
    end

    function check_reachable(payload, target_solution, verbose_test = false)
        task, maximum_frontier, g, type_weights, mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        mfp = 10
        run_context = Dict{String,Any}("program_timeout" => program_timeout, "timeout" => timeout)
        target_program = parse_program(target_solution)
        blocks, vars_mapping = _extract_blocks(task, target_program, verbose_test)
        if verbose_test
            @info blocks
            @info vars_mapping
        end
        sc = create_starting_context(task, type_weights, verbose_test)
        enqueue_updates(sc, g)
        branches = Dict()
        for br_id in 1:sc.branches_count[]
            branches[sc.branch_vars[br_id]] = br_id
        end
        if verbose_test
            @info branches
        end
        save_changes!(sc, 0)

        start_time = time()
        hits = PriorityQueue{HitResult,Float64}()
        finalizer = function (solution, cost)
            if verbose_test
                @info "Got solution $solution"
            end
            ll = task.log_likelihood_checker(task, solution)
            if !isnothing(ll) && !isinf(ll)
                dt = time() - start_time
                res = HitResult(join(show_program(solution, false)), -cost, ll, dt)
                if haskey(hits, res)
                    # @warn "Duplicated solution $solution"
                else
                    hits[res] = -cost + ll
                end
                while length(hits) > maximum_frontier
                    dequeue!(hits)
                end
            end
        end

        inner_mapping = Dict{UInt64,UInt64}()
        for (arg, _) in task.task_type.arguments
            for (v, a) in sc.input_keys
                if a == arg
                    inner_mapping[v] = vars_mapping[arg]
                end
            end
        end
        inner_mapping[vars_mapping["out"]] = sc.branch_vars[sc.target_branch_id]
        if verbose_test
            @info inner_mapping
        end
        successful, failed =
            _check_reachable(sc, blocks, inner_mapping, branches, [], g, run_context, finalizer, mfp, verbose_test)
        if verbose_test
            @info "successful: $successful"
            @info "failed: $failed"
            @info "length successful: $(length(successful))"
            @info "length failed: $(length(failed))"
        end
        @test !isempty(successful)
        for f_entries in failed
            for s_snapshots in successful
                @test all(s_entries != f_entries for s_entries in s_snapshots)
                if any(s_entries == f_entries for s_entries in s_snapshots)
                    @info "Found failed case"
                    @info f_entries
                    @info s_snapshots
                end
            end
        end
    end

    @testset "Repeat" begin
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
        )
        target_solution = "let \$v1, \$v2 = rev(\$inp0 = (repeat \$v1 \$v2)) in (repeat \$v2 \$v1)"
        check_reachable(payload, target_solution)
    end

    @testset "Find const" begin
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
        )
        target_solution = "let \$v1, \$v2 = rev(\$inp0 = (repeat \$v1 \$v2)) in let \$v3::int = Const(int, 5) in (repeat \$v2 \$v3)"
        check_reachable(payload, target_solution)
    end

    @testset "Use eithers" begin
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
        )
        target_solution = "let \$v1::list(int) = Const(list(int), Any[6, 7, 8, 9, 10]) in (concat \$inp0 \$v1)"
        check_reachable(payload, target_solution)
    end

    @testset "Use eithers 2" begin
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
        )
        target_solution = "let \$v1::int = (length \$inp0) in let \$v2::int = Const(int, 1) in let \$v3::list(int) = (repeat \$v1 \$v2) in let \$v4::list(int) = (concat \$inp0 \$v3) in let \$v5::list(int) = Const(list(int), Any[6, 7, 8, 9, 10]) in (concat \$v4 \$v5)"
        check_reachable(payload, target_solution)
    end

    @testset "Use eithers from input" begin
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
        )
        target_solution = "let \$v1, \$v2 = rev(\$inp0 = (rev_fix_param (concat \$v1 \$v2) \$v2 (lambda Const(list(int), Any[10, 9, 8, 7])))) in \$v1"
        check_reachable(payload, target_solution)
    end

    @testset "Replace background" begin
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
        )
        target_solution = "let \$v1::int = Const(int, 1) in let \$v2::int = Const(int, 1) in let \$v3, \$v4, \$v5 = rev(\$inp0 = (rev_fix_param (rev_select (lambda (eq? \$0 \$v3)) \$v4 \$v5) \$v3 (lambda Const(int, 3)))) in let \$v6, \$v7 = rev(\$v4 = (repeat \$v6 \$v7)) in let \$v8::list(int) = (repeat \$v2 \$v7) in (rev_select (lambda (eq? \$0 \$v1)) \$v8 \$v5)"
        check_reachable(payload, target_solution)
    end

    @testset "Add const" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "add const",
                "maximumFrontier" => 10,
                "examples" => Any[
                    Dict{String,Any}("output" => 39, "inputs" => Dict{String,Any}("inp0" => 28)),
                    Dict{String,Any}("output" => 22, "inputs" => Dict{String,Any}("inp0" => 11)),
                    Dict{String,Any}("output" => 5, "inputs" => Dict{String,Any}("inp0" => -6)),
                ],
                "test_examples" => Any[],
                "request" => Dict{String,Any}(
                    "arguments" => Dict{String,Any}(
                        "inp0" => Dict{String,Any}("arguments" => Any[], "constructor" => "int"),
                    ),
                    "output" => Dict{String,Any}("arguments" => Any[], "constructor" => "int"),
                    "constructor" => "->",
                ),
            ),
        )
        target_solution = "let \$v1::int = Const(int, 11) in (+ \$v1 \$inp0)"
        check_reachable(payload, target_solution)
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
            sample_payload2,
        )
        target_solution = "let \$v1, \$v2 = rev(\$inp0 = (cons \$v1 \$v2)) in let \$v3, \$v4 = rev(\$v2 = (cons \$v3 \$v4)) in let \$v5::int = (car \$v4) in let \$v6::list(int) = Const(list(int), Any[]) in let \$v7::list(int) = (cons \$v5 \$v6) in (concat \$v7 \$inp0)"
        check_reachable(payload, target_solution)
        target_solution = "let \$v1::int = Const(int, 1) in let \$v2, \$v3 = rev(\$inp0 = (cons \$v2 \$v3)) in let \$v4, \$v5 = rev(\$v3 = (cons \$v4 \$v5)) in let \$v6::int = (index \$v1 \$v5) in let \$v7::list(int) = (repeat \$v6 \$v1) in (concat \$v7 \$inp0)"
        check_reachable(payload, target_solution)
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
            sample_payload2,
        )
        target_solution = "let \$v1, \$v2 = rev(\$inp0 = (cons \$v1 \$v2)) in let \$v3, \$v4 = rev(\$v2 = (cons \$v3 \$v4)) in let \$v5, \$v6 = rev(\$v4 = (cons \$v5 \$v6)) in (cdr (cdr \$v6))"
        check_reachable(payload, target_solution)
    end

    @testset "Select background" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "Select background",
                "maximumFrontier" => 10,
                "examples" => Any[Dict{String,Any}(
                    "output" => [
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 7 7 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 7 7 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 2 2 2 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 2 2 2 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 9 9 0 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 9 9 9 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 9 9 0 0 0 0 0 0 0 0 0
                        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                    ],
                    "inputs" => Dict{String,Any}(
                        "inp0" => [
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing 7 7 7 nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing 7 nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing 7 7 7 nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing 2 2 2 nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing 2 nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing 2 2 2 nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing 9 9 nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing 9 9 9 nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing 9 9 nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                        ],
                    ),
                ),],
                "test_examples" => Any[],
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
            ),
        )
        target_solution = "let \$v4::color = Const(color, 0) in let \$v6::int = Const(int, 20) in let \$v5::int = Const(int, 20) in let \$v1::color = Const(color, 0) in let \$v2::grid(color) = (repeat_grid \$v4 \$v5 \$v6) in (rev_select_grid (lambda (eq? \$0 \$v1)) \$v2 \$inp0)"
        check_reachable(payload, target_solution)
    end

    @testset "Select background reverse" begin
        payload = create_task(
            Dict{String,Any}(
                "name" => "Select background",
                "maximumFrontier" => 10,
                "examples" => Any[Dict{String,Any}(
                    "output" => (
                        (20, 20),
                        [
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing 7 7 7 nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing 7 nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing 7 7 7 nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing 2 2 2 nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing 2 nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing 2 2 2 nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing 9 9 nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing 9 9 9 nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing 9 9 nothing nothing nothing nothing nothing nothing nothing nothing nothing
                            nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing nothing
                        ],
                    ),
                    "inputs" => Dict{String,Any}(
                        "inp0" => [
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 7 7 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 7 7 7 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 2 2 2 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 2 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 2 2 2 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 9 9 0 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 9 9 9 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 9 9 0 0 0 0 0 0 0 0 0
                            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                        ],
                    ),
                ),],
                "test_examples" => Any[],
                "request" => Dict{String,Any}(
                    "arguments" => Dict{String,Any}(
                        "inp0" => Dict{String,Any}(
                            "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "color")],
                            "constructor" => "grid",
                        ),
                    ),
                    "output" => Dict{String,Any}(
                        "arguments" => Any[
                            Dict{String,Any}(
                                "arguments" => Any[
                                    Dict{String,Any}("arguments" => Any[], "constructor" => "int"),
                                    Dict{String,Any}("arguments" => Any[], "constructor" => "int"),
                                ],
                                "constructor" => "tuple2",
                            ),
                            Dict{String,Any}(
                                "arguments" => Any[Dict{String,Any}("arguments" => Any[], "constructor" => "color")],
                                "constructor" => "grid",
                            ),
                        ],
                        "constructor" => "tuple2",
                    ),
                    "constructor" => "->",
                ),
            ),
        )

        target_solution = "let \$v1, \$v2, \$v3 = rev(\$inp0 = (rev_fix_param (rev_select_grid (lambda (eq? \$0 \$v1)) \$v2 \$v3) \$v1 (lambda Const(color, 0)))) in let \$v4, \$v5, \$v6 = rev(\$v2 = (repeat_grid \$v4 \$v5 \$v6)) in let \$v7::tuple2(int, int) = (tuple2 \$v5 \$v6) in (tuple2 \$v7 \$v3)"
        check_reachable(payload, target_solution)
    end
end

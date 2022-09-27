
using Test

using solver:
    load_problems,
    create_starting_context,
    ProgramBlock,
    FreeVar,
    add_new_block,
    RedisContext,
    BlockPrototype,
    EnumerationState,
    enumeration_iteration_finished_output,
    unifying_expressions,
    empty_context,
    every_primitive,
    tint,
    tlist,
    get_argument_requests,
    Apply,
    Hole,
    modify_skeleton,
    LeftTurn,
    RightTurn,
    ArgTurn,
    Tp,
    Context,
    block_prototype,
    number_of_free_parameters,
    follow_path,
    unwind_path,
    path_environment,
    apply_context,
    SetConst

import Redis
using DataStructures
using SuiteSparseGraphBLAS

function initial_state(t, g)
    EnumerationState(Hole(t, g.no_context), empty_context, [], 0.0, 0, false)
end

function next_state(state, target_candidate, cg)
    current_hole = follow_path(state.skeleton, state.path)
    if !isa(current_hole, Hole)
        error("Error during following path")
    end
    request = current_hole.t
    g = current_hole.grammar

    context = state.context
    context, request = apply_context(context, request)

    environment = path_environment(state.path)
    candidates = unifying_expressions(g, environment, request, context, state.abstractors_only)
    if !isa(state.skeleton, Hole)
        push!(candidates, (FreeVar(request, nothing), [], context, g.log_variable))
    end

    states = collect(
        skipmissing(
            map(candidates) do (candidate, argument_types, context, ll)
                if candidate != target_candidate
                    return missing
                end
                new_free_parameters = number_of_free_parameters(candidate)
                argument_requests = get_argument_requests(candidate, argument_types, cg)

                if isempty(argument_types)
                    new_skeleton = modify_skeleton(state.skeleton, candidate, state.path)
                    new_path = unwind_path(state.path, new_skeleton)
                else
                    application_template = candidate
                    for (a, at) in argument_requests
                        application_template = Apply(application_template, Hole(a, at))
                    end
                    new_skeleton = modify_skeleton(state.skeleton, application_template, state.path)
                    new_path = vcat(state.path, [LeftTurn() for _ in 2:length(argument_types)], [RightTurn()])
                end
                return EnumerationState(
                    new_skeleton,
                    context,
                    new_path,
                    state.cost + ll,
                    state.free_parameters + new_free_parameters,
                    state.abstractors_only,
                )
            end,
        ),
    )

    return states[1]
end

function create_block_prototype(sc, target_branch_id, steps, g)
    target_type_id = reduce(any, sc.branch_types[target_branch_id, :])
    target_type = sc.types[target_type_id]
    state = initial_state(target_type, g)
    for step in steps
        state = next_state(state, step, g)
    end

    target_var_id = sc.branch_vars[target_branch_id]
    bp = BlockPrototype(state, target_type, nothing, (target_var_id, target_branch_id), false)
    return bp
end

@testset "Test branches" begin
    base_task = Dict(
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
        "programTimeout" => 1,
        "timeout" => 20,
        "verbose" => false,
        "shatter" => 10,
    )
    run_context = Dict("redis" => RedisContext(Redis.RedisConnection(db = 2)), "program_timeout" => 1, "timeout" => 20)

    @testset "Exact value match" begin
        payload = merge(
            base_task,
            Dict(
                "task" => Dict{String,Any}(
                    "name" => "copy",
                    "maximumFrontier" => 10,
                    "examples" => Any[
                        Dict{String,Any}(
                            "output" => Any[4, 4, 4, 4, 4],
                            "inputs" => Dict{String,Any}("inp0" => Any[4, 4, 4, 4, 4]),
                        ),
                        Dict{String,Any}(
                            "output" => Any[1, 1, 1, 1, 1, 1],
                            "inputs" => Dict{String,Any}("inp0" => Any[1, 1, 1, 1, 1, 1]),
                        ),
                        Dict{String,Any}("output" => Any[3, 3], "inputs" => Dict{String,Any}("inp0" => Any[3, 3])),
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
                "name" => "copy",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        sc = create_starting_context(task, type_weights)
        inp_var_id = 1
        out_var_id = 2
        inp_branch_id = 1
        out_branch_id = 2
        inp_type_id = reduce(any, sc.branch_types[inp_branch_id, :])
        new_block = ProgramBlock(
            FreeVar(sc.types[inp_type_id], inp_var_id),
            sc.types[inp_type_id],
            0.0,
            [inp_var_id],
            out_var_id,
            false,
        )
        new_block_id = push!(sc.blocks, new_block)

        new_solution_paths = add_new_block(
            run_context,
            sc,
            new_block_id,
            Dict(inp_var_id => inp_branch_id),
            Dict(out_var_id => out_branch_id),
        )
        @test new_solution_paths == [OrderedDict(out_var_id => new_block_id)]

        out_children = nonzeroinds(sc.branch_children[out_branch_id, :])
        @test length(out_children) == 0

        @test sc.branch_is_explained[out_branch_id] == true
        @test sc.branch_is_not_copy[out_branch_id] == false
        @test sc.incoming_paths[out_branch_id] == [OrderedDict(out_var_id => new_block_id)]
        @test nnz(sc.branch_incoming_blocks[out_branch_id, :]) == 1
        @test sc.branch_incoming_blocks[out_branch_id, new_block_id] == 1
        @test nnz(sc.branch_outgoing_blocks[out_branch_id, :]) == 0

        @test sc.unknown_min_path_costs[out_branch_id] == 0.0
        @test sc.explained_min_path_costs[out_branch_id] == 0.0
        @test sc.explained_complexity_factors[out_branch_id] == 16.0
        @test sc.unknown_complexity_factors[out_branch_id] == 16.0
        @test sc.complexities[out_branch_id] == 16.0
        @test sc.added_upstream_complexities[out_branch_id] == 0.0
        @test sc.unused_explained_complexities[out_branch_id] == 0.0
        @test sc.unmatched_complexities[out_branch_id] == 0.0
        @test nnz(sc.related_unknown_complexity_branches[out_branch_id, :]) == 0
        @test nnz(sc.related_explained_complexity_branches[out_branch_id, :]) == 0
    end

    @testset "Type only match" begin
        payload = merge(
            base_task,
            Dict(
                "task" => Dict{String,Any}(
                    "name" => "cdr",
                    "maximumFrontier" => 10,
                    "examples" => Any[
                        Dict{String,Any}(
                            "output" => Any[4, 4, 4, 4],
                            "inputs" => Dict{String,Any}("inp0" => Any[4, 4, 4, 4, 4]),
                        ),
                        Dict{String,Any}(
                            "output" => Any[1, 1, 1, 1, 1],
                            "inputs" => Dict{String,Any}("inp0" => Any[1, 1, 1, 1, 1, 1]),
                        ),
                        Dict{String,Any}("output" => Any[3], "inputs" => Dict{String,Any}("inp0" => Any[3, 3])),
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
                "name" => "cdr",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        sc = create_starting_context(task, type_weights)
        inp_var_id = 1
        out_var_id = 2
        inp_branch_id = 1
        out_branch_id = 2
        inp_type_id = reduce(any, sc.branch_types[inp_branch_id, :])
        out_type_id = reduce(any, sc.branch_types[out_branch_id, :])

        bp = create_block_prototype(
            sc,
            out_branch_id,
            [every_primitive["cdr"], FreeVar(sc.types[out_type_id], nothing)],
            g,
        )
        new_block_result = enumeration_iteration_finished_output(run_context, sc, bp)
        first_block_id, input_branches = new_block_result
        new_solution_paths =
            add_new_block(run_context, sc, first_block_id, input_branches, Dict(out_var_id => out_branch_id))
        first_block_copy_id = first_block_id
        @test new_solution_paths == []

        connection_var_id = 3
        connection_branch_id = 3

        new_block = ProgramBlock(
            FreeVar(sc.types[inp_type_id], inp_var_id),
            sc.types[inp_type_id],
            0.0,
            [inp_var_id],
            connection_var_id,
            false,
        )
        new_block_id = push!(sc.blocks, new_block)

        new_solution_paths = add_new_block(
            run_context,
            sc,
            new_block_id,
            Dict(inp_var_id => inp_branch_id),
            Dict(connection_var_id => connection_branch_id),
        )
        @test new_solution_paths == [OrderedDict(out_var_id => first_block_id, connection_var_id => new_block_id)]
        new_block_copy_id = new_block_id

        conn_children = nonzeroinds(sc.branch_children[connection_branch_id, :])
        @test length(conn_children) == 1
        conn_child_id = conn_children[1]
        first_block_known_copy_id = new_block_copy_id + 1

        @test sc.branch_entries[conn_child_id] == sc.branch_entries[inp_branch_id]
        @test sc.branch_vars[conn_child_id] == connection_var_id
        @test sc.branch_types[conn_child_id, :] == sc.branch_types[inp_branch_id, :]
        @test sc.incoming_paths[conn_child_id] == [OrderedDict(connection_var_id => new_block_id)]
        @test nnz(sc.branch_incoming_blocks[conn_child_id, :]) == 1
        @test sc.branch_incoming_blocks[conn_child_id, new_block_copy_id] == new_block_id
        @test nnz(sc.branch_outgoing_blocks[conn_child_id, :]) == 1
        @test sc.branch_outgoing_blocks[conn_child_id, first_block_known_copy_id] == first_block_id
        @test sc.branch_is_unknown[conn_child_id] == false
        @test sc.branch_is_explained[conn_child_id] == true
        @test sc.branch_is_not_copy[conn_child_id] == false
        @test sc.explained_min_path_costs[conn_child_id] == 0.0
        @test sc.explained_complexity_factors[conn_child_id] == 16.0
        @test sc.complexities[conn_child_id] == 16.0
        @test sc.added_upstream_complexities[conn_child_id] == 0.0
        @test sc.unused_explained_complexities[conn_child_id] == 0.0
        @test sc.unmatched_complexities[conn_child_id] === nothing
        @test nnz(sc.related_unknown_complexity_branches[conn_child_id, :]) == 0
        @test nnz(sc.related_explained_complexity_branches[conn_child_id, :]) == 0

        out_children = nonzeroinds(sc.branch_children[out_branch_id, :])
        @test length(out_children) == 0

        @test sc.incoming_paths[out_branch_id] ==
              [OrderedDict(out_var_id => first_block_id, connection_var_id => new_block_id)]
        @test nnz(sc.branch_incoming_blocks[out_branch_id, :]) == 2
        @test sc.branch_incoming_blocks[out_branch_id, first_block_copy_id] == first_block_id
        @test sc.branch_incoming_blocks[out_branch_id, first_block_known_copy_id] == first_block_id
        @test nnz(sc.branch_outgoing_blocks[out_branch_id, :]) == 0
        @test sc.branch_is_unknown[out_branch_id] == true
        @test sc.branch_is_explained[out_branch_id] == true
        @test sc.branch_is_not_copy[out_branch_id] == true
        @test sc.explained_min_path_costs[out_branch_id] == 2.4849066497880004
        @test sc.unknown_min_path_costs[out_branch_id] == 0.0
        @test sc.explained_complexity_factors[out_branch_id] == 13.0
        @test sc.unknown_complexity_factors[out_branch_id] == 13.0
        @test sc.complexities[out_branch_id] == 13.0
        @test sc.added_upstream_complexities[out_branch_id] == 0.0
        @test sc.unused_explained_complexities[out_branch_id] == 0.0
        @test sc.unmatched_complexities[out_branch_id] == 0.0
        @test nnz(sc.related_unknown_complexity_branches[out_branch_id, :]) == 0
        @test nnz(sc.related_explained_complexity_branches[out_branch_id, :]) == 0
    end

    @testset "Either match" begin
        payload = merge(
            base_task,
            Dict(
                "task" => Dict{String,Any}(
                    "name" => "concat",
                    "maximumFrontier" => 10,
                    "examples" => Any[
                        Dict{String,Any}(
                            "output" => Any[5, 4, 4, 4, 4, 4],
                            "inputs" => Dict{String,Any}("inp0" => Any[4, 4, 4, 4, 4]),
                        ),
                        Dict{String,Any}(
                            "output" => Any[5, 1, 1, 1, 1, 1, 1],
                            "inputs" => Dict{String,Any}("inp0" => Any[1, 1, 1, 1, 1, 1]),
                        ),
                        Dict{String,Any}("output" => Any[5, 3, 3], "inputs" => Dict{String,Any}("inp0" => Any[3, 3])),
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
                "name" => "concat",
            ),
        )
        task, maximum_frontier, g, type_weights, _mfp, _nc, timeout, verbose, program_timeout = load_problems(payload)
        sc = create_starting_context(task, type_weights)
        inp_var_id = 1
        out_var_id = 2
        inp_branch_id = 1
        out_branch_id = 2

        bp = create_block_prototype(sc, out_branch_id, [every_primitive["concat"]], g)
        new_block_result = enumeration_iteration_finished_output(run_context, sc, bp)
        first_block_id, input_branches = new_block_result
        new_solution_paths =
            add_new_block(run_context, sc, first_block_id, input_branches, Dict(out_var_id => out_branch_id))
        first_block_copy_id = 1
        @test new_solution_paths == []

        v1_var_id = 3
        v2_var_id = 4

        v1_branch_id = 3
        v2_branch_id = 4

        constraint_id = 1
        @test sc.constrained_contexts[constraint_id] === nothing

        @test sc.branch_entries[v1_branch_id] == 3
        @test sc.branch_vars[v1_branch_id] == v1_var_id
        @test sc.branch_types[v1_branch_id, :] == sc.branch_types[inp_branch_id, :]
        @test nnz(sc.branch_children[v1_branch_id, :]) == 0
        @test nnz(sc.branch_children[:, v1_branch_id]) == 0
        @test nnz(sc.constrained_branches[v1_branch_id, :]) == 1
        @test sc.constrained_branches[v1_branch_id, constraint_id] == v1_var_id
        @test nnz(sc.constrained_vars[v1_var_id, :]) == 1
        @test sc.constrained_vars[v1_var_id, constraint_id] == v1_branch_id
        @test sc.incoming_paths[v1_branch_id] == []
        @test nnz(sc.branch_incoming_blocks[v1_branch_id, :]) == 0
        @test nnz(sc.branch_outgoing_blocks[v1_branch_id, :]) == 1
        @test sc.branch_outgoing_blocks[v1_branch_id, first_block_copy_id] == first_block_id
        @test sc.branch_is_unknown[v1_branch_id] == true
        @test sc.branch_is_explained[v1_branch_id] == false
        @test sc.unknown_min_path_costs[v1_branch_id] == 2.4849066497880004
        @test sc.unknown_complexity_factors[v1_branch_id] == 20.0
        @test sc.complexities[v1_branch_id] == 10.0
        @test sc.unmatched_complexities[v1_branch_id] == 10.0
        @test nnz(sc.related_unknown_complexity_branches[v1_branch_id, :]) == 1
        @test sc.related_unknown_complexity_branches[v1_branch_id, v2_branch_id] == 1

        @test sc.branch_entries[v2_branch_id] == 4
        @test sc.branch_vars[v2_branch_id] == v2_var_id
        @test sc.branch_types[v2_branch_id, :] == sc.branch_types[inp_branch_id, :]
        @test nnz(sc.branch_children[v2_branch_id, :]) == 0
        @test nnz(sc.branch_children[:, v2_branch_id]) == 0
        @test nnz(sc.constrained_branches[v2_branch_id, :]) == 1
        @test sc.constrained_branches[v2_branch_id, constraint_id] == v2_var_id
        @test nnz(sc.constrained_vars[v2_var_id, :]) == 1
        @test sc.constrained_vars[v2_var_id, constraint_id] == v2_branch_id
        @test sc.incoming_paths[v2_branch_id] == []
        @test nnz(sc.branch_incoming_blocks[v2_branch_id, :]) == 0
        @test nnz(sc.branch_outgoing_blocks[v2_branch_id, :]) == 1
        @test sc.branch_outgoing_blocks[v2_branch_id, first_block_copy_id] == first_block_id
        @test sc.branch_is_unknown[v2_branch_id] == true
        @test sc.branch_is_explained[v2_branch_id] == false
        @test sc.unknown_min_path_costs[v2_branch_id] == 2.4849066497880004
        @test sc.unknown_complexity_factors[v2_branch_id] == 20.0
        @test sc.complexities[v2_branch_id] == 10.0
        @test sc.unmatched_complexities[v2_branch_id] == 10.0
        @test nnz(sc.related_unknown_complexity_branches[v2_branch_id, :]) == 1
        @test sc.related_unknown_complexity_branches[v2_branch_id, v1_branch_id] == 1

        inp_type_id = reduce(any, sc.branch_types[inp_branch_id, :])
        inp_type = sc.types[inp_type_id]

        new_block = ProgramBlock(FreeVar(inp_type, inp_var_id), inp_type, 0.0, [inp_var_id], v2_var_id, false)
        new_block_id = push!(sc.blocks, new_block)

        new_solution_paths = add_new_block(
            run_context,
            sc,
            new_block_id,
            Dict(inp_var_id => inp_branch_id),
            Dict(v2_var_id => v2_branch_id),
        )
        new_block_copy_id = 3
        first_block_known_copy_id = 2
        @test new_solution_paths == []

        v2_children = nonzeroinds(sc.branch_children[v2_branch_id, :])
        @test length(v2_children) == 1
        v2_child_id = v2_children[1]

        v1_children = nonzeroinds(sc.branch_children[v1_branch_id, :])
        @test length(v1_children) == 1
        v1_child_id = v1_children[1]

        @test sc.branch_entries[v2_child_id] == sc.branch_entries[inp_branch_id]
        @test sc.branch_vars[v2_child_id] == v2_var_id
        @test sc.branch_types[v2_child_id, :] == sc.branch_types[inp_branch_id, :]
        @test nnz(sc.branch_children[v2_child_id, :]) == 0
        @test nnz(sc.branch_children[:, v2_child_id]) == 1
        @test sc.branch_children[v2_branch_id, v2_child_id] == 1
        @test nnz(sc.constrained_branches[v2_child_id, :]) == 0
        @test nnz(sc.constrained_vars[v2_var_id, :]) == 1
        @test sc.incoming_paths[v2_child_id] == [OrderedDict(v2_var_id => new_block_id)]
        @test nnz(sc.branch_incoming_blocks[v2_child_id, :]) == 1
        @test sc.branch_incoming_blocks[v2_child_id, new_block_copy_id] == new_block_id
        @test nnz(sc.branch_outgoing_blocks[v2_child_id, :]) == 1
        @test sc.branch_outgoing_blocks[v2_child_id, first_block_known_copy_id] == first_block_id
        @test sc.branch_is_unknown[v2_child_id] == false
        @test sc.branch_is_explained[v2_child_id] == true
        @test sc.branch_is_not_copy[v2_child_id] == false
        @test sc.explained_min_path_costs[v2_child_id] == 0.0
        @test sc.explained_complexity_factors[v2_child_id] == 16.0
        @test sc.complexities[v2_child_id] == 16.0
        @test sc.added_upstream_complexities[v2_child_id] == 0.0
        @test sc.unused_explained_complexities[v2_child_id] == 0.0
        @test sc.unmatched_complexities[v2_child_id] == 0.0
        @test nnz(sc.related_explained_complexity_branches[v2_child_id, :]) == 0
        @test nnz(sc.related_unknown_complexity_branches[v2_child_id, :]) == 0

        @test sc.branch_entries[v1_child_id] == 5
        @test sc.branch_vars[v1_child_id] == v1_var_id
        @test sc.branch_types[v1_child_id, :] == sc.branch_types[inp_branch_id, :]
        @test nnz(sc.branch_children[v1_child_id, :]) == 0
        @test nnz(sc.branch_children[:, v1_child_id]) == 1
        @test sc.branch_children[v1_branch_id, v1_child_id] == 1
        @test nnz(sc.constrained_branches[v1_child_id, :]) == 0
        @test nnz(sc.constrained_vars[v1_var_id, :]) == 1
        @test sc.incoming_paths[v1_child_id] == []
        @test nnz(sc.branch_incoming_blocks[v1_child_id, :]) == 0
        @test nnz(sc.branch_outgoing_blocks[v1_child_id, :]) == 1
        @test sc.branch_outgoing_blocks[v1_child_id, first_block_known_copy_id] == first_block_id
        @test sc.branch_is_unknown[v1_child_id] == true
        @test sc.branch_is_explained[v1_child_id] == false
        @test sc.branch_is_not_copy[v1_child_id] == false
        @test sc.unknown_min_path_costs[v1_child_id] == 2.4849066497880004
        @test sc.unknown_complexity_factors[v1_child_id] == 6.0
        @test sc.complexities[v1_child_id] == 6.0
        @test sc.unmatched_complexities[v1_child_id] == 6.0
        @test nnz(sc.related_unknown_complexity_branches[v1_child_id, :]) == 1
        @test sc.related_unknown_complexity_branches[v1_child_id, v2_child_id] == 1

        const_block = ProgramBlock(SetConst(inp_type, [5]), inp_type, 0.0, [], v1_var_id, false)
        const_block_id = push!(sc.blocks, const_block)
        new_solution_paths = add_new_block(run_context, sc, const_block_id, Dict(), Dict(v1_var_id => v1_branch_id))
        const_block_copy_id = 4

        @test new_solution_paths ==
              [OrderedDict(out_var_id => first_block_id, v2_var_id => new_block_id, v1_var_id => const_block_id)]

        @test nnz(sc.branch_children[v2_child_id, :]) == 0
        @test nnz(sc.constrained_branches[v2_child_id, :]) == 0

        @test nnz(sc.constrained_vars[v2_var_id, :]) == 1
        @test sc.incoming_paths[v2_child_id] == [OrderedDict(v2_var_id => new_block_id)]
        @test nnz(sc.branch_incoming_blocks[v2_child_id, :]) == 1
        @test sc.branch_incoming_blocks[v2_child_id, new_block_copy_id] == new_block_id
        @test nnz(sc.branch_outgoing_blocks[v2_child_id, :]) == 1
        @test sc.branch_outgoing_blocks[v2_child_id, first_block_known_copy_id] == first_block_id
        @test sc.branch_is_unknown[v2_child_id] == false
        @test sc.branch_is_explained[v2_child_id] == true
        @test sc.branch_is_not_copy[v2_child_id] == false
        @test sc.unknown_min_path_costs[v2_child_id] === nothing
        @test sc.unknown_complexity_factors[v2_child_id] === nothing
        @test sc.complexities[v2_child_id] == 16.0
        @test sc.added_upstream_complexities[v2_child_id] == 0.0
        @test sc.unused_explained_complexities[v2_child_id] == 0.0
        @test sc.unmatched_complexities[v2_child_id] == 0.0
        @test nnz(sc.related_explained_complexity_branches[v2_child_id, :]) == 0
        @test nnz(sc.related_unknown_complexity_branches[v2_child_id, :]) == 0

        @test nnz(sc.branch_children[v1_child_id, :]) == 0
        @test nnz(sc.branch_children[:, v1_child_id]) == 1
        @test sc.branch_children[v1_branch_id, v1_child_id] == 1
        @test nnz(sc.constrained_vars[v1_var_id, :]) == 1
        @test sc.incoming_paths[v1_child_id] == [OrderedDict(v1_var_id => const_block_id)]
        @test nnz(sc.branch_incoming_blocks[v1_child_id, :]) == 1
        @test sc.branch_incoming_blocks[v1_child_id, const_block_copy_id] == const_block_id
        @test nnz(sc.branch_outgoing_blocks[v1_child_id, :]) == 1
        @test sc.branch_outgoing_blocks[v1_child_id, first_block_known_copy_id] == first_block_id
        @test sc.branch_is_unknown[v1_child_id] == true
        @test sc.branch_is_explained[v1_child_id] == true
        @test sc.branch_is_not_copy[v1_child_id] == true
        @test sc.unknown_min_path_costs[v1_child_id] == 2.4849066497880004
        @test sc.explained_min_path_costs[v1_child_id] === nothing
        @test sc.unknown_complexity_factors[v1_child_id] == 6.0
        @test sc.explained_complexity_factors[v1_child_id] == 16.0
        @test sc.complexities[v1_child_id] == 6.0
        @test sc.added_upstream_complexities[v1_child_id] == 10.0
        @test sc.unused_explained_complexities[v1_child_id] == 0.0
        @test sc.unmatched_complexities[v1_child_id] == 0.0
        @test nnz(sc.related_unknown_complexity_branches[v1_child_id, :]) == 1
        @test sc.related_unknown_complexity_branches[v1_child_id, v2_child_id] == 1
        @test nnz(sc.related_explained_complexity_branches[v1_child_id, :]) == 0

        @test nnz(sc.branch_children[out_branch_id, :]) == 0

        @test nnz(sc.constrained_branches[out_branch_id, :]) == 0
        @test nnz(sc.constrained_vars[out_var_id, :]) == 0
        @test sc.incoming_paths[out_branch_id] ==
              [OrderedDict(out_var_id => first_block_id, v2_var_id => new_block_id, v1_var_id => const_block_id)]
        @test nnz(sc.branch_incoming_blocks[out_branch_id, :]) == 2
        @test sc.branch_incoming_blocks[out_branch_id, first_block_copy_id] == first_block_id
        @test sc.branch_incoming_blocks[out_branch_id, first_block_known_copy_id] == first_block_id
        @test nnz(sc.branch_outgoing_blocks[out_branch_id, :]) == 0
        @test sc.branch_is_unknown[out_branch_id] == true
        @test sc.branch_is_explained[out_branch_id] == true
        @test sc.branch_is_not_copy[out_branch_id] == true
        @test sc.explained_min_path_costs[out_branch_id] == 2.4849066497880004
        @test sc.explained_complexity_factors[out_branch_id] == 29.0
        @test sc.complexities[out_branch_id] == 19.0
        @test sc.added_upstream_complexities[out_branch_id] == 10.0
        @test sc.unused_explained_complexities[out_branch_id] == 0.0
        @test sc.unmatched_complexities[out_branch_id] == 0.0
        @test nnz(sc.related_unknown_complexity_branches[out_branch_id, :]) == 0
        @test nnz(sc.related_explained_complexity_branches[out_branch_id, :]) == 0
    end
end


using DataStructures: PriorityQueue

"Solution context"
mutable struct SolutionContext
    entries::IndexedStorage{Entry}
    types::TypeStorage
    vars_count::CountStorage
    branches_count::CountStorage

    branch_is_unknown::VectorStorage{Bool,Bool}
    branch_is_explained::VectorStorage{Bool,Bool}
    branch_is_not_copy::VectorStorage{Bool,Bool}

    branch_entries::VectorStorage{UInt64,Nothing}
    branch_vars::VectorStorage{UInt64,Nothing}

    "[branch_id x type_id] -> type_id"
    branch_types::GraphStorage{Nothing}

    blocks::IndexedStorage{AbstractProgramBlock}
    block_copies_count::CountStorage

    constraints_count::CountStorage
    constraint_contexts::IndexedStorage{Context}

    "[parent_branch_id x child_branch_id] -> {nothing, 1}"
    branch_children::GraphStorage{Nothing}

    "[branch_id x block_copy_id] -> block_id"
    branch_incoming_blocks::GraphStorage{Nothing}
    "[branch_id x block_copy_id] -> block_id"
    branch_outgoing_blocks::GraphStorage{Nothing}

    "[var_id x constraint_id] -> branch_id"
    constrained_vars::GraphStorage{Nothing}
    "[branch_id x constraint_id] -> var_id"
    constrained_branches::GraphStorage{Nothing}
    "constraint_id -> context_id"
    constrained_contexts::VectorStorage{UInt64,Nothing}

    "[branch_id x related_branch_id] -> {nothing, 1}"
    related_explained_complexity_branches::GraphStorage{Nothing}
    "[branch_id x related_branch_id] -> {nothing, 1}"
    related_unknown_complexity_branches::GraphStorage{Nothing}

    "branch_id -> [{var_id -> block_id}]"
    incoming_paths::PathsStorage

    unknown_min_path_costs::VectorStorage{Float64,Nothing}
    explained_min_path_costs::VectorStorage{Float64,Nothing}
    unknown_complexity_factors::VectorStorage{Float64,Nothing}
    explained_complexity_factors::VectorStorage{Float64,Nothing}
    complexities::VectorStorage{Float64,Nothing}
    added_upstream_complexities::VectorStorage{Float64,Nothing}
    unused_explained_complexities::VectorStorage{Float64,Nothing}
    unmatched_complexities::VectorStorage{Float64,Nothing}

    "[previous_var_id x following_var_id] -> {nothing, 1}"
    previous_vars::GraphStorage{Nothing}

    input_keys::Dict{UInt64,String}
    target_branch_id::UInt64
    example_count::Int64
    type_weights::Dict{String,Float64}
    total_number_of_enumerated_programs::Int64
    pq_input::PriorityQueue{Tuple{UInt64,Bool},Float64,Base.Order.ForwardOrdering}
    pq_output::PriorityQueue{Tuple{UInt64,Bool},Float64,Base.Order.ForwardOrdering}
    branch_queues_unknown::Dict{UInt64,PriorityQueue{BlockPrototype,Float64,Base.Order.ForwardOrdering}}
    branch_queues_explained::Dict{UInt64,PriorityQueue{BlockPrototype,Float64,Base.Order.ForwardOrdering}}
    branch_unknown_from_output::VectorStorage{Bool,Bool}
    branch_known_from_input::VectorStorage{Bool,Bool}

    verbose::Bool
end

function create_starting_context(task::Task, type_weights, verbose)::SolutionContext
    argument_types = arguments_of_type(task.task_type)
    example_count = length(task.train_outputs)
    sc = SolutionContext(
        IndexedStorage{Entry}(),
        TypeStorage(),
        CountStorage(),
        CountStorage(),
        VectorStorage{Bool}(false),
        VectorStorage{Bool}(false),
        VectorStorage{Bool}(false),
        VectorStorage{UInt64}(),
        VectorStorage{UInt64}(),
        GraphStorage(),
        IndexedStorage{AbstractProgramBlock}(),
        CountStorage(),
        CountStorage(),
        IndexedStorage{Context}(),
        GraphStorage(),
        GraphStorage(),
        GraphStorage(),
        GraphStorage(),
        GraphStorage(),
        VectorStorage{UInt64}(),
        GraphStorage(),
        GraphStorage(),
        PathsStorage(),
        VectorStorage{Float64}(),
        VectorStorage{Float64}(),
        VectorStorage{Float64}(),
        VectorStorage{Float64}(),
        VectorStorage{Float64}(),
        VectorStorage{Float64}(),
        VectorStorage{Float64}(),
        VectorStorage{Float64}(),
        GraphStorage(),
        Dict{UInt64,String}(),
        0,
        example_count,
        type_weights,
        0,
        PriorityQueue{Tuple{UInt64,Bool},Float64}(),
        PriorityQueue{Tuple{UInt64,Bool},Float64}(),
        Dict(),
        Dict(),
        VectorStorage{Bool}(false),
        VectorStorage{Bool}(false),
        verbose,
    )
    start_transaction!(sc)
    for (key, t) in argument_types
        values = [inp[key] for inp in task.train_inputs]
        complexity_summary = get_complexity_summary(values, t)
        type_id = push!(sc.types, t)
        entry = ValueEntry(type_id, values, complexity_summary, get_complexity(sc, complexity_summary))
        entry_id = push!(sc.entries, entry)
        var_id = create_next_var(sc)
        sc.input_keys[var_id] = key

        branch_id = increment!(sc.branches_count)

        sc.branch_entries[branch_id] = entry_id
        sc.branch_vars[branch_id] = var_id
        sc.branch_types[branch_id, type_id] = type_id
        sc.branch_is_explained[branch_id] = true
        sc.branch_is_not_copy[branch_id] = true
        sc.branch_known_from_input[branch_id] = true

        sc.explained_min_path_costs[branch_id] = 0.0
        sc.explained_complexity_factors[branch_id] = entry.complexity
        sc.complexities[branch_id] = entry.complexity
        sc.added_upstream_complexities[branch_id] = 0.0
        sc.unused_explained_complexities[branch_id] = entry.complexity

        add_path!(sc.incoming_paths, branch_id, empty_path())
    end
    return_type = return_of_type(task.task_type)
    complexity_summary = get_complexity_summary(task.train_outputs, return_type)
    type_id = push!(sc.types, return_type)
    entry = ValueEntry(type_id, task.train_outputs, complexity_summary, get_complexity(sc, complexity_summary))
    entry_id = push!(sc.entries, entry)
    var_id = create_next_var(sc)
    branch_id = increment!(sc.branches_count)

    sc.branch_entries[branch_id] = entry_id
    sc.branch_vars[branch_id] = var_id
    sc.branch_types[branch_id, type_id] = type_id
    sc.branch_is_unknown[branch_id] = true
    sc.branch_unknown_from_output[branch_id] = true

    sc.target_branch_id = branch_id

    sc.unknown_min_path_costs[branch_id] = 0.0
    sc.unknown_complexity_factors[branch_id] = entry.complexity
    sc.complexities[branch_id] = entry.complexity
    sc.unmatched_complexities[branch_id] = entry.complexity

    return sc
end

function transaction(f, sc::SolutionContext)
    try
        start_transaction!(sc)
        f()
        save_changes!(sc)
        return nothing
    catch e
        if isa(e, EnumerationException)
            drop_changes!(sc)
            return nothing
        else
            rethrow()
        end
    end
end

function start_transaction!(sc::SolutionContext)
    start_transaction!(sc.entries)
    start_transaction!(sc.types)
    start_transaction!(sc.vars_count)
    start_transaction!(sc.branches_count)
    start_transaction!(sc.branch_is_explained)
    start_transaction!(sc.branch_is_not_copy)
    start_transaction!(sc.branch_is_unknown)
    start_transaction!(sc.branch_entries)
    start_transaction!(sc.branch_vars)
    start_transaction!(sc.branch_types)
    start_transaction!(sc.blocks)
    start_transaction!(sc.block_copies_count)
    start_transaction!(sc.constraints_count)
    start_transaction!(sc.constraint_contexts)
    start_transaction!(sc.branch_children)
    start_transaction!(sc.branch_incoming_blocks)
    start_transaction!(sc.branch_outgoing_blocks)
    start_transaction!(sc.constrained_vars)
    start_transaction!(sc.constrained_branches)
    start_transaction!(sc.constrained_contexts)
    start_transaction!(sc.related_explained_complexity_branches)
    start_transaction!(sc.related_unknown_complexity_branches)
    start_transaction!(sc.incoming_paths)
    start_transaction!(sc.unknown_min_path_costs)
    start_transaction!(sc.explained_min_path_costs)
    start_transaction!(sc.unknown_complexity_factors)
    start_transaction!(sc.explained_complexity_factors)
    start_transaction!(sc.complexities)
    start_transaction!(sc.added_upstream_complexities)
    start_transaction!(sc.unused_explained_complexities)
    start_transaction!(sc.unmatched_complexities)
    start_transaction!(sc.previous_vars)
    start_transaction!(sc.branch_unknown_from_output)
    start_transaction!(sc.branch_known_from_input)
    nothing
end

function save_changes!(sc::SolutionContext)
    save_changes!(sc.entries)
    save_changes!(sc.types)
    save_changes!(sc.vars_count)
    save_changes!(sc.branches_count)
    save_changes!(sc.branch_is_explained)
    save_changes!(sc.branch_is_not_copy)
    save_changes!(sc.branch_is_unknown)
    save_changes!(sc.branch_entries)
    save_changes!(sc.branch_vars)
    save_changes!(sc.branch_types)
    save_changes!(sc.blocks)
    save_changes!(sc.block_copies_count)
    save_changes!(sc.constraints_count)
    save_changes!(sc.constraint_contexts)
    save_changes!(sc.branch_children)
    save_changes!(sc.branch_incoming_blocks)
    save_changes!(sc.branch_outgoing_blocks)
    save_changes!(sc.constrained_vars)
    save_changes!(sc.constrained_branches)
    save_changes!(sc.constrained_contexts)
    save_changes!(sc.related_explained_complexity_branches)
    save_changes!(sc.related_unknown_complexity_branches)
    save_changes!(sc.incoming_paths)
    save_changes!(sc.unknown_min_path_costs)
    save_changes!(sc.explained_min_path_costs)
    save_changes!(sc.unknown_complexity_factors)
    save_changes!(sc.explained_complexity_factors)
    save_changes!(sc.complexities)
    save_changes!(sc.added_upstream_complexities)
    save_changes!(sc.unused_explained_complexities)
    save_changes!(sc.unmatched_complexities)
    save_changes!(sc.previous_vars)
    save_changes!(sc.branch_unknown_from_output)
    save_changes!(sc.branch_known_from_input)
    nothing
end

function drop_changes!(sc::SolutionContext)
    drop_changes!(sc.entries)
    drop_changes!(sc.types)
    drop_changes!(sc.vars_count)
    drop_changes!(sc.branches_count)
    drop_changes!(sc.branch_is_explained)
    drop_changes!(sc.branch_is_not_copy)
    drop_changes!(sc.branch_is_unknown)
    drop_changes!(sc.branch_entries)
    drop_changes!(sc.branch_vars)
    drop_changes!(sc.branch_types)
    drop_changes!(sc.blocks)
    drop_changes!(sc.block_copies_count)
    drop_changes!(sc.constraints_count)
    drop_changes!(sc.constraint_contexts)
    drop_changes!(sc.branch_children)
    drop_changes!(sc.branch_incoming_blocks)
    drop_changes!(sc.branch_outgoing_blocks)
    drop_changes!(sc.constrained_vars)
    drop_changes!(sc.constrained_branches)
    drop_changes!(sc.constrained_contexts)
    drop_changes!(sc.related_explained_complexity_branches)
    drop_changes!(sc.related_unknown_complexity_branches)
    drop_changes!(sc.incoming_paths)
    drop_changes!(sc.unknown_min_path_costs)
    drop_changes!(sc.explained_min_path_costs)
    drop_changes!(sc.unknown_complexity_factors)
    drop_changes!(sc.explained_complexity_factors)
    drop_changes!(sc.complexities)
    drop_changes!(sc.added_upstream_complexities)
    drop_changes!(sc.unused_explained_complexities)
    drop_changes!(sc.unmatched_complexities)
    drop_changes!(sc.previous_vars)
    drop_changes!(sc.branch_unknown_from_output)
    drop_changes!(sc.branch_known_from_input)
    nothing
end

function create_next_var(sc::SolutionContext)
    v = increment!(sc.vars_count)
    sc.previous_vars[v, v] = 1
    return v
end

function update_branch_priority(sc::SolutionContext, branch_id::UInt64, is_known::Bool)
    if is_known
        pq = sc.branch_known_from_input[branch_id] ? sc.pq_input : sc.pq_output
        q = sc.branch_queues_explained[branch_id]
    else
        pq = sc.branch_unknown_from_output[branch_id] ? sc.pq_output : sc.pq_input
        q = sc.branch_queues_unknown[branch_id]
    end
    if !isempty(q)
        min_cost = peek(q)[2]
        if is_known
            pq[(branch_id, is_known)] =
                (sc.explained_min_path_costs[branch_id] + min_cost) * sc.explained_complexity_factors[branch_id]
            if sc.verbose
                @info "Known $(sc.branch_known_from_input[branch_id] ? "in" : "out" ) branch $branch_id priority is $(pq[(branch_id, is_known)]) with path cost $(sc.explained_min_path_costs[branch_id]) + $(min_cost) and complexity factor $(sc.explained_complexity_factors[branch_id])"
            end
        else
            pq[(branch_id, is_known)] =
                (sc.unknown_min_path_costs[branch_id] + min_cost) * sc.unknown_complexity_factors[branch_id]
            if sc.verbose
                @info "Unknown $(sc.branch_unknown_from_output[branch_id] ? "out" : "in" ) branch $branch_id priority is $(pq[(branch_id, is_known)]) with path cost $(sc.unknown_min_path_costs[branch_id]) + $(min_cost) and complexity factor $(sc.unknown_complexity_factors[branch_id])"
            end
        end
    elseif haskey(pq, (branch_id, is_known))
        delete!(pq, (branch_id, is_known))
        if sc.verbose
            @info "Dropped $(is_known ? "known" : "unknown") branch $branch_id"
        end
    end
end

function get_input_paths_for_new_block(sc::SolutionContext, bl, input_branches)
    new_block_paths = [empty_path()]
    for in_var in bl.input_vars
        inp_branch_id = input_branches[in_var]
        next_paths = []
        for path in new_block_paths
            for inp_path in sc.incoming_paths[inp_branch_id]
                new_path = merge_paths(sc, path, inp_path)
                if !isnothing(new_path)
                    push!(next_paths, new_path)
                end
            end
        end
        new_block_paths = next_paths
    end
    return new_block_paths
end

function get_input_paths_for_existing_block(sc::SolutionContext, bl, input_branches, new_paths)
    new_block_paths = []
    for v_id in bl.input_vars
        if !haskey(new_paths, input_branches[v_id])
            continue
        end
        new_block_paths_part = [empty_path()]
        for in_var_id in bl.input_vars
            inp_branch_id = input_branches[in_var_id]
            next_paths = []
            for path in new_block_paths_part
                if in_var_id == v_id
                    inp_paths = new_paths[inp_branch_id]
                elseif in_var_id < v_id && haskey(new_paths, inp_branch_id)
                    inp_paths = filter(p -> !in(p, new_paths[inp_branch_id]), sc.incoming_paths[inp_branch_id])
                else
                    inp_paths = sc.incoming_paths[inp_branch_id]
                end
                for inp_path in inp_paths
                    new_path = merge_paths(sc, path, inp_path)
                    if !isnothing(new_path)
                        push!(next_paths, new_path)
                    end
                end
            end
            new_block_paths_part = next_paths
        end
        append!(new_block_paths, new_block_paths_part)
    end
    return new_block_paths
end

function get_new_paths_for_block(sc::SolutionContext, bl_id, is_new_block, new_paths, output_branches, input_branches)
    # @info "Getting paths for new block $bl"
    bl = sc.blocks[bl_id]
    if is_new_block
        input_paths = get_input_paths_for_new_block(sc, bl, input_branches)
    else
        input_paths = get_input_paths_for_existing_block(sc, bl, input_branches, new_paths)
    end
    check_path_cost = nnz(sc.explained_min_path_costs[UInt64[input_branches[v_id] for v_id in bl.input_vars]]) > 0
    best_cost = Inf
    if check_path_cost
        for path in input_paths
            cost = path_cost(sc, path) + bl.cost
            if cost < best_cost
                best_cost = cost
            end
        end
    end
    return set_new_paths_for_block(sc, bl_id, bl, input_paths, output_branches, check_path_cost, best_cost)
end

function set_new_paths_for_block(
    sc::SolutionContext,
    bl_id,
    bl::ProgramBlock,
    input_paths,
    output_branches,
    check_path_cost,
    best_cost,
)
    if isa(bl.p, FreeVar)
        filter!(input_paths) do path
            if !haskey(path.main_path, bl.input_vars[1])
                return true
            end
            prev_block = sc.blocks[path.main_path[bl.input_vars[1]]]
            return !isa(prev_block, ProgramBlock) || !isa(prev_block.p, FreeVar)
        end
    end
    return Dict([
        set_new_paths_for_var(
            sc,
            bl_id,
            bl.output_var,
            [],
            input_paths,
            output_branches,
            check_path_cost,
            best_cost,
            !isa(bl.p, FreeVar),
        ),
    ])
end

function set_new_paths_for_block(
    sc::SolutionContext,
    bl_id,
    bl::Union{ReverseProgramBlock,WrapEitherBlock},
    input_paths,
    output_branches,
    check_path_cost,
    best_cost,
)
    return Dict([
        set_new_paths_for_var(
            sc,
            bl_id,
            out_var_id,
            [v for v in bl.output_vars if v != out_var_id],
            input_paths,
            output_branches,
            check_path_cost,
            best_cost,
            true,
        ) for out_var_id in bl.output_vars
    ])
end

function set_new_paths_for_var(
    sc::SolutionContext,
    bl_id,
    var_id,
    side_vars,
    input_paths,
    output_branches,
    check_path_cost,
    best_cost,
    is_not_copy,
)
    out_branch_id = output_branches[var_id]
    new_block_paths = []
    for path in input_paths
        p = merge_path(sc, path, var_id, bl_id, side_vars)
        path_added = add_path!(sc.incoming_paths, out_branch_id, p)
        if path_added
            push!(new_block_paths, p)
        end
    end
    if check_path_cost &&
       (isnothing(sc.explained_min_path_costs[out_branch_id]) || best_cost < sc.explained_min_path_costs[out_branch_id])
        sc.explained_min_path_costs[out_branch_id] = best_cost
    end
    if !sc.branch_is_explained[out_branch_id]
        sc.branch_is_explained[out_branch_id] = true
    end
    if is_not_copy && !sc.branch_is_not_copy[out_branch_id]
        sc.branch_is_not_copy[out_branch_id] = true
    end
    return (out_branch_id, new_block_paths)
end

function branch_complexity_factor_unknown(sc::SolutionContext, branch_id)
    related_branches = nonzeroinds(sc.related_unknown_complexity_branches[branch_id, :])
    return _branch_complexity_factor_unknown(sc, branch_id, related_branches)
end

function branch_complexity_factor_known(sc::SolutionContext, branch_id)
    related_branches = nonzeroinds(sc.related_explained_complexity_branches[branch_id, :])
    return _branch_complexity_factor_known(sc, branch_id, sc.added_upstream_complexities[branch_id], related_branches)
end

function _branch_complexity_factor_known(sc::SolutionContext, branch_id, added_complexity, related_branches)
    return sc.complexities[branch_id] +
           added_complexity +
           sum(sc.unused_explained_complexities[br_id] for br_id in related_branches; init = 0.0)
end

function _branch_complexity_factor_unknown(sc::SolutionContext, branch_id, related_branches)
    return sc.complexities[branch_id] + sum(sc.unmatched_complexities[br_id] for br_id in related_branches; init = 0.0)
end

function _update_complexity_factor_unknown(sc::SolutionContext, branch_id)
    if !isnothing(sc.complexities[branch_id])
        new_factor = branch_complexity_factor_unknown(sc, branch_id)
        if new_factor < sc.unknown_complexity_factors[branch_id]
            sc.unknown_complexity_factors[branch_id] = new_factor
        end
    else
        for out_block_copy_id in nonzeroinds(sc.branch_outgoing_blocks[branch_id, :])
            out_branches = nonzeroinds(sc.branch_incoming_blocks[:, out_block_copy_id])
            for out_branch_id in out_branches
                if sc.complexity_factors[branch_id] > sc.complexity_factors[out_branch_id]
                    sc.complexity_factors[branch_id] = sc.complexity_factors[out_branch_id]
                end
            end
        end
    end
end

function _push_unmatched_complexity_to_output(sc::SolutionContext, branch_id, fixed_branches, unmatched_complexity)
    current_unmatched_complexity = sc.unmatched_complexities[branch_id]
    if isnothing(current_unmatched_complexity) || current_unmatched_complexity > unmatched_complexity
        sc.unmatched_complexities[branch_id] = unmatched_complexity

        # @info "Updating complexities for $branch_id"
        # @info fixed_branches

        out_block_copies = nonzeroinds(sc.branch_outgoing_blocks[branch_id, :])

        for out_block_copy_id in out_block_copies
            inp_branches = nonzeroinds(sc.branch_outgoing_blocks[:, out_block_copy_id])

            un_complexity = sum(sc.unmatched_complexities[inp_branches])

            out_branches = nonzeroinds(sc.branch_incoming_blocks[:, out_block_copy_id])

            if nnz(sc.constrained_branches[out_branches, :]) > 0
                continue
                # error("Not implemented")
            end

            for out_branch_id in out_branches
                _push_unmatched_complexity_to_output(sc, out_branch_id, fixed_branches, un_complexity)
            end
        end
    end
end

function _push_unused_complexity_to_input(sc::SolutionContext, branch_id, fixed_branches, unused_complexity)
    current_unused_complexity = sc.unused_explained_complexities[branch_id]
    if isnothing(current_unused_complexity) || current_unused_complexity > unused_complexity
        sc.unused_explained_complexities[branch_id] = unused_complexity
        for (in_block_copy_id, in_block_id) in zip(findnz(sc.branch_incoming_blocks[branch_id, :])...)
            in_block = sc.blocks[in_block_id]

            out_branches = nonzeroinds(sc.branch_incoming_blocks[:, in_block_copy_id])
            if isa(in_block, ReverseProgramBlock)
                if any(
                    v_id -> haskey(fixed_branches, v_id) && !in(fixed_branches[v_id], out_branches),
                    in_block.output_vars,
                )
                    continue
                end
            end

            in_branches = nonzeroinds(sc.branch_outgoing_blocks[:, in_block_copy_id])
            if any(!sc.branch_is_explained[br] for br in in_branches)
                continue
            end
            if any(
                in_var -> haskey(fixed_branches, in_var) && !in(fixed_branches[in_var], in_branches),
                in_block.input_vars,
            )
                continue
            end
            un_complexity = sum(sc.unused_explained_complexities[out_branches])
            for in_branch_id in in_branches
                _push_unused_complexity_to_input(sc, in_branch_id, fixed_branches, un_complexity)
            end
        end
    end
end

function update_complexity_factors_unknown(sc::SolutionContext, input_branches, output_branch)
    if any(isnothing(sc.complexities[br_id]) for (_, br_id) in input_branches)
        return
    end
    branch_ids = UInt64[br_id for (_, br_id) in input_branches]
    un_complexity = sum(sc.unmatched_complexities[branch_ids])

    _push_unmatched_complexity_to_output(sc, output_branch, input_branches, un_complexity)

    related_branches = nonzeroinds(sc.related_unknown_complexity_branches[:, output_branch])
    for related_branch_id in related_branches
        # @info "Updating unknown complexity factor for related branch $related_branch_id"
        _update_complexity_factor_unknown(sc, related_branch_id)
    end
end

function update_complexity_factors_known(sc::SolutionContext, bl::ProgramBlock, input_branches, output_branches)
    out_branch_id = output_branches[bl.output_var]
    parents = get_all_parents(sc, out_branch_id)
    if isempty(bl.input_vars)
        if isnothing(sc.explained_complexity_factors[out_branch_id])
            if isempty(parents)
                sc.added_upstream_complexities[out_branch_id] =
                    sc.unknown_complexity_factors[out_branch_id] - sc.complexities[out_branch_id]
                sc.explained_complexity_factors[out_branch_id] =
                    sc.added_upstream_complexities[out_branch_id] + sc.complexities[out_branch_id]
            else
                best_parent = nothing
                for parent in parents
                    if isnothing(best_parent) ||
                       sc.unknown_complexity_factors[parent] > sc.unknown_complexity_factors[best_parent]
                        best_parent = parent
                    end
                end
                sc.added_upstream_complexities[out_branch_id] =
                    sc.unknown_complexity_factors[best_parent] - sc.complexities[best_parent]
                sc.explained_complexity_factors[out_branch_id] =
                    sc.added_upstream_complexities[out_branch_id] + sc.complexities[out_branch_id]
            end
        end
    else
        related_branches = Dict()
        in_complexity = 0.0
        added_upstream_complexity = 0.0
        for inp_var_id in bl.input_vars
            inp_branch_id = input_branches[inp_var_id]
            in_complexity += sc.complexities[inp_branch_id]
            added_upstream_complexity += sc.added_upstream_complexities[inp_branch_id]
            related_brs = nonzeroinds(sc.related_explained_complexity_branches[inp_branch_id, :])
            merge!(related_branches, Dict(zip(related_brs, sc.branch_vars[related_brs])))
        end

        for path in get_new_paths(sc.incoming_paths, out_branch_id)
            filtered_related_branches =
                UInt64[b_id for (b_id, var_id) in related_branches if !path_sets_var(path, var_id)]
            if isa(bl.p, FreeVar) || bl.is_reversible
                new_added_complexity = added_upstream_complexity
            else
                new_added_complexity =
                    added_upstream_complexity + max(sc.complexities[out_branch_id] - in_complexity, 0.0)
            end
            new_complexity_factor =
                _branch_complexity_factor_known(sc, out_branch_id, new_added_complexity, filtered_related_branches)
            current_factor = sc.explained_complexity_factors[out_branch_id]
            if isnothing(current_factor) || new_complexity_factor < current_factor
                sc.explained_complexity_factors[out_branch_id] = new_complexity_factor
                sc.added_upstream_complexities[out_branch_id] = new_added_complexity
                deleteat!(sc.related_explained_complexity_branches, out_branch_id, :)
                sc.related_explained_complexity_branches[out_branch_id, filtered_related_branches] = 1
            end
        end
    end

    if !any(isnothing, sc.complexities[parents])
        _push_unmatched_complexity_to_output(sc, out_branch_id, input_branches, 0.0)
        _push_unused_complexity_to_input(sc, out_branch_id, input_branches, 0.0)
        # for inp_branch_var in bl.input_vars
        #     _push_unused_complexity_to_input(sc, input_branches[inp_branch_var], input_branches, 0.0)
        # end
    end
end

function _update_complexity_factor_known(sc::SolutionContext, branch_id)
    new_factor = branch_complexity_factor_known(sc, branch_id)
    if sc.explained_complexity_factors[branch_id] > new_factor
        sc.explained_complexity_factors[branch_id] = new_factor
    end
end

function update_complexity_factors_known(
    sc::SolutionContext,
    bl::Union{ReverseProgramBlock,WrapEitherBlock},
    input_branches,
    output_branches,
)
    in_branch_id = input_branches[bl.input_vars[1]]

    added_upstream_complexity = sc.added_upstream_complexities[in_branch_id]

    for out_var_id in bl.output_vars
        out_branch_id = output_branches[out_var_id]
        related_brs = nonzeroinds(sc.related_explained_complexity_branches[out_branch_id, :])
        related_branches = Dict(zip(related_brs, sc.branch_vars[related_brs]))
        for path in get_new_paths(sc.incoming_paths, out_branch_id)
            filtered_related_branches =
                UInt64[b_id for (b_id, var_id) in related_branches if !path_sets_var(path, var_id)]

            new_complexity_factor =
                _branch_complexity_factor_known(sc, out_branch_id, added_upstream_complexity, filtered_related_branches)
            current_factor = sc.explained_complexity_factors[out_branch_id]
            if isnothing(current_factor) || new_complexity_factor < current_factor
                sc.explained_complexity_factors[out_branch_id] = new_complexity_factor
                sc.added_upstream_complexities[out_branch_id] = added_upstream_complexity
                deleteat!(sc.related_explained_complexity_branches, out_branch_id, :)
                sc.related_explained_complexity_branches[out_branch_id, filtered_related_branches] = 1
            end
        end
    end

    out_complexity = reduce(+, sc.complexities[UInt64[output_branches[v_id] for v_id in bl.output_vars]])
    _push_unused_complexity_to_input(sc, in_branch_id, Dict(), out_complexity)
end

function update_context(sc::SolutionContext)
    updated_unmatched_complexities = get_new_values(sc.unmatched_complexities)
    new_branches = get_new_values(sc.branch_is_unknown)
    setdiff!(updated_unmatched_complexities, new_branches)
    related_branches = unique(nonzeroinds(sc.related_unknown_complexity_branches[:, updated_unmatched_complexities])[1])
    for branch_id in related_branches
        _update_complexity_factor_unknown(sc, branch_id)
    end

    updated_unused_complexities = get_new_values(sc.unused_explained_complexities)
    new_branches = get_new_values(sc.branch_is_explained)
    setdiff!(updated_unused_complexities, new_branches)
    related_branches = unique(nonzeroinds(sc.related_explained_complexity_branches[:, updated_unused_complexities])[1])
    for branch_id in related_branches
        _update_complexity_factor_known(sc, branch_id)
    end

    return get_new_paths(sc.incoming_paths, sc.target_branch_id)
end

function update_prev_follow_vars(sc::SolutionContext, block_id::UInt64)
    bl = sc.blocks[block_id]
    _update_prev_follow_vars(sc, bl)
end

function _update_prev_follow_vars(sc::SolutionContext, bl::ProgramBlock)
    if isempty(bl.input_vars)
        return
    end
    inp_prev_vars = nonzeroinds(reduce(any, sc.previous_vars[:, bl.input_vars], dims = 2))
    out_foll_vars = nonzeroinds(sc.previous_vars[bl.output_var, :])
    sc.previous_vars[inp_prev_vars, out_foll_vars] = 1
end

function _update_prev_follow_vars(sc, bl::Union{ReverseProgramBlock,WrapEitherBlock})
    inp_prev_vars = nonzeroinds(reduce(any, sc.previous_vars[:, bl.input_vars], dims = 2))
    out_foll_vars = nonzeroinds(reduce(any, sc.previous_vars[bl.output_vars, :], dims = 1; desc = Descriptor()))
    sc.previous_vars[inp_prev_vars, out_foll_vars] = 1
end

function vars_in_loop(sc::SolutionContext, known_var_id, unknown_var_id)
    prev_known = sc.previous_vars[:, known_var_id]
    foll_unknown = sc.previous_vars[unknown_var_id, :]
    !isnothing((transpose(foll_unknown)*prev_known)[1])
end

function is_block_loops(sc::SolutionContext, bp::BlockPrototype)
    if isnothing(bp.input_vars)
        return false
    end
    if bp.reverse
        inp_vars = [bp.output_var[1]]
        out_vars = collect(keys(bp.input_vars))
    else
        out_vars = [bp.output_var[1]]
        inp_vars = collect(keys(bp.input_vars))
    end
    prev_inputs = reduce(any, sc.previous_vars[:, inp_vars], dims = 2)
    foll_outputs = reduce(any, sc.previous_vars[out_vars, :], dims = 1)
    return !isnothing((transpose(foll_outputs)*prev_inputs)[1])
end

function assert_context_consistency(sc::SolutionContext)
    return
    function _validate_branch(branch_id)
        if sc.branch_is_explained[branch_id]
            if nnz(sc.branch_children[branch_id, :]) > 0
                error("Known branch $branch_id has children")
            end
        else
            if !sc.branch_is_unknown[branch_id]
                # error("Unexplained branch $branch_id is not unknown")
            end
        end
        branch_parents = nonzeroinds(sc.branch_children[:, branch_id])
        var_id = sc.branch_vars[branch_id]

        branch_outgoing_block_copies = sc.branch_outgoing_blocks[branch_id, :]
        for child_id in nonzeroinds(sc.branch_children[branch_id, :])
            if any(in(p_id, branch_parents) for p_id in nonzeroinds(sc.branch_children[:, child_id]))
                error("Branch $child_id is a child of $branch_id but also is a child of one of its parents")
            end
            child_outgoing_block_copies = sc.branch_outgoing_blocks[child_id, :]
            if !issubset(Set(nonzeros(branch_outgoing_block_copies)), Set(nonzeros(child_outgoing_block_copies)))
                error(
                    "Branch $branch_id outgoing blocks $(Set(nonzeros(branch_outgoing_block_copies))) are missing from child $child_id outgoing blocks $(Set(nonzeros(child_outgoing_block_copies)))",
                )
            end
            if sc.branch_vars[branch_id] != sc.branch_vars[child_id]
                error("Branch $branch_id key differs from child $child_id key")
            end
        end
        for constraint_id in nonzeroinds(sc.constrained_branches[branch_id, :])
            if sc.constrained_branches[branch_id, constraint_id] != var_id
                error(
                    "Constrained var_id in constraint $constraint_id for branch $branch_id is $(sc.constrained_branches[branch_id, constraint_id]) differs from original $var_id",
                )
            end
            if sc.constrained_vars[var_id, constraint_id] != branch_id
                error(
                    "Constrained branch_id in constraint $constraint_id for var_id $var_id is $(sc.constrained_vars[var_id, constraint_id]) differs from expected $branch_id",
                )
            end
        end
        # if !isnothing(branch.complexity) &&
        #    branch.complexity_factor !=
        #    branch.complexity + sum(b.best_complexity for b in branch.related_complexity_branches; init = 0.0)
        #     error(
        #         "Branch $branch complexity factor is should be $(branch.complexity + sum(b.best_complexity for b in branch.related_complexity_branches; init=0.0)) but is $(branch.complexity_factor)",
        #     )
        # end

    end
    for branch_id in 1:sc.branches_count[]
        _validate_branch(branch_id)
    end
end


function export_frontiers(number_enumerated, task, solutions)
    Dict(
        "number_enumerated" => number_enumerated,
        "solutions" => [
            Dict(
                "program" => s.hit_program,
                "time" => s.hit_time,
                "logLikelihood" => s.hit_likelihood,
                "logPrior" => s.hit_prior,
            ) for s in solutions
        ],
    )
end

using MetaGraphsNext
using Graphs
using Dates

function get_var_branches(sc, branch_id)
    root_parent = get_root_parent(sc, branch_id)
    var_branches = get_all_children(sc, root_parent)
    push!(var_branches, root_parent)
    return var_branches
end

function check_following_blocks(
    sc::SolutionContext,
    branch_id,
    depth,
    right_border_depth,
    vars_depths,
    block_depths,
    following_vars_depths,
    following_blocks_depths,
)
    var_branches = get_var_branches(sc, branch_id)
    max_depth = depth
    for var_branch in var_branches
        for (block_copy_id, block_id) in get_connected_from(sc.branch_outgoing_blocks, var_branch)
            # if haskey(block_depths, block_id) || haskey(following_blocks_depths, block_id)
            #     continue
            # end
            block_outputs = get_connected_to(sc.branch_incoming_blocks, block_copy_id)
            following_blocks_depths[block_id] = depth
            for (output_branch_id, _) in block_outputs
                output_var_id = sc.branch_vars[output_branch_id]
                if haskey(following_vars_depths, output_var_id)
                    continue
                end
                if haskey(vars_depths, output_var_id)
                    following_max_depth = vars_depths[output_var_id] - right_border_depth + depth
                else
                    following_vars_depths[output_var_id] = depth + 1
                    following_max_depth, following_vars_depths, following_blocks_depths = check_following_blocks(
                        sc,
                        output_branch_id,
                        depth + 1,
                        right_border_depth,
                        vars_depths,
                        block_depths,
                        following_vars_depths,
                        following_blocks_depths,
                    )
                end
                max_depth = max(max_depth, following_max_depth)
            end
        end
    end
    return max_depth, following_vars_depths, following_blocks_depths
end

function do_sorting_step(sc::SolutionContext, queue, visited_branches, remaining_vars, vars_depths, blocks_depths)
    branch_id = pop!(queue)
    var_id = sc.branch_vars[branch_id]
    if !in(var_id, remaining_vars)
        return
    end
    delete!(remaining_vars, var_id)
    var_branches = get_var_branches(sc, branch_id)
    # @info "starting iteration for $var_id"
    # @info var_branches

    for var_branch in var_branches
        for (block_copy_id, block_id) in get_connected_from(sc.branch_incoming_blocks, var_branch)
            # @info "Checking incomimg block $block_copy_id $block_id"
            if !haskey(blocks_depths, block_id)
                blocks_depths[block_id] = vars_depths[var_id]
            end
            block_inputs = get_connected_to(sc.branch_outgoing_blocks, block_copy_id)
            # @info "block_inputs $block_inputs"
            inputs_depths = 0
            following_vars_depths = Dict()
            following_blocks_depths = Dict()
            for (input_branch_id, _) in block_inputs
                following_depth, following_vars_depths, following_blocks_depths = check_following_blocks(
                    sc,
                    input_branch_id,
                    0,
                    vars_depths[var_id],
                    vars_depths,
                    blocks_depths,
                    following_vars_depths,
                    following_blocks_depths,
                )
                # @info "For input $input_branch_id $(sc.branch_vars[input_branch_id]) following_depth $following_depth"
                # @info "following_vars_depths $following_vars_depths"
                # @info "following_blocks_depths $following_blocks_depths"
                inputs_depths = max(inputs_depths, following_depth)
            end
            # @info "inputs_depths $inputs_depths"
            # @info "following_vars_depths $following_vars_depths"
            # @info "following_blocks_depths $following_blocks_depths"
            for (v_id, depth) in following_vars_depths
                vars_depths[v_id] = vars_depths[var_id] + inputs_depths - depth + 1
            end
            for (b_id, depth) in following_blocks_depths
                blocks_depths[b_id] = vars_depths[var_id] + inputs_depths - depth
            end
            new_depth = vars_depths[var_id] + inputs_depths + 1
            for (input_branch_id, _) in block_inputs
                if !haskey(vars_depths, sc.branch_vars[input_branch_id])
                    vars_depths[sc.branch_vars[input_branch_id]] = new_depth
                else
                    # vars_depths[sc.branch_vars[input_branch_id]] =
                    #     max(vars_depths[sc.branch_vars[input_branch_id]], new_depth)
                end
                push!(queue, input_branch_id)
            end
            # @info "vars_depths $vars_depths"
            # @info "blocks_depths $blocks_depths"
        end
    end
end

function sort_vars_and_blocks(sc::SolutionContext)
    remaining_vars = Set(1:sc.vars_count[])
    output_var = sc.branch_vars[sc.target_branch_id]
    vars_depths = Dict{UInt64,Int}(output_var => 0)
    blocks_depths = Dict{UInt64,Int}()
    visited_branches = Set()
    queue = Set{UInt64}()
    push!(queue, sc.target_branch_id)
    while !isempty(queue)
        do_sorting_step(sc, queue, visited_branches, remaining_vars, vars_depths, blocks_depths)
    end
    if !isempty(remaining_vars)
        right_border_depth = maximum(values(vars_depths))
        inputs_depths = 0
        following_vars_depths = Dict()
        following_blocks_depths = Dict()
        for var_id in keys(sc.input_keys)
            if in(var_id, remaining_vars)
                branch_id = var_id  # hack due to initialization procedure

                following_depth, following_vars_depths, following_blocks_depths = check_following_blocks(
                    sc,
                    branch_id,
                    0,
                    right_border_depth,
                    vars_depths,
                    blocks_depths,
                    following_vars_depths,
                    following_blocks_depths,
                )
                inputs_depths = max(inputs_depths, following_depth)
            end
        end
        # @info "following_vars_depths $following_vars_depths"
        # @info "following_blocks_depths $following_blocks_depths"

        for (v_id, depth) in following_vars_depths
            vars_depths[v_id] = right_border_depth + inputs_depths - depth + 1
        end
        for (b_id, depth) in following_blocks_depths
            blocks_depths[b_id] = right_border_depth + inputs_depths - depth
        end
    end
    max_depth = maximum(values(vars_depths))
    out_var_depths = Dict{UInt64,Float64}()
    out_block_depths = Dict{UInt64,Float64}()
    for (var_id, depth) in vars_depths
        out_var_depths[var_id] = (max_depth / 2 - depth) * 20 + (rand() - 0.5) * 10
    end
    for (block_id, depth) in blocks_depths
        out_block_depths[block_id] = (max_depth / 2 - depth) * 20 - 10 + (rand() - 0.5) * 10
    end
    # @info remaining_vars
    # @info "vars_depths $vars_depths"
    # @info "blocks_depths $blocks_depths"
    # @info "out_var_depths $out_var_depths"
    # @info "out_block_depths $out_block_depths"
    return out_var_depths, out_block_depths
end

function export_solution_context(sc::SolutionContext, task)
    data = MetaGraph(
        DiGraph();  # underlying graph structure
        label_type = String,  # branch id
        vertex_data_type = Dict,
        edge_data_type = Dict,
        # graph_data = "solution context",  # tag for the whole graph
        # weight_function = ed -> ed["cost"],
        # default_weight = Inf,
    )
    vars_depths, blocks_depths = sort_vars_and_blocks(sc)
    for branch_id in 1:sc.branches_count[]
        entry = sc.entries[sc.branch_entries[branch_id]]
        vertex_dict = Dict(
            "_kind" => "branch",
            "_var_id" => sc.branch_vars[branch_id],
            "_is_unknown" => sc.branch_is_unknown[branch_id],
            "_is_explained" => sc.branch_is_explained[branch_id],
            "_is_not_copy" => sc.branch_is_not_copy[branch_id],
            "_is_not_const" => sc.branch_is_not_const[branch_id],
            "_type" => string(sc.types[entry.type_id]),
            "_entry_type" => typeof(entry),
            "_complexity" => sc.complexities[branch_id],
            "_unknown_complexity_factor" => sc.unknown_complexity_factors[branch_id],
            "_explained_complexity_factor" => sc.explained_complexity_factors[branch_id],
            "_unknown_min_path_cost" => sc.unknown_min_path_costs[branch_id],
            "_explained_min_path_cost" => sc.explained_min_path_costs[branch_id],
            "_unmatched_complexity" => sc.unmatched_complexities[branch_id],
            "_added_upstream_complexity" => sc.added_upstream_complexities[branch_id],
            "_unused_explained_complexity" => sc.unused_explained_complexities[branch_id],
            "_depth" => get(vars_depths, sc.branch_vars[branch_id], -200) + rand(),
            "_related_explained_branches" =>
                string(get_connected_from(sc.related_explained_complexity_branches, branch_id)),
            "_related_unknown_branches" =>
                string(get_connected_from(sc.related_unknown_complexity_branches, branch_id)),
        )
        if !isa(entry, NoDataEntry)
            vertex_dict["_entry_value"] = string(entry.values)
        end
        if haskey(sc.branch_queues_explained, branch_id)
            vertex_dict["_queue_explained_size"] = length(sc.branch_queues_explained[branch_id])
            if haskey(sc.pq_input, (branch_id, true))
                vertex_dict["_queue_explained_priority"] = sc.pq_input[(branch_id, true)]
            elseif haskey(sc.pq_output, (branch_id, true))
                vertex_dict["_queue_explained_priority"] = sc.pq_output[(branch_id, true)]
            end
            if branch_id == 1
                for (i, (bp, pr)) in enumerate(sc.branch_queues_explained[branch_id])
                    if i > 2000
                        break
                    end
                    @info "$pr $bp"
                end
            end
        end
        if haskey(sc.branch_queues_unknown, branch_id)
            vertex_dict["_queue_unknown_size"] = length(sc.branch_queues_unknown[branch_id])
            if haskey(sc.pq_input, (branch_id, false))
                vertex_dict["_queue_unknown_priority"] = sc.pq_input[(branch_id, false)]
            elseif haskey(sc.pq_output, (branch_id, false))
                vertex_dict["_queue_unknown_priority"] = sc.pq_output[(branch_id, false)]
            end
        end
        filter!(kv -> !isnothing(kv[2]), vertex_dict)
        add_vertex!(data, string(branch_id), vertex_dict)

        for parent_id in get_connected_to(sc.branch_children, branch_id)
            add_edge!(data, string(parent_id), string(branch_id), Dict("_type" => "child"))
        end
    end

    for block_copy_id in 1:sc.block_copies_count[]
        outs = get_connected_to(sc.branch_incoming_blocks, block_copy_id)
        if isempty(outs)
            @info "block $block_copy_id has no outputs"
            inputs = get_connected_to(sc.branch_outgoing_blocks, block_copy_id)
            @info inputs
            block_id = first(values(inputs))
            @info sc.blocks[block_id]
        end
        output_branches = keys(outs)
        block_id = first(values(outs))
        input_branches = keys(get_connected_to(sc.branch_outgoing_blocks, block_copy_id))
        block = sc.blocks[block_id]
        block_dict = Dict(
            "_kind" => "block",
            "_block_id" => block_id,
            "_block_copy_id" => block_copy_id,
            "_block_type" => typeof(block),
            "_p" => string(block.p),
            "_cost" => block.cost,
            "_depth" => get(blocks_depths, block_id, -200) + rand(),
        )

        if isa(block, ProgramBlock)
            block_dict["_is_reversible"] = block.is_reversible
            block_dict["_var_id"] = block.output_var
        else
            block_dict["_var_id"] = block.input_vars[1]
        end

        add_vertex!(data, "b$block_copy_id", block_dict)
        for input_branch in input_branches
            add_edge!(data, string(input_branch), "b$block_copy_id", Dict("_type" => "input"))
        end
        for output_branch in output_branches
            add_edge!(data, "b$block_copy_id", string(output_branch), Dict("_type" => "output"))
        end
    end

    # @info data
    filename = "solution_dumps/$(replace(task.name, " " => "_"))_$(now()).dot"
    # mkdir("solution_dumps")
    savegraph(filename, data, DOTFormat())
    @info filename
    # @info read(filename, String)
end

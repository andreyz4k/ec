
abstract type Turn end

struct LeftTurn <: Turn end
struct RightTurn <: Turn end
struct ArgTurn <: Turn
    type::Tp
end

Base.:(==)(a::ArgTurn, b::ArgTurn) = a.type == b.type

Base.hash(a::ArgTurn, h::UInt) = hash(a.type, h)

struct EnumerationState
    skeleton::Program
    context::Context
    path::Vector{Turn}
    cost::Float64
    free_parameters::Int64
end

Base.:(==)(a::EnumerationState, b::EnumerationState) =
    a.skeleton == b.skeleton &&
    a.context == b.context &&
    a.path == b.path &&
    a.cost == b.cost &&
    a.free_parameters == b.free_parameters

Base.hash(a::EnumerationState, h::UInt) =
    hash(a.skeleton, hash(a.context, hash(a.path, hash(a.cost, hash(a.free_parameters, h)))))

struct BlockPrototype
    state::EnumerationState
    request::Tp
    input_vars::Union{Dict{UInt64,UInt64},Nothing}
    output_var::Tuple{UInt64,UInt64}
    reverse::Bool
end

Base.:(==)(a::BlockPrototype, b::BlockPrototype) =
    a.state == b.state &&
    a.request == b.request &&
    a.input_vars == b.input_vars &&
    a.output_var == b.output_var &&
    a.reverse == b.reverse

Base.hash(a::BlockPrototype, h::UInt) =
    hash(a.state, hash(a.request, hash(a.input_vars, hash(a.output_var, hash(a.reverse, h)))))

EPSILON = 1e-3

function block_prototype(pr, inputs, output_var_id, output_branch_id, output_type)
    BlockPrototype(
        EnumerationState(pr, empty_context, [], EPSILON, 0),
        output_type,
        inputs,
        (output_var_id, output_branch_id),
        false,
    )
end

function get_candidates_for_unknown_var(sc, branch_id, g)::Vector{BlockPrototype}
    var_id = sc.branch_vars[branch_id]
    type_id = first(get_connected_from(sc.branch_types, branch_id))
    type = sc.types[type_id]
    entry = sc.entries[sc.branch_entries[branch_id]]
    prototypes = []
    if !isa(entry, NoDataEntry)
        context, type = instantiate(type, empty_context)
        push!(
            prototypes,
            BlockPrototype(
                EnumerationState(
                    Hole(type, g.no_context, CustomArgChecker(false, -1, true, nothing), entry.values),
                    context,
                    [],
                    EPSILON,
                    0,
                ),
                type,
                nothing,
                (var_id, branch_id),
                false,
            ),
        )
    end
    for (pr, inputs, out_type) in matching_with_unknown_candidates(sc, entry, var_id)
        push!(prototypes, block_prototype(pr, inputs, var_id, branch_id, out_type))
    end
    prototypes
end

function get_candidates_for_known_var(sc, branch_id, g)
    prototypes = []
    var_id = sc.branch_vars[branch_id]
    entry = sc.entries[sc.branch_entries[branch_id]]
    if !isnothing(sc.explained_min_path_costs[branch_id])
        # &&
        # !(isa(entry, PatternEntry) && all(v == PatternWrapper(any_object) for v in entry.values))
        type_id = first(get_connected_from(sc.branch_types, branch_id))
        type = sc.types[type_id]
        context, type = instantiate(type, empty_context)
        push!(
            prototypes,
            BlockPrototype(
                EnumerationState(
                    Hole(type, g.no_context, CustomArgChecker(true, -1, true, nothing), nothing),
                    context,
                    [],
                    EPSILON,
                    0,
                ),
                type,
                nothing,
                (var_id, branch_id),
                true,
            ),
        )
    end
    for (pr, output_var_id, output_br_id, out_type) in matching_with_known_candidates(sc, entry, branch_id)
        push!(prototypes, block_prototype(pr, Dict(var_id => branch_id), output_var_id, output_br_id, out_type))
    end
    prototypes
end

function enqueue_known_var(sc, branch_id, g)
    if branch_id == sc.target_branch_id
        return
    end
    prototypes = get_candidates_for_known_var(sc, branch_id, g)
    if haskey(sc.branch_queues_explained, branch_id)
        q = sc.branch_queues_explained[branch_id]
    else
        q = PriorityQueue{BlockPrototype,Float64}()
    end
    for bp in prototypes
        if sc.verbose
            @info "enqueueing $bp"
        end
        if (isnothing(bp.input_vars) || all(br -> sc.branch_is_explained[br[2]], bp.input_vars)) &&
           !isnothing(sc.explained_min_path_costs[branch_id])
            q[bp] = bp.state.cost
        else
            out_branch_id = bp.output_var[2]
            if !haskey(sc.branch_queues_unknown, out_branch_id)
                sc.branch_queues_unknown[out_branch_id] = PriorityQueue{BlockPrototype,Float64}()
            end
            out_q = sc.branch_queues_unknown[out_branch_id]
            out_q[bp] = bp.state.cost
            update_branch_priority(sc, out_branch_id, false)
        end
    end
    sc.branch_queues_explained[branch_id] = q
    if !isempty(q)
        update_branch_priority(sc, branch_id, true)
    end
end

function enqueue_unknown_var(sc, branch_id, g)
    prototypes = get_candidates_for_unknown_var(sc, branch_id, g)
    if haskey(sc.branch_queues_unknown, branch_id)
        q = sc.branch_queues_unknown[branch_id]
    else
        q = PriorityQueue{BlockPrototype,Float64}()
    end
    for bp in prototypes
        if sc.verbose
            @info "enqueueing $bp"
        end
        if !isnothing(bp.input_vars) &&
           !isempty(bp.input_vars) &&
           all(br -> sc.branch_is_explained[br[2]], bp.input_vars) &&
           !isnothing(sc.explained_min_path_costs[first(bp.input_vars)[2]])
            inp_branch_id = first(bp.input_vars)[2]
            if !haskey(sc.branch_queues_explained, inp_branch_id)
                sc.branch_queues_explained[inp_branch_id] = PriorityQueue{BlockPrototype,Float64}()
            end
            in_q = sc.branch_queues_explained[inp_branch_id]
            in_q[bp] = bp.state.cost
            update_branch_priority(sc, inp_branch_id, true)
        else
            q[bp] = bp.state.cost
        end
    end
    if !isempty(q)
        sc.branch_queues_unknown[branch_id] = q
        update_branch_priority(sc, branch_id, false)
    end
end

state_finished(state::EnumerationState) =
    if isa(state.skeleton, Hole)
        false
    else
        isempty(state.path)
    end

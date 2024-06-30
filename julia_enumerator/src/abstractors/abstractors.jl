
all_abstractors = Dict{Program,Tuple{Vector,Any}}()

abstract type ArgChecker end

struct CombinedArgChecker
    should_be_reversible::Union{Bool,Nothing}
    max_index::Union{Int64,Nothing}
    can_have_free_vars::Union{Bool,Nothing}
    inner_checkers::Vector
end

function CombinedArgChecker(checkers::Vector)
    should_be_reversible = nothing
    max_index = nothing
    can_have_free_vars = nothing
    for checker in checkers
        if !isnothing(checker.should_be_reversible)
            should_be_reversible = checker.should_be_reversible
        end
        if !isnothing(checker.max_index)
            if isnothing(max_index)
                max_index = checker.max_index
            else
                max_index = min(max_index, checker.max_index)
            end
        end
        if !isnothing(checker.can_have_free_vars)
            can_have_free_vars = checker.can_have_free_vars
        end
    end
    return CombinedArgChecker(should_be_reversible, max_index, can_have_free_vars, checkers)
end

Base.:(==)(c1::CombinedArgChecker, c2::CombinedArgChecker) =
    c1.should_be_reversible == c2.should_be_reversible &&
    c1.max_index == c2.max_index &&
    c1.can_have_free_vars == c2.can_have_free_vars &&
    c1.inner_checkers == c2.inner_checkers

Base.hash(c::CombinedArgChecker, h::UInt64) =
    hash(c.should_be_reversible, hash(c.max_index, hash(c.can_have_free_vars, hash(c.inner_checkers, h))))

function (c::CombinedArgChecker)(p::Index, skeleton, path)
    if !isnothing(c.max_index) && (p.n) > c.max_index
        return false
    end
    return all(checker(p, skeleton, path) for checker in c.inner_checkers)
end

function (c::CombinedArgChecker)(p::Union{Primitive,Invented}, skeleton, path)
    if c.should_be_reversible == true && !is_reversible(p)
        return false
    end
    return all(checker(p, skeleton, path) for checker in c.inner_checkers)
end

function (c::CombinedArgChecker)(p::SetConst, skeleton, path)
    return all(checker(p, skeleton, path) for checker in c.inner_checkers)
end

function (c::CombinedArgChecker)(p::FreeVar, skeleton, path)
    if c.can_have_free_vars == false
        return false
    end
    return all(checker(p, skeleton, path) for checker in c.inner_checkers)
end

function step_arg_checker(c::CombinedArgChecker, arg)
    new_checkers = [step_arg_checker(checker, arg) for checker in c.inner_checkers]
    filter!(c -> !isnothing(c), new_checkers)
    if isempty(new_checkers)
        return nothing
    end
    return CombinedArgChecker(new_checkers)
end

function combine_arg_checkers(old::CombinedArgChecker, new::ArgChecker)
    if new == old.inner_checkers[end]
        return old
    end
    should_be_reversible = if isnothing(new.should_be_reversible)
        old.should_be_reversible
    else
        new.should_be_reversible
    end
    max_index = if isnothing(new.max_index)
        old.max_index
    elseif isnothing(old.max_index)
        new.max_index
    else
        min(old.max_index, new.max_index)
    end
    can_have_free_vars = if isnothing(new.can_have_free_vars)
        old.can_have_free_vars
    else
        new.can_have_free_vars
    end
    new_checkers = vcat(old.inner_checkers, [new])
    return CombinedArgChecker(should_be_reversible, max_index, can_have_free_vars, new_checkers)
end

function combine_arg_checkers(old::CombinedArgChecker, new::CombinedArgChecker)
    for c in new.inner_checkers
        old = combine_arg_checkers(old, c)
    end
    return old
end

struct SimpleArgChecker <: ArgChecker
    should_be_reversible::Union{Bool,Nothing}
    max_index::Union{Int64,Nothing}
    can_have_free_vars::Union{Bool,Nothing}
end

Base.:(==)(c1::SimpleArgChecker, c2::SimpleArgChecker) =
    c1.should_be_reversible == c2.should_be_reversible &&
    c1.max_index == c2.max_index &&
    c1.can_have_free_vars == c2.can_have_free_vars

Base.hash(c::SimpleArgChecker, h::UInt64) =
    hash(c.should_be_reversible, hash(c.max_index, hash(c.can_have_free_vars, h)))

(c::SimpleArgChecker)(p, skeleton, path) = true

function step_arg_checker(c::SimpleArgChecker, arg::ArgTurn)
    return SimpleArgChecker(
        c.should_be_reversible,
        isnothing(c.max_index) ? c.max_index : c.max_index + 1,
        c.can_have_free_vars,
    )
end

function step_arg_checker(c::SimpleArgChecker, arg)
    return c
end

function _get_custom_arg_checkers(p::Primitive)
    if haskey(all_abstractors, p)
        [c[2] for c in all_abstractors[p][1]]
    else
        []
    end
end

_get_custom_arg_checkers(p::Index) = []
_get_custom_arg_checkers(p::FreeVar) = []

function _get_custom_arg_checkers(p::Invented)
    checkers, indices_checkers = __get_custom_arg_chekers(p, nothing, Dict())
    @assert isempty(indices_checkers)
    return checkers
end

function __get_custom_arg_chekers(p::Primitive, checker::Nothing, indices_checkers::Dict)
    if haskey(all_abstractors, p)
        [CombinedArgChecker([c[2]]) for c in all_abstractors[p][1]], indices_checkers
    else
        [], indices_checkers
    end
end

function __get_custom_arg_chekers(p::Primitive, checker, indices_checkers::Dict)
    arg_count = length(arguments_of_type(p.t))
    custom_checkers = _get_custom_arg_checkers(p)
    out_checkers = []
    for i in 1:arg_count
        current_checker = step_arg_checker(checker, (p, i))
        if i > length(custom_checkers)
            push!(out_checkers, current_checker)
        elseif isnothing(custom_checkers[i])
            push!(out_checkers, current_checker)
        elseif isnothing(current_checker)
            push!(out_checkers, custom_checkers[i])
        else
            combined = combine_arg_checkers(current_checker, custom_checkers[i])
            push!(out_checkers, combined)
        end
    end
    out_checkers, indices_checkers
end

function __get_custom_arg_chekers(p::SetConst, checker, indices_checkers::Dict)
    [], indices_checkers
end

function __get_custom_arg_chekers(p::Invented, checker, indices_checkers::Dict)
    return __get_custom_arg_chekers(p.b, checker, indices_checkers)
end

function __get_custom_arg_chekers(p::Apply, checker, indices_checkers::Dict)
    checkers, indices_checkers = __get_custom_arg_chekers(p.f, checker, indices_checkers)
    if !isempty(checkers)
        _, indices_checkers = __get_custom_arg_chekers(p.x, checkers[1], indices_checkers)
    else
        _, indices_checkers = __get_custom_arg_chekers(p.x, nothing, indices_checkers)
    end
    return checkers[2:end], indices_checkers
end

function __get_custom_arg_chekers(p::Index, checker::Nothing, indices_checkers::Dict)
    return [], indices_checkers
end

function __get_custom_arg_chekers(p::Index, checker, indices_checkers::Dict)
    current_checker = step_arg_checker(checker, p)
    if !isnothing(current_checker)
        if haskey(indices_checkers, p.n)
            combined = combine_arg_checkers(current_checker, indices_checkers[p.n])
            indices_checkers[p.n] = combined
        else
            indices_checkers[p.n] = current_checker
        end
    end
    return [], indices_checkers
end

function __get_custom_arg_chekers(p::Abstraction, checker, indices_checkers::Dict)
    chekers, indices_checkers = __get_custom_arg_chekers(
        p.b,
        isnothing(checker) ? checker : step_arg_checker(checker, ArgTurn(t0)),
        Dict(i + 1 => c for (i, c) in indices_checkers),
    )
    if haskey(indices_checkers, 0)
        out_checkers = vcat([indices_checkers[0]], chekers)
    elseif !isempty(chekers)
        out_checkers = vcat([nothing], chekers)
    else
        out_checkers = []
    end
    return out_checkers, Dict(i - 1 => c for (i, c) in indices_checkers if i > 0)
end

_fill_args(p::Program, environment) = p
_fill_args(p::Invented, environment) = _fill_args(p.b, environment)
_fill_args(p::Apply, environment) = Apply(_fill_args(p.f, environment), _fill_args(p.x, environment))
_fill_args(p::Abstraction, environment) = Abstraction(_fill_args(p.b, Dict(i + 1 => c for (i, c) in environment)))

function _fill_args(p::Index, environment)
    if haskey(environment, p.n)
        return environment[p.n]
    else
        return p
    end
end

function _is_reversible(p::Primitive, environment, args)
    if haskey(all_abstractors, p)
        [c[1] for c in all_abstractors[p][1]]
    else
        nothing
    end
end

function _is_reversible(p::Apply, environment, args)
    filled_x = _fill_args(p.x, environment)
    checkers = _is_reversible(p.f, environment, vcat(args, [filled_x]))
    if isnothing(checkers)
        return nothing
    end
    if isempty(checkers)
        if isa(filled_x, Hole)
            if !isarrow(filled_x.t)
                return checkers
            else
                return nothing
            end
        end
        if isa(filled_x, Index) || isa(filled_x, FreeVar)
            return checkers
        end
        checker = is_reversible
    else
        checker = checkers[1]
        if isnothing(checker)
            checker = is_reversible
        end
    end
    if !checker(filled_x)
        return nothing
    else
        return view(checkers, 2:length(checkers))
    end
end

_is_reversible(p::Invented, environment, args) = _is_reversible(p.b, environment, args)

function _is_reversible(p::Abstraction, environment, args)
    environment = Dict{Int64,Any}(i + 1 => c for (i, c) in environment)
    if !isempty(args)
        environment[0] = args[end]
    end
    return _is_reversible(p.b, environment, view(args, 1:length(args)-1))
end

_is_reversible(p::SetConst, environment, args) = []

function _is_reversible(p::Index, environment, args)
    filled_p = _fill_args(p, environment)
    if isa(filled_p, Index)
        return []
    else
        return _is_reversible(filled_p, Dict(), [])
    end
end

_is_reversible(p::Program, environment, args) = nothing

function is_reversible(p::Program)::Bool
    try
        !isnothing(_is_reversible(p, Dict(), []))
    catch
        @warn "Error while checking reversibility for $p"
        rethrow()
    end
end

struct SkipArg end

struct ValueContainer
    value::Any
    value_paths::Dict{Any,Vector{Vector{UInt64}}}
end

function ValueContainer(value)
    paths = Dict()
    for (v, path) in all_path_options(value)
        if !haskey(paths, v)
            paths[v] = []
        end
        push!(paths[v], path)
    end
    return ValueContainer(value, paths)
end

function ValueContainer(value::ValueContainer)
    @assert false
end

Base.:(==)(v1::ValueContainer, v2::ValueContainer) = v1.value == v2.value

function drop_remap_option_paths(value::ValueContainer, drop_paths, retain_paths, paths_remappings)
    return ValueContainer(drop_remap_option_paths(value.value, drop_paths, retain_paths, paths_remappings))
end

mutable struct ReverseRunContext
    upstream_outputs::Vector{ValueContainer}
    arguments::Vector{Any}
    predicted_arguments::Vector{ValueContainer}
    calculated_arguments::Vector{Any}
    filled_indices::Dict{Int64,ValueContainer}
    filled_vars::Dict{UInt64,ValueContainer}
end

ReverseRunContext() = ReverseRunContext([], [], [], [], Dict(), Dict())

function filter_context_values(ctx::ReverseRunContext, failed_paths, retain_paths, paths_remappings)
    if isempty(failed_paths) && isempty(paths_remappings)
        return ctx
    end
    # @info "Filtering context $ctx"
    # @info "Failed paths $failed_paths"
    # @info "Retain paths $retain_paths"
    # @info "Paths remappings $paths_remappings"
    filtered_predicted_arguments =
        [drop_remap_option_paths(v, failed_paths, retain_paths, paths_remappings) for v in ctx.predicted_arguments]
    filtered_upstream_outputs =
        [drop_remap_option_paths(v, failed_paths, retain_paths, paths_remappings) for v in ctx.upstream_outputs]
    filtered_indices = Dict(
        i => drop_remap_option_paths(val, failed_paths, retain_paths, paths_remappings) for
        (i, val) in ctx.filled_indices
    )
    filtered_vars = Dict(
        k => drop_remap_option_paths(val, failed_paths, retain_paths, paths_remappings) for (k, val) in ctx.filled_vars
    )

    res = ReverseRunContext(
        filtered_upstream_outputs,
        ctx.arguments,
        filtered_predicted_arguments,
        ctx.calculated_arguments,
        filtered_indices,
        filtered_vars,
    )
    # @info "Filtered context $res"
    return res
end

_try_unify_values(v1, v2::AnyObject, check_pattern) = true, v1
_try_unify_values(v1::AnyObject, v2, check_pattern) = true, v2
_try_unify_values(v1::AnyObject, v2::AnyObject, check_pattern) = true, v2

function _try_unify_values(v1::PatternWrapper, v2, check_pattern)
    found, res = _try_unify_values(v1.value, v2, true)
    if !found
        return found, res
    end
    return found, _wrap_wildcard(res)
end

function _try_unify_values(v1, v2::PatternWrapper, check_pattern)
    found, res = _try_unify_values(v1, v2.value, true)
    if !found
        return found, res
    end
    return found, _wrap_wildcard(res)
end

function _try_unify_values(v1::PatternWrapper, v2::PatternWrapper, check_pattern)
    found, res = _try_unify_values(v1.value, v2.value, true)
    if !found
        return found, res
    end
    return found, _wrap_wildcard(res)
end

_try_unify_values(v1::PatternWrapper, v2::AnyObject, check_pattern) = true, v1
_try_unify_values(v1::AnyObject, v2::PatternWrapper, check_pattern) = true, v2

function _try_unify_values(v1::AbductibleValue, v2, check_pattern)
    found, res = _try_unify_values(v1.value, v2, true)
    if !found
        return found, res
    end
    found, _wrap_abductible(res)
end

function _try_unify_values(v1, v2::AbductibleValue, check_pattern)
    found, res = _try_unify_values(v1, v2.value, true)
    if !found
        return found, res
    end
    found, _wrap_abductible(res)
end

function _try_unify_values(v1::AbductibleValue, v2::AbductibleValue, check_pattern)
    found, res = _try_unify_values(v1.value, v2.value, true)
    if !found
        return found, res
    end
    found, _wrap_abductible(res)
end

_try_unify_values(v1::AbductibleValue, v2::AnyObject, check_pattern) = true, v1
_try_unify_values(v1::AnyObject, v2::AbductibleValue, check_pattern) = true, v2

function _try_unify_values(v1::AbductibleValue, v2::PatternWrapper, check_pattern)
    found, res = _try_unify_values(v1.value, v2.value, true)
    if !found
        return found, res
    end
    found, _wrap_abductible(res)
end

function _try_unify_values(v1::PatternWrapper, v2::AbductibleValue, check_pattern)
    found, res = _try_unify_values(v1.value, v2.value, true)
    if !found
        return found, res
    end
    found, _wrap_abductible(res)
end

function _try_unify_values(v1::EitherOptions, v2::PatternWrapper, check_pattern)
    @invoke _try_unify_values(v1::EitherOptions, v2::Any, check_pattern)
end

function _try_unify_values(v1::EitherOptions, v2::AbductibleValue, check_pattern)
    @invoke _try_unify_values(v1::EitherOptions, v2::Any, check_pattern)
end

function _try_unify_values(v1::EitherOptions, v2, check_pattern)
    options = Dict()
    for (h, v) in v1.options
        found, unified_v = _try_unify_values(v, v2, check_pattern)
        if found
            options[h] = unified_v
        end
    end
    if isempty(options)
        return false, nothing
    end
    return true, EitherOptions(options)
end

function _try_unify_values(v1::PatternWrapper, v2::EitherOptions, check_pattern)
    @invoke _try_unify_values(v1::Any, v2::EitherOptions, check_pattern)
end

function _try_unify_values(v1::AbductibleValue, v2::EitherOptions, check_pattern)
    @invoke _try_unify_values(v1::Any, v2::EitherOptions, check_pattern)
end

function _try_unify_values(v1, v2::EitherOptions, check_pattern)
    options = Dict()
    for (h, v) in v2.options
        found, unified_v = _try_unify_values(v1, v, check_pattern)
        if found
            options[h] = unified_v
        end
    end
    if isempty(options)
        return false, nothing
    end
    return true, EitherOptions(options)
end

function _try_unify_values(v1::EitherOptions, v2::EitherOptions, check_pattern)
    options = Dict()
    for (h, v) in v1.options
        if haskey(v2.options, h)
            found, unified_v = _try_unify_values(v, v2.options[h], check_pattern)
            if found
                options[h] = unified_v
            else
                return false, nothing
            end
        end
    end
    if isempty(options)
        return false, nothing
    end
    return true, EitherOptions(options)
end

function _try_unify_values(v1, v2, check_pattern)
    if v1 == v2
        return true, v1
    end
    return false, nothing
end

function _try_unify_values(v1::Array, v2::Array, check_pattern)
    if length(v1) != length(v2)
        return false, nothing
    end
    if v1 == v2
        return true, v1
    end
    if !check_pattern
        return false, nothing
    end
    res = []
    for i in 1:length(v1)
        found, unified_v = _try_unify_values(v1[i], v2[i], check_pattern)
        if !found
            return false, nothing
        end
        push!(res, unified_v)
    end
    return true, res
end

function _try_unify_values(v1::Tuple, v2::Tuple, check_pattern)
    if length(v1) != length(v2)
        return false, nothing
    end
    if v1 == v2
        return true, v1
    end
    if !check_pattern
        return false, nothing
    end
    res = []
    for i in 1:length(v1)
        found, unified_v = _try_unify_values(v1[i], v2[i], check_pattern)
        if !found
            return false, nothing
        end
        push!(res, unified_v)
    end
    return true, Tuple(res)
end

function _try_unify_values(v1::Set, v2::Set, check_pattern)
    if length(v1) != length(v2)
        return false, nothing
    end
    if v1 == v2
        return true, v1
    end
    if !check_pattern
        return false, nothing
    end
    options = []
    f_v = first(v1)
    if in(f_v, v2)
        found, rest = _try_unify_values(v1 - Set([f_v]), v2 - Set([f_v]), check_pattern)
        if !found
            return false, nothing
        end
        if isa(rest, EitherOptions)
            for (h, v) in rest.options
                push!(options, union(Set([f_v]), v))
            end
        else
            push!(rest, f_v)
            return true, rest
        end
    else
        for v in v2
            found, unified_v = _try_unify_values(f_v, v, check_pattern)
            if !found
                continue
            end
            found, rest = _try_unify_values(v1 - Set([f_v]), v2 - Set([v]), check_pattern)
            if !found
                continue
            end
            if isa(rest, EitherOptions)
                for (h, val) in rest.options
                    push!(options, union(Set([unified_v]), val))
                end
            else
                push!(options, union(Set([unified_v]), rest))
            end
        end
    end
    if isempty(options)
        return false, nothing
    elseif length(options) == 1
        return true, options[1]
    else
        return true, EitherOptions(Dict(rand(UInt64) => option for option in options))
    end
end

function _unify_values(value1::ValueContainer, value2::ValueContainer)
    failed_paths = Set()
    failed_pairs = Set()
    retain_paths = Set()
    results = []
    unify_results = Dict()

    @info "Unifying values $value1 and $value2"

    for (v1, v1_paths) in value1.value_paths
        for v1_path in v1_paths
            _, v2_root, common_path = _follow_path(value2.value, v1_path, 1)

            path_results = []
            for (v2, v2_path) in all_path_options(v2_root)
                v2_full_path = vcat(common_path, v2_path)
                if haskey(unify_results, (v1, v2))
                    unified_v = unify_results[(v1, v2)]
                    push!(path_results, (unified_v, v2_path))
                    push!(retain_paths, v2_full_path)
                    continue
                end
                if in((v1, v2), failed_pairs)
                    push!(failed_paths, v2_full_path)
                    continue
                end
                found, unified_v = _try_unify_values(v1, v2, false)
                if !found
                    push!(failed_pairs, (v1, v2))
                    push!(failed_paths, v2_full_path)
                    continue
                end
                unify_results[(v1, v2)] = unified_v
                push!(path_results, (unified_v, v2_path))
                push!(retain_paths, v2_full_path)
            end
            if isempty(path_results)
                push!(failed_paths, v1_path)
            else
                push!(retain_paths, v1_path)
                push!(results, (v1_path, common_path, path_results))
            end
        end
    end

    # @info results
    results_tree = Dict()
    is_simple_value = false
    results_paths = []
    paths_remappings = Dict()
    for (v1_path, common_path, path_results) in results
        for (unified_v, v2_path) in path_results
            if isempty(v1_path) && isempty(v2_path)
                results_tree = unified_v
                is_simple_value = true
                break
            end
            current_tree = results_tree
            full_path = vcat(v1_path, v2_path)
            for i in 1:length(full_path)-1
                if !haskey(current_tree, full_path[i])
                    current_tree[full_path[i]] = Dict()
                end
                current_tree = current_tree[full_path[i]]
            end
            current_tree[full_path[end]] = unified_v
            push!(results_paths, full_path)
            if length(v2_path) > 0 && length(v1_path) > length(common_path)
                if !haskey(paths_remappings, common_path)
                    paths_remappings[common_path] = []
                end
                push!(paths_remappings[common_path], (v2_path, v1_path[length(common_path)+1:end]))
            end
        end
        if is_simple_value
            break
        end
    end
    if is_simple_value
        result = ValueContainer(results_tree)
    else
        result = ValueContainer(_build_eithers(results_tree, [], results_paths))
    end
    @info result
    @info "Remappings $paths_remappings"

    for path in retain_paths
        for i in 1:length(path)-1
            push!(retain_paths, path[1:i])
        end
    end
    for path in failed_paths
        if in(path, retain_paths)
            delete!(failed_paths, path)
            continue
        end
        for i in 1:length(path)
            if !in(path[1:end-i], retain_paths)
                push!(failed_paths, path[1:i])
            else
                break
            end
        end
    end
    # @info "Failed $failed_paths"
    # @info "Retain $retain_paths"

    return result, failed_paths, retain_paths, paths_remappings
end

function _preprocess_options(args_options, output)
    if any(isa(out, AbductibleValue) for out in values(args_options))
        abd = first(out for out in values(args_options) if isa(out, AbductibleValue))
        for (h, val) in args_options
            if !isa(val, AbductibleValue) && abd.value == val
                args_options[h] = abd
            end
        end
    end
    return EitherOptions(args_options)
end

abstract type ProgramInfo end

struct PrimitiveInfo <: ProgramInfo
    p::Primitive
    indices::Vector{Int64}
    var_ids::Vector{UInt64}
end

gather_info(p::Primitive) = PrimitiveInfo(p, [], [])

gather_info(p::Invented) = gather_info(p.b)

struct ApplyInfo <: ProgramInfo
    p::Apply
    f_info::ProgramInfo
    x_info::ProgramInfo
    indices::Vector{Int64}
    var_ids::Vector{UInt64}
end

function gather_info(p::Apply)
    f_info = gather_info(p.f)
    x_info = gather_info(p.x)
    indices = vcat(f_info.indices, x_info.indices)
    var_ids = vcat(f_info.var_ids, x_info.var_ids)
    return ApplyInfo(p, f_info, x_info, indices, var_ids)
end

struct AbstractionInfo <: ProgramInfo
    p::Abstraction
    b_info::ProgramInfo
    indices::Vector{Int64}
    var_ids::Vector{UInt64}
end

function gather_info(p::Abstraction)
    b_info = gather_info(p.b)
    return AbstractionInfo(p, b_info, [i - 1 for i in b_info.indices if i > 0], b_info.var_ids)
end

struct SetConstInfo <: ProgramInfo
    p::SetConst
    indices::Vector{Int64}
    var_ids::Vector{UInt64}
end

gather_info(p::SetConst) = SetConstInfo(p, [], [])

struct IndexInfo <: ProgramInfo
    p::Index
    indices::Vector{Int64}
    var_ids::Vector{UInt64}
end

gather_info(p::Index) = IndexInfo(p, [p.n], [])

struct FreeVarInfo <: ProgramInfo
    p::FreeVar
    indices::Vector{Int64}
    var_ids::Vector{UInt64}
end

gather_info(p::FreeVar) = FreeVarInfo(p, [], [p.var_id])

function _run_in_reverse(p_info, output, context, splitter::EitherOptions)
    # @info "Running in reverse $p $output $context"
    output_options = Dict()
    arguments_options = Dict[]
    arguments_options_counts = Int[]
    filled_indices_options = DefaultDict(() -> Dict())
    filled_indices_options_counts = DefaultDict(() -> 0)
    filled_vars_options = DefaultDict(() -> Dict())
    filled_vars_options_counts = DefaultDict(() -> 0)
    for (h, _) in splitter.options
        fixed_hashes = Set([h])
        op_calculated_arguments = [fix_option_hashes(fixed_hashes, v) for v in context.calculated_arguments]
        op_predicted_arguments = [fix_option_hashes(fixed_hashes, v) for v in context.predicted_arguments]
        op_filled_indices = Dict(i => fix_option_hashes(fixed_hashes, v) for (i, v) in context.filled_indices)
        op_filled_vars = Dict(k => fix_option_hashes(fixed_hashes, v) for (k, v) in context.filled_vars)

        try
            calculated_output, new_context = _run_in_reverse(
                p_info,
                fix_option_hashes(fixed_hashes, output),
                ReverseRunContext(
                    context.arguments,
                    op_predicted_arguments,
                    op_calculated_arguments,
                    op_filled_indices,
                    op_filled_vars,
                ),
            )

            if isempty(arguments_options)
                for _ in 1:(length(new_context.predicted_arguments))
                    push!(arguments_options, Dict())
                    push!(arguments_options_counts, 0)
                end
            end
            output_options[h] = calculated_output

            for i in 1:length(new_context.predicted_arguments)
                arguments_options[i][h] = new_context.predicted_arguments[i]
                arguments_options_counts[i] += get_options_count(new_context.predicted_arguments[i])
                if arguments_options_counts[i] > 100
                    throw(TooManyOptionsException())
                end
            end
            for (i, v) in new_context.filled_indices
                filled_indices_options[i][h] = v
                filled_indices_options_counts[i] += get_options_count(v)
                if filled_indices_options_counts[i] > 100
                    throw(TooManyOptionsException())
                end
            end
            for (k, v) in new_context.filled_vars
                filled_vars_options[k][h] = v
                filled_vars_options_counts[k] += get_options_count(v)
                if filled_vars_options_counts[k] > 100
                    throw(TooManyOptionsException())
                end
            end
        catch e
            if isa(e, InterruptException) || isa(e, MethodError)
                rethrow()
            end
            # bt = catch_backtrace()
            # @error "Got error" exception = (e, bt)
        end
    end

    out_args = []
    out_filled_indices = Dict()
    out_filled_vars = Dict()

    # @info arguments_options
    for args_options in arguments_options
        push!(out_args, _preprocess_options(args_options, output))
    end
    for (i, v) in filled_indices_options
        out_filled_indices[i] = _preprocess_options(v, output)
    end
    for (k, v) in filled_vars_options
        out_filled_vars[k] = _preprocess_options(v, output)
    end
    out_context = ReverseRunContext(
        context.arguments,
        out_args,
        context.calculated_arguments,
        out_filled_indices,
        out_filled_vars,
    )
    # @info "Output options $output_options"
    # @info "Output context $out_context"
    return EitherOptions(output_options), out_context
end

function _run_in_reverse(p_info, output::EitherOptions, context)
    return _run_in_reverse(p_info, output, context, output)
end

function _run_in_reverse(p_info, output, context)
    for (i, v) in context.filled_indices
        if isa(v, EitherOptions)
            return _run_in_reverse(p_info, output, context, v)
        end
    end
    for (k, v) in context.filled_vars
        if isa(v, EitherOptions)
            return _run_in_reverse(p_info, output, context, v)
        end
    end
    return __run_in_reverse(p_info, output, context)
end

function __run_in_reverse(p_info::PrimitiveInfo, output, context)
    # @info "Running in reverse $p $output $context"
    return all_abstractors[p_info.p][2](output, context)
end

function __run_in_reverse(p_info::PrimitiveInfo, output::AbductibleValue, context)
    # @info "Running in reverse $p $output $context"
    try
        calculated_output, new_context = all_abstractors[p_info.p][2](output, context)
        new_context.predicted_arguments = [_wrap_abductible(arg) for arg in new_context.predicted_arguments]
        return _wrap_abductible(calculated_output), new_context
    catch e
        # bt = catch_backtrace()
        # @error e exception = (e, bt)
        if isa(e, MethodError) && any(isa(arg, AbductibleValue) for arg in e.args)
            results = []
            for i in length(arguments_of_type(p_info.p.t))-1:-1:0
                if ismissing(context.calculated_arguments[end-i])
                    push!(results, AbductibleValue(any_object))
                else
                    push!(results, context.calculated_arguments[end-i])
                end
            end
            return output,
            ReverseRunContext(
                context.arguments,
                vcat(context.predicted_arguments, results),
                context.calculated_arguments,
                context.filled_indices,
                context.filled_vars,
            )
        end
        rethrow()
    end
end

function __run_in_reverse(p_info::PrimitiveInfo, output::PatternWrapper, context)
    # @info "Running in reverse $p $output $context"
    calculated_output, new_context = __run_in_reverse(p_info, output.value, context)

    new_context.predicted_arguments = [_wrap_wildcard(arg) for arg in new_context.predicted_arguments]

    return _wrap_wildcard(calculated_output), new_context
end

function __run_in_reverse(p_info::PrimitiveInfo, output::Union{Nothing,AnyObject}, context)
    # @info "Running in reverse $p $output $context"
    try
        return all_abstractors[p_info.p][2](output, context)
    catch e
        # @info e
        # bt = catch_backtrace()
        # @error e exception = (e, bt)
        if isa(e, MethodError)
            return output,
            ReverseRunContext(
                context.arguments,
                vcat(context.predicted_arguments, [output for _ in 1:length(arguments_of_type(p_info.p.t))]),
                context.calculated_arguments,
                context.filled_indices,
                context.filled_vars,
            )
        else
            rethrow()
        end
    end
end

function __run_in_reverse(p_info::ApplyInfo, output::AbductibleValue, context)
    # @info "Running in reverse $p $output $context"
    env = Any[nothing for _ in 1:maximum(keys(context.filled_indices); init = -1)+1]
    for (i, v) in context.filled_indices
        env[end-i] = v
    end
    try
        calculated_output = p_info.p(env, context.filled_vars)
        # @info calculated_output
        if calculated_output isa Function
            error("Function output")
        end
        return calculated_output, context
    catch e
        if e isa InterruptException
            rethrow()
        end
        return @invoke __run_in_reverse(p_info::ApplyInfo, output::Any, context)
    end
end

function _precalculate_arg(p_info, context)
    for i in p_info.indices
        if !haskey(context.filled_indices, i)
            return missing
        end
    end
    for i in p_info.var_ids
        if !haskey(context.filled_vars, i)
            return missing
        end
    end
    env = Any[missing for _ in 1:maximum(keys(context.filled_indices); init = -1)+1]
    for (i, v) in context.filled_indices
        env[end-i] = v.value
    end
    try
        # @info "Precalculating $p with $env and $(context.filled_vars)"
        calculated_output = p_info.p(env, Dict(k => v.value for (k, v) in context.filled_vars))
        # @info calculated_output
        if isa(calculated_output, Function) ||
           isa(calculated_output, AbductibleValue) ||
           isa(calculated_output, PatternWrapper)
            return missing
        end
        return ValueContainer(calculated_output)
    catch e
        if e isa InterruptException
            rethrow()
        end
        return missing
    end
end

function __run_in_reverse(p_info::ApplyInfo, output, context)
    # @info "Running in reverse $p $output $context"
    precalculated_arg = _precalculate_arg(p_info.x_info, context)
    # @info "Precalculated arg for $(p.x) is $precalculated_arg"
    calculated_output, arg_context = _run_in_reverse(
        p_info.f_info,
        output,
        ReverseRunContext(
            vcat(context.arguments, [p_info.x_info]),
            context.predicted_arguments,
            vcat(context.calculated_arguments, [precalculated_arg]),
            context.filled_indices,
            context.filled_vars,
        ),
    )
    # @info "Arg context for $p $arg_context"
    pop!(arg_context.arguments)
    pop!(arg_context.calculated_arguments)
    arg_target = pop!(arg_context.predicted_arguments)
    if arg_target isa SkipArg
        return calculated_output, arg_context
    end
    arg_calculated_output, out_context = _run_in_reverse(p_info.x_info, arg_target, arg_context)

    # @info "arg_target $arg_target"
    # @info "arg_calculated_output $arg_calculated_output"
    if arg_calculated_output != arg_target
        # if arg_target isa AbductibleValue && arg_calculated_output != arg_target
        calculated_output, arg_context = _run_in_reverse(
            p_info.f_info,
            calculated_output,
            ReverseRunContext(
                vcat(context.arguments, [p_info.x_info]),
                context.predicted_arguments,
                vcat(context.calculated_arguments, [arg_calculated_output]),
                out_context.filled_indices,
                out_context.filled_vars,
            ),
        )
        pop!(arg_context.arguments)
        pop!(arg_context.calculated_arguments)
        arg_target = pop!(arg_context.predicted_arguments)
        if arg_target isa SkipArg
            return calculated_output, arg_context
        end
        arg_calculated_output, out_context = _run_in_reverse(p_info.x_info, arg_target, arg_context)
        # @info "arg_target2 $arg_target"
        # @info "arg_calculated_output2 $arg_calculated_output"
    end
    # @info "Calculated output for $p $calculated_output"
    # @info "Out context for $p $out_context"
    return calculated_output, out_context
end

function __run_in_reverse(p_info::FreeVarInfo, output, context)
    # @info "Running in reverse $p $output $context"
    if haskey(context.filled_vars, p_info.p.var_id)
        context.filled_vars[p_info.p.var_id] = _unify_values(context.filled_vars[p_info.p.var_id], output, false)
    else
        context.filled_vars[p_info.p.var_id] = output
    end
    # @info context
    return context.filled_vars[p_info.p.var_id], context
end

function __run_in_reverse(p_info::IndexInfo, output, context)
    # @info "Running in reverse $p $output $context"
    if haskey(context.filled_indices, p_info.p.n)
        context.filled_indices[p_info.p.n] = _unify_values(context.filled_indices[p_info.p.n], output, false)
    else
        context.filled_indices[p_info.p.n] = output
    end
    # @info context
    return context.filled_indices[p_info.p.n], context
end

function __run_in_reverse(p_info::AbstractionInfo, output, context::ReverseRunContext)
    in_filled_indices = Dict{Int64,Any}(i + 1 => v for (i, v) in context.filled_indices)
    if !ismissing(context.calculated_arguments[end])
        in_filled_indices[0] = context.calculated_arguments[end]
    end
    calculated_output, out_context = _run_in_reverse(
        p_info.b_info,
        output,
        ReverseRunContext(
            context.arguments[1:end-1],
            context.predicted_arguments,
            context.calculated_arguments[1:end-1],
            in_filled_indices,
            context.filled_vars,
        ),
    )
    push!(out_context.predicted_arguments, out_context.filled_indices[0])
    push!(out_context.calculated_arguments, calculated_output)
    if !isempty(context.arguments)
        push!(out_context.arguments, context.arguments[end])
    end

    out_context.filled_indices = Dict{Int64,Any}(i - 1 => v for (i, v) in out_context.filled_indices if i > 0)
    return output, out_context
end

function __run_in_reverse(p_info::SetConstInfo, output, context)
    if output != p_info.p.value
        error("Const mismatch $output != $(p_info.p.value)")
    end
    return output, context
end

function _run_in_reverse2(p_info::PrimitiveInfo, output, context)
    # @info "Running in reverse $p $output $context"
    return all_abstractors[p_info.p][2](output, context)
end

function _run_in_reverse2(p_info::ApplyInfo, output, context)
    # @info "Running in reverse $p $output $context"
    precalculated_arg = _precalculate_arg(p_info.x_info, context)
    # @info "Precalculated arg for $(p.x) is $precalculated_arg"
    _, arg_context = _run_in_reverse2(
        p_info.f_info,
        output,
        ReverseRunContext(
            vcat(context.upstream_outputs, [output]),
            vcat(context.arguments, [p_info.x_info]),
            context.predicted_arguments,
            vcat(context.calculated_arguments, [precalculated_arg]),
            context.filled_indices,
            context.filled_vars,
        ),
    )
    # @info "Arg context for $p $arg_context"
    pop!(arg_context.arguments)
    pop!(arg_context.calculated_arguments)
    arg_target = pop!(arg_context.predicted_arguments)
    if arg_target.value isa SkipArg
        calculated_output = pop!(arg_context.upstream_outputs)
        return calculated_output, arg_context
    end
    arg_calculated_output, out_context = _run_in_reverse2(p_info.x_info, arg_target, arg_context)
    calculated_output = pop!(out_context.upstream_outputs)

    if arg_calculated_output != arg_target
        # @info "Running in reverse $(p_info.p) $(p_info.x_info.p)  $arg_context"
        # @info "arg_target $arg_target"
        # @info "arg_calculated_output $arg_calculated_output"
        #     # if arg_target isa AbductibleValue && arg_calculated_output != arg_target
        #     calculated_output, arg_context = _run_in_reverse2(
        #         p_info.f_info,
        #         calculated_output,
        #         ReverseRunContext(
        #             vcat(context.arguments, [p_info.x_info]),
        #             context.predicted_arguments,
        #             vcat(context.calculated_arguments, [arg_calculated_output]),
        #             out_context.filled_indices,
        #             out_context.filled_vars,
        #         ),
        #     )
        #     pop!(arg_context.arguments)
        #     pop!(arg_context.calculated_arguments)
        #     arg_target = pop!(arg_context.predicted_arguments)
        #     if arg_target isa SkipArg
        #         return calculated_output, arg_context
        #     end
        #     arg_calculated_output, out_context = _run_in_reverse2(p_info.x_info, arg_target, arg_context)
        #     # @info "arg_target2 $arg_target"
        #     # @info "arg_calculated_output2 $arg_calculated_output"
    end
    # @info "Calculated output for $p $calculated_output"
    # @info "Out context for $p $out_context"
    return calculated_output, out_context
end

function _run_in_reverse2(p_info::FreeVarInfo, output, context)
    # @info "Running in reverse $(p_info.p) $output $context"
    if haskey(context.filled_vars, p_info.p.var_id)
        unified_v, failed_paths, retain_paths, paths_remappings =
            _unify_values(context.filled_vars[p_info.p.var_id], output)
        context.filled_vars[p_info.p.var_id] = unified_v
        context = filter_context_values(context, failed_paths, retain_paths, paths_remappings)
    else
        context.filled_vars[p_info.p.var_id] = output
    end
    # @info context
    return context.filled_vars[p_info.p.var_id], context
end

function _run_in_reverse2(p_info::IndexInfo, output, context)
    # @info "Running in reverse $p $output $context"
    if haskey(context.filled_indices, p_info.p.n)
        # @info "Trying to unify"
        # @info context.filled_indices[p_info.p.n]
        # @info output
        unified_v, failed_paths, retain_paths, paths_remappings =
            _unify_values(context.filled_indices[p_info.p.n], output)
        context.filled_indices[p_info.p.n] = unified_v

        context = filter_context_values(context, failed_paths, retain_paths, paths_remappings)
    else
        context.filled_indices[p_info.p.n] = output
    end
    # @info context
    return context.filled_indices[p_info.p.n], context
end

function _run_in_reverse2(p_info::AbstractionInfo, output, context::ReverseRunContext)
    in_filled_indices = Dict{Int64,Any}(i + 1 => v for (i, v) in context.filled_indices)
    if !ismissing(context.calculated_arguments[end])
        in_filled_indices[0] = context.calculated_arguments[end]
    end
    calculated_output, out_context = _run_in_reverse2(
        p_info.b_info,
        output,
        ReverseRunContext(
            context.upstream_outputs,
            context.arguments[1:end-1],
            context.predicted_arguments,
            context.calculated_arguments[1:end-1],
            in_filled_indices,
            context.filled_vars,
        ),
    )
    push!(out_context.predicted_arguments, out_context.filled_indices[0])
    push!(out_context.calculated_arguments, calculated_output)
    if !isempty(context.arguments)
        push!(out_context.arguments, context.arguments[end])
    end

    out_context.filled_indices = Dict{Int64,Any}(i - 1 => v for (i, v) in out_context.filled_indices if i > 0)
    return output, out_context
end

function _run_in_reverse2(p_info::SetConstInfo, output, context)
    if output.value != p_info.p.value
        error("Const mismatch $output != $(p_info.p.value)")
    end
    return output, context
end

function run_in_reverse(p::Program, output)
    # @info p
    # start_time = time()
    p_info = gather_info(p)
    output_container = ValueContainer(output)
    computed_output, context = _run_in_reverse2(p_info, output_container, ReverseRunContext())
    # elapsed = time() - start_time
    # if elapsed > 2
    #     @info "Reverse run took $elapsed seconds"
    #     @info p
    #     @info output
    # end
    if computed_output.value != output && !isempty(context.filled_vars)
        error("Output mismatch $computed_output != $output")
    end
    return Dict(k => cleanup_options(c.value) for (k, c) in context.filled_vars)
end

_has_wildcard(v::PatternWrapper) = true
_has_wildcard(v) = false
_has_wildcard(v::AnyObject) = true
_has_wildcard(v::Array) = any(_has_wildcard, v)
_has_wildcard(v::Tuple) = any(_has_wildcard, v)
_has_wildcard(v::Set) = any(_has_wildcard, v)

_wrap_wildcard(p::PatternWrapper) = p

function _wrap_wildcard(v)
    if _has_wildcard(v)
        return PatternWrapper(v)
    else
        return v
    end
end

function _wrap_wildcard(v::EitherOptions)
    options = Dict()
    for (h, op) in v.options
        options[h] = _wrap_wildcard(op)
    end
    return EitherOptions(options)
end

_unwrap_abductible(v::AbductibleValue) = _unwrap_abductible(v.value)
_unwrap_abductible(v::PatternWrapper) = _unwrap_abductible(v.value)
function _unwrap_abductible(v::Array)
    res = [_unwrap_abductible(v) for v in v]
    return reshape(res, size(v))
end
_unwrap_abductible(v::Tuple) = tuple((_unwrap_abductible(v) for v in v)...)
_unwrap_abductible(v::Set) = Set([_unwrap_abductible(v) for v in v])
_unwrap_abductible(v) = v

_wrap_abductible(v::AbductibleValue) = v

function _wrap_abductible(v)
    if _has_wildcard(v)
        return AbductibleValue(_unwrap_abductible(v))
    else
        return v
    end
end

function _wrap_abductible(v::EitherOptions)
    options = Dict()
    for (h, op) in v.options
        options[h] = _wrap_abductible(op)
    end
    return EitherOptions(options)
end

# macro define_reverse_primitive(name, t, x, reverse_function)
#     return quote
#         local n = $(esc(name))
#         @define_primitive n $(esc(t)) $(esc(x))
#         local prim = every_primitive[n]
#         all_abstractors[prim] = [],
#         (
#             (v, ctx) -> (
#                 v,
#                 ReverseRunContext(
#                     ctx.arguments,
#                     vcat(ctx.predicted_arguments, reverse($(esc(reverse_function))(v))),
#                     ctx.calculated_arguments,
#                     ctx.filled_indices,
#                     ctx.filled_vars,
#                 ),
#             )
#         )
#     end
# end

function _simple_generic_reverse(f, value, paths, ctx, arg_count)
    # @info "Running simple generic reverse for $f $value"
    predicted_args = f(value)
    # @info predicted_args
    # @info paths
    if all(ismissing(ctx.calculated_arguments[end-i]) for i in 0:arg_count-1)
        return [(paths, predicted_args, nothing, nothing)], []
    end

    calculated_args_groups = Dict()
    if all(
        ismissing(ctx.calculated_arguments[end-i]) || !isa(ctx.calculated_arguments[end-i].value, EitherOptions) for
        i in 0:arg_count-1
    )
        calculated_args_groups[[
            ismissing(ctx.calculated_arguments[end-i]) ? missing : ctx.calculated_arguments[end-i].value for
            i in 0:arg_count-1
        ]] = paths
    else
        for path in paths
            calculated_args = [
                ismissing(ctx.calculated_arguments[end-i]) ? missing :
                _follow_path(ctx.calculated_arguments[end-i].value, path, 1)[2] for i in 0:arg_count-1
            ]
            if !haskey(calculated_args_groups, calculated_args)
                calculated_args_groups[calculated_args] = []
            end
            push!(calculated_args_groups[calculated_args], path)
        end
    end
    # @info calculated_args_groups

    output_results = []
    failed_paths = []
    for (calculated_args, paths_group) in calculated_args_groups
        matching_paths = [([], [], [])]

        is_good_group = true
        for i in 1:arg_count
            if ismissing(calculated_args[i])
                for (pred_path, calc_path, result_args) in matching_paths
                    pred_arg = _follow_path(predicted_args[i], pred_path, 1)[2]
                    push!(result_args, pred_arg)
                end
                continue
            end
            new_matching_paths = []
            # @info matching_paths
            for (pred_path, calc_path, result_args) in matching_paths
                pred_arg = _follow_path(predicted_args[i], pred_path, 1)[2]
                calc_arg = _follow_path(calculated_args[i], calc_path, 1)[2]

                # @info pred_arg
                # @info calc_arg
                for (pred_v, pred_path2) in all_path_options(pred_arg)
                    for (calc_v, calc_path2) in all_path_options(calc_arg)
                        # @info "Trying to unify $pred_v and $calc_v"
                        found, unified_v = _try_unify_values(pred_v, calc_v, false)
                        if !found
                            continue
                        end
                        full_pred_path = isempty(pred_path2) ? pred_path : vcat(pred_path, pred_path2)
                        full_calc_path = isempty(calc_path2) ? calc_path : vcat(calc_path, calc_path2)
                        upd_result_args =
                            isempty(pred_path2) ? result_args : [_follow_path(r, pred_path2, 1)[2] for r in result_args]

                        push!(new_matching_paths, (full_pred_path, full_calc_path, vcat(upd_result_args, [unified_v])))
                    end
                end
            end

            if isempty(new_matching_paths)
                is_good_group = false
                break
            end
            matching_paths = new_matching_paths
        end
        # @info "Matching paths $matching_paths"

        if !is_good_group
            append!(failed_paths, paths_group)
            continue
        end

        simple_values = false
        result_trees = [Dict() for _ in 1:arg_count]
        result_paths = []
        for (pred_path, calc_path, unified_args) in matching_paths
            full_path = vcat(calc_path, pred_path)
            if isempty(full_path)
                result_args = unified_args
                simple_values = true
                break
            end
            push!(result_paths, full_path)
            for i in 1:arg_count
                cur_tree = result_trees[i]
                for p in full_path[1:end-1]
                    if !haskey(cur_tree, p)
                        cur_tree[p] = Dict()
                    end
                    cur_tree = cur_tree[p]
                end
                cur_tree[full_path[end]] = unified_args[i]
            end
        end

        if !simple_values
            result_args = [_build_eithers(result_trees[i], [], result_paths) for i in 1:arg_count]
        end

        push!(output_results, (paths_group, result_args, nothing, nothing))
    end

    return output_results, failed_paths
end

function __generic_reverse(rev_func, f, value, paths, ctx, arg_count)
    return rev_func(f, value, paths, ctx, arg_count)
end

function __generic_reverse(rev_func, f, value::PatternWrapper, paths, ctx, arg_count)
    good_paths_results, bad_paths = __generic_reverse(rev_func, f, value.value, paths, ctx, arg_count)
    return [
        (ps, [_wrap_wildcard(r) for r in args], f_indices, f_vars) for
        (ps, args, f_indices, f_vars) in good_paths_results
    ],
    bad_paths
end

function __generic_reverse(rev_func, f, value::AbductibleValue, paths, ctx, arg_count)
    good_paths_results, bad_paths = try
        good_paths_results, bad_paths = @invoke __generic_reverse(rev_func, f, value::Any, paths, ctx, arg_count)
        [
            (ps, [_wrap_abductible(r) for r in args], f_indices, f_vars) for
            (ps, args, f_indices, f_vars) in good_paths_results
        ],
        bad_paths
    catch e
        # bt = catch_backtrace()
        # @error e exception = (e, bt)
        if isa(e, MethodError) && any(isa(arg, AbductibleValue) for arg in e.args)
            [], paths
        else
            rethrow()
        end
    end
    if isempty(good_paths_results)
        calculated_args_groups = Dict()
        if all(!isa(ctx.calculated_arguments[end-i], EitherOptions) for i in 0:arg_count-1)
            calculated_args_groups[[
                ismissing(ctx.calculated_arguments[end-i]) ? AbductibleValue(any_object) :
                ctx.calculated_arguments[end-i].value for i in 0:arg_count-1
            ]] = paths
        else
            for path in paths
                calculated_args = [
                    ismissing(ctx.calculated_arguments[end-i]) ? AbductibleValue(any_object) :
                    _follow_path(ctx.calculated_arguments[end-i].value, path, 1)[2] for i in 0:arg_count-1
                ]
                if !haskey(calculated_args_groups, calculated_args)
                    calculated_args_groups[calculated_args] = []
                end
                push!(calculated_args_groups[calculated_args], path)
            end
        end

        results = [(paths, args, nothing, nothing) for (args, paths) in calculated_args_groups]
        return results, []
    end
    return good_paths_results, bad_paths
end

function __generic_reverse(rev_func, f, value::Union{Nothing,AnyObject}, paths, ctx, arg_count)
    # @info "Running in reverse $p $output $context"
    good_paths_results, bad_paths = try
        rev_func(f, value, paths, ctx, arg_count)
    catch e
        # @info e
        # bt = catch_backtrace()
        # @error e exception = (e, bt)
        if isa(e, MethodError)
            [], paths
        else
            rethrow()
        end
    end
    if isempty(good_paths_results)
        return [(paths, [value for _ in 1:arg_count], nothing, nothing)], []
    end
    return good_paths_results, bad_paths
end

function _generic_reverse(rev_func, f, arg_count, value, ctx)
    failed_paths = []
    results = []
    last_error = nothing
    for (v, paths) in value.value_paths
        try
            @info f
            @info v
            @info paths
            @info ctx.calculated_arguments
            good_paths_results, bad_paths = __generic_reverse(rev_func, f, v, paths, ctx, arg_count)
            @info good_paths_results
            append!(results, good_paths_results)
            append!(failed_paths, bad_paths)
        catch e
            if isa(e, InterruptException) || isa(e, MethodError) || isa(e, UndefVarError)
                rethrow()
            end

            # rethrow()
            last_error = e
            append!(failed_paths, paths)
        end
    end
    if isempty(results)
        if isnothing(last_error)
            error("No reverse results")
        end
        throw(last_error)
    end
    if length(results) == 1 && results[1][1] == [[]]
        outputs = [ValueContainer(results[1][2][i]) for i in 1:arg_count]
        if isnothing(results[1][3])
            filled_indices = ctx.filled_indices
        else
            filled_indices = results[1][3]
        end
        if isnothing(results[1][4])
            filled_vars = ctx.filled_vars
        else
            filled_vars = results[1][4]
        end
        return (
            value,
            ReverseRunContext(
                ctx.upstream_outputs,
                ctx.arguments,
                vcat(ctx.predicted_arguments, reverse(outputs)),
                ctx.calculated_arguments,
                filled_indices,
                filled_vars,
            ),
        )
    end

    output_trees = [Dict() for _ in 1:arg_count]
    output_paths = [Dict() for _ in 1:arg_count]
    indices_trees = Dict()
    indices_paths = Dict()
    vars_trees = Dict()
    vars_paths = Dict()
    no_ind_var_changes = false
    all_parent_paths = Set()
    for (parent_paths, predicted_args, f_indices, f_vars) in results
        if isnothing(f_indices)
            no_ind_var_changes = true
        end
        for parent_path in parent_paths
            for i in 1:arg_count
                for (v, path) in all_path_options(predicted_args[i])
                    merged_path = vcat(parent_path, path)
                    if !haskey(output_paths[i], v)
                        output_paths[i][v] = []
                    end
                    push!(output_paths[i][v], merged_path)
                end
                cur_tree = output_trees[i]
                for p in parent_path[1:end-1]
                    if !haskey(cur_tree, p)
                        cur_tree[p] = Dict()
                    end
                    cur_tree = cur_tree[p]
                end
                cur_tree[parent_path[end]] = predicted_args[i]
            end
            if !no_ind_var_changes
                for (i, ind_v) in f_indices
                    if !haskey(indices_paths, i)
                        indices_paths[i] = Dict()
                    end
                    for (v, path) in all_path_options(ind_v.value)
                        merged_path = vcat(parent_path, path)
                        if !haskey(indices_paths[i], v)
                            indices_paths[i][v] = []
                        end
                        push!(indices_paths[i][v], merged_path)
                    end
                    if !haskey(indices_trees, i)
                        indices_trees[i] = Dict()
                    end
                    cur_tree = indices_trees[i]
                    for p in parent_path[1:end-1]
                        if !haskey(cur_tree, p)
                            cur_tree[p] = Dict()
                        end
                        cur_tree = cur_tree[p]
                    end
                    cur_tree[parent_path[end]] = ind_v.value
                end
                for (i, var_v) in f_vars
                    if !haskey(vars_paths, i)
                        vars_paths[i] = Dict()
                    end
                    for (v, path) in all_path_options(var_v.value)
                        merged_path = vcat(parent_path, path)
                        if !haskey(vars_paths[i], v)
                            vars_paths[i][v] = []
                        end
                        push!(vars_paths[i][v], merged_path)
                    end
                    if !haskey(vars_trees, i)
                        vars_trees[i] = Dict()
                    end
                    cur_tree = vars_trees[i]
                    for p in parent_path[1:end-1]
                        if !haskey(cur_tree, p)
                            cur_tree[p] = Dict()
                        end
                        cur_tree = cur_tree[p]
                    end
                    cur_tree[parent_path[end]] = var_v.value
                end
            end
        end
        union!(all_parent_paths, parent_paths)
    end
    output_values = [_build_eithers(output_trees[i], [], all_parent_paths) for i in 1:arg_count]
    outputs = [ValueContainer(output_values[i], output_paths[i]) for i in 1:arg_count]
    if !no_ind_var_changes
        filled_indices = Dict(
            i => ValueContainer(_build_eithers(indices_trees[i], [], all_parent_paths), indices_paths[i]) for
            i in keys(indices_trees)
        )
        filled_vars = Dict(
            i => ValueContainer(_build_eithers(vars_trees[i], [], all_parent_paths), vars_paths[i]) for
            i in keys(vars_trees)
        )
        ctx = ReverseRunContext(
            ctx.upstream_outputs,
            ctx.arguments,
            ctx.predicted_arguments,
            ctx.calculated_arguments,
            filled_indices,
            filled_vars,
        )
    end

    for path in all_parent_paths
        for i in 1:length(path)-1
            push!(all_parent_paths, path[1:i])
        end
    end
    for path in failed_paths
        for i in 1:length(path)-1
            if !in(path[1:end-i], all_parent_paths)
                push!(failed_paths, path[1:i])
            else
                break
            end
        end
    end

    filtered_value = drop_remap_option_paths(value, failed_paths, all_parent_paths, Dict())

    out_ctx = filter_context_values(ctx, failed_paths, all_parent_paths, Dict())
    append!(out_ctx.predicted_arguments, reverse(outputs))

    return (filtered_value, out_ctx)
end

macro define_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $(esc(t)) $(esc(x))
        local prim = every_primitive[n]
        local arg_count = length(arguments_of_type($(esc(t))))
        all_abstractors[prim] = (
            [],
            (val::ValueContainer, ctx) ->
                _generic_reverse(_simple_generic_reverse, $(esc(reverse_function)), arg_count, val, ctx),
        )
    end
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg)
    if i == n
        return f(value, calculated_arguments)
    else
        return _generic_abductible_reverse(f, n, value, calculated_arguments, i + 1, calculated_arguments[end-i])
    end
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg::EitherOptions)
    outputs = Dict()
    for (h, v) in calculated_arg.options
        new_args = [fix_option_hashes(Set([h]), v) for v in calculated_arguments]
        outputs[h] = _generic_abductible_reverse(f, n, value, new_args, 1, new_args[end])
    end
    results = [EitherOptions(Dict(h => v[j] for (h, v) in outputs)) for j in 1:n]
    # @info results
    return results
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg::PatternWrapper)
    new_args =
        [j == length(calculated_arguments) - i + 1 ? arg.value : arg for (j, arg) in enumerate(calculated_arguments)]
    results = _generic_abductible_reverse(f, n, value, new_args, i, calculated_arg.value)
    return [_wrap_wildcard(r) for r in results]
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg::AbductibleValue)
    new_args =
        [j == length(calculated_arguments) - i + 1 ? arg.value : arg for (j, arg) in enumerate(calculated_arguments)]
    results = _generic_abductible_reverse(f, n, value, new_args, i, calculated_arg.value)
    return [_wrap_abductible(r) for r in results]
end

function _generic_abductible_reverse(f, n, value, calculated_arguments, i, calculated_arg::Union{AnyObject,Nothing})
    try
        if i == n
            return f(value, calculated_arguments)
        else
            return _generic_abductible_reverse(f, n, value, calculated_arguments, i + 1, calculated_arguments[end-i])
        end
    catch e
        if isa(e, InterruptException)
            rethrow()
        end
        # @info e
        new_args = [
            j == (length(calculated_arguments) - i + 1) ? missing : calculated_arguments[j] for
            j in 1:length(calculated_arguments)
        ]
        # @info calculated_arguments
        # @info new_args
        if i == n
            return f(value, new_args)
        else
            return _generic_abductible_reverse(f, n, value, new_args, i + 1, new_args[end-i])
        end
    end
end

function _generic_abductible_reverse(f, value, paths, ctx, arg_count)
    @info "Running in reverse $f $value $(ctx.calculated_arguments)"

    if all(ismissing(ctx.calculated_arguments[end-i]) for i in 0:arg_count-1)
        return [(paths, f(value, ctx.calculated_arguments), nothing, nothing)], []
    end

    calculated_args_groups = Dict()

    if all(
        ismissing(ctx.calculated_arguments[end-i]) || !isa(ctx.calculated_arguments[end-i].value, EitherOptions) for
        i in 0:arg_count-1
    )
        calculated_args_groups[[
            (ismissing(ctx.calculated_arguments[end-i]) ? missing : ctx.calculated_arguments[end-i].value, []) for
            i in 0:arg_count-1
        ]] = paths
    else
        for path in paths
            calculated_args = [
                ismissing(ctx.calculated_arguments[end-i]) ? (missing, []) :
                _follow_path(ctx.calculated_arguments[end-i].value, path, 1)[2:3] for i in 0:arg_count-1
            ]
            if !haskey(calculated_args_groups, calculated_args)
                calculated_args_groups[calculated_args] = []
            end
            push!(calculated_args_groups[calculated_args], path)
        end
    end
    @info calculated_args_groups

    output_results = []
    failed_paths = []

    for (calculated_args, paths_group) in calculated_args_groups
        arg_groups = [([], [], false, false)]
        for i in 1:arg_count
            if ismissing(calculated_args[i][1])
                for (calc_path, args, has_pattern, has_abductible) in arg_groups
                    push!(args, missing)
                end
                continue
            end
            new_arg_groups = []
            for (calc_path, args, has_pattern, has_abductible) in arg_groups
                calc_arg = _follow_path(calculated_args[i][1], calc_path, 1)[2]

                for (v, path) in all_path_options(calc_arg)
                    full_path = vcat(calc_path, path)
                    if isa(v, PatternWrapper)
                        op_has_pattern = true
                        v = v.value
                    else
                        op_has_pattern = has_pattern
                    end
                    if isa(v, AbductibleValue)
                        op_has_abductible = true
                        v = v.value
                    else
                        op_has_abductible = has_abductible
                    end
                    push!(new_arg_groups, (full_path, vcat(args, [v]), op_has_pattern, op_has_abductible))
                end
            end
            arg_groups = new_arg_groups
        end
        @info arg_groups

        simple_values = false
        result_trees = [Dict() for _ in 1:arg_count]
        result_paths = []

        for (calc_path, args, has_pattern, has_abductible) in arg_groups
            # @info calc_path, args
            args_options = [args]
            any_nones = findall(a -> isa(a, AnyObject) || isnothing(a), args)
            for i in any_nones
                added_options = []
                for op in args_options
                    new_op = copy(op)
                    new_op[i] = missing
                    push!(added_options, new_op)
                end
                append!(args_options, added_options)
            end

            for args in args_options
                predicted_args = try
                    f(value, args)
                catch e
                    if isa(e, InterruptException)
                        rethrow()
                    end
                    if isa(value, AbductibleValue) &&
                       isa(e, MethodError) &&
                       any(isa(arg, AbductibleValue) for arg in e.args)
                        [ismissing(a) ? AbductibleValue(any_object) : a for a in args]
                    else
                        continue
                    end
                end
                if has_abductible
                    predicted_args = [_wrap_abductible(a) for a in predicted_args]
                elseif has_pattern
                    predicted_args = [_wrap_wildcard(a) for a in predicted_args]
                end

                if isempty(calc_path)
                    result_args = predicted_args
                    simple_values = true
                    break
                end

                push!(result_paths, calc_path)
                for i in 1:arg_count
                    cur_tree = result_trees[i]
                    for p in calc_path[1:end-1]
                        if !haskey(cur_tree, p)
                            cur_tree[p] = Dict()
                        end
                        cur_tree = cur_tree[p]
                    end
                    cur_tree[calc_path[end]] = predicted_args[i]
                end
                break
            end
        end
        @info result_trees

        if !simple_values
            if isempty(result_paths)
                append!(failed_paths, paths_group)
                continue
            end
            result_args = [_build_eithers(result_trees[i], [], result_paths) for i in 1:arg_count]
        end

        push!(output_results, (paths_group, result_args, nothing, nothing))
    end

    return output_results, failed_paths
end

macro define_abductible_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        local arg_count = length(arguments_of_type($(esc(t))))
        all_abstractors[prim] = [],
        ((val, ctx) -> _generic_reverse(_generic_abductible_reverse, $(esc(reverse_function)), arg_count, val, ctx))
    end
end

macro define_custom_reverse_primitive(name, t, x, arg_checkers, reverse_function)
    # return quote
    #     local n = $(esc(name))
    #     @define_primitive n $t $x
    #     local prim = every_primitive[n]
    #     all_abstractors[prim] = $(esc(reverse_function))
    # end
    return quote
        local n = $(esc(name))
        @define_primitive n $(esc(t)) $(esc(x))
        local prim = every_primitive[n]
        local arg_count = length(arguments_of_type($(esc(t))))
        all_abstractors[prim] = (
            $(esc(arg_checkers)),
            (val::ValueContainer, ctx) ->
                _generic_reverse($(esc(reverse_function)), $(esc(reverse_function)), arg_count, val, ctx),
        )
    end
end

_has_no_holes(p::Hole) = false
_has_no_holes(p::Apply) = _has_no_holes(p.f) && _has_no_holes(p.x)
_has_no_holes(p::Abstraction) = _has_no_holes(p.b)
_has_no_holes(p::Program) = true

_is_reversible_subfunction(p) = is_reversible(p) && _has_no_holes(p)

struct IsPossibleSubfunction <: ArgChecker
    should_be_reversible::Nothing
    max_index::Nothing
    can_have_free_vars::Nothing
    IsPossibleSubfunction() = new(nothing, nothing, nothing)
end

Base.:(==)(c1::IsPossibleSubfunction, c2::IsPossibleSubfunction) = true

Base.hash(c::IsPossibleSubfunction, h::UInt64) =
    hash(c.should_be_reversible, hash(c.max_index, hash(c.can_have_free_vars, h)))

function (c::IsPossibleSubfunction)(p::Index, skeleton, path)
    return p.n != 0
end

(c::IsPossibleSubfunction)(p, skeleton, path) = true

step_arg_checker(c::IsPossibleSubfunction, arg::ArgTurn) = c
step_arg_checker(::IsPossibleSubfunction, arg) = nothing

function calculate_dependent_vars(p, inputs, output)
    context = ReverseRunContext([], [], [], [], Dict(), Dict(k => ValueContainer(v) for (k, v) in inputs))
    p_info = gather_info(p)
    updated_inputs = _run_in_reverse2(p_info, ValueContainer(output), context)[2].filled_vars
    updated_inputs = Dict(k => cleanup_options(v.value) for (k, v) in updated_inputs)

    return Dict(
        k => v for (k, v) in updated_inputs if (!haskey(inputs, k) || inputs[k] != v) # && !isa(v, AbductibleValue)
    )
end

include("repeat.jl")
include("cons.jl")
include("map.jl")
include("concat.jl")
include("range.jl")
include("rows.jl")
include("select.jl")
include("elements.jl")
include("zip.jl")
include("reverse.jl")
include("fold.jl")
include("tuple.jl")
include("adjoin.jl")
include("groupby.jl")
include("cluster.jl")
include("bool.jl")
include("int.jl")
include("rev_fix_param.jl")

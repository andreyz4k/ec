
abstract type Entry end

using DataStructures: Accumulator
struct ValueEntry <: Entry
    type_id::UInt64
    values::Vector
    complexity_summary::Accumulator
    complexity::Float64
end

Base.hash(v::ValueEntry, h::UInt64) = hash(v.type_id, hash(v.values, h))
Base.:(==)(v1::ValueEntry, v2::ValueEntry) = v1.type_id == v2.type_id && v1.values == v2.values

match_at_index(entry::ValueEntry, index::Int, value) = entry.values[index] == value

match_with_entry(sc, entry::ValueEntry, other::ValueEntry) = entry == other

function matching_with_unknown_candidates(sc, entry::ValueEntry, var_id)
    results = []
    index = get_index(sc.entries, entry)

    branches = get_connected_to(sc.branch_types, entry.type_id)

    for known_branch_id in branches
        if !sc.branch_is_not_copy[known_branch_id]
            continue
        end
        if known_branch_id == sc.target_branch_id
            continue
        end
        known_var_id = sc.branch_vars[known_branch_id]
        if vars_in_loop(sc, known_var_id, var_id)
            # || !is_branch_compatible(unknown_branch.key, unknown_branch, [input_branch])
            continue
        end
        if sc.branch_entries[known_branch_id] == index
            known_type = sc.types[first(get_connected_from(sc.branch_types, known_branch_id))]
            push!(results, (FreeVar(known_type, known_var_id), Dict(known_var_id => known_branch_id), known_type))
        end
    end
    results
end

const_options(entry::ValueEntry) = [entry.values[1]]

struct NoDataEntry <: Entry
    type_id::UInt64
end
Base.hash(v::NoDataEntry, h::UInt64) = hash(v.type_id, h)
Base.:(==)(v1::NoDataEntry, v2::NoDataEntry) = v1.type_id == v2.type_id

match_at_index(entry::NoDataEntry, index::Int, value) = true

match_with_entry(sc, entry::NoDataEntry, other::ValueEntry) =
    might_unify(sc.types[entry.type_id], sc.types[other.type_id])

function matching_with_unknown_candidates(sc, entry::NoDataEntry, var_id)
    results = []
    types = get_sub_types(sc.types, entry.type_id)

    for tp_id in types
        for known_branch_id in get_connected_to(sc.branch_types, tp_id)
            if !sc.branch_is_not_copy[known_branch_id]
                continue
            end
            if known_branch_id == sc.target_branch_id
                continue
            end
            known_var_id = sc.branch_vars[known_branch_id]
            if vars_in_loop(sc, known_var_id, var_id)
                # || !is_branch_compatible(unknown_branch.key, unknown_branch, [input_branch])
                continue
            end
            tp = sc.types[tp_id]
            push!(results, (FreeVar(tp, known_var_id), Dict(known_var_id => known_branch_id), tp))
        end
    end

    results
end

const_options(entry::NoDataEntry) = []

function matching_with_known_candidates(sc, entry::ValueEntry, known_branch_id)
    results = []
    types = get_super_types(sc.types, entry.type_id)
    entry_type = sc.types[entry.type_id]

    known_var_id = sc.branch_vars[known_branch_id]
    for tp_id in types
        for unknown_branch_id in get_connected_to(sc.branch_types, tp_id)
            if !sc.branch_is_unknown[unknown_branch_id]
                continue
            end
            unknown_var_id = sc.branch_vars[unknown_branch_id]
            if vars_in_loop(sc, known_var_id, unknown_var_id)
                # || !is_branch_compatible(unknown_branch.key, unknown_branch, [input_branch])
                continue
            end
            unknown_entry_id = sc.branch_entries[unknown_branch_id]
            unknown_entry = sc.entries[unknown_entry_id]
            if unknown_entry_id == sc.branch_entries[known_branch_id] ||
               (!isa(unknown_entry, ValueEntry) && match_with_entry(sc, unknown_entry, entry))
                push!(results, (FreeVar(entry_type, known_var_id), unknown_var_id, unknown_branch_id, entry_type))
            end
        end
    end

    results
end

struct EitherOptions
    options::Dict{UInt64,Any}
    function EitherOptions(options)
        first_value = first(values(options))
        if all(v -> v == first_value, values(options))
            return first_value
        end
        return new(options)
    end
end

Base.:(==)(v1::EitherOptions, v2::EitherOptions) = v1.options == v2.options
Base.hash(v::EitherOptions, h::UInt64) = hash(v.options, h)

struct AnyObject end
any_object = AnyObject()

struct PatternWrapper
    value::Any
end

Base.:(==)(v1::PatternWrapper, v2::PatternWrapper) = v1.value == v2.value
Base.hash(v::PatternWrapper, h::UInt64) = hash(v.value, h)

struct AbductibleValue
    value::Any
    generator::Function
end

Base.:(==)(v1::AbductibleValue, v2::AbductibleValue) = v1.value == v2.value && v1.generator == v2.generator
Base.hash(v::AbductibleValue, h::UInt64) = hash(v.value, hash(v.generator, h))

struct EitherEntry <: Entry
    type_id::UInt64
    values::Vector
    complexity_summary::Accumulator
    complexity::Float64
end

Base.hash(v::EitherEntry, h::UInt64) = hash(v.type_id, hash(v.values, h))
Base.:(==)(v1::EitherEntry, v2::EitherEntry) = v1.type_id == v2.type_id && v1.values == v2.values

function matching_with_unknown_candidates(sc, entry::EitherEntry, var_id)
    results = []
    types = get_super_types(sc.types, entry.type_id)

    for tp_id in types
        for known_branch_id in get_connected_to(sc.branch_types, tp_id)
            if !sc.branch_is_not_copy[known_branch_id]
                continue
            end
            if known_branch_id == sc.target_branch_id
                continue
            end
            known_var_id = sc.branch_vars[known_branch_id]
            if vars_in_loop(sc, known_var_id, var_id) ||
               !match_with_entry(sc, entry, sc.entries[sc.branch_entries[known_branch_id]])
                # || !is_branch_compatible(unknown_branch.key, unknown_branch, [input_branch])
                continue
            end
            tp = sc.types[tp_id]
            push!(results, (FreeVar(tp, known_var_id), Dict(known_var_id => known_branch_id), tp))
        end
    end

    results
end

function _const_options(options::EitherOptions)
    return vcat([_const_options(op) for (_, op) in options.options]...)
end

function _const_options(value)
    return [value]
end

function _const_options(value::PatternWrapper)
    return []
end

function const_options(entry::EitherEntry)
    return _const_options(entry.values[1])
end

function _match_options(value::EitherOptions, other_value)
    return any(_match_options(op, other_value) for (_, op) in value.options)
end

_match_options(value::PatternWrapper, other_value) = _match_pattern(value, other_value)
_match_options(value::AbductibleValue, other_value) = _match_pattern(value, other_value)
_match_options(value, other_value) = value == other_value

match_at_index(entry::EitherEntry, index::Int, value) = _match_options(entry.values[index], value)

function match_with_entry(sc, entry::EitherEntry, other::ValueEntry)
    return all(match_at_index(entry, i, other.values[i]) for i in 1:sc.example_count)
end

is_subeither(wide::EitherOptions, narrow) = any(is_subeither(op, narrow) for op in wide.options)
is_subeither(wide, narrow::EitherOptions) = false
is_subeither(wide, narrow) = wide == narrow

function is_subeither(wide::EitherOptions, narrow::EitherOptions)
    check_level = any(haskey(wide.options, k) for k in keys(narrow.options))
    if check_level
        all(haskey(wide.options, k) && is_subeither(wide.options[k], n_op) for (k, n_op) in narrow.options)
    else
        any(is_subeither(op, narrow) for op in wide.options)
    end
end

struct PatternEntry <: Entry
    type_id::UInt64
    values::Vector
    complexity_summary::Accumulator
    complexity::Float64
end

Base.hash(v::PatternEntry, h::UInt64) = hash(v.type_id, hash(v.values, h))
Base.:(==)(v1::PatternEntry, v2::PatternEntry) = v1.type_id == v2.type_id && v1.values == v2.values

_match_pattern(value::AnyObject, other_value) = true
_match_pattern(value::PatternWrapper, other_value) = _match_pattern(value.value, other_value)
_match_pattern(value::PatternWrapper, other_value::PatternWrapper) = value.value == other_value.value
_match_pattern(value, other_value) = value == other_value
_match_pattern(value::Vector, other_value) = all(_match_pattern(v, ov) for (v, ov) in zip(value, other_value))
_match_pattern(value::Tuple, other_value) = all(_match_pattern(v, ov) for (v, ov) in zip(value, other_value))
_match_pattern(value::AbductibleValue, other_value) = _match_pattern(value.value, other_value)

match_at_index(entry::PatternEntry, index::Int, value) = _match_pattern(entry.values[index], value)

function match_with_entry(sc, entry::PatternEntry, other::ValueEntry)
    return all(match_at_index(entry, i, other.values[i]) for i in 1:sc.example_count)
end

function match_with_entry(sc, entry::ValueEntry, other::PatternEntry)
    return false
end

function match_with_entry(sc, entry::PatternEntry, other::PatternEntry)
    return all(match_at_index(entry, i, other.values[i]) for i in 1:sc.example_count)
end

function match_with_entry(sc, entry::EitherEntry, other::PatternEntry)
    return all(match_at_index(entry, i, other.values[i]) for i in 1:sc.example_count)
end

match_with_entry(sc, entry::NoDataEntry, other::PatternEntry) =
    might_unify(sc.types[entry.type_id], sc.types[other.type_id])

function matching_with_unknown_candidates(sc, entry::PatternEntry, var_id)
    results = []

    for known_branch_id in get_connected_to(sc.branch_types, entry.type_id)
        if !sc.branch_is_not_copy[known_branch_id]
            continue
        end
        if known_branch_id == sc.target_branch_id
            continue
        end
        known_var_id = sc.branch_vars[known_branch_id]
        if vars_in_loop(sc, known_var_id, var_id) ||
           !match_with_entry(sc, entry, sc.entries[sc.branch_entries[known_branch_id]])
            # || !is_branch_compatible(unknown_branch.key, unknown_branch, [input_branch])
            continue
        end
        tp = sc.types[entry.type_id]
        push!(results, (FreeVar(tp, known_var_id), Dict(known_var_id => known_branch_id), tp))
    end
    results
end

function matching_with_known_candidates(sc, entry::PatternEntry, known_branch_id)
    results = []
    types = get_super_types(sc.types, entry.type_id)
    entry_type = sc.types[entry.type_id]

    known_var_id = sc.branch_vars[known_branch_id]
    for tp_id in types
        for unknown_branch_id in get_connected_to(sc.branch_types, tp_id)
            if !sc.branch_is_unknown[unknown_branch_id]
                continue
            end
            unknown_var_id = sc.branch_vars[unknown_branch_id]
            if vars_in_loop(sc, known_var_id, unknown_var_id)
                # || !is_branch_compatible(unknown_branch.key, unknown_branch, [input_branch])
                continue
            end
            unknown_entry_id = sc.branch_entries[unknown_branch_id]
            unknown_entry = sc.entries[unknown_entry_id]
            if unknown_entry_id == sc.branch_entries[known_branch_id] ||
               (!isa(unknown_entry, ValueEntry) && match_with_entry(sc, unknown_entry, entry))
                push!(results, (FreeVar(entry_type, known_var_id), unknown_var_id, unknown_branch_id, entry_type))
            end
        end
    end

    results
end

const_options(entry::PatternEntry) = []

struct AbductibleEntry <: Entry
    type_id::UInt64
    values::Vector
    complexity_summary::Accumulator
    complexity::Float64
end

Base.hash(v::AbductibleEntry, h::UInt64) = hash(v.type_id, hash(v.values, h))
Base.:(==)(v1::AbductibleEntry, v2::AbductibleEntry) = v1.type_id == v2.type_id && v1.values == v2.values

match_at_index(entry::AbductibleEntry, index::Int, value) = _match_pattern(entry.values[index], value)

function match_with_entry(sc, entry::AbductibleEntry, other::ValueEntry)
    return all(match_at_index(entry, i, other.values[i]) for i in 1:sc.example_count)
end

function match_with_entry(sc, entry::AbductibleEntry, other::PatternEntry)
    return false
end

function matching_with_unknown_candidates(sc, entry::AbductibleEntry, var_id)
    results = []

    for known_branch_id in get_connected_to(sc.branch_types, entry.type_id)
        if !sc.branch_is_not_copy[known_branch_id]
            continue
        end
        if known_branch_id == sc.target_branch_id
            continue
        end
        known_var_id = sc.branch_vars[known_branch_id]
        if vars_in_loop(sc, known_var_id, var_id) ||
           !match_with_entry(sc, entry, sc.entries[sc.branch_entries[known_branch_id]])
            # || !is_branch_compatible(unknown_branch.key, unknown_branch, [input_branch])
            continue
        end
        tp = sc.types[entry.type_id]
        push!(results, (FreeVar(tp, known_var_id), Dict(known_var_id => known_branch_id), tp))
    end
    results
end

const_options(entry::AbductibleEntry) = []

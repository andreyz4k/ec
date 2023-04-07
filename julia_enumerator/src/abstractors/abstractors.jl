
all_abstractors = Dict{Program,Tuple{Vector,Any}}()

struct AnyObject end
any_object = AnyObject()

function _is_reversible(p::Primitive)
    if haskey(all_abstractors, p)
        all_abstractors[p][1]
    else
        nothing
    end
end

function _is_reversible(p::Apply)
    rev_f = _is_reversible(p.f)
    if !isnothing(rev_f)
        if isempty(rev_f)
            if isa(p.x, Hole)
                if !isarrow(p.x.t)
                    return rev_f
                else
                    return nothing
                end
            end
            if isa(p.x, Index) || isa(p.x, FreeVar)
                return rev_f
            end
            if isa(p.x, Abstraction) || isa(p.x, Apply)
                return _is_reversible(p.x)
            end
        else
            checker = rev_f[end][1]
            if checker(p.x)
                return view(rev_f, 1:length(rev_f)-1)
            else
                return nothing
            end
        end
    end
    nothing
end

_is_reversible(p::Invented) = _is_reversible(p.b)
_is_reversible(p::Abstraction) = _is_reversible(p.b)

_is_reversible(p::Program) = nothing

is_reversible(p::Program)::Bool = !isnothing(_is_reversible(p))

function _get_reversed_program(p::Primitive, arguments)
    return all_abstractors[p][2](arguments)
end

function _get_reversed_program(p::Invented, arguments)
    _get_reversed_program(p.b, arguments)
end

noop(a)::Vector{Any} = [a]

function _get_reversed_program(p::Hole, arguments)
    return noop
end

function _get_reversed_program(p::FreeVar, arguments)
    return noop
end

function _get_reversed_program(p::Index, arguments)
    return noop
end

function _get_reversed_program(p::Apply, arguments)
    push!(arguments, p.x)
    reversed_f = _get_reversed_program(p.f, arguments)
    return reversed_f
end

function _get_reversed_program(p::Abstraction, arguments)
    # Only used in invented functions
    rev_f = _get_reversed_program(p.b, arguments)
    rev_a = _get_reversed_program(pop!(arguments), arguments)
    # TODO: Properly use rev_a
    return rev_f
end

function get_reversed_program(p::Program)
    return _get_reversed_program(p, [])
end

function _reverse_eithers(_reverse_function, value)
    hashes = []
    outputs = Vector{Any}[]
    for (h, val) in value.options
        outs = _reverse_function(val)
        if isempty(outputs)
            for _ in 1:length(outs)
                push!(outputs, [])
            end
        end
        push!(hashes, h)
        for i in 1:length(outs)
            push!(outputs[i], outs[i])
        end
    end
    results = []
    for values in outputs
        if allequal(values)
            push!(results, values[1])
        elseif any(out == value for out in values)
            push!(results, value)
        else
            options = Dict(hashes[i] => values[i] for i in 1:length(hashes))
            push!(results, EitherOptions(options))
        end
    end
    return results
end

function generic_reverse(rev_function, n)
    function _generic_reverse(arguments)
        rev_functions = []
        for _ in 1:n
            rev_a = _get_reversed_program(pop!(arguments), arguments)
            push!(rev_functions, rev_a)
        end
        function _reverse_function(value)::Vector{Any}
            rev_results = rev_function(value)
            return vcat([rev_functions[i](rev_results[i]) for i in 1:n]...)
        end
        function _reverse_function(value::EitherOptions)::Vector{Any}
            _reverse_eithers(_reverse_function, value)
        end
        return _reverse_function
    end
    return _generic_reverse
end

macro define_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        local rev = generic_reverse($(esc(reverse_function)), length(arguments_of_type(prim.t)))
        all_abstractors[prim] = [], rev
    end
end

macro define_custom_reverse_primitive(name, t, x, reverse_function)
    return quote
        local n = $(esc(name))
        @define_primitive n $t $x
        local prim = every_primitive[n]
        local out = $(esc(reverse_function))
        all_abstractors[prim] = out
    end
end

_has_no_holes(p::Hole) = false
_has_no_holes(p::Apply) = _has_no_holes(p.f) && _has_no_holes(p.x)
_has_no_holes(p::Abstraction) = _has_no_holes(p.b)
_has_no_holes(p::Program) = true

_is_reversible_subfunction(p) = is_reversible(p) && _has_no_holes(p)

_is_possible_subfunction(p::Index, from_input, skeleton, path) = p.n != 0 || !isa(path[end], ArgTurn)
_is_possible_subfunction(p::Primitive, from_input, skeleton, path) = !from_input || haskey(all_abstractors, p)
_is_possible_subfunction(p::Invented, from_input, skeleton, path) = !from_input || is_reversible(p)
_is_possible_subfunction(p::FreeVar, from_input, skeleton, path) = true

__get_var_indices(p::Index) = [p.n]
__get_var_indices(p::FreeVar) = [-1]
__get_var_indices(p::Primitive) = []
__get_var_indices(p::Invented) = []
__get_var_indices(p::Apply) = vcat(__get_var_indices(p.f), __get_var_indices(p.x))
__get_var_indices(p::Abstraction) = [((i > 0) ? (i - 1) : i) for i in __get_var_indices(p.b) if (i > 0 || i == -1)]

function _get_var_indices(f, n)
    raw_indices_mapping = __get_var_indices(f)
    external_vars = 0
    for i in raw_indices_mapping
        if i == -1 || i > n - 1
            external_vars += 1
        end
    end
    indices_mapping = []
    marked_external = 0
    for i in raw_indices_mapping
        if i == -1 || i > n - 1
            marked_external += 1
            push!(indices_mapping, marked_external)
        else
            push!(indices_mapping, external_vars + n - i)
        end
    end
    return indices_mapping, external_vars
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


abstract type Tp end

struct TypeVariable <: Tp
    id::Int64
end

struct TypeConstructor <: Tp
    name::String
    arguments::Vector{Tp}
    is_poly::Bool

    function TypeConstructor(name, arguments)
        new(name, arguments, any(is_polymorphic(a) for a in arguments))
    end
end

struct TypeNamedArgsConstructor <: Tp
    name::String
    arguments::Dict{String,Tp}
    output::Tp
    is_poly::Bool

    function TypeNamedArgsConstructor(name, arguments, output)
        new(name, arguments, output, any(is_polymorphic(a) for a in values(arguments)) || is_polymorphic(output))
    end
end

is_polymorphic(::TypeVariable) = true
is_polymorphic(tc::TypeConstructor) = tc.is_poly
is_polymorphic(tc::TypeNamedArgsConstructor) = tc.is_poly

ARROW = "->"

Base.:(==)(a::TypeVariable, b::TypeVariable) = a.id == b.id
Base.:(==)(a::TypeConstructor, b::TypeConstructor) = a.name == b.name && a.arguments == b.arguments
Base.:(==)(a::TypeNamedArgsConstructor, b::TypeNamedArgsConstructor) =
    a.name == b.name && a.arguments == b.arguments && a.output == b.output

Base.hash(a::TypeVariable, h::Core.UInt64) = hash(a.id, h)
Base.hash(a::TypeConstructor, h::Core.UInt64) = hash(a.name, hash(a.arguments, h))
Base.hash(a::TypeNamedArgsConstructor, h::Core.UInt64) = hash(a.name, hash(a.arguments, hash(a.output, h)))

Base.show(io::IO, t::Tp) = print(io, show_type(t, true)...)

show_type(t::TypeVariable, is_return::Bool) = ["t", t.id]
function show_type(t::TypeConstructor, is_return::Bool)
    if isempty(t.arguments)
        [t.name]
    elseif t.name == ARROW
        if is_return
            vcat(show_type(t.arguments[1], false), [" -> "], show_type(t.arguments[2], true))
        else
            vcat(["("], show_type(t.arguments[1], false), [" -> "], show_type(t.arguments[2], true), [")"])
        end
    else
        vcat([t.name, "("], vcat([vcat(show_type(a, true), [", "]) for a in t.arguments]...)[1:end-1], [")"])
    end
end
function show_type(t::TypeNamedArgsConstructor, is_return::Bool)
    if isempty(t.arguments)
        vcat([t.name, "("], show_type(t.output, true), [")"])
    elseif t.name == ARROW
        args = vcat([vcat([k, ":"], show_type(a, false), [" -> "]) for (k, a) in t.arguments]...)[1:end-1]
        if is_return
            vcat(args, [" -> "], show_type(t.output, true))
        else
            vcat(["("], args, [" -> "], show_type(t.output, true), [")"])
        end
    else
        args = vcat([vcat([k, ":"], show_type(a, false), [", "]) for (k, a) in t.arguments]...)[1:end-1]
        vcat([t.name, "("], args, [", "], show_type(t.output, true), [")"])
    end
end

struct Context
    next_variable::Int64
    substitution::Dict{Int64,Tp}
end

empty_context = Context(0, Dict())

Base.:(==)(a::Context, b::Context) = a.next_variable == b.next_variable && a.substitution == b.substitution

Base.hash(a::Context, h::UInt64) = hash(a.next_variable, hash(a.substitution, h))

arrow(arguments...) =
    if length(arguments) == 1
        return arguments[1]
    else
        return TypeConstructor(ARROW, [arguments[1], arrow(arguments[2:end]...)])
    end

isarrow(t::TypeConstructor) = t.name == ARROW
isarrow(t::TypeNamedArgsConstructor) = t.name == ARROW
isarrow(::TypeVariable) = false

t0 = TypeVariable(0)
t1 = TypeVariable(1)
t2 = TypeVariable(2)

tlist(t) = TypeConstructor("list", [t])
ttuple2(t0, t1) = TypeConstructor("tuple2", [t0, t1])
ttuple3(t0, t1, t2) = TypeConstructor("tuple3", [t0, t1, t2])
tset(t) = TypeConstructor("set", [t])

tgrid(t) = TypeConstructor("grid", [t])

baseType(n) = TypeConstructor(n, [])

tint = baseType("int")
treal = baseType("real")
tbool = baseType("bool")
tboolean = tbool  # alias
tcharacter = baseType("char")
tcolor = baseType("color")
tcoord = baseType("coord")

function instantiate(t::TypeVariable, context, bindings = nothing)
    if isnothing(bindings)
        bindings = Dict()
    end
    if haskey(bindings, t.id)
        return (context, bindings[t.id])
    end
    new = TypeVariable(context.next_variable)
    bindings[t.id] = new
    context = Context(context.next_variable + 1, context.substitution)
    return (context, new)
end

function instantiate(t::TypeConstructor, context, bindings = nothing)
    if !t.is_poly
        return context, t
    end
    if isnothing(bindings)
        bindings = Dict()
    end
    new_arguments = []
    for x in t.arguments
        (context, new_x) = instantiate(x, context, bindings)
        push!(new_arguments, new_x)
    end
    return (context, TypeConstructor(t.name, new_arguments))
end

function instantiate(t::TypeNamedArgsConstructor, context, bindings = nothing)
    if !t.is_poly
        return context, t
    end
    if isnothing(bindings)
        bindings = Dict()
    end
    new_arguments = Dict()
    for (k, x) in t.arguments
        (context, new_x) = instantiate(x, context, bindings)
        new_arguments[k] = new_x
    end
    (context, new_output) = instantiate(t.output, context, bindings)
    return (context, TypeNamedArgsConstructor(t.name, new_arguments, new_output))
end

arguments_of_type(t::TypeConstructor) =
    if t.name == ARROW
        return vcat([t.arguments[1]], arguments_of_type(t.arguments[2]))
    else
        return []
    end

arguments_of_type(t::TypeNamedArgsConstructor) =
    if t.name == ARROW
        return vcat(collect(t.arguments), arguments_of_type(t.output))
    else
        return []
    end

arguments_of_type(t::TypeVariable) = []

return_of_type(t::TypeConstructor) =
    if t.name == ARROW
        return_of_type(t.arguments[2])
    else
        t
    end

return_of_type(t::TypeNamedArgsConstructor) =
    if t.name == ARROW
        return_of_type(t.output)
    else
        t
    end

return_of_type(t::TypeVariable) = t

occurs(i::Int64, t::TypeVariable) = t.id == i
occurs(i::Int64, t::TypeConstructor) =
    if !is_polymorphic(t)
        false
    else
        any(occurs(i, ta) for ta in t.arguments)
    end
occurs(i::Int64, t::TypeNamedArgsConstructor) =
    if !is_polymorphic(t)
        false
    else
        any(occurs(i, ta) for ta in t.arguments) || occurs(i, t.output)
    end

struct UnificationFailure <: Exception end

_unify(context, t1::TypeVariable, t2) =
    if t1 == t2
        context
    elseif occurs(t1.id, t2)
        throw(UnificationFailure())
    else
        bindTID(t1.id, t2, context)
    end

_unify(context, t1, t2::TypeVariable) =
    if t1 == t2
        context
    elseif occurs(t2.id, t1)
        throw(UnificationFailure())
    else
        bindTID(t2.id, t1, context)
    end

_unify(context, t1::TypeVariable, t2::TypeVariable) = invoke(_unify, Tuple{Any,TypeVariable,Any}, context, t1, t2)

_unify(context, t1::TypeConstructor, t2::TypeConstructor) =
    if t1.name == t2.name
        for (x1, x2) in zip(t1.arguments, t2.arguments)
            context = unify(context, x1, x2)
        end
        context
    else
        throw(UnificationFailure())
    end

_unify(context, t1::TypeNamedArgsConstructor, t2::TypeNamedArgsConstructor) =
    if t1.name == t2.name
        for (k, x1) in t1.arguments
            context = unify(context, x1, t2.arguments[k])
        end
        context = unify(context, t1.output, t2.output)
        context
    else
        throw(UnificationFailure())
    end

_unify(context, ::TypeNamedArgsConstructor, ::TypeConstructor) = throw(UnificationFailure())
_unify(context, ::TypeConstructor, ::TypeNamedArgsConstructor) = throw(UnificationFailure())

function unify(context, t1, t2)
    (context, t1) = apply_context(context, t1)
    (context, t2) = apply_context(context, t2)
    if (!is_polymorphic(t1)) && (!is_polymorphic(t2))
        if t1 == t2
            context
        else
            throw(UnificationFailure())
        end
    else
        _unify(context, t1, t2)
    end
end

might_unify(t1::TypeVariable, t2) = true
might_unify(t1, t2::TypeVariable) = true
might_unify(t1::TypeVariable, t2::TypeVariable) = true
might_unify(t1::TypeConstructor, t2::TypeConstructor) =
    t1.name == t2.name &&
    length(t1.arguments) == length(t2.arguments) &&
    all(might_unify(as1, as2) for (as1, as2) in zip(t1.arguments, t2.arguments))
might_unify(t1::TypeNamedArgsConstructor, t2::TypeNamedArgsConstructor) =
    t1.name == t2.name &&
    keys(t1.arguments) == keys(t2.arguments) &&
    all(might_unify(as1, t2.arguments[k]) for (k, as1) in t1.arguments) &&
    might_unify(t1.output, t2.output)
might_unify(t1::TypeNamedArgsConstructor, t2::TypeConstructor) = false
might_unify(t1::TypeConstructor, t2::TypeNamedArgsConstructor) = false

is_subtype(parent::TypeVariable, child) = true
is_subtype(parent::TypeVariable, child::TypeVariable) = true
is_subtype(parent, child::TypeVariable) = false
is_subtype(parent::TypeConstructor, child::TypeConstructor) =
    parent.name == child.name &&
    length(parent.arguments) == length(child.arguments) &&
    all(is_subtype(as1, as2) for (as1, as2) in zip(parent.arguments, child.arguments))
is_subtype(parent::TypeNamedArgsConstructor, child::TypeNamedArgsConstructor) =
    parent.name == child.name &&
    keys(parent.arguments) == keys(child.arguments) &&
    all(is_subtype(as1, child.arguments[k]) for (k, as1) in parent.arguments) &&
    is_subtype(parent.output, child.output)
is_subtype(::TypeNamedArgsConstructor, ::TypeConstructor) = false
is_subtype(::TypeConstructor, ::TypeNamedArgsConstructor) = false

function makeTID(context::Context)
    (TypeVariable(context.next_variable), Context(context.next_variable + 1, context.substitution))
end

function lookupTID(context::Context, j)
    @assert (j < context.next_variable)
    get(context.substitution, j, nothing)
end

function bindTID(i, t, context)
    new_substitutions = copy(context.substitution)
    new_substitutions[i] = t
    Context(context.next_variable, new_substitutions)
end

function apply_context(context, t::TypeVariable)
    tp = lookupTID(context, t.id)
    if isnothing(tp)
        (context, t)
    else
        (context, tp2) = apply_context(context, tp)
        context = tp == tp2 ? context : bindTID(t.id, tp2, context)
        (context, tp2)
    end
end

function apply_context(context, t::TypeConstructor)
    if !is_polymorphic(t)
        (context, t)
    end
    new_argtypes = []
    for x in t.arguments
        context, xt = apply_context(context, x)
        push!(new_argtypes, xt)
    end
    (context, TypeConstructor(t.name, new_argtypes))
end

function apply_context(context, t::TypeNamedArgsConstructor)
    if !is_polymorphic(t)
        (context, t)
    end
    new_argtypes = Dict()
    for (k, x) in t.arguments
        context, xt = apply_context(context, x)
        new_argtypes[k] = xt
    end
    context, ot = apply_context(context, t.output)
    (context, TypeNamedArgsConstructor(t.name, new_argtypes, ot))
end

function deserialize_type(message)
    if haskey(message, "index")
        return TypeVariable(message["index"])
    elseif haskey(message, "output")
        return TypeNamedArgsConstructor(
            message["constructor"],
            Dict(key => deserialize_type(value) for (key, value) in message["arguments"]),
            deserialize_type(message["output"]),
        )
    else
        return TypeConstructor(message["constructor"], map(deserialize_type, message["arguments"]))
    end
end

using ParserCombinator

type_parser = Delayed()
parse_number = p"([0-9])+" > (s -> parse(Int64, s))
parse_token = p"([a-zA-Z0-9])+"
parse_tid = E"t" + parse_number > (x -> TypeVariable(x))
parse_tcon_simple = parse_token > (x -> TypeConstructor(x, []))
parse_args_seq = Repeat(type_parser + E", ") + type_parser

parse_tcon = parse_token + E"(" + parse_args_seq + E")" |> (x -> TypeConstructor(x[1], x[2:end]))

parse_tncon = Delayed()
parse_simple_type = parse_tid | parse_tcon | parse_tcon_simple | parse_tncon

parse_function_type = Delayed()
parse_tparam = parse_simple_type | (P"\(" + parse_function_type + P"\)")
parse_tcon_arrow = (parse_tparam+E" -> ")[1:end] + parse_tparam |> (x -> arrow(x...))

parse_named_arg = parse_token + E":" + parse_tparam |> (x -> (x[1], x[2]))

parse_tncon_arrow =
    (parse_named_arg+E" -> ")[1:end] + parse_simple_type |>
    (x -> TypeNamedArgsConstructor(ARROW, Dict(x[1:end-1]), x[end]))

parse_function_type.matcher = parse_tcon_arrow | parse_tncon_arrow

parse_nargs_seq = Repeat(parse_named_arg + E", ") + parse_simple_type
parse_tncon.matcher =
    parse_token + E"(" + parse_nargs_seq + E")" |> (x -> TypeNamedArgsConstructor(x[1], Dict(x[2:end-1]), x[end]))

type_parser.matcher = parse_function_type | parse_simple_type

function parse_type(s)
    parse_one(s, type_parser + Eos())[1]
end

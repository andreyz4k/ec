
abstract type Program <: Function end

struct Index <: Program
    n::Int64
    hash_value::UInt64
    Index(n::Int64) = new(n, hash(n))
end

Base.hash(p::Program, h::UInt64) = p.hash_value ⊻ h
Base.:(==)(p::Index, q::Index) = p.n == q.n

struct Abstraction <: Program
    b::Program
    hash_value::UInt64
    Abstraction(b::Program) = new(b, hash(b))
end
Base.:(==)(p::Abstraction, q::Abstraction) = p.b == q.b

struct Apply <: Program
    f::Program
    x::Program
    hash_value::UInt64
    Apply(f::Program, x::Program) = new(f, x, hash(f, hash(x)))
end
Base.:(==)(p::Apply, q::Apply) = p.f == q.f && p.x == q.x

struct Primitive <: Program
    t::Tp
    name::String
    code::Any
    hash_value::UInt64
    Primitive(t::Tp, name::String, code::Any) = new(t, name, code, hash(name))
end

Base.:(==)(p::Primitive, q::Primitive) = p.name == q.name

every_primitive = Dict{String,Primitive}()

macro define_primitive(name, t, x)
    return quote
        local n = $(esc(name))
        local p = Primitive($(esc(t)), n, $(esc(x)))
        every_primitive[n] = p
    end
end

struct Invented <: Program
    t::Tp
    b::Program
    is_reversible::Bool
    hash_value::UInt64
    Invented(t::Tp, b::Program) = new(t, b, is_reversible(b), hash(b))
end
Base.:(==)(p::Invented, q::Invented) = p.b == q.b

struct Hole <: Program
    t::Tp
    grammar::Any
    locations::Vector{Tuple{Program,Int64}}
    candidates_filter::Any
    possible_values::Any
    hash_value::UInt64
    Hole(t::Tp, grammar::Any, locations, candidates_filter::Any, possible_values) = new(
        t,
        grammar,
        locations,
        candidates_filter,
        possible_values,
        hash(t, hash(grammar, hash(locations, hash(candidates_filter, hash(possible_values))))),
    )
end

Base.:(==)(p::Hole, q::Hole) =
    p.t == q.t &&
    p.grammar == q.grammar &&
    p.locations == q.locations &&
    p.candidates_filter == q.candidates_filter &&
    p.possible_values == q.possible_values

struct FreeVar <: Program
    t::Tp
    var_id::Union{UInt64,Nothing,String}
    location::Union{Nothing,Tuple{Program,Int64}}
    hash_value::UInt64
    FreeVar(t::Tp, var_id::Union{UInt64,Nothing,String}, location::Union{Nothing,Tuple{Program,Int64}}) =
        new(t, var_id, location, hash(t, hash(var_id, hash(location))))
end
Base.:(==)(p::FreeVar, q::FreeVar) = p.t == q.t && p.var_id == q.var_id && p.location == q.location

struct SetConst <: Program
    t::Tp
    value::Any
    hash_value::UInt64
    SetConst(t::Tp, value::Any) = new(t, value, hash(t, hash(value)))
end
Base.:(==)(p::SetConst, q::SetConst) = p.t == q.t && p.value == q.value

struct LetClause <: Program
    var_id::UInt64
    var_type::Tp
    v::Program
    b::Program
    hash_value::UInt64
    LetClause(var_id::UInt64, var_type::Tp, v::Program, b::Program) =
        new(var_id, var_type, v, b, hash(var_id, hash(v, hash(b))))
end
Base.:(==)(p::LetClause, q::LetClause) = p.var_id == q.var_id && p.v == q.v && p.b == q.b

struct LetRevClause <: Program
    var_ids::Vector{UInt64}
    inp_var_id::Union{UInt64,String}
    v::Program
    b::Program
    hash_value::UInt64
    LetRevClause(var_ids::Vector{UInt64}, inp_var_id::Union{UInt64,String}, v::Program, b::Program) =
        new(var_ids, inp_var_id, v, b, hash(var_ids, hash(inp_var_id, hash(v, hash(b)))))
end
Base.:(==)(p::LetRevClause, q::LetRevClause) =
    p.var_ids == q.var_ids && p.inp_var_id == q.inp_var_id && p.v == q.v && p.b == q.b

Base.show(io::IO, p::Program) = print(io, show_program(p, false)...)
Base.print(io::IO, p::Program) = print(io, show_program(p, false)...)

show_program(p::Index, is_function::Bool) = ["\$", p.n]
show_program(p::Abstraction, is_function::Bool) = vcat(["(lambda "], show_program(p.b, false), [")"])
show_program(p::Apply, is_function::Bool) =
    if is_function
        vcat(show_program(p.f, true), [" "], show_program(p.x, false))
    else
        vcat(["("], show_program(p.f, true), [" "], show_program(p.x, false), [")"])
    end
show_program(p::Primitive, is_function::Bool) = [p.name]
show_program(p::FreeVar, is_function::Bool) =
    isnothing(p.var_id) ? vcat(["FREE_VAR("], show_type(p.t, true), [")"]) :
    ["\$", (isa(p.var_id, UInt64) ? "v" : ""), "$(p.var_id)"]
show_program(p::Hole, is_function::Bool) = ["??(", p.t, ")"]
show_program(p::Invented, is_function::Bool) = vcat(["#"], show_program(p.b, false))
show_program(p::SetConst, is_function::Bool) = vcat(["Const("], show_type(p.t, true), [", ", p.value, ")"])
show_program(p::LetClause, is_function::Bool) = vcat(
    ["let \$v$(p.var_id)::"],
    show_type(p.var_type, true),
    [" = "],
    show_program(p.v, false),
    [" in "],
    show_program(p.b, false),
)
show_program(p::LetRevClause, is_function::Bool) = vcat(
    [
        "let ",
        join(["\$v$v" for v in p.var_ids], ", "),
        " = rev(\$",
        (isa(p.inp_var_id, UInt64) ? "v" : ""),
        "$(p.inp_var_id) = ",
    ],
    show_program(p.v, false),
    [") in "],
    show_program(p.b, false),
)

abstract type AbstractProgramBlock end

struct ProgramBlock <: AbstractProgramBlock
    p::Program
    type::Tp
    cost::Float64
    input_vars::Vector{UInt64}
    output_var::UInt64
    is_reversible::Bool
end

Base.show(io::IO, block::ProgramBlock) = print(
    io,
    "ProgramBlock(",
    block.p,
    ", ",
    block.type,
    ", ",
    block.cost,
    ", ",
    block.input_vars,
    ", ",
    string(block.output_var),
    ")",
)

Base.:(==)(block::ProgramBlock, other::ProgramBlock) =
    block.p == other.p &&
    block.type == other.type &&
    block.cost == other.cost &&
    block.input_vars == other.input_vars &&
    block.output_var == other.output_var

Base.hash(block::ProgramBlock, h::UInt64) =
    hash(block.p, hash(block.type, hash(block.cost, hash(block.input_vars, hash(block.output_var, h)))))

struct ReverseProgramBlock <: AbstractProgramBlock
    p::Program
    cost::Float64
    input_vars::Vector{UInt64}
    output_vars::Vector{UInt64}
end

Base.show(io::IO, block::ReverseProgramBlock) =
    print(io, "ReverseProgramBlock(", block.p, ", ", block.cost, ", ", block.input_vars, ", ", block.output_vars, ")")

Base.:(==)(block::ReverseProgramBlock, other::ReverseProgramBlock) =
    block.p == other.p &&
    block.cost == other.cost &&
    block.input_vars == other.input_vars &&
    block.output_vars == other.output_vars

Base.hash(block::ReverseProgramBlock, h::UInt64) =
    hash(block.p, hash(block.cost, hash(block.input_vars, hash(block.output_vars, h))))

struct UnknownPrimitive <: Exception
    name::String
end

function lookup_primitive(name)
    if haskey(every_primitive, name)
        every_primitive[name]
    else
        throw(UnknownPrimitive(name))
    end
end

function infer_program_type(context, environment, p::Index)::Tuple{Context,Tp}
    t = environment[p.n+1]
    if isnothing(t)
        throw(UnboundVariable())
    else
        apply_context(context, t)
    end
end

infer_program_type(context, environment, p::Primitive)::Tuple{Context,Tp} = instantiate(p.t, context)

infer_program_type(context, environment, p::Invented)::Tuple{Context,Tp} = instantiate(p.t, context)

function infer_program_type(context, environment, p::Abstraction)::Tuple{Context,Tp}
    (xt, context) = makeTID(context)
    (context, rt) = infer_program_type(context, vcat([xt], environment), p.b)
    apply_context(context, arrow(xt, rt))
end

function infer_program_type(context, environment, p::Apply)::Tuple{Context,Tp}
    (rt, context) = makeTID(context)
    (context, xt) = infer_program_type(context, environment, p.x)
    (context, ft) = infer_program_type(context, environment, p.f)
    context = unify(context, ft, arrow(xt, rt))
    if isnothing(context)
        error("Unification failed")
    end
    apply_context(context, rt)
end

infer_program_type(context, environment, p::FreeVar)::Tuple{Context,Tp} = instantiate(p.t, context)
infer_program_type(context, environment, p::SetConst)::Tuple{Context,Tp} = instantiate(p.t, context)

closed_inference(p) = infer_program_type(empty_context, [], p)[2]

using ParserCombinator

parse_token = p"([a-zA-Z0-9_\-+*/'.<>|@?])+"

parse_whitespace = Drop(Star(Space()))

parse_number = p"([0-9])+" > (s -> parse(Int64, s))

parse_var_name = (E"v" + p"([0-9])+" > (s -> parse(UInt64, s))) | (p"([a-zA-Z0-9])+" > (s -> string(s)))

using AutoHashEquals
@auto_hash_equals mutable struct MatchPrimitive <: Delegate
    name::Symbol
    matcher::Matcher

    MatchPrimitive(matcher) = new(:MatchPrimitive, matcher)
end

@auto_hash_equals struct MatchPrimitiveState <: DelegateState
    state::State
end

function ParserCombinator.success(k::Config, m::MatchPrimitive, s, t, i, r::Value)
    try
        result = lookup_primitive(r[1])
        Success(MatchPrimitiveState(t), i, Any[result])
    catch e
        if isa(e, InterruptException)
            rethrow()
        end
        # @error "Error finding type of primitive $(r[1])"
        FAILURE
    end
end
parse_primitive = MatchPrimitive(parse_token)

parse_variable = P"\$" + parse_number > Index

parse_free_variable = P"\$" + parse_var_name > (v -> FreeVar(t0, v, nothing))

parse_fixed_real = P"real" + parse_token > (v -> Primitive(treal, "real", parse(Float64, v)))

_parse_program = Delayed()

struct UnboundVariable <: Exception end

parse_invented =
    P"#" + _parse_program > (p -> begin
        t = try
            infer_program_type(empty_context, [], p)[2]
        catch e
            if isa(e, ErrorException) || isa(e, UnboundVariable)
                bt = catch_backtrace()
                @warn "WARNING: Could not type check invented $p" exception = (e, bt)
                t0
            else
                rethrow()
            end
        end

        Invented(t, p)
    end)

parse_abstraction = P"\(lambda " + parse_whitespace + _parse_program + P"\)" > Abstraction

parse_application = P"\(" + Repeat(_parse_program + parse_whitespace, 2, ALL) + P"\)" |> (xs -> foldl(Apply, xs))

parse_let_clause =
    P"let " +
    P"\$v" +
    parse_number +
    P"::" +
    type_parser +
    P" = " +
    _parse_program +
    P" in" +
    parse_whitespace +
    _parse_program |> (v -> LetClause(UInt64(v[1]), v[2], v[3], v[4]))

parse_var_name_list = (E"$"+parse_var_name+E", ")[0:end] + E"$" + parse_var_name |> (vs -> [v for v in vs])

parse_let_rev_clause =
    P"let " +
    parse_var_name_list +
    P" = rev\(\$" +
    parse_var_name +
    P" = " +
    _parse_program +
    P"\) in" +
    parse_whitespace +
    _parse_program |> (v -> LetRevClause(v[1], v[2], v[3], v[4]))

julia_type_def = Delayed()
julia_type_def.matcher = parse_token | (parse_token + e"{" + (julia_type_def+e",")[0:end] + julia_type_def + e"}")

parse_object = Delayed()
parse_object.matcher =
    parse_token |
    (parse_token + Opt(e"{" + julia_type_def + e"}") + e"(" + (parse_object+e", ")[0:end] + parse_object + e")") |
    (parse_token + Opt(e"{" + julia_type_def + e"}") + e"()") |
    (e"[" + (parse_object+e", ")[0:end] + parse_object + e"]") |
    (e"[" + (parse_object+Opt(e";")+e" ")[0:end] + parse_object + e"]") |
    (e"[]") |
    (e"(" + (parse_object+e", ")[0:end] + parse_object + e")") |
    (parse_token + Opt(e"{" + julia_type_def + e"}") + e"[" + (parse_object+e", ")[0:end] + parse_object + e"]") |
    (parse_token + Opt(e"{" + julia_type_def + e"}") + e"[]") |> (vs -> eval(Meta.parse(join(vs, ""))))

parse_const_clause = P"Const\(" + type_parser + P", " + parse_object + P"\)" |> (v -> SetConst(v[1], v[2]))

parse_hole = P"\?\?\(" + type_parser + P"\)" > (t -> Hole(t, nothing, [], nothing, nothing))

_parse_program.matcher =
    parse_application |
    parse_variable |
    parse_invented |
    parse_abstraction |
    parse_primitive |
    parse_fixed_real |
    parse_free_variable |
    parse_let_clause |
    parse_let_rev_clause |
    parse_const_clause |
    parse_hole

function parse_program(s)
    parse_one(s, _parse_program)[1]
end

number_of_free_parameters(p::Invented) = number_of_free_parameters(p.b)
number_of_free_parameters(p::Abstraction) = number_of_free_parameters(p.b)
number_of_free_parameters(p::Apply) = number_of_free_parameters(p.f) + number_of_free_parameters(p.x)
number_of_free_parameters(p::FreeVar) = 1

const free_param_keys = Set(["REAL", "STRING", "r_const"])

number_of_free_parameters(p::Primitive) =
    if in(p.name, free_param_keys)
        1
    else
        0
    end
number_of_free_parameters(::Index) = 0
number_of_free_parameters(::SetConst) = 0

application_function(p::Apply) = application_function(p.f)
application_function(p::Program) = p

application_parse(p) = _application_parse(p, Program[])

function _application_parse(p::Apply, arguments)
    push!(arguments, p.x)
    _application_parse(p.f, arguments)
end
_application_parse(p::Program, args) = (p, reverse(args))

struct BoundAbstraction <: Function
    p::Abstraction
    arguments::Vector{Any}
    workspace::Dict{Any,Any}
end

function (p::Abstraction)(environment, workspace)
    return BoundAbstraction(p, environment, workspace)
end
(p::BoundAbstraction)(x) = p.p.b(vcat(p.arguments, [x]), p.workspace)

(p::Index)(environment, workspace) = environment[end-p.n]

(p::FreeVar)(environment, workspace) = workspace[p.var_id]

(p::Primitive)(environment, workspace) = p.code

(p::Invented)(environment, workspace) = p.b(environment, workspace)

function wrap_any_object_call(f)
    # Should I put this in @define_primitive macro?
    function _inner(x)
        try
            r = f(x)
            if r isa Function
                return wrap_any_object_call(r)
            else
                return _wrap_wildcard(r)
            end
        catch e
            if e isa MethodError && any(arg === any_object for arg in e.args)
                if x === any_object
                    return PatternWrapper(any_object)
                else
                    error("MethodError with any_object")
                end
            else
                rethrow()
            end
        end
    end
    return _inner
end

function (p::Apply)(environment, workspace)
    if isa(p.f, Apply) && isa(p.f.f, Apply) && isa(p.f.f.f, Primitive) && p.f.f.f.name == "if"
        branch = p.f.f.x(environment, workspace)
        if branch
            p.f.x(environment, workspace)
        else
            p.x(environment, workspace)
        end
    else
        f = p.f(environment, workspace)
        x = p.x(environment, workspace)
        if x === nothing
            error("Parameter is nothing")
        elseif x isa PatternWrapper
            return wrap_any_object_call(f)(x.value)
            # if x.value === any_object
            #     return wrap_any_object_call(f)(x.value)
            # else
            #     try
            #         return _wrap_wildcard(f(x.value))
            #     catch e
            #         if e isa MethodError && any(arg === any_object for arg in e.args)
            #             error("MethodError with any_object")
            #         end
            #         rethrow()
            #     end
            # end
        else
            try
                return f(x)
            catch e
                if e isa MethodError && any(arg === any_object for arg in e.args)
                    error("MethodError with any_object")
                end
                rethrow()
            end
        end
    end
end

(p::SetConst)(environment, workspace) = p.value

function (p::LetClause)(environment, workspace)
    v = p.v(environment, workspace)
    workspace[p.var_id] = v
    b = p.b(environment, workspace)
    delete!(workspace, p.var_id)
    return b
end

function (p::LetRevClause)(environment, workspace)
    vals = run_in_reverse(p.v, workspace[p.inp_var_id])
    for (k, v) in vals
        if isa(v, EitherOptions) || isa(v, AbductibleValue)
            @error p.v
            @error workspace[p.inp_var_id]
            error("LetRevClause $p cannot return wildcard $k $v")
        end
        workspace[k] = v
    end
    b = p.b(environment, workspace)
    for var_id in p.var_ids
        delete!(workspace, var_id)
    end
    return b
end

function run_with_arguments(p::Program, arguments, workspace)
    l = p([], workspace)
    for x in arguments
        l = l(x)
    end
    return l
end

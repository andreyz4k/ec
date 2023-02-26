
abstract type Program end

struct Index <: Program
    n::Int64
end

Base.hash(p::Index, h::UInt64) = hash(p.n, h)
Base.:(==)(p::Index, q::Index) = p.n == q.n

struct Abstraction <: Program
    b::Program
end
Base.hash(p::Abstraction, h::UInt64) = hash(p.b, h)
Base.:(==)(p::Abstraction, q::Abstraction) = p.b == q.b

struct Apply <: Program
    f::Program
    x::Program
end
Base.hash(p::Apply, h::UInt64) = hash(p.f, hash(p.x, h))
Base.:(==)(p::Apply, q::Apply) = p.f == q.f && p.x == q.x

struct Primitive <: Program
    t::Tp
    name::String
    code::Any
end

Base.hash(p::Primitive, h::UInt64) = hash(p.name, h)
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
end
Base.hash(p::Invented, h::UInt64) = hash(p.b, h)
Base.:(==)(p::Invented, q::Invented) = p.b == q.b

struct Hole <: Program
    t::Tp
    grammar::Any
    abstractors_only::Bool
end
Base.hash(p::Hole, h::UInt64) = hash(p.t, hash(p.grammar, h))
Base.:(==)(p::Hole, q::Hole) = p.t == q.t && p.grammar == q.grammar && p.abstractors_only == q.abstractors_only

struct FreeVar <: Program
    t::Tp
    var_id::Union{UInt64,Nothing,String}
end
Base.hash(p::FreeVar, h::UInt64) = hash(p.t, hash(p.var_id, h))
Base.:(==)(p::FreeVar, q::FreeVar) = p.t == q.t && p.var_id == q.var_id

struct SetConst <: Program
    t::Tp
    value::Any
end
Base.hash(p::SetConst, h::UInt64) = hash(p.t, hash(p.value, h))
Base.:(==)(p::SetConst, q::SetConst) = p.t == q.t && p.value == q.value

struct LetClause <: Program
    var_id::UInt64
    var_type::Tp
    v::Program
    b::Program
end
Base.hash(p::LetClause, h::UInt64) = hash(p.var_id, h) + hash(p.v, h) + hash(p.b, h)
Base.:(==)(p::LetClause, q::LetClause) = p.var_id == q.var_id && p.v == q.v && p.b == q.b

struct LetRevClause <: Program
    var_ids::Vector{UInt64}
    inp_var_id::Union{UInt64,String}
    v::Program
    rev_v::Any
    b::Program
end
Base.hash(p::LetRevClause, h::UInt64) = hash(p.var_ids, h) + hash(p.v, h) + hash(p.b, h)
Base.:(==)(p::LetRevClause, q::LetRevClause) = p.var_ids == q.var_ids && p.v == q.v && p.b == q.b

struct WrapEither <: Program
    var_ids::Vector{UInt64}
    inp_var_id::Union{UInt64,String}
    fixer_var_id::UInt64
    v::Program
    rev_v::Any
    f::FreeVar
    b::Program
end
Base.hash(p::WrapEither, h::UInt64) =
    hash(p.var_ids, hash(p.inp_var_id, hash(p.fixer_var_id, hash(p.v, hash(p.f, hash(p.b, h))))))
Base.:(==)(p::WrapEither, q::WrapEither) =
    p.var_ids == q.var_ids &&
    p.inp_var_id == q.inp_var_id &&
    p.fixer_var_id == q.fixer_var_id &&
    p.v == q.v &&
    p.f == q.f &&
    p.b == q.b

struct ExceptionProgram <: Program end

Base.show(io::IO, p::Program) = print(io, show_program(p, false)...)

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
show_program(p::WrapEither, is_function::Bool) = vcat(
    [
        "let ",
        join(["\$v$v" for v in p.var_ids], ", "),
        " = wrap(let ",
        join(["\$v$v" for v in p.var_ids], ", "),
        " = rev(\$",
        (isa(p.inp_var_id, UInt64) ? "v" : ""),
        "$(p.inp_var_id) = ",
    ],
    show_program(p.v, false),
    ["); let \$v$(p.fixer_var_id) = "],
    show_program(p.f, false),
    [") in "],
    show_program(p.b, false),
)
show_program(p::ExceptionProgram, is_function::Bool) = ["EXCEPTION"]

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
    block.output_var,
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
    reverse_program::Any
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

struct WrapEitherBlock <: AbstractProgramBlock
    main_block::ReverseProgramBlock
    fixer_var::UInt64
    cost::Float64
    input_vars::Vector{UInt64}
    output_vars::Vector{UInt64}
end

Base.:(==)(block::WrapEitherBlock, other::WrapEitherBlock) =
    block.main_block == other.main_block &&
    block.fixer_var == other.fixer_var &&
    block.cost == other.cost &&
    block.input_vars == other.input_vars &&
    block.output_vars == other.output_vars

Base.hash(block::WrapEitherBlock, h::UInt64) =
    hash(block.main_block, hash(block.fixer_var, hash(block.cost, hash(block.input_vars, hash(block.output_vars, h)))))

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

using ParserCombinator

parse_token = p"([a-zA-Z0-9_\-+*/',.<>|@?])+"

parse_whitespace = Drop(Star(Space()))

parse_number = p"([0-9])+" > (s -> parse(Int64, s))

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
        # @error "Error finding type of primitive $(r[1])"
        FAILURE
    end
end
parse_primitive = MatchPrimitive(parse_token)

parse_variable = P"\$" + parse_number > Index

parse_fixed_real = P"real" + parse_token > (v -> Primitive(treal, "real", parse(Float64, v)))

_parse_program = Delayed()

parse_invented = P"#" + _parse_program > (p -> begin
    t = try
        infer_program_type(empty_context, [], p)[2]
    catch e
        if isa(e, UnificationFailure) || isa(e, UnboundVariable)
            @warn "WARNING: Could not type check invented $p"
            t0
        else
            rethrow()
        end
    end

    Invented(t, p)
end)

parse_abstraction = P"\(lambda " + parse_whitespace + _parse_program + P"\)" > Abstraction

parse_application = P"\(" + Repeat(_parse_program + parse_whitespace, 2, ALL) + P"\)" |> (xs -> foldl(Apply, xs))

parse_exception = P"exception" > ExceptionProgram

_parse_program.matcher =
    parse_application |
    parse_exception |
    parse_variable |
    parse_invented |
    parse_abstraction |
    parse_primitive |
    parse_fixed_real

function parse_program(s)
    parse_one(s, _parse_program)[1]
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
    apply_context(context, rt)
end

infer_program_type(context, environment, p::FreeVar) = instantiate(p.t, context)

infer_program_type(context, environment, p::ExceptionProgram) = instantiate(t0, context)

closed_inference(p) = infer_program_type(empty_context, [], p)[2]

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

application_function(p::Apply) = application_function(p.f)
application_function(p::Program) = p

application_parse(p) = _application_parse(p, Program[])

function _application_parse(p::Apply, arguments)
    push!(arguments, p.x)
    _application_parse(p.f, arguments)
end
_application_parse(p::Program, args) = (p, reverse(args))

function analyze_evaluation(p::Abstraction)::Function
    b = analyze_evaluation(p.b)
    (environment, workspace) -> (x -> (b(vcat([x], environment), workspace)))
end

function _run_with_arguments(p::Abstraction, arguments, workspace)
    x -> begin
        inner_args = vcat(arguments, [x])
        res = _run_with_arguments(p.b, inner_args, workspace)
        return res
    end
end

analyze_evaluation(p::Index)::Function = (environment, workspace) -> environment[p.n+1]
_run_with_arguments(p::Index, environment, workspace) = environment[end-p.n]

analyze_evaluation(p::FreeVar)::Function = (environment, workspace) -> workspace[p.var_id]
_run_with_arguments(p::FreeVar, environment, workspace) = workspace[p.var_id]

analyze_evaluation(p::Primitive)::Function = (_, _) -> p.code
_run_with_arguments(p::Primitive, environment, workspace) = p.code

function analyze_evaluation(p::Invented)::Function
    b = analyze_evaluation(p.b)
    (_, _) -> b([], Dict())
end
_run_with_arguments(p::Invented, environment, workspace) = _run_with_arguments(p.b, environment, workspace)

function analyze_evaluation(p::Apply)::Function
    if isa(p.f, Apply) && isa(p.f.f, Apply) && isa(p.f.f.f, Primitive) && p.f.f.f.name == "if"
        branch = analyze_evaluation(p.f.f.x)
        yes = analyze_evaluation(p.f.x)
        no = analyze_evaluation(p.x)
        return (environment, workspace) ->
            (branch(environment, workspace) ? yes(environment, workspace) : no(environment, workspace))
    else
        f = analyze_evaluation(p.f)
        x = analyze_evaluation(p.x)
        (environment, workspace) -> (f(environment, workspace)(x(environment, workspace)))
    end
end

function _run_with_arguments(p::Apply, arguments, workspace)
    if isa(p.f, Apply) && isa(p.f.f, Apply) && isa(p.f.f.f, Primitive) && p.f.f.f.name == "if"
        branch = _run_with_arguments(p.f.f.x, arguments, workspace)
        if branch
            _run_with_arguments(p.f.x, arguments, workspace)
        else
            _run_with_arguments(p.x, arguments, workspace)
        end
    else
        f = _run_with_arguments(p.f, arguments, workspace)
        x = _run_with_arguments(p.x, arguments, workspace)
        return f(x)
    end
end

analyze_evaluation(p::SetConst)::Function = (_, _) -> p.value
_run_with_arguments(p::SetConst, environment, workspace) = p.value

function analyze_evaluation(p::LetClause)::Function
    v = analyze_evaluation(p.v)
    b = analyze_evaluation(p.b)
    (environment, workspace) -> b(environment, merge(workspace, Dict(p.var_id => v(environment, workspace))))
end

function _run_with_arguments(p::LetClause, arguments, workspace)
    v = _run_with_arguments(p.v, arguments, workspace)
    workspace[p.var_id] = v
    b = _run_with_arguments(p.b, arguments, workspace)
    delete!(workspace, p.var_id)
    return b
end

function analyze_evaluation(p::LetRevClause)::Function
    b = analyze_evaluation(p.b)
    (environment, workspace) -> begin
        vals = p.rev_v(workspace[p.inp_var_id])
        for i in 1:length(p.var_ids)
            workspace[p.var_ids[i]] = vals[i]
        end
        res = b(environment, workspace)
        for var_id in p.var_ids
            delete!(workspace, var_id)
        end
        return res
    end
end

function _run_with_arguments(p::LetRevClause, arguments, workspace)
    vals = p.rev_v(workspace[p.inp_var_id])
    for i in 1:length(p.var_ids)
        workspace[p.var_ids[i]] = vals[i]
    end
    b = _run_with_arguments(p.b, arguments, workspace)
    for var_id in p.var_ids
        delete!(workspace, var_id)
    end
    return b
end

function analyze_evaluation(p::WrapEither)::Function
    b = analyze_evaluation(p.b)
    f = analyze_evaluation(p.f)
    (environment, workspace) -> begin
        vals = p.rev_v(workspace[p.inp_var_id])
        unfixed_vals = Dict()
        for i in 1:length(p.var_ids)
            unfixed_vals[p.var_ids[i]] = vals[i]
        end
        fixed_val = f(environment, workspace)

        fixed_hashes = [_get_fixed_hashes(unfixed_vals[p.fixer_var_id], fixed_val)]

        fixed_values = Dict()
        for (var_id, target_value) in unfixed_vals
            if var_id == p.fixer_var_id
                fixed_values[var_id] = fixed_val
            else
                fixed_values[var_id] = _fix_option_hashes(fixed_hashes, [target_value])[1]
            end
        end

        b(environment, merge(workspace, fixed_values))
    end
end

function _run_with_arguments(p::WrapEither, arguments, workspace)
    vals = p.rev_v(workspace[p.inp_var_id])
    unfixed_vals = Dict()
    for i in 1:length(p.var_ids)
        unfixed_vals[p.var_ids[i]] = vals[i]
    end
    fixed_val = _run_with_arguments(p.f, arguments, workspace)

    fixed_hashes = [_get_fixed_hashes(unfixed_vals[p.fixer_var_id], fixed_val)]

    fixed_values = Dict()
    for (var_id, target_value) in unfixed_vals
        if var_id == p.fixer_var_id
            fixed_values[var_id] = fixed_val
        else
            fixed_values[var_id] = _fix_option_hashes(fixed_hashes, [target_value])[1]
        end
    end

    merge!(workspace, fixed_values)
    b = _run_with_arguments(p.b, arguments, workspace)
    for var_id in p.var_ids
        delete!(workspace, var_id)
    end
    return b
end

function analyze_evaluation(p::ExceptionProgram)::Function
    (environment, workspace) -> error("Inapplicable program")
end

function run_with_arguments(p::Program, arguments, workspace)
    l = _run_with_arguments(p, [], workspace)
    for x in arguments
        l = l(x)
    end
    return l
end

function run_analyzed_with_arguments(@nospecialize(p::Function), arguments, workspace)
    l = p([], workspace)
    for x in arguments
        l = l(x)
    end
    return l
end

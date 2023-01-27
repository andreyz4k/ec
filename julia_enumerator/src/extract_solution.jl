
block_to_let(block::ProgramBlock, output) = LetClause(block.output_var, block.p, output)
block_to_let(block::ReverseProgramBlock, output) =
    LetRevClause(block.output_vars, block.input_vars[1], block.p, block.reverse_program, output)

function block_to_let(block::WrapEitherBlock, output)
    WrapEither(
        block.output_vars,
        block.input_vars[1],
        block.fixer_var,
        block.main_block.p,
        block.main_block.reverse_program,
        FreeVar(t0, block.input_vars[2]),
        output,
    )
end

function extract_solution(sc::SolutionContext, solution_path::Path)
    res = [sc.blocks[bl_id] for bl_id in extract_block_sequence(solution_path)]
    # @info res
    cost = sum(block.cost for block in res)
    output = res[end].p
    for block in view(res, length(res)-1:-1:1)
        output = block_to_let(block, output)
    end
    # @info output
    # Renaming variables for comparison between programs and remove variables copying
    output = alpha_substitution(output, Dict{UInt64,Any}(), UInt64(1), sc.input_keys)[1]
    # @info output
    return (output, cost)
end

function alpha_substitution(p::LetClause, replacements, next_index::UInt64, input_keys)
    if isa(p.v, FreeVar)
        if haskey(input_keys, p.v.var_id)
            replacements[p.var_id] = input_keys[p.v.var_id]
        elseif haskey(replacements, p.v.var_id)
            replacements[p.var_id] = replacements[p.v.var_id]
        else
            replacements[p.var_id] = p.v.var_id
        end
        return alpha_substitution(p.b, replacements, next_index, input_keys)
    elseif isa(p.b, FreeVar) && p.b.var_id == p.var_id
        return alpha_substitution(p.v, replacements, next_index, input_keys)
    else
        new_v, next_index = alpha_substitution(p.v, replacements, next_index, input_keys)
        replacements[p.var_id] = next_index
        new_b, next_index2 = alpha_substitution(p.b, replacements, next_index + 1, input_keys)
        return LetClause(next_index, new_v, new_b), next_index2
    end
end

function alpha_substitution(p::LetRevClause, replacements, next_index::UInt64, input_keys)
    new_var_ids = []
    for var_id in p.var_ids
        replacements[var_id] = next_index
        push!(new_var_ids, next_index)
        next_index += 1
    end
    new_v, next_index = alpha_substitution(p.v, replacements, next_index, input_keys)
    if haskey(input_keys, p.inp_var_id)
        new_inp_var_id = input_keys[p.inp_var_id]
    elseif haskey(replacements, p.inp_var_id)
        new_inp_var_id = replacements[p.inp_var_id]
    else
        new_inp_var_id = p.inp_var_id
    end
    new_b, next_index = alpha_substitution(p.b, replacements, next_index, input_keys)
    return LetRevClause(new_var_ids, new_inp_var_id, new_v, p.rev_v, new_b), next_index
end

function alpha_substitution(p::WrapEither, replacements, next_index::UInt64, input_keys)
    new_var_ids = []
    for var_id in p.var_ids
        replacements[var_id] = next_index
        push!(new_var_ids, next_index)
        next_index += 1
    end
    new_fixer_var_id = replacements[p.fixer_var_id]
    new_v, next_index = alpha_substitution(p.v, replacements, next_index, input_keys)
    if haskey(input_keys, p.inp_var_id)
        new_inp_var_id = input_keys[p.inp_var_id]
    elseif haskey(replacements, p.inp_var_id)
        new_inp_var_id = replacements[p.inp_var_id]
    else
        new_inp_var_id = p.inp_var_id
    end
    new_f, next_index = alpha_substitution(p.f, replacements, next_index, input_keys)
    new_b, next_index = alpha_substitution(p.b, replacements, next_index, input_keys)
    return WrapEither(new_var_ids, new_inp_var_id, new_fixer_var_id, new_v, p.rev_v, new_f, new_b), next_index
end

function alpha_substitution(p::FreeVar, replacements, next_index::UInt64, input_keys)
    if haskey(input_keys, p.var_id)
        return FreeVar(p.t, input_keys[p.var_id]), next_index
    elseif haskey(replacements, p.var_id)
        return FreeVar(p.t, replacements[p.var_id]), next_index
    else
        return p, next_index
    end
end

function alpha_substitution(p::Abstraction, replacements, next_index::UInt64, input_keys)
    new_b, next_index = alpha_substitution(p.b, replacements, next_index, input_keys)
    Abstraction(new_b), next_index
end

function alpha_substitution(p::Apply, replacements, next_index::UInt64, input_keys)
    new_f, next_index = alpha_substitution(p.f, replacements, next_index, input_keys)
    new_x, next_index = alpha_substitution(p.x, replacements, next_index, input_keys)
    return Apply(new_f, new_x), next_index
end

alpha_substitution(p::Program, replacements, next_index::UInt64, input_keys) = p, next_index

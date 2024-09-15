
struct DummyGuidingModel
    grammars::Dict{Any,ContextualGrammar}
end

function DummyGuidingModel()
    return DummyGuidingModel(Dict())
end

function run_guiding_model(guiding_model::DummyGuidingModel, model_inputs)
    grammar_len = length(model_inputs[1])
    result = [0.0 for _ in 1:grammar_len]
    result[end-1:end] = [-3.0, -3.0]
    return result
end

function generate_grammar(sc, guiding_model::DummyGuidingModel, grammar, entry_id, is_known)
    if !haskey(guiding_model.grammars, grammar)
        log_variable = 0.0
        log_lambda = -3.0
        log_free_var = -3.0
        productions = Tuple{Program,Tp,Float64}[(p, p.t, 0.0) for p in grammar]
        g = Grammar(log_variable, log_lambda, log_free_var, productions, nothing)
        guiding_model.grammars[grammar] = make_dummy_contextual(g)
    end
    return guiding_model.grammars[grammar]
end

function update_guiding_model(guiding_model::DummyGuidingModel, traces)
    return guiding_model
end

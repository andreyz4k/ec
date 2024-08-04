
struct DummyGuidingModel
    grammar::ContextualGrammar
end

function DummyGuidingModel(base_grammar::Dict)
    log_variable = 0.0
    log_lambda = -3.0
    log_free_var = -3.0
    productions = Tuple{Program,Tp,Float64}[(p, p.t, 0.0) for p in values(base_grammar)]
    g = Grammar(log_variable, log_lambda, log_free_var, productions, nothing)
    grammar = make_dummy_contextual(g)
    return DummyGuidingModel(grammar)
end

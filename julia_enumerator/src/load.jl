
function load_problems(message)
    grammar_payload = message["DSL"]
    # try
    g = deserialize_grammar(grammar_payload)
    grammar = make_dummy_contextual(g)
    # catch
    #     grammar = deserialize_contextual_grammar(grammar_payload)
    # end
    type_weights = message["type_weights"]
    # hyperparameters = message["hyperparameters"]
    hyperparameters = Dict{String,Any}("path_cost_power" => 1.0, "complexity_power" => 1.0, "block_cost_power" => 1.0)
    type_weights["any"] = 0.0
    # hyperparameters = Dict{String,Any}("path_cost_power" => 3.0, "complexity_power" => 1.0, "block_cost_power" => 1.0)
    # type_weights["any"] = 0.0
    # hyperparameters = Dict{String,Any}("path_cost_power" => 3.0, "complexity_power" => 2.0, "block_cost_power" => 1.0)
    # type_weights["any"] = 0.0
    # hyperparameters = Dict{String,Any}("path_cost_power" => 3.0, "complexity_power" => 3.0, "block_cost_power" => 1.0)
    # type_weights["any"] = 0.0
    # hyperparameters = Dict{String,Any}("path_cost_power" => 5.0, "complexity_power" => 1.0, "block_cost_power" => 1.0)
    # type_weights["any"] = 0.1
    # hyperparameters = Dict{String,Any}("path_cost_power" => 5.0, "complexity_power" => 1.0, "block_cost_power" => 2.0)
    # type_weights["any"] = 0.5
    # hyperparameters = Dict{String,Any}("path_cost_power" => 5.0, "complexity_power" => 1.0, "block_cost_power" => 2.0)
    # type_weights["any"] = 2.0
    # hyperparameters = Dict{String,Any}("path_cost_power" => 5.0, "complexity_power" => 2.0, "block_cost_power" => 2.0)
    # type_weights["any"] = 0.0
    # hyperparameters = Dict{String,Any}("path_cost_power" => 5.0, "complexity_power" => 2.0, "block_cost_power" => 2.0)
    # type_weights["any"] = 2.0
    if haskey(message, "programTimeout")
        program_timeout = message["programTimeout"]
    else
        program_timeout = 0.1
        @warn "(julia) WARNING: programTimeout not set. Defaulting to $program_timeout."
    end

    #  Automatic differentiation parameters
    max_parameters = get(message, "maxParameters", 99)

    task_payload = message["task"]
    examples = task_payload["examples"]
    task_type = deserialize_type(task_payload["request"])

    maximum_frontier = task_payload["maximumFrontier"]
    name = task_payload["name"]
    test_examples = task_payload["test_examples"]

    # if haskey(task_payload, "specialTask")
    #     handler = find_task_handler(task_payload["specialTask"], task_payload["extras"])
    # else
    handler = supervised_task_checker
    # end

    if haskey(task_payload, "specialTask")
        task = build_task(handler, name, task_type, examples, test_examples, task_payload["specialTask"])
    else
        task = build_task(handler, name, task_type, examples, test_examples)
    end

    verbose = get(message, "verbose", false)
    timeout = message["timeout"]
    nCPUs = get(message, "nc", 1)

    (
        task,
        maximum_frontier,
        grammar,
        type_weights,
        hyperparameters,
        max_parameters,
        nCPUs,
        timeout,
        verbose,
        program_timeout,
    )
end

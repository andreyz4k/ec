
function load_sampling_payload(payload)
    grammar = deserialize_grammar(payload["DSL"])
    request = parse_type(payload["request"])
    max_depth = payload["max_depth"]
    max_attempts = payload["max_attempts"]
    timeout = payload["timeout"]
    return grammar, request, max_depth, max_attempts, timeout
end

function run_sampling_process(run_context, payload)
    grammar, request, max_depth, max_attempts, timeout = load_sampling_payload(payload)
    run_context["timeout"] = timeout
    result = Dict("program" => nothing, "task" => Dict("request" => string(request), "examples" => []))
    return result
end

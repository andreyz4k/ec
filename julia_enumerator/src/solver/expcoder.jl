
using ArgParse

function config_options()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "-c"
        help = "number of workers to start"
        arg_type = Int
        default = 1
    end
    @add_arg_table! s begin
        "-i"
        help = "number of iterations"
        arg_type = Int
        default = 1
    end
    @add_arg_table! s begin
        "-d"
        help = "domain"
        arg_type = String
        default = "arc"
    end
    return s
end

function main(include_func)
    parsed_args = parse_args(ARGS, config_options())

    tasks = get_domain_tasks(parsed_args["domain"])
    grammar = get_starting_grammar()
    guiding_model = get_guiding_model(grammar)
    traces = []

    for i in 1:parsed_args["i"]
        new_traces = try_solve_tasks(tasks, guiding_model, grammar)
        append!(traces, new_traces)
        traces, grammar = compress_traces(traces, grammar)
        guiding_model = update_guiding_model(guiding_model, grammar, traces)
    end
end

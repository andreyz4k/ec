
using ArgParse

function create_arc_task(fname, tp)
    arc_task = JSON.parsefile(fname)

    train_inputs = []
    train_outputs = []
    for example in arc_task["train"]
        push!(train_inputs, Dict("inp0" => vcat([reshape(r, (1, length(r))) for r in example["input"]]...)))
        push!(train_outputs, vcat([reshape(r, (1, length(r))) for r in example["output"]]...))
    end
    test_inputs = []
    test_outputs = []
    for example in arc_task["test"]
        push!(test_inputs, Dict("inp0" => vcat([reshape(r, (1, length(r))) for r in example["input"]]...)))
        push!(test_outputs, vcat([reshape(r, (1, length(r))) for r in example["output"]]...))
    end

    return Task(basename(fname), tp, supervised_task_checker, train_inputs, train_outputs, test_inputs, test_outputs)
end

function get_arc_tasks()
    tasks = []
    tp = parse_type("inp0:grid(color) -> grid(color)")
    arc_folder = normpath(joinpath(@__DIR__, "../../..", "dreamcoder/domains/arc"))
    for fname in readdir(joinpath(arc_folder, "sortOfARC"); join = true)
        if endswith(fname, ".json")
            task = create_arc_task(fname, tp)
            push!(tasks, task)
        end
    end
    for fname in readdir(joinpath(arc_folder, "ARC/data/training"); join = true)
        if endswith(fname, ".json")
            task = create_arc_task(fname, tp)
            push!(tasks, task)
        end
    end
    return tasks
end

function get_domain_tasks(domain)
    if domain == "arc"
        return get_arc_tasks()
    end
    error("Unknown domain: $domain")
end

function get_starting_grammar()
    copy(every_primitive)
end

function get_guiding_model(model, grammar)
    if model == "dummy"
        return DummyGuidingModel(grammar)
    end
    error("Unknown model: $model")
end

function try_solve_task(task, guiding_model, grammar)
    @info "Solving task $(task.name)"
    return
    program = solve_task(task, guiding_model, grammar)
    return Dict("task" => task, "program" => program)
end

function try_solve_tasks(worker_pool, tasks, guiding_model, grammar)
    pmap(worker_pool, tasks; retry_check = (s, e) -> isa(e, ProcessExitedException), retry_delays = zeros(5)) do task
        try_solve_task(task, guiding_model, grammar)
    end
end

function config_options()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "-c"
        help = "number of workers to start"
        arg_type = Int
        default = 2

        "-i"
        help = "number of iterations"
        arg_type = Int
        default = 1

        "--domain", "-d"
        help = "domain"
        arg_type = String
        default = "arc"

        "--model", "-m"
        help = "guiding model type"
        arg_type = String
        default = "dummy"
    end
    return s
end

function main()
    @info "Starting enumeration service"
    parsed_args = parse_args(ARGS, config_options())

    tasks = get_domain_tasks(parsed_args["domain"])
    grammar = get_starting_grammar()
    guiding_model = get_guiding_model(parsed_args["model"], grammar)
    traces = []
    worker_pool = ReplenishingWorkerPool(parsed_args["c"])

    try
        for i in 1:parsed_args["i"]
            new_traces = try_solve_tasks(worker_pool, tasks, guiding_model, grammar)
            append!(traces, new_traces)
            traces, grammar = compress_traces(traces, grammar)
            guiding_model = update_guiding_model(guiding_model, grammar, traces)
        end
    finally
        stop(worker_pool)
    end
end

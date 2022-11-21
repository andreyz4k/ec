
struct Task
    name::String
    task_type::Tp
    log_likelihood_checker::Any
    train_inputs::Any
    train_outputs::Any
    test_inputs::Any
    test_outputs::Any
end

@enum MatchResult NoMatch = 0 TypeOnly = 1 Pattern = 2 Strict = 3

function supervised_task_checker(task::Task, p::Program)
    p_analized = analyze_evaluation(p)
    if all(
        try
            run_analyzed_with_arguments(p_analized, [], xs) == y
        catch e
            if isa(e, UnknownPrimitive)
                error("Unknown primitive: $(e.name)")
            elseif isa(e, InterruptException)
                rethrow()
            else
                @error e
                @error p
                false
            end
        end for (xs, y) in zip(vcat(task.train_inputs, task.test_inputs), vcat(task.train_outputs, task.test_outputs))
    )
        0.0
    else
        log(0)
    end
end

function build_task(handler, name, task_type, examples, test_examples)
    Task(
        name,
        task_type,
        handler,
        [ex["inputs"] for ex in examples],
        [ex["output"] for ex in examples],
        [ex["inputs"] for ex in test_examples],
        [ex["output"] for ex in test_examples],
    )
end

function build_task(handler, name, task_type, examples, test_examples, special_task)
    if special_task == "arc"
        Task(
            name,
            task_type,
            handler,
            [Dict(k => vcat([r' for r in val]...) for (k, val) in ex["inputs"]) for ex in examples],
            [vcat([r' for r in ex["output"]]...) for ex in examples],
            [Dict(k => vcat([r' for r in val]...) for (k, val) in ex["inputs"]) for ex in test_examples],
            [vcat([r' for r in ex["output"]]...) for ex in test_examples],
        )
    end
end

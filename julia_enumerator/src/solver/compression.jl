
using StitchBindings

function extract_programs_and_tasks(traces)
    programs = String[]
    tasks = String[]
    all_hits = []
    for (task_name, hits) in traces
        for (hit, cost) in hits
            push!(programs, hit.hit_program)
            push!(tasks, task_name)
            push!(all_hits, (hit, cost))
        end
    end
    return programs, tasks, all_hits
end

function store_precompressed_traces(traces, grammar)
    traces_dir = "compressed_traces"
    if !isdir(traces_dir)
        mkdir(traces_dir)
    end
    fname = joinpath(traces_dir, string(Dates.now()))
    Serialization.serialize(fname, (traces, grammar))
    @info "Stored precompressed traces to $fname"
end

function compress_traces(traces, grammar)
    if isempty(traces)
        return traces, grammar
    end
    store_precompressed_traces(traces, grammar)
    existing_inventions = String[string(p) for p in grammar if isa(p, Invented)]
    programs, tasks, hits = extract_programs_and_tasks(traces)
    iterations = 0
    max_arity = 3
    silent = false
    threads = 1
    panic_loud = true
    rewritten_dreamcoder = true
    new_abstractions, rewritten_programs = compress_backend(
        programs,
        tasks,
        existing_inventions,
        iterations,
        max_arity,
        threads,
        silent,
        panic_loud,
        rewritten_dreamcoder,
        ;
        eta_long = true,
        utility_by_rewrite = true,
    )
    new_grammar = Program[p for p in grammar]
    for abst_dict in new_abstractions
        push!(new_grammar, parse_program(abst_dict["body"]))
    end
    new_traces = Dict()
    for ((hit, cost), task_name, new_program) in zip(hits, tasks, rewritten_programs)
        if !haskey(new_traces, task_name)
            new_traces[task_name] = PriorityQueue{HitResult,Float64}()
        end
        new_hit = HitResult(new_program, hit.hit_prior, hit.hit_likelihood, hit.hit_time, hit.trace_values)
        new_traces[task_name][new_hit] = cost
    end
    return new_traces, new_grammar
end

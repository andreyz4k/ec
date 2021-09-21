module solver

include("parser.jl")
include("type.jl")
include("program.jl")
include("grammar.jl")
include("task.jl")
include("load.jl")


function run_solving_process(message)
    @info "running processing"
    @info message
    task, maximum_frontier, g, _mfp, _nc, timeout, _verbose = load_problems(message)
    # solutions, number_enumerated = enumerate_for_task(timeout, g, task, maximum_frontier)
    # return export_frontiers(number_enumerated, task, solutions)
    return message
end


end
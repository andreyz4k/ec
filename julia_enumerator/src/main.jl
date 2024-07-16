include("solver.jl")
using Distributed

function include_module_in_pid(pid, source_path)
    @fetchfrom pid begin
        task_local_storage()[:SOURCE_PATH] = source_path
        include("solver.jl")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    solver.main(include_module_in_pid)
end

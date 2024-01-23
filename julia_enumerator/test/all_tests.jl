
using XUnit

@testset runner = DistributedTestRunner() "all" begin
    include("reachable.jl")
    include("abstractors.jl")
    include("abstractors_tasks.jl")
    include("arc_tasks.jl")
    include("branches.jl")
    include("complexity.jl")
    include("enumeration.jl")
    include("inventions.jl")
    include("objects_processing.jl")
    include("program_parser.jl")
    include("rev_fixers.jl")
end

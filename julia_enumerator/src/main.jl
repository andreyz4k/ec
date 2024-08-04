
include("solver.jl")

if abspath(PROGRAM_FILE) == @__FILE__
    solver.main()
end

include("solver.jl")

if abspath(PROGRAM_FILE) == @__FILE__
    solver.dc_main_node()
end

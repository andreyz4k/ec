using Aqua
using solver
@testcase_log "Aqua.jl" begin
    Aqua.test_all(solver; deps_compat = false, stale_deps = (; ignore = [:ArgParse]))
end

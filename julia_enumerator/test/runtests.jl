
using Distributed
if myid() != 1
    cd("julia_enumerator/test")
else
    addprocs(Threads.nthreads())
    @everywhere using XUnit
end

runtests("all_tests.jl", ["all/" * a for a in ARGS]...)

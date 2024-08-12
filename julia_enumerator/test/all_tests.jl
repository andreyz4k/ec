
using XUnit, Logging
using Test: TestLogger

macro testcase_log(name, body)
    return quote
        local name_ = $(esc(name))
        @testcase "$name_" begin
            test_logger = TestLogger()
            try
                with_logger(test_logger) do
                    $(esc(body))
                end
            finally
                if !isempty(test_logger.logs)
                    @info "Test $(name_) logs:"
                    for log in test_logger.logs
                        @logmsg(
                            log.level,
                            log.message,
                            _module = log._module,
                            _group = log.group,
                            _id = log.id,
                            _file = log.file,
                            _line = log.line,
                            log.kwargs...,
                        )
                    end
                end
            end
        end
    end
end

@testset runner = DistributedTestRunner() "all" begin
    include("aqua.jl")
    include("reachable.jl")
    include("reachable_expl.jl")
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
    include("sample.jl")
end


using solver:
    run_in_reverse,
    is_reversible,
    EitherOptions,
    Apply,
    Abstraction,
    Hole,
    FreeVar,
    fix_option_hashes,
    parse_program,
    t0,
    run_with_arguments

@testset "Reverse fixers" begin
    function unfold_options(options::Dict)
        if all(x -> !isa(x, EitherOptions), values(options))
            return [options]
        end
        result = []
        for (i, item) in options
            if isa(item, EitherOptions)
                for (h, val) in item.options
                    new_option = Dict(k => fix_option_hashes([h], v) for (k, v) in options)
                    append!(result, unfold_options(new_option))
                end
                break
            end
        end
        return result
    end

    function compare_options(options, expected)
        if Set(unfold_options(options)) != Set(unfold_options(expected))
            @error options
            @error expected
            return false
        end
        return true
    end

    capture_free_vars(p, max_var = UInt64(0)) = p, max_var

    function capture_free_vars(p::Apply, max_var = UInt64(0))
        new_f, max_var = capture_free_vars(p.f, max_var)
        new_x, max_var = capture_free_vars(p.x, max_var)
        Apply(new_f, new_x), max_var
    end

    function capture_free_vars(p::Abstraction, max_var = UInt64(0))
        new_b, max_var = capture_free_vars(p.b, max_var)
        Abstraction(new_b), max_var
    end

    function capture_free_vars(p::Hole, max_var = UInt64(0))
        var_id = max_var + 1
        FreeVar(t0, var_id), max_var + 1
    end

    function capture_free_vars(p::FreeVar, max_var = UInt64(0))
        if isnothing(p.var_id)
            var_id = max_var + 1
            FreeVar(t0, var_id), max_var + 1
        else
            p, max_var
        end
    end

    @testset "Fix mult" begin
        p = parse_program("(* \$v1 \$v2)")
        @test is_reversible(p)
        @test compare_options(
            run_in_reverse(p, 6),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x791ecca7c8ec2799 => -1,
                        0x026990618cb235dc => 1,
                        0x9f0554b8d57c3390 => -2,
                        0x80564a377a546d05 => 3,
                        0xfd0b1e52b4af8b42 => 6,
                        0x6cd6c1f33c45263a => -6,
                        0xc46230a01bf2d454 => -3,
                        0x47d84b05977b5deb => 2,
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x791ecca7c8ec2799 => -6,
                        0x026990618cb235dc => 6,
                        0x9f0554b8d57c3390 => -3,
                        0x80564a377a546d05 => 2,
                        0xfd0b1e52b4af8b42 => 1,
                        0x6cd6c1f33c45263a => -1,
                        0xc46230a01bf2d454 => -2,
                        0x47d84b05977b5deb => 3,
                    ),
                ),
            ),
        )
        wrapped_p = parse_program("(rev_fix_param (* \$v1 \$v2) \$v1 (lambda 1))")
        @test is_reversible(wrapped_p)
        @test run_in_reverse(wrapped_p, 6) == Dict(UInt64(1) => 1, UInt64(2) => 6)
        @test run_with_arguments(wrapped_p, [], Dict(UInt64(1) => 1, UInt64(2) => 6)) == 6
        @test run_with_arguments(wrapped_p, [], Dict(UInt64(1) => 2, UInt64(2) => 3)) == 6
    end
end

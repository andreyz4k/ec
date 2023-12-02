
using Test

using solver:
    every_primitive,
    Apply,
    Hole,
    tint,
    FreeVar,
    Abstraction,
    tlist,
    t0,
    t1,
    ttuple2,
    Index,
    SetConst,
    EitherOptions,
    is_reversible,
    parse_program,
    closed_inference,
    any_object,
    tgrid,
    tcolor,
    _is_possible_selector,
    is_reversible_selector,
    _is_possible_subfunction,
    _is_reversible_subfunction,
    arrow,
    tbool,
    EnumerationException,
    run_with_arguments,
    Tp,
    ttuple2,
    ttuple3,
    tset,
    fix_option_hashes,
    match_at_index,
    PatternEntry,
    PatternWrapper,
    AbductibleValue,
    calculate_dependent_vars,
    run_in_reverse,
    UnifyError
using DataStructures: OrderedDict, Accumulator

@testset "Abstractors" begin
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

    function compare_options_subset(options, expected)
        if !issubset(Set(unfold_options(expected)), Set(unfold_options(options)))
            @error "Expected options are not in the result $(setdiff(Set(unfold_options(expected)), Set(unfold_options(options))))"
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

    function capture_free_vars(p::Union{Hole,FreeVar}, max_var = UInt64(0))
        var_id = max_var + 1
        FreeVar(t0, var_id), max_var + 1
    end

    @testset "Check reversible simple" begin
        @test is_reversible(parse_program("(repeat ??(int) ??(int))"))
    end

    @testset "Check reversible map" begin
        @test !is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(every_primitive["repeat"], Hole(tint, nothing, true, _is_possible_subfunction)),
                            Hole(tint, nothing, true, _is_possible_subfunction),
                        ),
                    ),
                ),
                Hole(tlist(ttuple2(tint, tint)), nothing, true, nothing),
            ),
        )
        @test is_reversible(parse_program("(map (lambda (repeat \$0 \$0)) ??(list(int)))"))
        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(
                            Abstraction(
                                Apply(
                                    Apply(
                                        every_primitive["repeat"],
                                        Hole(tint, nothing, true, _is_possible_subfunction),
                                    ),
                                    Hole(tint, nothing, true, _is_possible_subfunction),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
        )
        @test is_reversible(parse_program("(map2 (lambda (repeat \$0 \$1)) ??(list(int)) ??(list(int)))"))
        @test is_reversible(parse_program("(map2 (lambda (repeat \$1 \$0)) ??(list(int)) ??(list(int)))"))
        @test !is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(every_primitive["cons"], Index(0)),
                            Hole(tlist(tbool), nothing, true, _is_possible_subfunction),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, true, nothing),
            ),
        )
        @test !_is_reversible_subfunction(
            Abstraction(
                Apply(
                    Apply(every_primitive["cons"], Index(0)),
                    Hole(tlist(tbool), nothing, true, _is_possible_subfunction),
                ),
            ),
        )
    end

    @testset "Check reversible nested map" begin
        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(
                            Abstraction(
                                Apply(
                                    Apply(
                                        Apply(
                                            every_primitive["map2"],
                                            Abstraction(
                                                Abstraction(
                                                    Apply(
                                                        Apply(
                                                            every_primitive["repeat"],
                                                            Hole(tint, nothing, true, _is_possible_subfunction),
                                                        ),
                                                        Hole(tint, nothing, true, _is_possible_subfunction),
                                                    ),
                                                ),
                                            ),
                                        ),
                                        Hole(tlist(tint), nothing, true, _is_possible_subfunction),
                                    ),
                                    Hole(tlist(tint), nothing, true, _is_possible_subfunction),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tlist(tint)), nothing, true, nothing),
                ),
                Hole(tlist(tlist(tint)), nothing, true, nothing),
            ),
        )
        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(
                            Abstraction(
                                Apply(
                                    Apply(
                                        Apply(
                                            every_primitive["map2"],
                                            Abstraction(
                                                Abstraction(
                                                    Apply(Apply(every_primitive["repeat"], Index(0)), Index(1)),
                                                ),
                                            ),
                                        ),
                                        Hole(tlist(tint), nothing, true, _is_possible_subfunction),
                                    ),
                                    Hole(tlist(tint), nothing, true, _is_possible_subfunction),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tlist(tint)), nothing, true, nothing),
                ),
                Hole(tlist(tlist(tint)), nothing, true, nothing),
            ),
        )
        @test is_reversible(
            parse_program(
                "(map2 (lambda (map2 (lambda (repeat \$0 \$1)) \$1 \$0)) ??(list(list(int))) ??(list(list(int))))",
            ),
        )
        @test !is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(
                                every_primitive["map"],
                                Abstraction(
                                    Apply(
                                        Apply(
                                            every_primitive["repeat"],
                                            Hole(tint, nothing, true, _is_possible_subfunction),
                                        ),
                                        Hole(tint, nothing, true, _is_possible_subfunction),
                                    ),
                                ),
                            ),
                            Hole(tlist(tlist(tint)), nothing, true, _is_possible_subfunction),
                        ),
                    ),
                ),
                Hole(tlist(ttuple2(tlist(tint), tlist(tint))), nothing, true, nothing),
            ),
        )
        @test !is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(
                                every_primitive["map"],
                                Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(0))),
                            ),
                            Hole(tlist(tint), nothing, true, _is_possible_subfunction),
                        ),
                    ),
                ),
                Hole(tlist(tlist(tint)), nothing, true, nothing),
            ),
        )
        @test is_reversible(parse_program("(map (lambda (map (lambda (repeat \$0 \$0)) \$0)) ??(list(list(int))))"))
    end

    @testset "Check reversible select" begin
        @test is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(
                            Apply(
                                Apply(every_primitive["eq?"], Index(0)),
                                Hole(tint, nothing, true, _is_possible_selector),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
        )
        @test is_reversible_selector(
            Abstraction(
                Apply(Apply(every_primitive["eq?"], Index(0)), Hole(tint, nothing, true, _is_possible_selector)),
            ),
        )

        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(
                            Apply(
                                Apply(every_primitive["eq?"], Hole(tint, nothing, false, _is_possible_selector)),
                                Hole(tint, nothing, false, _is_possible_selector),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
        )
        @test !is_reversible_selector(
            Abstraction(
                Apply(
                    Apply(every_primitive["eq?"], Hole(tint, nothing, false, _is_possible_selector)),
                    Hole(tint, nothing, false, _is_possible_selector),
                ),
            ),
        )

        @test is_reversible(parse_program("(rev_select (lambda (empty? \$0)) ??(list(int)) ??(list(int)))"))
        @test is_reversible_selector(Abstraction(Apply(every_primitive["empty?"], Index(0))))
        @test !is_reversible_selector(Abstraction(Apply(every_primitive["empty?"], Index(1))))

        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(
                            Apply(every_primitive["empty?"], Hole(tint, nothing, false, _is_possible_selector)),
                        ),
                    ),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
        )
    end

    @testset "Reverse repeat" begin
        skeleton = parse_program("(repeat ??(int) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(run_in_reverse(p, [[1, 2, 3], [1, 2, 3]]), Dict(UInt64(1) => [1, 2, 3], UInt64(2) => 2))
        @test compare_options(run_in_reverse(p, [1, 1, 1]), Dict(UInt64(1) => 1, UInt64(2) => 3))
        @test compare_options(run_in_reverse(p, [1, any_object, 1]), Dict(UInt64(1) => 1, UInt64(2) => 3))
        @test compare_options(run_in_reverse(p, [any_object, any_object, 1]), Dict(UInt64(1) => 1, UInt64(2) => 3))
        @test run_in_reverse(p, [any_object, any_object, 1])[UInt64(1)] !== any_object
        @test match_at_index(
            PatternEntry(
                0x0000000000000001,
                Any[
                    PatternWrapper(Any[1, any_object, 1, any_object, 1]),
                    PatternWrapper(Any[any_object, any_object, any_object, 1, 1, 1]),
                    PatternWrapper(Any[1, any_object, any_object, any_object, 1, 1, any_object]),
                ],
                Accumulator("int" => 9, "list" => 3),
                12.0,
            ),
            1,
            [1, 1, 1, 1, 1],
        )
    end

    @testset "Reverse repeat grid" begin
        skeleton = parse_program("(repeat_grid ??(int) ??(int) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[[1, 2, 3], [1, 2, 3]] [[1, 2, 3], [1, 2, 3]] [[1, 2, 3], [1, 2, 3]]]),
            Dict(UInt64(1) => [1, 2, 3], UInt64(2) => 2, UInt64(3) => 3),
        )
        @test compare_options(
            run_in_reverse(p, [[1, 1, 1] [1, 1, 1]]),
            Dict(UInt64(1) => 1, UInt64(2) => 3, UInt64(3) => 2),
        )
        @test compare_options(
            run_in_reverse(p, [[1, any_object, 1] [1, any_object, any_object]]),
            Dict(UInt64(1) => 1, UInt64(2) => 3, UInt64(3) => 2),
        )
        @test compare_options(
            run_in_reverse(p, [[any_object, any_object, 1] [any_object, any_object, any_object]]),
            Dict(UInt64(1) => 1, UInt64(2) => 3, UInt64(3) => 2),
        )
        @test run_in_reverse(p, [[any_object, any_object, 1] [any_object, any_object, any_object]])[1] !== any_object
    end

    @testset "Reverse cons" begin
        skeleton = parse_program("(cons ??(int) ??(list(int)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(run_in_reverse(p, [1, 2, 3]), Dict(UInt64(1) => 1, UInt64(2) => [2, 3]))
    end

    @testset "Reverse adjoin" begin
        skeleton = parse_program("(adjoin ??(int) ??(set(int)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([1, 2, 3])),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(0xdab8105ae838a43f => 1, 0x369f7593fdd6aa68 => 3, 0xa546dd1af6daadbb => 2),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0xdab8105ae838a43f => Set([2, 3]),
                        0x369f7593fdd6aa68 => Set([2, 1]),
                        0xa546dd1af6daadbb => Set([3, 1]),
                    ),
                ),
            ),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => 1, UInt64(2) => Set([3, 2]))) == Set([1, 2, 3])
    end

    @testset "Reverse tuple2" begin
        skeleton = parse_program("(tuple2 ??(color) ??(list(int)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(run_in_reverse(p, (1, [2, 3])), Dict(UInt64(1) => 1, UInt64(2) => [2, 3]))
    end

    @testset "Reverse plus" begin
        skeleton = parse_program("(+ ??(int) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x77a9026ed8716b32 => AbductibleValue(any_object),
                        0x459d37a140ff9981 => -3,
                        0x3265ec908a0608dc => 3,
                        0x5d2180d7ab2643ec => 2,
                        0x8d0977bf38eb147f => 4,
                        0xa74551280ce09917 => 1,
                        0x9face253d5d128fe => -1,
                        0x35422d29f2a87761 => 6,
                        0x5f167b5beff0a9cc => 5,
                        0x3b9a2ba398e93739 => 0,
                        0x2237f75dda3318f3 => -2,
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x77a9026ed8716b32 => AbductibleValue(any_object),
                        0x459d37a140ff9981 => 6,
                        0x3265ec908a0608dc => 0,
                        0x5d2180d7ab2643ec => 1,
                        0x8d0977bf38eb147f => -1,
                        0xa74551280ce09917 => 2,
                        0x9face253d5d128fe => 4,
                        0x35422d29f2a87761 => -3,
                        0x5f167b5beff0a9cc => -2,
                        0x3b9a2ba398e93739 => 3,
                        0x2237f75dda3318f3 => 5,
                    ),
                ),
            ),
        )
        @test compare_options(
            run_in_reverse(p, 15),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xc0eed55d65d0bcfe => -1,
                        0xb4e26543bad24318 => 2,
                        0x7f59d64eb7896cdb => 13,
                        0x8d0bdf7aa927df45 => -2,
                        0xef64a9d7f7f151ff => 1,
                        0x57ffa8893dac4229 => -3,
                        0x95a12eba920b7eae => AbductibleValue(any_object),
                        0xbf80b6a36531dc8b => 15,
                        0x08b914a10f83da7b => 14,
                        0x5883d3b29c393f21 => 17,
                        0x33a6357487f26f15 => 16,
                        0x471a0b5abea801fc => 18,
                        0x65591b60574c9c40 => 3,
                        0xac6cddb60e99ba87 => 12,
                        0xbb76995c7147740c => 0,
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xc0eed55d65d0bcfe => 16,
                        0xb4e26543bad24318 => 13,
                        0x7f59d64eb7896cdb => 2,
                        0x8d0bdf7aa927df45 => 17,
                        0xef64a9d7f7f151ff => 14,
                        0x57ffa8893dac4229 => 18,
                        0x95a12eba920b7eae => AbductibleValue(any_object),
                        0xbf80b6a36531dc8b => 0,
                        0x08b914a10f83da7b => 1,
                        0x5883d3b29c393f21 => -2,
                        0x33a6357487f26f15 => -1,
                        0x471a0b5abea801fc => -3,
                        0x65591b60574c9c40 => 12,
                        0xac6cddb60e99ba87 => 3,
                        0xbb76995c7147740c => 15,
                    ),
                ),
            ),
        )
        @test compare_options(
            run_in_reverse(p, -5),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x77bd594ea52823ef => -3,
                        0x7a2ec8f4190578f9 => -7,
                        0xe4b130b2924858ff => 1,
                        0x50ac44c12ff9ca42 => -5,
                        0x9d70cec704239f74 => 2,
                        0xc2c41806f6ce6414 => -1,
                        0xf273272c80a440d1 => -6,
                        0x4df243b7ed4ff045 => 3,
                        0x64de184119556de4 => -2,
                        0x9364575ef7342f32 => AbductibleValue(any_object),
                        0x8f6a3d05e8032b73 => -4,
                        0xc40a0ac2d09a9b45 => -8,
                        0xb1b95b97d0754f88 => 0,
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x77bd594ea52823ef => -2,
                        0x7a2ec8f4190578f9 => 2,
                        0xe4b130b2924858ff => -6,
                        0x50ac44c12ff9ca42 => 0,
                        0x9d70cec704239f74 => -7,
                        0xc2c41806f6ce6414 => -4,
                        0xf273272c80a440d1 => 1,
                        0x4df243b7ed4ff045 => -8,
                        0x64de184119556de4 => -3,
                        0x9364575ef7342f32 => AbductibleValue(any_object),
                        0x8f6a3d05e8032b73 => -1,
                        0xc40a0ac2d09a9b45 => 3,
                        0xb1b95b97d0754f88 => -5,
                    ),
                ),
            ),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), 3) == Dict(UInt64(2) => 2)
        @test calculate_dependent_vars(
            p,
            Dict{UInt64,Any}(UInt64(1) => 1),
            EitherOptions(Dict{UInt64,Any}(0xaa2dcc33efe7cdcd => 30, 0x4ef19a9b1c1cc5e2 => 15)),
        ) == Dict(UInt64(2) => EitherOptions(Dict{UInt64,Any}(0xaa2dcc33efe7cdcd => 29, 0x4ef19a9b1c1cc5e2 => 14)))
    end

    @testset "Reverse plus with plus" begin
        skeleton = parse_program("(+ (+ ??(int) ??(int)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x2f4fdcb7842ba70c => EitherOptions(
                            Dict{UInt64,Any}(
                                0xc183276ea452aa6d => -1,
                                0x0891ab47318930ce => -2,
                                0xdd163e1300ab58f7 => -3,
                                0x0b56e50821fa2c23 => AbductibleValue(any_object),
                                0xd7408e4a0302f6c8 => 3,
                                0xbead9a130202cf2d => 0,
                                0xfe101c0da0e95a0e => 1,
                                0xeddea093c9290daf => 2,
                            ),
                        ),
                        0xeedc9f4034a61639 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x1ca116ec8a3c1ace => -3,
                                0x581ef8567937c13e => 4,
                                0x903726cd9ebacc15 => 2,
                                0x4b51748595db84bf => AbductibleValue(any_object),
                                0x438e19f40b01011b => 3,
                                0x7c8dd15e162acebb => -2,
                                0x9096f12d5513c24f => 0,
                                0x2d48ebad0db7df96 => 1,
                                0x26bcb987a6eaa3a9 => -1,
                            ),
                        ),
                        0x6f303adf666172f9 => AbductibleValue(any_object),
                        0x318e41605a3be000 => EitherOptions(
                            Dict{UInt64,Any}(
                                0xafb58697c4658fba => 0,
                                0x8144b3050efb0ce4 => 7,
                                0xfb7b0c7de3398de8 => -1,
                                0x56c2e66e304b2e56 => AbductibleValue(any_object),
                                0x6e254c63b61500a4 => 3,
                                0x6166f79ad43ab541 => 5,
                                0xe3ba99dbb48660f5 => 1,
                                0xe6b2f94cdccd8f2c => 4,
                                0x3c10fc91cc86a2b8 => -2,
                                0x85b89f803f32956c => 6,
                                0x9b847cfcaedfb950 => -3,
                                0x451abce42a7d8be8 => 2,
                            ),
                        ),
                        0x128772c4f3e3c9a8 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x87de3e5902d4beb9 => -2,
                                0x7ec2334590902ceb => 1,
                                0x80ce54ad5dd3e38c => -4,
                                0xfba2a27b3cafbd4f => AbductibleValue(any_object),
                                0x1a171967a569f71e => 3,
                                0x9fa744fbf5efb23c => 0,
                                0x0b9f894614aae9e2 => -1,
                                0xb942e20c5ba78cb5 => 2,
                                0xa379e772dc68c0b5 => -3,
                            ),
                        ),
                        0xa8ff02da9bda973f => EitherOptions(
                            Dict{UInt64,Any}(
                                0xc79c6900b5ad099c => -1,
                                0x429ef7f0124e9748 => 0,
                                0xb4bd912e1296a218 => -2,
                                0xea280039c77c3bfc => 2,
                                0x7a25bd0c02f466ee => AbductibleValue(any_object),
                                0x38ddf54ae7b607cd => -5,
                                0xe051ed27eb907270 => 1,
                                0x01c966fc602d4624 => -3,
                                0xdd45eb0f6f08e821 => 3,
                                0xfd95287ff75b84d4 => -4,
                            ),
                        ),
                        0x3d322e8935d61bd2 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x318cf32cfd2dbb7b => -6,
                                0x30496905ec086e36 => 2,
                                0xdf597d6e0751bc07 => 0,
                                0x261415c480931323 => -5,
                                0x7a320e66ce613707 => -3,
                                0x8bfc25e37b19f677 => 3,
                                0xb930a2a2c7239c2d => -2,
                                0xf0a1a8c2ae2ce23b => -4,
                                0xb194d4556881c656 => 1,
                                0x2575fe05d0e4d493 => AbductibleValue(any_object),
                                0x79d9b59ab117300f => -1,
                            ),
                        ),
                        0x763c248d4453a14b => EitherOptions(
                            Dict{UInt64,Any}(
                                0x2087f4868e7daf83 => 2,
                                0x19527f36df3c38c6 => 1,
                                0x9676a52fb6a2f038 => 7,
                                0x3482b91ed62a3457 => 5,
                                0xf647e7d7583799ae => 9,
                                0x81d8d7306eae09da => AbductibleValue(any_object),
                                0x7cae0d1c384d427e => 6,
                                0xed01756b30a0a68d => 0,
                                0x0853689a38f4a6bf => -3,
                                0xd2e56ab3c1af326f => -1,
                                0xbcd1cf58f55e8c60 => 4,
                                0xd7af0200ceaf90ef => 8,
                                0x83147f06052eae4f => -2,
                                0x718d1cbb95a696d5 => 3,
                            ),
                        ),
                        0xac35ab71f5a4ddcb => EitherOptions(
                            Dict{UInt64,Any}(
                                0x89701ba47c069c64 => 4,
                                0x124d2b2d0903e16c => -2,
                                0x2084a623f1e5c1a2 => 1,
                                0xfa99bf70e6c1faa8 => 5,
                                0x67e47e5c8857cb3f => -3,
                                0x4b7a2b8e613b2e16 => 0,
                                0x35c06e21769038d0 => 2,
                                0xde083980ed984269 => AbductibleValue(any_object),
                                0x3a0c7192848979a9 => 3,
                                0x8829c39fed644b86 => -1,
                            ),
                        ),
                        0x6891f07dcf4993c2 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x14de195b472473a0 => -2,
                                0x23e8b444ad63dce7 => 7,
                                0xd6ae74ac150bba94 => 5,
                                0x155383c1cd869be8 => 6,
                                0x708fca8346d76649 => -1,
                                0x0c61c8c7f9029596 => 0,
                                0x836a12e1f7b838bc => -3,
                                0xb238e9b432cc10ce => 3,
                                0x86d8991af86a29f4 => AbductibleValue(any_object),
                                0x07ff20d28d87c06e => 8,
                                0xc22cd6d64d0f8371 => 1,
                                0x1015d5a533a18605 => 2,
                                0xb41b4603008fb810 => 4,
                            ),
                        ),
                        0x77a46938da0fcd52 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x9d1fa5d1426898e3 => 4,
                                0x25a4a5a01d1d13ed => 3,
                                0x95c5b3787cf29eb4 => AbductibleValue(any_object),
                                0x66e6feda9f674e4b => -3,
                                0x38534a497bc069eb => -2,
                                0x0fb611fbdd9ebfbb => 6,
                                0x4fc2f4f5b59e9981 => -1,
                                0x9fe203345dc2ea6e => 0,
                                0x8753f039667e7fb2 => 2,
                                0xd8595bb38f6e093f => 1,
                                0xb7d5960bbeba0330 => 5,
                            ),
                        ),
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x2f4fdcb7842ba70c => 3,
                        0xeedc9f4034a61639 => 2,
                        0x6f303adf666172f9 => AbductibleValue(any_object),
                        0x318e41605a3be000 => -1,
                        0x128772c4f3e3c9a8 => 4,
                        0xa8ff02da9bda973f => 5,
                        0x3d322e8935d61bd2 => 6,
                        0x763c248d4453a14b => -3,
                        0xac35ab71f5a4ddcb => 1,
                        0x6891f07dcf4993c2 => -2,
                        0x77a46938da0fcd52 => 0,
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x2f4fdcb7842ba70c => EitherOptions(
                            Dict{UInt64,Any}(
                                0xc183276ea452aa6d => 1,
                                0x0891ab47318930ce => 2,
                                0xdd163e1300ab58f7 => 3,
                                0x0b56e50821fa2c23 => AbductibleValue(any_object),
                                0xd7408e4a0302f6c8 => -3,
                                0xbead9a130202cf2d => 0,
                                0xfe101c0da0e95a0e => -1,
                                0xeddea093c9290daf => -2,
                            ),
                        ),
                        0xeedc9f4034a61639 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x1ca116ec8a3c1ace => 4,
                                0x581ef8567937c13e => -3,
                                0x903726cd9ebacc15 => -1,
                                0x4b51748595db84bf => AbductibleValue(any_object),
                                0x438e19f40b01011b => -2,
                                0x7c8dd15e162acebb => 3,
                                0x9096f12d5513c24f => 1,
                                0x2d48ebad0db7df96 => 0,
                                0x26bcb987a6eaa3a9 => 2,
                            ),
                        ),
                        0x6f303adf666172f9 => AbductibleValue(any_object),
                        0x318e41605a3be000 => EitherOptions(
                            Dict{UInt64,Any}(
                                0xafb58697c4658fba => 4,
                                0x8144b3050efb0ce4 => -3,
                                0xfb7b0c7de3398de8 => 5,
                                0x56c2e66e304b2e56 => AbductibleValue(any_object),
                                0x6e254c63b61500a4 => 1,
                                0x6166f79ad43ab541 => -1,
                                0xe3ba99dbb48660f5 => 3,
                                0xe6b2f94cdccd8f2c => 0,
                                0x3c10fc91cc86a2b8 => 6,
                                0x85b89f803f32956c => -2,
                                0x9b847cfcaedfb950 => 7,
                                0x451abce42a7d8be8 => 2,
                            ),
                        ),
                        0x128772c4f3e3c9a8 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x87de3e5902d4beb9 => 1,
                                0x7ec2334590902ceb => -2,
                                0x80ce54ad5dd3e38c => 3,
                                0xfba2a27b3cafbd4f => AbductibleValue(any_object),
                                0x1a171967a569f71e => -4,
                                0x9fa744fbf5efb23c => -1,
                                0x0b9f894614aae9e2 => 0,
                                0xb942e20c5ba78cb5 => -3,
                                0xa379e772dc68c0b5 => 2,
                            ),
                        ),
                        0xa8ff02da9bda973f => EitherOptions(
                            Dict{UInt64,Any}(
                                0xc79c6900b5ad099c => -1,
                                0x429ef7f0124e9748 => -2,
                                0xb4bd912e1296a218 => 0,
                                0xea280039c77c3bfc => -4,
                                0x7a25bd0c02f466ee => AbductibleValue(any_object),
                                0x38ddf54ae7b607cd => 3,
                                0xe051ed27eb907270 => -3,
                                0x01c966fc602d4624 => 1,
                                0xdd45eb0f6f08e821 => -5,
                                0xfd95287ff75b84d4 => 2,
                            ),
                        ),
                        0x3d322e8935d61bd2 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x318cf32cfd2dbb7b => 3,
                                0x30496905ec086e36 => -5,
                                0xdf597d6e0751bc07 => -3,
                                0x261415c480931323 => 2,
                                0x7a320e66ce613707 => 0,
                                0x8bfc25e37b19f677 => -6,
                                0xb930a2a2c7239c2d => -1,
                                0xf0a1a8c2ae2ce23b => 1,
                                0xb194d4556881c656 => -4,
                                0x2575fe05d0e4d493 => AbductibleValue(any_object),
                                0x79d9b59ab117300f => -2,
                            ),
                        ),
                        0x763c248d4453a14b => EitherOptions(
                            Dict{UInt64,Any}(
                                0x2087f4868e7daf83 => 4,
                                0x19527f36df3c38c6 => 5,
                                0x9676a52fb6a2f038 => -1,
                                0x3482b91ed62a3457 => 1,
                                0xf647e7d7583799ae => -3,
                                0x81d8d7306eae09da => AbductibleValue(any_object),
                                0x7cae0d1c384d427e => 0,
                                0xed01756b30a0a68d => 6,
                                0x0853689a38f4a6bf => 9,
                                0xd2e56ab3c1af326f => 7,
                                0xbcd1cf58f55e8c60 => 2,
                                0xd7af0200ceaf90ef => -2,
                                0x83147f06052eae4f => 8,
                                0x718d1cbb95a696d5 => 3,
                            ),
                        ),
                        0xac35ab71f5a4ddcb => EitherOptions(
                            Dict{UInt64,Any}(
                                0x89701ba47c069c64 => -2,
                                0x124d2b2d0903e16c => 4,
                                0x2084a623f1e5c1a2 => 1,
                                0xfa99bf70e6c1faa8 => -3,
                                0x67e47e5c8857cb3f => 5,
                                0x4b7a2b8e613b2e16 => 2,
                                0x35c06e21769038d0 => 0,
                                0xde083980ed984269 => AbductibleValue(any_object),
                                0x3a0c7192848979a9 => -1,
                                0x8829c39fed644b86 => 3,
                            ),
                        ),
                        0x6891f07dcf4993c2 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x14de195b472473a0 => 7,
                                0x23e8b444ad63dce7 => -2,
                                0xd6ae74ac150bba94 => 0,
                                0x155383c1cd869be8 => -1,
                                0x708fca8346d76649 => 6,
                                0x0c61c8c7f9029596 => 5,
                                0x836a12e1f7b838bc => 8,
                                0xb238e9b432cc10ce => 2,
                                0x86d8991af86a29f4 => AbductibleValue(any_object),
                                0x07ff20d28d87c06e => -3,
                                0xc22cd6d64d0f8371 => 4,
                                0x1015d5a533a18605 => 3,
                                0xb41b4603008fb810 => 1,
                            ),
                        ),
                        0x77a46938da0fcd52 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x9d1fa5d1426898e3 => -1,
                                0x25a4a5a01d1d13ed => 0,
                                0x95c5b3787cf29eb4 => AbductibleValue(any_object),
                                0x66e6feda9f674e4b => 6,
                                0x38534a497bc069eb => 5,
                                0x0fb611fbdd9ebfbb => -3,
                                0x4fc2f4f5b59e9981 => 4,
                                0x9fe203345dc2ea6e => 3,
                                0x8753f039667e7fb2 => 1,
                                0xd8595bb38f6e093f => 2,
                                0xb7d5960bbeba0330 => -2,
                            ),
                        ),
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), 3),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x3cdb6cb0c188e4dc => 5,
                        0xff850579fde1e115 => 3,
                        0x5d7b01ec86db7a88 => 4,
                        0x4ac29db122aadcfa => AbductibleValue(any_object),
                        0x2456ae3dc9898a3b => -1,
                        0x3dee7e565d6399f2 => -2,
                        0xdc23f6695ee7f278 => 1,
                        0x68c42a44110a41c0 => 0,
                        0xbb6da82bcf882b88 => 2,
                        0x1823ab61483903bd => -4,
                        0xbaf128e66515e678 => -3,
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x3cdb6cb0c188e4dc => -3,
                        0xff850579fde1e115 => -1,
                        0x5d7b01ec86db7a88 => -2,
                        0x4ac29db122aadcfa => AbductibleValue(any_object),
                        0x2456ae3dc9898a3b => 3,
                        0x3dee7e565d6399f2 => 4,
                        0xdc23f6695ee7f278 => 1,
                        0x68c42a44110a41c0 => 2,
                        0xbb6da82bcf882b88 => 0,
                        0x1823ab61483903bd => 6,
                        0xbaf128e66515e678 => 5,
                    ),
                ),
            ),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1, UInt64(2) => 5), 3) == Dict(UInt64(3) => -3)
        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1, UInt64(3) => 5), 3) == Dict(UInt64(2) => -3)
    end

    @testset "Reverse repeat with plus" begin
        skeleton = parse_program("(repeat (+ ??(int) ??(int)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, [3, 3, 3, 3]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xa66778304e8308c0 => 1,
                        0x2837c23efabc1abe => -2,
                        0x537ae6260f30fcc1 => AbductibleValue(any_object),
                        0x076b6141ef49a7a3 => 0,
                        0x92d6d05e1d7116d2 => 2,
                        0xf92ada83cdbc17a0 => 4,
                        0x88206808898e4818 => 5,
                        0xc84dd10cbb41c949 => -1,
                        0x3281a11d980b112f => 3,
                        0x97828aec8edfbf49 => -3,
                        0xf84db463c945f870 => 6,
                    ),
                ),
                0x0000000000000003 => 4,
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xa66778304e8308c0 => 2,
                        0x2837c23efabc1abe => 5,
                        0x537ae6260f30fcc1 => AbductibleValue(any_object),
                        0x076b6141ef49a7a3 => 3,
                        0x92d6d05e1d7116d2 => 1,
                        0xf92ada83cdbc17a0 => -1,
                        0x88206808898e4818 => -2,
                        0xc84dd10cbb41c949 => 4,
                        0x3281a11d980b112f => 0,
                        0x97828aec8edfbf49 => 6,
                        0xf84db463c945f870 => -3,
                    ),
                ),
            ),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1, UInt64(3) => 4), [3, 3, 3, 3]) ==
              Dict(UInt64(2) => 2)
    end

    @testset "Reverse abs with plus" begin
        skeleton = parse_program("(abs (+ ??(int) ??(int)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xb135ab00fa81010b => EitherOptions(
                            Dict{UInt64,Any}(
                                0x23b33bf236020616 => AbductibleValue(any_object),
                                0x149650bc5da337c5 => -2,
                                0x4bee8b95d2d12ca4 => -3,
                                0x5e838979652d2b00 => 3,
                                0x9a3ec9cbc4fc6787 => 6,
                                0x9add49a4bcd8168f => 0,
                                0x272bfecf7f13f09a => 5,
                                0x5561da68968e904a => 2,
                                0x0eaee76c318f58c5 => 4,
                                0x8f3a0d2259a945ed => -1,
                                0x4067af5c6254a6aa => 1,
                            ),
                        ),
                        0xaf4407769a7b1068 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x21cb00b13b33a7aa => AbductibleValue(any_object),
                                0x721035d0f9f838cb => 3,
                                0xf2f7ca05262d402d => -1,
                                0x5cb0b36d40cc2e97 => 0,
                                0x629e3e6fd67f3521 => 1,
                                0x0f904e3a4f6fe0d7 => -2,
                                0x1949a3faf24e9432 => -5,
                                0x42b38fd779f21338 => -6,
                                0x5cac8ee187c26ebd => -4,
                                0x3a4bbefc1887ebb1 => -3,
                                0xd1af83552df9fab8 => 2,
                            ),
                        ),
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xb135ab00fa81010b => EitherOptions(
                            Dict{UInt64,Any}(
                                0x23b33bf236020616 => AbductibleValue(any_object),
                                0x149650bc5da337c5 => 5,
                                0x4bee8b95d2d12ca4 => 6,
                                0x5e838979652d2b00 => 0,
                                0x9a3ec9cbc4fc6787 => -3,
                                0x9add49a4bcd8168f => 3,
                                0x272bfecf7f13f09a => -2,
                                0x5561da68968e904a => 1,
                                0x0eaee76c318f58c5 => -1,
                                0x8f3a0d2259a945ed => 4,
                                0x4067af5c6254a6aa => 2,
                            ),
                        ),
                        0xaf4407769a7b1068 => EitherOptions(
                            Dict{UInt64,Any}(
                                0x21cb00b13b33a7aa => AbductibleValue(any_object),
                                0x721035d0f9f838cb => -6,
                                0xf2f7ca05262d402d => -2,
                                0x5cb0b36d40cc2e97 => -3,
                                0x629e3e6fd67f3521 => -4,
                                0x0f904e3a4f6fe0d7 => -1,
                                0x1949a3faf24e9432 => 2,
                                0x42b38fd779f21338 => 3,
                                0x5cac8ee187c26ebd => 1,
                                0x3a4bbefc1887ebb1 => 0,
                                0xd1af83552df9fab8 => -5,
                            ),
                        ),
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), 3),
            Dict(UInt64(2) => EitherOptions(Dict{UInt64,Any}(0xc8e6a6dedcb6f132 => -4, 0x9fede9511319ae42 => 2))),
        )
    end

    @testset "Reverse plus with abs" begin
        skeleton = parse_program("(+ (abs ??(int)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x8c29b3948f0a5452 => 1,
                        0x1b2ba6471d31782d => 3,
                        0xec9a92e89cf0f3f8 => -1,
                        0xbdafdacc023c1692 => 2,
                        0x699961c54b193c77 => 0,
                        0x25f4597a9d45f7d8 => AbductibleValue(any_object),
                        0x085817ae919c8a33 => -2,
                        0x23f2af89d2e05a5d => -3,
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x8c29b3948f0a5452 =>
                            EitherOptions(Dict{UInt64,Any}(0x996f87847904da43 => 2, 0x463800fecde61ab0 => -2)),
                        0x1b2ba6471d31782d => 0,
                        0xec9a92e89cf0f3f8 =>
                            EitherOptions(Dict{UInt64,Any}(0xa3d74fc7242dcfeb => -4, 0xf541153614fa0880 => 4)),
                        0xbdafdacc023c1692 =>
                            EitherOptions(Dict{UInt64,Any}(0xfc77bd60620e7a6d => -1, 0x6c69de9376c47036 => 1)),
                        0x699961c54b193c77 =>
                            EitherOptions(Dict{UInt64,Any}(0x759346d3bea9297d => -3, 0x072fc2634d8edac8 => 3)),
                        0x25f4597a9d45f7d8 => AbductibleValue(any_object),
                        0x085817ae919c8a33 =>
                            EitherOptions(Dict{UInt64,Any}(0x84ea1434e5854ec2 => -5, 0x9b521859de6cb4c2 => 5)),
                        0x23f2af89d2e05a5d =>
                            EitherOptions(Dict{UInt64,Any}(0x39e007ddc6612439 => 6, 0xb0faf74ce4a2b3d1 => -6)),
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => 1), 3),
            Dict(UInt64(1) => EitherOptions(Dict{UInt64,Any}(0xc8e6a6dedcb6f132 => -2, 0x9fede9511319ae42 => 2))),
        )
    end

    @testset "Reverse mult" begin
        skeleton = parse_program("(* ??(int) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
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
        @test compare_options(
            run_in_reverse(p, 240),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0xdf1f43b4a5bf81a0 => 20,
                        0x93342815c80247ec => -4,
                        0xe9aa1d03c08f0cf2 => -80,
                        0x33d952fcc54c964d => -1,
                        0x37b8c54b99b5c3a5 => -15,
                        0x63dc56578163bc76 => 5,
                        0x6ff7a2bbcc2ed680 => -2,
                        0x941309243bb48eeb => 16,
                        0x968d3c8577b18d2d => 10,
                        0xed04d74cdd8b9877 => -240,
                        0xa81928b0536b8026 => -10,
                        0x6af9aef9d020dbdc => 60,
                        0x0a20d070ec27503e => 40,
                        0xce660b2661a5f670 => 3,
                        0xee6f39a86668b1d8 => -30,
                        0x31ca15c719434b64 => 48,
                        0x66580b8c6fc55812 => 4,
                        0xb802e16655a4d0c2 => -16,
                        0x41197faacc3a74ef => -60,
                        0xbcee6210abb25cbd => 120,
                        0xd570ebd291a05d56 => 240,
                        0x584056c4e4e5ea8a => 2,
                        0xd8bc8f3c8eb7bd15 => -24,
                        0x9c90ebf3a0c1332e => -48,
                        0x8424b68d7a07b04a => 30,
                        0x76bcaa937dbd48f6 => 8,
                        0x80ee83c129fde539 => -12,
                        0x827c3471f6fb075a => 80,
                        0x432965e7dc197b0a => -5,
                        0xadfbb35f2eba95a1 => -20,
                        0x82ad704409428d81 => -6,
                        0x628014e86a639bab => -40,
                        0xf6e78669adbc0876 => -8,
                        0x63b5e889bec042a2 => 24,
                        0x7b43eca45d3cb38c => -3,
                        0x974f110b4bc26192 => 12,
                        0x2210825b9d16bfdc => -120,
                        0xb435ceee34eddd5a => 6,
                        0x5e01c8deb0bca629 => 1,
                        0x149de8d52b424366 => 15,
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0xdf1f43b4a5bf81a0 => 12,
                        0x93342815c80247ec => -60,
                        0xe9aa1d03c08f0cf2 => -3,
                        0x33d952fcc54c964d => -240,
                        0x37b8c54b99b5c3a5 => -16,
                        0x63dc56578163bc76 => 48,
                        0x6ff7a2bbcc2ed680 => -120,
                        0x941309243bb48eeb => 15,
                        0x968d3c8577b18d2d => 24,
                        0xed04d74cdd8b9877 => -1,
                        0xa81928b0536b8026 => -24,
                        0x6af9aef9d020dbdc => 4,
                        0x0a20d070ec27503e => 6,
                        0xce660b2661a5f670 => 80,
                        0xee6f39a86668b1d8 => -8,
                        0x31ca15c719434b64 => 5,
                        0x66580b8c6fc55812 => 60,
                        0xb802e16655a4d0c2 => -15,
                        0x41197faacc3a74ef => -4,
                        0xbcee6210abb25cbd => 2,
                        0xd570ebd291a05d56 => 1,
                        0x584056c4e4e5ea8a => 120,
                        0xd8bc8f3c8eb7bd15 => -10,
                        0x9c90ebf3a0c1332e => -5,
                        0x8424b68d7a07b04a => 8,
                        0x76bcaa937dbd48f6 => 30,
                        0x80ee83c129fde539 => -20,
                        0x827c3471f6fb075a => 3,
                        0x432965e7dc197b0a => -48,
                        0xadfbb35f2eba95a1 => -12,
                        0x82ad704409428d81 => -40,
                        0x628014e86a639bab => -6,
                        0xf6e78669adbc0876 => -30,
                        0x63b5e889bec042a2 => 10,
                        0x7b43eca45d3cb38c => -80,
                        0x974f110b4bc26192 => 20,
                        0x2210825b9d16bfdc => -2,
                        0xb435ceee34eddd5a => 40,
                        0x5e01c8deb0bca629 => 240,
                        0x149de8d52b424366 => 16,
                    ),
                ),
            ),
        )
    end

    @testset "Reverse combined abstractors" begin
        skeleton = parse_program("(repeat (cons ??(int) ??(list(int))) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[1, 2], [1, 2], [1, 2]]),
            Dict(UInt64(1) => 1, UInt64(2) => [2], UInt64(3) => 3),
        )
    end

    @testset "Reverse map2" begin
        @testset "with holes" begin
            skeleton = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(
                            Abstraction(
                                Apply(
                                    Apply(
                                        every_primitive["repeat"],
                                        Hole(tint, nothing, true, _is_possible_subfunction),
                                    ),
                                    Hole(tint, nothing, true, _is_possible_subfunction),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(t0), nothing, true, nothing),
                ),
                Hole(tlist(t1), nothing, true, nothing),
            )
            @test !is_reversible(skeleton)
        end

        @testset "repeat indices 1 0" begin
            skeleton = parse_program("(map2 (lambda (lambda (repeat \$1 \$0))) ??(list(t0)) ??(list(t1)))")
            @test is_reversible(skeleton)

            p, _ = capture_free_vars(skeleton)

            @test compare_options(
                run_in_reverse(p, [[1, 1, 1], [2, 2], [4]]),
                Dict(UInt64(1) => [1, 2, 4], UInt64(2) => [3, 2, 1]),
            )

            @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 2, 4], UInt64(2) => [3, 2, 1])) ==
                  [[1, 1, 1], [2, 2], [4]]
        end

        @testset "repeat indices 0 1" begin
            skeleton = parse_program("(map2 (lambda (lambda (repeat \$0 \$1))) ??(list(t0)) ??(list(t1)))")
            @test is_reversible(skeleton)

            p, _ = capture_free_vars(skeleton)

            @test compare_options(
                run_in_reverse(p, [[1, 1, 1], [2, 2], [4]]),
                Dict(UInt64(1) => [3, 2, 1], UInt64(2) => [1, 2, 4]),
            )

            @test run_with_arguments(p, [], Dict(UInt64(2) => [1, 2, 4], UInt64(1) => [3, 2, 1])) ==
                  [[1, 1, 1], [2, 2], [4]]
        end

        @testset "cons indices 1 0" begin
            skeleton = parse_program("(map2 (lambda (lambda (cons \$1 \$0))) ??(list(t0)) ??(list(t1)))")
            @test is_reversible(skeleton)
            p, _ = capture_free_vars(skeleton)

            @test compare_options(
                run_in_reverse(p, [[1, 1, 1], [2, 2], [4]]),
                Dict(UInt64(1) => [1, 2, 4], UInt64(2) => [[1, 1], [2], []]),
            )

            @test run_with_arguments(p, [], Dict(UInt64(2) => [[1, 1], [2], []], UInt64(1) => [1, 2, 4])) ==
                  [[1, 1, 1], [2, 2], [4]]
        end

        @testset "cons indices 0 1" begin
            skeleton = parse_program("(map2 (lambda (lambda (cons \$0 \$1))) ??(list(t0)) ??(list(t1)))")
            @test is_reversible(skeleton)
            p, _ = capture_free_vars(skeleton)

            @test compare_options(
                run_in_reverse(p, [[1, 1, 1], [2, 2], [4]]),
                Dict(UInt64(1) => [[1, 1], [2], []], UInt64(2) => [1, 2, 4]),
            )

            @test run_with_arguments(p, [], Dict(UInt64(1) => [[1, 1], [2], []], UInt64(2) => [1, 2, 4])) ==
                  [[1, 1, 1], [2, 2], [4]]
        end
    end

    @testset "Reverse nested map2" begin
        skeleton = parse_program(
            "(map2 (lambda (lambda (map2 (lambda (lambda (repeat \$1 \$0))) \$1 \$0))) ??(list(t0)) ??(list(t1)))",
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[[1, 1, 1], [2, 2], [4]], [[3, 3, 3, 3], [2, 2, 2], [8, 8, 8]]]),
            Dict(UInt64(1) => [[1, 2, 4], [3, 2, 8]], UInt64(2) => [[3, 2, 1], [4, 3, 3]]),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [[1, 2, 4], [3, 2, 8]], UInt64(2) => [[3, 2, 1], [4, 3, 3]]),
        ) == [[[1, 1, 1], [2, 2], [4]], [[3, 3, 3, 3], [2, 2, 2], [8, 8, 8]]]
    end

    @testset "Reverse range" begin
        skeleton = parse_program("(range ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, [0, 1, 2]), Dict(UInt64(1) => 3))
        @test compare_options(run_in_reverse(p, []), Dict(UInt64(1) => 0))
    end

    @testset "Reverse map with range" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(every_primitive["range"], Hole(tint, nothing, true, _is_possible_subfunction))),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test !is_reversible(skeleton)

        skeleton = parse_program("(map (lambda (range \$0)) ??(list(t0)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, [[0, 1, 2], [0, 1], [0, 1, 2, 3]]), Dict(UInt64(1) => [3, 2, 4]))
    end

    @testset "Reverse map set with range" begin
        skeleton = Apply(
            Apply(
                every_primitive["map_set"],
                Abstraction(Apply(every_primitive["range"], Hole(tint, nothing, true, _is_possible_subfunction))),
            ),
            Hole(tset(t0), nothing, true, nothing),
        )
        @test !is_reversible(skeleton)

        skeleton = parse_program("(map_set (lambda (range \$0)) ??(set(t0)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([[0, 1, 2], [0, 1], [0, 1, 2, 3]])),
            Dict(UInt64(1) => Set([3, 2, 4])),
        )
    end

    @testset "Reverse map with repeat" begin
        skeleton = parse_program("(map (lambda (repeat \$0 \$0)) ??(list(t0)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, [[1], [2, 2], [4, 4, 4, 4]]), Dict(UInt64(1) => [1, 2, 4]))
        @test_throws UnifyError run_in_reverse(p, [[1, 1], [2, 2], [4, 4, 4, 4]])

        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 2, 4])) == [[1], [2, 2], [4, 4, 4, 4]]
    end

    @testset "Reverse map set with tuple" begin
        skeleton = Apply(
            Apply(
                every_primitive["map_set"],
                Abstraction(Apply(Apply(every_primitive["tuple2"], Index(0)), FreeVar(tint, nothing))),
            ),
            Hole(tset(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([(3, 2), (1, 2), (6, 2)])),
            Dict(UInt64(1) => 2, UInt64(2) => Set([3, 1, 6])),
        )
        @test_throws UnifyError run_in_reverse(p, Set([(3, 2), (1, 2), (6, 3)]))

        @test run_with_arguments(p, [], Dict(UInt64(1) => 2, UInt64(2) => Set([3, 1, 6]))) ==
              Set([(3, 2), (1, 2), (6, 2)])

        @test compare_options(
            calculate_dependent_vars(p, Dict(UInt64(2) => Set([3, 1, 6])), Set([(3, 2), (1, 2), (6, 2)])),
            Dict(UInt64(1) => 2),
        )
    end

    @testset "Reverse map2 with either options" begin
        skeleton = parse_program("(map2 (lambda (lambda (concat \$1 \$0))) ??(list(t0)) ??(list(t1)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Vector{Any}[[1, 1, 1], [0, 0, 0], [3, 0, 0]]),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x46747a050c3da14d => Any[Any[], Any[0, 0, 0], Any[3, 0, 0]],
                        0x96b63758bb6f2f0b => Any[Any[], Any[0], Any[3]],
                        0x83e3ae72ee56d307 => Any[Any[1, 1, 1], Any[0, 0], Any[3, 0]],
                        0x96ad706bdffc3737 => Any[Any[], Any[0, 0], Any[3]],
                        0x7d67dcff3642e41d => Any[Any[1, 1, 1], Any[], Any[3, 0, 0]],
                        0x1c6caff0063cbea3 => Any[Any[1], Any[0, 0, 0], Any[3, 0]],
                        0x564dd102fdddd0cb => Any[Any[1], Any[], Any[3, 0]],
                        0x92876fbb2f369411 => Any[Any[], Any[], Any[]],
                        0x30ec40ac72825976 => Any[Any[1, 1], Any[0, 0, 0], Any[3, 0, 0]],
                        0x1af6dcc07bf6c7e6 => Any[Any[], Any[], Any[3]],
                        0x16d70977726635b6 => Any[Any[], Any[0], Any[3, 0, 0]],
                        0x2546b0a52616f299 => Any[Any[1, 1, 1], Any[0, 0, 0], Any[]],
                        0xc17d6ba201ce8953 => Any[Any[1], Any[0, 0], Any[]],
                        0x883c711013d62e1a => Any[Any[1, 1, 1], Any[], Any[3]],
                        0xe068d4da7cf8aa2b => Any[Any[1], Any[0], Any[3, 0, 0]],
                        0x7852c6b58b30cd84 => Any[Any[1, 1], Any[0, 0], Any[3]],
                        0xca38cc2b2e4e1cba => Any[Any[1, 1, 1], Any[], Any[3, 0]],
                        0x9db664d29a9e8cf7 => Any[Any[1, 1], Any[0, 0], Any[]],
                        0x6d221685d9c292b2 => Any[Any[1, 1], Any[0, 0, 0], Any[]],
                        0xc1de4c753cf31b7b => Any[Any[1], Any[], Any[3]],
                        0xe584794cd7f2f556 => Any[Any[1, 1, 1], Any[0, 0], Any[3, 0, 0]],
                        0x104d6e2ff7fe3adf => Any[Any[1, 1, 1], Any[0], Any[3, 0]],
                        0x1db98e0c1aed18d2 => Any[Any[], Any[0, 0, 0], Any[3, 0]],
                        0x8b93c58bfc4bb95e => Any[Any[], Any[0, 0], Any[3, 0, 0]],
                        0x40a01147e668e215 => Any[Any[], Any[0, 0, 0], Any[]],
                        0xb5b7bd276ad64956 => Any[Any[1, 1, 1], Any[0, 0, 0], Any[3]],
                        0xfa571018db6b0c60 => Any[Any[1, 1], Any[0, 0], Any[3, 0]],
                        0xdb3ed675876f55cf => Any[Any[1], Any[0, 0], Any[3, 0, 0]],
                        0x029b206ec0b47b46 => Any[Any[], Any[0, 0], Any[]],
                        0x96927b2ba8872ddb => Any[Any[1, 1], Any[0], Any[]],
                        0xfb6ed84453190134 => Any[Any[1], Any[0, 0], Any[3]],
                        0xae66724471f06c8d => Any[Any[1, 1, 1], Any[], Any[]],
                        0xbad1f7d92b7bacff => Any[Any[1, 1], Any[0], Any[3, 0, 0]],
                        0xefe28afb1fe50242 => Any[Any[1, 1, 1], Any[0], Any[3, 0, 0]],
                        0xb96f2353f661d494 => Any[Any[1, 1], Any[0], Any[3]],
                        0x1c277604e2641a1f => Any[Any[1], Any[0], Any[]],
                        0x55a45a5e395b5a0b => Any[Any[1, 1, 1], Any[0], Any[3]],
                        0xcdfbffee4d6bf9ca => Any[Any[1, 1, 1], Any[0, 0], Any[]],
                        0x48f8eeda86de1a1f => Any[Any[1, 1], Any[0, 0, 0], Any[3, 0]],
                        0xcda9647d6dea1da3 => Any[Any[1, 1], Any[], Any[3, 0]],
                        0x5e7a642a2d1b628d => Any[Any[], Any[], Any[3, 0, 0]],
                        0x95ac7f8ec5bd538a => Any[Any[1], Any[0, 0, 0], Any[]],
                        0xfc0a18fbbf73f1e3 => Any[Any[1, 1], Any[0, 0, 0], Any[3]],
                        0x1d620ec2886f5db8 => Any[Any[1], Any[0, 0], Any[3, 0]],
                        0x68d354ad42789e5a => Any[Any[], Any[], Any[3, 0]],
                        0xa6407d4c86f11d55 => Any[Any[1, 1, 1], Any[0, 0, 0], Any[3, 0, 0]],
                        0xa03b597ef9b4fa7e => Any[Any[], Any[0], Any[]],
                        0x38b087e5087db16a => Any[Any[1, 1, 1], Any[0, 0, 0], Any[3, 0]],
                        0xd55627c8129d95ea => Any[Any[1, 1], Any[], Any[]],
                        0x3c60c45fbc886d7a => Any[Any[], Any[0, 0, 0], Any[3]],
                        0xaf78291a35dbf59f => Any[Any[1], Any[0, 0, 0], Any[3]],
                        0x1587ae9a953d6420 => Any[Any[1], Any[0], Any[3, 0]],
                        0xd8a035e1bafc733b => Any[Any[1, 1], Any[], Any[3]],
                        0x4798c578c6551c36 => Any[Any[1], Any[], Any[3, 0, 0]],
                        0x2104fdef0e161adc => Any[Any[1], Any[0], Any[3]],
                        0x985db617f1b898a2 => Any[Any[1, 1], Any[], Any[3, 0, 0]],
                        0xa2bf418f40b96d43 => Any[Any[], Any[0], Any[3, 0]],
                        0x24f657c69402ff66 => Any[Any[1, 1, 1], Any[0], Any[]],
                        0xc093510f28398df6 => Any[Any[1], Any[0, 0, 0], Any[3, 0, 0]],
                        0x6496dda12e1a4c36 => Any[Any[1], Any[], Any[]],
                        0x5b73de666b46ecbf => Any[Any[], Any[0, 0], Any[3, 0]],
                        0x8dbe9b502cdd76d0 => Any[Any[1, 1], Any[0], Any[3, 0]],
                        0xeccdc5b37d74b46b => Any[Any[1, 1], Any[0, 0], Any[3, 0, 0]],
                        0xa3fd43ac20d453b3 => Any[Any[1, 1, 1], Any[0, 0], Any[3]],
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x46747a050c3da14d => Any[Any[1, 1, 1], Any[], Any[]],
                        0x96b63758bb6f2f0b => Any[Any[1, 1, 1], Any[0, 0], Any[0, 0]],
                        0x83e3ae72ee56d307 => Any[Any[], Any[0], Any[0]],
                        0x96ad706bdffc3737 => Any[Any[1, 1, 1], Any[0], Any[0, 0]],
                        0x7d67dcff3642e41d => Any[Any[], Any[0, 0, 0], Any[]],
                        0x1c6caff0063cbea3 => Any[Any[1, 1], Any[], Any[0]],
                        0x564dd102fdddd0cb => Any[Any[1, 1], Any[0, 0, 0], Any[0]],
                        0x92876fbb2f369411 => Any[Any[1, 1, 1], Any[0, 0, 0], Any[3, 0, 0]],
                        0x30ec40ac72825976 => Any[Any[1], Any[], Any[]],
                        0x1af6dcc07bf6c7e6 => Any[Any[1, 1, 1], Any[0, 0, 0], Any[0, 0]],
                        0x16d70977726635b6 => Any[Any[1, 1, 1], Any[0, 0], Any[]],
                        0x2546b0a52616f299 => Any[Any[], Any[], Any[3, 0, 0]],
                        0xc17d6ba201ce8953 => Any[Any[1, 1], Any[0], Any[3, 0, 0]],
                        0x883c711013d62e1a => Any[Any[], Any[0, 0, 0], Any[0, 0]],
                        0xe068d4da7cf8aa2b => Any[Any[1, 1], Any[0, 0], Any[]],
                        0x7852c6b58b30cd84 => Any[Any[1], Any[0], Any[0, 0]],
                        0xca38cc2b2e4e1cba => Any[Any[], Any[0, 0, 0], Any[0]],
                        0x9db664d29a9e8cf7 => Any[Any[1], Any[0], Any[3, 0, 0]],
                        0x6d221685d9c292b2 => Any[Any[1], Any[], Any[3, 0, 0]],
                        0xc1de4c753cf31b7b => Any[Any[1, 1], Any[0, 0, 0], Any[0, 0]],
                        0xe584794cd7f2f556 => Any[Any[], Any[0], Any[]],
                        0x104d6e2ff7fe3adf => Any[Any[], Any[0, 0], Any[0]],
                        0x1db98e0c1aed18d2 => Any[Any[1, 1, 1], Any[], Any[0]],
                        0x8b93c58bfc4bb95e => Any[Any[1, 1, 1], Any[0], Any[]],
                        0x40a01147e668e215 => Any[Any[1, 1, 1], Any[], Any[3, 0, 0]],
                        0xb5b7bd276ad64956 => Any[Any[], Any[], Any[0, 0]],
                        0xfa571018db6b0c60 => Any[Any[1], Any[0], Any[0]],
                        0xdb3ed675876f55cf => Any[Any[1, 1], Any[0], Any[]],
                        0x029b206ec0b47b46 => Any[Any[1, 1, 1], Any[0], Any[3, 0, 0]],
                        0x96927b2ba8872ddb => Any[Any[1], Any[0, 0], Any[3, 0, 0]],
                        0xfb6ed84453190134 => Any[Any[1, 1], Any[0], Any[0, 0]],
                        0xae66724471f06c8d => Any[Any[], Any[0, 0, 0], Any[3, 0, 0]],
                        0xbad1f7d92b7bacff => Any[Any[1], Any[0, 0], Any[]],
                        0xefe28afb1fe50242 => Any[Any[], Any[0, 0], Any[]],
                        0xb96f2353f661d494 => Any[Any[1], Any[0, 0], Any[0, 0]],
                        0x1c277604e2641a1f => Any[Any[1, 1], Any[0, 0], Any[3, 0, 0]],
                        0x55a45a5e395b5a0b => Any[Any[], Any[0, 0], Any[0, 0]],
                        0xcdfbffee4d6bf9ca => Any[Any[], Any[0], Any[3, 0, 0]],
                        0x48f8eeda86de1a1f => Any[Any[1], Any[], Any[0]],
                        0xcda9647d6dea1da3 => Any[Any[1], Any[0, 0, 0], Any[0]],
                        0x5e7a642a2d1b628d => Any[Any[1, 1, 1], Any[0, 0, 0], Any[]],
                        0x95ac7f8ec5bd538a => Any[Any[1, 1], Any[], Any[3, 0, 0]],
                        0xfc0a18fbbf73f1e3 => Any[Any[1], Any[], Any[0, 0]],
                        0x1d620ec2886f5db8 => Any[Any[1, 1], Any[0], Any[0]],
                        0x68d354ad42789e5a => Any[Any[1, 1, 1], Any[0, 0, 0], Any[0]],
                        0xa6407d4c86f11d55 => Any[Any[], Any[], Any[]],
                        0xa03b597ef9b4fa7e => Any[Any[1, 1, 1], Any[0, 0], Any[3, 0, 0]],
                        0x38b087e5087db16a => Any[Any[], Any[], Any[0]],
                        0xd55627c8129d95ea => Any[Any[1], Any[0, 0, 0], Any[3, 0, 0]],
                        0x3c60c45fbc886d7a => Any[Any[1, 1, 1], Any[], Any[0, 0]],
                        0xaf78291a35dbf59f => Any[Any[1, 1], Any[], Any[0, 0]],
                        0x1587ae9a953d6420 => Any[Any[1, 1], Any[0, 0], Any[0]],
                        0xd8a035e1bafc733b => Any[Any[1], Any[0, 0, 0], Any[0, 0]],
                        0x4798c578c6551c36 => Any[Any[1, 1], Any[0, 0, 0], Any[]],
                        0x2104fdef0e161adc => Any[Any[1, 1], Any[0, 0], Any[0, 0]],
                        0x985db617f1b898a2 => Any[Any[1], Any[0, 0, 0], Any[]],
                        0xa2bf418f40b96d43 => Any[Any[1, 1, 1], Any[0, 0], Any[0]],
                        0x24f657c69402ff66 => Any[Any[], Any[0, 0], Any[3, 0, 0]],
                        0xc093510f28398df6 => Any[Any[1, 1], Any[], Any[]],
                        0x6496dda12e1a4c36 => Any[Any[1, 1], Any[0, 0, 0], Any[3, 0, 0]],
                        0x5b73de666b46ecbf => Any[Any[1, 1, 1], Any[0], Any[0]],
                        0x8dbe9b502cdd76d0 => Any[Any[1], Any[0, 0], Any[0]],
                        0xeccdc5b37d74b46b => Any[Any[1], Any[0], Any[]],
                        0xa3fd43ac20d453b3 => Any[Any[], Any[0], Any[0, 0]],
                    ),
                ),
            ),
        )
    end

    @testset "Reverse map with either options" begin
        skeleton = parse_program("(map (lambda (concat \$0 \$0)) ??(list(t0)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Vector{Any}[[1, 2, 1, 2], [0, 0, 0, 0], [3, 0, 1, 3, 0, 1]]),
            Dict(UInt64(1) => [[1, 2], [0, 0], [3, 0, 1]]),
        )
    end

    @testset "Reverse map with either options with free var" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(Apply(every_primitive["concat"], Index(0)), FreeVar(tlist(tint), nothing))),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Vector{Any}[[1, 1, 1, 0, 0], [0, 0, 0], [3, 0, 0]]),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0xdab1e199b1c94074 => Any[],
                        0x0c3b2c341e5c3951 => Any[0],
                        0x75e9840090e65b2f => Any[0, 0],
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0xdab1e199b1c94074 => Any[Any[1, 1, 1, 0, 0], Any[0, 0, 0], Any[3, 0, 0]],
                        0x0c3b2c341e5c3951 => Any[Any[1, 1, 1, 0], Any[0, 0], Any[3, 0]],
                        0x75e9840090e65b2f => Any[Any[1, 1, 1], Any[0], Any[3]],
                    ),
                ),
            ),
        )
    end

    @testset "Reverse map with either options with free var and plus" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(Apply(every_primitive["+"], FreeVar(tint, nothing)), Index(0))),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [12, 0, 36, 2]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x743f54b86bcb42e8 => [13, 1, 37, 3],
                        0x1cedc8e9cad8591d => [12, 0, 36, 2],
                        0xf66d702ce1bf2b1b => [9, -3, 33, -1],
                        0xe8fe0460914ccaa8 => [-3, -15, 21, -13],
                        0xc598cef5c8458c5e => [11, -1, 35, 1],
                        0xbbf1284c6c04f72f => [0, -12, 24, -10],
                        0x31bde8e087a25a52 => [10, -2, 34, 0],
                        0x73f3dbffc28fdc80 => AbductibleValue([any_object, any_object, any_object, any_object]),
                        0x2b77470a6d7e53ec => [-2, -14, 22, -12],
                        0x91bcc2466dfa2ad8 => [-1, -13, 23, -11],
                        0xfa8b6e9d6901f238 => [1, -11, 25, -9],
                        0x5aed6f2b2e1fd626 => [14, 2, 38, 4],
                        0xfa13600035aab273 => [3, -9, 27, -7],
                        0xdc9d2aa25b9f8d1d => [15, 3, 39, 5],
                        0x47b2ae44b3de4601 => [2, -10, 26, -8],
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x743f54b86bcb42e8 => -1,
                        0x1cedc8e9cad8591d => 0,
                        0xf66d702ce1bf2b1b => 3,
                        0xe8fe0460914ccaa8 => 15,
                        0xc598cef5c8458c5e => 1,
                        0xbbf1284c6c04f72f => 12,
                        0x31bde8e087a25a52 => 2,
                        0x73f3dbffc28fdc80 => AbductibleValue(any_object),
                        0x2b77470a6d7e53ec => 14,
                        0x91bcc2466dfa2ad8 => 13,
                        0xfa8b6e9d6901f238 => 11,
                        0x5aed6f2b2e1fd626 => -2,
                        0xfa13600035aab273 => 9,
                        0xdc9d2aa25b9f8d1d => -3,
                        0x47b2ae44b3de4601 => 10,
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict(UInt64(1) => 2), [12, 0, 36, 2]),
            Dict(UInt64(2) => [10, -2, 34, 0]),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict(UInt64(2) => [9, -3, 33, -1]), [12, 0, 36, 2]),
            Dict(UInt64(1) => 3),
        )

        @test_throws ErrorException compare_options(
            calculate_dependent_vars(p, Dict(UInt64(2) => [9, -3, 37, -1]), [12, 0, 36, 2]),
            Dict(UInt64(1) => 3),
        )
    end

    @testset "Reverse map with either options with free var with plus and mult" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(every_primitive["*"], Index(0)),
                        Apply(
                            Apply(every_primitive["*"], Index(0)),
                            Apply(Apply(every_primitive["+"], FreeVar(tint, nothing)), Index(0)),
                        ),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [12, 0, 36, 2]),
            Dict(
                UInt64(1) => 1,
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(0x83f70505be91eff8 => Any[2, 0, 3, 1], 0x0853c75d0ab1b91c => Any[2, -1, 3, 1]),
                ),
            ),
        )
    end

    @testset "Reverse map with either options with free var with plus and mult 2" begin
        # (map (lambda (* $0 (* (+ $v651 $0) $v652))) $v653)
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(every_primitive["*"], Index(0)),
                        Apply(
                            Apply(
                                every_primitive["*"],
                                Apply(Apply(every_primitive["+"], FreeVar(tint, nothing)), Index(0)),
                            ),
                            FreeVar(tint, nothing),
                        ),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test_throws ErrorException compare_options(
            run_in_reverse(p, [1, 2, 3]),
            Dict(
                UInt64(1) => 1,
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(0x83f70505be91eff8 => Any[2, 0, 3, 1], 0x0853c75d0ab1b91c => Any[2, -1, 3, 1]),
                ),
            ),
        )
    end

    @testset "Reverse map with either options with free var with plus and mult 3" begin
        # (map (lambda (* $0 (+ $v154 $0))) $v155)
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(every_primitive["*"], Index(0)),
                        Apply(Apply(every_primitive["+"], FreeVar(tint, nothing)), Index(0)),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [0, 1, 4]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xa053df3c4db3e4d3 => Any[0, -1, -2],
                        0x5d2bb9255b9c58d5 => Any[0, 1, 2],
                        0x5ba8072154451d21 => Any[0, -1, 2],
                        0x97d800ee965ba928 => Any[0, 1, -2],
                    ),
                ),
                0x0000000000000001 => 0,
            ),
        )
    end

    @testset "Reverse map with either options with free var with plus and mult 4" begin
        skeleton = parse_program("(map (lambda (* \$0 (+ \$0 \$0))) ??(list(t0)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test_throws ErrorException compare_options(
            run_in_reverse(p, [0, 2, 12, 2, 11, 0]),
            Dict(
                UInt64(1) => 1,
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(0x83f70505be91eff8 => Any[2, 0, 3, 1], 0x0853c75d0ab1b91c => Any[2, -1, 3, 1]),
                ),
            ),
        )
    end

    @testset "Reverse map with either options with free var with plus and mult 5" begin
        # (map (lambda (* $0 (* (+ $v2080 $0) $v2081))) $v2082)
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(every_primitive["*"], Index(0)),
                        Apply(
                            Apply(
                                every_primitive["*"],
                                Apply(Apply(every_primitive["+"], FreeVar(tint, nothing)), Index(0)),
                            ),
                            FreeVar(tint, nothing),
                        ),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test_throws ErrorException compare_options(
            run_in_reverse(p, [16, 10, 7, 12, 13, 3]),
            Dict(
                UInt64(1) => 1,
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(0x83f70505be91eff8 => Any[2, 0, 3, 1], 0x0853c75d0ab1b91c => Any[2, -1, 3, 1]),
                ),
            ),
        )
    end

    @testset "Reverse map2 with plus" begin
        skeleton = parse_program("(map2 (lambda (lambda (+ \$0 \$1))) ??(list(t0)) ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [3, 2]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x7d2fb8f58da9eb62 => AbductibleValue(Any[any_object, -3]),
                        0x09d499d0f83dad4e => AbductibleValue(Any[any_object, 2]),
                        0xb130466300e8e71e => AbductibleValue(Any[any_object, 3]),
                        0x52f3a5765320e7d8 => AbductibleValue(Any[any_object, 5]),
                        0x635c5e2a7d5d15ef => AbductibleValue([any_object, any_object]),
                        0x75c8b2557bc4c2ed => AbductibleValue(Any[any_object, -1]),
                        0x28c516e8fa249f7b => AbductibleValue(Any[any_object, -2]),
                        0x8be335ff9a95004d => AbductibleValue(Any[any_object, 0]),
                        0x114739fa3de68684 => AbductibleValue(Any[any_object, 4]),
                        0x52223593f0227e0f => AbductibleValue(Any[any_object, 1]),
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x7d2fb8f58da9eb62 => AbductibleValue(Any[any_object, 5]),
                        0x09d499d0f83dad4e => AbductibleValue(Any[any_object, 0]),
                        0xb130466300e8e71e => AbductibleValue(Any[any_object, -1]),
                        0x52f3a5765320e7d8 => AbductibleValue(Any[any_object, -3]),
                        0x635c5e2a7d5d15ef => AbductibleValue([any_object, any_object]),
                        0x75c8b2557bc4c2ed => AbductibleValue(Any[any_object, 3]),
                        0x28c516e8fa249f7b => AbductibleValue(Any[any_object, 4]),
                        0x8be335ff9a95004d => AbductibleValue(Any[any_object, 2]),
                        0x114739fa3de68684 => AbductibleValue(Any[any_object, -2]),
                        0x52223593f0227e0f => AbductibleValue(Any[any_object, 1]),
                    ),
                ),
            ),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => [1, 2]), [3, 2]) == Dict(UInt64(2) => [2, 0])
    end

    @testset "Reverse map with plus and free var" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(Apply(every_primitive["+"], FreeVar(tint, nothing)), Index(0))),
            ),
            Hole(tlist(tint), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [3, 2]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x7e987f6ace15a7f7 => [1, 0],
                        0x51144d3768e88eef => [0, -1],
                        0xae04ee8f70df7180 => [2, 1],
                        0xc7fd9e16dafc209b => [-2, -3],
                        0x2f4dd2ead2dee45f => EitherOptions(
                            Dict{UInt64,Any}(
                                0x14b6256f0375a776 => [1, 0],
                                0x789def85a710a675 => [5, 4],
                                0x6001e40de2c9b6e5 => [6, 5],
                                0x24af14392931b9f2 => [-1, -2],
                                0xcb45e82c38a335c2 => [-2, -3],
                                0x76db39bcdc36e2a7 => [0, -1],
                                0x4d86998475269179 => [2, 1],
                                0xab000386c5c70a8a => [4, 3],
                                0xa4bca046e0f212f6 => AbductibleValue([any_object, any_object]),
                                0x4bb0e9ccd4db50f8 => [3, 2],
                            ),
                        ),
                        0x75bb3259c6e70688 => [6, 5],
                        0x98013a22f0c7c03e => [-3, -4],
                        0xd0f7427aec52ce60 => [-1, -2],
                        0xedc4ce9ac3a20228 => [5, 4],
                        0xeeab88762f51080f => [4, 3],
                        0xd7918dea99162163 => [3, 2],
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x7e987f6ace15a7f7 => 2,
                        0x51144d3768e88eef => 3,
                        0xae04ee8f70df7180 => 1,
                        0xc7fd9e16dafc209b => 5,
                        0x2f4dd2ead2dee45f => EitherOptions(
                            Dict{UInt64,Any}(
                                0x14b6256f0375a776 => 2,
                                0x789def85a710a675 => -2,
                                0x6001e40de2c9b6e5 => -3,
                                0x24af14392931b9f2 => 4,
                                0xcb45e82c38a335c2 => 5,
                                0x76db39bcdc36e2a7 => 3,
                                0x4d86998475269179 => 1,
                                0xab000386c5c70a8a => -1,
                                0xa4bca046e0f212f6 => AbductibleValue(any_object),
                                0x4bb0e9ccd4db50f8 => 0,
                            ),
                        ),
                        0x75bb3259c6e70688 => -3,
                        0x98013a22f0c7c03e => 6,
                        0xd0f7427aec52ce60 => 4,
                        0xedc4ce9ac3a20228 => -2,
                        0xeeab88762f51080f => -1,
                        0xd7918dea99162163 => 0,
                    ),
                ),
            ),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => [2, 1]), [3, 2]) == Dict(UInt64(1) => 1)
        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), [3, 2]) == Dict(UInt64(2) => [2, 1])
    end

    @testset "Reverse rows with either" begin
        skeleton = Apply(every_primitive["rows"], Hole(tgrid(tcolor), nothing, true, nothing))
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test_throws ErrorException compare_options(
            run_in_reverse(
                p,
                EitherOptions(
                    Dict{UInt64,Any}(
                        0x46747a050c3da14d => Any[Any[], Any[0, 0, 0], Any[3, 0, 0]],
                        0x96b63758bb6f2f0b => Any[Any[], Any[0], Any[3]],
                        0x83e3ae72ee56d307 => Any[Any[1, 1, 1], Any[0, 0], Any[3, 0]],
                        0x96ad706bdffc3737 => Any[Any[], Any[0, 0], Any[3]],
                        0x7d67dcff3642e41d => Any[Any[1, 1, 1], Any[], Any[3, 0, 0]],
                        0x1c6caff0063cbea3 => Any[Any[1], Any[0, 0, 0], Any[3, 0]],
                        0x564dd102fdddd0cb => Any[Any[1], Any[], Any[3, 0]],
                        0x92876fbb2f369411 => Any[Any[], Any[], Any[]],
                        0x30ec40ac72825976 => Any[Any[1, 1], Any[0, 0, 0], Any[3, 0, 0]],
                        0x1af6dcc07bf6c7e6 => Any[Any[], Any[], Any[3]],
                        0x16d70977726635b6 => Any[Any[], Any[0], Any[3, 0, 0]],
                        0x2546b0a52616f299 => Any[Any[1, 1, 1], Any[0, 0, 0], Any[]],
                        0xc17d6ba201ce8953 => Any[Any[1], Any[0, 0], Any[]],
                        0x883c711013d62e1a => Any[Any[1, 1, 1], Any[], Any[3]],
                        0xe068d4da7cf8aa2b => Any[Any[1], Any[0], Any[3, 0, 0]],
                        0x7852c6b58b30cd84 => Any[Any[1, 1], Any[0, 0], Any[3]],
                        0xca38cc2b2e4e1cba => Any[Any[1, 1, 1], Any[], Any[3, 0]],
                        0x9db664d29a9e8cf7 => Any[Any[1, 1], Any[0, 0], Any[]],
                        0x6d221685d9c292b2 => Any[Any[1, 1], Any[0, 0, 0], Any[]],
                        0xc1de4c753cf31b7b => Any[Any[1], Any[], Any[3]],
                        0xe584794cd7f2f556 => Any[Any[1, 1, 1], Any[0, 0], Any[3, 0, 0]],
                        0x104d6e2ff7fe3adf => Any[Any[1, 1, 1], Any[0], Any[3, 0]],
                        0x1db98e0c1aed18d2 => Any[Any[], Any[0, 0, 0], Any[3, 0]],
                        0x8b93c58bfc4bb95e => Any[Any[], Any[0, 0], Any[3, 0, 0]],
                        0x40a01147e668e215 => Any[Any[], Any[0, 0, 0], Any[]],
                        0xb5b7bd276ad64956 => Any[Any[1, 1, 1], Any[0, 0, 0], Any[3]],
                        0xfa571018db6b0c60 => Any[Any[1, 1], Any[0, 0], Any[3, 0]],
                        0xdb3ed675876f55cf => Any[Any[1], Any[0, 0], Any[3, 0, 0]],
                        0x029b206ec0b47b46 => Any[Any[], Any[0, 0], Any[]],
                        0x96927b2ba8872ddb => Any[Any[1, 1], Any[0], Any[]],
                        0xfb6ed84453190134 => Any[Any[1], Any[0, 0], Any[3]],
                        0xae66724471f06c8d => Any[Any[1, 1, 1], Any[], Any[]],
                        0xbad1f7d92b7bacff => Any[Any[1, 1], Any[0], Any[3, 0, 0]],
                        0xefe28afb1fe50242 => Any[Any[1, 1, 1], Any[0], Any[3, 0, 0]],
                        0xb96f2353f661d494 => Any[Any[1, 1], Any[0], Any[3]],
                        0x1c277604e2641a1f => Any[Any[1], Any[0], Any[]],
                        0x55a45a5e395b5a0b => Any[Any[1, 1, 1], Any[0], Any[3]],
                        0xcdfbffee4d6bf9ca => Any[Any[1, 1, 1], Any[0, 0], Any[]],
                        0x48f8eeda86de1a1f => Any[Any[1, 1], Any[0, 0, 0], Any[3, 0]],
                        0xcda9647d6dea1da3 => Any[Any[1, 1], Any[], Any[3, 0]],
                        0x5e7a642a2d1b628d => Any[Any[], Any[], Any[3, 0, 0]],
                        0x95ac7f8ec5bd538a => Any[Any[1], Any[0, 0, 0], Any[]],
                        0xfc0a18fbbf73f1e3 => Any[Any[1, 1], Any[0, 0, 0], Any[3]],
                        0x1d620ec2886f5db8 => Any[Any[1], Any[0, 0], Any[3, 0]],
                        0x68d354ad42789e5a => Any[Any[], Any[], Any[3, 0]],
                        0xa6407d4c86f11d55 => Any[Any[1, 1, 1], Any[0, 0, 0], Any[3, 0, 0]],
                        0xa03b597ef9b4fa7e => Any[Any[], Any[0], Any[]],
                        0x38b087e5087db16a => Any[Any[1, 1, 1], Any[0, 0, 0], Any[3, 0]],
                        0xd55627c8129d95ea => Any[Any[1, 1], Any[], Any[]],
                        0x3c60c45fbc886d7a => Any[Any[], Any[0, 0, 0], Any[3]],
                        0xaf78291a35dbf59f => Any[Any[1], Any[0, 0, 0], Any[3]],
                        0x1587ae9a953d6420 => Any[Any[1], Any[0], Any[3, 0]],
                        0xd8a035e1bafc733b => Any[Any[1, 1], Any[], Any[3]],
                        0x4798c578c6551c36 => Any[Any[1], Any[], Any[3, 0, 0]],
                        0x2104fdef0e161adc => Any[Any[1], Any[0], Any[3]],
                        0x985db617f1b898a2 => Any[Any[1, 1], Any[], Any[3, 0, 0]],
                        0xa2bf418f40b96d43 => Any[Any[], Any[0], Any[3, 0]],
                        0x24f657c69402ff66 => Any[Any[1, 1, 1], Any[0], Any[]],
                        0xc093510f28398df6 => Any[Any[1], Any[0, 0, 0], Any[3, 0, 0]],
                        0x6496dda12e1a4c36 => Any[Any[1], Any[], Any[]],
                        0x5b73de666b46ecbf => Any[Any[], Any[0, 0], Any[3, 0]],
                        0x8dbe9b502cdd76d0 => Any[Any[1, 1], Any[0], Any[3, 0]],
                        0xeccdc5b37d74b46b => Any[Any[1, 1], Any[0, 0], Any[3, 0, 0]],
                        0xa3fd43ac20d453b3 => Any[Any[1, 1, 1], Any[0, 0], Any[3]],
                    ),
                ),
            ),
            Dict{UInt64,Any}(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xa6407d4c86f11d55 => Any[1 1 1; 0 0 0; 3 0 0],
                        0xfa571018db6b0c60 => Any[1 1; 0 0; 3 0],
                        0x2104fdef0e161adc => Any[1; 0; 3;;],
                        0x92876fbb2f369411 => Matrix{Any}(undef, 3, 0),
                    ),
                ),
            ),
        )
    end

    @testset "Reverse rev select" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["rev_select"],
                    Abstraction(
                        Apply(Apply(every_primitive["eq?"], Index(0)), Hole(t0, nothing, false, _is_possible_selector)),
                    ),
                ),
                Hole(tlist(tcolor), nothing, true, nothing),
            ),
            Hole(tlist(tcolor), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [1, 2, 1, 3, 2, 1]),
            Dict(
                UInt64(1) =>
                    EitherOptions(Dict(0xa0664d92ec387436 => 3, 0x6711a85d77d098cf => 1, 0xfcd4cc2c187414b6 => 2)),
                UInt64(2) => EitherOptions(
                    Dict(
                        0xa0664d92ec387436 =>
                            PatternWrapper(Any[any_object, any_object, any_object, 3, any_object, any_object]),
                        0x6711a85d77d098cf => PatternWrapper(Any[1, any_object, 1, any_object, any_object, 1]),
                        0xfcd4cc2c187414b6 =>
                            PatternWrapper(Any[any_object, 2, any_object, any_object, 2, any_object]),
                    ),
                ),
                UInt64(3) => EitherOptions(
                    Dict(
                        0xa0664d92ec387436 => Any[1, 2, 1, nothing, 2, 1],
                        0x6711a85d77d098cf => Any[nothing, 2, nothing, 3, 2, nothing],
                        0xfcd4cc2c187414b6 => Any[1, nothing, 1, 3, nothing, 1],
                    ),
                ),
            ),
        )
    end

    @testset "Reverse rev select set" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["rev_select_set"],
                    Abstraction(
                        Apply(Apply(every_primitive["eq?"], Index(0)), Hole(t0, nothing, false, _is_possible_selector)),
                    ),
                ),
                Hole(tset(tcolor), nothing, true, nothing),
            ),
            Hole(tset(tcolor), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([1, 2, 3])),
            Dict(
                UInt64(1) =>
                    EitherOptions(Dict(0x6711a85d77d098cf => 2, 0x7fec434e3caa5c07 => 1, 0xc99cccbee72d140a => 3)),
                UInt64(2) => EitherOptions(
                    Dict(
                        0x6711a85d77d098cf => Set(Any[2]),
                        0x7fec434e3caa5c07 => Set(Any[1]),
                        0xc99cccbee72d140a => Set(Any[3]),
                    ),
                ),
                UInt64(3) => EitherOptions(
                    Dict(
                        0x6711a85d77d098cf => Set(Any[3, 1]),
                        0x7fec434e3caa5c07 => Set(Any[2, 3]),
                        0xc99cccbee72d140a => Set(Any[2, 1]),
                    ),
                ),
            ),
        )
    end

    @testset "Reverse rev select with empty" begin
        skeleton = parse_program("(rev_select (lambda (empty? \$0)) ??(list(list(int))) ??(list(list(int))))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[0, 1, 2], [], [0, 1, 2, 3]]),
            Dict(
                UInt64(1) => PatternWrapper([any_object, [], any_object]),
                UInt64(2) => [[0, 1, 2], nothing, [0, 1, 2, 3]],
            ),
        )
    end

    @testset "Invented abstractor" begin
        source = "#(lambda (lambda (repeat (cons \$1 \$0))))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = parse_program("(#(lambda (lambda (repeat (cons \$1 \$0)))) ??(t0) ??(list(t0)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3]]),
            Dict(UInt64(1) => 1, UInt64(2) => [2, 3], UInt64(3) => 4),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => 1, UInt64(2) => [2, 3], UInt64(3) => 4)) ==
              [[1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3]]
    end

    @testset "Invented abstractor with same index" begin
        source = "#(lambda (* \$0 \$0))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = parse_program("(#(lambda (* \$0 \$0)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, 16),
            Dict(UInt64(1) => EitherOptions(Dict{UInt64,Any}(0x61b87a7d8efbbc18 => -4, 0x34665f52efaea3b2 => 4))),
        )
    end

    @testset "Invented abstractor with same index combined" begin
        source = "#(lambda (* \$0 (* \$0 \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = parse_program("(#(lambda (* \$0 (* \$0 \$0))) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, 64), Dict(UInt64(1) => 4))
    end

    @testset "Invented abstractor with same index combined #2" begin
        source = "#(lambda (* (* \$0 \$0) \$0))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = parse_program("(#(lambda (* (* \$0 \$0) \$0)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, 64), Dict(UInt64(1) => 4))
    end

    @testset "Invented abstractor with same index combined #3" begin
        source = "#(lambda (* (* \$0 \$0) (* \$0 \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = parse_program("(#(lambda (* (* \$0 \$0) (* \$0 \$0))) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, 16),
            Dict(UInt64(1) => EitherOptions(Dict{UInt64,Any}(0x791ecca7c8ec2799 => -2, 0x026990618cb235dc => 2))),
        )
    end

    @testset "Invented abstractor with range" begin
        source = "#(lambda (repeat (range \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = parse_program("(#(lambda (repeat (range \$0))) ??(int) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]]),
            Dict(UInt64(1) => 4, UInt64(2) => 3),
        )
    end

    @testset "Invented abstractor with range in map2" begin
        source = "#(lambda (repeat (range \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton =
            parse_program("(map2 (lambda (lambda (#(lambda (repeat (range \$0))) \$1 \$0))) ??(list(t0)) ??(list(t1)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]], [[0, 1, 2], [0, 1, 2]]]),
            Dict(UInt64(1) => [4, 3], UInt64(2) => [4, 2]),
        )
    end

    @testset "Reversed map with rev_select" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(
                            Apply(
                                every_primitive["rev_select"],
                                Abstraction(
                                    Apply(
                                        Apply(every_primitive["eq?"], Index(0)),
                                        Hole(t1, nothing, false, _is_possible_selector),
                                    ),
                                ),
                            ),
                            Hole(tlist(tcolor), nothing, true, _is_possible_subfunction),
                        ),
                        Hole(tlist(tcolor), nothing, true, _is_possible_subfunction),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )

        @test !is_reversible(skeleton)
    end

    @testset "Reverse list elements" begin
        skeleton = parse_program("(rev_list_elements ??(list(tuple2(int, int))) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [3, 2, 1]),
            Dict(UInt64(1) => Set([(1, 3), (2, 2), (3, 1)]), UInt64(2) => 3),
        )
        @test compare_options(
            run_in_reverse(p, [3, nothing, 1]),
            Dict(UInt64(1) => Set([(1, 3), (3, 1)]), UInt64(2) => 3),
        )
        @test compare_options(
            run_in_reverse(p, [3, 2, nothing]),
            Dict(UInt64(1) => Set([(1, 3), (2, 2)]), UInt64(2) => 3),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => [(1, 3), (2, 2), (3, 1)], UInt64(2) => 3)) == [3, 2, 1]
        @test run_with_arguments(p, [], Dict(UInt64(1) => [(1, 3), (3, 1)], UInt64(2) => 3)) == [3, nothing, 1]
        @test run_with_arguments(p, [], Dict(UInt64(1) => [(1, 3), (2, 2)], UInt64(2) => 3)) == [3, 2, nothing]
    end

    @testset "Reverse grid elements" begin
        skeleton = parse_program("(rev_grid_elements ??(list(tuple2(tuple2(int, int), int))) ??(int) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[3, 2, 1] [4, 5, 6]]),
            Dict(
                UInt64(1) => Set([((1, 1), 3), ((1, 2), 4), ((2, 1), 2), ((2, 2), 5), ((3, 1), 1), ((3, 2), 6)]),
                UInt64(2) => 3,
                UInt64(3) => 2,
            ),
        )
        @test compare_options(
            run_in_reverse(p, [[3, nothing, 1] [4, 5, 6]]),
            Dict(
                UInt64(1) => Set([((1, 1), 3), ((1, 2), 4), ((2, 2), 5), ((3, 1), 1), ((3, 2), 6)]),
                UInt64(2) => 3,
                UInt64(3) => 2,
            ),
        )
        @test compare_options(
            run_in_reverse(p, [[3, 2, 1] [nothing, nothing, nothing]]),
            Dict(UInt64(1) => Set([((1, 1), 3), ((2, 1), 2), ((3, 1), 1)]), UInt64(2) => 3, UInt64(3) => 2),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(
                UInt64(1) => [((1, 1), 3), ((1, 2), 4), ((2, 1), 2), ((2, 2), 5), ((3, 1), 1), ((3, 2), 6)],
                UInt64(2) => 3,
                UInt64(3) => 2,
            ),
        ) == [[3, 2, 1] [4, 5, 6]]
        @test run_with_arguments(
            p,
            [],
            Dict(
                UInt64(1) => [((1, 1), 3), ((1, 2), 4), ((2, 2), 5), ((3, 1), 1), ((3, 2), 6)],
                UInt64(2) => 3,
                UInt64(3) => 2,
            ),
        ) == [[3, nothing, 1] [4, 5, 6]]
        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [((1, 1), 3), ((2, 1), 2), ((3, 1), 1)], UInt64(2) => 3, UInt64(3) => 2),
        ) == [[3, 2, 1] [nothing, nothing, nothing]]
    end

    @testset "Reverse zip2" begin
        skeleton = parse_program("(zip2 ??(list(int)) ??(list(color)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [(1, 3), (2, 2), (3, 1)]),
            Dict(UInt64(1) => [1, 2, 3], UInt64(2) => [3, 2, 1]),
        )
        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 2, 3], UInt64(2) => [3, 2, 1])) ==
              [(1, 3), (2, 2), (3, 1)]
    end

    @testset "Reverse zip_grid2" begin
        skeleton = parse_program("(zip_grid2 ??(grid(int)) ??(grid(color)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[(1, 3), (2, 2), (3, 1)] [(4, 5), (9, 2), (2, 5)]]),
            Dict(UInt64(1) => [[1, 2, 3] [4, 9, 2]], UInt64(2) => [[3, 2, 1] [5, 2, 5]]),
        )
        @test run_with_arguments(p, [], Dict(UInt64(1) => [[1, 2, 3] [4, 9, 2]], UInt64(2) => [[3, 2, 1] [5, 2, 5]])) ==
              [[(1, 3), (2, 2), (3, 1)] [(4, 5), (9, 2), (2, 5)]]
    end

    @testset "Reverse rev_fold" begin
        skeleton = parse_program("(rev_fold (lambda (lambda (cons \$1 \$0))) empty ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, [2, 4, 1, 4, 1]), Dict(UInt64(1) => [1, 4, 1, 4, 2]))

        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 4, 1, 4, 2])) == [2, 4, 1, 4, 1]
    end

    @testset "Reverse fold" begin
        skeleton = parse_program("(fold (lambda (lambda (cons \$1 \$0))) ??(list(int)) ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [2, 4, 1, 4, 1]),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x5a93e9ec4bc05a56 => Any[2, 4],
                        0x6a7634569af3396c => Any[2, 4, 1, 4],
                        0x51aaed7b1c6bb305 => Any[2, 4, 1, 4, 1],
                        0xb693e3cf592eb63c => Any[2],
                        0x49021a5ed5ec68f1 => Any[],
                        0x8c2b7a5e76148bda => Any[2, 4, 1],
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x5a93e9ec4bc05a56 => Any[1, 4, 1],
                        0x6a7634569af3396c => Any[1],
                        0x51aaed7b1c6bb305 => Any[],
                        0xb693e3cf592eb63c => Any[4, 1, 4, 1],
                        0x49021a5ed5ec68f1 => Any[2, 4, 1, 4, 1],
                        0x8c2b7a5e76148bda => Any[4, 1],
                    ),
                ),
            ),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 4, 1, 4, 2], UInt64(2) => [])) == [1, 4, 1, 4, 2]
    end

    @testset "Reverse fold with plus" begin
        skeleton = parse_program("(fold (lambda (lambda (+ \$0 \$1))) ??(list(t0)) ??(int))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options_subset(
            run_in_reverse(p, 1),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x13c6e8120a792414 => 0,
                        0x6f06515bb4de0f6b => 1,
                        0x3f1fcb7159a87472 => 3,
                        0x57c4500f0120a022 => -3,
                        0xaf62816174ae3b14 => -1,
                        0x4d8bb92837c9b51a => 4,
                        0x3d74768e3ebe0076 => -2,
                        0x486ce1664368b877 => 2,
                        0x1ed971da45e03b55 => 1,
                        0x4f79ef1616287bea => AbductibleValue(any_object),
                        0x3d754dd768cd3f88 => AbductibleValue(any_object),
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x13c6e8120a792414 => Any[1],
                        0x6f06515bb4de0f6b => Any[],
                        0x3f1fcb7159a87472 => Any[-2],
                        0x57c4500f0120a022 => Any[4],
                        0xaf62816174ae3b14 => Any[2],
                        0x4d8bb92837c9b51a => Any[-3],
                        0x3d74768e3ebe0076 => Any[3],
                        0x486ce1664368b877 => Any[-1],
                        0x1ed971da45e03b55 => Any[0],
                        0x4f79ef1616287bea => AbductibleValue([any_object]),
                        0x3d754dd768cd3f88 => AbductibleValue(any_object),
                    ),
                ),
            ),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => [1], UInt64(2) => 0)) == 1

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => [1, 2]), 4) == Dict(UInt64(2) => 1)
        @test compare_options_subset(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => 2), 4),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x006e2b30c0d0317d => Any[2, 0],
                        0xc9152f463efdbeb9 => Any[4, -2],
                        0x34665a2239ce7554 => Any[0, 2],
                        0x6043de1657d59f57 => Any[-2, 4],
                        0x83fbd2bf3ec61c67 => Any[3, -1],
                        0x4548807bcf41c2f8 => Any[5, -3],
                        0x4535b312e823860e => Any[-1, 3],
                        0x56bc721b286adec3 => Any[-3, 5],
                        0x3dcbf526125730a1 => Any[1, 1],
                        0x81d67038ed043d8a => Any[6, -4],
                        0x7912c2fba0076269 => Any[2],
                        0x9b2b7a3ecf026057 => Any[7, -5],
                        0x0abc8d53582d3dbc => AbductibleValue(any_object),
                    ),
                ),
            ),
        )

        @test compare_options_subset(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => 4), 4),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xb6c82b2f29376e3c => AbductibleValue(any_object),
                        0x41ca0851a73e0f1f => Any[-2, 2],
                        0x1da8ee2ea441b303 => Any[-3, 3],
                        0x962a1ea7bf04f019 => Any[7, -7],
                        0x217ec347af1e7eb0 => Any[],
                        0xfdabfa28e21eecea => Any[1, -1],
                        0xc5589d28e249654c => Any[3, -3],
                        0x286dedbc8cc5c5e2 => Any[0, 0],
                        0xf1c9160fdad8f5e8 => Any[-1, 1],
                        0xd8c4119928c65e22 => Any[5, -5],
                        0xbc37ea17effea691 => Any[2, -2],
                        0x4cb6a6700b3f5ba4 => Any[6, -6],
                        0x5fec1c510fbe81ac => Any[0],
                        0x71110033ed99ddbc => Any[4, -4],
                    ),
                ),
            ),
        )
    end

    @testset "Reverse fold with free var" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(
                        Abstraction(
                            Apply(
                                Apply(
                                    every_primitive["cons"],
                                    Apply(Apply(every_primitive["*"], Index(1)), FreeVar(tint, nothing)),
                                ),
                                Index(0),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, true, nothing),
            ),
            Hole(tint, nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [3, 5, 2, 1]),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x513e080ea70f5b90 => -3,
                        0x5027e196b5246a17 => 3,
                        0xeac31cc26eb31998 => -1,
                        0x02443a8494b58942 => 1,
                        0x2ee1e14605cecb1d => -1,
                        0x5e2483c9ad470920 => -1,
                        0x94a98a58a423153b => -1,
                        0x121ba9a3e12380e7 => 1,
                        0x3dec996303c78cd9 => 1,
                        0x5aec02cea828a07a => 1,
                    ),
                ),
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x513e080ea70f5b90 => Any[-1],
                        0x5027e196b5246a17 => Any[1],
                        0xeac31cc26eb31998 => Any[-3, -5],
                        0x02443a8494b58942 => Any[3, 5],
                        0x2ee1e14605cecb1d => Any[-3],
                        0x5e2483c9ad470920 => Any[-3, -5, -2, -1],
                        0x94a98a58a423153b => Any[-3, -5, -2],
                        0x121ba9a3e12380e7 => Any[3, 5, 2, 1],
                        0x3dec996303c78cd9 => Any[3],
                        0x5aec02cea828a07a => Any[3, 5, 2],
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x513e080ea70f5b90 => Any[5, 2, 1],
                        0x5027e196b5246a17 => Any[5, 2, 1],
                        0xeac31cc26eb31998 => Any[2, 1],
                        0x02443a8494b58942 => Any[2, 1],
                        0x2ee1e14605cecb1d => Any[5, 2, 1],
                        0x5e2483c9ad470920 => Any[],
                        0x94a98a58a423153b => Any[1],
                        0x121ba9a3e12380e7 => Any[],
                        0x3dec996303c78cd9 => Any[5, 2, 1],
                        0x5aec02cea828a07a => Any[1],
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(3) => []), [3, 5, 2, 1]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(0xfe1aa1e710789fbb => Any[3, 5, 2, 1], 0xa8b7141625cc424c => Any[-3, -5, -2, -1]),
                ),
                0x0000000000000001 =>
                    EitherOptions(Dict{UInt64,Any}(0xfe1aa1e710789fbb => 1, 0xa8b7141625cc424c => -1)),
            ),
        )

        @test compare_options(
            run_in_reverse(p, [2, 4, 0, 6]),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xca760a1bb67c5298 => -2,
                        0xed2bac15a8d6cc26 => -1,
                        0xb1284b06664deac4 => -1,
                        0xa3b7143518b9cd9b => 1,
                        0x5b6f8d43aef8a633 => 2,
                        0x6ad4d8ebad9f1ef6 => 1,
                        0x05c76f82e24eb100 => 2,
                        0x2d8fe6fd1d74d9ae => 2,
                        0x0a8e28c73f4e426b => -1,
                        0xe82d332493f0bd5e => -1,
                        0x21a484a40db7f88f => -2,
                        0xb2a7250d9572ee4b => 1,
                        0x29c6dada72473106 => -2,
                        0x560a67db6e685723 => -2,
                        0x0c2931a6fbd1d7e7 => 1,
                        0x0c44d0d6b88fb944 => 2,
                    ),
                ),
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xca760a1bb67c5298 => Any[-1, -2, 0],
                        0xed2bac15a8d6cc26 => Any[-2, -4, 0],
                        0xb1284b06664deac4 => Any[-2],
                        0xa3b7143518b9cd9b => Any[2, 4],
                        0x5b6f8d43aef8a633 => Any[1, 2],
                        0x6ad4d8ebad9f1ef6 => Any[2, 4, 0, 6],
                        0x05c76f82e24eb100 => Any[1, 2, 0, 3],
                        0xe82d332493f0bd5e => Any[-2, -4, 0, -6],
                        0x2d8fe6fd1d74d9ae => Any[1],
                        0x0a8e28c73f4e426b => Any[-2, -4],
                        0x21a484a40db7f88f => Any[-1, -2, 0, -3],
                        0xb2a7250d9572ee4b => Any[2, 4, 0],
                        0x29c6dada72473106 => Any[-1],
                        0x560a67db6e685723 => Any[-1, -2],
                        0x0c2931a6fbd1d7e7 => Any[2],
                        0x0c44d0d6b88fb944 => Any[1, 2, 0],
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xca760a1bb67c5298 => Any[6],
                        0xed2bac15a8d6cc26 => Any[6],
                        0xb1284b06664deac4 => Any[4, 0, 6],
                        0xa3b7143518b9cd9b => Any[0, 6],
                        0x5b6f8d43aef8a633 => Any[0, 6],
                        0x6ad4d8ebad9f1ef6 => Any[],
                        0x05c76f82e24eb100 => Any[],
                        0xe82d332493f0bd5e => Any[],
                        0x2d8fe6fd1d74d9ae => Any[4, 0, 6],
                        0x0a8e28c73f4e426b => Any[0, 6],
                        0x21a484a40db7f88f => Any[],
                        0xb2a7250d9572ee4b => Any[6],
                        0x29c6dada72473106 => Any[4, 0, 6],
                        0x560a67db6e685723 => Any[0, 6],
                        0x0c2931a6fbd1d7e7 => Any[4, 0, 6],
                        0x0c44d0d6b88fb944 => Any[6],
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(3) => []), [2, 4, 0, 6]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x3cf38ef68394c11e => Any[2, 4, 0, 6],
                        0x6f1c3f9f9812328d => Any[1, 2, 0, 3],
                        0xc3eab21c6b1fbda0 => Any[-2, -4, 0, -6],
                        0x6e360089059eb8c4 => Any[-1, -2, 0, -3],
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x3cf38ef68394c11e => 1,
                        0x6f1c3f9f9812328d => 2,
                        0xc3eab21c6b1fbda0 => -1,
                        0x6e360089059eb8c4 => -2,
                    ),
                ),
            ),
        )
    end

    @testset "Reverse fold with free var with plus and mult" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(
                        Abstraction(
                            Apply(
                                Apply(
                                    every_primitive["cons"],
                                    Apply(
                                        Apply(every_primitive["*"], Index(1)),
                                        Apply(Apply(every_primitive["+"], Index(1)), FreeVar(tint, nothing)),
                                    ),
                                ),
                                Index(0),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, true, nothing),
            ),
            Hole(tint, nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [2, 6, 12]),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x0e690ae5de47ee55 => 1,
                        0x1bc8ebaec22ac2a5 => 1,
                        0x6e64a1283f62644b => 1,
                        0xa35f46e88205b06c => 1,
                        0x0577a46b493bfc76 => 1,
                        0x0f39a4e46f1c9bc5 => -1,
                        0x86e66c24bd02ed4f => -1,
                        0xe92160d3a7018821 => -1,
                        0x013e17a783256094 => -1,
                        0x0130fdc7641bc8b0 => -1,
                        0x24410cdad14d3c67 => -1,
                        0x2d3d89b0d28b1962 => 1,
                        0x8d99c7b718a725b2 => 1,
                        0x4e0d8693ae1fe9e8 => -1,
                        0xe2c213aed0588770 => -1,
                        0xe22037e66aa3c7a0 => -1,
                        0x5261536726da829c => -1,
                        0x6bb1c38a5eff030c => 1,
                        0x6687b799d963bf53 => 1,
                        0x222528c3977b34fc => -1,
                        0x9ed60d5a2abfca5a => -1,
                        0x2bcbf8b70e34aaa3 => -1,
                        0xe326edd66135e301 => 1,
                        0x0b40b3fbfae73982 => -1,
                        0xee6c6a618e339dd8 => 1,
                        0x578e794d049ab55a => 1,
                        0x892be32d50183539 => 1,
                        0x5eb3ec525bd0610a => 1,
                    ),
                ),
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x0e690ae5de47ee55 => Any[1],
                        0x1bc8ebaec22ac2a5 => Any[-2, 2, -4],
                        0x6e64a1283f62644b => Any[1, -3, 3],
                        0xa35f46e88205b06c => Any[1, -3, -4],
                        0x0577a46b493bfc76 => Any[-2, -3],
                        0x0f39a4e46f1c9bc5 => Any[-1, -2, -3],
                        0x86e66c24bd02ed4f => Any[-1, 3],
                        0xe92160d3a7018821 => Any[2, 3, 4],
                        0x013e17a783256094 => Any[-1],
                        0x0130fdc7641bc8b0 => Any[2, -2, 4],
                        0x24410cdad14d3c67 => Any[-1, -2, 4],
                        0x2d3d89b0d28b1962 => Any[1, -3],
                        0x8d99c7b718a725b2 => Any[1, 2],
                        0x4e0d8693ae1fe9e8 => Any[2, 3, -3],
                        0xe2c213aed0588770 => Any[2],
                        0xe22037e66aa3c7a0 => Any[-1, -2],
                        0x5261536726da829c => Any[-1, 3, -3],
                        0x6bb1c38a5eff030c => Any[-2, 2],
                        0x6687b799d963bf53 => Any[-2, -3, 3],
                        0x222528c3977b34fc => Any[2, -2, -3],
                        0x9ed60d5a2abfca5a => Any[2, -2],
                        0x2bcbf8b70e34aaa3 => Any[-1, 3, 4],
                        0xe326edd66135e301 => Any[-2],
                        0x0b40b3fbfae73982 => Any[2, 3],
                        0xee6c6a618e339dd8 => Any[1, 2, -4],
                        0x578e794d049ab55a => Any[-2, 2, 3],
                        0x892be32d50183539 => Any[1, 2, 3],
                        0x5eb3ec525bd0610a => Any[-2, -3, -4],
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x0e690ae5de47ee55 => Any[6, 12],
                        0x1bc8ebaec22ac2a5 => Any[],
                        0x6e64a1283f62644b => Any[],
                        0xa35f46e88205b06c => Any[],
                        0x0577a46b493bfc76 => Any[12],
                        0x0f39a4e46f1c9bc5 => Any[],
                        0x86e66c24bd02ed4f => Any[12],
                        0xe92160d3a7018821 => Any[],
                        0x013e17a783256094 => Any[6, 12],
                        0x0130fdc7641bc8b0 => Any[],
                        0x24410cdad14d3c67 => Any[],
                        0x2d3d89b0d28b1962 => Any[12],
                        0x8d99c7b718a725b2 => Any[12],
                        0x4e0d8693ae1fe9e8 => Any[],
                        0xe2c213aed0588770 => Any[6, 12],
                        0xe22037e66aa3c7a0 => Any[12],
                        0x5261536726da829c => Any[],
                        0x6bb1c38a5eff030c => Any[12],
                        0x6687b799d963bf53 => Any[],
                        0x222528c3977b34fc => Any[],
                        0x9ed60d5a2abfca5a => Any[12],
                        0x2bcbf8b70e34aaa3 => Any[],
                        0xe326edd66135e301 => Any[6, 12],
                        0x0b40b3fbfae73982 => Any[12],
                        0xee6c6a618e339dd8 => Any[],
                        0x578e794d049ab55a => Any[],
                        0x892be32d50183539 => Any[],
                        0x5eb3ec525bd0610a => Any[],
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict(UInt64(3) => []), [2, 6, 12]),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x7871f5b3fd369c86 => -1,
                        0xa35fc19c1e73bb96 => 1,
                        0xbf8c18e285e6687c => 1,
                        0xa6be11fb3fe86802 => -1,
                        0x14afff92861e3828 => 1,
                        0x50a73c3a1361bb75 => -1,
                        0x6927b6f73a02ba3f => 1,
                        0x1fa59feed3584b9e => -1,
                        0x2a3b1fe25aa2fb9c => -1,
                        0x7ad90cdc29051cd5 => 1,
                        0x41fa7426dc0beccd => 1,
                        0xe17eca9de51ae684 => 1,
                        0x6047efdbf05fa049 => -1,
                        0x04705ab1e71592d0 => -1,
                        0xac7d12ce7eab2b23 => 1,
                        0x4f7f86f04ec75f5a => -1,
                    ),
                ),
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x7871f5b3fd369c86 => Any[2, 3, 4],
                        0xa35fc19c1e73bb96 => Any[-2, -3, 3],
                        0xbf8c18e285e6687c => Any[1, 2, 3],
                        0xa6be11fb3fe86802 => Any[-1, -2, -3],
                        0x14afff92861e3828 => Any[-2, -3, -4],
                        0x50a73c3a1361bb75 => Any[2, 3, -3],
                        0x6927b6f73a02ba3f => Any[1, -3, -4],
                        0x1fa59feed3584b9e => Any[2, -2, -3],
                        0x2a3b1fe25aa2fb9c => Any[-1, 3, 4],
                        0x7ad90cdc29051cd5 => Any[1, -3, 3],
                        0x41fa7426dc0beccd => Any[1, 2, -4],
                        0xe17eca9de51ae684 => Any[-2, 2, 3],
                        0x6047efdbf05fa049 => Any[-1, 3, -3],
                        0x04705ab1e71592d0 => Any[2, -2, 4],
                        0xac7d12ce7eab2b23 => Any[-2, 2, -4],
                        0x4f7f86f04ec75f5a => Any[-1, -2, 4],
                    ),
                ),
            ),
        )

        @test compare_options(
            run_in_reverse(p, [2, 6, 0, 12]),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xa4ea3cb4b69bad2f => 1,
                        0xed006d55f4376adf => 1,
                        0x2e5326e9d9d139ac => -1,
                        0x271d023f1dcdd1f7 => 1,
                        0x8a649c5fc17f91ee => -1,
                        0x22fa46de7730c45b => 1,
                        0x61e5d158c32cb720 => 1,
                        0x6a7bf21ec0094bf4 => -1,
                        0xf2329b46347eb398 => -1,
                        0x466fdd8a98e5e559 => -1,
                        0xfe54673727a96a57 => 1,
                        0xe4c3f155ef76fcbb => 1,
                        0x0746572be785d45b => -1,
                        0x2abe19792f140c7d => 1,
                        0x824d4c59f39c059e => -1,
                        0x920ee0549f114042 => -1,
                        0x2d3724d9f23a1fa4 => -1,
                        0x01be34d0c392807d => 1,
                        0x7a79c13aea8bc432 => 1,
                        0xc646edfb8dd0d3ac => -1,
                        0x94cf8027c7559c04 => -1,
                        0x076c62bc8e202f8a => -1,
                        0x2354447502c44b06 => -1,
                        0xec7a2826c787efe2 => 1,
                        0xc5115e196a7d96f8 => -1,
                        0xc62ee1461a50c164 => -1,
                        0xb575e6dae94f8f8a => 1,
                        0x3fe4b3acab8a02d8 => 1,
                        0xd764510353c5d60c => -1,
                        0x61eb98abcb725303 => -1,
                        0xd2a5e99d641917c2 => 1,
                        0x4f44d55ce40a4205 => 1,
                        0x37dc5e4943d0af8e => -1,
                        0xd21d8497c476aa31 => 1,
                        0x12dcc19aaa49c722 => -1,
                        0xacee7b3ab1a9937d => 1,
                        0xec366ba1f1314140 => 1,
                        0x9fb7ba6612c577e3 => -1,
                        0x23c03170ecbf5ee0 => -1,
                        0xd40762d0abcba977 => -1,
                        0xf52731a3c4572c87 => 1,
                        0x09b439c6792b6bab => -1,
                        0x2cec70182cf7d159 => -1,
                        0xf5f2df3aea05638b => 1,
                        0x372f62708c5a359b => -1,
                        0xc90ace6f2d5fadbc => 1,
                        0x78fbf12562426470 => 1,
                        0xec5be8c4af0fa427 => 1,
                        0x844740651529a665 => -1,
                        0x32374d58b1e3438a => -1,
                        0x40f3c576d167a0f0 => 1,
                        0x4a80842b87e4d44d => -1,
                        0xc96153bfd10c20de => 1,
                        0x69fdfc5b2eb05631 => 1,
                        0x8c61695feb2f8114 => 1,
                        0x424fd85a49b20ef5 => 1,
                        0xa9e1534fc302fe25 => 1,
                        0x9b8ea66c6609347c => 1,
                        0xaa8d671aecadcb8e => -1,
                        0x85ea71d180be338f => -1,
                    ),
                ),
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xa4ea3cb4b69bad2f => Any[-2, 2, 0, 3],
                        0xed006d55f4376adf => Any[-2, -3],
                        0x2e5326e9d9d139ac => Any[2, -2, 0],
                        0x271d023f1dcdd1f7 => Any[1, -3, -1],
                        0x8a649c5fc17f91ee => Any[2, -2, 1, -3],
                        0x22fa46de7730c45b => Any[1, 2, 0, -4],
                        0x61e5d158c32cb720 => Any[-2],
                        0x6a7bf21ec0094bf4 => Any[2, 3, 0, -3],
                        0xf2329b46347eb398 => Any[2],
                        0x466fdd8a98e5e559 => Any[2, -2, 1],
                        0xfe54673727a96a57 => Any[-2, 2, -1],
                        0xe4c3f155ef76fcbb => Any[-2, -3, 0, -4],
                        0x0746572be785d45b => Any[2, 3, 1, 4],
                        0x2abe19792f140c7d => Any[1, -3],
                        0x824d4c59f39c059e => Any[-1, 3, 0, -3],
                        0x920ee0549f114042 => Any[2, 3, 0],
                        0x2d3724d9f23a1fa4 => Any[-1, 3, 0, 4],
                        0x01be34d0c392807d => Any[1],
                        0x7a79c13aea8bc432 => Any[1, -3, -1, 3],
                        0xc646edfb8dd0d3ac => Any[2, 3, 1, -3],
                        0x94cf8027c7559c04 => Any[-1, -2, 1],
                        0x076c62bc8e202f8a => Any[2, 3, 0, 4],
                        0x2354447502c44b06 => Any[-1],
                        0xec7a2826c787efe2 => Any[1, -3, 0, -4],
                        0xc5115e196a7d96f8 => Any[-1, -2, 1, -3],
                        0xc62ee1461a50c164 => Any[2, -2, 0, -3],
                        0xb575e6dae94f8f8a => Any[1, 2, -1],
                        0x3fe4b3acab8a02d8 => Any[-2, -3, -1, -4],
                        0xd764510353c5d60c => Any[-1, 3, 1],
                        0x61eb98abcb725303 => Any[-1, -2, 0],
                        0xd2a5e99d641917c2 => Any[-2, 2, -1, -4],
                        0x4f44d55ce40a4205 => Any[-2, 2, 0, -4],
                        0x37dc5e4943d0af8e => Any[2, -2],
                        0xd21d8497c476aa31 => Any[1, -3, 0, 3],
                        0x12dcc19aaa49c722 => Any[2, -2, 1, 4],
                        0xacee7b3ab1a9937d => Any[-2, -3, -1],
                        0xec366ba1f1314140 => Any[1, -3, 0],
                        0x9fb7ba6612c577e3 => Any[-1, 3, 1, 4],
                        0x23c03170ecbf5ee0 => Any[2, 3, 1],
                        0xd40762d0abcba977 => Any[-1, 3, 0],
                        0xf52731a3c4572c87 => Any[1, 2, 0],
                        0x09b439c6792b6bab => Any[-1, 3, 1, -3],
                        0x2cec70182cf7d159 => Any[2, -2, 0, 4],
                        0xf5f2df3aea05638b => Any[1, 2],
                        0x372f62708c5a359b => Any[-1, 3],
                        0xc90ace6f2d5fadbc => Any[1, -3, -1, -4],
                        0x78fbf12562426470 => Any[1, 2, -1, 3],
                        0xec5be8c4af0fa427 => Any[-2, 2, 0],
                        0x844740651529a665 => Any[-1, -2, 0, -3],
                        0x32374d58b1e3438a => Any[-1, -2, 1, 4],
                        0x40f3c576d167a0f0 => Any[-2, -3, -1, 3],
                        0x4a80842b87e4d44d => Any[-1, -2],
                        0xc96153bfd10c20de => Any[1, 2, -1, -4],
                        0x69fdfc5b2eb05631 => Any[-2, 2],
                        0x8c61695feb2f8114 => Any[-2, -3, 0, 3],
                        0x424fd85a49b20ef5 => Any[-2, 2, -1, 3],
                        0xa9e1534fc302fe25 => Any[-2, -3, 0],
                        0x9b8ea66c6609347c => Any[1, 2, 0, 3],
                        0xaa8d671aecadcb8e => Any[2, 3],
                        0x85ea71d180be338f => Any[-1, -2, 0, 4],
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xa4ea3cb4b69bad2f => Any[],
                        0xed006d55f4376adf => Any[0, 12],
                        0x2e5326e9d9d139ac => Any[12],
                        0x271d023f1dcdd1f7 => Any[12],
                        0x8a649c5fc17f91ee => Any[],
                        0x22fa46de7730c45b => Any[],
                        0x61e5d158c32cb720 => Any[6, 0, 12],
                        0x6a7bf21ec0094bf4 => Any[],
                        0xf2329b46347eb398 => Any[6, 0, 12],
                        0x466fdd8a98e5e559 => Any[12],
                        0xfe54673727a96a57 => Any[12],
                        0xe4c3f155ef76fcbb => Any[],
                        0x0746572be785d45b => Any[],
                        0x2abe19792f140c7d => Any[0, 12],
                        0x824d4c59f39c059e => Any[],
                        0x920ee0549f114042 => Any[12],
                        0x2d3724d9f23a1fa4 => Any[],
                        0x01be34d0c392807d => Any[6, 0, 12],
                        0x7a79c13aea8bc432 => Any[],
                        0xc646edfb8dd0d3ac => Any[],
                        0x94cf8027c7559c04 => Any[12],
                        0x076c62bc8e202f8a => Any[],
                        0x2354447502c44b06 => Any[6, 0, 12],
                        0xec7a2826c787efe2 => Any[],
                        0xc5115e196a7d96f8 => Any[],
                        0xc62ee1461a50c164 => Any[],
                        0xb575e6dae94f8f8a => Any[12],
                        0x3fe4b3acab8a02d8 => Any[],
                        0xd764510353c5d60c => Any[12],
                        0x61eb98abcb725303 => Any[12],
                        0xd2a5e99d641917c2 => Any[],
                        0x4f44d55ce40a4205 => Any[],
                        0x37dc5e4943d0af8e => Any[0, 12],
                        0xd21d8497c476aa31 => Any[],
                        0x12dcc19aaa49c722 => Any[],
                        0xacee7b3ab1a9937d => Any[12],
                        0xec366ba1f1314140 => Any[12],
                        0x9fb7ba6612c577e3 => Any[],
                        0x23c03170ecbf5ee0 => Any[12],
                        0xd40762d0abcba977 => Any[12],
                        0xf52731a3c4572c87 => Any[12],
                        0x09b439c6792b6bab => Any[],
                        0x2cec70182cf7d159 => Any[],
                        0xf5f2df3aea05638b => Any[0, 12],
                        0x372f62708c5a359b => Any[0, 12],
                        0xc90ace6f2d5fadbc => Any[],
                        0x78fbf12562426470 => Any[],
                        0xec5be8c4af0fa427 => Any[12],
                        0x844740651529a665 => Any[],
                        0x32374d58b1e3438a => Any[],
                        0x40f3c576d167a0f0 => Any[],
                        0x4a80842b87e4d44d => Any[0, 12],
                        0xc96153bfd10c20de => Any[],
                        0x69fdfc5b2eb05631 => Any[0, 12],
                        0x8c61695feb2f8114 => Any[],
                        0x424fd85a49b20ef5 => Any[],
                        0xa9e1534fc302fe25 => Any[12],
                        0x9b8ea66c6609347c => Any[],
                        0xaa8d671aecadcb8e => Any[0, 12],
                        0x85ea71d180be338f => Any[],
                    ),
                ),
            ),
        )
    end

    @testset "Reverse fold with free var with plus" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(
                        Abstraction(
                            Apply(
                                Apply(
                                    every_primitive["cons"],
                                    Apply(Apply(every_primitive["+"], Index(1)), FreeVar(tint, nothing)),
                                ),
                                Index(0),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, true, nothing),
            ),
            Hole(tlist(tint), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [2, 6, 12]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x40393b028d9bd4de => Any[-10, -6, 0],
                        0x1b1e9514e9b8e8e1 => Any[2],
                        0xfe869e12dba774da => Any[-9, -5, 1],
                        0x2315b137a0e8425a => Any[0],
                        0x7b8770b67f2d3a6e => AbductibleValue([any_object, any_object]),
                        0xfcb4c0b798470b9a => Any[-6],
                        0xa86446a3bab32ef2 => Any[-13],
                        0x56fe5757e7f6c8e7 => Any[-10, -6],
                        0x3d5ca78537a8b011 => Any[-4],
                        0xc9e2c3f7482061f3 => Any[-8, -4, 2],
                        0x0da3efd9dcb06981 => Any[-11],
                        0xca6bc5ecdde694a1 => Any[0, 4],
                        0xb921cc598df60ce6 => Any[-12, -8],
                        0xb135b25237920959 => AbductibleValue([any_object, any_object, any_object]),
                        0xce59dceb6a169284 => Any[2, 6],
                        0xe964d439f563ad82 => Any[-13, -9, -3],
                        0x912e31630a5125ad => Any[4],
                        0xf60a59bdd0c4123e => Any[-2],
                        0xf715dd592cc5a639 => Any[-3, 1, 7],
                        0xfcacaeb522e538c4 => Any[-1],
                        0x2c5c1809c9099b5e => Any[-8, -4],
                        0x72735b399144e62e => Any[-1, 3],
                        0x54781e4f3fc9a1c9 => Any[3, 7, 13],
                        0x64c81fa2d96b36d3 => Any[0, 4, 10],
                        0xacbf3cc81acde340 => Any[3, 7],
                        0x9f6030b3423c8a99 => Any[-6, -2, 4],
                        0x8ee053a531aef29c => Any[-10],
                        0x688816e9f74abeec => Any[-5, -1],
                        0xfe8e3ff8852261ba => Any[-7, -3, 3],
                        0x14d7809da24ce3e9 => Any[-7, -3],
                        0xa2accf7f4f7d0918 => Any[5, 9],
                        0xa5502fac8477de46 => Any[-11, -7, -1],
                        0xe97a6d52079ba288 => Any[-3],
                        0xf93049d1b0ffc376 => Any[5, 9, 15],
                        0xe2ad5cffc1a407c6 => Any[1, 5],
                        0x4a26026b78b5a0e8 => Any[3],
                        0x998c520c26368ecf => Any[-1, 3, 9],
                        0x64926d363ca670b3 => Any[-9],
                        0x1b5c14c2a9ff0a7f => Any[-2, 2, 8],
                        0xb11bbe20ec824625 => Any[-12],
                        0x6893f92ff6f9f8b0 => Any[-5],
                        0x3fb5b68c27e57b42 => Any[4, 8, 14],
                        0xbe75e6e73d3faff7 => Any[-2, 2],
                        0x593e556b86e2b24a => Any[-3, 1],
                        0xe772349b3e686847 => Any[-5, -1, 5],
                        0x9664b898838cf831 => Any[-12, -8, -2],
                        0x4fbfd456bbeff778 => Any[-11, -7],
                        0xce2221540c3f2060 => Any[-8],
                        0x51a026e71973da25 => Any[1],
                        0x1c6f3e5f3cf6728a => Any[2, 6, 12],
                        0x36686933b5970f94 => Any[-4, 0, 6],
                        0x2b3debce80692f3f => Any[1, 5, 11],
                        0x68c76a80e6dc2db2 => Any[-13, -9],
                        0x313db07994116cb2 => AbductibleValue([any_object]),
                        0x350adddbf30ef295 => Any[5],
                        0xb5e3617a00d07edf => Any[-9, -5],
                        0x7aaece909795eeeb => Any[-4, 0],
                        0x5d4126efb0548b06 => Any[-7],
                        0x384058a640cb457c => Any[4, 8],
                        0xf6dc7faacce60dfa => Any[-6, -2],
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x40393b028d9bd4de => Any[],
                        0x1b1e9514e9b8e8e1 => Any[6, 12],
                        0xfe869e12dba774da => Any[],
                        0x2315b137a0e8425a => Any[6, 12],
                        0x7b8770b67f2d3a6e => Any[12],
                        0xfcb4c0b798470b9a => Any[6, 12],
                        0xa86446a3bab32ef2 => Any[6, 12],
                        0x56fe5757e7f6c8e7 => Any[12],
                        0x3d5ca78537a8b011 => Any[6, 12],
                        0xc9e2c3f7482061f3 => Any[],
                        0x0da3efd9dcb06981 => Any[6, 12],
                        0xca6bc5ecdde694a1 => Any[12],
                        0xb921cc598df60ce6 => Any[12],
                        0xb135b25237920959 => Any[],
                        0xce59dceb6a169284 => Any[12],
                        0xe964d439f563ad82 => Any[],
                        0x912e31630a5125ad => Any[6, 12],
                        0xf60a59bdd0c4123e => Any[6, 12],
                        0xf715dd592cc5a639 => Any[],
                        0xfcacaeb522e538c4 => Any[6, 12],
                        0x2c5c1809c9099b5e => Any[12],
                        0x72735b399144e62e => Any[12],
                        0x54781e4f3fc9a1c9 => Any[],
                        0x64c81fa2d96b36d3 => Any[],
                        0xacbf3cc81acde340 => Any[12],
                        0x9f6030b3423c8a99 => Any[],
                        0x8ee053a531aef29c => Any[6, 12],
                        0x688816e9f74abeec => Any[12],
                        0xfe8e3ff8852261ba => Any[],
                        0x14d7809da24ce3e9 => Any[12],
                        0xa2accf7f4f7d0918 => Any[12],
                        0xa5502fac8477de46 => Any[],
                        0xe97a6d52079ba288 => Any[6, 12],
                        0xf93049d1b0ffc376 => Any[],
                        0xe2ad5cffc1a407c6 => Any[12],
                        0x4a26026b78b5a0e8 => Any[6, 12],
                        0x998c520c26368ecf => Any[],
                        0x64926d363ca670b3 => Any[6, 12],
                        0x1b5c14c2a9ff0a7f => Any[],
                        0xb11bbe20ec824625 => Any[6, 12],
                        0x6893f92ff6f9f8b0 => Any[6, 12],
                        0x3fb5b68c27e57b42 => Any[],
                        0xbe75e6e73d3faff7 => Any[12],
                        0x593e556b86e2b24a => Any[12],
                        0xe772349b3e686847 => Any[],
                        0x9664b898838cf831 => Any[],
                        0x4fbfd456bbeff778 => Any[12],
                        0xce2221540c3f2060 => Any[6, 12],
                        0x51a026e71973da25 => Any[6, 12],
                        0x1c6f3e5f3cf6728a => Any[],
                        0x36686933b5970f94 => Any[],
                        0x2b3debce80692f3f => Any[],
                        0x68c76a80e6dc2db2 => Any[12],
                        0x313db07994116cb2 => Any[6, 12],
                        0x350adddbf30ef295 => Any[6, 12],
                        0xb5e3617a00d07edf => Any[12],
                        0x7aaece909795eeeb => Any[12],
                        0x5d4126efb0548b06 => Any[6, 12],
                        0x384058a640cb457c => Any[12],
                        0xf6dc7faacce60dfa => Any[12],
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x40393b028d9bd4de => 12,
                        0x1b1e9514e9b8e8e1 => 0,
                        0xfe869e12dba774da => 11,
                        0x2315b137a0e8425a => 2,
                        0x7b8770b67f2d3a6e => AbductibleValue(any_object),
                        0xfcb4c0b798470b9a => 8,
                        0xa86446a3bab32ef2 => 15,
                        0x56fe5757e7f6c8e7 => 12,
                        0x3d5ca78537a8b011 => 6,
                        0xc9e2c3f7482061f3 => 10,
                        0x0da3efd9dcb06981 => 13,
                        0xca6bc5ecdde694a1 => 2,
                        0xb921cc598df60ce6 => 14,
                        0xb135b25237920959 => AbductibleValue(any_object),
                        0xce59dceb6a169284 => 0,
                        0xe964d439f563ad82 => 15,
                        0x912e31630a5125ad => -2,
                        0xf60a59bdd0c4123e => 4,
                        0xf715dd592cc5a639 => 5,
                        0xfcacaeb522e538c4 => 3,
                        0x2c5c1809c9099b5e => 10,
                        0x72735b399144e62e => 3,
                        0x54781e4f3fc9a1c9 => -1,
                        0x64c81fa2d96b36d3 => 2,
                        0xacbf3cc81acde340 => -1,
                        0x9f6030b3423c8a99 => 8,
                        0x8ee053a531aef29c => 12,
                        0x688816e9f74abeec => 7,
                        0xfe8e3ff8852261ba => 9,
                        0x14d7809da24ce3e9 => 9,
                        0xa2accf7f4f7d0918 => -3,
                        0xa5502fac8477de46 => 13,
                        0xe97a6d52079ba288 => 5,
                        0xf93049d1b0ffc376 => -3,
                        0xe2ad5cffc1a407c6 => 1,
                        0x4a26026b78b5a0e8 => -1,
                        0x998c520c26368ecf => 3,
                        0x64926d363ca670b3 => 11,
                        0x1b5c14c2a9ff0a7f => 4,
                        0xb11bbe20ec824625 => 14,
                        0x6893f92ff6f9f8b0 => 7,
                        0x3fb5b68c27e57b42 => -2,
                        0xbe75e6e73d3faff7 => 4,
                        0x593e556b86e2b24a => 5,
                        0xe772349b3e686847 => 7,
                        0x9664b898838cf831 => 14,
                        0x4fbfd456bbeff778 => 13,
                        0xce2221540c3f2060 => 10,
                        0x51a026e71973da25 => 1,
                        0x1c6f3e5f3cf6728a => 0,
                        0x36686933b5970f94 => 6,
                        0x2b3debce80692f3f => 1,
                        0x68c76a80e6dc2db2 => 15,
                        0x313db07994116cb2 => AbductibleValue(any_object),
                        0x350adddbf30ef295 => -3,
                        0xb5e3617a00d07edf => 11,
                        0x7aaece909795eeeb => 6,
                        0x5d4126efb0548b06 => 9,
                        0x384058a640cb457c => -2,
                        0xf6dc7faacce60dfa => 8,
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict(UInt64(1) => 1), [2, 6, 12]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x9905cb6a759136a0 => Any[],
                        0x632db207cba038e9 => Any[1],
                        0xcf6638f9e6d8a4c3 => Any[1, 5, 11],
                        0x88156e4dc6ade027 => Any[1, 5],
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x9905cb6a759136a0 => Any[2, 6, 12],
                        0x632db207cba038e9 => Any[6, 12],
                        0xcf6638f9e6d8a4c3 => Any[],
                        0x88156e4dc6ade027 => Any[12],
                    ),
                ),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict(UInt64(2) => [0, 4]), [2, 6, 12]),
            Dict(0x0000000000000001 => 2, 0x0000000000000003 => Any[12]),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict(UInt64(3) => [12]), [2, 6, 12]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xf8a25e789a94226f => Any[-2, 2],
                        0x4c698a827a817b9a => Any[2, 6],
                        0xe59ca7b1957346cb => Any[-12, -8],
                        0x3a2da8dc33bcba6f => Any[-11, -7],
                        0xd62e9777c4af4834 => Any[-13, -9],
                        0xeea6edcb712a52a3 => Any[-6, -2],
                        0xaad7e2a66e2f30d9 => Any[-10, -6],
                        0x9247365111af6d6a => Any[4, 8],
                        0x7253c6d032e394b7 => Any[-1, 3],
                        0xdeeeada85a08699a => Any[-7, -3],
                        0x55cd26afe5088013 => Any[1, 5],
                        0xd3cfe49692fd1295 => Any[-9, -5],
                        0x35a898bb0237fdbb => Any[-8, -4],
                        0xe433c3ae409db1c3 => Any[-4, 0],
                        0xdac76da73b03f993 => Any[3, 7],
                        0x3afe037542df7091 => Any[0, 4],
                        0x28e81f1d7ab53902 => AbductibleValue([any_object, any_object]),
                        0x9a45bd259cdd42eb => Any[-3, 1],
                        0xce65679c2dcc94b5 => Any[5, 9],
                        0x981f0587f90de938 => Any[-5, -1],
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xf8a25e789a94226f => 4,
                        0x4c698a827a817b9a => 0,
                        0xe59ca7b1957346cb => 14,
                        0x3a2da8dc33bcba6f => 13,
                        0xd62e9777c4af4834 => 15,
                        0xeea6edcb712a52a3 => 8,
                        0xaad7e2a66e2f30d9 => 12,
                        0x9247365111af6d6a => -2,
                        0x7253c6d032e394b7 => 3,
                        0xdeeeada85a08699a => 9,
                        0x55cd26afe5088013 => 1,
                        0xd3cfe49692fd1295 => 11,
                        0x35a898bb0237fdbb => 10,
                        0xe433c3ae409db1c3 => 6,
                        0xdac76da73b03f993 => -1,
                        0x3afe037542df7091 => 2,
                        0x28e81f1d7ab53902 => AbductibleValue(any_object),
                        0x9a45bd259cdd42eb => 5,
                        0xce65679c2dcc94b5 => -3,
                        0x981f0587f90de938 => 7,
                    ),
                ),
            ),
        )
    end

    @testset "Reverse fold_set" begin
        skeleton = parse_program("(fold_set (lambda (lambda (adjoin \$1 \$0))) ??(set(int)) ??(set(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([2, 4, 1, 6, 9])),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x165848f11efe26a6 => Set(Any[9, 1]),
                        0x1dca63b72383214d => Set(Any[6, 2]),
                        0xb2cc5dada6d38f57 => Set(Any[2, 9]),
                        0x2f8f2c859ba29884 => Set(Any[6, 2, 9]),
                        0x70daccc919ec02b9 => Set(Any[6]),
                        0xa0c9970916da706f => Set(Any[4]),
                        0xda1fe319623f9e8b => Set(Any[6, 9]),
                        0x79a5ddd70bf57483 => Set(Any[4, 2, 9]),
                        0x8291d0c2f5ec5ef1 => Set(Any[6, 2, 1]),
                        0x60b465716eb269cf => Set(Any[4, 6, 9]),
                        0xf16d99ce639f68b1 => Set(Any[4, 2, 9, 1]),
                        0x4d65a4180c8d755d => Set(Any[4, 9, 1]),
                        0xc2d298e2cb49c5a2 => Set{Any}(),
                        0x1c4e8b21d43377c7 => Set(Any[9]),
                        0xdd298a36240a51f8 => Set(Any[2, 9, 1]),
                        0xbc14c737e8828a8b => Set(Any[4, 2, 1]),
                        0x7a9d92bd9032a544 => Set(Any[4, 6]),
                        0x9c20a4a86f1ba4fd => Set(Any[1]),
                        0x01c6d489e5283818 => Set(Any[4, 1]),
                        0xff3bd5808f308284 => Set(Any[4, 6, 9, 1]),
                        0x0bf9fae00f4b9d5f => Set(Any[4, 6, 2, 1]),
                        0x5479ec353ac344d7 => Set(Any[4, 6, 1]),
                        0x7079dbcfe172684f => Set(Any[4, 2]),
                        0x3dcf2bed10f8152b => Set(Any[6, 1]),
                        0xe8ab06e087cdbf97 => Set(Any[2, 1]),
                        0x76db2010010b88bf => Set(Any[6, 2, 9, 1]),
                        0x6879a2389d5ffded => Set(Any[4, 6, 2, 9]),
                        0xcc7e478ec7e4dd4e => Set(Any[4, 6, 2, 9, 1]),
                        0x4241266a96d58d62 => Set(Any[4, 6, 2]),
                        0x9d47aa483f7d6c70 => Set(Any[2]),
                        0xf377591f0f71ea3f => Set(Any[6, 9, 1]),
                        0x705e4c787e636ea1 => Set(Any[4, 9]),
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x165848f11efe26a6 => Set([4, 6, 2]),
                        0x1dca63b72383214d => Set([4, 9, 1]),
                        0xb2cc5dada6d38f57 => Set([4, 6, 1]),
                        0x2f8f2c859ba29884 => Set([4, 1]),
                        0x70daccc919ec02b9 => Set([4, 2, 9, 1]),
                        0xa0c9970916da706f => Set([6, 2, 9, 1]),
                        0xda1fe319623f9e8b => Set([4, 2, 1]),
                        0x79a5ddd70bf57483 => Set([6, 1]),
                        0x8291d0c2f5ec5ef1 => Set([4, 9]),
                        0x60b465716eb269cf => Set([2, 1]),
                        0xf16d99ce639f68b1 => Set([6]),
                        0x4d65a4180c8d755d => Set([6, 2]),
                        0xc2d298e2cb49c5a2 => Set([4, 6, 2, 9, 1]),
                        0x1c4e8b21d43377c7 => Set([4, 6, 2, 1]),
                        0xdd298a36240a51f8 => Set([4, 6]),
                        0xbc14c737e8828a8b => Set([6, 9]),
                        0x7a9d92bd9032a544 => Set([2, 9, 1]),
                        0x9c20a4a86f1ba4fd => Set([4, 6, 2, 9]),
                        0x01c6d489e5283818 => Set([6, 2, 9]),
                        0xff3bd5808f308284 => Set([2]),
                        0x0bf9fae00f4b9d5f => Set([9]),
                        0x5479ec353ac344d7 => Set([2, 9]),
                        0x7079dbcfe172684f => Set([6, 9, 1]),
                        0x3dcf2bed10f8152b => Set([4, 2, 9]),
                        0xe8ab06e087cdbf97 => Set([4, 6, 9]),
                        0x76db2010010b88bf => Set([4]),
                        0x6879a2389d5ffded => Set([1]),
                        0xcc7e478ec7e4dd4e => Set{Int64}(),
                        0x4241266a96d58d62 => Set([9, 1]),
                        0x9d47aa483f7d6c70 => Set([4, 6, 9, 1]),
                        0xf377591f0f71ea3f => Set([4, 2]),
                        0x705e4c787e636ea1 => Set([6, 2, 1]),
                    ),
                ),
            ),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => Set([1, 4]), UInt64(2) => Set([2, 6, 9]))) ==
              Set([2, 4, 1, 6, 9])
    end

    @testset "Reverse fold with concat" begin
        skeleton = parse_program("(fold (lambda (lambda (concat \$1 \$0))) ??(list(list(int))) ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options_subset(
            run_in_reverse(p, [2, 4, 1, 4, 1]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x8da30d18793380b5 => Any[4, 1],
                        0x31a0f63c32e08468 => Any[1],
                        0x9c67d11b16a073aa => Any[2, 4, 1, 4, 1],
                        0x2189077af6b4199d => Any[4, 1, 4, 1],
                        0x735647e308b6a7de => Any[1],
                        0xe2035f45aad2f2fc => Any[4, 1],
                        0xc28b183855b3f478 => Any[1],
                        0x24464916741629ce => Any[2, 4, 1, 4, 1],
                        0x55fbe9b458a1ac0a => Any[],
                        0xd7c7cb86449f9090 => Any[1],
                        0x009f6a4cbd99063c => Any[1],
                        0x3f5dbbfba5f9e123 => Any[4, 1],
                        0x0d10c3bc675dd43b => Any[],
                        0xe0df273cf6144158 => Any[4, 1],
                        0x880892bb9187ef7f => Any[1],
                        0xa733db04fb278acd => Any[4, 1],
                        0x29e582eed81040c1 => Any[],
                        0x9e49a006a4448bed => Any[],
                        0x6fc1f7b37668f35d => Any[],
                        0x1cc3a1d65866a81c => Any[1, 4, 1],
                        0xdfa148e61e3478b1 => Any[1, 4, 1],
                        0xf93c98a844a7fceb => Any[1],
                        0x33a5c0baa0063793 => Any[1],
                        0xe7036a7826b8dba7 => Any[4, 1, 4, 1],
                        0xf1d8525f68b94da2 => Any[4, 1],
                        0xc28379809fd920dc => Any[1],
                        0x7a71fef7b5e20066 => Any[],
                        0x7cf7ef47cf12219e => Any[4, 1, 4, 1],
                        0xe2257ffc90e830cb => Any[1, 4, 1],
                        0xeb866a4a9edfad46 => Any[],
                        0xc78c1c8fed7755dd => Any[2, 4, 1, 4, 1],
                        0x583f169e52b69d61 => Any[1],
                        0x5b4bbd75bd9a7e69 => Any[2, 4, 1, 4, 1],
                        0x6495e75deac82dec => Any[4, 1, 4, 1],
                        0x5d8d5f64cf6a4bb4 => Any[],
                        0x151f919e9172bf98 => Any[4, 1, 4, 1],
                        0x80784e0d4a9042a9 => Any[],
                        0xf4ee20f0d3a4a12f => Any[4, 1],
                        0xd2a7ab7dde5d0762 => Any[4, 1],
                        0x25c1ede4dbb7cba5 => Any[1],
                        0xfc0c59d42c72a44e => Any[],
                        0x01160c096bc6fc79 => Any[1],
                        0xf237be4b4c13851c => Any[1, 4, 1],
                        0xd415d47bd71cc061 => Any[1, 4, 1],
                        0x899aa26363422bb1 => Any[],
                        0x5dcaabcb2ac44457 => Any[],
                        0x790a826619b8f51a => Any[4, 1],
                        0xe7fb386fd1355543 => Any[1, 4, 1],
                        0x39a60c241170e921 => Any[],
                        0x706ae7c422ebcd2b => Any[],
                        0x828e60dfd5c0ec85 => Any[1],
                        0x1ddd3c2554e18674 => Any[1],
                        0x40d0fc51611b18e8 => Any[4, 1],
                        0xd5b806ebe46b12e2 => Any[4, 1],
                        0xa2cabbbb1aacec04 => Any[4, 1, 4, 1],
                        0x9124b8e897e94bf6 => Any[1, 4, 1],
                        0xbf1f140210105010 => Any[],
                        0x8ffdb1b76f2523a4 => Any[1, 4, 1],
                        0x3484937c9c1ce8a0 => Any[],
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x8da30d18793380b5 => Any[Any[2], Any[4, 1], Any[]],
                        0x31a0f63c32e08468 => Any[Any[2, 4, 1], Any[4]],
                        0x9c67d11b16a073aa => Any[Any[], Any[]],
                        0x2189077af6b4199d => Any[Any[], Any[2]],
                        0x735647e308b6a7de => Any[Any[2, 4, 1, 4]],
                        0xe2035f45aad2f2fc => Any[Any[2, 4], Any[], Any[1]],
                        0xc28b183855b3f478 => Any[Any[], Any[2], Any[4, 1, 4]],
                        0x24464916741629ce => Any[Any[], Any[], Any[]],
                        0x55fbe9b458a1ac0a => Any[Any[2, 4], Any[1, 4, 1]],
                        0xd7c7cb86449f9090 => Any[Any[2, 4, 1, 4], Any[]],
                        0x009f6a4cbd99063c => Any[Any[2, 4], Any[1, 4]],
                        0x3f5dbbfba5f9e123 => Any[Any[], Any[], Any[2, 4, 1]],
                        0x0d10c3bc675dd43b => Any[Any[2, 4], Any[1], Any[4, 1]],
                        0xe0df273cf6144158 => Any[Any[2], Any[], Any[4, 1]],
                        0x880892bb9187ef7f => Any[Any[2, 4], Any[1], Any[4]],
                        0xa733db04fb278acd => Any[Any[2, 4, 1], Any[]],
                        0x29e582eed81040c1 => Any[Any[2, 4, 1], Any[4], Any[1]],
                        0x9e49a006a4448bed => Any[Any[2, 4, 1, 4], Any[1]],
                        0x6fc1f7b37668f35d => Any[Any[2, 4, 1, 4, 1]],
                        0x1cc3a1d65866a81c => Any[Any[2, 4], Any[]],
                        0xdfa148e61e3478b1 => Any[Any[2], Any[], Any[4]],
                        0xf93c98a844a7fceb => Any[Any[2, 4, 1], Any[4], Any[]],
                        0x33a5c0baa0063793 => Any[Any[], Any[2, 4, 1, 4], Any[]],
                        0xe7036a7826b8dba7 => Any[Any[2]],
                        0xf1d8525f68b94da2 => Any[Any[2, 4, 1]],
                        0xc28379809fd920dc => Any[Any[2], Any[], Any[4, 1, 4]],
                        0x7a71fef7b5e20066 => Any[Any[], Any[2, 4, 1, 4], Any[1]],
                        0x7cf7ef47cf12219e => Any[Any[], Any[2], Any[]],
                        0xe2257ffc90e830cb => Any[Any[], Any[], Any[2, 4]],
                        0xeb866a4a9edfad46 => Any[Any[2], Any[4, 1], Any[4, 1]],
                        0xc78c1c8fed7755dd => Any[Any[]],
                        0x583f169e52b69d61 => Any[Any[2], Any[4, 1], Any[4]],
                        0x5b4bbd75bd9a7e69 => Any[],
                        0x6495e75deac82dec => Any[Any[2], Any[], Any[]],
                        0x5d8d5f64cf6a4bb4 => Any[Any[2], Any[], Any[4, 1, 4, 1]],
                        0x151f919e9172bf98 => Any[Any[], Any[], Any[2]],
                        0x80784e0d4a9042a9 => Any[Any[2], Any[4, 1, 4, 1]],
                        0xf4ee20f0d3a4a12f => Any[Any[2, 4], Any[1], Any[]],
                        0xd2a7ab7dde5d0762 => Any[Any[2], Any[4, 1]],
                        0x25c1ede4dbb7cba5 => Any[Any[], Any[2, 4, 1, 4]],
                        0xfc0c59d42c72a44e => Any[Any[2, 4, 1, 4, 1], Any[]],
                        0x01160c096bc6fc79 => Any[Any[], Any[], Any[2, 4, 1, 4]],
                        0xf237be4b4c13851c => Any[Any[], Any[2], Any[4]],
                        0xd415d47bd71cc061 => Any[Any[2, 4], Any[], Any[]],
                        0x899aa26363422bb1 => Any[Any[2, 4, 1], Any[4, 1]],
                        0x5dcaabcb2ac44457 => Any[Any[], Any[2, 4, 1, 4, 1]],
                        0x790a826619b8f51a => Any[Any[2, 4], Any[1]],
                        0xe7fb386fd1355543 => Any[Any[], Any[2, 4]],
                        0x39a60c241170e921 => Any[Any[2, 4], Any[1, 4, 1], Any[]],
                        0x706ae7c422ebcd2b => Any[Any[], Any[], Any[2, 4, 1, 4, 1]],
                        0x828e60dfd5c0ec85 => Any[Any[2, 4], Any[], Any[1, 4]],
                        0x1ddd3c2554e18674 => Any[Any[2], Any[4, 1, 4]],
                        0x40d0fc51611b18e8 => Any[Any[], Any[2, 4, 1]],
                        0xd5b806ebe46b12e2 => Any[Any[], Any[2], Any[4, 1]],
                        0xa2cabbbb1aacec04 => Any[Any[2], Any[]],
                        0x9124b8e897e94bf6 => Any[Any[2, 4]],
                        0xbf1f140210105010 => Any[Any[2, 4], Any[], Any[1, 4, 1]],
                        0x8ffdb1b76f2523a4 => Any[Any[2], Any[4]],
                        0x3484937c9c1ce8a0 => Any[Any[], Any[2], Any[4, 1, 4, 1]],
                    ),
                ),
            ),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => [[1, 4, 1, 4, 2], [3, 5, 2, 5]], UInt64(2) => [])) ==
              [1, 4, 1, 4, 2, 3, 5, 2, 5]
    end

    @testset "Reverse fold_h" begin
        skeleton = parse_program("(fold_h (lambda (lambda (cons \$1 \$0))) ??(grid(int)) ??(list(list(int))))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[1, 3, 9], [4, 6, 1], [1, 1, 4], [4, 5, 0], [2, 2, 4]]),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x412daf04220dbd95 => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0; 2 2 4],
                        0x1676212d88803b6a => Any[1 3; 4 6; 1 1; 4 5; 2 2],
                        0x05b532410082e162 => Any[1; 4; 1; 4; 2;;],
                        0x48834f8b9af8b495 => Matrix{Any}(undef, 5, 0),
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x412daf04220dbd95 => Any[Int64[], Int64[], Int64[], Int64[], Int64[]],
                        0x1676212d88803b6a => Any[[9], [1], [4], [0], [4]],
                        0x05b532410082e162 => Any[[3, 9], [6, 1], [1, 4], [5, 0], [2, 4]],
                        0x48834f8b9af8b495 => [[1, 3, 9], [4, 6, 1], [1, 1, 4], [4, 5, 0], [2, 2, 4]],
                    ),
                ),
            ),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [[1, 4, 1, 4, 2] [3, 6, 1, 5, 2] [9, 1, 4, 0, 4]], UInt64(2) => [[], [], [], [], []]),
        ) == [[1, 3, 9], [4, 6, 1], [1, 1, 4], [4, 5, 0], [2, 2, 4]]
    end

    @testset "Reverse fold_h with plus" begin
        skeleton = parse_program("(fold_h (lambda (lambda (+ \$0 \$1))) ??(grid(int)) ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options_subset(
            run_in_reverse(p, [13, 11, 6, 9, 8]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xffdd4eee8a234e9c =>
                            AbductibleValue([any_object, any_object, any_object, any_object, any_object]),
                        0xf783671441fdab86 => [13, 11, 6, 9, 8],
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xffdd4eee8a234e9c => AbductibleValue(any_object),
                        0xf783671441fdab86 => Matrix{Any}(undef, 5, 0),
                    ),
                ),
            ),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [[1, 4, 1, 4, 2] [3, 6, 1, 5, 2] [9, 1, 4, 0, 4]], UInt64(2) => [0, 0, 0, 0, 0]),
        ) == [13, 11, 6, 9, 8]

        @test calculate_dependent_vars(
            p,
            Dict{UInt64,Any}(UInt64(1) => [[1, 4, 1, 4, 2] [3, 6, 1, 5, 2] [9, 1, 4, 0, 4]]),
            [13, 11, 6, 9, 8],
        ) == Dict(UInt64(2) => [0, 0, 0, 0, 0])

        @test compare_options_subset(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => [1, 4, 1, 4, 2]), [13, 11, 6, 9, 8]),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x437f3ce1e7c276f9 => AbductibleValue(any_object),
                        0xc4fe1f60b8197d8f => Any[12 0; 7 0; 5 0; 5 0; 6 0],
                        0x05ab344de32a539e => Any[12; 7; 5; 5; 6;;],
                    ),
                ),
            ),
        )
    end

    @testset "Reverse fold_v" begin
        skeleton = parse_program("(fold_v (lambda (lambda (cons \$1 \$0))) ??(grid(int)) ??(list(list(int))))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[1, 4, 1, 4, 2], [3, 6, 1, 5, 2], [9, 1, 4, 0, 4]]),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x1052d159da118660 => Matrix{Any}(undef, 0, 3),
                        0x458556b23e850c49 => Any[1 3 9],
                        0x795b80cb1f1a8203 => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0],
                        0x8b8a8aa5dbbc1b17 => Any[1 3 9; 4 6 1],
                        0x79cba76627e90a05 => Any[1 3 9; 4 6 1; 1 1 4],
                        0x0b8058b5a72803e8 => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0; 2 2 4],
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x1052d159da118660 => [[1, 4, 1, 4, 2], [3, 6, 1, 5, 2], [9, 1, 4, 0, 4]],
                        0x458556b23e850c49 => Any[[4, 1, 4, 2], [6, 1, 5, 2], [1, 4, 0, 4]],
                        0x795b80cb1f1a8203 => Any[[2], [2], [4]],
                        0x8b8a8aa5dbbc1b17 => Any[[1, 4, 2], [1, 5, 2], [4, 0, 4]],
                        0x79cba76627e90a05 => Any[[4, 2], [5, 2], [0, 4]],
                        0x0b8058b5a72803e8 => Any[Int64[], Int64[], Int64[]],
                    ),
                ),
            ),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [[1, 4, 1, 4, 2] [3, 6, 1, 5, 2] [9, 1, 4, 0, 4]], UInt64(2) => [[], [], []]),
        ) == [[1, 4, 1, 4, 2], [3, 6, 1, 5, 2], [9, 1, 4, 0, 4]]
    end

    @testset "Reverse fold_v with plus" begin
        skeleton = parse_program("(fold_v (lambda (lambda (+ \$0 \$1))) ??(grid(int)) ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options_subset(
            run_in_reverse(p, [12, 17, 18]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xbe1588e7ccfde359 => AbductibleValue([any_object, any_object, any_object]),
                        0x1ef7d4c6064df491 => [12, 17, 18],
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xbe1588e7ccfde359 => AbductibleValue(any_object),
                        0x1ef7d4c6064df491 => Matrix{Any}(undef, 0, 3),
                    ),
                ),
            ),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [[1, 4, 1, 4, 2] [3, 6, 1, 5, 2] [9, 1, 4, 0, 4]], UInt64(2) => [0, 0, 0]),
        ) == [12, 17, 18]

        @test calculate_dependent_vars(
            p,
            Dict{UInt64,Any}(UInt64(1) => [[1, 4, 1, 4, 2] [3, 6, 1, 5, 2] [9, 1, 4, 0, 4]]),
            [12, 17, 18],
        ) == Dict(UInt64(2) => [0, 0, 0])

        @test compare_options_subset(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => [1, 4, 1]), [12, 17, 18]),
            Dict(
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x9c51243a18a3677b => Any[11 13 17],
                        0xbc1074b971844af9 => AbductibleValue(any_object),
                        0x8175ffe377ab9da6 => Any[11 13 17; 0 0 0],
                    ),
                ),
            ),
        )
    end

    @testset "Reverse rev_groupby" begin
        skeleton = parse_program("(rev_groupby (lambda (car \$0)) ??(list(int)) ??(set(tuple2(int, set(list(int))))))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([(1, Set([[1, 2, 3], [1, 4, 2]])), (2, Set([[2]]))])),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x1c6ee62fbac1d45a => [2],
                        0x61176613c407e226 => [1, 4, 2],
                        0x52c032b6da5f6ae8 => [1, 2, 3],
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x1c6ee62fbac1d45a => Set([(1, Set([[1, 2, 3], [1, 4, 2]]))]),
                        0x61176613c407e226 => Set([(2, Set([[2]])), (1, Set([[1, 2, 3]]))]),
                        0x52c032b6da5f6ae8 => Set([(1, Set([[1, 4, 2]])), (2, Set([[2]]))]),
                    ),
                ),
            ),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [1, 2, 3], UInt64(2) => Set([(1, Set([[1, 4, 2]])), (2, Set([[2]]))])),
        ) == Set([(1, Set([[1, 2, 3], [1, 4, 2]])), (2, Set([[2]]))])
        @test run_with_arguments(p, [], Dict(UInt64(1) => [2], UInt64(2) => Set([(1, Set([[1, 2, 3], [1, 4, 2]]))]))) ==
              Set([(1, Set([[1, 2, 3], [1, 4, 2]])), (2, Set([[2]]))])
    end

    @testset "Reverse rev_fold with rev_groupby" begin
        skeleton = parse_program(
            "(rev_fold_set (lambda (lambda (rev_groupby (lambda (car \$0)) \$1 \$0))) empty_set ??(set(list(int))))",
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([[1, 2, 3], [1, 4, 2], [2]])),
            Dict(UInt64(1) => Set([(1, Set([[1, 2, 3], [1, 4, 2]])), (2, Set([[2]]))])),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => Set([(1, Set([[1, 2, 3], [1, 4, 2]])), (2, Set([[2]]))]))) ==
              Set([[1, 2, 3], [1, 4, 2], [2]])
    end

    @testset "Reverse rev_greedy_cluster" begin
        skeleton = parse_program(
            "(rev_greedy_cluster (lambda (lambda (all_set (lambda (eq? (car \$0) (car \$2))) \$0))) ??(list(list(int))) ??(set(set(list(int)))))",
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([Set([[1, 2, 3], [1, 4, 2]]), Set([[2]])])),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x0cd30b3b35947074 => [2],
                        0xb77bceb05f49bb13 => [1, 4, 2],
                        0x507b93ad884f9c7a => [1, 2, 3],
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x0cd30b3b35947074 => Set([Set([[1, 2, 3], [1, 4, 2]])]),
                        0xb77bceb05f49bb13 => Set([Set([[1, 2, 3]]), Set([[2]])]),
                        0x507b93ad884f9c7a => Set([Set([[1, 4, 2]]), Set([[2]])]),
                    ),
                ),
            ),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [1, 2, 3], UInt64(2) => Set([Set([[1, 4, 2]]), Set([[2]])])),
        ) == Set([Set([[1, 2, 3], [1, 4, 2]]), Set([[2]])])

        @test run_with_arguments(p, [], Dict(UInt64(1) => [2], UInt64(2) => Set([Set([[1, 2, 3], [1, 4, 2]])]))) ==
              Set([Set([[1, 2, 3], [1, 4, 2]]), Set([[2]])])
    end

    @testset "Reverse rev_greedy_cluster by length" begin
        skeleton = parse_program(
            "(rev_greedy_cluster (lambda (lambda (any_set (lambda (not (gt? (abs (- (length \$0) (length \$2))) 1))) \$0))) ??(list(list(int))) ??(set(set(list(int)))))",
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([Set([[1, 2, 3], [1, 4, 2, 2], [3, 5, 2, 5, 2]]), Set([[2]])])),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x6bc2689b3f9c3031 => [1, 4, 2, 2],
                        0x8f23b130f21cfac2 => [3, 5, 2, 5, 2],
                        0x3153e6863760efd0 => [1, 2, 3],
                        0x50c67e216811b75a => [2],
                    ),
                ),
                UInt64(2) => EitherOptions(
                    Dict{UInt64,Any}(
                        0x6bc2689b3f9c3031 =>
                            Set(Set{Vector{Int64}}[Set([[1, 2, 3]]), Set([[3, 5, 2, 5, 2]]), Set([[2]])]),
                        0x8f23b130f21cfac2 => Set(Set{Vector{Int64}}[Set([[2]]), Set([[1, 2, 3], [1, 4, 2, 2]])]),
                        0x3153e6863760efd0 =>
                            Set(Set{Vector{Int64}}[Set([[3, 5, 2, 5, 2], [1, 4, 2, 2]]), Set([[2]])]),
                        0x50c67e216811b75a =>
                            Set(Set{Vector{Int64}}[Set([[3, 5, 2, 5, 2], [1, 2, 3], [1, 4, 2, 2]])]),
                    ),
                ),
            ),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [1, 2, 3], UInt64(2) => Set([Set([[1, 4, 2, 2], [3, 5, 2, 5, 2]]), Set([[2]])])),
        ) == Set([Set([[1, 2, 3], [1, 4, 2, 2], [3, 5, 2, 5, 2]]), Set([[2]])])

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [1, 4, 2, 2], UInt64(2) => Set([Set([[1, 2, 3]]), Set([[3, 5, 2, 5, 2]]), Set([[2]])])),
        ) == Set([Set([[1, 2, 3], [1, 4, 2, 2], [3, 5, 2, 5, 2]]), Set([[2]])])
    end

    @testset "Reverse rev_fold_set with rev_greedy_cluster" begin
        skeleton = parse_program(
            "(rev_fold_set (lambda (lambda (rev_greedy_cluster (lambda (lambda (any_set (lambda (not (gt? (abs (- (length \$0) (length \$2))) 1))) \$0))) \$1 \$0))) empty_set ??(set(list(int))))",
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([[1, 2, 3], [1, 4, 2, 2], [3, 5, 2, 5, 2], [2]])),
            Dict(UInt64(1) => Set([Set([[1, 2, 3], [1, 4, 2, 2], [3, 5, 2, 5, 2]]), Set([[2]])])),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => Set([Set([[1, 2, 3], [1, 4, 2, 2], [3, 5, 2, 5, 2]]), Set([[2]])])),
        ) == Set([[1, 2, 3], [1, 4, 2, 2], [3, 5, 2, 5, 2], [2]])
    end
end


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
    get_reversed_program,
    is_reversible,
    parse_program,
    closed_inference,
    any_object,
    tgrid,
    tcolor,
    _is_possible_selector,
    is_reversible_selector,
    _is_possible_mapper,
    _is_reversible_mapper,
    arrow,
    tbool,
    EnumerationException,
    run_with_arguments,
    Tp,
    ttuple2,
    ttuple3
using DataStructures: OrderedDict, Accumulator

@testset "Abstractors" begin
    @testset "Check reversible simple" begin
        @test is_reversible(
            Apply(
                Apply(every_primitive["repeat"], Hole(tint, nothing, true, nothing)),
                Hole(tint, nothing, true, nothing),
            ),
        )
    end

    @testset "Check reversible map" begin
        @test !is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(every_primitive["repeat"], Hole(tint, nothing, true, _is_possible_mapper)),
                            Hole(tint, nothing, true, _is_possible_mapper),
                        ),
                    ),
                ),
                Hole(tlist(ttuple2(tint, tint)), nothing, true, nothing),
            ),
        )
        @test is_reversible(
            Apply(
                Apply(every_primitive["map"], Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(0)))),
                Hole(tlist(tint), nothing, true, nothing),
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
                                    Apply(every_primitive["repeat"], Hole(tint, nothing, true, _is_possible_mapper)),
                                    Hole(tint, nothing, true, _is_possible_mapper),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
        )
        @test is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(1)))),
                    ),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
        )
        @test is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["repeat"], Index(1)), Index(0)))),
                    ),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
        )
        @test !is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(every_primitive["cons"], Index(0)),
                            Hole(tlist(tbool), nothing, true, _is_possible_mapper),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, true, nothing),
            ),
        )
        @test !_is_reversible_mapper(
            Abstraction(
                Apply(Apply(every_primitive["cons"], Index(0)), Hole(tlist(tbool), nothing, true, _is_possible_mapper)),
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
                                                            Hole(tint, nothing, true, _is_possible_mapper),
                                                        ),
                                                        Hole(tint, nothing, true, _is_possible_mapper),
                                                    ),
                                                ),
                                            ),
                                        ),
                                        Hole(tlist(tint), nothing, true, _is_possible_mapper),
                                    ),
                                    Hole(tlist(tint), nothing, true, _is_possible_mapper),
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
                                        Hole(tlist(tint), nothing, true, _is_possible_mapper),
                                    ),
                                    Hole(tlist(tint), nothing, true, _is_possible_mapper),
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
                                        Index(1),
                                    ),
                                    Index(0),
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
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(
                                every_primitive["map"],
                                Abstraction(
                                    Apply(
                                        Apply(
                                            every_primitive["repeat"],
                                            Hole(tint, nothing, true, _is_possible_mapper),
                                        ),
                                        Hole(tint, nothing, true, _is_possible_mapper),
                                    ),
                                ),
                            ),
                            Hole(tlist(tlist(tint)), nothing, true, _is_possible_mapper),
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
                            Hole(tlist(tint), nothing, true, _is_possible_mapper),
                        ),
                    ),
                ),
                Hole(tlist(tlist(tint)), nothing, true, nothing),
            ),
        )
        @test is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(
                                every_primitive["map"],
                                Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(0))),
                            ),
                            Index(0),
                        ),
                    ),
                ),
                Hole(tlist(tlist(tint)), nothing, true, nothing),
            ),
        )
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

        @test is_reversible(
            Apply(
                Apply(
                    Apply(every_primitive["rev_select"], Abstraction(Apply(every_primitive["empty?"], Index(0)))),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
        )
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
        skeleton = Apply(
            Apply(every_primitive["repeat"], Hole(tint, nothing, true, nothing)),
            Hole(tint, nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)
        @test rev_p([[1, 2, 3], [1, 2, 3]]) == [[1, 2, 3], 2]
        @test rev_p([1, 1, 1]) == [1, 3]
        @test rev_p([1, any_object, 1]) == [1, 3]
        @test rev_p([any_object, any_object, 1]) == [1, 3]
        @test rev_p([any_object, any_object, 1])[1] !== any_object
    end

    @testset "Reverse repeat grid" begin
        skeleton = Apply(
            Apply(
                Apply(every_primitive["repeat_grid"], Hole(tint, nothing, true, nothing)),
                Hole(tint, nothing, true, nothing),
            ),
            Hole(tint, nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[[1, 2, 3], [1, 2, 3]] [[1, 2, 3], [1, 2, 3]] [[1, 2, 3], [1, 2, 3]]]) == [[1, 2, 3], 2, 3]
        @test rev_p([[1, 1, 1] [1, 1, 1]]) == [1, 3, 2]
        @test rev_p([[1, any_object, 1] [1, any_object, any_object]]) == [1, 3, 2]
        @test rev_p([[any_object, any_object, 1] [any_object, any_object, any_object]]) == [1, 3, 2]
        @test rev_p([[any_object, any_object, 1] [any_object, any_object, any_object]])[1] !== any_object
    end

    @testset "Reverse cons" begin
        skeleton = Apply(
            Apply(every_primitive["cons"], Hole(tint, nothing, true, nothing)),
            Hole(tlist(tint), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)
        @test rev_p([1, 2, 3]) == [1, [2, 3]]
    end

    @testset "Reverse combined abstractors" begin
        skeleton = Apply(
            Apply(
                every_primitive["repeat"],
                Apply(
                    Apply(every_primitive["cons"], Hole(tint, nothing, true, nothing)),
                    Hole(tlist(tint), nothing, true, nothing),
                ),
            ),
            Hole(tint, nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[1, 2], [1, 2], [1, 2]]) == [1, [2], 3]
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
                                    Apply(every_primitive["repeat"], Hole(tint, nothing, true, _is_possible_mapper)),
                                    Hole(tint, nothing, true, _is_possible_mapper),
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
            skeleton = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["repeat"], Index(1)), Index(0)))),
                    ),
                    Hole(tlist(t0), nothing, true, nothing),
                ),
                Hole(tlist(t1), nothing, true, nothing),
            )
            @test is_reversible(skeleton)

            rev_p = get_reversed_program(skeleton)

            @test rev_p([[1, 1, 1], [2, 2], [4]]) == [[1, 2, 4], [3, 2, 1]]

            p = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["repeat"], Index(1)), Index(0)))),
                    ),
                    FreeVar(tlist(tint), UInt64(1)),
                ),
                FreeVar(tlist(tint), UInt64(2)),
            )
            @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 2, 4], UInt64(2) => [3, 2, 1])) ==
                  [[1, 1, 1], [2, 2], [4]]
        end

        @testset "repeat indices 0 1" begin
            skeleton = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(1)))),
                    ),
                    Hole(tlist(t0), nothing, true, nothing),
                ),
                Hole(tlist(t1), nothing, true, nothing),
            )
            @test is_reversible(skeleton)

            rev_p = get_reversed_program(skeleton)

            @test rev_p([[1, 1, 1], [2, 2], [4]]) == [[3, 2, 1], [1, 2, 4]]

            p = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(1)))),
                    ),
                    FreeVar(tlist(tint), UInt64(1)),
                ),
                FreeVar(tlist(tint), UInt64(2)),
            )
            @test run_with_arguments(p, [], Dict(UInt64(2) => [1, 2, 4], UInt64(1) => [3, 2, 1])) ==
                  [[1, 1, 1], [2, 2], [4]]
        end

        @testset "cons indices 1 0" begin
            skeleton = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                    ),
                    Hole(tlist(t0), nothing, true, nothing),
                ),
                Hole(tlist(t1), nothing, true, nothing),
            )
            @test is_reversible(skeleton)
            rev_p = get_reversed_program(skeleton)

            @test rev_p([[1, 1, 1], [2, 2], [4]]) == [[1, 2, 4], [[1, 1], [2], []]]

            p = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                    ),
                    FreeVar(tlist(tint), UInt64(1)),
                ),
                FreeVar(tlist(tlist(tint)), UInt64(2)),
            )
            @test run_with_arguments(p, [], Dict(UInt64(2) => [[1, 1], [2], []], UInt64(1) => [1, 2, 4])) ==
                  [[1, 1, 1], [2, 2], [4]]
        end

        @testset "cons indices 0 1" begin
            skeleton = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(0)), Index(1)))),
                    ),
                    Hole(tlist(t0), nothing, true, nothing),
                ),
                Hole(tlist(t1), nothing, true, nothing),
            )
            @test is_reversible(skeleton)
            rev_p = get_reversed_program(skeleton)

            @test rev_p([[1, 1, 1], [2, 2], [4]]) == [[[1, 1], [2], []], [1, 2, 4]]

            p = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(0)), Index(1)))),
                    ),
                    FreeVar(tlist(tlist(tint)), UInt64(1)),
                ),
                FreeVar(tlist(tint), UInt64(2)),
            )
            @test run_with_arguments(p, [], Dict(UInt64(1) => [[1, 1], [2], []], UInt64(2) => [1, 2, 4])) ==
                  [[1, 1, 1], [2, 2], [4]]
        end
    end

    @testset "Reverse nested map2" begin
        skeleton = Apply(
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
                                            Abstraction(Apply(Apply(every_primitive["repeat"], Index(1)), Index(0))),
                                        ),
                                    ),
                                    Index(1),
                                ),
                                Index(0),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, true, nothing),
            ),
            Hole(tlist(t1), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[[1, 1, 1], [2, 2], [4]], [[3, 3, 3, 3], [2, 2, 2], [8, 8, 8]]]) ==
              [[[1, 2, 4], [3, 2, 8]], [[3, 2, 1], [4, 3, 3]]]

        p = Apply(
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
                                            Abstraction(Apply(Apply(every_primitive["repeat"], Index(1)), Index(0))),
                                        ),
                                    ),
                                    Index(1),
                                ),
                                Index(0),
                            ),
                        ),
                    ),
                ),
                FreeVar(tlist(tlist(tint)), UInt64(1)),
            ),
            FreeVar(tlist(tlist(tint)), UInt64(2)),
        )
        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [[1, 2, 4], [3, 2, 8]], UInt64(2) => [[3, 2, 1], [4, 3, 3]]),
        ) == [[[1, 1, 1], [2, 2], [4]], [[3, 3, 3, 3], [2, 2, 2], [8, 8, 8]]]
    end

    @testset "Reverse range" begin
        skeleton = Apply(every_primitive["range"], Hole(tint, nothing, true, nothing))
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([0, 1, 2]) == [2]
        @test rev_p([]) == [-1]
    end

    @testset "Reverse map with range" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(every_primitive["range"], Hole(tint, nothing, true, _is_possible_mapper))),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test !is_reversible(skeleton)

        skeleton = Apply(
            Apply(every_primitive["map"], Abstraction(Apply(every_primitive["range"], Index(0)))),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[0, 1, 2], [0, 1], [0, 1, 2, 3]]) == [[2, 1, 3]]
    end

    @testset "Reverse map with repeat" begin
        skeleton = Apply(
            Apply(every_primitive["map"], Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(0)))),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[1], [2, 2], [4, 4, 4, 4]]) == [[1, 2, 4]]
        @test_throws ErrorException rev_p([[1, 1], [2, 2], [4, 4, 4, 4]])

        p = Apply(
            Apply(every_primitive["map"], Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(0)))),
            FreeVar(tlist(tint), UInt64(1)),
        )
        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 2, 4])) == [[1], [2, 2], [4, 4, 4, 4]]
    end

    @testset "Reverse map2 with either options" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["map2"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["concat"], Index(1)), Index(0)))),
                ),
                Hole(tlist(t0), nothing, true, nothing),
            ),
            Hole(tlist(t1), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p(Vector{Any}[[1, 1, 1], [0, 0, 0], [3, 0, 0]]) == [
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
            EitherOptions(
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
        ]
    end

    @testset "Reverse rows with either" begin
        skeleton = Apply(every_primitive["rows"], Hole(tgrid(tcolor), nothing, true, nothing))
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test_throws ArgumentError rev_p(
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

        rev_p = get_reversed_program(skeleton)

        rev_res = rev_p([1, 2, 1, 3, 2, 1])
        expected = Dict(
            1 => [1, [1, any_object, 1, any_object, any_object, 1], [nothing, 2, nothing, 3, 2, nothing]],
            2 => [2, [any_object, 2, any_object, any_object, 2, any_object], [1, nothing, 1, 3, nothing, 1]],
            3 => [3, [any_object, any_object, any_object, 3, any_object, any_object], [1, 2, 1, nothing, 2, 1]],
        )
        for (k, v) in rev_res[1].options
            for i in 1:3
                @test rev_res[i].options[k] == expected[v][i]
            end
        end
    end

    @testset "Reverse rev select with empty" begin
        skeleton = Apply(
            Apply(
                Apply(every_primitive["rev_select"], Abstraction(Apply(every_primitive["empty?"], Index(0)))),
                Hole(tlist(tlist(tint)), nothing, true, nothing),
            ),
            Hole(tlist(tlist(tint)), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[0, 1, 2], [], [0, 1, 2, 3]]) == [[any_object, [], any_object], [[0, 1, 2], nothing, [0, 1, 2, 3]]]
    end

    @testset "Invented abstractor" begin
        source = "#(lambda (lambda (repeat (cons \$1 \$0))))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = Apply(
            Apply(Apply(expression, Hole(t0, nothing, true, nothing)), Hole(tlist(t0), nothing, true, nothing)),
            Hole(tint, nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3]]) == [1, [2, 3], 4]
    end

    @testset "Invented abstractor with range" begin
        source = "#(lambda (repeat (range \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = Apply(Apply(expression, Hole(tint, nothing, true, nothing)), Hole(tint, nothing, true, nothing))
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]]) == [3, 4]
    end

    @testset "Invented abstractor with range in map2" begin
        source = "#(lambda (repeat (range \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = Apply(
            Apply(
                Apply(every_primitive["map2"], Abstraction(Abstraction(Apply(Apply(expression, Index(1)), Index(0))))),
                Hole(tlist(t0), nothing, true, nothing),
            ),
            Hole(tlist(t1), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]], [[0, 1, 2], [0, 1, 2]]]) ==
              [[3, 2], [4, 2]]
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
                            Hole(tlist(tcolor), nothing, true, _is_possible_mapper),
                        ),
                        Hole(tlist(tcolor), nothing, true, _is_possible_mapper),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, true, nothing),
        )

        @test !is_reversible(skeleton)
        @test_throws MethodError get_reversed_program(skeleton)
    end

    @testset "Reverse list elements" begin
        skeleton = Apply(
            Apply(every_primitive["rev_list_elements"], Hole(tlist(ttuple2(tint, tint)), nothing, true, nothing)),
            Hole(tint, nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([3, 2, 1]) == [[(1, 3), (2, 2), (3, 1)], 3]
        @test rev_p([3, nothing, 1]) == [[(1, 3), (3, 1)], 3]
        @test rev_p([3, 2, nothing]) == [[(1, 3), (2, 2)], 3]

        p = Apply(
            Apply(every_primitive["rev_list_elements"], FreeVar(tlist(ttuple2(tint, tint)), UInt64(1))),
            FreeVar(tint, UInt64(2)),
        )
        @test run_with_arguments(p, [], Dict(UInt64(1) => [(1, 3), (2, 2), (3, 1)], UInt64(2) => 3)) == [3, 2, 1]
        @test run_with_arguments(p, [], Dict(UInt64(1) => [(1, 3), (3, 1)], UInt64(2) => 3)) == [3, nothing, 1]
        @test run_with_arguments(p, [], Dict(UInt64(1) => [(1, 3), (2, 2)], UInt64(2) => 3)) == [3, 2, nothing]
    end

    @testset "Reverse grid elements" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["rev_grid_elements"],
                    Hole(tlist(ttuple2(ttuple2(tint, tint), tint)), nothing, true, nothing),
                ),
                Hole(tint, nothing, true, nothing),
            ),
            Hole(tint, nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[3, 2, 1] [4, 5, 6]]) ==
              [[((1, 1), 3), ((1, 2), 4), ((2, 1), 2), ((2, 2), 5), ((3, 1), 1), ((3, 2), 6)], 3, 2]
        @test rev_p([[3, nothing, 1] [4, 5, 6]]) ==
              [[((1, 1), 3), ((1, 2), 4), ((2, 2), 5), ((3, 1), 1), ((3, 2), 6)], 3, 2]
        @test rev_p([[3, 2, 1] [nothing, nothing, nothing]]) == [[((1, 1), 3), ((2, 1), 2), ((3, 1), 1)], 3, 2]

        p = Apply(
            Apply(
                Apply(
                    every_primitive["rev_grid_elements"],
                    FreeVar(tlist(ttuple2(ttuple2(tint, tint), tint)), UInt64(1)),
                ),
                FreeVar(tint, UInt64(2)),
            ),
            FreeVar(tint, UInt64(3)),
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
        skeleton = Apply(
            Apply(every_primitive["zip2"], Hole(tlist(tint), nothing, true, nothing)),
            Hole(tlist(tcolor), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([(1, 3), (2, 2), (3, 1)]) == [[1, 2, 3], [3, 2, 1]]
        p = Apply(Apply(every_primitive["zip2"], FreeVar(tlist(tint), UInt64(1))), FreeVar(tlist(tcolor), UInt64(2)))
        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 2, 3], UInt64(2) => [3, 2, 1])) ==
              [(1, 3), (2, 2), (3, 1)]
    end

    @testset "Reverse zip_grid2" begin
        skeleton = Apply(
            Apply(every_primitive["zip2"], Hole(tgrid(tint), nothing, true, nothing)),
            Hole(tgrid(tcolor), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p([[(1, 3), (2, 2), (3, 1)] [(4, 5), (9, 2), (2, 5)]]) ==
              [[[1, 2, 3] [4, 9, 2]], [[3, 2, 1] [5, 2, 5]]]
        p = Apply(Apply(every_primitive["zip2"], FreeVar(tgrid(tint), UInt64(1))), FreeVar(tgrid(tcolor), UInt64(2)))
        @test run_with_arguments(p, [], Dict(UInt64(1) => [[1, 2, 3] [4, 9, 2]], UInt64(2) => [[3, 2, 1] [5, 2, 5]])) ==
              [[(1, 3), (2, 2), (3, 1)] [(4, 5), (9, 2), (2, 5)]]
    end

    @testset "Reverse rev_fold" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["rev_fold"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                ),
                every_primitive["empty"],
            ),
            Hole(tlist(tint), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        rev_p = get_reversed_program(skeleton)

        @test rev_p([2, 4, 1, 4, 1]) == [[1, 4, 1, 4, 2]]

        p = Apply(
            Apply(
                Apply(
                    every_primitive["rev_fold"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                ),
                every_primitive["empty"],
            ),
            FreeVar(tlist(tint), UInt64(1)),
        )
        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 4, 1, 4, 2])) == [2, 4, 1, 4, 1]
    end

    @testset "Reverse fold" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                ),
                Hole(tlist(tint), nothing, true, nothing),
            ),
            Hole(tlist(tint), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        rev_p = get_reversed_program(skeleton)

        @test rev_p([2, 4, 1, 4, 1]) == [
            EitherOptions(
                Dict{UInt64,Any}(
                    0x9453a87fcd5f6f00 => Any[],
                    0xee18ccb3f3dadb77 => Any[2, 4, 1, 4],
                    0x60bf4ed0b3277eff => Any[2],
                    0xa5394d30d3d286b9 => Any[2, 4],
                    0x8baad56386e024ec => Any[2, 4, 1, 4, 1],
                    0x02d60cc1c7e6b755 => Any[2, 4, 1],
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0x9453a87fcd5f6f00 => [2, 4, 1, 4, 1],
                    0xee18ccb3f3dadb77 => [1],
                    0x60bf4ed0b3277eff => [4, 1, 4, 1],
                    0xa5394d30d3d286b9 => [1, 4, 1],
                    0x8baad56386e024ec => Int64[],
                    0x02d60cc1c7e6b755 => [4, 1],
                ),
            ),
        ]

        p = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                ),
                FreeVar(tlist(tint), UInt64(1)),
            ),
            FreeVar(tlist(tint), UInt64(2)),
        )
        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 4, 1, 4, 2], UInt64(2) => [])) == [1, 4, 1, 4, 2]
    end

    @testset "Reverse fold with concat" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["concat"], Index(1)), Index(0)))),
                ),
                Hole(tlist(tlist(tint)), nothing, true, nothing),
            ),
            Hole(tlist(tint), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        rev_p = get_reversed_program(skeleton)

        @test rev_p([2, 4, 1, 4, 1]) == [
            EitherOptions(
                Dict{UInt64,Any}(
                    0xe3b772ed30bd1603 => Any[[2], [4, 1], [4], [1]],
                    0xefad2bee99d827e1 => Any[[2], [4], [1, 4, 1]],
                    0x92d3a49196b6ec26 => Any[[2], [4], [1]],
                    0x78a4b116b771ebb4 => Any[[2, 4]],
                    0x2422ddddbbb4f32f => Any[[2, 4], [1, 4, 1]],
                    0x9453a87fcd5f6f00 => Any[],
                    0x1e841f32224786b7 => Any[[2], [4], [1], [4], [1]],
                    0xe3371c313212dd43 => Any[[2, 4, 1, 4, 1]],
                    0x4c8cf1adf1af769e => Any[[2], [4], [1, 4]],
                    0x88791d1e62714523 => Any[[2], [4]],
                    0xb2f92e306794ff1e => Any[[2], [4, 1], [4, 1]],
                    0xc0a0171f4fa5372c => Any[[2, 4], [1]],
                    0xf93f16a9dbd5aa89 => Any[[2, 4, 1], [4], [1]],
                    0x340528480ae7d245 => Any[[2, 4, 1, 4], [1]],
                    0x25fb53c9ad54723f => Any[[2, 4], [1], [4], [1]],
                    0x039f8b34c81db882 => Any[[2], [4, 1], [4]],
                    0x8172801003a5d07a => Any[[2, 4], [1], [4, 1]],
                    0x32ada425ce5e090f => Any[[2], [4], [1, 4], [1]],
                    0x8022d7c0c9234f15 => Any[[2], [4, 1, 4, 1]],
                    0xda854f001b269690 => Any[[2], [4, 1]],
                    0x03e9070d5f1e33fb => Any[[2, 4, 1], [4]],
                    0xb1782afb61a42e8c => Any[[2, 4, 1]],
                    0x678d482f38247116 => Any[[2, 4], [1, 4], [1]],
                    0x903de0f197a422bb => Any[[2], [4], [1], [4]],
                    0x55ba6e4fe60924b3 => Any[[2, 4, 1], [4, 1]],
                    0xc6ef9cebfce26584 => Any[[2, 4], [1, 4]],
                    0x1efac6ea27e12c4d => Any[[2], [4, 1, 4], [1]],
                    0xbecc6fea3ec2c80e => Any[[2, 4], [1], [4]],
                    0x90bc26734956aa6f => Any[[2], [4, 1, 4]],
                    0xc5b4b785e06feb5a => Any[[2, 4, 1, 4]],
                    0x156c6acf03db047e => Any[[2]],
                    0x4c92dc0699df6873 => Any[[2], [4], [1], [4, 1]],
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0xe3b772ed30bd1603 => Int64[],
                    0xefad2bee99d827e1 => Int64[],
                    0x92d3a49196b6ec26 => [4, 1],
                    0x78a4b116b771ebb4 => [1, 4, 1],
                    0x2422ddddbbb4f32f => Int64[],
                    0x9453a87fcd5f6f00 => [2, 4, 1, 4, 1],
                    0x1e841f32224786b7 => Int64[],
                    0xe3371c313212dd43 => Int64[],
                    0x4c8cf1adf1af769e => [1],
                    0x88791d1e62714523 => [1, 4, 1],
                    0xb2f92e306794ff1e => Int64[],
                    0xc0a0171f4fa5372c => [4, 1],
                    0xf93f16a9dbd5aa89 => Int64[],
                    0x340528480ae7d245 => Int64[],
                    0x25fb53c9ad54723f => Int64[],
                    0x039f8b34c81db882 => [1],
                    0x8172801003a5d07a => Int64[],
                    0x32ada425ce5e090f => Int64[],
                    0x8022d7c0c9234f15 => Int64[],
                    0xda854f001b269690 => [4, 1],
                    0x03e9070d5f1e33fb => [1],
                    0xb1782afb61a42e8c => [4, 1],
                    0x678d482f38247116 => Int64[],
                    0x903de0f197a422bb => [1],
                    0x55ba6e4fe60924b3 => Int64[],
                    0xc6ef9cebfce26584 => [1],
                    0x1efac6ea27e12c4d => Int64[],
                    0xbecc6fea3ec2c80e => [1],
                    0x90bc26734956aa6f => [1],
                    0xc5b4b785e06feb5a => [1],
                    0x156c6acf03db047e => [4, 1, 4, 1],
                    0x4c92dc0699df6873 => Int64[],
                ),
            ),
        ]

        p = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["concat"], Index(1)), Index(0)))),
                ),
                FreeVar(tlist(tlist(tint)), UInt64(1)),
            ),
            FreeVar(tlist(tint), UInt64(2)),
        )
        @test run_with_arguments(p, [], Dict(UInt64(1) => [[1, 4, 1, 4, 2], [3, 5, 2, 5]], UInt64(2) => [])) ==
              [1, 4, 1, 4, 2, 3, 5, 2, 5]
    end

    @testset "Reverse fold_h" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold_h"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                ),
                Hole(tgrid(tint), nothing, true, nothing),
            ),
            Hole(tlist(tlist(tint)), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        rev_p = get_reversed_program(skeleton)

        @test rev_p([[1, 3, 9], [4, 6, 1], [1, 1, 4], [4, 5, 0], [2, 2, 4]]) == [
            EitherOptions(
                Dict{UInt64,Any}(
                    0x434f074fb5907810 => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0; 2 2 4],
                    0x6ca162fa7613d2c5 => Any[1; 4; 1; 4; 2;;],
                    0xc72d85f67d60437d => Any[1 3; 4 6; 1 1; 4 5; 2 2],
                    0x09a140b0b4d7393c => Matrix{Any}(undef, 5, 0),
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0x434f074fb5907810 => Any[[], [], [], [], []],
                    0x6ca162fa7613d2c5 => Any[[3, 9], [6, 1], [1, 4], [5, 0], [2, 4]],
                    0xc72d85f67d60437d => Any[[9], [1], [4], [0], [4]],
                    0x09a140b0b4d7393c => [[1, 3, 9], [4, 6, 1], [1, 1, 4], [4, 5, 0], [2, 2, 4]],
                ),
            ),
        ]

        p = Apply(
            Apply(
                Apply(
                    every_primitive["fold_h"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                ),
                FreeVar(tgrid(tint), UInt64(1)),
            ),
            FreeVar(tlist(tlist(tint)), UInt64(2)),
        )
        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [[1, 4, 1, 4, 2] [3, 6, 1, 5, 2] [9, 1, 4, 0, 4]], UInt64(2) => [[], [], [], [], []]),
        ) == [[1, 3, 9], [4, 6, 1], [1, 1, 4], [4, 5, 0], [2, 2, 4]]
    end

    @testset "Reverse fold_v" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold_v"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                ),
                Hole(tgrid(tint), nothing, true, nothing),
            ),
            Hole(tlist(tlist(tint)), nothing, true, nothing),
        )
        @test is_reversible(skeleton)

        rev_p = get_reversed_program(skeleton)

        @test rev_p([[1, 4, 1, 4, 2], [3, 6, 1, 5, 2], [9, 1, 4, 0, 4]]) == [
            EitherOptions(
                Dict{UInt64,Any}(
                    0x1e98f7d47e1e4c0e => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0],
                    0xceee4e28778b81a4 => Any[1 3 9; 4 6 1; 1 1 4],
                    0x5c942edb34b81d2c => Any[1 3 9],
                    0xe76c4bfb8403877f => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0; 2 2 4],
                    0x129c2e0da08316d3 => Matrix{Any}(undef, 0, 3),
                    0xdb16df8f58606a0e => Any[1 3 9; 4 6 1],
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0x1e98f7d47e1e4c0e => Any[[2], [2], [4]],
                    0xceee4e28778b81a4 => Any[[4, 2], [5, 2], [0, 4]],
                    0x5c942edb34b81d2c => Any[[4, 1, 4, 2], [6, 1, 5, 2], [1, 4, 0, 4]],
                    0xe76c4bfb8403877f => Any[Int64[], Int64[], Int64[]],
                    0x129c2e0da08316d3 => [[1, 4, 1, 4, 2], [3, 6, 1, 5, 2], [9, 1, 4, 0, 4]],
                    0xdb16df8f58606a0e => Any[[1, 4, 2], [1, 5, 2], [4, 0, 4]],
                ),
            ),
        ]

        p = Apply(
            Apply(
                Apply(
                    every_primitive["fold_v"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["cons"], Index(1)), Index(0)))),
                ),
                FreeVar(tgrid(tint), UInt64(1)),
            ),
            FreeVar(tlist(tlist(tint)), UInt64(2)),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [[1, 4, 1, 4, 2] [3, 6, 1, 5, 2] [9, 1, 4, 0, 4]], UInt64(2) => [[], [], []]),
        ) == [[1, 4, 1, 4, 2], [3, 6, 1, 5, 2], [9, 1, 4, 0, 4]]
    end
end

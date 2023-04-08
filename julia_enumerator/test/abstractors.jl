
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
    _is_possible_subfunction,
    _is_reversible_subfunction,
    arrow,
    tbool,
    EnumerationException,
    run_with_arguments,
    Tp,
    ttuple2,
    ttuple3,
    tset
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
                            Apply(every_primitive["repeat"], Hole(tint, nothing, true, _is_possible_subfunction)),
                            Hole(tint, nothing, true, _is_possible_subfunction),
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

    @testset "Reverse adjoin" begin
        skeleton = Apply(
            Apply(every_primitive["adjoin"], Hole(tint, nothing, true, nothing)),
            Hole(tset(tint), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p(Set([1, 2, 3])) == [
            EitherOptions(Dict{UInt64,Any}(0xdab8105ae838a43f => 1, 0x369f7593fdd6aa68 => 3, 0xa546dd1af6daadbb => 2)),
            EitherOptions(
                Dict{UInt64,Any}(
                    0xdab8105ae838a43f => Set([2, 3]),
                    0x369f7593fdd6aa68 => Set([2, 1]),
                    0xa546dd1af6daadbb => Set([3, 1]),
                ),
            ),
        ]

        p = Apply(Apply(every_primitive["adjoin"], FreeVar(tint, UInt64(1))), FreeVar(tset(tint), UInt64(2)))
        @test run_with_arguments(p, [], Dict(UInt64(1) => 1, UInt64(2) => Set([3, 2]))) == Set([1, 2, 3])
    end

    @testset "Reverse tuple2" begin
        skeleton = Apply(
            Apply(every_primitive["tuple2"], Hole(tcolor, nothing, true, nothing)),
            Hole(tlist(tint), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)
        @test rev_p((1, [2, 3])) == [1, [2, 3]]
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
                Abstraction(Apply(every_primitive["range"], Hole(tint, nothing, true, _is_possible_subfunction))),
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

    @testset "Reverse map set with range" begin
        skeleton = Apply(
            Apply(
                every_primitive["map_set"],
                Abstraction(Apply(every_primitive["range"], Hole(tint, nothing, true, _is_possible_subfunction))),
            ),
            Hole(tset(t0), nothing, true, nothing),
        )
        @test !is_reversible(skeleton)

        skeleton = Apply(
            Apply(every_primitive["map_set"], Abstraction(Apply(every_primitive["range"], Index(0)))),
            Hole(tset(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p(Set([[0, 1, 2], [0, 1], [0, 1, 2, 3]])) == [Set([2, 1, 3])]
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

    @testset "Reverse map set with tuple" begin
        skeleton = Apply(
            Apply(
                every_primitive["map_set"],
                Abstraction(Apply(Apply(every_primitive["tuple2"], Index(0)), FreeVar(tint, nothing))),
            ),
            Hole(tset(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p(Set([(3, 2), (1, 2), (6, 2)])) == [2, Set([3, 1, 6])]
        @test_throws ErrorException rev_p(Set([(3, 2), (1, 2), (6, 3)]))

        p = Apply(
            Apply(
                every_primitive["map_set"],
                Abstraction(Apply(Apply(every_primitive["tuple2"], Index(0)), FreeVar(tint, UInt64(1)))),
            ),
            FreeVar(tset(tint), UInt64(2)),
        )
        @test run_with_arguments(p, [], Dict(UInt64(1) => 2, UInt64(2) => Set([3, 1, 6]))) ==
              Set([(3, 2), (1, 2), (6, 2)])
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

    @testset "Reverse map with either options" begin
        skeleton = Apply(
            Apply(every_primitive["map"], Abstraction(Apply(Apply(every_primitive["concat"], Index(0)), Index(0)))),
            Hole(tlist(t0), nothing, true, nothing),
        )
        @test is_reversible(skeleton)
        rev_p = get_reversed_program(skeleton)

        @test rev_p(Vector{Any}[[1, 2, 1, 2], [0, 0, 0, 0], [3, 0, 1, 3, 0, 1]]) == [[[1, 2], [0, 0], [3, 0, 1]]]
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
        rev_p = get_reversed_program(skeleton)

        @test rev_p(Vector{Any}[[1, 1, 1, 0, 0], [0, 0, 0], [3, 0, 0]]) == [
            EitherOptions(
                Dict{UInt64,Any}(
                    0xdab1e199b1c94074 => Any[],
                    0x0c3b2c341e5c3951 => Any[0],
                    0x75e9840090e65b2f => Any[0, 0],
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0xdab1e199b1c94074 => Any[Any[1, 1, 1, 0, 0], Any[0, 0, 0], Any[3, 0, 0]],
                    0x0c3b2c341e5c3951 => Any[Any[1, 1, 1, 0], Any[0, 0], Any[3, 0]],
                    0x75e9840090e65b2f => Any[Any[1, 1, 1], Any[0], Any[3]],
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

        rev_p = get_reversed_program(skeleton)

        rev_res = rev_p(Set([1, 2, 3]))
        expected =
            Dict(1 => [1, Set([1]), Set([2, 3])], 2 => [2, Set([2]), Set([1, 3])], 3 => [3, Set([3]), Set([1, 2])])
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
                            Hole(tlist(tcolor), nothing, true, _is_possible_subfunction),
                        ),
                        Hole(tlist(tcolor), nothing, true, _is_possible_subfunction),
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

        @test rev_p([3, 2, 1]) == [Set([(1, 3), (2, 2), (3, 1)]), 3]
        @test rev_p([3, nothing, 1]) == [Set([(1, 3), (3, 1)]), 3]
        @test rev_p([3, 2, nothing]) == [Set([(1, 3), (2, 2)]), 3]

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
              [Set([((1, 1), 3), ((1, 2), 4), ((2, 1), 2), ((2, 2), 5), ((3, 1), 1), ((3, 2), 6)]), 3, 2]
        @test rev_p([[3, nothing, 1] [4, 5, 6]]) ==
              [Set([((1, 1), 3), ((1, 2), 4), ((2, 2), 5), ((3, 1), 1), ((3, 2), 6)]), 3, 2]
        @test rev_p([[3, 2, 1] [nothing, nothing, nothing]]) == [Set([((1, 1), 3), ((2, 1), 2), ((3, 1), 1)]), 3, 2]

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
                    0x5a93e9ec4bc05a56 => Any[2, 4],
                    0x6a7634569af3396c => Any[2, 4, 1, 4],
                    0x51aaed7b1c6bb305 => Any[2, 4, 1, 4, 1],
                    0xb693e3cf592eb63c => Any[2],
                    0x49021a5ed5ec68f1 => Any[],
                    0x8c2b7a5e76148bda => Any[2, 4, 1],
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0x5a93e9ec4bc05a56 => Any[1, 4, 1],
                    0x6a7634569af3396c => Any[1],
                    0x51aaed7b1c6bb305 => Any[],
                    0xb693e3cf592eb63c => Any[4, 1, 4, 1],
                    0x49021a5ed5ec68f1 => Any[2, 4, 1, 4, 1],
                    0x8c2b7a5e76148bda => Any[4, 1],
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
                    0x6dd1aa195a066bdf => Any[Any[2, 4], Any[1, 4], Any[1]],
                    0xb6ad491e11602fb6 => Any[Any[2], Any[4, 1, 4, 1]],
                    0x36f0abd3c957d902 => Any[Any[2], Any[4], Any[1, 4, 1]],
                    0x3dc89139ec87f684 => Any[Any[2], Any[4, 1, 4]],
                    0x09a21ddf6148cc66 => Any[Any[2, 4, 1, 4], Any[1]],
                    0x429e3e302da41faf => Any[Any[2], Any[4], Any[1, 4]],
                    0xf3a80cf790032ca3 => Any[Any[2], Any[4, 1], Any[4]],
                    0xf8969b46bad3316b => Any[Any[2]],
                    0x91a8ff63c31d3bc0 => Any[Any[2], Any[4], Any[1], Any[4]],
                    0x5749e86be732d170 => Any[Any[2, 4], Any[1], Any[4], Any[1]],
                    0x0e7af63e5e7ef218 => Any[Any[2], Any[4]],
                    0x02e700ab85e09354 => Any[Any[2], Any[4, 1], Any[4], Any[1]],
                    0xce2e31d5d7b90709 => Any[Any[2, 4, 1]],
                    0x8d11ec691b4170ea => Any[Any[2, 4, 1], Any[4], Any[1]],
                    0x49021a5ed5ec68f1 => Any[],
                    0x5c837610f9257f13 => Any[Any[2], Any[4], Any[1]],
                    0x180ce0f9a07c74c0 => Any[Any[2, 4, 1], Any[4]],
                    0x149cc02404fb6a27 => Any[Any[2], Any[4, 1], Any[4, 1]],
                    0x9c96a163ad64d585 => Any[Any[2, 4]],
                    0x56e0a1008192c663 => Any[Any[2, 4], Any[1], Any[4, 1]],
                    0xe0ab1eabc7a900ce => Any[Any[2], Any[4, 1, 4], Any[1]],
                    0x390194261574b244 => Any[Any[2, 4, 1], Any[4, 1]],
                    0xb29db29038157944 => Any[Any[2], Any[4], Any[1], Any[4, 1]],
                    0xc98ebba910891ec0 => Any[Any[2], Any[4], Any[1, 4], Any[1]],
                    0x93ada4f27e102e34 => Any[Any[2, 4, 1, 4, 1]],
                    0xa0404a5fc84c9ab1 => Any[Any[2, 4], Any[1]],
                    0x7aad8022987ef4a0 => Any[Any[2, 4], Any[1, 4, 1]],
                    0x0881941fe61dbdc8 => Any[Any[2], Any[4], Any[1], Any[4], Any[1]],
                    0xac78ebcdfc97b49b => Any[Any[2, 4, 1, 4]],
                    0x865b127efccb3b4d => Any[Any[2, 4], Any[1, 4]],
                    0xd1c6f8802c3bc955 => Any[Any[2], Any[4, 1]],
                    0x35ebedd40c9a88df => Any[Any[2, 4], Any[1], Any[4]],
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0x6dd1aa195a066bdf => Any[],
                    0xb6ad491e11602fb6 => Any[],
                    0x36f0abd3c957d902 => Any[],
                    0x3dc89139ec87f684 => Any[1],
                    0x09a21ddf6148cc66 => Any[],
                    0x429e3e302da41faf => Any[1],
                    0xf3a80cf790032ca3 => Any[1],
                    0xf8969b46bad3316b => Any[4, 1, 4, 1],
                    0x91a8ff63c31d3bc0 => Any[1],
                    0x5749e86be732d170 => Any[],
                    0x0e7af63e5e7ef218 => Any[1, 4, 1],
                    0x02e700ab85e09354 => Any[],
                    0xce2e31d5d7b90709 => Any[4, 1],
                    0x8d11ec691b4170ea => Any[],
                    0x49021a5ed5ec68f1 => Any[2, 4, 1, 4, 1],
                    0x5c837610f9257f13 => Any[4, 1],
                    0x180ce0f9a07c74c0 => Any[1],
                    0x149cc02404fb6a27 => Any[],
                    0x9c96a163ad64d585 => Any[1, 4, 1],
                    0x56e0a1008192c663 => Any[],
                    0xe0ab1eabc7a900ce => Any[],
                    0x390194261574b244 => Any[],
                    0xb29db29038157944 => Any[],
                    0xc98ebba910891ec0 => Any[],
                    0x93ada4f27e102e34 => Any[],
                    0xa0404a5fc84c9ab1 => Any[4, 1],
                    0x7aad8022987ef4a0 => Any[],
                    0x0881941fe61dbdc8 => Any[],
                    0xac78ebcdfc97b49b => Any[1],
                    0x865b127efccb3b4d => Any[1],
                    0xd1c6f8802c3bc955 => Any[4, 1],
                    0x35ebedd40c9a88df => Any[1],
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
                    0x412daf04220dbd95 => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0; 2 2 4],
                    0x1676212d88803b6a => Any[1 3; 4 6; 1 1; 4 5; 2 2],
                    0x05b532410082e162 => Any[1; 4; 1; 4; 2;;],
                    0x48834f8b9af8b495 => Matrix{Any}(undef, 5, 0),
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0x412daf04220dbd95 => Any[Int64[], Int64[], Int64[], Int64[], Int64[]],
                    0x1676212d88803b6a => Any[[9], [1], [4], [0], [4]],
                    0x05b532410082e162 => Any[[3, 9], [6, 1], [1, 4], [5, 0], [2, 4]],
                    0x48834f8b9af8b495 => [[1, 3, 9], [4, 6, 1], [1, 1, 4], [4, 5, 0], [2, 2, 4]],
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
                    0x1052d159da118660 => Matrix{Any}(undef, 0, 3),
                    0x458556b23e850c49 => Any[1 3 9],
                    0x795b80cb1f1a8203 => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0],
                    0x8b8a8aa5dbbc1b17 => Any[1 3 9; 4 6 1],
                    0x79cba76627e90a05 => Any[1 3 9; 4 6 1; 1 1 4],
                    0x0b8058b5a72803e8 => Any[1 3 9; 4 6 1; 1 1 4; 4 5 0; 2 2 4],
                ),
            ),
            EitherOptions(
                Dict{UInt64,Any}(
                    0x1052d159da118660 => [[1, 4, 1, 4, 2], [3, 6, 1, 5, 2], [9, 1, 4, 0, 4]],
                    0x458556b23e850c49 => Any[[4, 1, 4, 2], [6, 1, 5, 2], [1, 4, 0, 4]],
                    0x795b80cb1f1a8203 => Any[[2], [2], [4]],
                    0x8b8a8aa5dbbc1b17 => Any[[1, 4, 2], [1, 5, 2], [4, 0, 4]],
                    0x79cba76627e90a05 => Any[[4, 2], [5, 2], [0, 4]],
                    0x0b8058b5a72803e8 => Any[Int64[], Int64[], Int64[]],
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

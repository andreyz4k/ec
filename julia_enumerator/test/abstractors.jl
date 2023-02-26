
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
    get_reversed_filled_program,
    is_reversible,
    parse_program,
    closed_inference,
    tgrid,
    tcolor,
    is_possible_selector,
    arrow,
    tbool,
    EnumerationException,
    run_with_arguments
using DataStructures: OrderedDict, Accumulator
import Redis

@testset "Abstractors" begin
    @testset "Check reversible simple" begin
        @test is_reversible(
            Apply(Apply(every_primitive["repeat"], Hole(tint, nothing, true)), Hole(tint, nothing, true)),
        )
    end

    @testset "Check reversible map" begin
        @test !is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(Apply(every_primitive["repeat"], Hole(tint, nothing, true)), Hole(tint, nothing, true)),
                    ),
                ),
                Hole(tlist(ttuple2(tint, tint)), nothing, true),
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
                                    Apply(every_primitive["repeat"], Hole(tint, nothing, true)),
                                    Hole(tint, nothing, true),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, true),
                ),
                Hole(tlist(tint), nothing, true),
            ),
        )
    end

    @testset "Check reversible nested map" begin
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
                                                    Apply(
                                                        Apply(every_primitive["repeat"], Hole(tint, nothing, true)),
                                                        Hole(tint, nothing, true),
                                                    ),
                                                ),
                                            ),
                                        ),
                                        Hole(tlist(tint), nothing, true),
                                    ),
                                    Hole(tlist(tint), nothing, true),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tlist(tint)), nothing, true),
                ),
                Hole(tlist(tlist(tint)), nothing, true),
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
                                        Apply(every_primitive["repeat"], Hole(tint, nothing, true)),
                                        Hole(tint, nothing, true),
                                    ),
                                ),
                            ),
                            Hole(tlist(tlist(tint)), nothing, true),
                        ),
                    ),
                ),
                Hole(tlist(ttuple2(tlist(tint), tlist(tint))), nothing, true),
            ),
        )
    end

    @testset "Check reversible select" begin
        @test is_possible_selector(Hole(arrow(tint, tbool), nothing, false))
        @test is_possible_selector(Abstraction(Hole(tbool, nothing, false)))

        @test is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(Apply(Apply(every_primitive["eq?"], Index(0)), Hole(tint, nothing, false))),
                    ),
                    Hole(tlist(tint), nothing, true),
                ),
                Hole(tlist(tint), nothing, true),
            ),
        )
        @test is_possible_selector(
            Abstraction(Apply(Apply(every_primitive["eq?"], Index(0)), Hole(tint, nothing, false))),
        )

        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(
                            Apply(
                                Apply(every_primitive["eq?"], Hole(tint, nothing, false)),
                                Hole(tint, nothing, false),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, true),
                ),
                Hole(tlist(tint), nothing, true),
            ),
        )
        @test is_possible_selector(
            Abstraction(Apply(Apply(every_primitive["eq?"], Hole(tint, nothing, false)), Hole(tint, nothing, false))),
        )

        @test is_reversible(
            Apply(
                Apply(
                    Apply(every_primitive["rev_select"], Abstraction(Apply(every_primitive["empty?"], Index(0)))),
                    Hole(tlist(tint), nothing, true),
                ),
                Hole(tlist(tint), nothing, true),
            ),
        )
        @test is_possible_selector(Abstraction(Apply(every_primitive["empty?"], Index(0))))
        @test !is_possible_selector(Abstraction(Apply(every_primitive["empty?"], Index(1))))

        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(Apply(every_primitive["empty?"], Hole(tint, nothing, false))),
                    ),
                    Hole(tlist(tint), nothing, true),
                ),
                Hole(tlist(tint), nothing, true),
            ),
        )
        @test is_possible_selector(Abstraction(Apply(every_primitive["empty?"], Hole(tint, nothing, false))))
    end

    @testset "Reverse repeat" begin
        skeleton = Apply(Apply(every_primitive["repeat"], Hole(tint, nothing, true)), Hole(tint, nothing, true))
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(Apply(every_primitive["repeat"], FreeVar(tint, nothing)), FreeVar(tint, nothing))
        @test rev_p([[1, 2, 3], [1, 2, 3]]) == [[1, 2, 3], 2]
        @test rev_p([1, 1, 1]) == [1, 3]
    end

    @testset "Reverse cons" begin
        skeleton = Apply(Apply(every_primitive["cons"], Hole(tint, nothing, true)), Hole(tint, nothing, true))
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(Apply(every_primitive["cons"], FreeVar(tint, nothing)), FreeVar(tint, nothing))
        @test rev_p([1, 2, 3]) == [1, [2, 3]]
    end

    @testset "Reverse combined abstractors" begin
        skeleton = Apply(
            Apply(every_primitive["cons"], Hole(tint, nothing, true)),
            Apply(Apply(every_primitive["repeat"], Hole(tint, nothing, true)), Hole(tint, nothing, true)),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(every_primitive["cons"], FreeVar(tint, nothing)),
            Apply(Apply(every_primitive["repeat"], FreeVar(tint, nothing)), FreeVar(tint, nothing)),
        )
        @test rev_p([1, 2, 2, 2]) == [1, 2, 3]
    end

    @testset "Reverse map2" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["map2"],
                    Abstraction(
                        Abstraction(
                            Apply(
                                Apply(every_primitive["repeat"], Hole(tint, nothing, true)),
                                Hole(tint, nothing, true),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(tint), nothing, true),
            ),
            Hole(tlist(tint), nothing, true),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(
                Apply(
                    every_primitive["map2"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(1)))),
                ),
                FreeVar(tlist(tint), nothing),
            ),
            FreeVar(tlist(tint), nothing),
        )
        @test rev_p([[1, 1, 1], [2, 2], [4]]) == [[1, 2, 4], [3, 2, 1]]

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
        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 2, 4], UInt64(2) => [3, 2, 1])) ==
              [[1, 1, 1], [2, 2], [4]]
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
                                            Abstraction(
                                                Apply(
                                                    Apply(every_primitive["repeat"], Hole(tint, nothing, true)),
                                                    Hole(tint, nothing, true),
                                                ),
                                            ),
                                        ),
                                    ),
                                    Hole(tlist(tint), nothing, true),
                                ),
                                Hole(tlist(tint), nothing, true),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(tlist(tint)), nothing, true),
            ),
            Hole(tlist(tlist(tint)), nothing, true),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
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
                                            Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(1))),
                                        ),
                                    ),
                                    Index(0),
                                ),
                                Index(1),
                            ),
                        ),
                    ),
                ),
                FreeVar(tlist(tlist(tint)), nothing),
            ),
            FreeVar(tlist(tlist(tint)), nothing),
        )
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
                                            Abstraction(Apply(Apply(every_primitive["repeat"], Index(0)), Index(1))),
                                        ),
                                    ),
                                    Index(0),
                                ),
                                Index(1),
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
        skeleton = Apply(every_primitive["range"], Hole(tint, nothing, true))
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(every_primitive["range"], FreeVar(tint, nothing))
        @test rev_p([0, 1, 2]) == [2]
        @test rev_p([]) == [-1]
    end

    @testset "Reverse map with range" begin
        skeleton = Apply(
            Apply(every_primitive["map"], Abstraction(Apply(every_primitive["range"], Hole(tint, nothing, true)))),
            Hole(tlist(tint), nothing, true),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(every_primitive["map"], Abstraction(Apply(every_primitive["range"], Index(0)))),
            FreeVar(tlist(tint), nothing),
        )
        @test rev_p([[0, 1, 2], [0, 1], [0, 1, 2, 3]]) == [[2, 1, 3]]
    end

    @testset "Reverse map2 with either options" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["map2"],
                    Abstraction(
                        Abstraction(
                            Apply(
                                Apply(every_primitive["concat"], Hole(tlist(tint), nothing, true)),
                                Hole(tlist(tint), nothing, true),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(tlist(tint)), nothing, true),
            ),
            Hole(tlist(tlist(tint)), nothing, true),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(
                Apply(
                    every_primitive["map2"],
                    Abstraction(Abstraction(Apply(Apply(every_primitive["concat"], Index(0)), Index(1)))),
                ),
                FreeVar(tlist(tlist(tint)), nothing),
            ),
            FreeVar(tlist(tlist(tint)), nothing),
        )
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
        skeleton = Apply(every_primitive["rows"], Hole(tgrid(tcolor), nothing, true))
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(every_primitive["rows"], FreeVar(tgrid(tcolor), nothing))
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
                    Abstraction(Apply(Apply(every_primitive["eq?"], Index(0)), Hole(tint, nothing, false))),
                ),
                Hole(tlist(tint), nothing, true),
            ),
            Hole(tlist(tint), nothing, true),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(
                Apply(
                    every_primitive["rev_select"],
                    Abstraction(Apply(Apply(every_primitive["eq?"], Index(0)), FreeVar(tint, nothing))),
                ),
                FreeVar(tlist(tint), nothing),
            ),
            FreeVar(tlist(tint), nothing),
        )
        rev_res = rev_p([1, 2, 1, 3, 2, 1])
        expected = Dict(
            1 => [1, [1, nothing, 1, nothing, nothing, 1], [nothing, 2, nothing, 3, 2, nothing]],
            2 => [2, [nothing, 2, nothing, nothing, 2, nothing], [1, nothing, 1, 3, nothing, 1]],
            3 => [3, [nothing, nothing, nothing, 3, nothing, nothing], [1, 2, 1, nothing, 2, 1]],
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
                Hole(tlist(tlist(tint)), nothing, true),
            ),
            Hole(tlist(tlist(tint)), nothing, true),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(
                Apply(every_primitive["rev_select"], Abstraction(Apply(every_primitive["empty?"], Index(0)))),
                FreeVar(tlist(tlist(tint)), nothing),
            ),
            FreeVar(tlist(tlist(tint)), nothing),
        )
        @test rev_p([[0, 1, 2], [], [0, 1, 2, 3]]) == [[nothing, [], nothing], [[0, 1, 2], nothing, [0, 1, 2, 3]]]
    end

    @testset "Invented abstractor" begin
        source = "#(lambda (lambda (repeat (cons \$1 \$0))))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = Apply(
            Apply(Apply(expression, Hole(t0, nothing, true)), Hole(tlist(t0), nothing, true)),
            Hole(tint, nothing, true),
        )
        @test is_reversible(skeleton)
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p ==
              Apply(Apply(Apply(expression, FreeVar(t0, nothing)), FreeVar(tlist(t0), nothing)), FreeVar(tint, nothing))
        @test rev_p([[1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3]]) == [1, [2, 3], 4]
    end

    @testset "Invented abstractor with range" begin
        source = "#(lambda (repeat (range \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = Apply(Apply(expression, Hole(tint, nothing, true)), Hole(tint, nothing, true))
        @test is_reversible(skeleton)
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(Apply(expression, FreeVar(tint, nothing)), FreeVar(tint, nothing))
        @test rev_p([[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]]) == [3, 4]
    end

    @testset "Invented abstractor with range in map2" begin
        source = "#(lambda (repeat (range \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["map2"],
                    Abstraction(
                        Abstraction(Apply(Apply(expression, Hole(tint, nothing, true)), Hole(tint, nothing, true))),
                    ),
                ),
                Hole(tlist(tint), nothing, true),
            ),
            Hole(tlist(tint), nothing, true),
        )
        @test is_reversible(skeleton)
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(
                Apply(every_primitive["map2"], Abstraction(Abstraction(Apply(Apply(expression, Index(0)), Index(1))))),
                FreeVar(tlist(tint), nothing),
            ),
            FreeVar(tlist(tint), nothing),
        )
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
                                Abstraction(Apply(Apply(every_primitive["eq?"], Index(0)), Hole(t1, nothing, false))),
                            ),
                            Hole(tlist(tcolor), nothing, true),
                        ),
                        Hole(tlist(tcolor), nothing, true),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, true),
        )

        @test !is_reversible(skeleton)
        @test_throws ArgumentError get_reversed_filled_program(skeleton)
    end
end

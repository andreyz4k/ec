
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
    ttuple2,
    Index,
    SetConst,
    EitherOptions,
    get_reversed_filled_program,
    is_reversible,
    parse_program,
    closed_inference
using DataStructures: OrderedDict, Accumulator
import Redis

@testset "Abstractors" begin
    @testset "Check reversible simple" begin
        @test is_reversible(Apply(Apply(every_primitive["repeat"], Hole(tint, nothing)), Hole(tint, nothing)))
    end

    @testset "Check reversible map" begin
        @test is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(Apply(Apply(every_primitive["repeat"], Hole(tint, nothing)), Hole(tint, nothing))),
                ),
                Hole(tlist(ttuple2(tint, tint)), nothing),
            ),
        )
    end

    @testset "Check reversible nested map" begin
        @test is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(
                                every_primitive["map"],
                                Abstraction(
                                    Apply(Apply(every_primitive["repeat"], Hole(tint, nothing)), Hole(tint, nothing)),
                                ),
                            ),
                            Hole(tlist(tlist(tint)), nothing),
                        ),
                    ),
                ),
                Hole(tlist(ttuple2(tlist(tint), tlist(tint))), nothing),
            ),
        )
    end

    @testset "Check reversible select" begin
        @test is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(Apply(Apply(every_primitive["eq?"], Index(0)), Hole(tint, nothing))),
                    ),
                    Hole(tlist(tint), nothing),
                ),
                Hole(tlist(tint), nothing),
            ),
        )
        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(Apply(Apply(every_primitive["eq?"], Hole(tint, nothing)), Hole(tint, nothing))),
                    ),
                    Hole(tlist(tint), nothing),
                ),
                Hole(tlist(tint), nothing),
            ),
        )
        @test is_reversible(
            Apply(
                Apply(
                    Apply(every_primitive["rev_select"], Abstraction(Apply(every_primitive["empty?"], Index(0)))),
                    Hole(tlist(tint), nothing),
                ),
                Hole(tlist(tint), nothing),
            ),
        )
        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(Apply(every_primitive["empty?"], Hole(tint, nothing))),
                    ),
                    Hole(tlist(tint), nothing),
                ),
                Hole(tlist(tint), nothing),
            ),
        )
    end

    @testset "Reverse repeat" begin
        skeleton = Apply(Apply(every_primitive["repeat"], Hole(tint, nothing)), Hole(tint, nothing))
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(Apply(every_primitive["repeat"], FreeVar(tint, nothing)), FreeVar(tint, nothing))
        @test rev_p([[1, 2, 3], [1, 2, 3]]) == [[1, 2, 3], 2]
        @test rev_p([1, 1, 1]) == [1, 3]
    end

    @testset "Reverse cons" begin
        skeleton = Apply(Apply(every_primitive["cons"], Hole(tint, nothing)), Hole(tint, nothing))
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(Apply(every_primitive["cons"], FreeVar(tint, nothing)), FreeVar(tint, nothing))
        @test rev_p([1, 2, 3]) == [1, [2, 3]]
    end

    @testset "Reverse combined abstractors" begin
        skeleton = Apply(
            Apply(every_primitive["cons"], Hole(tint, nothing)),
            Apply(Apply(every_primitive["repeat"], Hole(tint, nothing)), Hole(tint, nothing)),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(every_primitive["cons"], FreeVar(tint, nothing)),
            Apply(Apply(every_primitive["repeat"], FreeVar(tint, nothing)), FreeVar(tint, nothing)),
        )
        @test rev_p([1, 2, 2, 2]) == [1, 2, 3]
    end

    @testset "Reverse map" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(Apply(every_primitive["repeat"], Hole(tint, nothing)), Hole(tint, nothing))),
            ),
            Hole(tlist(ttuple2(tint, tint)), nothing),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(every_primitive["repeat"], Apply(every_primitive["tuple2_first"], Index(0))),
                        Apply(every_primitive["tuple2_second"], Index(0)),
                    ),
                ),
            ),
            Apply(Apply(every_primitive["zip2"], FreeVar(tlist(tint), nothing)), FreeVar(tlist(tint), nothing)),
        )
        @test rev_p([[1, 1, 1], [2, 2], [4]]) == [[1, 2, 4], [3, 2, 1]]
    end

    @testset "Reverse nested map" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(
                            every_primitive["map"],
                            Abstraction(
                                Apply(Apply(every_primitive["repeat"], Hole(tint, nothing)), Hole(tint, nothing)),
                            ),
                        ),
                        Hole(tlist(tlist(tint)), nothing),
                    ),
                ),
            ),
            Hole(tlist(ttuple2(tlist(tint), tlist(tint))), nothing),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(
                            every_primitive["map"],
                            Abstraction(
                                Apply(
                                    Apply(every_primitive["repeat"], Apply(every_primitive["tuple2_first"], Index(0))),
                                    Apply(every_primitive["tuple2_second"], Index(0)),
                                ),
                            ),
                        ),
                        Apply(
                            Apply(every_primitive["zip2"], Apply(every_primitive["tuple2_first"], Index(0))),
                            Apply(every_primitive["tuple2_second"], Index(0)),
                        ),
                    ),
                ),
            ),
            Apply(
                Apply(every_primitive["zip2"], FreeVar(tlist(tlist(tint)), nothing)),
                FreeVar(tlist(tlist(tint)), nothing),
            ),
        )
        @test rev_p([[[1, 1, 1], [2, 2], [4]], [[3, 3, 3, 3], [2, 2, 2], [8, 8, 8]]]) ==
              [[[1, 2, 4], [3, 2, 8]], [[3, 2, 1], [4, 3, 3]]]
    end

    @testset "Reverse range" begin
        skeleton = Apply(every_primitive["range"], Hole(tint, nothing))
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(every_primitive["range"], FreeVar(tint, nothing))
        @test rev_p([0, 1, 2]) == [2]
        @test rev_p([]) == [-1]
    end

    @testset "Reverse map with range" begin
        skeleton = Apply(
            Apply(every_primitive["map"], Abstraction(Apply(every_primitive["range"], Hole(tint, nothing)))),
            Hole(tlist(tint), nothing),
        )
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(every_primitive["map"], Abstraction(Apply(every_primitive["range"], Index(0)))),
            FreeVar(tlist(tint), nothing),
        )
        @test rev_p([[0, 1, 2], [0, 1], [0, 1, 2, 3]]) == [[2, 1, 3]]
    end

    @testset "Reverse rev select" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["rev_select"],
                    Abstraction(Apply(Apply(every_primitive["eq?"], Index(0)), Hole(tint, nothing))),
                ),
                Hole(tlist(tint), nothing),
            ),
            Hole(tlist(tint), nothing),
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
                Hole(tlist(tlist(tint)), nothing),
            ),
            Hole(tlist(tlist(tint)), nothing),
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
        skeleton = Apply(Apply(Apply(expression, Hole(t0, nothing)), Hole(tlist(t0), nothing)), Hole(tint, nothing))
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
        skeleton = Apply(Apply(expression, Hole(tint, nothing)), Hole(tint, nothing))
        @test is_reversible(skeleton)
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(Apply(expression, FreeVar(tint, nothing)), FreeVar(tint, nothing))
        @test rev_p([[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]]) == [3, 4]
    end

    @testset "Invented abstractor with range in map" begin
        source = "#(lambda (repeat (range \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(Apply(expression, Hole(tint, nothing)), Hole(tint, nothing))),
            ),
            Hole(tlist(ttuple2(tint, tint)), nothing),
        )
        @test is_reversible(skeleton)
        filled_p, rev_p = get_reversed_filled_program(skeleton)
        @test filled_p == Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(expression, Apply(every_primitive["tuple2_first"], Index(0))),
                        Apply(every_primitive["tuple2_second"], Index(0)),
                    ),
                ),
            ),
            Apply(Apply(every_primitive["zip2"], FreeVar(tlist(tint), nothing)), FreeVar(tlist(tint), nothing)),
        )
        @test rev_p([[[0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3], [0, 1, 2, 3]], [[0, 1, 2], [0, 1, 2]]]) ==
              [[3, 2], [4, 2]]
    end
end

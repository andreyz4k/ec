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
    is_reversible_selector,
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
    all_abstractors,
    TooManyOptionsException,
    CombinedArgChecker,
    SimpleArgChecker,
    step_arg_checker,
    ArgTurn
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

    function capture_free_vars(p::Hole, max_var = UInt64(0))
        var_id = max_var + 1
        FreeVar(t0, var_id, nothing), max_var + 1
    end

    function capture_free_vars(p::FreeVar, max_var = UInt64(0))
        if isnothing(p.var_id)
            var_id = max_var + 1
            FreeVar(t0, var_id, p.location), max_var + 1
        else
            p, max_var
        end
    end

    @testcase_log "Check reversible simple" begin
        @test is_reversible(parse_program("(repeat ??(int) ??(int))"))
    end

    @testcase_log "Check reversible map" begin
        @test !is_reversible(
            Apply(
                Apply(
                    every_primitive["map"],
                    Abstraction(
                        Apply(
                            Apply(
                                every_primitive["repeat"],
                                Hole(tint, nothing, [], all_abstractors[every_primitive["map"]][1][1][2], nothing),
                            ),
                            Hole(tint, nothing, [], all_abstractors[every_primitive["map"]][1][1][2], nothing),
                        ),
                    ),
                ),
                Hole(tlist(ttuple2(tint, tint)), nothing, [], nothing, nothing),
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
                                        Hole(
                                            tint,
                                            nothing,
                                            [],
                                            all_abstractors[every_primitive["map2"]][1][1][2],
                                            nothing,
                                        ),
                                    ),
                                    Hole(tint, nothing, [], all_abstractors[every_primitive["map2"]][1][1][2], nothing),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, [], nothing, nothing),
                ),
                Hole(tlist(tint), nothing, [], nothing, nothing),
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
                            Hole(tlist(tbool), nothing, [], all_abstractors[every_primitive["map"]][1][1][2], nothing),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, [], nothing, nothing),
            ),
        )
        @test !_is_reversible_subfunction(
            Abstraction(
                Apply(
                    Apply(every_primitive["cons"], Index(0)),
                    Hole(tlist(tbool), nothing, [], all_abstractors[every_primitive["map2"]][1][1][2], nothing),
                ),
            ),
        )
    end

    @testcase_log "Check reversible nested map" begin
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
                                                            Hole(
                                                                tint,
                                                                nothing,
                                                                [],
                                                                all_abstractors[every_primitive["map2"]][1][1][2],
                                                                nothing,
                                                            ),
                                                        ),
                                                        Hole(
                                                            tint,
                                                            nothing,
                                                            [],
                                                            all_abstractors[every_primitive["map2"]][1][1][2],
                                                            nothing,
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ),
                                        Hole(
                                            tlist(tint),
                                            nothing,
                                            [],
                                            all_abstractors[every_primitive["map2"]][1][1][2],
                                            nothing,
                                        ),
                                    ),
                                    Hole(
                                        tlist(tint),
                                        nothing,
                                        [],
                                        all_abstractors[every_primitive["map2"]][1][1][2],
                                        nothing,
                                    ),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tlist(tint)), nothing, [], nothing, nothing),
                ),
                Hole(tlist(tlist(tint)), nothing, [], nothing, nothing),
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
                                        Hole(
                                            tlist(tint),
                                            nothing,
                                            [],
                                            all_abstractors[every_primitive["map2"]][1][1][2],
                                            nothing,
                                        ),
                                    ),
                                    Hole(
                                        tlist(tint),
                                        nothing,
                                        [],
                                        all_abstractors[every_primitive["map2"]][1][1][2],
                                        nothing,
                                    ),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tlist(tint)), nothing, [], nothing, nothing),
                ),
                Hole(tlist(tlist(tint)), nothing, [], nothing, nothing),
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
                                            Hole(
                                                tint,
                                                nothing,
                                                [],
                                                all_abstractors[every_primitive["map2"]][1][1][2],
                                                nothing,
                                            ),
                                        ),
                                        Hole(
                                            tint,
                                            nothing,
                                            [],
                                            all_abstractors[every_primitive["map2"]][1][1][2],
                                            nothing,
                                        ),
                                    ),
                                ),
                            ),
                            Hole(
                                tlist(tlist(tint)),
                                nothing,
                                [],
                                all_abstractors[every_primitive["map2"]][1][1][2],
                                nothing,
                            ),
                        ),
                    ),
                ),
                Hole(tlist(ttuple2(tlist(tint), tlist(tint))), nothing, [], nothing, nothing),
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
                            Hole(tlist(tint), nothing, [], all_abstractors[every_primitive["map2"]][1][1][2], nothing),
                        ),
                    ),
                ),
                Hole(tlist(tlist(tint)), nothing, [], nothing, nothing),
            ),
        )
        @test is_reversible(parse_program("(map (lambda (map (lambda (repeat \$0 \$0)) \$0)) ??(list(list(int))))"))
    end

    @testcase_log "Check reversible select" begin
        @test is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(
                            Apply(
                                Apply(every_primitive["eq?"], Index(0)),
                                Hole(
                                    tint,
                                    nothing,
                                    [],
                                    all_abstractors[every_primitive["rev_select"]][1][1][2],
                                    nothing,
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, [], nothing, nothing),
                ),
                Hole(tlist(tint), nothing, [], nothing, nothing),
            ),
        )
        @test is_reversible_selector(
            Abstraction(
                Apply(
                    Apply(every_primitive["eq?"], Index(0)),
                    Hole(tint, nothing, [], all_abstractors[every_primitive["rev_select"]][1][1][2], nothing),
                ),
            ),
        )

        @test !is_reversible(
            Apply(
                Apply(
                    Apply(
                        every_primitive["rev_select"],
                        Abstraction(
                            Apply(
                                Apply(
                                    every_primitive["eq?"],
                                    Hole(
                                        tint,
                                        nothing,
                                        [],
                                        all_abstractors[every_primitive["rev_select"]][1][1][2],
                                        nothing,
                                    ),
                                ),
                                Hole(
                                    tint,
                                    nothing,
                                    [],
                                    all_abstractors[every_primitive["rev_select"]][1][1][2],
                                    nothing,
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, [], nothing, nothing),
                ),
                Hole(tlist(tint), nothing, [], nothing, nothing),
            ),
        )
        @test !is_reversible_selector(
            Abstraction(
                Apply(
                    Apply(
                        every_primitive["eq?"],
                        Hole(tint, nothing, [], all_abstractors[every_primitive["rev_select"]][1][1][2], nothing),
                    ),
                    Hole(tint, nothing, [], all_abstractors[every_primitive["rev_select"]][1][1][2], nothing),
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
                            Apply(
                                every_primitive["empty?"],
                                Hole(
                                    tint,
                                    nothing,
                                    [],
                                    all_abstractors[every_primitive["rev_select"]][1][1][2],
                                    nothing,
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(tint), nothing, [], nothing, nothing),
                ),
                Hole(tlist(tint), nothing, [], nothing, nothing),
            ),
        )
    end

    @testcase_log "Reverse repeat" begin
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

    @testcase_log "Reverse repeat grid" begin
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
            run_in_reverse(p, PatternWrapper([[1, any_object, 1] [1, any_object, any_object]])),
            Dict(UInt64(1) => 1, UInt64(2) => 3, UInt64(3) => 2),
        )
        @test compare_options(
            run_in_reverse(p, PatternWrapper([[any_object, any_object, 1] [any_object, any_object, any_object]])),
            Dict(UInt64(1) => 1, UInt64(2) => 3, UInt64(3) => 2),
        )
        @test run_in_reverse(p, PatternWrapper([[any_object, any_object, 1] [any_object, any_object, any_object]]))[1] !==
              any_object
    end

    @testcase_log "Reverse cons" begin
        skeleton = parse_program("(cons ??(int) ??(list(int)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(run_in_reverse(p, [1, 2, 3]), Dict(UInt64(1) => 1, UInt64(2) => [2, 3]))
    end

    @testcase_log "Reverse adjoin" begin
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

    @testcase_log "Reverse tuple2" begin
        skeleton = parse_program("(tuple2 ??(color) ??(list(int)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(run_in_reverse(p, (1, [2, 3])), Dict(UInt64(1) => 1, UInt64(2) => [2, 3]))
    end

    @testcase_log "Reverse plus" begin
        skeleton = parse_program("(+ ??(int) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000001 => AbductibleValue(any_object)),
        )
        @test compare_options(
            run_in_reverse(p, 15),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000001 => AbductibleValue(any_object)),
        )
        @test compare_options(
            run_in_reverse(p, -5),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000001 => AbductibleValue(any_object)),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), 3) == Dict(UInt64(2) => 2)
        @test calculate_dependent_vars(
            p,
            Dict{UInt64,Any}(UInt64(1) => 1),
            EitherOptions(Dict{UInt64,Any}(0xaa2dcc33efe7cdcd => 30, 0x4ef19a9b1c1cc5e2 => 15)),
        ) == Dict(UInt64(2) => EitherOptions(Dict{UInt64,Any}(0xaa2dcc33efe7cdcd => 29, 0x4ef19a9b1c1cc5e2 => 14)))
    end

    @testcase_log "Reverse minus" begin
        skeleton = parse_program("(- ??(int) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000001 => AbductibleValue(any_object)),
        )
        @test compare_options(
            run_in_reverse(p, 15),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000001 => AbductibleValue(any_object)),
        )
        @test compare_options(
            run_in_reverse(p, -5),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000001 => AbductibleValue(any_object)),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), 3) == Dict(UInt64(2) => -2)
        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => 1), 3) == Dict(UInt64(1) => 4)
        @test calculate_dependent_vars(
            p,
            Dict{UInt64,Any}(UInt64(2) => 1),
            EitherOptions(Dict{UInt64,Any}(0xaa2dcc33efe7cdcd => 30, 0x4ef19a9b1c1cc5e2 => 15)),
        ) == Dict(UInt64(1) => EitherOptions(Dict{UInt64,Any}(0xaa2dcc33efe7cdcd => 31, 0x4ef19a9b1c1cc5e2 => 16)))
    end

    @testcase_log "Reverse plus with plus" begin
        skeleton = parse_program("(+ (+ ??(int) ??(int)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(
                0x0000000000000002 => AbductibleValue(any_object),
                0x0000000000000003 => AbductibleValue(any_object),
                0x0000000000000001 => AbductibleValue(any_object),
            ),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), 3),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000003 => AbductibleValue(any_object)),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1, UInt64(2) => 5), 3) == Dict(UInt64(3) => -3)
        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1, UInt64(3) => 5), 3) == Dict(UInt64(2) => -3)
    end

    @testcase_log "Reverse repeat with plus" begin
        skeleton = parse_program("(repeat (+ ??(int) ??(int)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, [3, 3, 3, 3]),
            Dict(
                0x0000000000000002 => AbductibleValue(any_object),
                0x0000000000000003 => 4,
                0x0000000000000001 => AbductibleValue(any_object),
            ),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1, UInt64(3) => 4), [3, 3, 3, 3]) ==
              Dict(UInt64(2) => 2)
    end

    @testcase_log "Reverse abs with plus" begin
        skeleton = parse_program("(abs (+ ??(int) ??(int)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000001 => AbductibleValue(any_object)),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), 3),
            Dict(UInt64(2) => EitherOptions(Dict{UInt64,Any}(0xc8e6a6dedcb6f132 => -4, 0x9fede9511319ae42 => 2))),
        )
    end

    @testcase_log "Reverse plus with abs" begin
        skeleton = parse_program("(+ (abs ??(int)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)
        @test compare_options(
            run_in_reverse(p, 3),
            Dict(0x0000000000000002 => AbductibleValue(any_object), 0x0000000000000001 => AbductibleValue(any_object)),
        )

        @test compare_options(
            calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => 1), 3),
            Dict(UInt64(1) => EitherOptions(Dict{UInt64,Any}(0xc8e6a6dedcb6f132 => -2, 0x9fede9511319ae42 => 2))),
        )
    end

    @testcase_log "Reverse mult" begin
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

    @testcase_log "Reverse combined abstractors" begin
        skeleton = parse_program("(repeat (cons ??(int) ??(list(int))) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [[1, 2], [1, 2], [1, 2]]),
            Dict(UInt64(1) => 1, UInt64(2) => [2], UInt64(3) => 3),
        )
    end

    @testset "Reverse map2" begin
        @testcase_log "with holes" begin
            skeleton = Apply(
                Apply(
                    Apply(
                        every_primitive["map2"],
                        Abstraction(
                            Abstraction(
                                Apply(
                                    Apply(
                                        every_primitive["repeat"],
                                        Hole(
                                            tint,
                                            nothing,
                                            [],
                                            all_abstractors[every_primitive["map2"]][1][1][2],
                                            nothing,
                                        ),
                                    ),
                                    Hole(tint, nothing, [], all_abstractors[every_primitive["map2"]][1][1][2], nothing),
                                ),
                            ),
                        ),
                    ),
                    Hole(tlist(t0), nothing, [], nothing, nothing),
                ),
                Hole(tlist(t1), nothing, [], nothing, nothing),
            )
            @test !is_reversible(skeleton)
        end

        @testcase_log "repeat indices 1 0" begin
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

        @testcase_log "repeat indices 0 1" begin
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

        @testcase_log "cons indices 1 0" begin
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

        @testcase_log "cons indices 0 1" begin
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

    @testcase_log "Reverse nested map2" begin
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

    @testcase_log "Reverse range" begin
        skeleton = parse_program("(range ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, [0, 1, 2]), Dict(UInt64(1) => 3))
        @test compare_options(run_in_reverse(p, []), Dict(UInt64(1) => 0))
    end

    @testcase_log "Reverse map with range" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        every_primitive["range"],
                        Hole(tint, nothing, [], all_abstractors[every_primitive["map"]][1][1][2], nothing),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, [], nothing, nothing),
        )
        @test !is_reversible(skeleton)

        skeleton = parse_program("(map (lambda (range \$0)) ??(list(t0)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, [[0, 1, 2], [0, 1], [0, 1, 2, 3]]), Dict(UInt64(1) => [3, 2, 4]))
    end

    @testcase_log "Reverse map set with range" begin
        skeleton = Apply(
            Apply(
                every_primitive["map_set"],
                Abstraction(
                    Apply(
                        every_primitive["range"],
                        Hole(tint, nothing, [], all_abstractors[every_primitive["map_set"]][1][1][2], nothing),
                    ),
                ),
            ),
            Hole(tset(t0), nothing, [], nothing, nothing),
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

    @testcase_log "Reverse map with repeat" begin
        skeleton = parse_program("(map (lambda (repeat \$0 \$0)) ??(list(t0)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, [[1], [2, 2], [4, 4, 4, 4]]), Dict(UInt64(1) => [1, 2, 4]))
        @test_throws ErrorException run_in_reverse(p, [[1, 1], [2, 2], [4, 4, 4, 4]])

        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 2, 4])) == [[1], [2, 2], [4, 4, 4, 4]]
    end

    @testcase_log "Reverse map set with tuple" begin
        skeleton = Apply(
            Apply(
                every_primitive["map_set"],
                Abstraction(Apply(Apply(every_primitive["tuple2"], Index(0)), FreeVar(tint, nothing, nothing))),
            ),
            Hole(tset(t0), nothing, [], nothing, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Set([(3, 2), (1, 2), (6, 2)])),
            Dict(UInt64(1) => 2, UInt64(2) => Set([3, 1, 6])),
        )
        @test_throws ErrorException run_in_reverse(p, Set([(3, 2), (1, 2), (6, 3)]))

        @test run_with_arguments(p, [], Dict(UInt64(1) => 2, UInt64(2) => Set([3, 1, 6]))) ==
              Set([(3, 2), (1, 2), (6, 2)])

        @test compare_options(
            calculate_dependent_vars(p, Dict(UInt64(2) => Set([3, 1, 6])), Set([(3, 2), (1, 2), (6, 2)])),
            Dict(UInt64(1) => 2),
        )
    end

    @testcase_log "Reverse map2 with either options" begin
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

    @testcase_log "Reverse map with either options" begin
        skeleton = parse_program("(map (lambda (concat \$0 \$0)) ??(list(t0)))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, Vector{Any}[[1, 2, 1, 2], [0, 0, 0, 0], [3, 0, 1, 3, 0, 1]]),
            Dict(UInt64(1) => [[1, 2], [0, 0], [3, 0, 1]]),
        )
    end

    @testcase_log "Reverse map with either options with free var" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(Apply(every_primitive["concat"], Index(0)), FreeVar(tlist(tint), nothing, nothing))),
            ),
            Hole(tlist(t0), nothing, [], nothing, nothing),
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

    @testcase_log "Reverse map with either options with free var and plus" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(Apply(every_primitive["+"], FreeVar(tint, nothing, nothing)), Index(0))),
            ),
            Hole(tlist(t0), nothing, [], nothing, nothing),
        )
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [12, 0, 36, 2]),
            Dict(
                0x0000000000000002 => AbductibleValue([any_object, any_object, any_object, any_object]),
                0x0000000000000001 => AbductibleValue(any_object),
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

    @testcase_log "Reverse map with either options with free var with plus and mult" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(every_primitive["*"], Index(0)),
                        Apply(
                            Apply(every_primitive["*"], Index(0)),
                            Apply(Apply(every_primitive["+"], FreeVar(tint, nothing, nothing)), Index(0)),
                        ),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, [], nothing, nothing),
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

    @testcase_log "Reverse map with either options with free var with plus and mult 2" begin
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
                                Apply(Apply(every_primitive["+"], FreeVar(tint, nothing, nothing)), Index(0)),
                            ),
                            FreeVar(tint, nothing, nothing),
                        ),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, [], nothing, nothing),
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

    @testcase_log "Reverse map with either options with free var with plus and mult 3" begin
        # (map (lambda (* $0 (+ $v154 $0))) $v155)
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(
                    Apply(
                        Apply(every_primitive["*"], Index(0)),
                        Apply(Apply(every_primitive["+"], FreeVar(tint, nothing, nothing)), Index(0)),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, [], nothing, nothing),
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

    @testcase_log "Reverse map with either options with free var with plus and mult 4" begin
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

    @testcase_log "Reverse map with either options with free var with plus and mult 5" begin
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
                                Apply(Apply(every_primitive["+"], FreeVar(tint, nothing, nothing)), Index(0)),
                            ),
                            FreeVar(tint, nothing, nothing),
                        ),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, [], nothing, nothing),
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

    @testcase_log "Reverse map2 with plus" begin
        skeleton = parse_program("(map2 (lambda (lambda (+ \$0 \$1))) ??(list(t0)) ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [3, 2]),
            Dict(
                0x0000000000000002 => AbductibleValue([any_object, any_object]),
                0x0000000000000001 => AbductibleValue([any_object, any_object]),
            ),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => [1, 2]), [3, 2]) == Dict(UInt64(2) => [2, 0])
    end

    @testcase_log "Reverse map with plus and free var" begin
        skeleton = Apply(
            Apply(
                every_primitive["map"],
                Abstraction(Apply(Apply(every_primitive["+"], FreeVar(tint, nothing, nothing)), Index(0))),
            ),
            Hole(tlist(tint), nothing, [], nothing, nothing),
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [3, 2]),
            Dict(
                0x0000000000000002 => AbductibleValue([any_object, any_object]),
                0x0000000000000001 => AbductibleValue(any_object),
            ),
        )

        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(2) => [2, 1]), [3, 2]) == Dict(UInt64(1) => 1)
        @test calculate_dependent_vars(p, Dict{UInt64,Any}(UInt64(1) => 1), [3, 2]) == Dict(UInt64(2) => [2, 1])
    end

    @testcase_log "Reverse rows with either" begin
        skeleton = Apply(every_primitive["rows"], Hole(tgrid(tcolor), nothing, [], nothing, nothing))
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

    @testcase_log "Reverse rev select" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["rev_select"],
                    Abstraction(
                        Apply(
                            Apply(every_primitive["eq?"], Index(0)),
                            Hole(t0, nothing, [], all_abstractors[every_primitive["rev_select"]][1][1][2], nothing),
                        ),
                    ),
                ),
                Hole(tlist(tcolor), nothing, [], nothing, nothing),
            ),
            Hole(tlist(tcolor), nothing, [], nothing, nothing),
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

    @testcase_log "Reverse rev select set" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["rev_select_set"],
                    Abstraction(
                        Apply(
                            Apply(every_primitive["eq?"], Index(0)),
                            Hole(t0, nothing, [], all_abstractors[every_primitive["rev_select_set"]][1][1][2], nothing),
                        ),
                    ),
                ),
                Hole(tset(tcolor), nothing, [], nothing, nothing),
            ),
            Hole(tset(tcolor), nothing, [], nothing, nothing),
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

    @testcase_log "Reverse rev select with empty" begin
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

    @testcase_log "Invented abstractor" begin
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

    @testcase_log "Invented abstractor with same index" begin
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

    @testcase_log "Invented abstractor with same index combined" begin
        source = "#(lambda (* \$0 (* \$0 \$0)))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = parse_program("(#(lambda (* \$0 (* \$0 \$0))) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, 64), Dict(UInt64(1) => 4))
    end

    @testcase_log "Invented abstractor with same index combined #2" begin
        source = "#(lambda (* (* \$0 \$0) \$0))"
        expression = parse_program(source)
        tp = closed_inference(expression)
        @test is_reversible(expression)
        skeleton = parse_program("(#(lambda (* (* \$0 \$0) \$0)) ??(int))")
        @test is_reversible(skeleton)
        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, 64), Dict(UInt64(1) => 4))
    end

    @testcase_log "Invented abstractor with same index combined #3" begin
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

    @testcase_log "Invented abstractor with range" begin
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

    @testcase_log "Invented abstractor with range in map2" begin
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

    @testcase_log "Reversed map with rev_select" begin
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
                                        Hole(
                                            t1,
                                            nothing,
                                            [],
                                            step_arg_checker(
                                                step_arg_checker(
                                                    CombinedArgChecker([
                                                        SimpleArgChecker(false, -1, true),
                                                        all_abstractors[every_primitive["map"]][1][1][2],
                                                        all_abstractors[every_primitive["rev_select"]][1][1][2],
                                                    ]),
                                                    ArgTurn(tcolor),
                                                ),
                                                (every_primitive["eq?"], 2),
                                            ),
                                            nothing,
                                        ),
                                    ),
                                ),
                            ),
                            Hole(tlist(tcolor), nothing, [], all_abstractors[every_primitive["map"]][1][1][2], nothing),
                        ),
                        Hole(tlist(tcolor), nothing, [], all_abstractors[every_primitive["map"]][1][1][2], nothing),
                    ),
                ),
            ),
            Hole(tlist(t0), nothing, [], nothing, nothing),
        )

        @test !is_reversible(skeleton)
    end

    @testcase_log "Reverse list elements" begin
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

    @testcase_log "Reverse grid elements" begin
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

    @testcase_log "Reverse zip2" begin
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

    @testcase_log "Reverse zip_grid2" begin
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

    @testcase_log "Reverse rev_fold" begin
        skeleton = parse_program("(rev_fold (lambda (lambda (cons \$1 \$0))) empty ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(run_in_reverse(p, [2, 4, 1, 4, 1]), Dict(UInt64(1) => [1, 4, 1, 4, 2]))

        @test run_with_arguments(p, [], Dict(UInt64(1) => [1, 4, 1, 4, 2])) == [2, 4, 1, 4, 1]
    end

    @testcase_log "Reverse fold" begin
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

    @testcase_log "Reverse fold with plus" begin
        skeleton = parse_program("(fold (lambda (lambda (+ \$0 \$1))) ??(list(t0)) ??(int))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, 1),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x885704307b580177 => AbductibleValue(any_object),
                        0x4601bc5ea0f07048 => 1,
                        0x006ce5b829e80cf6 => AbductibleValue(any_object),
                    ),
                ),
                0x0000000000000001 => EitherOptions(
                    Dict{UInt64,Any}(
                        0x885704307b580177 => AbductibleValue(any_object),
                        0x4601bc5ea0f07048 => Any[],
                        0x006ce5b829e80cf6 => AbductibleValue([any_object]),
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
                        0x7912c2fba0076269 => Any[2],
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
                        0x217ec347af1e7eb0 => Any[],
                        0x286dedbc8cc5c5e2 => Any[0, 0],
                        0x5fec1c510fbe81ac => Any[0],
                    ),
                ),
            ),
        )
    end

    @testcase_log "Reverse fold with free var" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(
                        Abstraction(
                            Apply(
                                Apply(
                                    every_primitive["cons"],
                                    Apply(Apply(every_primitive["*"], Index(1)), FreeVar(tint, nothing, nothing)),
                                ),
                                Index(0),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, [], nothing, nothing),
            ),
            Hole(tint, nothing, [], nothing, nothing),
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

    @testcase_log "Reverse fold with free var with plus and mult" begin
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
                                        Apply(Apply(every_primitive["+"], Index(1)), FreeVar(tint, nothing, nothing)),
                                    ),
                                ),
                                Index(0),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, [], nothing, nothing),
            ),
            Hole(tint, nothing, [], nothing, nothing),
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

    @testcase_log "Reverse fold with free var with plus" begin
        skeleton = Apply(
            Apply(
                Apply(
                    every_primitive["fold"],
                    Abstraction(
                        Abstraction(
                            Apply(
                                Apply(
                                    every_primitive["cons"],
                                    Apply(Apply(every_primitive["+"], Index(1)), FreeVar(tint, nothing, nothing)),
                                ),
                                Index(0),
                            ),
                        ),
                    ),
                ),
                Hole(tlist(t0), nothing, [], nothing, nothing),
            ),
            Hole(tlist(tint), nothing, [], nothing, nothing),
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options(
            run_in_reverse(p, [2, 6, 12]),
            Dict(
                0x0000000000000002 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xbd03eea21edc0245 => AbductibleValue([any_object, any_object]),
                        0x8666ee0fa727dc64 => AbductibleValue([any_object, any_object, any_object]),
                        0xc21725c4204c919f => AbductibleValue([any_object]),
                    ),
                ),
                0x0000000000000003 => EitherOptions(
                    Dict{UInt64,Any}(
                        0xbd03eea21edc0245 => Any[12],
                        0x8666ee0fa727dc64 => Any[],
                        0xc21725c4204c919f => Any[6, 12],
                    ),
                ),
                0x0000000000000001 => AbductibleValue(any_object),
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
                0x0000000000000002 => AbductibleValue([any_object, any_object]),
                0x0000000000000001 => AbductibleValue(any_object),
            ),
        )
    end

    @testcase_log "Reverse fold_set" begin
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

    @testcase_log "Reverse fold with concat" begin
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
                        0xe0df273cf6144158 => Any[4, 1],
                        0xa733db04fb278acd => Any[4, 1],
                        0x9e49a006a4448bed => Any[],
                        0x6fc1f7b37668f35d => Any[],
                        0x1cc3a1d65866a81c => Any[1, 4, 1],
                        0xdfa148e61e3478b1 => Any[1, 4, 1],
                        0xe7036a7826b8dba7 => Any[4, 1, 4, 1],
                        0xf1d8525f68b94da2 => Any[4, 1],
                        0xc28379809fd920dc => Any[1],
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
                        0xe0df273cf6144158 => Any[Any[2], Any[], Any[4, 1]],
                        0xa733db04fb278acd => Any[Any[2, 4, 1], Any[]],
                        0x9e49a006a4448bed => Any[Any[2, 4, 1, 4], Any[1]],
                        0x6fc1f7b37668f35d => Any[Any[2, 4, 1, 4, 1]],
                        0x1cc3a1d65866a81c => Any[Any[2, 4], Any[]],
                        0xdfa148e61e3478b1 => Any[Any[2], Any[], Any[4]],
                        0xe7036a7826b8dba7 => Any[Any[2]],
                        0xf1d8525f68b94da2 => Any[Any[2, 4, 1]],
                        0xc28379809fd920dc => Any[Any[2], Any[], Any[4, 1, 4]],
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

    @testcase_log "Reverse fold_h" begin
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

    @testcase_log "Reverse fold_h with plus" begin
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

    @testcase_log "Reverse fold_v" begin
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

    @testcase_log "Reverse fold_v with plus" begin
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

    @testcase_log "Reverse rev_groupby" begin
        skeleton = parse_program("(rev_groupby (lambda (car \$0)) ??(list(int)) ??(set(tuple2(int, set(list(int))))))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test in(
            run_in_reverse(p, Set([(1, Set([[1, 2, 3], [1, 4, 2]])), (2, Set([[2]]))])),
            [
                Dict(UInt64(1) => [2], UInt64(2) => Set([(1, Set([[1, 2, 3], [1, 4, 2]]))])),
                Dict(UInt64(1) => [1, 4, 2], UInt64(2) => Set([(2, Set([[2]])), (1, Set([[1, 2, 3]]))])),
                Dict(UInt64(1) => [1, 2, 3], UInt64(2) => Set([(1, Set([[1, 4, 2]])), (2, Set([[2]]))])),
            ],
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [1, 2, 3], UInt64(2) => Set([(1, Set([[1, 4, 2]])), (2, Set([[2]]))])),
        ) == Set([(1, Set([[1, 2, 3], [1, 4, 2]])), (2, Set([[2]]))])
        @test run_with_arguments(p, [], Dict(UInt64(1) => [2], UInt64(2) => Set([(1, Set([[1, 2, 3], [1, 4, 2]]))]))) ==
              Set([(1, Set([[1, 2, 3], [1, 4, 2]])), (2, Set([[2]]))])
    end

    @testcase_log "Reverse rev_fold with rev_groupby" begin
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

    @testcase_log "Reverse rev_greedy_cluster" begin
        skeleton = parse_program(
            "(rev_greedy_cluster (lambda (lambda (all_set (lambda (eq? (car \$0) (car \$2))) \$0))) ??(list(list(int))) ??(set(set(list(int)))))",
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test in(
            run_in_reverse(p, Set([Set([[1, 2, 3], [1, 4, 2]]), Set([[2]])])),
            Set([
                Dict(UInt64(1) => [2], UInt64(2) => Set([Set([[1, 2, 3], [1, 4, 2]])])),
                Dict(UInt64(1) => [1, 4, 2], UInt64(2) => Set([Set([[1, 2, 3]]), Set([[2]])])),
                Dict(UInt64(1) => [1, 2, 3], UInt64(2) => Set([Set([[1, 4, 2]]), Set([[2]])])),
            ]),
        )

        @test run_with_arguments(
            p,
            [],
            Dict(UInt64(1) => [1, 2, 3], UInt64(2) => Set([Set([[1, 4, 2]]), Set([[2]])])),
        ) == Set([Set([[1, 2, 3], [1, 4, 2]]), Set([[2]])])

        @test run_with_arguments(p, [], Dict(UInt64(1) => [2], UInt64(2) => Set([Set([[1, 2, 3], [1, 4, 2]])]))) ==
              Set([Set([[1, 2, 3], [1, 4, 2]]), Set([[2]])])
    end

    @testcase_log "Reverse rev_greedy_cluster by length" begin
        skeleton = parse_program(
            "(rev_greedy_cluster (lambda (lambda (any_set (lambda (not (gt? (abs (- (length \$0) (length \$2))) 1))) \$0))) ??(list(list(int))) ??(set(set(list(int)))))",
        )
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test in(
            run_in_reverse(p, Set([Set([[1, 2, 3], [1, 4, 2, 2], [3, 5, 2, 5, 2]]), Set([[2]])])),
            Set([
                Dict(
                    UInt64(1) => [1, 4, 2, 2],
                    UInt64(2) => Set(Set{Vector{Int64}}[Set([[1, 2, 3]]), Set([[3, 5, 2, 5, 2]]), Set([[2]])]),
                ),
                Dict(
                    UInt64(1) => [3, 5, 2, 5, 2],
                    UInt64(2) => Set(Set{Vector{Int64}}[Set([[2]]), Set([[1, 2, 3], [1, 4, 2, 2]])]),
                ),
                Dict(
                    UInt64(1) => [1, 2, 3],
                    UInt64(2) => Set(Set{Vector{Int64}}[Set([[3, 5, 2, 5, 2], [1, 4, 2, 2]]), Set([[2]])]),
                ),
                Dict(
                    UInt64(1) => [2],
                    UInt64(2) => Set(Set{Vector{Int64}}[Set([[3, 5, 2, 5, 2], [1, 2, 3], [1, 4, 2, 2]])]),
                ),
            ]),
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

    @testcase_log "Reverse rev_fold_set with rev_greedy_cluster" begin
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

    @testcase_log "Reverse fold with concat and range" begin
        skeleton = parse_program("(fold (lambda (lambda (concat \$0 (range \$1)))) ??(list(int)) ??(list(int)))")
        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test compare_options_subset(
            run_in_reverse(p, [12, 4, 8, 11, 0, 8, 11]),
            Dict(
                UInt64(1) => EitherOptions(
                    Dict{UInt64,Any}(
                        0xc051555df3f52f90 => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0x58f65bfff9aff2b5 => Any[0, 0, 0, 0, 0, 0, 0],
                        0xd4c0847c70a422be => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0xe218a9c75cd0a8e5 => Any[0, 0, 0, 0, 0],
                        0xe5f88ea7e065eaed => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0x9c617295e48b296f => Any[0, 0, 0],
                        0x7bebac37d5e5eb89 => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0xc9970bcc3709cb64 => Any[0],
                        0x00da77c6db754f1f => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0x67446ae45e1e69f9 => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0x4a4b94369d374257 => Any[0, 0, 0, 0],
                        0x6dacb8f1d62b78de => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0x27e029194b0f4979 => Any[],
                        0x082d2f7a58693222 => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0xb64b0c70faed7b57 => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0x768b1bad4a071f7f => Any[0, 0, 0, 0, 0, 0],
                        0xd4fa0a335b722d0e => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0xba2a4bc6fd4702d8 => Any[0, 0, 0, 0, 0, 0, 0, 0],
                        0xbad4eddfdbb89749 => Any[0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0xc79adcab7e05081c => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0xd5fedbd27adb7015 => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                        0xac2b4fc6c2c9430a => Any[0, 0],
                        0x4b25e6664a7ae4ba => Any[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
                    ),
                ),
                UInt64(2) => [12, 4, 8, 11, 0, 8, 11],
            ),
        )

        @test run_with_arguments(p, [], Dict(UInt64(1) => [0], UInt64(2) => [12, 4, 8, 11, 0, 8, 11])) ==
              [12, 4, 8, 11, 0, 8, 11]
    end

    @testcase_log "Reverse map with input fixed to nothing" begin
        skeleton = parse_program(
            "((lambda ((lambda ((lambda ((lambda (rev_fix_param (map_set (lambda (tuple2 \$2 \$0)) \$0) \$0 (lambda (car (rev_list_elements (tuple2_first (tuple2 empty_set empty)) 1))))) (tuple2_second (tuple2_first \$v11)))) \$0)) \$v12)) \$v13)",
        )

        @test is_reversible(skeleton)

        p, _ = capture_free_vars(skeleton)

        @test_throws ErrorException compare_options_subset(
            run_in_reverse(
                p,
                Set([
                    (6, [6, 4, 0, 8, 4, 5, 9, 1, 8, 4, 1, 3, 4, 9]),
                    (6, [1, 2, 8, 9, 3, 4, 5, 9, 0, 2, 2, 4, 2, 8, 5, 6, 3, 0, 7]),
                    (6, [6, 4, 1, 2, 0, 3, 2, 0, 3, 7, 3, 5, 1, 7, 5, 6]),
                    (6, [6, 8, 2, 7, 6, 1, 7, 4, 1, 4]),
                    (6, [0, 7, 9, 3, 9]),
                    (6, [6, 9, 9, 3, 2, 8, 2, 7, 6, 4, 6, 3, 7, 7, 6]),
                    (6, [7, 3, 9, 4, 3, 1, 3, 7, 1, 9, 8, 2, 8, 3, 2, 9, 3, 3, 5]),
                    (6, [7, 5, 7, 2, 4, 3, 1, 1, 6, 0, 6]),
                ]),
            ),
            Dict(),
        )
    end
end

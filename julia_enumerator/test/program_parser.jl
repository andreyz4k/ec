
using Test

using solver: parse_program

@testset "Program parser" begin
    function parsing_test_case(s)
        @test repr(parse_program(s)) == s
    end

    parsing_test_case("1")
    parsing_test_case("+")
    parsing_test_case("(+ 1)")
    parsing_test_case("(\$0 \$1)")
    parsing_test_case("(+ 1 \$0 \$2)")
    parsing_test_case("(map (+ 1) \$0 \$1)")
    parsing_test_case("(map (+ 1) (\$0 (+ 1) (- 1) (+ -)) \$1)")
    parsing_test_case("(lambda \$0)")
    parsing_test_case("(lambda (+ 1 #(* 0 1)))")
    parsing_test_case("(lambda (+ 1 #(* 0 map)))")
    # parsing_test_case("let \$v1 = 1 in \$v1")

    # parsing_test_case(
    #     "(lambda let \$v1 = (cdr \$0) in let \$v2 = (eq? \$0 \$v1) in let \$v3 = (eq? \$0 \$0) in (eq? \$v2 \
    #      \$v3))",
    # )

    # parsing_test_case(
    #     "let \$v1 = Const(list(int), Any[]) in let \$v2 = Const(list(int), Any[0]) in let \$v3 = (concat \
    #      \$v1 \$v2) in (concat \$inp0 \$v3)",
    # )

    # parsing_test_case("let \$v1 = Const(list(int), Any[5]) in let \$v2 = Const(list(int), Any[]) in let \$v3, \$v4 = \
    #                    wrap(let \$v3, \$v4 = rev(\$inp0 = (concat \$v3 \$v4)); let \$v3 = \$v2) in (concat \$v1 \$v4)")

    # parsing_test_case("let \$v1 = Const(list(list(color)), Any[Any[0, 0, 0]]) in \$v1")
    # parsing_test_case("Const(list(list(color)), Any[Any[0, 0, 0]])")

    # parsing_test_case(
    #     "let \$v1 = Const(list(list(color)), Any[Any[0, 0, 0]]) in let \$v2, \$v3 = rev(\$inp0 = (cons \$v2 \
    #      \$v3)) in let \$v4 = (car \$v3) in let \$v5 = Const(int, 1) in let \$v6 = (repeat \$v4 \$v5) in let \
    #      \$v7 = (cons \$v2 \$v6) in (concat \$v1 \$v7)",
    # )
end

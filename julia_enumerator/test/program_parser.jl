
using Test

using solver: parse_program, parse_type, TypeVariable

@testset "Program parser" begin
    function parsing_test_case(s)
        @testset "$s" begin
            @test repr(parse_program(s)) == s
        end
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
    parsing_test_case("\$inp0")
    parsing_test_case("let \$v1::int = 1 in \$v1")

    parsing_test_case("(lambda let \$v1::list(int) = (cdr \$0) in let \$v2::bool = (eq? \$0 \$v1) in \
                      let \$v3::bool = (eq? \$0 \$0) in (eq? \$v2 \$v3))")

    parsing_test_case(
        "let \$v1::list(int) = Const(list(int), Any[]) in let \$v2::list(int) = Const(list(int), Any[0]) in \
            let \$v3::list(int) = (concat \$v1 \$v2) in (concat \$inp0 \$v3)",
    )

    parsing_test_case(
        "let \$v1::list(int) = Const(list(int), Any[5]) in let \$v2::list(int) = Const(list(int), Any[]) in \
            let \$v3, \$v4 = wrap(let \$v3, \$v4 = rev(\$inp0 = (concat \$v3 \$v4)); let \$v3 = \$v2) in \
            (concat \$v1 \$v4)",
    )

    parsing_test_case("let \$v1::list(list(color)) = Const(list(list(color)), Any[Any[0, 0, 0]]) in \$v1")
    parsing_test_case("Const(list(list(color)), Any[Any[0, 0, 0]])")

    parsing_test_case("let \$v1::list(list(color)) = Const(list(list(color)), Any[Any[0, 0, 0]]) in \
                          let \$v2, \$v3 = rev(\$inp0 = (cons \$v2 \$v3)) in let \$v4::list(color) = (car \$v3) in \
                          let \$v5::int = Const(int, 1) in let \$v6::list(list(color)) = (repeat \$v4 \$v5) in \
                          let \$v7::list(list(color)) = (cons \$v2 \$v6) in (concat \$v1 \$v7)")
end

@testset "Type parser" begin
    function parsing_test_case(s)
        @testset "$s" begin
            @test repr(parse_type(s)) == s
        end
    end
    @test parse_type("t0") == TypeVariable(0)

    parsing_test_case("t0")
    parsing_test_case("t1")
    parsing_test_case("int")
    parsing_test_case("list(int)")
    parsing_test_case("tuple(int, int)")
    parsing_test_case("int -> int")
    parsing_test_case("int -> int -> int")
    parsing_test_case("list(int) -> list(int)")
    parsing_test_case("list(int) -> list(int) -> list(int)")
    parsing_test_case("list(int) -> (int -> bool) -> list(bool)")
    parsing_test_case("inp0:list(int) -> list(int)")
    parsing_test_case("inp0:list(int) -> inp1:list(int) -> list(int)")
    parsing_test_case("f:(list(int) -> int) -> inp1:list(int) -> list(int)")
    parsing_test_case("obj(cells:list(tuple(int, int)), kind)")
    parsing_test_case("obj(cells:list(tuple(int, int)), pivot:bool, kind)")
    parsing_test_case("obj(f:(int -> int), cells:list(tuple(int, int)), kind)")
    parsing_test_case("obj(int -> int, list(tuple(int, int)), kind)")
end

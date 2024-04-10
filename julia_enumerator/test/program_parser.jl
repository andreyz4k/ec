
using solver: parse_program, parse_type, TypeVariable

@testset "Program parser" begin
    function parsing_test_case(s)
        @testcase_log "$s" begin
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
    parsing_test_case("(lambda (+ 1 (#(* 0) \$0)))")
    parsing_test_case("\$inp0")
    parsing_test_case("let \$v1::int = 1 in \$v1")

    parsing_test_case("(lambda let \$v1::list(int) = (cdr \$0) in let \$v2::bool = (eq? \$0 \$v1) in \
                      let \$v3::bool = (eq? \$0 \$0) in (eq? \$v2 \$v3))")

    parsing_test_case(
        "let \$v1::list(int) = Const(list(int), Any[]) in let \$v2::list(int) = Const(list(int), Any[0]) in \
            let \$v3::list(int) = (concat \$v1 \$v2) in (concat \$inp0 \$v3)",
    )

    parsing_test_case(
        "let \$v1::list(int) = Const(list(int), Any[5]) in \
            let \$v3, \$v4 = rev(\$inp0 = (rev_fix_param (concat \$v3 \$v4) \$v3 (lambda Const(list(int), Any[])))) in \
            (concat \$v1 \$v4)",
    )

    parsing_test_case("let \$v1::list(list(color)) = Const(list(list(color)), Any[Any[0, 0, 0]]) in \$v1")
    parsing_test_case("Const(list(list(color)), Any[Any[0, 0, 0]])")

    parsing_test_case("let \$v1::list(list(color)) = Const(list(list(color)), Any[Any[0, 0, 0]]) in \
                          let \$v2, \$v3 = rev(\$inp0 = (cons \$v2 \$v3)) in let \$v4::list(color) = (car \$v3) in \
                          let \$v5::int = Const(int, 1) in let \$v6::list(list(color)) = (repeat \$v4 \$v5) in \
                          let \$v7::list(list(color)) = (cons \$v2 \$v6) in (concat \$v1 \$v7)")

    parsing_test_case("(+ 1 ??(int))")
    parsing_test_case(
        "((lambda (lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first \$0) (tuple2_first \$2)) (+ (tuple2_second \$0) (tuple2_second \$2)))) \$0) \$1 (lambda (tuple2 (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_first \$0)) (collect \$0)) max_int) (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_second \$0)) (collect \$0)) max_int)))))) (tuple2_first \$v1) (tuple2_second \$v1))",
    )
    parsing_test_case(
        "#(lambda (lambda (map_set (lambda (tuple2 (+ (tuple2_first \$0) (tuple2_first \$2)) (+ (tuple2_second \$0) (tuple2_second \$2)))) \$0)))",
    )

    parsing_test_case(
        "#(lambda (lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first \$0) (tuple2_first \$2)) (+ (tuple2_second \$0) (tuple2_second \$2)))) \$0) \$1 (lambda (tuple2 (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_first \$0)) (collect \$0)) max_int) (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_second \$0)) (collect \$0)) max_int))))))",
    )

    parsing_test_case(
        "(#(lambda (lambda (rev_fix_param (map_set (lambda (tuple2 (+ (tuple2_first \$0) (tuple2_first \$2)) (+ (tuple2_second \$0) (tuple2_second \$2)))) \$0) \$1 (lambda (tuple2 (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_first \$0)) (collect \$0)) max_int) (fold (lambda (lambda (if (gt? \$0 \$1) \$1 \$0))) (map (lambda (tuple2_second \$0)) (collect \$0)) max_int)))))) (tuple2_first \$v1) (tuple2_second \$v1))",
    )
    parsing_test_case("Const(set(tuple2(int, int)), Set{Any}())")
    parsing_test_case("Const(set(tuple2(int, int)), Set([(0, 0), (0, 2), (2, 0), (1, 1), (0, 1), (2, 2), (2, 1)]))")
    parsing_test_case(
        "let \$v1, \$v2 = rev(\$inp0 = (tuple2 \$v1 \$v2)) in let \$v3::set(tuple2(int, int)) = Const(set(tuple2(int, int)), Set([(0, 0), (0, 2), (2, 0), (1, 1), (0, 1), (2, 2), (2, 1)])) in (rev_select_set (lambda (eq? (tuple2_second (tuple2_first \$0)) \$v3)) \$v1 \$v2)",
    )
    parsing_test_case(
        "Const(grid(t1), [[any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object; any_object any_object any_object any_object any_object]])",
    )
    parsing_test_case("#(lambda (lambda (lambda (cons \$0 (cons \$1 \$2)))))")
    parsing_test_case("#(lambda (repeat \$0 Const(int, 1)))")
    parsing_test_case("#(lambda (lambda (- \$0 (- \$0 \$1))))")
end

@testset "Type parser" begin
    function parsing_test_case(s)
        @testcase_log "$s" begin
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

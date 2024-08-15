using solver: create_arc_task, get_starting_grammar, get_guiding_model, solve_task

@testset "Expl arc tasks" begin
    function _create_arc_task(filename, dir = "ARC/data/training/")
        fname = "../../dreamcoder/domains/arc/" * dir * filename
        tp = parse_type("inp0:grid(color) -> grid(color)")
        return create_arc_task(fname, tp)
    end

    grammar = get_starting_grammar()
    guiding_model = get_guiding_model("dummy")
    type_weights = Dict{String,Any}(
        "int" => 1.0,
        "list" => 1.0,
        "color" => 1.0,
        "bool" => 1.0,
        "float" => 1.0,
        "grid" => 1.0,
        "tuple2" => 1.0,
        "tuple3" => 1.0,
        "coord" => 1.0,
        "set" => 1.0,
        "any" => 1.0,
    )
    hyperparameters = Dict{String,Any}("path_cost_power" => 1.0, "complexity_power" => 1.0, "block_cost_power" => 1.0)

    @testcase_log "a416b8f3.json" begin
        task = _create_arc_task("a416b8f3.json")

        result =
            @time solve_task(task, guiding_model, grammar, nothing, 40, 1, type_weights, hyperparameters, 10, false)
        @test length(result) == 10
    end
end

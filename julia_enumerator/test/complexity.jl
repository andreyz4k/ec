
using Test
using DataStructures

using solver: get_complexity_summary, tlist, tint, tgrid, tcolor

@testset "Test complexity" begin
    @testset "list complexity" begin
        l = [1, 2, 3]
        t = tlist(tint)
        s = get_complexity_summary([l], t)
        @test s == Accumulator("list" => 1, "int" => 3)

        ll = [[1, 2, 3], [1, 2, 3]]
        tt = tlist(tlist(tint))
        ss = get_complexity_summary([ll], tt)
        @test ss == Accumulator("list" => 3, "int" => 6)
    end

    @testset "grid complexity" begin
        g = [1 2 3; 4 5 6]
        t = tgrid(tcolor)
        s = get_complexity_summary([g], t)
        @test s == Accumulator("grid" => 1, "color" => 6)
    end
end

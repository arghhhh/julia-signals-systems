

include( "env.jl")

using Test

import Sequences
import Processors
import ProcSeqs

sys1_add = 100 + Processors.Map( x -> 2x )
sys1_sub = 100 - Processors.Map( x -> 2x )
sys1_mul = 100 * Processors.Map( x -> 2x )
sys1_div = 120 / Processors.Map( x -> 2x )

@testset "arith-seq-proc" begin

        @test 1:5 |> sys1_add |> collect == [ 102, 104, 106, 108, 110 ]
        @test 1:5 |> sys1_sub |> collect == [  98,  96,  94,  92,  90 ]
        @test 1:5 |> sys1_mul |> collect == [ 200, 400, 600, 800, 1000 ]
        @test 1:5 |> sys1_div |> collect == [ 60.0, 30.0, 20.0, 15.0, 12.0 ]

        sys2_add = Processors.Map( x -> 2x ) + 100 
        sys2_sub = Processors.Map( x -> 2x ) - 100 
        sys2_mul = Processors.Map( x -> 2x ) * 100 
        sys2_div = Processors.Map( x -> 4x ) / 2 

        @test 1:5 |> sys2_add |> collect == [ 102, 104, 106, 108, 110 ]
        @test 1:5 |> sys2_sub |> collect == [ -98, -96, -94, -92, -90 ]
        @test 1:5 |> sys2_mul |> collect == [ 200, 400, 600, 800, 1000 ]
        @test 1:5 |> sys2_div |> collect == [ 2.0, 4.0, 6.0, 8.0, 10.0 ]

        # check that it looks like length is being calculated properly:
        @test 1:5 |> ( ones(5) + Processors.Map( x->2x ) ) |> collect == [ 3.0, 5.0, 7.0, 9.0, 11.0 ]
        @test Sequences.sequence(1) |> ( ones(5) + Processors.Map( x->2x ) ) |> collect == [ 3.0, 3.0, 3.0, 3.0, 3.0 ]
        # following checks that the promotion from a Number to a infinite sequence works:
        @test 1 |> ( ones(5) + Processors.Map( x->2x ) ) |> collect == [ 3.0, 3.0, 3.0, 3.0, 3.0 ]
end

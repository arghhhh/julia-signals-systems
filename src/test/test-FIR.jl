include( "env.jl")

using Test
using Plots # convenience for interactive dev

import Sequences
import Processors
import ProcSeqs

@testset "FIR" begin

        impulse = [ 0, 0, 1, 0, 0, 0 ]

        sys = Processors.FIR( [ 1, -1 ] )

        y1 = impulse |> sys |> collect

        impulse_Float64 = Float64[ 0, 0, 1, 0, 0, 0 ]
        y2 = impulse_Float64 |> sys |> collect

        @show impulse_Float64 y2

        @test        [0,0,1,0,0,0] |> Processors.FIR( [1,-1] ) |> collect == [0,0,1,-1,0,0]
        @test Float64[0,0,1,0,0,0] |> Processors.FIR( [1,-1] ) |> collect == [0,0,1,-1,0,0]
        @test        [0,0,1,0,0,0] |> Processors.FIR( [1.0,-1.0] ) |> collect == [0,0,1,-1,0,0]
        @test Float64[0,0,1,0,0,0] |> Processors.FIR( [1.0,-1.0] ) |> collect == [0,0,1,-1,0,0]

        # check actual and expected output type for combinations of Int64 and Float64 inputs and coeffs:
        @test eltype(        [0,0,1,0,0,0] |> Processors.FIR( [1,-1]     )         ) == Int64
        @test eltype( Float64[0,0,1,0,0,0] |> Processors.FIR( [1,-1]     )         ) == Float64
        @test eltype(        [0,0,1,0,0,0] |> Processors.FIR( [1.0,-1.0] )         ) == Float64
        @test eltype( Float64[0,0,1,0,0,0] |> Processors.FIR( [1.0,-1.0] )         ) == Float64
        @test eltype(        [0,0,1,0,0,0] |> Processors.FIR( [1,-1]     ) |> collect ) == Int64
        @test eltype( Float64[0,0,1,0,0,0] |> Processors.FIR( [1,-1]     ) |> collect ) == Float64
        @test eltype(        [0,0,1,0,0,0] |> Processors.FIR( [1.0,-1.0] ) |> collect ) == Float64
        @test eltype( Float64[0,0,1,0,0,0] |> Processors.FIR( [1.0,-1.0] ) |> collect ) == Float64

        # check actual and expected output type for combinations of Int64 and Complex{Int64} inputs and coeffs:
        @test eltype( [0,0,1  ,0,0,0] |> Processors.FIR( [1,-1]   )         ) == Int64
        @test eltype( [0,0,1im,0,0,0] |> Processors.FIR( [1,-1]   )         ) == Complex{Int}
        @test eltype( [0,0,1  ,0,0,0] |> Processors.FIR( [1,-1im] )         ) == Complex{Int}
        @test eltype( [0,0,1im,0,0,0] |> Processors.FIR( [1,-1im] )         ) == Complex{Int}
        @test eltype( [0,0,1  ,0,0,0] |> Processors.FIR( [1,-1]   ) |> collect ) == Int64
        @test eltype( [0,0,1im,0,0,0] |> Processors.FIR( [1,-1]   ) |> collect ) == Complex{Int}
        @test eltype( [0,0,1  ,0,0,0] |> Processors.FIR( [1,-1im] ) |> collect ) == Complex{Int}
        @test eltype( [0,0,1im,0,0,0] |> Processors.FIR( [1,-1im] ) |> collect ) == Complex{Int}



        # coefficient chosen so that output should have exact Float64 representation:
        @test [0,0,1,0,0,0] |> Processors.FIR( [1.0,-0.875] ) |> collect == [0,0,1,-0.875,0,0]
        @test [0,0,1,2,3,0,0,0] |> Processors.FIR( [1.0,-0.875] ) |> collect == [0,0,1,1.125,1.25,-2.625,0,0]
end

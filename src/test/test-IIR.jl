include( "env.jl")

using Test
using Plots # convenience for interactive dev

import Sequences
import Processors
import ProcSeqs

@testset "IIR" begin

        impulse = [ 0, 0, 1, 0, 0, 0 ]

        sys = Processors.IIR_poles( [ 1, -1 ] )

        y1 = impulse |> sys |> collect

        impulse_Float64 = Float64[ 0, 0, 1, 0, 0, 0 ]
        y2 = impulse_Float64 |> sys |> collect

        @show impulse_Float64 y2

        @test        [0,0,1,0,0,0] |> Processors.IIR_poles( [1,-1] ) |> collect == [0,0,1,1,1,1]
        @test Float64[0,0,1,0,0,0] |> Processors.IIR_poles( [1,-1] ) |> collect == [0,0,1,1,1,1]
        @test        [0,0,1,0,0,0] |> Processors.IIR_poles( [1.0,-1.0] ) |> collect == [0,0,1,1,1,1]
        @test Float64[0,0,1,0,0,0] |> Processors.IIR_poles( [1.0,-1.0] ) |> collect == [0,0,1,1,1,1]

        # check actual and expected output type for combinations of Int64 and Float64 inputs and coeffs:
        @test eltype(        [0,0,1,0,0,0] |> Processors.IIR_poles( [1,-1]     )         ) == Int64
        @test eltype( Float64[0,0,1,0,0,0] |> Processors.IIR_poles( [1,-1]     )         ) == Float64
        @test eltype(        [0,0,1,0,0,0] |> Processors.IIR_poles( [1.0,-1.0] )         ) == Float64
        @test eltype( Float64[0,0,1,0,0,0] |> Processors.IIR_poles( [1.0,-1.0] )         ) == Float64
        @test eltype(        [0,0,1,0,0,0] |> Processors.IIR_poles( [1,-1]     ) |> collect ) == Int64
        @test eltype( Float64[0,0,1,0,0,0] |> Processors.IIR_poles( [1,-1]     ) |> collect ) == Float64
        @test eltype(        [0,0,1,0,0,0] |> Processors.IIR_poles( [1.0,-1.0] ) |> collect ) == Float64
        @test eltype( Float64[0,0,1,0,0,0] |> Processors.IIR_poles( [1.0,-1.0] ) |> collect ) == Float64

        # coefficient chosen so that output should have exact Float64 representation:
        @test [0,0,1,0,0,0] |> Processors.IIR_poles( [1.0,-0.875] ) |> collect == [0,0,1,0.875,0.765625,0.669921875]
        @test [0,0,1,2,3,0] |> Processors.IIR_poles( [1.0,-0.875] ) |> collect == [0,0,1,2.875,5.515625,4.826171875]
end


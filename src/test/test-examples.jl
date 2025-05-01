
include( "env.jl")

using Test

import Sequences:  Sequences, Test_Range, concatenate, info, sequence
import Processors: Processors, Downsample, Upsample, Vectorize, Take, fir, Map, MapT, Integrator, Filter, Flatten
import ProcSeqs  # not actually used here, but leave make it available for interactive work after running this

# examples from https://clojure.org/reference/transducers

inc(x) = x+1
isdiv4(x) = x%4 == 0

# buildingup a system from parts:
f1 = Filter( isodd )
f2 = Map( inc )
f3 = Take( 5 )

xf = f1 |> f2 |> f3

# @show 1:100 |> xf |> collect


@testset "examples" begin
        @test 0:100 |> Filter( isodd  )               |> Take( 5 ) |> collect == [1,3,5,7,9]
        @test 0:100 |> Filter( isodd  ) |> Map( inc ) |> Take( 5 ) |> collect == [2,4,6,8,10]
        @test 1:100 |> Filter( isdiv4 ) |> Map( inc ) |> Take( 5 ) |> collect == [5,9,13,17,21]
        @test 1:100 |> xf |> collect == [2,4,6,8,10]


        # some variants of the above with different parenthesis
        @test 0:100 |> ( Filter( isodd ) |> Take( 5 ) ) |> collect == [1,3,5,7,9]
        @test 0:100 |> ( Filter( isodd ) |>   Map( inc )   |> Take( 5 ) ) |> collect == [2,4,6,8,10]
        @test 0:100 |> ( Filter( isodd ) |>   Map( inc ) ) |> Take( 5 )   |> collect == [2,4,6,8,10]
        @test 0:100 |>   Filter( isodd ) |> ( Map( inc )   |> Take( 5 ) ) |> collect == [2,4,6,8,10]


        # https://juliafolds.github.io/Transducers.jl/dev/#Examples

        @test 1:3 |> Map(x -> 2x) |> collect == [2,4,6]
        @test 1:6 |> Filter(iseven) |> collect == [2,4,6]

        # the following line is from https://juliafolds.github.io/Transducers.jl/dev/#Examples
        # 1:3 |> MapCat(x -> 1:x) |> collect
        # an equivalent is:
        @test 1:3 |> Map(x -> 1:x) |> Base.Iterators.flatten |> collect == [1, 1,2, 1,2,3]
        # but this is cheating slightly, because this doesn't work:
        # 1:3 |> ( Map(x -> 1:x) |> Base.Iterators.flatten ) |> collect
        # this could be fixed by writing a processor that expands iterables... 
        # 1:0 is zero length - so checking that these are skipped over
        @test [ 1:0, 1:0, 1:2, 1:0,  4:5 , 1:0, 1:0 ] |> Processors.Flatten() |> collect == [ 1,2,4,5]
        # so finally, equivalent to transducers.jl: 1:3 |> MapCat(x -> 1:x) |> collect
        @test 1:3 |>   Map(x -> 1:x) |> Flatten()   |> collect == [1, 1,2, 1,2,3]
        @test 1:3 |> ( Map(x -> 1:x) |> Flatten() ) |> collect == [1, 1,2, 1,2,3]

        @test 1:6 |> Filter(iseven) |> Map(x -> 2x) |> collect == [4,8,12]

        # from https://juliafolds.github.io/Transducers.jl/dev/#Examples
        # but this is the standard Base.foldl whereas the Transducers.jl uses 
        # https://juliafolds.github.io/Transducers.jl/dev/reference/manual/#Base.foldl
        @test Base.foldl(+, 1:6 |> Filter(iseven) |> Map(x -> 2x)) == 24

        # even with a single noise source - should get different random numbers every time
        noise = Sequences.UniformRandom(-1.0,1.0)
        y1 = noise |> Processors.Take(10) |> collect
        y2 = noise |> Processors.Take(10) |> collect
        @test y1 != y2
        y1 = Sequences.UniformRandom(-1.0,1.0) |> Processors.Take(10) |> collect
        y2 = Sequences.UniformRandom(-1.0,1.0) |> Processors.Take(10) |> collect
        @test y1 != y2

        # but with the same given seed, even with two distinct noise sources, 
        # should get the same sequence:
        seed = 1
        y1 = Sequences.UniformRandom(-1.0,1.0,seed) |> Processors.Take(10) |> collect
        y2 = Sequences.UniformRandom(-1.0,1.0,seed) |> Processors.Take(10) |> collect
        @test y1 == y2

        # even with a single noise source - should get different random numbers every time
        noise = Sequences.GaussianRandom()
        y1 = noise |> Processors.Take(10) |> collect
        y2 = noise |> Processors.Take(10) |> collect
        @test y1 != y2
        y1 = Sequences.GaussianRandom() |> Processors.Take(10) |> collect
        y2 = Sequences.GaussianRandom() |> Processors.Take(10) |> collect
        @test y1 != y2

        # but with the same given seed, even with two distinct noise sources, 
        # should get the same sequence:
        seed = 1
        y1 = Sequences.GaussianRandom(seed) |> Processors.Take(10) |> collect
        y2 = Sequences.GaussianRandom(seed) |> Processors.Take(10) |> collect
        @test y1 == y2

        # arithmetic with sequences
        # the random numbers should have mean 2, so plus 3 and then multiply by 2
        # gives an expected value of 10, summed over 10000 values, gives an 
        # expected value of 100000
        s = sum( 2*( 3 + Sequences.UniformRandom(1.0, 3.0, seed) ) |> Processors.Take(10000) )
        @test 99000 < s < 101000

end
nothing
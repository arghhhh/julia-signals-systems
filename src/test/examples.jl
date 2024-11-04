
include( "env.jl")

using Test

import Sequences:  Sequences, Test_Range, concatenate, info, sequence
import Processors: Processors, Downsample, Upsample, Vectorize, Take, fir, Map, MapT, Integrator, Filter, Flatten


# examples from https://clojure.org/reference/transducers

inc(x) = x+1

f1 = Filter( isodd )
f2 = Map( inc )
f3 = Take( 5 )

isdiv4(x) = x%4 == 0

xf = Filter( isodd ) |> Map( inc ) |> Take( 5 )

@show 1:100 |> xf |> collect


@testset begin
        @test 0:100 |> Filter( isodd ) |> Take( 5 ) |> collect == [1,3,5,7,9]
        @test 0:100 |> Filter( isodd ) |> Map( inc ) |> Take( 5 ) |> collect == [2,4,6,8,10]
        @test 1:100 |> Filter( isdiv4 ) |> Map( inc ) |> Take( 5 ) |> collect == [5,9,13,17,21]
        @test 1:100 |> xf |> collect == [2,4,6,8,10]

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
        # equivalent to transducers.jl: 1:3 |> MapCat(x -> 1:x) |> collect
        @test 1:3 |> Map(x -> 1:x) |> Flatten() |> collect == [1, 1,2, 1,2,3]
        @test 1:3 |> ( Map(x -> 1:x) |> Flatten() ) |> collect == [1, 1,2, 1,2,3]

        @test 1:6 |> Filter(iseven) |> Map(x -> 2x) |> collect == [4,8,12]

        # from https://juliafolds.github.io/Transducers.jl/dev/#Examples
        # but this is Base.foldl whereas the Transducers.jl uses 
        # https://juliafolds.github.io/Transducers.jl/dev/reference/manual/#Base.foldl
        @test Base.foldl(+, 1:6 |> Filter(iseven) |> Map(x -> 2x)) == 24
end
nothing
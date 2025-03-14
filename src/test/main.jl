

include( "env.jl")

using Plots

# bring the following names into scope:
import Sequences:  Sequences, Test_Range, concatenate, info, sequence
import Processors: Processors, Downsample, Upsample, Vectorize, Take, fir, Map, MapT, Integrator

Test_Range(10) |> info
Test_Range(10) |> collect

Test_Range(50) |> Downsample(5) |> info

# check that length calculation looks OK for a range of input lengths:
Test_Range(50) |> Downsample(5) |> collect
Test_Range(51) |> Downsample(5) |> collect
Test_Range(52) |> Downsample(5) |> collect
Test_Range(53) |> Downsample(5) |> collect
Test_Range(54) |> Downsample(5) |> collect
Test_Range(55) |> Downsample(5) |> collect
Test_Range(56) |> Downsample(5) |> collect

Test_Range(4) |> Upsample(4)  |> collect

# The Vectorize output is a view of its state - and this state is mutated for each sample for efficiency
# - but as a consequence of this, if these views are simply collected as views, they become invalidated
# - so in this case, need to tell collect to copy the view into new Vectors for each sample.  
# - For most real applications this will not be a problem and should not be necessary.
Test_Range(10)+100 |> Vectorize(4) |> x->collect(Vector,x)
Test_Range(10)+100 |> Vectorize(4) |> Downsample(1,4-1) |> x->collect(Vector,x)



concatenate( zeros(10), sequence(0.0) ) |> info
concatenate( zeros(10), 1.0, sequence(0.0) ) |> info
concatenate( zeros(10), 1.0, sequence(0.0) ) |> Take(15) |> info

impulse = concatenate( zeros(10), 1.0, sequence(0.0) )

y = ( impulse 
	|> Take(100) 
	|> fir( ones(10) ) 
	|> fir( ones(10) ) 
	|> fir( ones(10) ) 
	|> fir( ones(10) ) 
	|> collect
)

plot(y, line=:stem, marker=:circle )

impulse = concatenate( zeros(10), 1.0, sequence(0.0) )

sys = fir( ones(10) ) |> fir( ones(10) ) |> fir( ones(10) ) |> fir( ones(10) ) 

y3 = impulse |> sys |> Take(100) |> collect


impulse = concatenate( zeros(Int64,10), 1, sequence(0) )
y = ( impulse 
	|> Take(100) 
	|> Integrator(1)
	|> Integrator(1)
	|> Integrator(1)
	|> Integrator(1)
	|> fir( [1,0,0,0,0,0,0,0,0,0,-1])
	|> fir( [1,0,0,0,0,0,0,0,0,0,-1])
	|> fir( [1,0,0,0,0,0,0,0,0,0,-1])
	|> fir( [1,0,0,0,0,0,0,0,0,0,-1])
	|> collect
)

y1 = ( impulse 
	|> Take(100) 
	|> Integrator(1)
	|> Integrator(1)
	|> Integrator(1)
	|> Integrator(1)
	|> fir( [1,0,0,0,0,0,0,0,0,0,-1])
	|> fir( [1,0,0,0,0,0,0,0,0,0,-1])
	|> fir( [1,0,0,0,0,0,0,0,0,0,-1])
	|> fir( [1,0,0,0,0,0,0,0,0,0,-1])
	|> Downsample(10)
	|> collect
)

y2 = ( impulse 
	|> Take(100) 
	|> Integrator(1)
	|> Integrator(1)
	|> Integrator(1)
	|> Integrator(1)
	|> Downsample(10)
	|> fir( [1,-1])
	|> fir( [1,-1])
	|> fir( [1,-1])
	|> fir( [1,-1])
	|> collect
)

@test 1:6 |> Processors.SlidingWindow(3) |> x->collect(Vector,x) == [[1,2,3],[2,3,4],[3,4,5],[4,5,6]]

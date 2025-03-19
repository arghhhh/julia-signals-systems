include( "env.jl")

using Test
using Plots # convenience for interactive dev

import Sequences
import Processors
import ProcSeqs

import DSPfns

impulse = [ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]

sys = Processors.FIR( [ 1, 1, 1, 1 ] )

sys1 = Processors.FIR( [ 1, 1, 1, 1, 1, 1, 1 ] )
sys2 = Processors.FIR( [ 0, 1, 2, 3, 2, 1    ] )


y   = impulse |> sys |> collect
y2  = impulse |> sys |> collect

y3  = impulse |> sys |> sys |> collect
y4  = impulse |> (sys1 + sys2) |> collect


r1   = ProcSeqs.freqz(   sys               , range( 0.0, 1.0; length = 1000 ) )
r2   = ProcSeqs.freqz(   sys |> sys        , range( 0.0, 1.0; length = 1000 ) )
r3   = ProcSeqs.freqz(   sys |> sys |> sys , range( 0.0, 1.0; length = 1000 ) )
r1dB = ProcSeqs.freqzdB( sys               , range( 0.0, 1.0; length = 1000 ) )
r2dB = ProcSeqs.freqzdB( sys |> sys        , range( 0.0, 1.0; length = 1000 ) )
r3dB = ProcSeqs.freqzdB( sys |> sys |> sys , range( 0.0, 1.0; length = 1000 ) )

impulse |> Processors.Gain(2.5) |> collect

# 
# sys = Processors.FIR( [ 0, 1 ] )
# r4dB  = ProcSeqs.freqzdB( sys , f )
# r4deg = ProcSeqs.freqphasedegrees( sys , f )

sys = Processors.ForwardFeedback( Processors.Gain(1), Processors.Gain(-0.99) )

f = logrange( 0.0001, 0.5; length = 1000 )
r4dB  = ProcSeqs.freqzdB( sys , f )
r4deg = ProcSeqs.freqphasedegrees( sys , f )

sys = Processors.IIR_poles( [1.0, -0.99] )
r5dB  = ProcSeqs.freqzdB( sys , f )
r5deg = ProcSeqs.freqphasedegrees( sys , f )

# plot( f, [ r4dB r5dB ], xaxis=:log )


sys = Processors.FIR( [1,2,3,2,1] )
r6dB  = ProcSeqs.freqzdB( sys , f )
r6deg = ProcSeqs.freqphasedegrees( sys , f )
r6dly = ProcSeqs.freqz_grpdelay( sys, f )

sys = Processors.FIR( [1,2,3,4,5] )
r7dB  = ProcSeqs.freqzdB( sys , f )
r7deg = ProcSeqs.freqphasedegrees( sys , f )
r7dly = ProcSeqs.freqz_grpdelay( sys, f )

f = range( 0.0001, 1.0; length = 1000 )

sys = Processors.FIR( [1,2im,3,4im,5] )
r8dB  = ProcSeqs.freqzdB( sys , f )
r8deg = ProcSeqs.freqphasedegrees( sys , f )
r8dly = ProcSeqs.freqz_grpdelay( sys, f )
# compare with MATLAB: grpdelay( [1,2i,3,4i,5], 1, linspace(0,1,1000), 1.0 )


#= MATLAB:
>> format long
>> [z,p,k] = butter(6,0.2);
>> sos = zp2sos(z,p,k)

sos =

   0.000340537652720   0.000681075305440   0.000340537652720   1.000000000000000  -1.032069405319713   0.275707942472945
   1.000000000000000   2.000000000000000   1.000000000000000   1.000000000000000  -1.142980502539899   0.412801598096187
   1.000000000000000   2.000000000000000   1.000000000000000   1.000000000000000  -1.404384890471582   0.735915191196472

=#

sys_butt6 = (
           Processors.FIR( [ 0.000340537652720,   0.000681075305440 ,  0.000340537652720 ] ) 
        |> Processors.FIR( [ 1,2,1 ] )
        |> Processors.FIR( [ 1,2,1 ] ) 
        |> Processors.IIR_poles( [ 1.000000000000000,  -1.032069405319713,   0.275707942472945 ] )
        |> Processors.IIR_poles( [ 1.000000000000000,  -1.142980502539899,   0.412801598096187 ] )
        |> Processors.IIR_poles( [ 1.000000000000000,  -1.404384890471582,   0.735915191196472 ] )
)

sys = sys_butt6
# sys = Processors.IIR_poles( [ 1.0, -0.9 ] )
f = range( 0.0001, 0.9999; length = 997 )

r9dB  = ProcSeqs.freqzdB( sys , f )
r9deg = ProcSeqs.freqphasedegrees( sys , f )
r9dly = ProcSeqs.freqz_grpdelay( sys, f )

sys = sys_butt6 |> Processors.Downsample(2) |> sys_butt6
r10dB  = ProcSeqs.freqzdB( sys , f )
r10deg = ProcSeqs.freqphasedegrees( sys , f )
r10dly = ProcSeqs.freqz_grpdelay( sys, f )


int1 = Processors.IIR_poles( [ 1, -1 ] )
diff1 = Processors.FIR( [ 1, -1 ] )

# CIC terminology:
# r = decimation ratio
# n = order

r = 8
n = 4

sys = int1^n |> Processors.Downsample(r) |> diff1^n
r11dB  = ProcSeqs.freqzdB( sys , f )
r11deg = ProcSeqs.freqphasedegrees( sys , f )
r11dly = ProcSeqs.freqz_grpdelay( sys, f )
r11_impulse = impulse |> sys |> collect

sys = Processors.FIR( ones(Int,r) )^n
r12dB  = ProcSeqs.freqzdB( sys , f )
r12deg = ProcSeqs.freqphasedegrees( sys , f )
r12dly = ProcSeqs.freqz_grpdelay( sys, f )
r12_impulse = impulse |> sys |> Processors.Downsample(r) |> collect

p = Processors.VectorProcessor{Float64}( [ Processors.Delay(1), Processors.Delay(0) ] )
v = [ 1.0, 1.0]

y,states = Processors.process( p, v )
y,states = Processors.process( p, v, states )

impulse = [ 0, 0, 1, 0, 0, 0]

n = 4

p1 = Processors.VectorProcessor{Float64}( [ Processors.Delay(i) for i in n-1:-1:0 ] )
p2 = Processors.VectorProcessor{Float64}( [ Processors.Delay(i) for i in   0: n-1 ] )

# y0 = impulse |> Processors.MapT{ Vector{Float64} }( x->[x,x] ) |> p |> collect
y0 = impulse |> Processors.MapT{ Vector{Float64} }( x->fill(x,n) ) |> p1 |> collect
y1 = impulse |> Processors.Vectorize(n) |> (x->collect(Vector,x))

y0 == y1
 
rnd = [ rand( 0:10 ) for x in 1:10 ]



# want to make p2 type reformatter take a vector of inputs
# and make the appropriate length incremental delay processor automatically

sys = (
           Processors.MapT{ Vector{Float64} }( x->fill(x,n) ) 
        |> p1 
        |> Processors.Downsample(n,n-1)
        |> Processors.Upsample(n)
        |> p2
        |> Processors.MapT{Float64}( sum )
)

1:20 |> sys |> collect


include( "env.jl")

using Test
using Plots # convenience for interactive dev

import Sequences
import Processors
import ProcSeqs

impulse = [ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]

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
f = range( 0.0001, 1.0; length = 1000 )

r9dB  = ProcSeqs.freqzdB( sys , f )
r9deg = ProcSeqs.freqphasedegrees( sys , f )
r9dly = ProcSeqs.freqz_grpdelay( sys, f )

sys = sys_butt6 |> Processors.Downsample(2) |> sys_butt6
r10dB  = ProcSeqs.freqzdB( sys , f )
r10deg = ProcSeqs.freqphasedegrees( sys , f )
r10dly = ProcSeqs.freqz_grpdelay( sys, f )


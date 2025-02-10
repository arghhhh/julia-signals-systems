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

sys = Processors.ForwardFeedback( Processors.Gain(1), Processors.Gain(-0.99) )

f = logrange( 0.0001, 0.5; length = 1000 )
r4dB  = ProcSeqs.freqzdB( sys , f )
r4deg = ProcSeqs.freqphasedegrees( sys , f )

sys = Processors.FIR( [ 0, 1 ] )
r4dB  = ProcSeqs.freqzdB( sys , f )
r4deg = ProcSeqs.freqphasedegrees( sys , f )

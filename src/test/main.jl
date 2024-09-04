

include( "env.jl")

# bring the following names into scope:
import Sequences
import Processors

Sequences.Test_Range(10) |> Sequences.info
Sequences.Test_Range(10) |> collect

Sequences.Test_Range(50) |> Processors.Downsample(5) |> Sequences.info

# check that length calculation looks OK for a range of input lengths:
Sequences.Test_Range(50) |> Processors.Downsample(5) |> collect
Sequences.Test_Range(51) |> Processors.Downsample(5) |> collect
Sequences.Test_Range(52) |> Processors.Downsample(5) |> collect
Sequences.Test_Range(53) |> Processors.Downsample(5) |> collect
Sequences.Test_Range(54) |> Processors.Downsample(5) |> collect
Sequences.Test_Range(55) |> Processors.Downsample(5) |> collect
Sequences.Test_Range(56) |> Processors.Downsample(5) |> collect

Sequences.Test_Range(4) |> Processors.Upsample(4)  |> collect



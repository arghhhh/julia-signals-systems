# julia-signals-systems
Using Julia to model DSP signals and systems efficiently with reusable and composable system blocks.

Julia iterators provide a convenient means for describing sampled-data signals used in digital signal processors.
This work builds on this and describes a simple means of composing signal processing operations to describe a signal processing system independent of the applied input signal.

### Some terminology:

| DSP term  | more general term | Julia etc |
| ------- | ------------- | ------ |
| Signal  | sequence   | iterator   |
| System  | processor  | transducer |

## How is this different from functions operating on iterators that return iterators?

Julia already provides some functions that operate on iterators.  For example [Base.Iterators.map](https://docs.julialang.org/en/v1/base/iterators/#Base.Iterators.map) and [Base.Iterators.take](https://docs.julialang.org/en/v1/base/iterators/#Base.Iterators.take), but it is not possible to use these without also specifying the input iterator to act on.
For example this is not supported:

```julia
system = Base.Iterators.map( x->x^2 ) |> Base.Iterators.take(5)  # this does not work
```
To make this work, it would need to be written as:

```julia
system = sig -> Base.Iterators.map( x->x^2, sig ) |> sig -> Base.Iterators.take(sig,5)
```
which returns an anonymous function with a meaningless symbol name during debugging.

However, using this very simple framework, this is supported:

```julia
system = Processors.Map( x->x^2 ) |> Processors.Take(5)
y = 1:10 |> system |> collect
```

giving:

```
5-element Vector{Int64}:
  1
  4
  9
 16
 25
```

This could also be achieved using [Transducers.jl](https://juliafolds.github.io/Transducers.jl/dev/) but transducers are more general and harder to comprehend. The heart of this functionality is the few lines of code in [src/Processors/processor.jl](src/Processors/processor.jl).  The rest of repository contains example processors and also some signal generators.

## Overview of Provided System Blocks

upsample, downsample, take, map, flatten, SlidingWindow etc

## Example building up high order running sum filters

## Non-Signal-Processing examples



A version of this was presented at [OrConf 2024](
https://fossi-foundation.org/orconf/2024#digital-signal-processing-modeling-with-julia
) - [Slides](
https://drive.google.com/file/d/1xa5Qo3rNUa1yPdEiyER2-X_EuIClHvdp/view?usp=sharing
) - [YouTube](
https://youtu.be/507sU2NTNjs
).


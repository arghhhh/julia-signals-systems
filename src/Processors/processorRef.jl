

# add all processor behavior to Base.RefValue{Processor} 

# this is a copy of processor.jl
# with all mentions of Processor changed to Base.RefValue{Processor} 
# if a function does not use the Processor, then it does not need to be repeated here
# need to add any other functions that user adds externally - eg iterate() has been added at the bottom of this

## abstract type abstract_processor end
## 
## # this defines the iterator formed by applying "in" to the the processor "p":
## struct Apply{Iter,Processor}
##         in::Iter
##         p::Processor
## end
## 
## # this defines a composition of two processors:
## struct Compose{Processor1,Processor2} <: abstract_processor
##         p1::Processor1
##         p2::Processor2
## end
## 
## # the normal way to construct Apply{} and Compose{} is through pipe "|>" notation
## # which is converted to the parenthesis call operator in Julia
## # (Never define a "|>" implementation - that is unnecessary and breaks expectations)  
## 
## # all processors should be defined deriving from abstract_processor, so
## # if the argument is not an abstract_processor, it is assumed to be the source iterator
## (p2::abstract_processor)( p1::abstract_processor ) = Compose( p1, p2 )

(p2::Base.RefValue{P2})( p1::abstract_processor ) where { P2 <: abstract_processor } = Compose( p1, p2 )
(p2::abstract_processor)( p1::Base.RefValue{P1} ) where { P1 <: abstract_processor } = Compose( p1, p2 )
(p2::Base.RefValue{P2})( p1::Base.RefValue{P1} ) where { P1 <: abstract_processor, P2 <: abstract_processor } = Compose( p1, p2 )


## (p2::abstract_processor)( it                     ) = Apply(   it, p2 )
(p2::Base.RefValue{P2})( it                     ) where { P2 <: abstract_processor } = Apply(   it, p2 )

## 
## # this would be better, but would introduce Sequences as a dependency
## # it would allow things like (1 |> sys) where 1 would be promoted to an infinite length sequence
## # instead this must use this: ( Sequences.sequence(1) |> sys )
## # (p2::Processors.abstract_processor)( it ) = Processors.Apply(   Sequences.sequence(it), p2 )
## 
## 
## # a composed structure will be used, by applying an input iterator,
## # or composing with another processor:
## (c::Compose)( in                     ) = c.p2( c.p1( in ) )
## (c::Compose)( p1::abstract_processor ) = Compose( p1, c )
(c::Compose)( p1::Base.RefValue{P1} ) where { P1 <: abstract_processor } = Compose( p1, c )

## 
## # Could consider using ComposedFunction defined in julia/base/operators.jl​
## 
## 
## # add default versions of the optional and required functions for the iterator interface: 
## 
## # size related - by default, same as input:
## Base.IteratorSize(  ::Type{Apply{Iter,Processor}}) where {Iter,Processor} = Base.IteratorSize( Iter )
	
## Base.length(      it::     Apply{Iter,Processor} ) where {Iter,Processor} = Base.length( it )	                
Base.length(      it::     Apply{Iter,Base.RefValue{Processor}} ) where {Iter,Processor} = Base.length( Apply(it.in,it.p[])  )              

## Base.size(        it::     Apply{Iter,Processor} ) where {Iter,Processor} = Base.size(   it )
Base.size(        it::     Apply{Iter,Base.RefValue{Processor}} ) where {Iter,Processor} = Base.size(  Apply(it.in,it.p[])  )
## 
## # eltype related - by default, same as the input:
## Base.IteratorEltype(::Type{Apply{Iter,Processor}}) where {Iter,Processor} = Base.IteratorEltype( Iter )

## #Base.eltype(        ::Type{Apply{Iter,Processor}}) where {Iter,Processor} = Base.eltype( Iter )
Base.eltype( ::Type{Apply{Iter,Base.RefValue{P}}}) where {Iter,P} = Base.eltype( Apply{Iter,P} )


## 
## # isdone - required when the input iterator is stateful - 
## Base.isdone(      it::     Apply{Iter,Processor} ) where {Iter,Processor} = Base.isdone(   it )	
## Base.isdone(      it::     Apply{Iter,Processor}, state ) where {Iter,Processor} = Base.isdone(   it , state )	
## 



Base.iterate( it::Apply{Iter,Base.RefValue{P} } ) where {Iter,P} = Base.iterate( Apply( it.in, it.p[] ) )
Base.iterate( it::Apply{Iter,Base.RefValue{P} }, state ) where {Iter,P} = Base.iterate( Apply( it.in, it.p[] ), state )



#=

# some test and debugging stuff used to develop this:

I = Ref( Processors.Integrator(2.0) )

@show 1:10 |> I |> size
@show 1:10 |> I |> length
@show 1:10 |> I |> collect
@show 1:10 |> I |> I |> collect
@show 1:10 |> ( I |> I ) |> collect

I[].gain = 1.0
@show 1:10 |> ( I |> I ) |> collect


@show eltype(  1:10 |> Processors.Integrator(2) )
@show eltype(  1:10 |> I )



=#

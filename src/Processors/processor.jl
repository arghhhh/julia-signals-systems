
abstract type abstract_processor end

# this defines the iterator formed by applying "in" to the the processor "p":
struct Apply{Iter,Processor}
        in::Iter
        p::Processor
end

# this defines a composition of two processors:
struct Compose{Processor1,Processor2} <: abstract_processor
        p1::Processor1
        p2::Processor2
end

# the normal way to construct Apply{} and Compose{} is through pipe "|>" notation
# which is converted to the parenthesis call operator in Julia
# (Never define a "|>" implementation - that is unnecessary and breaks expectations)  

# all processors should be defined deriving from abstract_processor, so
# if the argument is not an abstract_processor, it is assumed to be the source iterator
(p2::abstract_processor)( p1::abstract_processor ) = Compose( p1, p2 )
(p2::abstract_processor)( it                     ) = Apply(   it, p2 )

# this would be better, but would introduce Sequences as a dependency
# it would allow things like (1 |> sys) where 1 would be promoted to an infinite length sequence
# instead this must use this: ( Sequences.sequence(1) |> sys )
# (p2::Processors.abstract_processor)( it ) = Processors.Apply(   Sequences.sequence(it), p2 )


# a composed structure will be used, by applying an input iterator,
# or composing with another processor:
(c::Compose)( in                     ) = c.p2( c.p1( in ) )
(c::Compose)( p1::abstract_processor ) = Compose( p1, c )

# Could consider using ComposedFunction defined in julia/base/operators.jl​


# add default versions of the optional and required functions for the iterator interface: 

# size related - by default, same as input:
Base.IteratorSize(  ::Type{Apply{Iter,Processor}}) where {Iter,Processor} = Base.IteratorSize( Iter )	
Base.length(      it::     Apply{Iter,Processor} ) where {Iter,Processor} = Base.length( it )	                
Base.size(        it::     Apply{Iter,Processor} ) where {Iter,Processor} = Base.size(   it )

# eltype related - by default, same as the input:
Base.IteratorEltype(::Type{Apply{Iter,Processor}}) where {Iter,Processor} = Base.IteratorEltype( Iter )
Base.eltype(        ::Type{Apply{Iter,Processor}}) where {Iter,Processor} = Base.eltype( Iter )  

# isdone - required when the input iterator is stateful - 
Base.isdone(      it::     Apply{Iter,Processor} ) where {Iter,Processor} = Base.isdone(   it )	
Base.isdone(      it::     Apply{Iter,Processor}, state ) where {Iter,Processor} = Base.isdone(   it , state )	

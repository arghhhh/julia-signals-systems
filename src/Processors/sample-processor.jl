


# to define a processor which produces one and only one output per input,
# define the processor as a struct P
# and deine the functions process( p::P, x        ) returning y,next_state
#                   and   process( p::P, x, state ) returning y,next_state


abstract type SampleProcessor <: abstract_processor
end


# functions dependent on the type only
Base.IteratorEltype(::Type{Apply{I,P}}) where {I,P<:SampleProcessor} = Base.IteratorEltype(I)
Base.IteratorSize(  ::Type{Apply{I,P}}) where {I,P<:SampleProcessor} = Base.IteratorSize(I)

# functions dependent on the instance:
#       eltype by default is the same as the input - override with specific version if necessary
Base.eltype( ::Type{ Apply{I,P} } ) where {I,P<:SampleProcessor} = begin
        @show I P Base.eltype( I )
        Base.eltype( I )
end
Base.length( a::Apply{I,P}) where {I,P<:SampleProcessor} = Base.length(a.in)
Base.size(   a::Apply{I,P}) where {I,P<:SampleProcessor} = Base.size(  a.in)

# first call to iterate:
function Base.iterate(it::Apply{I,P} ) where {I,P<:SampleProcessor}

@show it

	# get the input:
	t = Base.iterate(it.in )
	t === nothing && return nothing
	x,input_state = t

@show x input_state

	# initialize processor state and get first output:
	y,next_state = process( it.p, x )

@show next_state y

	# return output and the combined state for next time
	return y, (input_state,next_state)
end

# subsequent calls to iterate:
function Base.iterate(it::Apply{I,P}, state ) where {I,P<:SampleProcessor}
	# separate the combined state into 
	# the input iterator state and the processor state:
	input_state,state = state

	# get the input:
	t = Base.iterate(it.in, input_state )
	t === nothing && return nothing
	x,input_state = t

	# calculate next processor state and current output
        y,next_state = process( it.p, x, state )

         # return output and the combined state for next time
         return y, (input_state,next_state)
end

# could have a specialized version of composition for two SampleProcessors that is also a SampleProcessor
# (Normal processor composition is just a placeholder waiting for an applied seuqence)


# --------------------------------

# this defines a composition of two processors:
struct Compose1{Processor1,Processor2} <: SampleProcessor
        p1::Processor1
        p2::Processor2
end

# the normal way to construct Apply{} and Compose{} is through pipe "|>" notation
# which is converted to the parenthesis call operator in Julia
# (Never define a "|>" implementation - that is unnecessary and breaks expectations)  

# all processors should be defined deriving from abstract_processor, so
# if the argument is not an abstract_processor, it is assumed to be the source iterator
(p2::SampleProcessor)( p1::SampleProcessor ) = Compose1( p1, p2 )

# this would be better, but would introduce Sequences as a dependency
# it would allow things like (1 |> sys) where 1 would be promoted to an infinite length sequence
# instead this must use this: ( Sequences.sequence(1) |> sys )
# (p2::Processors.abstract_processor)( it ) = Processors.Apply(   Sequences.sequence(it), p2 )


# a composed structure will be used, by applying an input iterator,
# or composing with another processor:
#(c::Compose1)( in                     ) = c.p2( c.p1( in ) )
(c::Compose1)( p1::SampleProcessor ) = Compose1( p1, c )


# --------------------------------



# ambiguious whether

#  ( fir + 1 ) means add the constant sequence one
#              or add the input to the ouput of the filter

# fir + Sequences.Sequence(1) 
# fir + 1 



#  


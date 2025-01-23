


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
Base.eltype( a::Apply{I,P}) where {I,P<:SampleProcessor} = Base.eltype( a.in )
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



# ambiguious whether

#  ( fir + 1 ) means add the constant sequence one
#              or add the input to the ouput of the filter

# fir + Sequences.Sequence(1) 
# fir + 1 

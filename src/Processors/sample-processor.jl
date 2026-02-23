

# to define a processor which produces one and only one output per input,
# define the processor as a struct P
# and define the functions process( p::P, x        ) returning y,next_state
#                   and    process( p::P, x, state ) returning y,next_state
# The size of the output is the same as that of the input
# The eltype is by default, the same as the input.
# This default can be overriden by defining 
#     Base.eltype( ::Type{Apply{I,P}})
# as usual.  There is a helper struct SeqT that exists to help define eltype
# and process(..) when the input type is known. 

# having a processor category that always produces one and only one output 
# for each input makes it possible to easily define processors that combine other 
# processors in parallel - eg adding/subtracting processors, or have a vector of 
# processors act on a vector input



# TODO:
# look into allowing having a single function for both initial sample and subsequent samples
# have a default implementation of two argument process( ) that calls the three argument version with state=nothing
# - if this can be done efficiently, then it removes a lot of cut'n'paste duplication - eg in carfac model


abstract type SampleProcessor <: abstract_processor
end


# functions dependent on the type only
# Base.IteratorEltype(::Type{Apply{I,P}}) where {I,P<:SampleProcessor} = Base.IteratorEltype(I)
Base.IteratorEltype(::Type{Apply{I,P}}) where {I,P<:SampleProcessor} = Base.EltypeUnknown()

 

Base.IteratorSize(  ::Type{Apply{I,P}}) where {I,P<:SampleProcessor} = Base.IteratorSize(I)

# functions dependent on the instance:
#       eltype by default is the same as the input - override with specific version if necessary
Base.eltype( ::Type{ Apply{I,P} } ) where {I,P<:SampleProcessor} = begin
 #       @show I P Base.eltype( I )
        Base.eltype( I )
end
Base.length( a::Apply{I,P}) where {I,P<:SampleProcessor} = Base.length(a.in)
Base.size(   a::Apply{I,P}) where {I,P<:SampleProcessor} = Base.size(  a.in)

# first call to iterate:
function Base.iterate(it::Apply{I,P} ) where {I,P<:SampleProcessor}

#@show it

	# get the input:
	t = Base.iterate(it.in )
	t === nothing && return nothing
	x,input_state = t

#@show x input_state

	# initialize processor state and get first output:
	y,next_state = process( it.p, x )

#@show next_state y

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


## Don't do this - conflicts with the use of P1( Seq ) === Seq |> P1
#      but should define a simpler type level function
#  eg process_type( p::SampleProcessor, ::Type{Tin} ) = T_out
## 
## # define a stateless process as a special case of SampleProcessor
## # where the state is initialized as nothing and is not used, and 
## # use the struct as a 
## #   https://docs.julialang.org/en/v1/manual/methods/#Function-like-objects
## # where the function is expected to also operate on a ::Type arg to give the return type
## abstract type StatelessProcessor <: SampleProcessor
## end
## process( p::P, x, state=nothing ) where {P<:StatelessProcessor} = p(x),state
## Base.eltype( ::Type{ Apply{I,P} }) where {I,P<:StatelessProcessor} = p( base.eltype(I) )
## 
## 
## 


# --------------------------------


# minimal type level "sequence" - that returns an eltype of T
# there is no iteration implementation, so can't be used for anything 
# other than calculating other eltypes:
struct SeqT{T}
end
Base.eltype( ::Type{ SeqT{T}} ) where {T} = T



# this defines a composition of two processors:
struct Compose1{Processor1,Processor2} <: SampleProcessor
        p1::Processor1
        p2::Processor2
end

function process( sys::Compose1{Processor1,Processor2}, x ) where {Processor1,Processor2}
	p1_y,p1_state = process( sys.p1, x    )
	p2_y,p2_state = process( sys.p2, p1_y )
	return p2_y, (p1_state,p2_state)
end
function process( sys::Compose1{Processor1,Processor2}, x, state ) where {Processor1,Processor2}
	p1_state,p2_state = state
	p1_y,next_p1_state = process( sys.p1, x    , p1_state )
	p2_y,next_p2_state = process( sys.p2, p1_y , p2_state )
	return p2_y, (next_p1_state,next_p2_state)
end
Base.eltype( ::Type{Apply{I,Compose1{Processor1,Processor2}}}) where {I,Processor1,Processor2} = begin
        Base.eltype( Apply{ SeqT{Base.eltype( Apply{I,Processor1} )}, Processor2 } )
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
(c::Compose1)( p1::abstract_processor ) = Compose( p1, c )

(c::Compose1)( in                  ) = c.p2( c.p1( in ) )




# --------------------------------



# ambiguious whether

#  ( fir + 1 ) means add the constant sequence one
#              or add the input to the ouput of the filter

# fir + Sequences.Sequence(1) 
# fir + 1 

# this ambiguity resoved by defaulting to treating constant numbers as infinite length sequences
# Use Gain() or similar to add a parallel path

#  





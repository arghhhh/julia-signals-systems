


struct Vectorize <: abstract_processor
	n::Int
end

Base.IteratorSize( ::Type{ Apply{T_iter,Vectorize} } ) where { T_iter } = Base.IteratorSize( T_iter )
Base.length(  a::Apply{T_iter,Vectorize} ) where { T_iter } = Base.length(a.in)
Base.size(  a::Apply{T_iter,Vectorize} ) where { T_iter } = Base.size(a.in)
Base.eltype( ::Type{ Apply{T_iter,Vectorize} } ) where { T_iter }  = begin
#	@show a
#	@show AbstractArray{Base.eltype(a.in), 1} 
	AbstractArray{Base.eltype(T_iter), 1}   
end



# Vectorize has state:
# a vector and the current index
# the state is mutated.  This is pretty much a requirement for efficiency 
# - don't want to reallocating memory for every element

# this allows zero to be defined for existing types which don't have zero() already defined
# - eg tuples
vectorize_zero( t ) = zero(t)


# TODO: variant that eliminates the zero problem by initializing with collect
# This will form the first ouput from the first n inputs and then proceed 
# to produce one sample out for each input
# so the output length will be input (length - n + 1 )

function Base.iterate( a::Apply{T_iter,Vectorize} ) where { T_iter }

	i = Base.iterate( a.in )
	if i === nothing
		return nothing
	end
	(input_val, input_state) = i

	# create the Vectorize state
	state_v = [ zero(input_val) for i in 1 : 2 * a.p.n ]

	# do the first operation:
	state_i = a.p.n 
	state_v[ state_i         ] = input_val
	state_v[ state_i + a.p.n ] = input_val

	y = view( state_v , state_i+1:state_i+a.p.n )
	state = ( input_state, state_i, state_v )

	return ( y, state )
end

function Base.iterate( a::Apply{T_iter,Vectorize}, state ) where { T_iter }
	input_state, state_i, state_v = state

	i = Base.iterate( a.in, input_state )
	if i === nothing
		return nothing
	end
	(input_val, input_state) = i

	# do the operation:
	state_i = ( state_i < a.p.n ) ? state_i + 1 : 1
	state_v[ state_i         ] = input_val
	state_v[ state_i + a.p.n ] = input_val

	y = view( state_v , state_i+1:state_i+a.p.n )
	state = ( input_state, state_i, state_v )

	return ( y, state )
end




struct Serialize <: abstract_processor
end

# the size is unknown,because the vector length is unknown from just the type:
# TODO: consider using StaticArrays
Base.IteratorSize( ::Type{ Apply{T_iter,Serialize} } ) where { T_iter } = Base.SizeUnknown()
#Base.length(  a::Apply{T_iter,Serialize} ) where { T_iter } = Base.length(a.in)
#Base.size(  a::Apply{T_iter,Serialize} ) where { T_iter } = Base.size(a.in)
Base.eltype( ::Type{ Apply{T_iter,Serialize} } ) where { T_iter }  = Base.eltype( Base.eltype(T_iter) )



# Serialize has state:
# the vector that is being worked on
# index 


function Base.iterate( a::Apply{T_iter,Serialize} ) where { T_iter }

	i = Base.iterate( a.in )
	if i === nothing
		return nothing
	end
	(input_val, input_state) = i

	# create the Serialize state
	state_v = input_val
	state_i = firstindex( state_v )

	state = input_state, state_v, state_i

	# now just use the general index version with the inditialized state:
	return Base.iterate( a, state )
end

function Base.iterate( a::Apply{T_iter,Serialize}, state ) where { T_iter }
	input_state, state_v, state_i = state

	if !checkbounds( Bool, state_v, state_i )
		# need new input:
		i = Base.iterate( a.in, input_state )
		if i === nothing
			return nothing
		end
		(input_val, input_state) = i
		state_v = input_val
		state_i = firstindex( state_v)
	end

	y = state_v[ state_i ]
	state_i = Base.nextind( state_v, state_i )
	state = input_state, state_v, state_i

	return y, state
end


# variant that allows the indices to be specified:
struct SerializeInd <: abstract_processor
	ind  # indices to use
	SerializeInd() = new( : )
end

# TBD


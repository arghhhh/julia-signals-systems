


struct SlidingWindow <: abstract_processor
	n::Int
end

Base.IteratorSize( ::Type{ Apply{T_iter,SlidingWindow} } ) where { T_iter } = Base.IteratorSize( T_iter )
Base.length(  a::Apply{T_iter,SlidingWindow} ) where { T_iter } = max( 0, Base.length(a.in) - a.p.n + 1 )
Base.size(  a::Apply{T_iter,SlidingWindow} ) where { T_iter } = max( 0, Base.length(a.in) - a.p.n + 1 )
Base.eltype( a::Apply{T_iter,SlidingWindow} ) where { T_iter }  = begin
#	@show a
#	@show AbstractArray{Base.eltype(a.in), 1} 
	AbstractArray{Base.eltype(a.in), 1}   
end



# SlidingWindow has state:
# a vector and the current index
# the state is mutated.  This is pretty much a requirement for efficiency 
# - don't want to reallocating memory for every element


# This is a variant of Vectorize that eliminates the zero problem by initializing with collect
# This will form the first ouput from the first n inputs and then proceed 
# to produce one sample out for each input
# so the output length will be input (length - n + 1 )

function Base.iterate( a::Apply{T_iter,SlidingWindow} ) where { T_iter }

#	i = Base.iterate( a.in )
#	if i === nothing
#		return nothing
#	end
#	(input_val, input_state) = i
#
	# create the SlidingWindow state
#	state_v = [ zero(input_val) for i in 1 : 2 * a.p.n ]

        # now using a stateful version of the input iterator
        # to make it easier to use collect (which will determine the element type automatically)
        # and then to pick up the rest of the input in future iterations

        it = Base.Iterators.Stateful( a.in )
        # Base version of Take is OK here - reducing dependencies by not using redefined version
        state_v = collect( Base.Iterators.Take( it, a.p.n) )
        length( state_v ) < a.p.n && return nothing
        resize!( state_v, 2 * a.p.n )

	state_i = 0 

	y = view( state_v , state_i+1:state_i+a.p.n )
	state = ( it, state_i, state_v )

	return ( y, state )
end

function Base.iterate( a::Apply{T_iter,SlidingWindow}, state ) where { T_iter }
	input_state, state_i, state_v = state

	i = Base.iterate( input_state )
	if i === nothing
		return nothing
	end
	input_val = i[1]

	# do the operation:
	state_i = ( state_i < a.p.n ) ? state_i + 1 : 1
	state_v[ state_i         ] = input_val
	state_v[ state_i + a.p.n ] = input_val

	y = view( state_v , state_i+1:state_i+a.p.n )
	state = ( input_state, state_i, state_v )

	return ( y, state )
end

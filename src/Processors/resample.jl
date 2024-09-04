



struct Downsample <: abstract_processor
	n::Int
	initial_phase::Int

	Downsample( n, initial_phase = 0 ) = new( n, initial_phase )
end

Base.IteratorSize( ::Type{Apply{T_iter,Downsample}} ) where { T_iter } = Base.IteratorSize(T_iter) == Base.HasShape{1}() ? Base.HasLength() : Base.IteratorSize(T_iter)
Base.length( a::Apply{T_iter,Downsample} ) where { T_iter } = div( length(a.in) + a.p.n - a.p.initial_phase - 1, a.p.n )
Base.size( a::Apply{T_iter,Downsample} ) where { T_iter } = ( Base.length( a ), )
Base.eltype( ::Type{Apply{T_iter,Downsample}} ) where { T_iter }  = Base.eltype( T_iter )

function Base.iterate( a::Apply{T_iter,Downsample} ) where { T_iter }

	# Downsample needs no state of its own, so state is just the input state:

	local input_val
	local input_state
	
	it = Base.iterate( a.in )
	if it === nothing
		return nothing
	end
	(input_val, input_state ) = it

	for i in 1:a.p.initial_phase
		it = Base.iterate( a.in, input_state )
		if it === nothing
			return nothing
		end
		(input_val, input_state ) = it                
	end

	y = input_val
	return ( y, input_state )
end

function Base.iterate( a::Apply{T_iter,Downsample}, input_state1 ) where { T_iter }

	local input_val
	local input_state = input_state1
	for i in 1:a.p.n
		it = Base.iterate( a.in, input_state )
		if it === nothing
			return nothing
		end
		(input_val, input_state ) = it                
	end
	return ( input_val, input_state )
end



# Two types of upsampling:
# 1.  Upsample     : zero insertion - requires zero( eltype ) to be defined
# 2.  Upsamplehold : repeat the input an additional n-1 times for each input sample


struct Upsample <: abstract_processor
	n::Int
end

Base.IteratorSize( ::Type{Apply{T_iter,Upsample}} ) where { T_iter } = Base.IteratorSize(T_iter ) 
Base.eltype( a::Type{Apply{T_iter,Upsample}} ) where { T_iter } = Base.eltype( T_iter )
Base.length( a::Apply{T_iter,Upsample} ) where { T_iter } = length(a.in) * a.p.n


function Base.iterate( a::Apply{T_iter,Upsample} ) where { T_iter }
	
	i = Base.iterate( a.in )
	if i === nothing
		return nothing
	end
	
	(input_val, input_state) = i
	upsample_state = a.p.n - 1 

	y = input_val
	return ( y, (input_state,upsample_state ) )
end

function Base.iterate( a::Apply{T_iter,Upsample}, input_state_upsample_state ) where { T_iter }

	(input_state,upsample_state) = input_state_upsample_state

	y = zero( Base.eltype(a.in) )
	upsample_state_next = upsample_state - 1
	if upsample_state == 0
		upsample_state_next = a.p.n-1
		next = Base.iterate( a.in, input_state )
		if next === nothing
			return nothing
		end
		(y, input_state) = next
	end        

	return ( y, (input_state,upsample_state_next) )
end

struct Upsamplehold <: abstract_processor
	n::Int
end

Base.IteratorSize( ::Type{Apply{T_iter,Upsamplehold}} ) where { T_iter } = Base.IteratorSize(T_iter ) 
Base.eltype( a::Type{Apply{T_iter,Upsamplehold}} ) where { T_iter } = Base.eltype( T_iter )
Base.length( a::Apply{T_iter,Upsamplehold} ) where { T_iter } = length(a.in) * a.p.n

function Base.iterate( a::Apply{T_iter,Upsamplehold} ) where { T_iter }

	# this function creates the input state and the decimator_state
	# and returns the these with the first output
	
	i = Base.iterate( a.in )
	if i === nothing
		return nothing
	end
	
	(input_val, input_state) = i
	y = input_val
	
	upsamplehold_state = ( a.p.n-1, y )

	return ( y, (input_state,upsamplehold_state ) )
end

function Base.iterate( a::Apply{T_iter,Upsamplehold}, input_state_upsamplehold_state ) where { T_iter }

	(input_state,upsamplehold_state) = input_state_upsamplehold_state

	count,y = upsamplehold_state

	upsamplehold_state_next = ( count - 1, y )
	if count == 0
		next = Base.iterate( a.in, input_state )
		if next === nothing
			return nothing
		end
		(y, input_state) = next
		upsamplehold_state_next = ( a.p.n-1, y )
	end        

	return ( y, (input_state,upsamplehold_state_next) )
end





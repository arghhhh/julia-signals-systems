


struct Vectorize <: abstract_processor
        n::Int
end

Base.IteratorSize( ::Type{ Apply{T_iter,Vectorize} } ) where { T_iter } = Base.IteratorSize( T_iter )
Base.length(  a::Apply{T_iter,Vectorize} ) where { T_iter } = Base.length(a.in)
Base.size(  a::Apply{T_iter,Vectorize} ) where { T_iter } = Base.size(a.in)
Base.eltype( ::Type{Apply{T_iter,Vectorize}}  ) where { T_iter }  = AbstractArray{Base.eltype(T_iter), 1}   



# Vectorize has state:
# a vector and the current index
# the state is mutated.  This is pretty much a requirement for efficiency 
# - don't want to reallocating memory for every element

# this allows zero to be defined for existing types which don't have zero() already defined
# - eg tuples
vectorize_zero( t ) = zero(t)

function Base.iterate( a::Apply{T_iter,Vectorize} ) where { T_iter }

        # input related:
        i = Base.iterate( a.in )
        if i === nothing
                return nothing
        end
        (input_val, input_state) = i

        # create the Vectorize state
        # delay line could be length 2 * (a.p.n-1) - but I think making it more regular is better
        # - eg consider the case where you are collecting large 0% overlap FFT records
        #      the usage would gradually rotate instead of alternating ping-pong style
  #      state_i = 1
 #       state_v =  zeros( eltype( a.in ), 2 * a.p.n )
        state_v = [ vectorize_zero( eltype( T_iter ) ) for i in 1 : 2 * a.p.n ]

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

        # input related:
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
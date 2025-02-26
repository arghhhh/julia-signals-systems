

struct Identity <: SampleProcessor; end

process( id::Identity, x, state=nothing ) = x,state




struct Convert{T} <: SampleProcessor
end

process( p::Convert{T}, x, state=nothing ) where {T} = Base.convert(T,x),state
Base.eltype( ::Type{ Apply{I,Convert{T}} }) where {I,T} = T


# this is a simple implementation of an FIR filter
# it moves the delay line contents every sample (ie not efficient)

struct FIR{T} <: SampleProcessor
        coeffs::Vector{T}
end

process( p::FIR{T}, x, state=zeros(typeof(x),length(p.coeffs) ) ) where {T} = begin
        next_state = [ x, state[1:end-1]... ]
        y = LinearAlgebra.dot( next_state, p.coeffs )
        @show x state next_state y
        println()
        return y,next_state
end

Base.eltype( ::Type{ Apply{I,FIR{T}} } ) where {I,T} = Base.promote_op( *, Base.eltype( Base.eltype(I) ),T)






# minimal type level "sequence" - that returns an eltype of T
# there is no iteration implementation, so can't be used for anything 
# other than calculating other eltypes:
struct SeqT{T}
end
Base.eltype( ::Type{ SeqT{T}} ) where {T} = T





struct IIR_poles{T} <: SampleProcessor
        coeffs::Vector{T}
#        function IIR_poles( coeffs )
#                @assert isone(coeffs[1])
#                new{T}( coeffs )
#        end
end

# unlike FIR where the state is the same type as the input,
# the poles need to store state in the output type:
process( p::IIR_poles{T}, x ) where {T} = begin
        # check that first coefficient is one
        # the time domain algorithm assumes that it is one (for efficiency)
        # so its upto the caller to ensure that this assertion doesn't fire
        @assert isone(p.coeffs[1])
        @show SeqT{typeof(x)}
        @show Apply{ SeqT{typeof(x) }, IIR_poles{T} }
        @show p Base.eltype( Apply{ SeqT{typeof(x) }, IIR_poles{T} } )
        state=zeros( Base.eltype( Apply{ SeqT{typeof(x) }, IIR_poles{T} } ) ,length(p.coeffs) - 1 )
        return process( p, x, state )
end
process( p::IIR_poles{T}, x, state ) where {T} = begin
        y1 = LinearAlgebra.dot( state, p.coeffs[2:end] )
        y = x - y1
        next_state = [ y, state[1:end-1]... ]
        @show x state next_state y
        println()
        return y,next_state
end

Base.eltype( ::Type{ Apply{I,IIR_poles{T}} } ) where {I,T} = Base.promote_op( *, Base.eltype( Base.eltype(I) ),T)







struct ForwardFeedback{B,A} <: SampleProcessor
        forward::B
        reverse::A
end

process( p::ForwardFeedback{B,A}, x ) where {B,A} = begin
        yzm1 = zero( eltype( Apply{SeqT{typeof(x)},ForwardFeedback{B,A}} ) )

        a_out, next_a_state = process( p.reverse, yzm1 )
        b_in  = x - a_out
        y, next_b_state = process( p.forward, b_in )

        next_state = y,next_b_state,next_a_state

        return y,next_state
end
process( p::ForwardFeedback{B,A}, x, state ) where {B,A} = begin
        yzm1, b_state, a_state = state
        
        a_out, next_a_state = process( p.reverse, yzm1, a_state )
        b_in  = x - a_out
        y, next_b_state = process( p.forward, b_in, b_state )

        next_state = y,next_b_state,next_a_state

        return y,next_state
end

function Base.eltype( ::Type{ Apply{I,ForwardFeedback{B,A}} } ) where {I,B,A} 
        T_x   = Base.eltype( I )
        T_y0  = Base.eltype( Apply{I,B} )
        T_fb0 = Base.eltype( Apply{SeqT{T_y0},A } )
        T_bin = Base.promote_op( -, T_x, T_fb0 )
        T_y1  = Base.eltype( Apply{SeqT{T_bin}, B} )

        # could possibly rerun the loop until type convergence 
        # and/or check that types are settled - but I think this is good enough
        # this is setting the output type to be that of the second output

        return T_y1
end


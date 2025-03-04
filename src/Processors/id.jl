

struct Identity <: SampleProcessor; end

process( id::Identity, x, state=nothing ) = x,state

struct Delay1 <: SampleProcessor; end
process( ::Delay1, x, state=zero(x) ) = state,x

struct Delay <: SampleProcessor
        n::Int
end
process( p::Delay, x, state=(1,zeros(typeof(x), p.n)) ) = begin
        i,v = state

        if p.n == 0 
                # no delay - special case, don't use vector state at all:
                return x,state
        end

        y = v[i]
	v[ i ] = x

	i_next = ( i < p.n ) ? i + 1 : 1
        next_state = i_next,v

        return y,next_state
end


delay_state( x, v, i ) = begin
        if length(v) < 1 
                return x,v,i
        end
        y = v[i]
        v[i] = x
        i = i < length(v) ? i + 1 : 1
        return y, v, i
end



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

# for now at least - force user to explicity specify output eltype
struct VectorProcessor{T} <: SampleProcessor
        p::Vector{SampleProcessor}
end
process( p::VectorProcessor{T}, v ) where {T} = begin
        n = length(v)
        states  = Vector( undef, n )
        ys      = zeros(      T, n )
        for i = eachindex( p.p )
                ys[i],states[i] = process( p.p[i], v[i] )
        end
        return ys, states
end
process( p::VectorProcessor{T}, v, states ) where {T} = begin
        n  = length(v)
        ys = zeros(      T, n )
        for i = eachindex( p.p )
                ys[i],states[i] = process( p.p[i], v[i], states[i] )
        end
        return ys, states
end


# the only difference between Delays1 and Delays2 is the ordering of the delays is reversed
# so they both are very similar and commonality factored out into process_delays

struct Delays1 <: SampleProcessor ; end
struct Delays2 <: SampleProcessor ; end

process( p::Delays1, v ) = begin
        n = length(v)
        state_v  = [ zeros(eltype(v), i ) for i in n-1:-1:0 ]
        state_i  = ones( Int64, n )

        return process_delays( v, (state_v, state_i) )
end
process( p::Delays1, v, state ) = process_delays( v, state )

process( p::Delays2, v ) = begin
        n = length(v)
     #   state_v  = [ zeros(eltype(v), i ) for i in 0:n-1 ]
     # the above line doesn't work when eltype(v) is a Vector (the length is unknown)
     # so write it out like below
        state_v  = [ eltype(v)[ zero( v[j] ) for j in 1:i ]  for i in 0:n-1 ]
        state_i  = ones( Int64, n )

        return process_delays( v, (state_v, state_i) )
end
process( p::Delays2, v, state ) = process_delays( v, state )



process_delays( vx, states ) = begin
        (state_v, state_i) = states
   #     n  = length(vx)
        y = Vector{eltype(vx)}(undef,length(vx))
        for j in eachindex( state_v )
                y[j], state_v[j], state_i[j] = delay_state( vx[j], state_v[j], state_i[j] )
        end


        return y, (state_v,state_i)
end



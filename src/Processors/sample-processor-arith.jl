
struct Arith_ProcProc{OP, P1, P2} <: SampleProcessor
        lhs::P1
        rhs::P2

        function Arith_ProcProc{op}( a1::P1, b1::P2 ) where {op,P1<:SampleProcessor,P2<:SampleProcessor}
                new{op,P1,P2}(a1,b1)
        end

end

Base.:+( lhs::SampleProcessor , rhs::SampleProcessor ) = Arith_ProcProc{+}( lhs, rhs )
Base.:-( lhs::SampleProcessor , rhs::SampleProcessor ) = Arith_ProcProc{-}( lhs, rhs )


import Sequences

function Base.eltype( ::Type{ Apply{I,Arith_ProcProc{OP, P1, P2}} }) where {I,OP,P1,P2} 
        T_x  = Base.eltype( I )
        T_P1 = Base.eltype( Apply{I,P1} )
        T_P2 = Base.eltype( Apply{I,P2} )

        T_y  = Base.promote_op(OP,T_P1,T_P2)

   #     println( "In Base.eltype( ::Type{ Apply{I,Arith_ProcProc{OP, P1, P2}} }" )
   #     @show I OP P1 P2

   #     @show Apply{I,P1} Apply{I,P2} 
   #     @show T_x T_P1 T_P2 T_y

        return T_y
end


function process( p::Arith_ProcProc{OP, P1, P2}, x ) where {OP,P1,P2}
	y1,next_state1 = process( p.lhs, x )
	y2,next_state2 = process( p.rhs, x )
        y = (OP)( y1, y2 )
        next_state = ( next_state1, next_state2 )
	# return output and the combined state for next time
	return y, next_state
end  
function process( p::Arith_ProcProc{OP, P1, P2}, x, state ) where {OP,P1,P2}
        lhs_state,rhs_state = state
	y1,next_state1 = process( p.lhs, x, lhs_state )
	y2,next_state2 = process( p.rhs, x, rhs_state )
        y = (OP)( y1, y2 )
        next_state = ( next_state1, next_state2 )
	# return output and the combined state for next time
	return y, next_state
end 



struct Gain{T} <: SampleProcessor
        gain::T
end

function Base.eltype( ::Type{ Apply{I,Gain{T}} }) where {I,T} 
        T_x  = Base.eltype( I )
        T_y  = Base.promote_op(*,T_x,T)
   #     println( "In Base.eltype( ::Type{ Apply{I,Gain{T}} })" )
   #     @show I T
   #     @show T_x T_y
        return T_y
end

process( p::Gain{T}, x, state=nothing ) where{T} = p.gain * x, state


Base.:+( lhs::SampleProcessor , rhs::Number ) = Arith_ProcProc{+}( lhs, Gain(rhs) )
Base.:-( lhs::SampleProcessor , rhs::Number ) = Arith_ProcProc{-}( lhs, Gain(rhs) )
Base.:+( lhs::Number , rhs::SampleProcessor ) = Arith_ProcProc{+}( Gain(lhs), rhs )
Base.:-( lhs::Number , rhs::SampleProcessor ) = Arith_ProcProc{-}( Gain(lhs), rhs )


Base.:*( lhs::Number , rhs::SampleProcessor ) = Processors.Compose1( Gain(lhs), rhs )
# assuming commutivity of * when applied on the next line:
Base.:*( lhs::SampleProcessor , rhs::Number ) = Processors.Compose1( Gain(rhs), lhs )
# assuming reciprocal etc below:
Base.:/( lhs::SampleProcessor , rhs::Number ) = Processors.Compose1( Gain(1/rhs), lhs )

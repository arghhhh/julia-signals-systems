



# arithmetic between an iterator and a processor

# two variants - depending on the order - whether the LHS is the sequence or the processor

# the implementation uses the corresponding functions defined for arithmetic between two sequences

import Sequences
import Processors

# this is not allowed here, because this function has already been defined in processor.jl
# (p2::Processors.abstract_processor)( it ) = Processors.Apply(   Sequences.sequence(it), p2 )
# but these more explicit versions can be:
(p2::Processors.abstract_processor)( x::Number ) = Processors.Apply( Sequences.sequence(x), p2 )
(p2::Processors.abstract_processor)( x::Tuple  ) = Processors.Apply( Sequences.sequence(x), p2 )



struct Arith_SeqProc{OP, It, Sys} <: Processors.abstract_processor
        it::It
        sys::Sys

        function Arith_SeqProc{op}( a1::A1, b1::B1 ) where {op,A1,B1}
                a = Sequences.sequence(a1)
                new{op,typeof(a),typeof(b1)}(a,b1)
        end

end

struct Arith_ProcSeq{OP, Sys, It} <: Processors.abstract_processor
        sys::Sys
        it::It

        function Arith_ProcSeq{op}( a1::A1, b1::B1 ) where {op,A1,B1}
                b = Sequences.sequence(b1)
                new{op,typeof(a1),typeof(b)}(a1,b)
        end

end


Base.:+( it , sys::Processors.abstract_processor ) = Arith_SeqProc{+}( Sequences.sequence(it), sys )
Base.:-( it , sys::Processors.abstract_processor ) = Arith_SeqProc{-}( Sequences.sequence(it), sys )
Base.:*( it , sys::Processors.abstract_processor ) = Arith_SeqProc{*}( Sequences.sequence(it), sys )
Base.:/( it , sys::Processors.abstract_processor ) = Arith_SeqProc{/}( Sequences.sequence(it), sys )

# these disambiguate: 
#    eg Processors.Identity() + Sequences.triangular_dither
Base.:+( it::Sequences.abstract_sequence , sys::Processors.abstract_processor ) = Arith_SeqProc{+}( Sequences.sequence(it), sys )
Base.:-( it::Sequences.abstract_sequence , sys::Processors.abstract_processor ) = Arith_SeqProc{-}( Sequences.sequence(it), sys )
Base.:*( it::Sequences.abstract_sequence , sys::Processors.abstract_processor ) = Arith_SeqProc{*}( Sequences.sequence(it), sys )
Base.:/( it::Sequences.abstract_sequence , sys::Processors.abstract_processor ) = Arith_SeqProc{/}( Sequences.sequence(it), sys )




Base.IteratorSize( ::Type{Processors.Apply{I,Arith_SeqProc{OP,It,Sys}}}) where {I, OP, It, Sys} = Base.IteratorSize( Sequences.BinaryOp{OP, It, Processors.Apply{I,Sys} } )
Base.eltype(       ::Type{Processors.Apply{I,Arith_SeqProc{OP,It,Sys}}}) where {I, OP, It, Sys} = Base.eltype(       Sequences.BinaryOp{OP, It, Processors.Apply{I,Sys} } )

Base.length(it::Processors.Apply{I,Arith_SeqProc{OP,It,Sys}}       ) where {I,OP,It,Sys} = Base.length( Sequences.BinaryOp{OP}( it.p.it, it.in |> it.p.sys ) )
Base.size(  it::Processors.Apply{I,Arith_SeqProc{OP,It,Sys}}       ) where {I,OP,It,Sys} = Base.size(   Sequences.BinaryOp{OP}( it.p.it, it.in |> it.p.sys ) )
Base.isdone(it::Processors.Apply{I,Arith_SeqProc{OP,It,Sys}}       ) where {I,OP,It,Sys} = Base.isdone( Sequences.BinaryOp{OP}( it.p.it, it.in |> it.p.sys ) )
Base.isdone(it::Processors.Apply{I,Arith_SeqProc{OP,It,Sys}}, state) where {I,OP,It,Sys} = Base.isdone( Sequences.BinaryOp{OP}( it.p.it, it.in |> it.p.sys ), state)


function Base.iterate(it::Processors.Apply{I,Arith_SeqProc{OP,It,Sys}}        ) where {I,OP,It, Sys} 
        return Base.iterate( OP( it.p.it, it.in |> it.p.sys ) )
end
function Base.iterate(it::Processors.Apply{I,Arith_SeqProc{OP,It,Sys}}, state ) where {I,OP,It, Sys} 
        return Base.iterate( OP( it.p.it, it.in |> it.p.sys ), state )
end






Base.:+( sys::Processors.abstract_processor, it ) = Arith_ProcSeq{+}( sys, Sequences.sequence(it) )
Base.:-( sys::Processors.abstract_processor, it ) = Arith_ProcSeq{-}( sys, Sequences.sequence(it) )
Base.:*( sys::Processors.abstract_processor, it ) = Arith_ProcSeq{*}( sys, Sequences.sequence(it) )
Base.:/( sys::Processors.abstract_processor, it ) = Arith_ProcSeq{/}( sys, Sequences.sequence(it) )

# these disambiguate: 
#    eg Processors.Identity() + Sequences.triangular_dither
Base.:+( sys::Processors.abstract_processor, it::Sequences.abstract_sequence ) = Arith_ProcSeq{+}( sys, Sequences.sequence(it) )
Base.:-( sys::Processors.abstract_processor, it::Sequences.abstract_sequence ) = Arith_ProcSeq{-}( sys, Sequences.sequence(it) )
Base.:*( sys::Processors.abstract_processor, it::Sequences.abstract_sequence ) = Arith_ProcSeq{*}( sys, Sequences.sequence(it) )
Base.:/( sys::Processors.abstract_processor, it::Sequences.abstract_sequence ) = Arith_ProcSeq{/}( sys, Sequences.sequence(it) )


Base.IteratorSize( ::Type{Processors.Apply{I,Arith_ProcSeq{OP,Sys,It}}}) where {I, OP, It, Sys} = Base.IteratorSize( Sequences.BinaryOp{OP, Processors.Apply{I,Sys}, It } )
Base.eltype(       ::Type{Processors.Apply{I,Arith_ProcSeq{OP,Sys,It}}}) where {I, OP, It, Sys} = Base.eltype(       Sequences.BinaryOp{OP, Processors.Apply{I,Sys}, It } )

Base.length(it::Processors.Apply{I,Arith_ProcSeq{OP,Sys,It}}       ) where {I,OP,It,Sys} = Base.length( Sequences.BinaryOp{OP}( it.in |> it.p.sys, it.p.it )       )
Base.size(  it::Processors.Apply{I,Arith_ProcSeq{OP,Sys,It}}       ) where {I,OP,It,Sys} = Base.size(   Sequences.BinaryOp{OP}( it.in |> it.p.sys, it.p.it )       )
Base.isdone(it::Processors.Apply{I,Arith_ProcSeq{OP,Sys,It}}       ) where {I,OP,It,Sys} = Base.isdone( Sequences.BinaryOp{OP}( it.in |> it.p.sys, it.p.it )       )
Base.isdone(it::Processors.Apply{I,Arith_ProcSeq{OP,Sys,It}}, state) where {I,OP,It,Sys} = Base.isdone( Sequences.BinaryOp{OP}( it.in |> it.p.sys, it.p.it ), state)

function Base.iterate(it::Processors.Apply{I,Arith_ProcSeq{OP,Sys,It}}               ) where {I,OP,It, Sys} 
        return Base.iterate( Sequences.BinaryOp{OP}( it.in |> it.p.sys, it.p.it )        )
end
function Base.iterate(it::Processors.Apply{I,Arith_ProcSeq{OP,Sys,It}}, state        ) where {I,OP,It, Sys} 
        return Base.iterate( Sequences.BinaryOp{OP}( it.in |> it.p.sys, it.p.it ), state )
end







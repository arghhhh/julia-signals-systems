

# should be able to use Base.Iterators.Flatten for this
# but had problem with eltype being set to Any rather than a more specific type
# also had an issue where combining unknown and infinite length yielding unknown length, when it should be infinite


# concatenation:


struct Conc{A,B} <: abstract_sequence
        a::A
        b::B
end

function Base.iterate( p::Conc{A,B}, states = (Base.iterate(p.a),Base.iterate(p.b)) ) where {A,B }
        a,b = states
        # A and B may have difference eltype - so want to always convert to a single eltype
        T = eltype( Conc{A,B} )
        if a !== nothing
                # iterating a:
                return convert( T, a[1]),( iterate(p.a,a[2]), b )
        elseif b !== nothing
                # iterating b:
                return convert( T, b[1]),( nothing, iterate(p.b,b[2]) )
        else return nothing
        end
end
Base.IteratorSize( ::Type{Conc{A,B}} ) where {A,B} = begin
        as = Base.IteratorSize( A )
        bs = Base.IteratorSize( B )
        if as == Base.IsInfinite() || bs == Base.IsInfinite()
                return Base.IsInfinite()
        elseif bs == Base.SizeUnknown() || bs == Base.SizeUnknown()
                return Base.SizeUnknown()
        else
                return Base.HasLength()
        end
end
Base.IteratorEltype( ::Type{Conc{A,B}} ) where {A,B} = Base.IteratorEltype(A) == Base.IteratorEltype(B) == Base.HasEltype() ? Base.HasEltype() : Base.EltypeUnknown()
Base.eltype( ::Type{Conc{A,B}} ) where {A,B} = Base.promote_type( eltype(A), eltype(B) )
Base.length( it::Conc{A,B} ) where {A,B} = Base.length( it.a ) + Base.length( it.b )

concatenate( a, b ) = Conc( a, b )
concatenate( a, b, c... ) = Conc( Conc( a, b ), c... )

function sample_rate( p::Conc )
        return combined_sample_rate( sample_rate(p.a), sample_rate(p.b) )
end


module Polys

# this declares a simple wrapper over an Array{T}
# to hold a poly, and then defines arithmetic functions
# for it

import PolyImplementation


struct Poly{T}
    p::Array{T}
end

Poly( x::T ) where {T <: Number } = Poly{T}( [x] )


# allow conversion of a numbers to a length 1 polynomial:
Base.convert( ::Type{Poly}, x::T ) where {T} = Poly{T}( [x] )

Poly( coeffs... ) = Poly( collect( coeffs ) )
Poly( ::Type{T}, coeffs... ) where {T} = Poly( T[ coeffs... ] )
(p::Poly)(x) = PolyImplementation.poly_eval( p.p, x)

Base.:+( a::Poly, b::Poly ) = Poly( PolyImplementation.poly_add( a.p, b.p ) )
Base.:+( a::Poly, b       ) = Poly( PolyImplementation.poly_add( a.p, (b,) ) )
Base.:+( a      , b::Poly ) = Poly( PolyImplementation.poly_add( (a,), b.p ) )

Base.:-( a::Poly, b::Poly ) = Poly( PolyImplementation.poly_sub( a.p, b.p ) )
Base.:-( a::Poly, b       ) = Poly( PolyImplementation.poly_sub( a.p, (b,) ) )
Base.:-( a      , b::Poly ) = Poly( PolyImplementation.poly_sub( (a,), b.p ) )

Base.:*( a::Poly, b::Poly ) = Poly( PolyImplementation.poly_mult( a.p, b.p ) )
Base.:*( a::Poly, b       ) = Poly( PolyImplementation.poly_mult( a.p, (b,) ) )
Base.:*( a      , b::Poly ) = Poly( PolyImplementation.poly_mult( (a,), b.p ) )

Base.:/( a::Poly, b::Poly ) = Poly( PolyImplementation.poly_divrem( a.p, b.p )[1] )
Base.:/( a::Poly, b       ) = Poly( PolyImplementation.poly_divrem( a.p, (b,) )[1] )
Base.:/( a      , b::Poly ) = Poly( PolyImplementation.poly_divrem( (a,), b.p )[1] )

Base.:%( a::Poly, b::Poly ) = Poly( PolyImplementation.poly_divrem( a.p, b.p )[2] )
Base.:%( a::Poly, b       ) = Poly( PolyImplementation.poly_divrem( a.p, (b,) )[2] )
Base.:%( a      , b::Poly ) = Poly( PolyImplementation.poly_divrem( (a,), b.p )[2] )

Base.iszero( a::Poly ) = iszero( a.p )

# need to define both versions of zero and one because Poly is
# not subtyped from Number
Base.zero( p::Poly{T}         ) where {T} = Poly( zeros(T, 0) )
Base.zero(  ::Type{ Poly{T} } ) where {T} = Poly( zeros(T, 0) )
Base.one(  p::Poly{T}         ) where {T} = Poly( ones( T, 1) )
Base.one(   ::Type{ Poly{T} } ) where {T} = Poly( ones( T, 1) )

# want to support things like: sum( abs2, sinc_2_1 )
# where is sinc_2_1 is Poly
# make iterable
# https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-iteration
Base.iterate(       p::Poly{T}         ) where {T} = Base.iterate( p.p )
Base.iterate(       p::Poly{T}, state  ) where {T} = Base.iterate( p.p, state )
Base.IteratorSize(   ::Type{ Poly{T} } ) where {T} = Base.IteratorSize(   Array{T} )
Base.IteratorEltype( ::Type{ Poly{T} } ) where {T} = Base.IteratorEltype( Array{T} )
Base.eltype(         ::Type{ Poly{T} } ) where {T} = Base.eltype( Array{T} )
Base.length(        p::Poly{T}         ) where {T} = Base.length( p.p )
Base.size(          p::Poly{T}         ) where {T} = Base.size(   p.p )
Base.isdone(        p::Poly{T}         ) where {T} = Base.isdone( p.p )
Base.isdone(        p::Poly{T}, state  ) where {T} = Base.isdone( p.p, state )

# https://docs.julialang.org/en/v1/manual/interfaces/#Indexing
Base.getindex( p::Poly{T} , i        ) where {T} = p.p[i]
Base.setindex( p::Poly{T} , v, i     ) where {T} = p.p[i] = v
Base.firstindex( p::Poly{T}          ) where {T} = Base.firstindex( p.p )
Base.lastindex( p::Poly{T}          ) where {T} = Base.lastindex( p.p )

end


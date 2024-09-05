

import LinearAlgebra

# this looks good - but does't allow cascades, because eltype information is lost by Map
fir1( coeffs ) = (
	   Vectorize( length(coeffs) ) 
	|> Map( x->LinearAlgebra.dot( reverse(coeffs), x ) )
)

# this is a little ugly - because Julia doesn't make it easy to know the result
# type of a function
# the easiest solution to this problem is to make the user specify the result type
# the better solution is to code up the dot product as a processor 
# and then eltype can be properly defined as the type obtained as the type of the product of eltype(coeffs) and eltype(inputs)
# when the inputs are applied (which isn't known in the above function)
# ie all properly promoted. 
fir2( T, coeffs ) = (
	   Vectorize( length(coeffs) ) 
	|> MapT{T}( x->LinearAlgebra.dot( reverse(coeffs), x ) )
)


# could generalise this solution
# to be like a version of Map, except that there is also a function returning the eltype as a function of input eltype

# this processes the input stream
# assuming each input is some form of AbstractVector
# and produces the output as the dot product of the input and coeffs
struct DotProduct{T} <: abstract_processor
        coeffs::AbstractVector{T}
end


# set the eltype to be unknown - this causes some of the Julia library functions to base the type on
# the type of the first value returned - eg when using collect, the resulting vector can still have a paramterized 
# type, even though IteratorEltype returned EltypeUnknown.  This is better than the accepting the defaults
# where eltype is known, but defaults to Any.

# know the eltype, if and only if, know the eltype of the input:
Base.IteratorEltype(::Type{Apply{I,DotProduct{T}}}) where {I,T} = Base.IteratorEltype(I)
# if asked for the eltype, should be able to assume that the input eltype is known:
# the input eltype is some kind of AbstractVector, so want the eltype of the eltype..
Base.eltype( ::Type{Apply{I,DotProduct{T}}}) where {I,T} = Base.promote_op(*,Base.eltype(Base.eltype(I)),T)

# length is the same as the input:
Base.IteratorSize( ::Type{Apply{I,DotProduct{T}}}) where {I,T} = Base.IteratorSize(I)
Base.length(t::Apply{I,DotProduct{T}}) where {I,T} = Base.length(t.in)
Base.size(t::Apply{I,DotProduct{T}}) where {I,T} = Base.size(t.in)
Base.isdone(t::Apply{I,DotProduct{T}}) where {I,T} = Base.isdone(t.xs)
Base.isdone(t::Apply{I,DotProduct{T}}, state) where {I,T} = Base.isdone(t.xs, state)

function Base.iterate(it::Apply{I,DotProduct{T}} ) where {I,T}

    y = Base.iterate(it.in )
    y === nothing && return nothing

    yout = LinearAlgebra.dot( y[1], it.p.coeffs )
    return yout, y[2]
end

function Base.iterate(it::Apply{I,DotProduct{T}}, state ) where {I,T}

        y = Base.iterate(it.in, state )
        y === nothing && return nothing
    
	yout = LinearAlgebra.dot( y[1], it.p.coeffs )
        return yout, y[2]
end

fir( coeffs ) = (
	   Vectorize( length(coeffs) ) 
	|> DotProduct( reverse(coeffs) )
)


decimator( n, coeffs ) = (
	   Vectorize( length(coeffs) ) 
	|> Downsample(n) 
	|> DotProduct( reverse(coeffs) )
)

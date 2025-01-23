

struct Identity <: SampleProcessor; end

process( id::Identity, x, state=nothing ) = x,state




struct Convert{T} <: SampleProcessor
end

process( p::Convert{T}, x, state=nothing ) where {T} = Base.convert(T,x),state
Base.eltype( a::Apply{I,Convert{T}}) where {I,T} = T

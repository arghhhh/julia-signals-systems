struct Repeated{T} <: abstract_sequence
        x::T
end
    
function Base.iterate( u::Repeated )
        return u.x, nothing
end
function Base.iterate( u::Repeated, state )
        return u.x, nothing
end
Base.IteratorEltype( ::Type{Repeated{T}} ) where {T} = Base.HasEltype()
Base.IteratorSize( ::Type{Repeated{T}} ) where {T} = Base.Base.IsInfinite()
Base.eltype( ::Type{Repeated{T}} ) where {T} = T


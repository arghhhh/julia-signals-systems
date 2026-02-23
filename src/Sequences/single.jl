
struct Single{T} <: abstract_sequence
        x::T
end
    
function Base.iterate( u::Single )
        return u.x, nothing
end
function Base.iterate( u::Single, state )
        return nothing
end
Base.IteratorEltype( ::Type{Single{T}} ) where {T} = Base.HasEltype()
Base.IteratorSize( ::Type{Single{T}} ) where {T} = Base.HasLength()
Base.eltype( ::Type{Single{T}} ) where {T} = T
Base.length( it::Single{T} ) where {T} = 1


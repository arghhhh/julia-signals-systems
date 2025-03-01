


struct Map <: abstract_processor
        fn::Function
end


# set the eltype to be unknown - this causes some of the Julia library functions to base the type on
# the type of the first value returned - eg when using collect, the resulting vector can still have a paramterized 
# type, even though IteratorEltype returned EltypeUnknown.  This is better than the accepting the defaults
# where eltype is known, but defaults to Any.
Base.IteratorEltype(::Type{Apply{I,Map}}) where {I} = Base.EltypeUnknown()
Base.IteratorSize( ::Type{Apply{I,Map}}) where {I} = Base.IteratorSize(I)

Base.length(t::Apply{I,Map}) where {I} = Base.length(t.in)
Base.size(t::Apply{I,Map}) where {I} = Base.size(t.in)
Base.isdone(t::Apply{I,Map}) where {I} = Base.isdone(t.xs)
Base.isdone(t::Apply{I,Map}, state) where {I} = Base.isdone(t.xs, state)

function Base.iterate(it::Apply{I,Map} ) where {I}

    y = Base.iterate(it.in )
    y === nothing && return nothing

    yout = it.p.fn( y[1] )
    return yout, y[2]
end

function Base.iterate(it::Apply{I,Map}, state ) where {I}

        y = Base.iterate(it.in, state )
        y === nothing && return nothing
    
        yout = it.p.fn( y[1] )
        return yout, y[2]
end



# this includes a conversion of the result to type T:

struct MapT{T} <: abstract_processor
        fn::Function
end


Base.eltype(::Type{Apply{I,MapT{T}}}) where {I,T} = T

Base.IteratorSize( ::Type{Apply{I,MapT{T}} }) where {I,T} = Base.IteratorSize(I)

Base.length(t::Apply{I,MapT{T}}) where {I,T} = Base.length(t.in)
Base.size(t::Apply{I,MapT{T}}) where {I,T} = Base.size(t.in)
Base.isdone(t::Apply{I,MapT{T}}) where {I,T} = Base.isdone(t.xs)
Base.isdone(t::Apply{I,MapT{T}}, state) where {I,T} = Base.isdone(t.xs, state)

function Base.iterate(it::Apply{I,MapT{T}} ) where {I,T}

    y = Base.iterate(it.in )
    y === nothing && return nothing

    yout = convert( T, it.p.fn( y[1] ) )
    return yout, y[2]
end

function Base.iterate(it::Apply{I,MapT{T}}, state ) where {I,T}

        y = Base.iterate(it.in, state )
        y === nothing && return nothing
    
        yout = convert( T, it.p.fn( y[1] ) )
        return yout, y[2]
end

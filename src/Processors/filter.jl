

# This is a filter that will only pass inputs x, for which fn(x) is true
# similar to https://clojure.org/reference/transducers
# Not a signal processing linear filter!

struct Filter <: abstract_processor
        fn::Function
end

# eltype, if known, is the same as input
Base.IteratorEltype(::Type{Apply{I,Filter}}) where {I} = Base.IteratorEltype(I)
Base.eltype( ::Type{Apply{I,Filter}}) where {I} = Base.eltype(I)

# the size is unknown:
Base.IteratorSize( ::Type{Apply{I,Filter}}) where {I} = Base.SizeUnknown()

Base.isdone(t::Apply{I,Filter}) where {I} = Base.isdone(t.xs)
Base.isdone(t::Apply{I,Filter}, state) where {I} = Base.isdone(t.xs, state)


function iterate_filter_body( it, y )

        # this the common part of the two iterate functions
        # iterate() has already been called once and returned y

        y === nothing && return nothing

        while !it.p.fn( y[1] )
                y = Base.iterate(it.in, y[2] )
                y === nothing && return nothing
        end

        return y  # this is the tuple of output and input-state
end        

function Base.iterate(it::Apply{I,Filter} ) where {I}

        y = Base.iterate(it.in )
        return iterate_filter_body(it,y)
end

function Base.iterate(it::Apply{I,Filter}, state ) where {I}
        y = Base.iterate(it.in, state )
        return iterate_filter_body(it,y)
end






struct Flatten <: abstract_processor
end


# set the eltype to be unknown - this causes some of the Julia library functions to base the type on
# the type of the first value returned - eg when using collect, the resulting vector can still have a paramterized 
# type, even though IteratorEltype returned EltypeUnknown.  This is better than the accepting the defaults
# where eltype is known, but defaults to Any.
Base.IteratorEltype(::Type{Apply{I,Flatten}}) where {I} = Base.EltypeUnknown()

# the size is unknown:
Base.IteratorSize( ::Type{Apply{I,Flatten}}) where {I} = Base.SizeUnknown()

Base.isdone(t::Apply{I,Flatten}) where {I} = Base.isdone(t.xs)
Base.isdone(t::Apply{I,Flatten}, state) where {I} = Base.isdone(t.xs, state)

function iterate_flatten_body( it, y_outer, y_inner )
        while y_inner === nothing
                # inner iterator is done
                # iterate the outer loop and start again:
                y_outer = Base.iterate(it.in, y_outer[2] )
                y_outer === nothing && return nothing
                y_inner = Base.iterate( y_outer[1])
        end

        yout = y_inner[1]
        state = y_outer,y_inner[2]

        return yout, state
end

function Base.iterate(it::Apply{I,Flatten} ) where {I}

        y_outer = Base.iterate(it.in )
        y_outer === nothing && return nothing
        y_inner = Base.iterate( y_outer[1])

        return iterate_flatten_body( it, y_outer, y_inner )
end

function Base.iterate(it::Apply{I,Flatten}, state ) where {I}

        y_outer, y_inner_state = state
        y_inner = Base.iterate( y_outer[1], y_inner_state )

        return iterate_flatten_body( it, y_outer, y_inner )
end

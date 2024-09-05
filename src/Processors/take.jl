


struct Take <: abstract_processor
	n::UInt  # force n to be positive
end


# eltype same as input eltype:
Base.IteratorEltype(::Type{Apply{I,Take}}) where {I} = Base.IteratorEltype(I)
Base.eltype(::Type{Apply{I,Take}}) where {I} = Base.eltype(I)

# length of iterator should be known
# either the min of the input length, or the given take value n
# but could be unknown if the input size is unknown:
take_iteratorsize(a) = Base.HasLength()
take_iteratorsize(::Base.SizeUnknown) = Base.SizeUnknown()
function Base.IteratorSize(::Type{Apply{I,Take}}) where {I}
	if Base.IteratorSize(I) == Base.SizeUnknown()
		return Base.SizeUnknown()
	end
	# input is either infinite or has length, so have well defined output length:
	return Base.HasLength()
end
function Base.length(t::Apply{I,Take}) where {I} 
	if Base.IteratorSize(I) == Base.IsInfinite()
		return t.p.n
	end
	# at this point, should be safe to call length on input
	# if input length unknown, shouldn't have called this function
	return min( t.p.n, Base.length(t.in) )
end

function Base.iterate(it::Apply{I,Take}, state=(it.p.n,)) where {I}
	n, rest = state[1], Base.tail(state)
	n <= 0 && return nothing
	y = Base.iterate(it.in, rest...)
	y === nothing && return nothing
	return y[1], (n - 1, y[2])
end




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



# this is adapted from Julia Base Iterators 
# https://github.com/JuliaLang/julia/blob/760b2e5b7396f9cc0da5efce0cadd5d1974c4069/base/iterators.jl#L802-L826

# uses:
# https://github.com/JuliaLang/julia/blob/760b2e5b7396f9cc0da5efce0cadd5d1974c4069/base/iterators.jl#L72C1-L78C4
_diff_length(a, b, A, ::Base.IsInfinite) = 0
_diff_length(a, b, ::Base.IsInfinite, ::Base.IsInfinite) = 0
_diff_length(a, b, ::Base.IsInfinite, B) = length(a) # inherit behaviour, error
function _diff_length(a, b, A, B)
    m, n = length(a), length(b)
    return m > n ? m - n : zero(n - m)
end

struct Drop <: abstract_processor
    n::Int
    function Drop(n::Integer)
        n < 0 && throw(ArgumentError("Drop length must be non-negative"))
        return new(n)
    end
end


#drop(xs, n::Integer) = Drop(xs, Int(n))
# drop(xs::Take, n::Integer) = Take(drop(xs.xs, Int(n)), max(0, xs.n - Int(n)))
#drop(xs::Drop, n::Integer) = Drop(xs.xs, Int(n) + xs.n)

Base.eltype(::Type{Apply{I,Drop}}) where {I} = eltype(I)
Base.IteratorEltype(::Type{Apply{I,Drop}}) where {I} = Base.IteratorEltype(I)
drop_iteratorsize(::Base.SizeUnknown) = Base.SizeUnknown()
drop_iteratorsize(::Union{Base.HasShape, Base.HasLength}) = Base.HasLength()
drop_iteratorsize(::Base.IsInfinite) = Base.IsInfinite()
Base.IteratorSize(::Type{Apply{I,Drop}}) where {I} = drop_iteratorsize(Base.IteratorSize(I))

# it is 1:d.n below so that _diff_length can call length on it...
Base.length(d::Apply{I,Drop}) where {I} = _diff_length(d.in, 1:d.p.n, Base.IteratorSize(d.in), Base.HasLength())

function Base.iterate(d::Apply{I,Drop}) where {I}
    y = iterate(d.in)
    for i in 1:d.p.n
        y === nothing && return y
        y = iterate(d.in, y[2])
    end
    y
end
Base.iterate(d::Apply{I,Drop}, state) where {I} = iterate(d.in, state)
Base.isdone(d::Apply{I,Drop}, state) where {I} = isdone(d.in, state)

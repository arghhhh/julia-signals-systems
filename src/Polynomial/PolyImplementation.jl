


# minimal set of functions to implement polynomials

# by minimal, mean that the storage of the polynomial is not restricted
# - could be an array or a tuple.
# however arrays are used in performing arithmetic and returning the result
# - though, still it is an unadorned array, not some sort of polynomial type

# not sure if the feature of allowing tuples is useful
# accepting tuples is the reason why some of the loops are explicit below - 
# processing element by element, instead of using Julia's vector arithmetic



module PolyImplementation

poly_iszero(v) = iszero(v)

# this is approx half the significant digits - pretty poor
poly_iszero(v::AbstractFloat) = isapprox( v, zero(v))


poly_add( a, b ) = begin
	T  = promote_type( eltype(a), eltype(b) )
	n  = max( length(a), length(b) )
	n1 = min( length(a), length(b) )
	r  = zeros( T, n )

	for i in 1:n1
		r[i]=a[i]+b[i]
	end
    	if length(a)>length(b)
    		for i in n1+1:n
			r[i] = a[i]
		end
	else 
    		for i in n1+1:n
			r[i] = b[i]
		end
	end

	return r
end

poly_sub( a, b ) = begin
	T = promote_type( eltype(a), eltype(b) )
	n = max( length(a), length(b) )
	n1 = min( length(a), length(b) )

	r  = zeros( T, n )

	for i in 1:n1
		r[i] = a[i] - b[i]
	end
    	if length(a)>length(b)
    		for i in n1+1:n
			r[i] =  a[i]
		end
	else 
    		for i in n1+1:n
			r[i] = -b[i]
		end
	end

	return r
end

poly_mult(p1, p2) = begin
	R = promote_type(eltype(p1),eltype(p2))
	n = length(p1)
	m = length(p2)

	if n==0 || m == 0
		return zeros(R,0)
	end

	a = zeros(R,m+n-1)
	for i = 1:n
		for j = 1:m
			a[i+j-1] += p1[i] * p2[j]
		end
	end

	return a
end

"""
divrem( num, dem)
returns the quotient of length num - dem+1
and the remainder of length dem-1
unless length num < den in which case returned
divisor is zero and remainder is the input numerator
dem must have length >= 1
"""
function poly_divrem(num, den)
    if length(den) == 0
        throw(DivideError())
    end
    R = typeof(one(eltype(num))/one(eltype(den)))
    aR = R[ num[i] for i = 1:length(num) ]
    if length(num) < length(den) # deg <= 0
        return zeros(R, 0), aR
    end
    aQ = zeros(R, length(num)-length(den)+1)
    for i = length(num):-1:length(den)
        quot = aR[i] / den[(length(den)-1)+1]
        aQ[i-(length(den)-1)] = quot
        for j = 1:length(den)
            aR[i-(length(den)-j)] -= den[j]*quot
        end
    end
    resize!(aR, length(den)-1 )
    return aQ, aR
end

# version of polyval from Pkg::Polynomials
# modified to not have conversions

# if the polynomial has no coefficients
# then the result is always the zero corresponding to x
# otherwise the return type corresponds to a direct
# evaluation using Horner's method

# p can be a tuple or an Array
# - an empty tuple is fairly meaningless, and does not have a meaningful
# eltype. An empty Array does have a meaningful eltype.

# there is now https://docs.julialang.org/en/v1/base/math/#Base.Math.evalpoly

# function poly_eval(p, x)
#     if length(p) == 0
#         return zero( eltype(p) ) + zero(x) * zero(eltype(p))
#     else
#         y = p[end] + zero(x) # +zero(x) for type stability
#         for i = (lastindex(p)-1):-1:1
#             y = p[i] + y*x
#         end
#         return y
#     end
# end

poly_eval(p, x) = Base.Math.evalpoly( x, p )

# this is just the polynomial with the coefficients reversed
# this has the property:
# poly_reciprocal(p)(x) = x^n * p( x^-1 )
# p(x) = x^n * poly_reciprocal(p)(x^−1)
# https://en.wikipedia.org/wiki/Reciprocal_polynomial

poly_reciprocal(p) = reverse(p)

# function poly_reciprocal(p)
#     # this is just the polynomial with the coefficients reversed
#     # this has the property:
#     # poly_reciprocal(p)(x) = x^n * p( x^-1 )
#     # p(x) = x^n * poly_reciprocal(p)(x^−1)
#     # https://en.wikipedia.org/wiki/Reciprocal_polynomial
#     return collect( view(p, lastindex(p):-1:firstindex(p)) )
# end


end




module PolyTransform

import Polys

function f_to_s( f )
	return complex( 0.0, 2π*f )
end

function f_to_z( freq, fs = 1.0 )
	f2 = 2*freq/fs
	return complex( cospi(f2), sinpi(f2) )
end

function f_to_zinv( freq, fs = 1.0 )
	f2 = 2*freq/fs
	return complex( cospi(f2), -sinpi(f2) )
end
	
# Proakis p643
function lowpass( p, f1, f2 )
	num = Polys.Poly( 0.0, f1 / f2 )
	denom = Polys.Poly( 1.0 )

	tfn = apply_rational_transform( p, num, denom )

	return tfn
end
	

function highpass( p, f1, f2 )
	num = Polys.Poly( f1 * f2 * 4 * π * π )
	denom = Polys.Poly( 0.0, 1.0 )

	tfn = apply_rational_transform( p, num, denom )

	return tfn
end

function bilinear_poly( f1, f2, fs )
		# this is the transform
		# s <-  wo / tan( wo T / 2 ) * ( z - 1 ) / ( z + 1 )

		# this yields a Polynomial in z  (not z^-1)

		x = 2π * f1 / tan( π * f2 / fs )
		num = Polys.Poly( -x, x )
		denom = Polys.Poly( 1.0, 1.0 )
		return num,denom
end

function bilinear_poly_zm1( f1, f2, fs )

		# this is the transform
		# s <-  wo / tan( wo T / 2 ) * ( 1 - z^-1 ) / ( 1 + z^1 )

		# this yields a Polynomial in z  (not z^-1)

		x = 2π * f1 / tan( π * f2 / fs )
		num = Polys.Poly( x, -x )
		denom = Polys.Poly( 1.0, 1.0 )
		return num,denom
end


function apply_rational_transform( p1::Polys.Poly, num, denom )
	a = p1.p
	p = Polys.Poly( a[1] )
	N = Polys.Poly( 1.0 )
	for i in 2:length(a)
		p = p * denom
		N = N * num
		p = p + a[i] * N
	end

	return p
end


function tidy_form_lowest( p::Polys.Poly )
	p1 = similar( p.p )
	p1[2:end] = p[2:end] ./ p[1]
	p1[1] = one( p[1] )
	return Polys.Poly( p1 )
end

end


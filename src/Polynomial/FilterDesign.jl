
module FilterDesign

import Polys
import TFNs

function s_1_fo( fo )
	wo = 2*π*fo
	return ( wo, 1.0 )
end
	
function s_2_fo( fo )
	wo = 2*π*fo
	return ( wo * wo , 0.0, 1.0 )
end

function s_foQ( fo, Q )
	wo = 2*π*fo
	return ( wo * wo , wo/Q, 1.0 )
end
	
function complex_root( z )
	re = real(z)
	im = imag(z)
	return ( re*re + im*im , -2.0 * re, 1.0 )
end
	
"""
n th order butterworth filter
unity DC gain
-3dB at w=1 ( f=1/(2pi) )
"""
function butterworth( n )
	tfn = TFNs.TFN( [ Polys.Poly( 1.0 ) ], Polys.Poly{Float64}[] )

	if n%2 == 1
		push!( tfn.denominator, Polys.Poly( 1.0, 1.0 ) )
	end
	for i in 0:( div(n,2) - 1 )
		ang = (0.5+ (0.5+i)/n) * π;
		push!(  tfn.denominator, Polys.Poly( complex_root( complex(cos(ang), sin(ang) ) )... ) )
	end

	return tfn
end

# this is inspired by Proakis & Manolakis p636
function chebyshev( n, ripple )
	numerator = [ Polys.Poly(1.0) ]
	denominator = Polys.Poly{Float64}[]
	tfn = TFNs.TFN( numerator, denominator )

	B =  ( (2.0-ripple)/sqrt(2*ripple - ripple*ripple) ) ^ ( 1.0/n )
	r1 = (B*B+1.0)/(2.0*B)
	r2 = (B*B-1.0)/(2.0*B)

	if isodd(n)
		push!( denominator, Polys.Poly( r2, 1.0 ) )
	end

	for i in 0:(div(n,2)-1)
		ang = (0.5+ (0.5+i)/n) * π
		push!( denominator, Polys.Poly( complex_root( complex( r2*cos(ang), r1*sin(ang) ) )... ) )
	end

	dc_gain = tfn( 0.0 )
	if iseven( n )
		dc_gain = dc_gain / ( 1.0- ripple )
	end

	numerator[1].p[1] = 1.0 / dc_gain

	return tfn
end


function inverse_chebyshev( n, ripple )
	numerator = [ Polys.Poly(1.0) ]
	denominator = Polys.Poly{Float64}[]
	tfn = TFNs.TFN( numerator, denominator )

	A =  1.0 / ripple;

	y = ( A + sqrt( A*A - 1 ) ) ^ ( 1.0/n );
	
	r2 = 0.5 * (y - 1.0/y);
	r1 = 0.5 * (y + 1.0/y);
	
	if isodd( n )
		push!( denominator, Polys.Poly( 1.0/r2, 1.0 ) )
	end
	for i in 0:(div(n,2)-1)
			ang = (0.5+ (0.5+i)/n)* π
			push!( numerator, Polys.Poly( complex_root( complex( 0.0, 1.0/sin(ang) ) )... ) )

			x = r2*cos(ang);
			y = r1*sin(ang);
			mag = x*x + y*y
			push!( denominator, Polys.Poly( complex_root( complex( x/mag, y/mag ) )... ) )

		end
	
	push!( numerator, Polys.Poly( 1.0/tfn(0.0) ) )

	return tfn
end

end # module

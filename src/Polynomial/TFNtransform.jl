
module TFNtransform

import Polys
import PolyTransform
import TFNs


function lowpass( tfn, f1, f2 )
	numerator   = map( f->PolyTransform.lowpass( f, f1, f2 ) , tfn.numerator   )
	denominator = map( f->PolyTransform.lowpass( f, f1, f2 ) , tfn.denominator )
	return TFNs.TFN( numerator, denominator )
end


function poly_order( p::Polys.Poly{T} ) where {T}
	return max( 0, length(p.p)-1 )
end
function tfn_order( p::Array{Polys.Poly{T},1} ) where {T}
	return sum( poly_order.(p) )
end


function apply_poly_transform( tfn::TFNs.TFN, num )

	numerator   = map( p->p(num) , tfn.numerator   )
	denominator = map( p->p(num) , tfn.denominator )

	return TFNs.TFN( numerator, denominator )
end
	
	
function apply_rational_transform( tfn::TFNs.TFN, num, denom )
	ndiff = tfn_order( tfn.denominator ) - tfn_order( tfn.numerator )

	numerator   = map( f->PolyTransform.apply_rational_transform( f, num, denom ) , tfn.numerator   )
	denominator = map( f->PolyTransform.apply_rational_transform( f, num, denom ) , tfn.denominator )

	# add any extra zeros:
	for i in 1:ndiff
		push!( numerator, denom )
	end
	# add any extra poles:
	for i in 1:(-ndiff)
		push!( denominator, denom )
	end
	return TFNs.TFN( numerator, denominator )
end



function matched_z_factor( p, fs )

	n = length(p)
	f = zeros(n)

	# @show p fs
	
		if n == 1
			# constant factor
			# do nothing
			f[1] = p[1]
		elseif n == 2
			# first order factor ( p[2].s + p[1] ) has
			# root location: ( s - si )
			si = -p[1] / p[2]
			# and maps to:
			f[2] = 1
			f[1] = -exp( si/fs )
	
			println( "matched_z ", si, " -> ", -f[1] )
		elseif n == 3
			# second order factor

			z,z2 = roots_of_factor( p );
	
			f[3] = p[3]
			f[2] = p[3] * -2.0 * exp( z.re /  fs ) * cos( z.im /  fs )
			f[1] = p[3] * exp( 2.0 * z.re /  fs )
		else
			error(" matched z transform poly must be factored")
		end

	return f
end
	
	
function matched_z( tfn::TFNs.TFN, fs = 1 )
	t = factor->Poly( matched_z_factor( factor.p, fs ) )
	num = map( t, tfn.numerator )
	denom = map( t, tfn.denominator )

	return TFN( num, denom )
end
	
	
function set_gain!( tfn::TFNs.TFN, z = 1.0 , g = 1.0 )
	# evaluate gain at complex z, and adjust gain to have magnitude gain
	g1 = abs( tfn(z) )
	push!( tfn.numerator, Polys.Poly( g/g1 ) )
end
	
function with_gain( tfn1::TFNs.TFN, z, g )

	tfn = deepcopy( tfn1 )

	set_gain!( tfn, z, g )
	
	return tfn
end
			

function expand( tfn::TFNs.TFN )
	# multiply out an array or tuple of polys
	return TFNs.TFN( [ prod(tfn.numerator) ], [ prod(tfn.denominator) ] )
end
	
function tidy_form_lowest( tfn::TFNs.TFN )
	return TFNs.TFN( map( PolyTransform.tidy_form_lowest, tfn.numerator ),  map( PolyTransform.tidy_form_lowest, tfn.denominator ) )
end

end

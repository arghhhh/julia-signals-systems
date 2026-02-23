
module TFNs

import Polys
import PolyImplementation
import PolyTransform

struct TFN{T}
	numerator   :: Array{ Polys.Poly{T}, 1 }
	denominator :: Array{ Polys.Poly{T}, 1 }
end

# TODO want some TFN constructors
# eg TFN( poly, poly )

# and want to promote scalars appropriately
# eg TFN( poly, 1 ) and TFN( 1, poly )

# function TFN( num, denom )
#         num1, denom1 = promote( num, denom )
#         return TFN{eltype(num1)}( num1, denom1 )
# end



function to_dB( x )
		return 20.0 * log10( abs(x) )
	end

function to_phase_degrees( x )
		return atan( imag(x), real(x) ) * 180.0 / π
end

# these seem to work for individual frequencies (ie f::Float64) and for arrays
function response_s_dB( hz::TFNs.TFN, f )
		tfn_dB = hz.( PolyTransform.f_to_s.(f) ) .|> to_dB
		return tfn_dB
end
function response_s_degrees( hz::TFNs.TFN, f )
		tfn_dB = hz.( PolyTransform.f_to_s.(f) ) .|> to_phase_degrees
		return tfn_dB
end
function response_z_dB( hz::TFNs.TFN, f, fs = 1.0 )
		tfn_dB = hz.( PolyTransform.f_to_z.(f,fs) ) .|> to_dB
		return tfn_dB
end
function response_z_degrees( hz::TFNs.TFN, f, fs = 1.0 )
		tfn_dB = hz.( PolyTransform.f_to_z.(f,fs) ) .|> to_phase_degrees
		return tfn_dB
end
function response_zinv_dB( hz::TFNs.TFN, f, fs = 1.0 )
		tfn_dB = hz.( PolyTransform.f_to_zinv.(f,fs) ) .|> to_dB
		return tfn_dB
end
function response_zinv_degrees( hz::TFNs.TFN, f, fs = 1.0 )
		tfn_dB = hz.( PolyTransform.f_to_zinv.(f,fs) ) .|> to_phase_degrees
		return tfn_dB
end
   





function poly_eval( p::Array{ Polys.Poly{T}, 1 }, x ) where {T}
	return reduce( *, map( p1->PolyImplementation.poly_eval(p1.p,x), p ); init= one(T) )
end

function poly_eval( p::TFN{T}, x ) where {T}
	return poly_eval( p.numerator, x) / poly_eval( p.denominator, x)
end

(p::TFN)(x) = poly_eval( p.numerator, x) / poly_eval( p.denominator, x)



# define arithmetic over TFNs

function Base.:*( lhs::TFN, rhs::TFN )
		return TFN( vcat( lhs.numerator, rhs.numerator ), vcat( lhs.denominator, rhs.denominator ) )
end
# TODO: +, -, /






function print_info_s( ply::Polys.Poly{T} ) where {T}
	p = ply.p
	n = length( p ) - 1  # ORDER is one less than length....
	if n == 1
		b = p[1]/p[2]; # normalised coeff of const term
		print("1:fo ", b / (2π) , "\n" )
	elseif n == 2
		b = p[2] / p[3]
		c = p[1] / p[3]
		w = sqrt( c );
		if ( p[2] != 0.0 ) 
			Q = w / b
			print( "2:foQ ", w / (2π), " ", Q, "\n" )
		else
			print( "2:fo ", w / (2π), "\n" )
		end
	else
		print(" ", n, ":" );
		for i in length( p ):-1:1
			print( " ", p[i] )
		end
		print( "\n" )
	end
end
	
function print_info_s( p::Vector{Polys.Poly{T}} ) where {T}
	for factor in p
		print_info_s( factor )
	end
end

function print_info_s( tfn::TFN )
	print( "{\n" )
	print_info_s( tfn.numerator   )
	print( "} / {\n" )
	print_info_s( tfn.denominator )
	print( "}\n" )
end


# z-domain

function print_info_z( ply::Polys.Poly{T}, fs = 1.0 ) where {T}
	p = ply.p
	n = length( p ) - 1  # ORDER is one less than length....

	if n == 1
		print("matched_z ", fs, " " );
		b = p[1]/p[2] # normalised coeff of const term
		if b > 0
			print("Root on -ve real axis of z-plane - no s-domain equivalent\n")
		else
			print( -fs * log( -b ) / (2π) )
		end
	elseif n == 2
		print("matched_z ", fs, " " );

		if ( p[1] != p[3] ) 
			# not on unit circle
			b = p[2]/p[3]
			c = p[1]/p[3]
			if ( c < 0 )
				print("Can't cope with this\n")
			else
				re = log( c ) * fs / 2.0
					# need domain check on next line?
				im = fs * acos( -b / 2.0 / exp( re / fs )) # could simplify

				w = sqrt( re*re + im*im )
				Q = - w / ( 2.0 * re )
				print("2:foQ ", w/(2π), " ", Q, "\n" )
			end
		else
			# on unit circle
			b = p[2]/p[3]
			w = fs * acos( -b / 2.0 )
			print("2:fo ", w/(2π), "\n" )
		end
	end
end
	
	
function print_info_z( p::Vector{Polys.Poly{T}}, fs = 1.0 ) where {T}
	for factor in p
		print_info_z( factor, fs )
	end
end

function print_info_z( tfn::TFN, fs = 1.0 )
	print( "{\n" )
	print_info_z( tfn.numerator   , fs )
	print( "} / {\n" )
	print_info_z( tfn.denominator , fs )
	print( "}\n" )
end
	
end # module


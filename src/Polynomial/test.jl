

function add_to_Julia_path( p )
        if p ∉ LOAD_PATH
                push!( LOAD_PATH, p )
        end
end


add_to_Julia_path( "." )

import Polys

# just check that some things compile and run without error
# TODO: add checking
p1 = Polys.Poly( 1,2,3 )
p2 = Polys.Poly( 1,2,3 )
p1 + p2

import FilterDesign
import PolyTransform
import TFNtransform
import TFNs

tf = FilterDesign.butterworth(2)

butts = [ FilterDesign.butterworth(n) for n in 1:10 ]


# transform 1rad/s to 1000Hz:
t1 = TFNtransform.lowpass( butts[5], 1.0/2pi, 1000.0 )




using Plots

fs = 10.0 .^ range( 1.0, 6.0 ; length = 1000 ) 
t1_dB = response_s_dB( t1, fs )



# Bilinear transformation that preserves 1e3 with a sample rate of 100e3
bl_num, bl_denom = PolyTransform.bilinear_poly( 1/(2π) , 1e3, 100e3 )
butt5z   = TFNtransform.apply_rational_transform( butts[5], bl_num, bl_denom )

bl_num, bl_denom = PolyTransform.bilinear_poly_zm1( 1/(2π) , 1e3, 100e3 )
butt5zm1 = TFNtransform.apply_rational_transform( butts[5], bl_num, bl_denom )

butt5z_dB = response_z_dB( butt5z, fs, 100e3 )
butt5zm1_dB = response_zinv_dB( butt5zm1, fs, 100e3 )

plot( fs, t1_dB , xaxis=:log)
plot!( fs, butt5z_dB )
plot!( fs, butt5zm1_dB )


plot(  fs, response_s_degrees(t1    , fs )  , xaxis=:log)
plot!( fs, response_z_degrees(butt5z, fs, 100e3 )  , xaxis=:log)
plot!( fs, response_zinv_degrees(butt5zm1, fs, 100e3 )  , xaxis=:log)




# calculate the frequency response of a system

f_to_z( f, fs ) = cispi( 2*f/fs )
f_to_zm1( f, fs ) = conj( cispi( 2*f/fs ) )

function freqz( sys, f )
        [ abs( response( sys, f1 )[1] ) for f1 in f ]
end
function freqzdB( sys, f )
        [ 20*log10( abs( response( sys, f1 )[1] ) ) for f1 in f ]
end
function freqphase( sys, f )
        [ angle( response( sys, f1 )[1] ) for f1 in f ]
end
function freqphasedegrees( sys, f )
        [ rad2deg( angle( response( sys, f1 )[1] ) ) for f1 in f ] 
end
function response( sys::Processors.Compose, f, fs = 1.0, z = f_to_zm1(f,fs) )
        h1,f1,fs1,z1 = response( sys.p1, f, fs, z )        
        h2,f2,fs2,z2 = response( sys.p2, f1, fs1, z1 )
        return h1 * h2, f2, fs2, z2
end
function response( sys::Processors.Compose1, f, fs = 1.0, z = f_to_zm1(f,fs) )
        h1,f1,fs1,z1 = response( sys.p1, f, fs, z )        
        h2,f2,fs2,z2 = response( sys.p2, f1, fs1, z1 )
        return h1 * h2, f2, fs2, z2
end
function response( sys::Processors.FIR, f, fs = 1.0, z = f_to_zm1(f,fs) )
        h = evalpoly(z, sys.coeffs )
        return h, f, fs, z
end

function response( sys::Processors.Gain, f, fs = 1.0, z = f_to_zm1(f,fs) )
        return sys.gain, f, fs, z
end
function response( sys::Processors.ForwardFeedback, f, fs = 1.0, z = f_to_zm1(f,fs) )
        B,_,_,_ = response( sys.forward, f, fs, z )
        A,_,_,_ = response( sys.reverse, f, fs, z )
        h = B/(1+z*A*B), f, fs, z

        return h
end

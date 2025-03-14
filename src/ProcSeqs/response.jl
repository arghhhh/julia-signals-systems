

# calculate the frequency response of a system

f_to_z( f, fs ) = cispi( 2*f/fs )
f_to_zm1( f, fs ) = conj( cispi( 2*f/fs ) )

function freqz( sys, f, fs = 1.0 )
        [ abs(  response( sys, f1, fs )[1] ) for f1 in f ]
end
function freqz2( sys, f, fs = 1.0 )  # response squared
        [ abs2( response( sys, f1, fs )[1] ) for f1 in f ]
end
function freqzdB( sys, f, fs = 1.0 )
        [ 20*log10( abs( response( sys, f1 )[1] ) ) for f1 in f ]
end
function freqphase( sys, f, fs = 1.0 )
        [ angle( response( sys, f1, fs )[1] ) for f1 in f ]
end
function freqphasedegrees( sys, f, fs = 1.0 )
        [ rad2deg( angle( response( sys, f1, fs )[1] ) ) for f1 in f ] 
end
function freqz_grpdelay( sys, f, fs = 1.0 )
        [ response( sys, f1, fs )[2] for f1 in f ]
end

function response( sys::Processors.Compose, f, fs = 1.0, z = f_to_zm1(f,fs) )
        h1,d1,f1,fs1,z1 = response( sys.p1, f, fs, z )        
        h2,d2,f2,fs2,z2 = response( sys.p2, f1, fs1, z1 )
        return h1 * h2, d1 + d2, f2, fs2, z2
end
function response( sys::Processors.Compose1, f, fs = 1.0, z = f_to_zm1(f,fs) )
        h1,d1,f1,fs1,z1 = response( sys.p1, f, fs, z )        
        h2,d2,f2,fs2,z2 = response( sys.p2, f1, fs1, z1 )
        return h1 * h2, d1 + d2, f2, fs2, z2
end
function response( sys::Processors.FIR, f, fs = 1.0, z = f_to_zm1(f,fs) )
        h = evalpoly(z, sys.coeffs )
        p_ramped = evalpoly( z, sys.coeffs .* ( 0:length(sys.coeffs)-1 ) )
        delay = real( p_ramped / h ) / fs

        return h, delay, f, fs, z
end
function response( sys::Processors.IIR_poles, f, fs = 1.0, z = f_to_zm1(f,fs) )
        h1 = evalpoly(z, sys.coeffs )
        h = 1.0 / h1
        p_ramped = evalpoly( z, sys.coeffs .* ( 0:length(sys.coeffs)-1 ) )
        delay = -real( p_ramped / h1 ) / fs
        return h, delay, f, fs, z
end
function response( sys::Processors.Gain, f, fs = 1.0, z = f_to_zm1(f,fs) )
        return sys.gain, 0.0, f, fs, z
end
function response( sys::Processors.ForwardFeedback, f, fs = 1.0, z = f_to_zm1(f,fs) )
        B,df,_,_,_ = response( sys.forward, f, fs, z )
        A,dr,_,_,_ = response( sys.reverse, f, fs, z )

        delay = NaN  # TBD
        h = B/(1+z*A*B), delay, f, fs, z

        return h
end
function response( sys::Processors.Downsample, f, fs = 1.0, z = f_to_zm1(f,fs) )

        h1 = 1.0
        d1 = 0.0
        fs1 = fs / sys.n
        z1 = f_to_zm1(f,fs1)

        return h1, d1, f, fs1, z1
end
function response( sys::Processors.Upsample, f, fs = 1.0, z = f_to_zm1(f,fs) )

        h1 = 1.0
        d1 = 0.0
        fs1 = fs * sys.n
        z1 = f_to_zm1(f,fs1)

        return h1, d1, f, fs1, z1
end

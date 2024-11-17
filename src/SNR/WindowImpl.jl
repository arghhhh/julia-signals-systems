
module WindowImpl

function D( f, N )
        r = if abs( sinpi( f / N ) ) < 1e-20
                # apply L'Hôpital's rule:
                N * cospi( f ) / cospi( f/N )
        else
                sinpi( f ) / sinpi( f / N )
        end
        return r * complex( cospi( f * (N-1)/N ) , sinpi( f * (N-1)/N ) )
end

D2( f, N, off ) =  0.5 * ( D( f - off, N ) + D( f + off, N ) )
    
# frequency response of window, f is in units of bins
function W( f, N, w_coeffs )
        return w_coeffs[1] * D(f,N) + sum( w_coeffs[k] * D2( f, N, k-1 ) for k in 2 : length( w_coeffs ) )
end
    
# dot products of the various combinations of window, sine, cosine:
w_cos( f , N, w_coeffs ) = real(0.5*( W(f, N, w_coeffs) + W(-f, N, w_coeffs) ) )
w_sin( f , N, w_coeffs ) = imag(0.5*( W(f, N, w_coeffs) - W(-f, N, w_coeffs) ) )

w_cos_cos( f1, f2,  N, w_coeffs ) =  0.5*(w_cos(f1 + f2, N, w_coeffs) + w_cos(f1 - f2, N, w_coeffs) );
w_cos_sin( f1, f2,  N, w_coeffs ) =  0.5*(w_sin(f1 + f2, N, w_coeffs) - w_sin(f1 - f2, N, w_coeffs) );
w_sin_cos( f1, f2,  N, w_coeffs ) =  0.5*(w_sin(f1 + f2, N, w_coeffs) + w_sin(f1 - f2, N, w_coeffs) );
w_sin_sin( f1, f2,  N, w_coeffs ) = -0.5*(w_cos(f1 + f2, N, w_coeffs) - w_cos(f1 - f2, N, w_coeffs) );
    

end # module



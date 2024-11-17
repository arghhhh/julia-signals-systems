

# define some useful functions for when a window is defined as a cosine series

module Windows

const nuttall_window_coeffs = [ 0.338946, -0.481973, 0.161054, -0.018027 ]
const rectangular_window_coeffs = [1]
const hann_window_coeffs = [ 0.5, -0.5 ]
const hamming_window_coeffs = [ 0.54, -0.46 ]

# set a default window
const default_window_coeffs = nuttall_window_coeffs

# (an alternate implementation exists in WindowImplRef.jl)
import WindowImpl: w_cos, w_sin, w_cos_cos, w_cos_sin, w_sin_cos, w_sin_sin


# create a window as a vector, length N:
function make_window( N, w_coeffs )
    return sum( w_coeffs[i] * cospi.( 2 * (0:N-1) * (i-1) / N ) for i in 1:length( w_coeffs) )
end

# same as sum( w .* w )
window_power_gain(  N, w_coeffs = default_window_coeffs ) =
        sum( map( j-> w_coeffs[j+1] * w_cos( j, N, w_coeffs  )
                , 0:( length( w_coeffs )-1) )
                )


# the ez versions are such that they are 1.0 for rectangular windows
ez_window_gain( N,w_coeffs)       = w_cos(0.0,N,w_coeffs) / N
ez_window_gain_power( N,w_coeffs) = window_power_gain( N,w_coeffs) / Float64(N)


end

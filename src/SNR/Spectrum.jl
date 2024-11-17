


module Spectrum

using  FFTW
import Windows

#=

Make a spectrum estimate by doing a windowed FFT

Two variants /uses for spectrums depending on use:

For plots, want the y-axis to be scaled such that sinusoid amplitude can be read directly
Usualy scaled so that +/-1.0 peak sinuosid appears with an amplitude of 0.0dB.
This scaling is really only useful for plots, so to make things simpler, I include the 
conversion to dB.

For measuring noise power, want the spectrum to be scaled such that summing the power in the bins
gives the expected power.  In this application, the DC and Nyquist (fs/2) bins are special.
This is because the power of 1,1,1,1,1,1... or 1,-1,1,-1,1,-1,1... sequence is twice that of 
a sinusoid at any other frequency with peak amplitude +1, -1.

Want the power summed from DC to Nyquist to match that determined from the time domain view

=#


# an consequence of the real FFT is that we must consider the "ac" bins differently
# compared with the "dc" and "nyquist" bins - these are always real numbers
# when summing for power, need to multiply ac bins by 2 to take account of the
# redundant "half" of the spectrum that we are not storing


# For following spectrum_power(...) satisfies
#   sum( x .* x ) / length( x ) approx= sum( spectrum_power( x, w_coeffs ) )
# this is only approximate because the LHS is unwindowed and the RHS is windowed
# if w_coeffs = [1], then LHS and RHS match (other than numerical precision)

# TODO separate the window length from the FFT length
#      to allow zero padded windows
#      so that window length could be prime number
#      but FFT length could be the next higher power of two

# spectrum returned is just a vector - no datatype encapsulation
function spectrum( x, w_coeffs = Windows.default_window_coeffs )
        N = length( x )
        w = Windows.make_window( N, w_coeffs )
        gain = 2.0 / ( N *N * Windows.ez_window_gain_power( N,w_coeffs) )
        s1 = gain * abs2.( rfft( w .* x ) )
        s1[1] *= 0.5
        s1[ length(s1) ] *= 0.5
        return s1
end

function bandlimited_power( s, f_lo, f_hi, fs = 1.0 )
        # s is the power spectrum as returned by spectrum_power

        # the frequencies f_lo, f_hi are quantized to the nearest bin
        # and no adjustment made for partial bin coverage

        # map x_lo..x_hi to y_lo..y_hi without thinking too hard:
        linear_range_map( x_lo, x_hi, y_lo, y_hi ) = x->(x - x_lo) / (x_hi-x_lo) * (y_hi - y_lo) + y_lo

        f_to_i = linear_range_map( 0.0, fs/2, 1, length(s) )
        i_lo =      round( Int, f_to_i( f_lo ) )
        i_hi = min( round( Int, f_to_i( f_hi ) ), length(s) )

        bandlimited_noise = sum( s[i_lo:i_hi] ) 
        return bandlimited_noise
end

# same as spectrum_bandlimited_power, but with a dB conversion at the end:
function bandlimited_power_dB( s, f_lo, f_hi, fs = 1.0 )

        bandlimited_noise = bandlimited_power( s, f_lo, f_hi, fs )

        power_to_dB(x) = 10*log10( x )

        bandlimited_noise_dB = power_to_dB( bandlimited_noise )
        return bandlimited_noise_dB
end

# this version is for plots - do not use to sum power
# It is similar to above except
# it is scaled such that sinusoid components are referenced to a
# sin/cos signal of amplitude 1 (power -3dB)
# and DC is referenced relative to ones(N) (power 0dB)
function spectrum_dB( x, w_coeffs = Windows.nuttall_window_coeffs )
        N = length( x )
        w = Windows.make_window( N, w_coeffs )
        gain = 2.0 / ( N * Windows.ez_window_gain( N,w_coeffs) )
        w *= gain
        s1 = 10.0 * log10.( abs2.( rfft( w .* x ) ) .+ 1e-50 )
        # fix up DC term
        s1[1] -= 20.0*log10(2.0)

        # fix up Nyquist ?

        return s1
end

# with a corresponding frequency axis that can be fed directly to Plots.plot:
function axis_spectrum_dB( x, fs=1.0, w_coeffs = Windows.nuttall_window_coeffs )
        s = spectrum_dB( x, w_coeffs )
        a = range( 0.0, fs/2 ; length = length(s) )
        return a,s
end

end # module

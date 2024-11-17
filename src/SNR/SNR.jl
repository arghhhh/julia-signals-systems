
module SNR

import Windows

# this module includes code to calculate Signal to Noise Ratios (SNR)
# and other signal processing performance metrics 
# It works by doing a weighted least squares fit of the signal to a set of 
# sinusoidal basis functions.  These basis sinusoids need to have precisely known 
# frequencies - so this method is only directly applicable to simulation environments 
# where the signal frequencies are precisely known.  (It can be extended to work on 
# measured (lab) data by making the frequencies the parameters of an optimization problem)

# The weights in the weighted least squares have the same role as applying a window
# It makes the estimate less sensitive to nearby tonal interferers that are not 
# in the basis set.
# A common example of this occurs when observing the output of a halfband interpolating 
# filter at high frequency - the signal and the first alias are close in frequency, but 
# often only the signal frequency has been included in basis set

# It is possible to replace all the vector calls of sin and cos - by setting up an 
# iteration that rotates around the unit circle at the prescribed rate.
# But computers are fast these days, so I haven't bothered to do it that way for years....
# This could save memory (the full A matrix never needs to exist) and time, probably at the 
# expense of accuracy.

# "make_vector" solves the problem that the input may be an iterator that could be expensive to 
# to collect - or even gives different results each time due to calls to random number generators
# This will make a new vector, unless the input is already a vector
# The input could be a view of another vector - so don't mutate the output of this
# (If you want to mutate the vector - just make an unconditional copy using collect)
make_vector( v::AbstractArray ) = v
make_vector( it               ) = collect(it)

# make A.
# A is the matrix of basis vectors
# A'A is the matrix of dot products of the basis vectors - used for solving the normal equations for least squares
# the basis sines and cosines can have arbitrary frequencies - not necessarily on a bin frequency 
# Columns are the basis signals in the order:
# DC cos( fs[1] ) sin( fs[1] ) cos( fs[2] ) sin( fs[2] ) ...
function make_A( fs1, N )
	t = 0 : N-1
	A = zeros( N, 2*length(fs1)+1 )
	A[:,1] .= 1
	for (i,f) in enumerate( fs1 )
		A[:, 2*i   ] = cospi.( 2*f*t )
		A[:, 2*i+1 ] = sinpi.( 2*f*t )
	end
	return A
end




# this is equivalent to: A' * ( window .* A )
function make_snr_matrix( f, N, w_coeffs )
	k = 2*length(f)+1
	m = zeros(k,k)
	m[1,1] = Windows.w_cos( 0.0, N, w_coeffs )
	for i in 1:length(f)
		m[ 2*i  , 1 ] = m[ 1, 2*i   ] = Windows.w_cos( f[i] * N, N, w_coeffs )
		m[ 2*i+1, 1 ] = m[ 1, 2*i+1 ] = Windows.w_sin( f[i] * N, N, w_coeffs )
	end
	for i in 1:length(f), j in 1:length(f)
		m[ 2*i   , 2*j   ] = Windows.w_cos_cos( f[i] * N , f[j] * N, N, w_coeffs )
		m[ 2*i   , 2*j+1 ] = Windows.w_cos_sin( f[i] * N , f[j] * N, N, w_coeffs )
		m[ 2*i+1 , 2*j   ] = Windows.w_sin_cos( f[i] * N , f[j] * N, N, w_coeffs )
		m[ 2*i+1 , 2*j+1 ] = Windows.w_sin_sin( f[i] * N , f[j] * N, N, w_coeffs )
	end

	return m
end

function least_squares_fit( y, f, A, w_coeffs )
	# this is the fast version where
	# A'wA is determined by formula
	N = length( y )
	m = make_snr_matrix( f, N, w_coeffs )  # A'wA
	w = Windows.make_window( N, w_coeffs )

	# equivalent to A'wA \ A'wy
	return m \ ( A' * ( w .* y ) )
end

function slow_least_squares_fit( y, f, A, w_coeffs )
	N = length( y )

	w = Windows.make_window( N, w_coeffs )
	m = A' * ( w .* A )  # make the AwA matrix the slow way...

	return m \ ( A' * ( w .* y ) )
end

function slow_least_squares_fit2( y, f, A, w_coeffs )
	N = length( y )
	# added small positive value because some window values near the ends become negative
	# due to numerical precision - and sqrt doesn't like negative numbers...
	w = Windows.make_window( N, w_coeffs ) .+ 1e-16
	sqrt_w = sqrt.( w )

	# the following is doing a weighted least squares fit, using the unweighted least squares solver:
	Aw = A .* sqrt_w
	return Aw \ ( y .* sqrt_w )
end

# in some cases, you want to remove DC before looking further
# eg if the signal energy at DC and at a low frequency
# then these can merge due to the window

function remove_dc( y1, window_coeffs = Windows.default_window_coeffs )

	y = make_vector(y1)

	n_samples = length(y)

	A = make_A( [], length(y) )
	fs1 = []
	bhat = least_squares_fit( y, fs1, A, window_coeffs )
	residual = y - A * bhat

	dc = bhat[1]  # this is a windowed estimate

	return residual, dc
end

function estimate_dc_ac( y1, window_coeffs = Windows.default_window_coeffs )
	y = make_vector(y1)
	n_samples = length(y)

	A = make_A( [], length(y) )
	fs1 = []
	bhat = least_squares_fit( y, fs1, A, window_coeffs )
	residual = y - A * bhat

	dc = bhat[1]  # this is a windowed estimate

	# ac = sqrt( sum( sequence(residual) |> x->x*x ) / n_samples )
	ac = sqrt( sum( x*x for x in residual ) / n_samples )

	return dc,ac
end

function estimate_ac_windowed( v, w )
    # v is the vector of data
    # w is the window - same length as v (not just the coefficients)
    # this returns approx 0.707 for sin(x)
    n_samples = length(v)
    return sqrt( sum( w.*w.*v.*v ) / ( Windows.window_power_gain( n_samples, Windows.default_window_coeffs ) ) )
end

function determine_snr( v, freqs , window_coeffs = Windows.default_window_coeffs )

	y = make_vector(v) 
	n_samples = length(y)

	A = make_A( freqs, n_samples )
	bhat = least_squares_fit( y, freqs, A, window_coeffs )
	residual = y - A * bhat

	mag = zeros( length(freqs) )
	for i in 1:length(freqs)
		mag[i] = hypot( bhat[2*i], bhat[2*i+1] )
	end

	return mag, residual, bhat

end


end # module


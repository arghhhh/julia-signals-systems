

module WindowImplRef

import LinearAlgebra


# this is a "reference" version that "explains" what these functions do.
# These are not used other than for test purposes.
# The "real" versions are in "WindowImpl.jl"

cosinusoid( f, N ) = cospi.( 2*f * ( 0:N-1) )
sinusoid(   f, N ) = sinpi.( 2*f * ( 0:N-1) )

# theta is such that -1..1 maps to -180..+180degrees or equivalently -pi..+pi
cosinusoid( f, N, theta ) = cospi.( 2*f * ( 0:N-1) + theta )
sinusoid(   f, N, theta ) = sinpi.( 2*f * ( 0:N-1) + theta )


function make_window( N, w_coeffs )
        return sum( w_coeffs[i] * cospi.( 2 * (0:N-1) * (i-1) / N ) for i in 1:length( w_coeffs) )
end

# slow versions for reference
function w_cos( f , N, w_coeffs )
    w = make_window( N, w_coeffs )
    sum( w .* cosinusoid( f/N, N ) )
end

function w_sin( f , N, w_coeffs )
    w = make_window( N, w_coeffs )
    sum( w .*   sinusoid( f/N, N ) )
end

function w_cos_cos( f1, f2 , N, w_coeffs )
    w = make_window( N, w_coeffs )
    LinearAlgebra.dot( w .* cosinusoid( f1/N, N ) , cosinusoid( f2/N, N ))
end

function w_cos_sin( f1, f2 , N, w_coeffs )
    w = make_window( N, w_coeffs )
    LinearAlgebra.dot( w .* cosinusoid( f1/N, N ) ,   sinusoid( f2/N, N ))
end

function w_sin_cos( f1, f2 , N, w_coeffs )
    w = make_window( N, w_coeffs )
    LinearAlgebra.dot( w .*   sinusoid( f1/N, N ) , cosinusoid( f2/N, N ))
end

function w_sin_sin( f1, f2 , N, w_coeffs )
    w = make_window( N, w_coeffs )
    LinearAlgebra.dot( w .*   sinusoid( f1/N, N ) ,   sinusoid( f2/N, N ))
end

end # module

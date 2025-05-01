

include( "env.jl")

using Test

import WindowImpl
import WindowImplRef


import Windows

w_coeffs = Windows.default_window_coeffs
N = 128



all_approx_equal( xs, ys; atol = 1e-10 ) = all( isapprox( x,y; atol=atol ) for (x,y) in zip( xs, ys ) )



fs = range( 0.0, 3N ; length = 1234 )

v1 = [ WindowImpl.w_cos(    f , N, w_coeffs ) for f in fs ]
v2 = [ WindowImplRef.w_cos( f , N, w_coeffs ) for f in fs ]

@test all_approx_equal( v1, v2 )

v1 = [ WindowImpl.w_sin(    f , N, w_coeffs ) for f in fs ]
v2 = [ WindowImplRef.w_sin( f , N, w_coeffs ) for f in fs ]

@test all_approx_equal( v1, v2 )


@testset "windows" begin
        @testset for f in range( 0.0, 3N ; length = 1234 )
                @test isapprox( WindowImpl.w_cos( f , N, w_coeffs ), WindowImplRef.w_cos(    f , N, w_coeffs ) ; atol = 1e-10 )
        end
        @testset for f in range( 0.0, 3N ; length = 1234 )
                @test isapprox( WindowImpl.w_sin( f , N, w_coeffs ), WindowImplRef.w_sin(    f , N, w_coeffs ) ; atol = 1e-10 )
        end
        @testset for f1 in range( 0.0, 4N ; length = 8*51+1 ), f2 in range( 0.0, 4N ; length = 8*53+1 )
                @test isapprox( WindowImpl.w_cos_cos( f1,f2 , N, w_coeffs ), WindowImplRef.w_cos_cos( f1,f2, N, w_coeffs ) ; atol = 1e-10 )
        end
        @testset for f1 in range( 0.0, 4N ; length = 8*51+1 ), f2 in range( 0.0, 4N ; length = 8*53+1 )
                @test isapprox( WindowImpl.w_cos_sin( f1,f2 , N, w_coeffs ), WindowImplRef.w_cos_sin( f1,f2, N, w_coeffs ) ; atol = 1e-10 )
        end
        @testset for f1 in range( 0.0, 4N ; length = 8*51+1 ), f2 in range( 0.0, 4N ; length = 8*53+1 )
                @test isapprox( WindowImpl.w_sin_cos( f1,f2 , N, w_coeffs ), WindowImplRef.w_sin_cos( f1,f2, N, w_coeffs ) ; atol = 1e-10 )
        end
        @testset for f1 in range( 0.0, 4N ; length = 8*51+1 ), f2 in range( 0.0, 4N ; length = 8*53+1 )
                @test isapprox( WindowImpl.w_sin_sin( f1,f2 , N, w_coeffs ), WindowImplRef.w_sin_sin( f1,f2, N, w_coeffs ) ; atol = 1e-10 )
        end

        @testset for n1 = range( 1000, 100000 ; length = 100 )
                n = round(Int64,n1)
                w_coeffs = Windows.nuttall_window_coeffs
                w = Windows.make_window(n,w_coeffs)
                @test isapprox( Windows.window_power_gain(n,w_coeffs), sum(w.*w) ; atol = 1e-10 )
        end

end


nothing


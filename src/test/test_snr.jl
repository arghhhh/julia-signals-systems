
include( "env.jl")

using Test
using Plots

import Statistics
import Windows
import SNR
import Spectrum


@testset begin

        # there is no science behind any of the atol (absolute tolerance) settings here
        # - so there is finite chance of isolated failures depending on the random numbers generated

        # make up some test data:

        n = 2048
        fsig = 2.4
        sig = sinpi.( ( 2fsig / n) .* range( 0,n-1;length = n ) )
        freqs = [ fsig/n ]

        A = SNR.make_A( freqs, n )
        y = copy(sig)
        window_coeffs = Windows.default_window_coeffs
        bhat1 = SNR.least_squares_fit(       y, freqs, A, window_coeffs )
        bhat2 = SNR.slow_least_squares_fit(  y, freqs, A, window_coeffs )
        bhat3 = SNR.slow_least_squares_fit2( y, freqs, A, window_coeffs )
        residual = y - A * bhat1

        @test isapprox( 0.0, maximum( abs.( residual ) ), atol = 1e-10 )
        @test isapprox( 0.0, maximum( abs.( bhat1 - [ 0, 0, 1 ] ) ), atol = 1e-10 )
        @test isapprox( 0.0, maximum( abs.( bhat2 - [ 0, 0, 1 ] ) ), atol = 1e-10 )
        @test isapprox( 0.0, maximum( abs.( bhat3 - [ 0, 0, 1 ] ) ), atol = 1e-10 )


        n = 10000000
        y = 2.0 .+ 3.0.*randn(n)
        dc,ac = SNR.estimate_dc_ac(y)

        @test isapprox( 2.0, dc ; atol = 0.01 )
        @test isapprox( 3.0, ac ; atol = 0.01 )

        y = sinpi.( ( 2*1.5 / n) .* range( 0,n-1;length = n ) )

        # this illustrates the windowed estimate of dc and ac
        # any sinusoids with "a few" repitions will be treated as ac, regardless 
        # of whether there are an integer number of repitions with in the window
        # in this example, the zero dc is recovered, even though the mean is non zero
        # 10.5 cycles of sine wave:
        n = 1000000
        y = sinpi.( ( 2*10.5 / n) .* range( 0,n-1;length = n ) )
        # mean of rectified sine wave is 2/pi, so mean of 10.5 cycles is 2/pi/21
        @test isapprox( Statistics.mean(y), 2/pi/21 ; atol = 1e-6 )
        dc,ac = SNR.estimate_dc_ac(y)
        @test isapprox( dc, 0.0         ; atol = 1e-4 )
        @test isapprox( ac, 1/sqrt(2.0) ; atol = 1e-4 )

        y = randn(1024*1024)
        s = Spectrum.spectrum(y)
        p = Spectrum.bandlimited_power(s,0.0,0.5,1.0)
        pdB = Spectrum.bandlimited_power_dB(s,0.0,0.5,1.0)

        @test isapprox( p   , 1.0; atol = 0.01 )
        @test isapprox( pdB , 0.0; atol = 0.05 )

        y = randn(1024*1024) .+ 1.0

        s = Spectrum.spectrum(y)
        p = Spectrum.bandlimited_power(s,0.0,0.5,1.0)
        pdB = Spectrum.bandlimited_power_dB(s,0.0,0.5,1.0)

        @test isapprox( p  , 2.0       ; atol = 0.01 ) # 1 from DC, 1 from the AC noise
        @test isapprox( pdB, 10log10(2); atol = 0.05 ) # ie +3dB

        p = Spectrum.bandlimited_power(s,0.0,0.25,1.0)
        pdB = Spectrum.bandlimited_power_dB(s,0.0,0.25,1.0)

        @test isapprox( p  , 1.5         ; atol = 0.01 ) # 1 from DC, 0.5 from the bandlimited AC noise
        @test isapprox( pdB, 10log10(1.5); atol = 0.1 ) # 



        n = 65536
        dc = 0.01
        noise = 0.000001  # ie -120dB
        ac    = 1.0       # ie -3dB
        f = 15.34567 # in bins
        y = ac .* sinpi.( ( 2*f / n) .* range( 0,n-1;length = n ) ) .+ noise .* randn(n) .+ dc
        
        a,s = Spectrum.axis_spectrum_dB( y )
        plot( a,s, xlim=(0,0.005), ylim=(-200,0))
        
        mag, residual, bhat = SNR.determine_snr( y, [f/n] )
        r = Spectrum.spectrum_dB( residual )
        plot!( a,r )
        
        # check that the dc level, and the ac sinuosid level are properly recovered:
        @test isapprox( 0.0, maximum( abs.( bhat - [ dc, 0, ac ] ) ), atol = 1e-6 )
        # and check that the noise level is properly recovered:
        rs = Spectrum.spectrum( residual )
        p = Spectrum.bandlimited_power(rs,0.0,0.5,1.0)
        pa = sqrt(p)  # convert from power to rms
        @test isapprox( pa, noise, rtol = 0.01 )
end



if false
        # check run time for the various versions, for a larger problem:

        n = 16 * 1024 * 1024

        fsig = 0.001234

        sig = sinpi.( ( 2fsig / n) .* range( 0,n-1;length = n ) )

        freqs = [ i*fsig/n for i in 1:10 ]

        A = SNR.make_A( freqs, n )

        y = copy(sig)
        window_coeffs = Windows.default_window_coeffs

        fn() = begin
                @time bhat1 = SNR.least_squares_fit(       y, freqs, A, window_coeffs )
                @time bhat2 = SNR.slow_least_squares_fit(  y, freqs, A, window_coeffs )
                @time bhat3 = SNR.slow_least_squares_fit2( y, freqs, A, window_coeffs )
        end
        fn()
        fn()
end






nothing



#  
#  #TODO
#  
#  # standard SNR tests
#  # sweep amplitude of sine wave with known noise level GaussianRandom
#  # sweep frequency
#  # sweep frequency of an interferer which is not in the basis set
#  


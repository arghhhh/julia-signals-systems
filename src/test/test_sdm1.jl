

include( "env.jl")

using Test
using Plots

import Sequences:  Sequences, Test_Range, concatenate, info, sequence
import Processors: Processors, Downsample, Upsample, Vectorize, Take, fir, Map, MapT, Integrator, Filter, Flatten
import SNR
import Spectrum

xs = 0.8 .* ones(100)

ys = xs |> Processors.SDM1() |> collect


if true

        # DC Sweep

        n = 65536  # number of samples for each simulation

        dc_range = range( -1.1, 1.1 ; length = 1001 )

        y_dc = zeros( length(dc_range) )
        y_ac = zeros( length(dc_range) )
        y_pdB = zeros( length(dc_range) )
        threadid = zeros( Int64, length(dc_range) )
        #Threads.@threads for (i,dc) in enumerate(dc_range)
        Threads.@threads for i in 1:length(dc_range)
                threadid[i] = Threads.threadid()
                dc = dc_range[i]
                x = dc .* ones(n)
                y = x |> Processors.SDM1() |> collect
                y_dc[i],y_ac[i] = SNR.estimate_dc_ac(y)

                # calculate bandlimited ac:

                mag, residual, bhat = SNR.determine_snr( y, [] )  # least squares fit - just DC
                s = Spectrum.spectrum(residual)
                y_pdB[i] = Spectrum.bandlimited_power_dB(s,0.0,0.5/8,1.0)

        end
        plot( dc_range, y_pdB, ylim=(-50,0 ) )
        plot!( xlabel="Input DC Level")
        plot!( ylabel="Inband Noise Level")
        plot!( legend=nothing )

        savefig( "sdm1_dc_sweep.svg")
end

if true

        # AC Level Sweep

        acdB_range = range( -60, 0.0 ; length = 121 )
        n = 65536  # number of samples for each simulation
        fsig = 0.001

        y_dc = zeros( length(acdB_range) )
        y_ac = zeros( length(acdB_range) )
        y_pdB = zeros( length(acdB_range) )
        y_sigdB = zeros( length(acdB_range) )
        threadid = zeros( Int64, length(acdB_range) )
        #Threads.@threads for (i,dc) in enumerate(acdB_range)
        x_fullscale = sinpi.( 2fsig .* (0:(n-1) ) )
        # Threads.@threads 
        for i in 1:length(acdB_range)
                threadid[i] = Threads.threadid()
                ac = 10.0 ^ (acdB_range[i]/20.0)  # from dB
                x = ac .* x_fullscale
                y = x |> Processors.SDM1() |> collect
                y_dc[i],y_ac[i] = SNR.estimate_dc_ac(y)

                # calculate bandlimited ac:
                mag, residual, bhat = SNR.determine_snr( y, [fsig] )  # least squares fit, with one sine component
                s = Spectrum.spectrum(residual)
                y_pdB[i] = Spectrum.bandlimited_power_dB(s,0.0,0.5/8,1.0)
                y_sigdB[i] = 20.0 * log10( mag[1] )

        end
        plot( acdB_range, y_sigdB, ylim=(-60,0 ) )
        plot!( xlabel="Input Level (dB)")
        plot!( ylabel="Output Level (dB)")
        plot!( legend=nothing )

        savefig( "sdm1_ac_sweep.svg")

end





include( "env.jl")

using Test

@testset verbose=true "all" begin

        include( "test-examples.jl" )
        include( "test_snr.jl"  )
        include( "test_windows.jl" )
        include( "test-arith-seq-proc.jl" )
        include( "test-response.jl" )
        include( "test_sdm1.jl" )
        include( "test-FIR.jl" )
        include( "test-IIR.jl" )

end
nothing



include( "env.jl")

using Test

@testset "all" begin

        include( "test_snr.jl"  )
        include( "test_windows.jl" )
        include( "test-arith-seq-proc.jl" )
        include( "test-response.jl" )
        include( "test_sdm1.jl" )

end
nothing


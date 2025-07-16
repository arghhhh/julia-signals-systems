
module DSPfns



# TODO:
# what if one of v1 or v2 is actually a tuple
# eg a tuple consisting of fixed point constants
# - then in that case, there isn't an overall eltype
# The Processors.FIR filter gets this correct - so maybe just 
# adopt that method?
conv1( v1, v2 ) = begin
        l1 = length(v1)
        l2 = length(v2)

        # TODO: https://docs.julialang.org/en/v1/manual/methods/#Output-type-computation
        # should replace promote_type with promote_op
        # see the Julia documentation example
        z = zeros( promote_type( eltype(v1), eltype(v2) ), l1 + l2 -1 )
        for i in eachindex(v2)
                z[ i:i+l1-1 ] += v2[i] .* v1
        end
        return z
end
conv( v1, v2 ) = length(v1) >= length(v2) ? conv1( v1, v2 ) : conv1( v2, v1 )



end # module

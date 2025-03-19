
module DSPfns

conv1( v1, v2 ) = begin
        l1 = length(v1)
        l2 = length(v2)
        z = zeros( promote_type( eltype(v1), eltype(v2) ), l1 + l2 -1 )
        for i in eachindex(v2)
                z[ i:i+l1-1 ] += v2[i] .* v1
        end
        return z
end
conv( v1, v2 ) = length(v1) >= length(v2) ? conv1( v1, v2 ) : conv1( v2, v1 )



end # module

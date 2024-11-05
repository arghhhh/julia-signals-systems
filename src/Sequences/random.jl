

import Random

struct UniformRandom <: abstract_sequence
    lo
    hi
    seed
    rng   # the function, not the instance
    function UniformRandom( lo, hi,  seed = nothing, rng = Random.default_rng )
        new( lo,hi, seed, rng )
    end
    
end


Base.IteratorSize( ::Type{UniformRandom} ) = Base.IsInfinite()
Base.eltype(       ::Type{UniformRandom} ) = Float64


function Base.iterate( u::UniformRandom )
        rng = u.rng()
        if u.seed !== nothing
                Random.seed!( rng, u.seed )
        end
        return u.lo + rand(rng) * (u.hi-u.lo), rng
end

function Base.iterate( u::UniformRandom,rng )
    return u.lo + rand(rng) * (u.hi-u.lo), rng
end


struct GaussianRandom  <: abstract_sequence
        seed
        rng   # the function, not the instance
        function GaussianRandom( seed = nothing, rng = Random.default_rng )
            new( seed, rng )
        end
end
Base.IteratorSize( ::Type{GaussianRandom} ) = Base.IsInfinite()
Base.eltype(       ::Type{GaussianRandom} ) = Float64


function Base.iterate( u::GaussianRandom )
        rng = u.rng()
        if u.seed !== nothing
                Random.seed!( rng, u.seed )
        end
        return randn(rng), rng
    end

function Base.iterate( u::GaussianRandom,rng )
        return randn(rng), rng
end

rectangular_dither = UniformRandom( -0.5, 0.5 )
triangular_dither = rectangular_dither + rectangular_dither


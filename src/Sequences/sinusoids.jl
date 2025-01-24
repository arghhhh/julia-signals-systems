

struct Sinusoid <: infinite_sequence{Float64}
        f       # signal frequency
        fs      # sample rate
        phase0  # initial phase as a fraction (-1.0, 1.0 maps to -pi, +pi)
        Sinusoid( f, fs = 1.0, phase0 = 0.0 ) = new( f, fs, phase0 )
end
    
function Base.iterate( u::Sinusoid, state = ( u.f / u.fs, u.phase0 ) )
        inc, phase = state
        next_phase = phase + u.f / u.fs 
        fpart,ipart = Base.Math.modf( next_phase )
        return sinpi( 2*phase ), (inc,fpart)
end
sample_rate( u::Sinusoid ) = u.fs



struct ComplexSinusoid <: infinite_sequence{ Complex{Float64} }
        f       # signal frequency
        fs      # sample rate
        phase0  # initial phase as a fraction (-1.0, 1.0 maps to -pi, +pi)
        ComplexSinusoid( f, fs = 1.0, phase0 = 0.0 ) = new( f, fs, phase0 )
end

function Base.iterate( u::ComplexSinusoid, state = ( u.f / u.fs, u.phase0 ) )
        inc, phase = state
        next_phase = phase + u.f / u.fs 
        fpart,ipart = Base.Math.modf( next_phase )
        return cispi( 2*phase ), (inc,fpart)
end
sample_rate( u::ComplexSinusoid ) = u.fs
    
    
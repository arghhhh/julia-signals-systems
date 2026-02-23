





function eval_s_domain_f( p::Tuple{T0,T1,T2}, f ) where { T0, T1, T2 }
    s = complex( 0.0, 2*π*f )
    return poly_eval( p, s )
end

function to_dB( x )
    return 20.0 * log10( abs(x) )
end



if false
    pDenom = s_foQ( 1.0, 1/sqrt(2.0) )
    pNum = ( abs( eval_s_domain_f( pDenom, 0.0 ) ), )
    for f in exp10.( range( -3, 3, length=101 ) )
        s = complex( 0.0, 2*π*f )
        print( f, "   ", to_dB( poly_eval( pNum, s ) / poly_eval( pDenom, s )  ), "\n" )
    #    print( f, "   ", to_dB( pNum(s) / pDenom(s)  ), "\n" )
    end
end




function eval_poly_f_fs( p, f, fs = 1.0 )
    zinv = f_to_zinv( f, fs )
    h = p( zinv )
    dB = 20.0*log10( abs(h) )

    return dB
end











if false

    freqs = exp10.( range( -3, 3, length=601 ) )
    s = complex.( 0.0, 2π .* freqs )


    butts = [ butterworth(n) for n in 1:10 ]
    butt = butterworth( 1 )

    mags = to_dB.( map( x->poly_eval( butt, x ), s ) )

    open( "zz.dat", "w" ) do io
        print( io, "Freq" )
        for i in 1:10
            print( io, ", Butterworth", i)
        end
        print( io, "\nHz" )
        for i in 1:10
            print( io, ", dB")
        end
        print( io, "\n" )
        for f in freqs
            s = complex.( 0.0, 2π .* f )
            print( io, f )
            for i in 1:10
                magdB = to_dB( poly_eval( butts[i], s ) )
                print( io, ", ", magdB )
            end
            print( io, "\n" )
        end
    end
end



if false
        
    bl_num, bl_denom = bilinear_poly( 1/(2π) , 1e3, 100e3 )

    butt5z = apply_rational_transform( butts[5], bl_num, bl_denom )

    response = f->f_to_z( f, 100e3 ) |> butt5z |> to_dB

    freqs = LinRange(1.0, 100000.0, 1000 ) 
    freqs = freqs = exp10.( range( -3, 3, length=601 ) ) 
end

function crude_group_delay_s( h, f )
    eps = 1e-3
    f1 = ( 1 - eps ) * f
    f2 = ( 1 + eps ) * f
    w1 = 2π * f1
    w2 = 2π * f2
    s1 = f_to_s(f1)
    s2 = f_to_s(f2)
#    @show s1 s2
    p1 = angle( h( s1 ) )
    p2 = angle( h( s2 ) )
#    @show p1 p2
    delay = -  (p2-p1)/( w2 - w1 )
    return delay
end




function crude_group_delay_z( h, f, fs = 1 )
    eps = 1e-3
    f1 = ( 1 - eps ) * f
    f2 = ( 1 + eps ) * f
    w1 = 2π * f1
    w2 = 2π * f2
    
    p1 = angle( h( f_to_z( f1 , fs ) ) )
    p2 = angle( h( f_to_z( f2 , fs ) ) )
#    delay = - fs * (p2-p1)/( 2π * ( f2 - f1 ) )
    delay = - fs * (p2-p1)/( w2 - w1 )

    return delay
end

if false
    using DelimitedFiles
    open("butt5z.dat", "w") do io

        h = butts[5]

        hz = freqs .|> f->f_to_s(f) |> h
        magdB = hz .|> to_dB
        phase = hz .|> to_phase_degrees
        delay = freqs .|> f->crude_group_delay_s( h, f )

        writedlm(io, [ freqs magdB phase delay ] )
    #    writedlm(io, [ freqs freqs .|> f->f_to_s(f) |> butts[5] |> to_dB ] )

    #    writedlm(io, [ freqs freqs .|> response ])
    #    writedlm(io, [ freqs freqs .|> f->f_to_z( f, 100e3 ) |> butt5z |> to_phase_degrees ])
    end
end

# TODO: this is suspicous - there is anotehr verison of this function
#           further down this file.  Of both are needed, one would be written in terms of the 
#           the other, and they should be next to each other in this source file
function group_delay_z( p::Poly, f::Float64, fs = 1 )
    # this is just a weighted sum of the delays associated with each coefficient
    # eg delay of z^2 is -2
    # ( consider (z^2).(z^-2) where the second factor has a delay of two samples)

    z = f_to_z( f, fs )

    p_ramped = Poly( p.p .* ( 0:length(p.p)-1 ) )

    delay = -real( p_ramped(z) / p(z) )

    return delay
end

# derivative of poly with respect to w for s-domain poly p(jw)
function derivative_s( p::Poly )

    p1 = Poly( zeros( Complex{Float64}, length( p.p ) -1 ) )

#    @show p1
#    @show length( p.p ) length( p1.p )

    ji = 0.0+1.0im
    for i in 2:length( p.p )
        p1.p[i-1] = (i-1) * ji * p.p[i]
        ji = ji * 1im
    end

#    @show p
#    @show p1

    return p1
end

function group_delay_s( p::Poly )
    p1 = derivative_s( p )
    function delay(f)
        s = f_to_s(f)
#        @show s
        return -imag( p1( 2π * f ) / p(s) )
    end
    return delay
end

function group_delay_s( tfn::TFN )
    numerator_delays = group_delay_s.( tfn.numerator )
    denominator_delays = group_delay_s.( tfn.denominator )

#    @show numerator_delays denominator_delays
#    @show length( numerator_delays ) length( denominator_delays )

    function delay( f )
        d_num = 0.0;
        for di in numerator_delays
            d_num = d_num + di(f)
        end
        d_denom = 0.0;
        for di in denominator_delays
            d_denom = d_denom + di(f)
        end
        return d_num - d_denom
    end
    return delay
end

function group_delay_z( p::Poly, z::Complex{T} ) where {T}
    # this is just a weighted sum of the delays associated with each coefficient
    # eg delay of z^2 is -2
    # ( consider (z^2).(z^-2) where the second factor has a delay of two samples)

    p_ramped = Poly( p.p .* ( 0:length(p.p)-1 ) )

    delay = -real( p_ramped(z) / p(z) )

    return delay
end

function group_delay_z( tfn::TFN, z )
    delay_numerator = 0.0


    for p in tfn.numerator
        d = group_delay_z( p, z )
        delay_numerator = delay_numerator + d
    end

    delay_denominator = 0.0
    for p in tfn.denominator
 #       p1 = poly_reciprocal(p.p)
        d = group_delay_z( p, z )
        delay_denominator = delay_denominator + d
    end

#    @show delay_numerator delay_denominator
    return delay_numerator - delay_denominator
end


if false
    io = open("delays.dat", "w")

  #  h = Poly( rand( Float64, 5 ) )

    fc = 1e3
    fs = 100e3
    freqs = LinRange(1, 100.0e3, 1000 )
    freqs = LinRange(1000, 99.0e3/2, 1000 )

    freqs = exp10.( range( 0, 0.999*log10(fs), length=601 ) ) 


    h = Poly( ones(5) )
    h = Poly( 0,0,0,1,0 )

    hs_unscaled = butts[5]
    hs_unscaled = chebyshev( 5, 0.1 )
    hs_unscaled = inverse_chebyshev( 8, 0.1 )


    # lowpass transform from 1rad/s to fc Hz
    lowpass_scaling = 1 / (fc * 2π )
    hs = apply_poly_transform( hs_unscaled, Poly( 0.0, lowpass_scaling ) )

    hs = highpass( hs_unscaled, 1.0/(2*π), 1000.0 )


    bl_num, bl_denom = bilinear_poly( 1/(2π) , 1e3, 100e3 )
    hz = apply_rational_transform( hs_unscaled, bl_num, bl_denom )

    response_s_dB          = freqs .|> f->f_to_s( f ) |> hs |> to_dB
    response_s_phase       = freqs .|> f->f_to_s( f ) |> hs |> to_phase_degrees
    response_s_delay       = freqs .|> group_delay_s( hs )
    response_s_delay_crude = freqs .|> f->crude_group_delay_s( hs, f )

    response_z_dB          = freqs .|> f->f_to_z( f, fs ) |> hz |> to_dB
    response_z_phase       = freqs .|> f->f_to_z( f, fs ) |> hz |> to_phase_degrees
    response_z_delay       = freqs .|> f->group_delay_z( hz, f_to_z( f, fs ) )
    response_z_delay_crude = freqs .|> f->crude_group_delay_z( hz, f, fs )



    writedlm(io, hcat(
          freqs 
        , response_s_dB
        , response_s_phase       
        , response_s_delay       
        , response_s_delay_crude 
        , response_z_dB          
        , response_z_phase       
        , response_z_delay       
        , response_z_delay_crude 
    ) )

    close(io)
#    writedlm(io, [ freqs freqs .|> f->f_to_s(f) |> butts[5] |> to_dB ] )

#    writedlm(io, [ freqs freqs .|> response ])
#    writedlm(io, [ freqs freqs .|> f->f_to_z( f, 100e3 ) |> butt5z |> to_phase_degrees ])
end


# TODO: change this so it takes an iterable to specify the frequencies
# ie response_z( hz::TFN, fs, freqs )
# and returns collect( freqs ) along with the result, ready for a plot call
function response_z( hz::TFN, f1, f2, fs, n )
    f = collect( range( f1, f2, length = n ) )
    tfn_dB = f .|> f->f_to_z( f, fs ) |> hz |> to_dB

    return f, tfn_dB
end




function roots_of_factor( f )
    @assert( length(f) == 3 )
    a = f[3]
    b = f[2]
    c = f[1]

    # numerical recipes book method:

    # this could use a little work.
    # check that it works for real roots
    # and make it work for complex coefficients (where the roots where no longer be conjugates)

    x = sqrt( complex( b*b - 4 * a * c ) )
    q = -0.5 * ( ( b > 0 ) ? ( b + x ) : ( b - x ) )

    x1 = q / a
    x2 = c / q

    return x1, x2
end


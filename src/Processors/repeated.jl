
# Sometime you want top repeat a processor block multiple times
# eg in maing the recursive implementation of a 
# cascaded integrator comb (CIC) filter

# There are two ways to approach this:
#
# 1.  Add this as a lazy wrapper that incorpates the 
#     number of repetations and the processor object
#     In the time domain, this needs to be expanded 
#     with a state vector/tuple for each stage.
#     In the frequency domain (response.jl), this can 
#     be efficiently evaluated with a single response 
#     evaluation and an exponential operation.
#
# 2.  Eagerly expand the defintion with the existing 
#     Compose methods.  In the time domain this is similar 
#     to option 1, except that the compiler does more work 
#     for us.  In the frequency domain, the response 
#     must be calculated multiple times which is not as 
#     efficient as option 1.  Fast response calculation 
#     is not a problem - except perhaps in iterative 
#     filter design, but you would be unlikely to want 
#     to blindly repeat stages in this case.
#     This option should be really simple.
#
# So option 2 follows:

# use the exponential operator:

Base.:^( p::abstract_processor, n::Int ) = begin
        if     n  < 0
                error( "n: $(n) should be non-negative" )
        elseif n == 0
                return Processors.Identity()
        elseif n == 1
                return p
        else
                # recursion...
                # this will choose between Compose and Compose1
                return p |> p^(n-1)
        end
end



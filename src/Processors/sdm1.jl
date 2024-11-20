

# first order sigma delta modulator



struct SDM1 <: abstract_processor
	# include any parameters, but not state here:
        quantizer
        function SDM1()
                return new( x->( x>=0 ? 1 : -1 ) ) 
        end
end

# functions dependent on the type only
Base.IteratorEltype(::Type{Apply{I,SDM1}}) where {I} = Base.IteratorEltype(I)
Base.IteratorSize(  ::Type{Apply{I,SDM1}}) where {I} = Base.IteratorSize(I)

# functions dependent on the instance:
Base.eltype( a::Apply{I,SDM1}) where {I} = Int64 
Base.length( a::Apply{I,SDM1}) where {I} = Base.length(a.in)
Base.size(   a::Apply{I,SDM1}) where {I} = Base.size(  a.in)

# first call to iterate:
function Base.iterate(it::Apply{I,SDM1} ) where {I}
	# get the input:
	t = Base.iterate(it.in )
	t === nothing && return nothing
	x,input_state = t

	# initialize processor state:
	sdm_state = zero(x)

	# calculate next processor state and current output
        quantizer_in  = x - sdm_state
        quantizer_out = it.p.quantizer(quantizer_in)
	error = quantizer_out - quantizer_in
	yout = quantizer_out
        sdm_state = -error

	# return output and the combined state for next time
	return yout, (input_state,sdm_state)
end

# subsequent calls to iterate:
function Base.iterate(it::Apply{I,SDM1}, state ) where {I}
	# separate the combined state into 
	# the input iterator state and the processor state:
	input_state,sdm_state = state

	# get the input:
	t = Base.iterate(it.in, input_state )
	t === nothing && return nothing
	x,input_state = t

	# calculate next processor state and current output
        quantizer_in  = x + sdm_state
        quantizer_out = it.p.quantizer(quantizer_in)
	error = quantizer_out - quantizer_in
	yout = quantizer_out
        sdm_state = -error
        
	# return output and the combined state for next time
	return yout, (input_state,sdm_state)
end


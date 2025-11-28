
# made this mutable, for testing processorRef stuff:
mutable struct Integrator <: abstract_processor
	# include any parameters, but not state here:
	gain
end

# functions dependent on the type only
Base.IteratorEltype(::Type{Apply{I,Integrator}}) where {I} = Base.IteratorEltype(I)
Base.IteratorSize(  ::Type{Apply{I,Integrator}}) where {I} = Base.IteratorSize(I)

# eltype operates at the type level - returns iterator element type for the given iterator type
# this should really promote from input and type of gain
Base.eltype( ::Type{Apply{I,Integrator}}) where {I} = Base.eltype(I)

# functions dependent on the instance:


Base.length( a::Apply{I,Integrator}) where {I} = Base.length(a.in)
Base.size(   a::Apply{I,Integrator}) where {I} = Base.size(  a.in)

# first call to iterate:
function Base.iterate(it::Apply{I,Integrator} ) where {I}
	# get the input:
	t = Base.iterate(it.in )
	t === nothing && return nothing
	x,input_state = t

	# initialize processor state:
	integrator_state = zero(x)

	# calculate next processor state and current output
	integrator_state = x * it.p.gain + integrator_state
	yout = integrator_state

	# return output and the combined state for next time
	return yout, (input_state,integrator_state)
end

# subsequent calls to iterate:
function Base.iterate(it::Apply{I,Integrator}, state ) where {I}
	# separate the combined state into 
	# the input iterator state and the processor state:
	input_state,integrator_state = state

	# get the input:
	t = Base.iterate(it.in, input_state )
	t === nothing && return nothing
	x,input_state = t

	# calculate next processor state and current output
	integrator_state = x * it.p.gain + integrator_state
	yout = integrator_state

	# return output and the combined state for next time
	return yout, (input_state,integrator_state)
end




# Julia does not define an abstract type for iterable structures
# - so define one here:
# This will enable operators to be defined over sequences.
abstract type abstract_sequence  end


# Usually want to reference a specific sequence, defined by the type parameter {A}
# This will specialize generated code according to each specific A type:
# (This is similar to C++ templates)
struct Sequence{A} <: abstract_sequence
	a::A
end

# enable the Sequence type to behave as a Julia iterator by forwarding all the standard 
# iteration protocol functions to the implementation:
# Julia will optimize this out
Base.iterate( it::Sequence{A} ) where {A} = Base.iterate( it.a )
Base.iterate( it::Sequence{A}, state ) where {A} = Base.iterate( it.a, state )
Base.IteratorSize( ::Type{Sequence{A}} ) where {A} = Base.IteratorSize( A )
Base.IteratorEltype( ::Type{Sequence{A}} ) where {A} = Base.IteratorEltype( A )
Base.eltype( ::Type{Sequence{A}} ) where {A} = Base.eltype( A )
Base.length( it::Sequence{A} ) where {A} = Base.length( it.a )
Base.size( it::Sequence{A} ) where {A} = Base.size( it.a )

# can ask for the sample rate, but unless it is known, it will be returned as nothing, indicating unknown
sample_rate( it ) = nothing


# making sequences:

sequence( x ) = Sequence( x )         # wrap x with Sequence{}
sequence( x::abstract_sequence ) = x  # unless it is already an abstract_sequence
sequence( x::Number ) = Sequence( Base.Iterators.repeated(x) ) # scalars become infinite sequences
sequence( x::Tuple  ) = Sequence( Base.Iterators.repeated(x) ) # repeat tuples rather than iterating through the tuple values


# Arithmetic Binary Operations
# ----------------------------
#
# These will promote arguments - in particular constants will become infinite length sequences

# Op - is a function (not a symbol)
struct BinaryOp{Op,A,B} <: abstract_sequence
	a::A
	b::B
	function BinaryOp{Op}( a1::A1, b1::B1 ) where {Op,A1,B1}
		# promote the arguments to sequence - this is where constants become infinite length sequences
		a,b = sequence(a1), sequence(b1)
		new{Op,typeof(a),typeof(b)}(a,b)
	end


end

function Base.iterate( p::BinaryOp{Op,A,B}, states = (Base.iterate(p.a),Base.iterate(p.b)) ) where {Op,A,B }

	# at this point iterate has already been called for A and B

	a,b = states
	if a == nothing || b == nothing
		return nothing
	else
		# this is preparing for the next iteration:
		a1 = Base.iterate(p.a,a[2])
		b1 = Base.iterate(p.b,b[2])
		# perform the arithmetic operation using the first part of the iterate() tuple that was supplied as input to this function
		# and return the next iterate() tuples (or nothing)
		return Op( a[1] , b[1] ), (a1,b1)
	end
end

Base.IteratorSize( ::Type{ BinaryOp{Op,A,B} } ) where {Op,A,B} = combined_iteratorsize( Base.IteratorSize(A), Base.IteratorSize(B) )
Base.length( it::BinaryOp{Op,A,B} ) where {Op,A,B} = begin
	combined_iteratorlength( Base.IteratorSize(A), Base.IteratorSize(B), it.a, it.b )
end

# use the Julia promote_op mechanism to determine the result type of arithmetically combining eltype(A) and eltype(B):
Base.eltype( ::Type{ BinaryOp{Op,A,B} } ) where {Op,A,B} = begin
	Base.promote_op(Op,Base.eltype(A),Base.eltype(B))
end

# view of a matrix column (for example) gives a type that returns Base.HasShape{1} when Base.IteratorSize() called
# - make this behave the same as if HasLength() had been returned:
reduce_HasShape1_to_HasLength( a ) = a  # in general return argument unchanged
reduce_HasShape1_to_HasLength( ::Base.HasShape{1} ) = Base.HasLength() # convert HasShape{1} to HasLength

# Rules for the length of arithmetically combined sequences:
#
# is either length is unknown, then result is unknown:
combined_iteratorsize(::Base.SizeUnknown, _ ) = Base.SizeUnknown()
combined_iteratorsize( _, ::Base.SizeUnknown ) = Base.SizeUnknown()
combined_iteratorsize( ::Base.SizeUnknown, ::Base.SizeUnknown ) = Base.SizeUnknown()  # disambiguate
# if either length is infinite, then result is the other one:
combined_iteratorsize(::Base.IsInfinite, bs ) = reduce_HasShape1_to_HasLength(bs)
combined_iteratorsize( as, ::Base.IsInfinite ) = reduce_HasShape1_to_HasLength(as)
combined_iteratorsize( ::Base.IsInfinite, ::Base.IsInfinite ) = Base.IsInfinite() # disambiguate
## disambiguate when combining IsInfinite and SizeUnknown:
combined_iteratorsize(::Base.IsInfinite , ::Base.SizeUnknown) = Base.SizeUnknown()
combined_iteratorsize(::Base.SizeUnknown, ::Base.IsInfinite ) = Base.SizeUnknown()

# else both must be HasLength:
combined_iteratorsize( ::Base.HasLength, ::Base.HasLength ) = Base.HasLength()
combined_iteratorsize( ::Base.HasShape{1}, ::Base.HasLength ) = Base.HasLength()
combined_iteratorsize( ::Base.HasLength, ::Base.HasShape{1} ) = Base.HasLength()

combined_iteratorsize( ::Base.HasShape{1}, ::Base.HasShape{1} ) = Base.HasLength()

combined_iteratorlength(::Base.IsInfinite, bs, a, b  ) = Base.length(b)
combined_iteratorlength( as, ::Base.IsInfinite, a, b ) = Base.length(a)
combined_iteratorlength( ::Base.HasLength, ::Base.HasLength, a, b ) = begin
	la = Base.length(a)
	lb = Base.length(b)
	@assert la == lb "Length of sequences being combined must be equal, have $la and $lb"
	la
end
combined_iteratorlength( ::Base.HasShape{1}, ::Base.HasLength, a, b ) = combined_iteratorlength( Base.HasLength(), Base.HasLength(), a, b )
combined_iteratorlength( ::Base.HasLength, ::Base.HasShape{1}, a, b ) = combined_iteratorlength( Base.HasLength(), Base.HasLength(), a, b )
combined_iteratorlength( ::Base.HasShape{1}, ::Base.HasShape{1}, a, b ) = combined_iteratorlength( Base.HasLength(), Base.HasLength(), a, b )


for op = (:+,:-,:*,:/ )
	eval(quote
		# at least one of the two arguments needs to be a sequence:
		(Base.$op)(a                   ,b::abstract_sequence ) = BinaryOp{$op}( a, b )
		(Base.$op)(a::abstract_sequence,b                    ) = BinaryOp{$op}( a, b )
		(Base.$op)(a::abstract_sequence,b::abstract_sequence ) = BinaryOp{$op}( a, b )
	end)
end

function combined_sample_rate( s1, s2 )
        if s1 === nothing
                return s2
        elseif s2 === nothing
                return s1
        end
        @assert( s1 == s2, "Combining unequal sample rates $(s1) and $(s2)" )
        return s1
end

function sample_rate( p::BinaryOp{op,A,B} ) where {op,A,B}
        return combined_sample_rate( sample_rate(p.a), sample_rate(p.b) )
end




# some helper definitions to make defining sequences with fixed eltype easier:
abstract type       infinite_sequence{Eltype} <: abstract_sequence where { Eltype } end
abstract type   known_length_sequence{Eltype} <: abstract_sequence where { Eltype } end
abstract type unknown_length_sequence{Eltype} <: abstract_sequence where { Eltype } end

Base.IteratorSize( ::Type{T} ) where { T <: infinite_sequence       } = Base.IsInfinite()
Base.IteratorSize( ::Type{T} ) where { T <: known_length_sequence   } = Base.HasLength()
Base.IteratorSize( ::Type{T} ) where { T <: unknown_length_sequence } = Base.SizeUnknown()

Base.IteratorEltype( ::Type{ T } ) where { T <:       infinite_sequence{Eltype} } where {Eltype} = Base.HasEltype()
Base.IteratorEltype( ::Type{ T } ) where { T <:   known_length_sequence{Eltype} } where {Eltype} = Base.HasEltype()
Base.IteratorEltype( ::Type{ T } ) where { T <: unknown_length_sequence{Eltype} } where {Eltype} = Base.HasEltype()

Base.eltype( ::Type{ T } ) where { T <:       infinite_sequence{Eltype} } where {Eltype} = Eltype
Base.eltype( ::Type{ T } ) where { T <:   known_length_sequence{Eltype} } where {Eltype} = Eltype
Base.eltype( ::Type{ T } ) where { T <: unknown_length_sequence{Eltype} } where {Eltype} = Eltype



# some simple Test sequences:
# count from 0 to n-1
# Julia iterators need to respect the length - so no need to check and return nothing at the end of the sequence
struct Test_Range <: known_length_sequence{Int}
	n
end
Base.iterate( r::Test_Range, state = 0 ) = state < r.n ? (state, state+1) : nothing
Base.length( r::Test_Range ) = r.n

# This iterator should run forever:
struct Test_Range_Inf <: infinite_sequence{Int}
end
Base.iterate( ::Test_Range_Inf, state = 0 ) = (state, state+1)

# This iterator selects a random length between 10 and 15 and counts down to one
# length is not defined and should not be called
struct Test_Range_Unknown <: unknown_length_sequence{Int}
end
Base.iterate( ::Test_Range_Unknown, state = rand(10:15) ) = state > 0 ? (state, state-1) : nothing




# print debug info for initial testing of new sequences:
function info( s, n = 20 ; print_state = false )
	print( "IteratorSize:     ", Base.IteratorSize( typeof(s) ), "\n" )
	print( "IteratorEltype:   ", Base.IteratorEltype( typeof(s) ), "\n")
	if Base.IteratorEltype( typeof(s) ) == Base.HasEltype()
		print( "HasEltype() :")
		print( "\teltype:           ", Base.eltype(s), "\n" )
	end
	if Base.IteratorSize( typeof(s) ) == Base.HasLength()
		# HasLength implies that length() is defined:
		print( "HasLength() :")
		print( "length:           ", Base.length(s), "\n" )
	end
	if isa( Base.IteratorSize( typeof(s) ) , Base.HasShape )
		# HasShape implies that size() is defined:
		# This is used by Julia for multidimensional arrays - and is not really used much here
		print( "HasShape() : ", Base.IteratorSize( typeof(s) ) )
		print( "size:             ", Base.size(s) , "\n" )
	end

	y = iterate(s)

	# i is counting the number of times that iterate() has been called (including the first call without existing state)
	# i is counting the number of values that have been returned
	i = 1
	while y !== nothing && i <= n
		val, state = y

		# annotate with an asterisk if the returned type is not what was expected
		print( lpad(i,3) )
		if Base.IteratorEltype( typeof(s) ) == Base.HasEltype()
			print( Base.eltype(s) == typeof(val) ? " " : "*" )
		else
			# print actual type if eltype is not known:
			print( lpad(i,3), lpad( typeof(val), 20 ) )
		end
		print( " ", rpad( val, 20 ) )
		if print_state
			print( "    ", state )
		end
		print( "\n" )



		if y === nothing
			println( "Sequence ended with iterate() returning nothing")
			if Base.IteratorSize( typeof(s) ) == Base.IsInfinite()
				print( "**** Sequence was declared to be infinite length, but ended...." )
			elseif Base.IteratorSize( typeof(s) ) != Base.SizeUnknown()
				if i != Base.length(s) - 1
					@show i Base.length(s)
					print( "**** Sequence ended at wrong time" )
				end
			end
			break  # sequence ended with nothing
		end

		if reduce_HasShape1_to_HasLength(Base.IteratorSize( typeof(s) )) == Base.HasLength() && i >= Base.length(s)
			# respect the declared finite length:
			break
		end

		y = iterate(s, state)
		i = i+1
	end
end


# TODO: move these to a separate file
#=
# some simple bring-up "tests"
info( Test_Range(5) )
info( Test_Range_Inf() )
info( Test_Range_Unknown() )
info( 100 + Test_Range(5) )
info( 100 + Test_Range_Inf() )
info( 100 + Test_Range_Unknown() )
=#


abstract type abstract_processor end

# this defines the iterator formed by applying "in" to the the processor "p":
struct Apply{T_iter,T_proc}
        in::T_iter
        p::T_proc
end

# this defines a composition of two processors:
struct Compose{P1,P2} <: abstract_processor
        p1::P1
        p2::P2
end

# the normal way to construct Apply{} and Compose{} is through pipe "|>" notation
# which is converted to the parenthesis call operator in Julia
# (Never define a "|>" implementation - that is unnecessary and breaks expectations)  

# all processors should be defined deriving from abstract_processor, so
# if the argument is not an abstract_processor, it is assumed to be the source iterator
(p2::abstract_processor)( p1::abstract_processor ) = Compose( p1, p2 )
(p2::abstract_processor)( it                     ) = Apply(   it, p2 )

# a composed structure will be used, by applying an input iterator,
# or composing with another processor:
(c::Compose)( in                     ) = c.p2( c.p1( in ) )
(c::Compose)( p1::abstract_processor ) = Compose( p1, c )



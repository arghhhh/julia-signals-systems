


# it'd be nice if this also worked for regular processors (interpolators and decimators)
# - but this will get complicated with things like length (would be a function of state)


mutable struct Stateful{P} <: SampleProcessor  where {P<:SampleProcessor}
        p::P
        started::Bool
        state

        Stateful(p::P) where {P} = begin
                r = new{P}()
                r.started = false
                r.p = p

                return r
        end
end

function process( p::Stateful{P}, x ) where {P}

        # this check is only performed once for each input sequence:
        if p.started
                (y, p.state) = process( p.p, x, p.state )
                return y, nothing
        else
                (y, p.state) = process( p.p, x )
                p.started = true
                return y, nothing
        end
end

function process( p::Stateful{P}, x, state ) where {P}
        (y, p.state) = process( p.p, x, p.state )
        return y, nothing
end




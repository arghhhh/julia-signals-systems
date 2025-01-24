

Sequences.sample_rate( a::Processors.Apply{It,P} ) where { It,P } = begin
        @error "Sequences.sample_rate needs to be specialized for $P in \"sample_rate.jl\""
end

Sequences.sample_rate( a::Processors.Apply{It,P} ) where { It,P<:Processors.SampleProcessor } = begin
        Sequences.sample_rate( a.in )
end

Sequences.sample_rate( a::Processors.Apply{It,Processors.Downsample} ) where { It } = begin
        Sequences.sample_rate( a.in ) / a.p.n
end

Sequences.sample_rate( a::Processors.Apply{It,Processors.Upsample  } ) where { It } = begin
        Sequences.sample_rate( a.in ) * a.p.n
end

Sequences.sample_rate( a::Processors.Apply{It,Processors.Upsamplehold} ) where { It } = begin
        Sequences.sample_rate( a.in ) * a.p.n
end




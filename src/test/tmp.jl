

# this is an example of what should be possible
# with a little effort..

# Vectorize is quite efficient at consuming input and generating views
# into the storage array built from the previous input values with the new value appended

# Combine with Downsample to do things like partition the input stream

partition( n ) = (
	   Vectorize( n ) 
	|> Downsample(n,n-1) 
)

partition_with_overlap(n) = (
           Vectorize( n ) 
        |> Downsample(div(n,2),n-1 ) 
)       

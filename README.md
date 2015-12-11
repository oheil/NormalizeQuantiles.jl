# NormalizeQuantiles

[![Build Status](https://travis-ci.org/oheil/NormalizeQuantiles.jl.svg?branch=master)](https://travis-ci.org/oheil/NormalizeQuantiles.jl)


Package NormalizeQuantiles implements Quantile normalization

# Usage example

	Pkg.add("NormalizeQuantiles")
	using NormalizeQuantiles
	
	array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
	qn = normalizeQuantiles(array)
	
'array' is interpreted as a matrix with 4 columns and 3 rows.
After quantile normalization the sets of values of each column have the same statistical properties.
This is quantile normalization without a reference column.
	
# Data prerequisites

To use quantile normalization your data 






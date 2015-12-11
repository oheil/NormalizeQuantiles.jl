# NormalizeQuantiles

[![Build Status](https://travis-ci.org/oheil/NormalizeQuantiles.jl.svg?branch=master)](https://travis-ci.org/oheil/NormalizeQuantiles.jl)


Package NormalizeQuantiles implements Quantile normalization.

# Usage example

	julia> Pkg.add("NormalizeQuantiles")
	julia> using NormalizeQuantiles
	
	julia> array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
	julia> qn = normalizeQuantiles(array)
	4x3 DataArrays.DataArray{Float64,2}:
	 6.5  5.0  3.5
	 3.5  5.0  6.5
	 6.5  3.5  5.0
	 5.0  3.5  6.5

`array` is interpreted as a matrix with 4 columns and 3 rows.
	 
# Behaviour of function 'normalizeQuantiles'

After quantile normalization the sets of values of each column have the same statistical properties.
This is quantile normalization without a reference column.

The function 'normalizeQuantiles' always returns a DataArray of equal dimension as the input matrix.

`NA` values are treated as random missing values and the result value will be NA again. Because of this expected randomness the function returns varying results on successive calls with the same array containing 'NA' values.
	
# Data prerequisites

To use quantile normalization your data should have the following properties:

* the distribution of values in each column should be similar
* number of values for each column should be large
* number of 'NA' in the data should be small and of random nature







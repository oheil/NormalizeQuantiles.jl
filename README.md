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

`NA` values are treated as random missing values and the result value will be NA again. Because of this expected randomness the function returns varying results on successive calls with the same array containing `NA` values. 
	
# Data prerequisites

To use quantile normalization your data should have the following properties:

* the distribution of values in each column should be similar
* number of values for each column should be large
* number of `NA` in the data should be small and of random nature

# Remarks on data with `NA`

Currently there seems to be no general agreement on how to deal with `NA` during quantile normalization. Here we distribute the given number of `NA` randomly back into the sorted list of values for each column before calculating
the mean of the rows. Therefore successive calls of normalizeQuantiles will give different results. On large datasets with small number of `NA` these difference should be marginal.

You can avoid varying results by seeding the random generator using `srand(...)`:

	julia> using NormalizeQuantiles
	julia> using DataArrays
	
	julia> array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
	julia> dataarray = DataArray(array)
	julia> column = 3
	julia> row = 2
	julia> dataarray = DataArray(array)
	julia> dataarray[column,row]=NA

Varying results:

	julia> qn = normalizeQuantiles(dataarray)
	4x3 DataArrays.DataArray{Float64,2}:
	 5.66667  5.25  3.75
	 3.75     5.25  5.66667
	 5.25      NA   3.75
	 5.25     3.75  5.66667

	julia> qn = normalizeQuantiles(dataarray)
	4x3 DataArrays.DataArray{Float64,2}:
	 6.5      5.0      2.33333
	 2.33333  5.0      6.5
	 6.5       NA      5.0
	 5.0      2.33333  6.5

Stable results:
	 
	julia> srand(0);qn = normalizeQuantiles(dataarray)
	4x3 DataArrays.DataArray{Float64,2}:
	 6.5      5.0      2.33333
	 2.33333  5.0      6.5
	 6.5       NA      5.0
	 5.0      2.33333  6.5

	julia> srand(0);qn = normalizeQuantiles(dataarray)
	4x3 DataArrays.DataArray{Float64,2}:
	 6.5      5.0      2.33333
	 2.33333  5.0      6.5
	 6.5       NA      5.0
	 5.0      2.33333  6.5





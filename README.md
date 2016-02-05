# Important:

Current versions are Alpha-Releases!

Expect heavy changes in future releases!

# NormalizeQuantiles

[![Build Status](https://travis-ci.org/oheil/NormalizeQuantiles.jl.svg?branch=master)](https://travis-ci.org/oheil/NormalizeQuantiles.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/24mlc8g1x65a57h7?svg=true)](https://ci.appveyor.com/project/oheil/normalizequantiles-jl)

Package NormalizeQuantiles implements Quantile normalization.

# Usage example
	
`array` is interpreted as a matrix with 4 rows and 3 columns.
	 
	# example for julia version >= 0.4
	julia> Pkg.add("NormalizeQuantiles")
	julia> using NormalizeQuantiles

	julia> array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
	julia> qn = normalizeQuantiles(array)
	4x3 Array{Float64,2}:
	 2.0  3.0  2.0
	 4.0  6.0  4.0
	 8.0  8.0  7.0
	 6.0  3.0  7.0

	julia> arrayWithNA = Array{Nullable{Float64}}(array)
	julia> arrayWithNA[2,2] = Nullable{Float64}()
	julia> arrayWithNA
	4x3 Array{Nullable{Float64},2}:
	 Nullable(3.0)  Nullable(2.0)        Nullable(1.0)
	 Nullable(4.0)  Nullable{Float64}()  Nullable(6.0)
	 Nullable(9.0)  Nullable(7.0)        Nullable(8.0)
	 Nullable(5.0)  Nullable(2.0)        Nullable(8.0)
	
	julia> srand(0);qn = normalizeQuantiles(arrayWithNA)
	4x3 Array{Nullable{Float64},2}:
	 Nullable(2.0)  Nullable(4.5)        Nullable(2.0)
	 Nullable(4.0)  Nullable{Float64}()  Nullable(4.0)
	 Nullable(8.0)  Nullable(8.0)        Nullable(6.5)
	 Nullable(5.0)  Nullable(4.5)        Nullable(6.5)

	julia> isnull(qn[2,2])
	true
	
	julia> qn[2,2]=0.0
	julia> isnull(qn[2,2])
	false
	
	julia> qn_array = convert(Array{Float64},reshape([get(qn[i]) for i=1:length(qn)],size(qn)))
	4x3 Array{Float64,2}:
	 2.0  4.5  2.0
	 4.0  0.0  4.0
	 8.0  8.0  6.5
	 5.0  4.5  6.5


	 
	# example for julia version 0.3
	julia> Pkg.add("NormalizeQuantiles")
	julia> using NormalizeQuantiles
	julia> using DataArrays
	
	julia> array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
	julia> qn = normalizeQuantiles(array)
	4x3 DataArrays.DataArray{Float64,2}:
     2.0  3.0  2.0
     4.0  6.0  4.0
     8.0  8.0  7.0
     6.0  3.0  7.0

# Behaviour of function 'normalizeQuantiles'

After quantile normalization the sets of values of each column have the same statistical properties.
This is quantile normalization without a reference column.

For julia version >= 0.4:

The function 'normalizeQuantiles' always returns an array of equal dimension as the input matrix and of type Array{Float} or Array{Nullable{Float}}.

`NA` values are of type Nullable{Float} and are treated as random missing values and the result value will be Nullable{Float} again. Because of this expected randomness the function returns varying results on successive calls with the same array containing `NA` values. See "Remarks on data with `NA`" below.

Float can be Float64 or Float32 depending on your environment



For julia version 0.3:

The function 'normalizeQuantiles' always returns a DataArray of equal dimension as the input matrix.

`NA` values are treated as random missing values and the result value will be NA again. Because of this expected randomness the function returns varying results on successive calls with the same array containing `NA` values. 
	
# Data prerequisites

To use quantile normalization your data should have the following properties:

* the distribution of values in each column should be similar
* number of values for each column should be large
* number of `NA` in the data should be small and of random nature

# Remarks on data with `NA`

In julia version 0.3 `NA` values have been implemented using the Package DataArray. With julia 0.4 the concept of Nullables has been introduced. Tests using DataArrays and Arrays of Nullables have shown, that performance of Arrays of Nullables is vastly superior to DataArrays. Therefore with julia version 0.4 the dependency on DataArrays is droped in favor of Arrays of Nullables.

Currently there seems to be no general agreement on how to deal with `NA` during quantile normalization. Here we distribute the given number of `NA` randomly back into the sorted list of values for each column before calculating
the mean of the rows. Therefore successive calls of normalizeQuantiles will give different results. On large datasets with small number of `NA` these difference should be marginal.

You can avoid varying results by seeding the random generator using `srand(...)`. See following example for julia 0.3:

	julia> using NormalizeQuantiles
	julia> using DataArrays
	
	julia> array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
	julia> dataarray = DataArray(array)
	julia> column = 2
	julia> row = 3
	julia> dataarray = DataArray(array)
	julia> dataarray[row,column]=NA

Varying results:

	julia> qn = normalizeQuantiles(dataarray)
	4x3 DataArrays.DataArray{Float64,2}:
     2.0      3.5      2.0
     5.0      7.33333  5.0
     7.33333   NA      6.16667
     5.0      3.5      6.16667

	julia> qn = normalizeQuantiles(dataarray)
	4x3 DataArrays.DataArray{Float64,2}:
     2.0  3.0  2.0
     4.0  6.0  4.0
     8.5   NA  7.25
     6.0  3.0  7.25

Stable results:
	 
	julia> srand(0);qn = normalizeQuantiles(dataarray)
	4x3 DataArrays.DataArray{Float64,2}:
     2.0      4.5      2.0
     4.0      7.33333  4.0
     7.33333   NA      6.16667
     5.0      4.5      6.16667

	julia> srand(0);qn = normalizeQuantiles(dataarray)
	4x3 DataArrays.DataArray{Float64,2}:
     2.0      4.5      2.0
     4.0      7.33333  4.0
     7.33333   NA      6.16667
     5.0      4.5      6.16667




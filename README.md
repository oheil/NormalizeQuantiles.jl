# NormalizeQuantiles

[![Build Status](https://travis-ci.org/oheil/NormalizeQuantiles.jl.svg?branch=master)](https://travis-ci.org/oheil/NormalizeQuantiles.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/24mlc8g1x65a57h7?svg=true)](https://ci.appveyor.com/project/oheil/normalizequantiles-jl)

Package NormalizeQuantiles implements Quantile normalization.

## Dependencies

#### julia version >= 0.4

No dependencies

####  julia version 0.3

[DataArrays](https://github.com/JuliaStats/DataArrays.jl) ([StatsBase](https://github.com/JuliaStats/StatsBase.jl),[Compat](https://github.com/JuliaLang/Compat.jl),[Reexport](https://github.com/simonster/Reexport.jl))

## Usage examples
	
`array` is interpreted as a matrix with 4 rows and 3 columns.
	 
#### Example for julia version >= 0.4

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
	
	julia> qn[2,2] = 0.0
	julia> isnull(qn[2,2])
	false
	
	julia> qn_array = convert(Array{Float64},reshape([get(qn[i]) for i=1:length(qn)],size(qn)))
	4x3 Array{Float64,2}:
	 2.0  4.5  2.0
	 4.0  0.0  4.0
	 8.0  8.0  6.5
	 5.0  4.5  6.5
	 
	julia> using NullableArrays
	
	julia> na = NullableArray(array)
	julia> na[2,2] = Nullable()
	julia> na
	4x3 NullableArrays.NullableArray{Float64,2}:
	 3.0      2.0  1.0
	 4.0  #NULL    6.0
	 9.0      7.0  8.0
	 5.0      2.0  8.0	

	julia> arrayOfNullables = convert(Array{Nullable{Float64}},reshape([na[i] for i=1:length(na)],size(na)))
	julia> srand(0);qn = normalizeQuantiles(arrayOfNullables)
	4x3 Array{Nullable{Float64},2}:
	 Nullable(2.0)  Nullable(4.5)        Nullable(2.0)
	 Nullable(4.0)  Nullable{Float64}()  Nullable(4.0)
	 Nullable(8.0)  Nullable(8.0)        Nullable(6.5)
	 Nullable(5.0)  Nullable(4.5)        Nullable(6.5)	

	julia> isn = convert(Array{Bool},reshape([isnull(qn[i]) for i=1:length(qn)],size(qn)))
	julia> qn[isn] = 0.0
	julia> qna = NullableArray(convert(Array{Float64},reshape([get(qn[i]) for i=1:length(qn)],size(qn))),isn)
	4x3 NullableArrays.NullableArray{Float64,2}:
	 2.0      4.5  2.0
	 4.0  #NULL    4.0
	 8.0      8.0  6.5
	 5.0      4.5  6.5

	julia> using DataArrays
	
	julia> da = DataArray(array)
	4x3 DataArrays.DataArray{Float64,2}:
	 3.0  2.0  1.0
	 4.0  5.0  6.0
	 9.0  7.0  8.0
	 5.0  2.0  8.0
	
	julia> da[2,2] = NA
	julia> arrayWithNA = convert(Array{Nullable{Float64}},reshape([isna(da[i])?Nullable{Float64}():Nullable{Float64}(da[i]) for i=1:length(da)],size(da)))
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
	
	julia> daqn = DataArray(Float64,size(qn))
	julia> daqn[1:length(qn)] = DataArray(reshape([isnull(qn[i])?NA:get(qn[i]) for i=1:length(qn)],size(qn)))[1:length(qn)]
	julia> daqn
	4x3 DataArrays.DataArray{Float64,2}:
	 2.0  4.5  2.0
	 4.0   NA  4.0
	 8.0  8.0  6.5
	 5.0  4.5  6.5
	
#### Example for julia version 0.3

	julia> Pkg.add("NormalizeQuantiles")
	julia> using NormalizeQuantiles
	julia> using DataArrays
	
	julia> array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
	julia> srand(0);qn = normalizeQuantiles(array)
	4x3 DataArrays.DataArray{Float64,2}:
     2.0  3.0  2.0
     4.0  6.0  4.0
     8.0  8.0  7.0
     6.0  3.0  7.0
	
	julia> da = DataArray(array)
	julia> da[2,2] = NA
	julia> srand(0);daqn = normalizeQuantiles(da)
	4x3 DataArray{Float64,2}:
	 2.0  4.5  2.0
	 4.0   NA  4.0
	 8.0  8.0  6.5
	 5.0  4.5  6.5
 
## Behaviour of function 'normalizeQuantiles'

After quantile normalization the sets of values of each column have the same statistical properties.
This is quantile normalization without a reference column.

#### For julia version >= 0.4:

The function 'normalizeQuantiles' always returns an array of equal dimension as the input matrix and of type Array{Float} or Array{Nullable{Float}}.

`NA` values are of type Nullable{Float} and are treated as random missing values and the result value will be Nullable{Float} again. Because of this expected randomness the function returns varying results on successive calls with the same array containing `NA` values. See "Remarks on data with `NA`" below.

Float can be Float64 or Float32 depending on your environment

#### For julia version 0.3:

The function 'normalizeQuantiles' always returns a DataArray of equal dimension as the input matrix.

`NA` values are treated as random missing values and the result value will be NA again. Because of this expected randomness the function returns varying results on successive calls with the same array containing `NA` values. 
	
## Data prerequisites

To use quantile normalization your data should have the following properties:

* the distribution of values in each column should be similar
* number of values for each column should be large
* number of `NA` in the data should be small and of random nature

## Remarks on data with `NA`

In julia version 0.3 `NA` values have been implemented using the Package DataArray. With julia 0.4 the concept of Nullables has been introduced. Tests using DataArrays and Arrays of Nullables have shown, that performance of Arrays of Nullables is vastly superior to DataArrays. Therefore with julia version 0.4 the dependency on DataArrays is dropped in favor of Arrays of Nullables:

#### julia version 0.3:

	julia> using NormalizeQuantiles
	
	julia> r=randn((1000,10));
	
	julia> qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);
	elapsed time: 14.095581822 seconds (333478396 bytes allocated, 74.58% gc time)
	
	julia> r=randn((10000,10));
	
	julia> qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);	
	elapsed time: 1022.546972627 seconds (27043119092 bytes allocated, 77.33% gc time)
	
	julia> r=randn((1000,100));
	
	julia> qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);
	elapsed time: 117.107284172 seconds (3325883092 bytes allocated, 78.65% gc time)

#### julia version 0.4:

	julia> using NormalizeQuantiles
	
	julia> r=randn((1000,10));
	
	julia> qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);
	0.860034 seconds (183.47 k allocations: 49.989 MB, 4.92% gc time)
	
	julia> r=randn((10000,10));
	
	julia> qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);	
	66.305552 seconds (2.25 M allocations: 623.611 MB, 1.03% gc time)
	
	julia> r=randn((1000,100));
	
	julia> qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);
	9.421312 seconds (1.72 M allocations: 496.723 MB, 4.37% gc time)

(performed on a low performance netbook)

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




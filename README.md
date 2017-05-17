# NormalizeQuantiles

[![Build Status](https://travis-ci.org/oheil/NormalizeQuantiles.jl.svg?branch=master)](https://travis-ci.org/oheil/NormalizeQuantiles.jl/builds/)
[![Build status](https://ci.appveyor.com/api/projects/status/24mlc8g1x65a57h7?svg=true)](https://ci.appveyor.com/project/oheil/normalizequantiles-jl)

Package NormalizeQuantiles implements quantile normalization

```julia
qn = normalizeQuantiles(array);
```

and provides a function to calculate sample ranks

```julia
(r,m) = sampleRanks(array);
```

of a given vector or matrix.

**Table of Contents**

- [Dependencies](#dependencies)
- [Remarks](#remarks)
- [Usage examples `normalizeQuantiles`](#usage-examples-normalizequantiles)
  - [General usage](#general-usage)
  - [Missing values](#missing-values)
  - [NullableArrays](#nullablearrays)
  - [DataArrays](#dataarrays)
  - [SharedArray and multicore usage examples](#sharedarray-and-multicore-usage-examples)
- [Behaviour of function `normalizeQuantiles`](#behaviour-of-function-normalizequantiles)
- [Data prerequisites](#data-prerequisites)
- [Remarks on data with `NA`](#remarks-on-data-with-na)
- [List of all exported definitions for `normalizeQuantiles`](#list-of-all-exported-definitions-for-normalizequantiles)
- [Usage examples `sampleRanks`](#usage-examples-sampleranks)
- [List of all exported definitions for `sampleRanks`](#list-of-all-exported-definitions-for-sampleranks)

## Dependencies

Julia 0.4 or higher

No other dependencies

## Remarks

- Code examples and output on this page have been used on and copied from the julia 0.5 [REPL](https://docs.julialang.org/en/stable/manual/interacting-with-julia/)
- Last commit with julia v3.0 support: [Jan 20, 2017, eb97d24ff77d470d0d121fabf83d59979ad0db36](https://github.com/oheil/NormalizeQuantiles.jl/tree/eb97d24ff77d470d0d121fabf83d59979ad0db36)

## Usage examples `normalizeQuantiles`

#### General usage
 
```julia
Pkg.add("NormalizeQuantiles");
using NormalizeQuantiles;
```

The following `array` is interpreted as a matrix with 4 rows and 3 columns:

```julia
array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ];
qn = normalizeQuantiles(array)
```
```
	julia> qn
	4×3 Array{Float64,2}:
	 2.0  3.0  2.0
	 4.0  6.0  4.0
	 8.0  8.0  7.0
	 6.0  3.0  7.0
```

The columns in `qn` are now quantile normalized to each other.

#### Missing values

Missing values `NA` are handled using [Nullables](http://docs.julialang.org/en/stable/manual/types/#nullable-types-representing-missing-values):

```julia
arrayWithNA = Array{Nullable{Float64}}(array);
arrayWithNA[2,2] = Nullable{Float64}();
arrayWithNA
```
```
	julia> arrayWithNA
	4×3 Array{Nullable{Float64},2}:
	 3.0  2.0    1.0
	 4.0  #NULL  6.0
	 9.0  7.0    8.0
	 5.0  2.0    8.0
```
```julia
qn = normalizeQuantiles(arrayWithNA)
```
```
	julia> qn
	4×3 Array{Nullable{Float64},2}:
	 2.0  3.5    2.0
	 5.0  #NULL  5.0
	 8.0  8.0    6.5
	 5.0  3.5    6.5
```
```julia
isnull(qn[2,2])
```
```
	julia> isnull(qn[2,2])
	true
```

The result must be of type `Array{Nullable{Float64}}`, because `NAs` stay `NAs` after quantile normalization. Setting the `NA` to `0.0` we can convert the result back to `Array{Float64}`:

```julia
qn[2,2] = 0.0;
isnull(qn[2,2])
```
```
	julia> isnull(qn[2,2])
	false
```
```julia
tmp_qn = qn;
qn_array = convert(Array{Float64},reshape([get(tmp_qn[i]) for i=1:length(tmp_qn)],size(tmp_qn)));
qn_array
```
```
	julia> qn_array
	4×3 Array{Float64,2}:
	 2.0  3.5  2.0
	 5.0  0.0  5.0
	 8.0  8.0  6.5
	 5.0  3.5  6.5
```

#### NullableArrays

How to deal with [NullableArrays](https://github.com/JuliaStats/NullableArrays.jl):

```julia
Pkg.add("NullableArrays")
using NullableArrays;
na = NullableArray(array);
na[2,2] = Nullable();
na
```
```
	julia> na
	4×3 NullableArrays.NullableArray{Float64,2}:
	 3.0  2.0    1.0
	 4.0  #NULL  6.0
	 9.0  7.0    8.0
	 5.0  2.0    8.0
```

Convert the `NullableArray` `na` to `Array{Nullable{Float64}}`:

```julia
tmp_na = na;
arrayOfNullables = convert(Array{Nullable{Float64}},reshape([tmp_na[i] for i=1:length(tmp_na)],size(tmp_na)));
qn = normalizeQuantiles(arrayOfNullables)
```
```
	julia> qn
	4×3 Array{Nullable{Float64},2}:
	 2.0  3.5    2.0
	 5.0  #NULL  5.0
	 8.0  8.0    6.5
	 5.0  3.5    6.5
```

Convert the result `Array{Nullable{Float64}}` back to `NullableArray`:

```julia
tmp_qn = qn;
isn = convert(Array{Bool},reshape([isnull(tmp_qn[i]) for i=1:length(tmp_qn)],size(tmp_qn)));
tmp_qn[isn] = 0.0;
qna = NullableArray(convert(Array{Float64},reshape([get(tmp_qn[i]) for i=1:length(tmp_qn)],size(tmp_qn))),isn)
```
```
	julia> qna
	4×3 NullableArrays.NullableArray{Float64,2}:
	 2.0  3.5    2.0
	 5.0  #NULL  5.0
	 8.0  8.0    6.5
	 5.0  3.5    6.5
```

#### DataArrays

Dealing with `DataArrays`:

```julia
Pkg.add("DataArrays")
using DataArrays;
da = DataArray(array)
```
```
	julia> da
	4×3 DataArrays.DataArray{Float64,2}:
	 3.0  2.0  1.0
	 4.0  5.0  6.0
	 9.0  7.0  8.0
	 5.0  2.0  8.0
```
```julia
da[2,2] = NA
```

Converting the DataArray `da` containing `NAs` to an `Array{Nullable{Float64}}`:

```julia
tmp_da = da;
arrayWithNA = convert(Array{Nullable{Float64}},reshape([isna(tmp_da[i])?Nullable{Float64}():Nullable{Float64}(tmp_da[i]) for i=1:length(tmp_da)],size(tmp_da)))
```
```
	julia> arrayWithNA
	4×3 Array{Nullable{Float64},2}:
	 3.0  2.0    1.0
	 4.0  #NULL  6.0
	 9.0  7.0    8.0
	 5.0  2.0    8.0
```
```julia
qn = normalizeQuantiles(arrayWithNA)
```
```
	julia> qn
	4×3 Array{Nullable{Float64},2}:
	 2.0  3.5    2.0
	 5.0  #NULL  5.0
	 8.0  8.0    6.5
	 5.0  3.5    6.5
```

Converting the result `Array{Nullable{Float64}}` back to `DataArray` containg `NAs`:

```julia
tmp_qn = qn;
daqn = DataArray(Float64,size(tmp_qn));
for index in eachindex(daqn) daqn[index]=isnull(tmp_qn[index])?NA:get(tmp_qn[index]) end
daqn
```
```
	julia> daqn
	4×3 DataArrays.DataArray{Float64,2}:
	 2.0  3.5  2.0
	 5.0   NA  5.0
	 8.0  8.0  6.5
	 5.0  3.5  6.5
```

#### SharedArray and multicore usage examples

> Remark: restart julia now. `addprocs()` must be called before `using NormalizeQuantiles;`. Doing it the other way round will result in an error as observed with julia 0.4.

To use multiple cores on a single machine you can use `SharedArray{Nullable{Float64}}`:

```julia
addprocs();
using NormalizeQuantiles;
array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ];
# sa = SharedArray(Nullable{Float64},(size(array,1),size(array,2)));  # julia 0.4
sa = SharedArray{Nullable{Float64}}((size(array,1),size(array,2)));
sa[:] = array[:];
sa
```
```
	julia> sa
	4×3 SharedArray{Nullable{Float64},2}:
	 3.0  2.0  1.0
	 4.0  5.0  6.0
	 9.0  7.0  8.0
	 5.0  2.0  8.0
```
```julia
qn = normalizeQuantiles(sa)
```
```
	julia> qn
	4×3 SharedArray{Nullable{Float64},2}:
	 2.0  3.0  2.0
	 4.0  6.0  4.0
	 8.0  8.0  7.0
	 6.0  3.0  7.0
```

For small data sets performance using `SharedArrays` decreases:

```julia
la = randn((100,100));
tf = Array{Nullable{Float64}}(la);
sa = SharedArray{Nullable{Float64}}((size(tf,1),size(tf,2)));
sa[:] = tf[:];
normalizeQuantiles(tf); @time normalizeQuantiles(tf);
```
```
	julia> @time normalizeQuantiles(tf);
	  0.003926 seconds (6.71 k allocations: 4.466 MB)
```
```julia
normalizeQuantiles(sa); @time normalizeQuantiles(sa);
```
```
	julia> @time normalizeQuantiles(sa);
	  0.012880 seconds (11.14 k allocations: 354.813 KB)
```

For larger data sets performance increases with multicore processors:

```julia
la = randn((10000,10000));
tf = Array{Nullable{Float64}}(la);
sa = SharedArray{Nullable{Float64}}((size(tf,1),size(tf,2)));
sa[:] = tf[:];
normalizeQuantiles(tf); @time normalizeQuantiles(tf);
```
```
	julia> @time normalizeQuantiles(tf);
	  33.469397 seconds (1.06 M allocations: 38.215 GB, 12.81% gc time)
```
```julia
normalizeQuantiles(sa); @time normalizeQuantiles(sa);
```
```
	julia> @time normalizeQuantiles(sa);
	  11.311243 seconds (11.22 k allocations: 355.859 KB)
```

## Behaviour of function `normalizeQuantiles`

After quantile normalization the sets of values of each column have the same statistical properties.
This is quantile normalization without a reference column.

The function 'normalizeQuantiles' always returns a matrix of equal dimension as the input matrix and of type `Array{Float64}` or `Array{Nullable{Float64}}`. In case of Float64-type input matrices `normalizeQuantiles` returns the same type, in case of Int-type input matrices the result matrix will be the same but with base type Float64, e.g. a `Array{Nullable{Int}}` will result in `Array{Nullable{Float64}}`.

`NA` values are of type `Nullable{Float64}` and are treated as random missing values and the result value will be `Nullable{Float64}` again. See "Remarks on data with `NA`" below.

## Data prerequisites

To use quantile normalization your data should have the following properties:

* the distribution of values in each column should be similar
* number of values for each column should be large
* number of `NA` in the data should be small and of random nature

## Remarks on data with `NA`

Currently there seems to be no general agreement on how to deal with `NA` during quantile normalization. Here we put any given `NA` back into the sorted column at the original position before calculating the mean of the rows.

## List of all exported definitions for `normalizeQuantiles`

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Float64} function normalizeQuantiles(matrix::Array{Float64})` |
| Input type: | `Array{Float64}` |
| Return type: | `Array{Float64}` |

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Float64} function normalizeQuantiles(matrix::Array{Int})` |
| Input type: | `Array{Int}` |
| Return type: | `Array{Float64}` |

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Nullable{Float64}} function normalizeQuantiles(matrix::Array{Nullable{Float64}})` |
| Input type: | `Array{Nullable{Float64}}` |
| Return type: | `Array{Nullable{Float64}}` |

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Nullable{Float64}} function normalizeQuantiles(matrix::Array{Nullable{Int}})` |
| Input type: | `Array{Nullable{Int}}` |
| Return type: | `Array{Nullable{Float64}}` |

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Float64} function normalizeQuantiles(matrix::SharedArray{Float64})` |
| Input type: | `SharedArray{Float64}` |
| Return type: | `SharedArray{Float64}` |

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Float64} function normalizeQuantiles(matrix::SharedArray{Int})` |
| Input type: | `SharedArray{Int}` |
| Return type: | `SharedArray{Float64}` |

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Nullable{Float64}} function normalizeQuantiles(matrix::SharedArray{Nullable{Float64}})` |
| Input type: | `SharedArray{Nullable{Float64}}` |
| Return type: | `SharedArray{Nullable{Float64}}` |

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Nullable{Float64}} function normalizeQuantiles(matrix::SharedArray{Nullable{Int}})` |
| Input type: | `SharedArray{Nullable{Int}}` |
| Return type: | `SharedArray{Nullable{Float64}}` |

## Usage examples `sampleRanks`

`sampleRanks` of a given vector calculates for each element the rank, which is the position of the element in the sorted vector.

```julia
using NormalizeQuantiles
a = [ 5.0 2.0 4.0 3.0 1.0 ];
(r,m) = sampleRanks(a);   # here only return value r is relevant, for m see below
r
```
```
	julia> r
	5-element Array{Int64,1}:
	 5
	 2
	 4
	 3
	 1
```

If you provide a matrix like

```julia
array = [ 1.0 2.0 3.0 ; 4.0 5.0 6.0 ; 7.0 8.0 9.0 ; 10.0 11.0 12.0 ]
```
```
	julia> array
	4×3 Array{Float64,2}:
	  1.0   2.0   3.0
	  4.0   5.0   6.0
	  7.0   8.0   9.0
	 10.0  11.0  12.0
```

ranks are calculated column wise:
```julia
(r,m) = sampleRanks(array);
r
```
```
	julia> r
	12-element Array{Int64,1}:
	  1
	  4
	  7
	 10
	  2
	  5
	  8
	 11
	  3
	  6
	  9
	 12
```

There are three optional keyword parameters `tiesMethod`, `naIncreasesRank` and `resultMatrix`:

```julia
(r,m) = sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true);
(r,m) = sampleRanks(a,resultMatrix=true);
```

Equal values in the vector are called ties. There are several methods available on how to treat ties:
* tmMin : the smallest rank for all ties (default)
* tmMax : the largest rank
* tmOrder : increasing ranks
* tmReverse : decreasing ranks
* tmRandom : the ranks are randomly distributed
* tmAverage : the average rounded to the next integer

These methods are defined and exported as
	
```julia
	@enum qnTiesMethods tmMin tmMax tmOrder tmReverse tmRandom tmAverage
```

Internally ties have increasing ranks. On these the chosen method is applied.
	
Examples:

```julia
a = [ 7.0 2.0 4.0 2.0 1.0 ];
(r,m) = sampleRanks(a); #which is the same as (r,m)=sampleRanks(a,tiesMethod=tmMin)
r
```
```
	julia> r
	5-element Array{Int64,1}:
	 4
	 2
	 3
	 2
	 1
```
```julia
(r,m) = sampleRanks(a,tiesMethod=tmMax);
r
```
```
	julia> r
	5-element Array{Int64,1}:
	 5
	 3
	 4
	 3
	 1
```
```julia
(r,m) = sampleRanks(a,tiesMethod=tmReverse);
r
```
```
	julia> r
	5-element Array{Int64,1}:
	 5
	 3
	 4
	 2
	 1
```

One or more `NA` in the vector are never equal and remain on there position after sorting. The rank of each `NA` is always `NA`. The default is that a `NA` does not increase the rank for successive values. Giving true keyword parameter `naIncreasesRank` changes that behavior to increasing the rank by 1 for successive values:

```julia
a = [ 7.0 2.0 4.0 2.0 1.0 ];
n = Array{Nullable{Float64}}(a);
n[1] = Nullable{Float64}();
(r,m) = sampleRanks(n);
r
```
```
	julia> r
	5-element Array{Nullable{Int64},1}:
	 #NULL
	 2
	 3
	 2
	 1
```
```julia
(r,m) = sampleRanks(n,naIncreasesRank=true);
r
```
```
	julia> r
	5-element Array{Nullable{Int64},1}:
	 #NULL
	 3
	 4
	 3
	 2
```

The keyword parameter `resultMatrix` lets you generate a dictionary of rank indices to allow direct access to all values with a given rank. For large vectors this may have a large memory consumption therefor the default is to return an empty dictionary of type `Dict{Int64,Array{Int64,N}}`:

```julia
a = [ 7.0 2.0 4.0 2.0 1.0 ];
(r,m) = sampleRanks(a,resultMatrix=true);
m
```
```
	julia> m
	Dict{Int64,Array{Int64,N}} with 4 entries:
	  4 => [1]
	  2 => [2,4]
	  3 => [3]
	  1 => [5]
```
```julia
haskey(m,2)   #does rank 2 exist?
```
```
	julia> haskey(m,2)
	true
```
```julia
a[m[2]]   #all values of rank 2
```
```
	julia> a[m[2]]
	2-element Array{Float64,1}:
	 2.0
	 2.0
```

## List of all exported definitions for `sampleRanks`

| | sampleRanks |
| -----------------------: | ----------------------- | 
| **Definition:** | `@enum qnTiesMethods tmMin tmMax tmOrder tmReverse tmRandom tmAverage` |
| Description: ||
| tmMin | the smallest rank for all ties |
| tmMax | the largest rank |
| tmOrder | increasing ranks |
| tmReverse | decreasing ranks |
| tmRandom | the ranks are randomly distributed |
| tmAverage | the average rounded to the next integer |

| | sampleRanks | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Nullable{Int}},Dict{Int,Array{Int}}) sampleRanks(array::Array{Nullable{Float64}}; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `Array{Nullable{Float64}}` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Nullable{Int}},Dict{Int,Array{Int}})` ||

| | sampleRanks | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Nullable{Int}},Dict{Int,Array{Int}}) sampleRanks(array::Array{Nullable{Int}}; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `Array{Nullable{Int}}` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Nullable{Int}},Dict{Int,Array{Int}})` ||

| | sampleRanks | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Int},Dict{Int,Array{Int}}) sampleRanks(array::Array{Float64}; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `Array{Float64}` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Int},Dict{Int,Array{Int}})` ||

| | sampleRanks | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Int},Dict{Int,Array{Int}}) sampleRanks(array::Array{Int}; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `Array{Int}` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Int},Dict{Int,Array{Int}})` ||


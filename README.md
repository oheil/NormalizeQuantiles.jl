# NormalizeQuantiles

julia 0.7 support is currently under development, first release will be v0.5.0

For julia 0.4, 0.5, 0.6 see: https://github.com/oheil/NormalizeQuantiles.jl/tree/backport-0.6

Linux: [![Build Status](https://travis-ci.org/oheil/NormalizeQuantiles.jl.svg?branch=master)](https://travis-ci.org/oheil/NormalizeQuantiles.jl)
Windows: [![Build status](https://ci.appveyor.com/api/projects/status/github/oheil/normalizequantiles.jl?branch=master&svg=true)](https://ci.appveyor.com/project/oheil/normalizequantiles-jl/branch/master)

[![Coverage Status](https://coveralls.io/repos/github/oheil/NormalizeQuantiles.jl/badge.svg?branch=master)](https://coveralls.io/github/oheil/NormalizeQuantiles.jl?branch=master)

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

* [Dependencies](#dependencies)
* [Remarks](#remarks)
* [Usage examples `normalizeQuantiles`](#usage-examples-normalizequantiles)
  * [General usage](#general-usage)
  * [NaN](#nan)
  * [SharedArray and multicore usage examples](#sharedarray-and-multicore-usage-examples)
* [Behaviour of function `normalizeQuantiles`](#behaviour-of-function-normalizequantiles)
* [Data prerequisites](#data-prerequisites)
* [Remarks on data with missing values](#remarks-on-data-with-missing-values)
* [List of all exported definitions for `normalizeQuantiles`](#list-of-all-exported-definitions-for-normalizequantiles)
* [Usage examples `sampleRanks`](#usage-examples-sampleranks)
* [List of all exported definitions for `sampleRanks`](#list-of-all-exported-definitions-for-sampleranks)

## Dependencies

* Julia 0.7

## Remarks

* for julia 0.4, 0.5, 0.6 see: https://github.com/oheil/NormalizeQuantiles.jl/tree/backport-0.6
* Code examples and output on this page have been used on and copied from the julia 0.7 [REPL](https://docs.julialang.org/en/latest/manual/interacting-with-julia/)
* Last commit with julia 0.3 support: [Jan 20, 2017, eb97d24ff77d470d0d121fabf83d59979ad0db36](https://github.com/oheil/NormalizeQuantiles.jl/tree/eb97d24ff77d470d0d121fabf83d59979ad0db36)
  * git checkout eb97d24ff77d470d0d121fabf83d59979ad0db36

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
	4×3 Array{Union{Missing, Float64},2}:
	 2.0  3.0  2.0
	 4.0  6.0  4.0
	 8.0  8.0  7.0
	 6.0  3.0  7.0
```

The columns in `qn` are now quantile normalized to each other.

Return type of function normalizeQuantiles is always Array{Union{Missing, Float64},2}

#### NaN

If your data contains some NaN (Not a Number) those are changed to missing values (missing::Missing):

```julia
arrayWithNaN = array
arrayWithNaN[2,2] = NaN
```
```
	julia> arrayWithNaN
	4×3 Array{Float64,2}:
	 3.0    2.0  1.0
	 4.0  NaN    6.0
	 9.0    7.0  8.0
	 5.0    2.0  8.0
```
```julia
qn = normalizeQuantiles(arrayWithNaN)
```
```
	julia> qn
    4×3 Array{Union{Missing, Float64},2}:
     2.0  3.5       2.0
     5.0   missing  5.0
     8.0  8.0       6.5
     5.0  3.5       6.5
```

NaN is of type Float64, so there is nothing similar for Int types.

```
	julia> typeof(NaN)
	Float64
```

#### SharedArray and multicore usage examples

> Remark: restart julia now. `addprocs()` must be called before `using NormalizeQuantiles;`.

To use multiple cores on a single machine you can use `SharedArray{Float64}`:

```julia
using Distributed
addprocs();
@everywhere using SharedArrays
@everywhere using NormalizeQuantiles

array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ];
sa = SharedArray{Float64}((size(array,1),size(array,2)));
sa[:] = array[:];
sa
```
```
	julia> sa
    4×3 SharedArray{Float64,2}:
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
    4×3 Array{Union{Missing, Float64},2}:
     2.0  3.0  2.0
     4.0  6.0  4.0
     8.0  8.0  7.0
     6.0  3.0  7.0
```

For small data sets performance using `SharedArrays` decreases:

```julia
la = randn((10,10));
tf = Array{Float64}(la);
sa = SharedArray{Float64}((size(tf,1),size(tf,2)));
sa[:] = tf[:];
normalizeQuantiles(tf); @time normalizeQuantiles(tf);
```
```
	julia> @time normalizeQuantiles(tf);
	  0.015021 seconds (12.73 k allocations: 348.203 KiB)
```
```julia
normalizeQuantiles(sa); @time normalizeQuantiles(sa);
```
```
	julia> @time normalizeQuantiles(sa);
	  0.024173 seconds (12.63 k allocations: 348.078 KiB)
```

For larger data sets performance increases with multicore processors:

```julia
la = randn((10000,10000));
tf = Array{Float64}(la);
sa = SharedArray{Float64}((size(tf,1),size(tf,2)));
sa[:] = tf[:];
normalizeQuantiles(tf); @time normalizeQuantiles(tf);
```
```
	julia> @time normalizeQuantiles(tf);
	  109.319339 seconds (200.01 M allocations: 4.657 GiB, 24.76% gc time)
```
```julia
normalizeQuantiles(sa); @time normalizeQuantiles(sa);
```
```
	julia> @time normalizeQuantiles(sa);
	  32.670799 seconds (200.01 M allocations: 4.657 GiB, 44.22% gc time)
```

## Behaviour of function `normalizeQuantiles`

After quantile normalization the sets of values of each column have the same statistical properties.
This is quantile normalization without a reference column.

The function 'normalizeQuantiles' always returns a matrix of equal dimension as the input matrix and of type `Array{Union{Missing, Float64}}`.

`NaN` values are of type `Float64` and are treated as random missing values and the result value will be `missing::Missing`. See "Remarks on data with `NA`" below.

## Data prerequisites

To use quantile normalization your data should have the following properties:

* the distribution of values in each column should be similar
* number of values for each column should be large
* number of missing values in the data should be small and of random nature

## Remarks on data with missing values

Currently there seems to be no general agreement on how to deal with missing values during quantile normalization. Here we put any given missing value back into the sorted column at the original position before calculating the mean of the rows.

## List of all exported definitions for `normalizeQuantiles`

| | normalizeQuantiles |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Union{Missing,Float64}} function normalizeQuantiles(matrix::AbstractArray)` |
| Input type: | `AbstractArray` |
| Return type: | `Array{Union{Missing,Float64}}` |


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
	5-element Array{Union{Missing, Int64},1}:
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
	12-element Array{Union{Missing, Int64},1}:
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
	5-element Array{Union{Missing, Int64},1}:
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
	5-element Array{Union{Missing, Int64},1}:
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
	5-element Array{Union{Missing, Int64},1}:
	 5
	 3
	 4
	 2
	 1
```

One or more missing values in the vector are never equal and remain on there position after sorting. The rank of each missing value is always missing::Missing. The default is that a missing value does not increase the rank for successive values. Giving true keyword parameter `naIncreasesRank` changes that behavior to increasing the rank by 1 for successive values:

```julia
a = [ 7.0 2.0 4.0 2.0 1.0 ];
n = Array{Float64}(a);
n[1] = NaN;
(r,m) = sampleRanks(n);
r
```
```
	julia> r
	5-element Array{Union{Missing, Int64},1}:
	  missing
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
	5-element Array{Union{Missing, Int64},1}:
	  missing
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
	Dict{Int64,Array{Int64,N} where N} with 4 entries:
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
| **Definition:** | `(Array{Union{Missing,Int}},Dict{Int,Array{Int}}) sampleRanks(array::AbstractArray; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `AbstractArray` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Union{Missing,Int}},Dict{Int,Array{Int}})` ||



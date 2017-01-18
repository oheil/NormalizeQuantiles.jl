# NormalizeQuantiles

[![Build Status](https://travis-ci.org/oheil/NormalizeQuantiles.jl.svg?branch=master)](https://travis-ci.org/oheil/NormalizeQuantiles.jl/builds/)
[![Build status](https://ci.appveyor.com/api/projects/status/24mlc8g1x65a57h7?svg=true)](https://ci.appveyor.com/project/oheil/normalizequantiles-jl)

Package NormalizeQuantiles implements quantile normalization

```julia
qn = normalizeQuantiles(array);
```

and provides a function (julia>=0.4) to calculate sample ranks

```julia
(r,m) = sampleRanks(array);
```

of a given vector or matrix.

**Table of Contents**

- [Dependencies](#dependencies)
  - [julia version >= 0.4](#julia-version--04)
  - [julia version 0.3](#julia-version-03)
- [Usage examples `normalizeQuantiles`](#usage-examples-normalizequantiles)
  - [Example for julia version >= 0.4](#example-for-julia-version--04)
  - [Multicore usage examples for julia version >= 0.4](#multicore-usage-examples-for-julia-version--04)
  - [Example for julia version 0.3](#example-for-julia-version-03)
  - [Multicore usage examples for julia version 0.3](#multicore-usage-examples-for-julia-version-03)
- [Behaviour of function `normalizeQuantiles`](#behaviour-of-function-normalizequantiles)
  - [For julia version >= 0.4](#for-julia-version--04)
  - [For julia version 0.3](#for-julia-version-03)
- [Data prerequisites](#data-prerequisites)
- [Remarks on performance](#remarks-on-performance)
- [Remarks on data with `NA`](#remarks-on-data-with-na)
- [List of all exported definitions for `normalizeQuantiles`](#list-of-all-exported-definitions-for-normalizequantiles)
- [Usage examples `sampleRanks`](#usage-examples-sampleranks)
- [List of all exported definitions for `sampleRanks`](#list-of-all-exported-definitions-for-sampleranks)

## Dependencies

#### julia version >= 0.4

No dependencies

#### julia version 0.3

[DataArrays](https://github.com/JuliaStats/DataArrays.jl) ([StatsBase](https://github.com/JuliaStats/StatsBase.jl),[Compat](https://github.com/JuliaLang/Compat.jl),[Reexport](https://github.com/simonster/Reexport.jl))

## Usage examples `normalizeQuantiles`
 
#### Example for julia version >= 0.4

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
	4x3 Array{Float64,2}:
	 2.0  3.0  2.0
	 4.0  6.0  4.0
	 8.0  8.0  7.0
	 6.0  3.0  7.0
```

The columns in `qn` are now quantile normalized to each other.

Missing values `NA` are handled using [Nullables](http://docs.julialang.org/en/release-0.4/manual/types/#nullable-types-representing-missing-values):

```julia
arrayWithNA = Array{Nullable{Float64}}(array);
arrayWithNA[2,2] = Nullable{Float64}();
arrayWithNA


```
```
	julia> arrayWithNA
	4x3 Array{Nullable{Float64},2}:
	 Nullable(3.0)  Nullable(2.0)        Nullable(1.0)
	 Nullable(4.0)  Nullable{Float64}()  Nullable(6.0)
	 Nullable(9.0)  Nullable(7.0)        Nullable(8.0)
	 Nullable(5.0)  Nullable(2.0)        Nullable(8.0)
```
```julia
qn = normalizeQuantiles(arrayWithNA)


```
```
	julia> qn
	4x3 Array{Nullable{Float64},2}:
	 Nullable(2.0)  Nullable(3.5)        Nullable(2.0)
	 Nullable(5.0)  Nullable{Float64}()  Nullable(5.0)
	 Nullable(8.0)  Nullable(8.0)        Nullable(6.5)
	 Nullable(5.0)  Nullable(3.5)        Nullable(6.5)
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
qn_array = convert(Array{Float64},reshape([get(qn[i]) for i=1:length(qn)],size(qn)));
qn_array


```
```
	julia> qn_array
	4x3 Array{Float64,2}:
	 2.0  4.5  2.0
	 4.0  0.0  4.0
	 8.0  8.0  6.5
	 5.0  4.5  6.5
```

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
	4x3 NullableArrays.NullableArray{Float64,2}:
	 3.0      2.0  1.0
	 4.0  #NULL    6.0
	 9.0      7.0  8.0
	 5.0      2.0  8.0	
```

Convert the `NullableArray` `na` to `Array{Nullable{Float64}}`:

```julia
arrayOfNullables = convert(Array{Nullable{Float64}},reshape([na[i] for i=1:length(na)],size(na)));
qn = normalizeQuantiles(arrayOfNullables)


```
```
	julia> qn
	4x3 Array{Nullable{Float64},2}:
	 Nullable(2.0)  Nullable(4.5)        Nullable(2.0)
	 Nullable(4.0)  Nullable{Float64}()  Nullable(4.0)
	 Nullable(8.0)  Nullable(8.0)        Nullable(6.5)
	 Nullable(5.0)  Nullable(4.5)        Nullable(6.5)	
```

Convert the result `Array{Nullable{Float64}}` back to `NullableArray`:

```julia
isn = convert(Array{Bool},reshape([isnull(qn[i]) for i=1:length(qn)],size(qn)));
qn[isn] = 0.0;
qna = NullableArray(convert(Array{Float64},reshape([get(qn[i]) for i=1:length(qn)],size(qn))),isn)


```
```
	julia> qna
	4x3 NullableArrays.NullableArray{Float64,2}:
	 2.0      3.5  2.0
	 5.0  #NULL    5.0
	 8.0      8.0  6.5
	 5.0      3.5  6.5
```

Dealing with `DataArrays` in julia version >= 0.4 (if you use julia 0.3 and DataArrays see below the examples for julia version 0.3):

```julia
using DataArrays;
da = DataArray(array)


```
```
	julia> da
	4x3 DataArrays.DataArray{Float64,2}:
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
arrayWithNA = convert(Array{Nullable{Float64}},reshape([isna(da[i])?Nullable{Float64}():Nullable{Float64}(da[i]) for i=1:length(da)],size(da)))


```
```
	julia> arrayWithNA
	4x3 Array{Nullable{Float64},2}:
	 Nullable(3.0)  Nullable(2.0)        Nullable(1.0)
	 Nullable(4.0)  Nullable{Float64}()  Nullable(6.0)
	 Nullable(9.0)  Nullable(7.0)        Nullable(8.0)
	 Nullable(5.0)  Nullable(2.0)        Nullable(8.0)
```
```julia
qn = normalizeQuantiles(arrayWithNA)


```
```
	julia> qn
	4x3 Array{Nullable{Float64},2}:
	 Nullable(2.0)  Nullable(3.5)        Nullable(2.0)
	 Nullable(5.0)  Nullable{Float64}()  Nullable(5.0)
	 Nullable(8.0)  Nullable(8.0)        Nullable(6.5)
	 Nullable(5.0)  Nullable(3.5)        Nullable(6.5)
```

Converting the result `Array{Nullable{Float64}}` back to `DataArray` containg `NAs`:

```julia
daqn = DataArray(Float64,size(qn));
daqn[1:length(qn)] = DataArray(reshape([isnull(qn[i])?NA:get(qn[i]) for i=1:length(qn)],size(qn)))[1:length(qn)];
daqn


```
```
	julia> daqn
	4x3 DataArrays.DataArray{Float64,2}:
	 2.0  3.5  2.0
	 5.0   NA  5.0
	 8.0  8.0  6.5
	 5.0  3.5  6.5
```

#### Multicore usage examples for julia version >= 0.4

> Remark: restart julia now. `addprocs()` must be called before `using NormalizeQuantiles;`. Doing it the other way round will result in an error.

To use multiple cores on a single machine you can use `SharedArray{Nullable{Float64}}`:

```julia
addprocs();
using NormalizeQuantiles;
array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ];
sa=SharedArray(Nullable{Float64},(size(array,1),size(array,2)));
sa[:]=array[:];
sa


```
```
	julia> sa
	4x3 SharedArray{Nullable{Float64},2}:
	 Nullable(3.0)  Nullable(2.0)  Nullable(1.0)
	 Nullable(4.0)  Nullable(5.0)  Nullable(6.0)
	 Nullable(9.0)  Nullable(7.0)  Nullable(8.0)
	 Nullable(5.0)  Nullable(2.0)  Nullable(8.0)
```
```julia
qn = normalizeQuantiles(sa)


```
```
	julia> qn
	4x3 SharedArray{Nullable{Float64},2}:
	 Nullable(2.0)  Nullable(3.0)  Nullable(2.0)
	 Nullable(4.0)  Nullable(6.0)  Nullable(4.0)
	 Nullable(8.0)  Nullable(8.0)  Nullable(7.0)
	 Nullable(6.0)  Nullable(3.0)  Nullable(7.0)	
```

#### Example for julia version 0.3

```julia
Pkg.add("NormalizeQuantiles");
using NormalizeQuantiles;
using DataArrays;
array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ];
qn = normalizeQuantiles(array)


```
```
	julia> qn
	4x3 DataArrays.DataArray{Float64,2}:
     2.0  3.0  2.0
     4.0  6.0  4.0
     8.0  8.0  7.0
     6.0  3.0  7.0
```
	
```julia
da = DataArray(array);
da[2,2] = NA;
daqn = normalizeQuantiles(da)


```
```
	julia> daqn
	4x3 DataArray{Float64,2}:
	 2.0  3.5  2.0
	 5.0   NA  5.0
	 8.0  8.0  6.5
	 5.0  3.5  6.5
```

#### Multicore usage examples for julia version 0.3

> Remark: restart julia now. `addprocs()` must be called before `using NormalizeQuantiles;`. Doing it the other way round will result in an error.

To use multiple cores on a single machine you can use `SharedArray{Float64}`. Using multiple cores for data with `NA` is not implemented for julia 0.3:

```julia
addprocs(8);
using NormalizeQuantiles;
array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ];
sa=SharedArray(Float64,(size(array,1),size(array,2)));
sa[:]=array[:];
sa


```
```
	julia> sa
	4x3 SharedArray{Float64,2}:
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
	4x3 SharedArray{Float64,2}:
	 2.0  3.0  2.0
	 4.0  6.0  4.0
	 8.0  8.0  7.0
	 6.0  3.0  7.0
```
 
## Behaviour of function `normalizeQuantiles`

After quantile normalization the sets of values of each column have the same statistical properties.
This is quantile normalization without a reference column.

#### For julia version >= 0.4:

The function 'normalizeQuantiles' always returns a matrix of equal dimension as the input matrix and of type `Array{Float64}` or `Array{Nullable{Float64}}`. In case of Float64-type input matrices `normalizeQuantiles` returns the same type, in case of Int-type input matrices the result matrix will be the same but with base type Float64, e.g. a `Array{Nullable{Int}}` will result in `Array{Nullable{Float64}}`.

`NA` values are of type `Nullable{Float64}` and are treated as random missing values and the result value will be `Nullable{Float64}` again. See "Remarks on data with `NA`" below.

#### For julia version 0.3:

The function `normalizeQuantiles` always returns a `DataArray` of equal dimension as the input matrix.

`NA` values are treated as random missing values and the result value will be `NA` again. See "Remarks on data with `NA`" below.
	
## Data prerequisites

To use quantile normalization your data should have the following properties:

* the distribution of values in each column should be similar
* number of values for each column should be large
* number of `NA` in the data should be small and of random nature

## Remarks on performance

In julia version 0.3 `NA` values have been implemented using the Package DataArray. With julia 0.4 the concept of Nullables has been introduced. Tests using DataArrays and Arrays of Nullables have shown, that performance of Arrays of Nullables is superior to DataArrays. Therefore with julia version 0.4 the dependency on DataArrays is dropped in favor of Arrays of Nullables:

#### julia version 0.3:

```julia
using NormalizeQuantiles;
r=randn((1000,10));
qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);


```
```
	julia> @time qn=normalizeQuantiles(r);
	elapsed time: 0.021892844 seconds (6432744 bytes allocated)
```
```julia
r=randn((10000,10));
qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);


```
```
	julia> @time qn=normalizeQuantiles(r);
	elapsed time: 0.307518666 seconds (64381344 bytes allocated, 32.34% gc time)
```
```julia
r=randn((1000,100));
qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);


```
```
	julia> @time qn=normalizeQuantiles(r);
	elapsed time: 0.127257423 seconds (49638624 bytes allocated, 33.66% gc time)
```
```julia
r=randn((100000,10));
qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);


```
```
	julia> @time qn=normalizeQuantiles(r);
	elapsed time: 2.527081368 seconds (637277984 bytes allocated, 23.32% gc time)
```

#### julia version 0.4:

```julia
using NormalizeQuantiles;
r=randn((1000,10));
qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);


```
```
	julia> @time qn=normalizeQuantiles(r);
	  0.004806 seconds (13.39 k allocations: 4.605 MB)
```
```julia
r=randn((10000,10));
qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);	


```
```
	julia> @time qn=normalizeQuantiles(r);
	  0.055855 seconds (148.48 k allocations: 46.976 MB, 10.61% gc time)
```
```julia
r=randn((1000,100));
qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);


```
```
	julia> @time qn=normalizeQuantiles(r);
	  0.032935 seconds (20.36 k allocations: 41.598 MB, 11.14% gc time)
```
```julia
r=randn((100000,10));
qn=normalizeQuantiles(r);@time qn=normalizeQuantiles(r);


```
```
	julia> @time qn=normalizeQuantiles(r);
	  0.556000 seconds (1.50 M allocations: 464.510 MB, 8.81% gc time)
```

## Remarks on data with `NA`

Currently there seems to be no general agreement on how to deal with `NA` during quantile normalization. Here we put any given `NA` back into the sorted column at the original position before calculating the mean of the rows.

## List of all exported definitions for `normalizeQuantiles`

| | normalizeQuantiles, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Float64} function normalizeQuantiles(matrix::Array{Float64})` |
| Input type: | `Array{Float64}` |
| Return type: | `Array{Float64}` |

| | normalizeQuantiles, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Float64} function normalizeQuantiles(matrix::Array{Int})` |
| Input type: | `Array{Int}` |
| Return type: | `Array{Float64}` |

| | normalizeQuantiles, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Nullable{Float64}} function normalizeQuantiles(matrix::Array{Nullable{Float64}})` |
| Input type: | `Array{Nullable{Float64}}` |
| Return type: | `Array{Nullable{Float64}}` |

| | normalizeQuantiles, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `Array{Nullable{Float64}} function normalizeQuantiles(matrix::Array{Nullable{Int}})` |
| Input type: | `Array{Nullable{Int}}` |
| Return type: | `Array{Nullable{Float64}}` |

| | normalizeQuantiles, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Float64} function normalizeQuantiles(matrix::SharedArray{Float64})` |
| Input type: | `SharedArray{Float64}` |
| Return type: | `SharedArray{Float64}` |

| | normalizeQuantiles, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Float64} function normalizeQuantiles(matrix::SharedArray{Int})` |
| Input type: | `SharedArray{Int}` |
| Return type: | `SharedArray{Float64}` |

| | normalizeQuantiles, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Nullable{Float64}} function normalizeQuantiles(matrix::SharedArray{Nullable{Float64}})` |
| Input type: | `SharedArray{Nullable{Float64}}` |
| Return type: | `SharedArray{Nullable{Float64}}` |

| | normalizeQuantiles, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Nullable{Float64}} function normalizeQuantiles(matrix::SharedArray{Nullable{Int}})` |
| Input type: | `SharedArray{Nullable{Int}}` |
| Return type: | `SharedArray{Nullable{Float64}}` |

| | normalizeQuantiles, julia version = 0.3 |
| -----------------------: | ----------------------- | 
| **Definition:** | `DataArray{Float64} function normalizeQuantiles(matrix::Array{Float64})` |
| Input type: | `Array{Float64}` |
| Return type: | `DataArray{Float64}` |

| | normalizeQuantiles, julia version = 0.3 |
| -----------------------: | ----------------------- | 
| **Definition:** | `DataArray{Float64} function normalizeQuantiles(matrix::Array{Int})` |
| Input type: | `Array{Int}` |
| Return type: | `DataArray{Float64}` |

| | normalizeQuantiles, julia version = 0.3 |
| -----------------------: | ----------------------- | 
| **Definition:** | `DataArray{Float64} function normalizeQuantiles(matrix::DataArray{Float64})` |
| Input type: | `DataArray{Float64}` |
| Return type: | `DataArray{Float64}` |

| | normalizeQuantiles, julia version = 0.3 |
| -----------------------: | ----------------------- | 
| **Definition:** | `DataArray{Float64} function normalizeQuantiles(matrix::DataArray{Int})` |
| Input type: | `DataArray{Int}` |
| Return type: | `DataArray{Float64}` |

| | normalizeQuantiles, julia version = 0.3 |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Float64} function normalizeQuantiles(matrix::SharedArray{Float64})` |
| Input type: | `SharedArray{Float64}` |
| Return type: | `SharedArray{Float64}` |

| | normalizeQuantiles, julia version = 0.3 |
| -----------------------: | ----------------------- | 
| **Definition:** | `SharedArray{Float64} function normalizeQuantiles(matrix::SharedArray{Int})` |
| Input type: | `SharedArray{Int}` |
| Return type: | `SharedArray{Float64}` |

## Usage examples `sampleRanks`

##### Only available for julia>=0.4

`sampleRanks` of a given vector calculates for each element the rank, which is the position of the element in the sorted vector.

```julia
using NormalizeQuantiles
a = [ 5.0 2.0 4.0 3.0 1.0 ];
(r,m)=sampleRanks(a);   # here only return value r is relevant, for m see below
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
	4x3 Array{Float64,2}:
	  1.0   2.0   3.0
	  4.0   5.0   6.0
	  7.0   8.0   9.0
	 10.0  11.0  12.0
```

ranks are calculated column wise:
```julia
(r,m)=sampleRanks(array);
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
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true);
(r,m)=sampleRanks(a,resultMatrix=true);


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
(r,m)=sampleRanks(a); #which is the same as (r,m)=sampleRanks(a,tiesMethod=tmMin)
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
(r,m)=sampleRanks(a,tiesMethod=tmMax);
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
(r,m)=sampleRanks(a,tiesMethod=tmReverse);
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
n[1]=Nullable{Float64}();
(r,m)=sampleRanks(n);
r


```
```
	julia> r
	5-element Array{Nullable{Int64},1}:
	 Nullable{Int64}()
	 Nullable(2)
	 Nullable(3)
	 Nullable(2)
	 Nullable(1)	
```
```julia
(r,m)=sampleRanks(n,naIncreasesRank=true);
r


```
```
	julia> r
	5-element Array{Nullable{Int64},1}:
	 Nullable{Int64}()
	 Nullable(3)
	 Nullable(4)
	 Nullable(3)
	 Nullable(2)	
```

The keyword parameter `resultMatrix` lets you generate a dictionary of rank indices to allow direct access to all values with a given rank. For large vectors this may have a large memory consumption therefor the default is to return an empty dictionary of type `Dict{Int64,Array{Int64,N}}`:

```julia
a = [ 7.0 2.0 4.0 2.0 1.0 ];
(r,m)=sampleRanks(a,resultMatrix=true);
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

| | sampleRanks, julia version >= 0.4 |
| -----------------------: | ----------------------- | 
| **Definition:** | `@enum qnTiesMethods tmMin tmMax tmOrder tmReverse tmRandom tmAverage` |
| Description: ||
| tmMin | the smallest rank for all ties |
| tmMax | the largest rank |
| tmOrder | increasing ranks |
| tmReverse | decreasing ranks |
| tmRandom | the ranks are randomly distributed |
| tmAverage | the average rounded to the next integer |

| | sampleRanks, julia version >= 0.4 | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Nullable{Int}},Dict{Int,Array{Int}}) sampleRanks(array::Array{Nullable{Float64}}; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `Array{Nullable{Float64}}` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Nullable{Int}},Dict{Int,Array{Int}})` ||

| | sampleRanks, julia version >= 0.4 | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Nullable{Int}},Dict{Int,Array{Int}}) sampleRanks(array::Array{Nullable{Int}}; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `Array{Nullable{Int}}` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Nullable{Int}},Dict{Int,Array{Int}})` ||

| | sampleRanks, julia version >= 0.4 | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Int},Dict{Int,Array{Int}}) sampleRanks(array::Array{Float64}; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `Array{Float64}` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Int},Dict{Int,Array{Int}})` ||

| | sampleRanks, julia version >= 0.4 | |
| -----------------------: | ----------------------- | ----------------------- | 
| **Definition:** | `(Array{Int},Dict{Int,Array{Int}}) sampleRanks(array::Array{Int}; tiesMethod::qnTiesMethods=tmMin, naIncreasesRank=false, resultMatrix=false)` | **keyword arguments** |
| Input type: | `Array{Int}` | data |
| Input type: | `qnTiesMethods` | how to treat ties (default: `tmMin`) |
| Input type: | `bool` | increase rank by one if NA (default: `false`) |
| Input type: | `bool` | create rank dictionary (default: `false`) |
| Return type: | `(Array{Int},Dict{Int,Array{Int}})` ||


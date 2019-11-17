
using Revise

using NormalizeQuantiles

using SharedArrays
using Statistics

using Random

using BenchmarkTools

nrows=5000
ncols=50

sa=SharedArray{Float64}(nrows,ncols)
sa2=SharedArray{Float64}(nrows,ncols)
a=Array{Float64}(undef,nrows,ncols)
r=Array{Float64}(undef,nrows,ncols)
i=Array{Int}(undef,nrows,ncols)

icol=rand(Int,nrows)
col=rand(Float64,nrows)

allcols=collect(1:ncols)
[ a[:,c]=rand(Float64,nrows) for c in allcols ]

#benchmark preallocation of result array
@benchmark sa=SharedArray{Float64}($nrows,$ncols)
@benchmark a=Array{Float64}(undef,$nrows,$ncols)
@benchmark z=zeros($nrows,$ncols)

#benchmark writing column into result
randperm!(allcols)
@benchmark [ $sa[:,c]=$col for c in $allcols ]
@benchmark [ $a[:,c]=$col for c in $allcols ]
@benchmark [ $i[:,c]=$icol for c in $allcols ]

@benchmark goodIndices=[ ! NormalizeQuantiles.checkForNotANumber(x) for x in vec($a[:,1]) ]
@benchmark goodIndices=[ NormalizeQuantiles.checkForNotANumber(x) for x in vec($a[:,1]) ]
@benchmark goodIndices=.!NormalizeQuantiles.checkForNotANumber.($a[:,1])
@benchmark goodIndices=NormalizeQuantiles.checkForNotANumber.($a[:,1])

somerows=rand(1:nrows,10000)
a[somerows,1].=NaN
column=1
matrix=a
goodIndices=[ ! NormalizeQuantiles.checkForNotANumber(x) for x in vec(matrix[:,column]) ]
sortcol=vec(matrix[:,column])[goodIndices]
@benchmark sortcol=[Float64(x) for x in $sortcol]
@benchmark sortcol=Array{Float64}($sortcol)

matrix=i
goodIndices=[ ! NormalizeQuantiles.checkForNotANumber(x) for x in vec(matrix[:,column]) ]
sortcol=vec(matrix[:,column])[goodIndices]
@benchmark sortcol=[Float64(x) for x in $sortcol]
@benchmark sortcol=Array{Float64}($sortcol)

matrix=a
@benchmark missingIndices=(1:$nrows)[[ NormalizeQuantiles.checkForNotANumber(x) for x in vec($matrix[:,$column]) ]]
@benchmark missingIndices=findall(x->x==true,[ NormalizeQuantiles.checkForNotANumber(x) for x in vec($matrix[:,$column]) ])

@benchmark NormalizeQuantiles.oldSortColumns!($a,$sa,$nrows,$ncols)
@benchmark NormalizeQuantiles.sortColumns!($a,$sa2,$nrows,$ncols)

nas=15
for c in 1:ncols
    somerows=rand(1:nrows,nas)
    a[somerows,c].=NaN
end
NormalizeQuantiles.oldSortColumns!(a,sa,nrows,ncols)
NormalizeQuantiles.sortColumns!(a,sa2,nrows,ncols)
r=sa.===sa2
findall(x->x==0,r)

@benchmark NormalizeQuantiles.oldMeanRows!($sa,$nrows)
@benchmark NormalizeQuantiles.meanRows!($sa2,$nrows)

NormalizeQuantiles.oldMeanRows!(sa,nrows)
NormalizeQuantiles.meanRows!(sa2,nrows)
r=sa.===sa2
findall(x->x==0,r)

@benchmark NormalizeQuantiles.oldEqualValuesInColumnAndOrderToOriginal!($a,$sa,$nrows,$ncols)
@benchmark NormalizeQuantiles.equalValuesInColumnAndOrderToOriginal!($a,$sa2,$nrows,$ncols)

NormalizeQuantiles.equalValuesInColumnAndOrderToOriginal!(a,sa,nrows,ncols)
NormalizeQuantiles.equalValuesInColumnAndOrderToOriginal!(a,sa2,nrows,ncols)
r=sa.===sa2
findall(x->x==0,r)

@benchmark sa=NormalizeQuantiles.oldNormalizeQuantiles($a)
@benchmark sa2=NormalizeQuantiles.normalizeQuantiles($a)

sa=NormalizeQuantiles.oldNormalizeQuantiles(a)
sa2=NormalizeQuantiles.normalizeQuantiles(a)
r=sa.===sa2
findall(x->x==0,r)


A8 = [1,2,3,4,1,2,4,4]
A1000 = rand(1:20, 1000);
A10k = rand(1:20, 10_000);

nrows=100
A100 = rand(nrows);
nas=70
somerows=rand(1:nrows,nas)
A100[somerows].=NaN



@benchmark NormalizeQuantiles.newSampleRanks($A8,-1)
@benchmark NormalizeQuantiles.sampleRanks($A8)

@benchmark NormalizeQuantiles.newSampleRanks($A1000,-1)
@benchmark NormalizeQuantiles.sampleRanks($A1000)

@benchmark NormalizeQuantiles.newSampleRanks($A10k,-1.0)
@benchmark NormalizeQuantiles.sampleRanks($A10k)



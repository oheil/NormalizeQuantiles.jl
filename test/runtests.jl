
using NormalizeQuantiles

using Base.Test

# write your own tests here
@test 1 == 1

if VERSION >= v"0.4.0-"

testfloat = [ 3.0 2.0 8.0 1.0 ; 4.0 5.0 6.0 2.0 ; 9.0 7.0 8.0 3.0 ; 5.0 2.0 8.0 4.0 ]
r=normalizeQuantiles(testfloat)
@test mean(r[:,1]) >= 4.8124 && mean(r[:,1]) <= 4.8126
@test mean(r[:,2]) >= 4.8124 && mean(r[:,2]) <= 4.8126
@test mean(r[:,3]) >= 4.8124 && mean(r[:,3]) <= 4.8126
@test mean(r[:,4]) >= 4.8124 && mean(r[:,4]) <= 4.8126

sa=SharedArray(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
sa[:]=testfloat[:]
r=normalizeQuantiles(sa)
r=convert(Array{Float64},reshape([get(r[i]) for i=1:length(r)],size(r)))
@test mean(r[:,1]) >= 4.8124 && mean(r[:,1]) <= 4.8126
@test mean(r[:,2]) >= 4.8124 && mean(r[:,2]) <= 4.8126
@test mean(r[:,3]) >= 4.8124 && mean(r[:,3]) <= 4.8126
@test mean(r[:,4]) >= 4.8124 && mean(r[:,4]) <= 4.8126

testfloat = [ 3.5 2.0 8.1 1.0 ; 4.5 5.0 6.0 2.0 ; 9.0 7.6 8.2 3.0 ; 5.0 2.0 8.0 4.0 ]
r=normalizeQuantiles(testfloat)
@test mean(r[:,1]) >= 4.93124 && mean(r[:,1]) <= 4.93125
@test mean(r[:,2]) >= 4.93124 && mean(r[:,2]) <= 4.93125
@test mean(r[:,3]) >= 4.93124 && mean(r[:,3]) <= 4.93125
@test mean(r[:,4]) >= 4.93124 && mean(r[:,4]) <= 4.93125

sa=SharedArray(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
sa[:]=testfloat[:]
r=normalizeQuantiles(sa)
r=convert(Array{Float64},reshape([get(r[i]) for i=1:length(r)],size(r)))
@test mean(r[:,1]) >= 4.93124 && mean(r[:,1]) <= 4.93125
@test mean(r[:,2]) >= 4.93124 && mean(r[:,2]) <= 4.93125
@test mean(r[:,3]) >= 4.93124 && mean(r[:,3]) <= 4.93125
@test mean(r[:,4]) >= 4.93124 && mean(r[:,4]) <= 4.93125

testfloat=[ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
check=[ 2.0 3.0 2.0 ; 4.0 6.0 4.0 ; 8.0 8.0 7.0 ; 6.0 3.0 7.0 ]
qn=normalizeQuantiles(testfloat)
@test qn == check
sa=SharedArray(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
sa[:]=testfloat[:]
qn=normalizeQuantiles(sa)
qn=convert(Array{Float64},reshape([get(qn[i]) for i=1:length(qn)],size(qn)))
@test qn == check

testint = [ 1 1 1 ; 1 1 1 ; 1 1 1 ]
qn=normalizeQuantiles(testint)
@test qn == testint
sa=SharedArray(Nullable{Int},(size(testint,1),size(testint,2)));
sa[:]=testint[:]
qn=normalizeQuantiles(sa)
qn=convert(Array{Float64},reshape([get(qn[i]) for i=1:length(qn)],size(qn)))
@test qn == testint
sa=SharedArray(Int,(size(testint,1),size(testint,2)));
sa[:]=testint[:]
qn=normalizeQuantiles(sa)


dafloat=Array{Nullable{Float64}}(testfloat)
dafloat[2,2]=Nullable{Float64}()
qn=normalizeQuantiles(dafloat)
@test isnull(qn[2,2])
@test get(qn[1,2])==3.5
@test get(qn[2,1])==5.0
sa=SharedArray(Nullable{Float64},(size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn=normalizeQuantiles(sa)
@test isnull(qn[2,2])
@test get(qn[1,2])==3.5
@test get(qn[2,1])==5.0

dafloat[2,:]=Nullable{Float64}()
qn=normalizeQuantiles(dafloat)
@test isnull(qn[2,1])
@test isnull(qn[2,2])
@test isnull(qn[2,3])
sa=SharedArray(Nullable{Float64},(size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn=normalizeQuantiles(sa)
@test isnull(qn[2,1])
@test isnull(qn[2,2])
@test isnull(qn[2,3])

dafloat[3,1:2]=Nullable{Float64}()
qn=normalizeQuantiles(dafloat)
@test isnull(qn[3,1])
@test isnull(qn[3,2])
sa=SharedArray(Nullable{Float64},(size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn=normalizeQuantiles(sa)
@test isnull(qn[3,1])
@test isnull(qn[3,2])

dafloat[1,:]=Nullable{Float64}()
dafloat[2,:]=Nullable{Float64}()
dafloat[3,:]=Nullable{Float64}()
dafloat[4,:]=Nullable{Float64}()
qn = normalizeQuantiles(dafloat)
@test isnull(qn[1,1])
@test isnull(qn[1,2])
@test isnull(qn[1,3])
@test isnull(qn[2,1])
@test isnull(qn[2,2])
@test isnull(qn[2,3])
@test isnull(qn[3,1])
@test isnull(qn[3,2])
@test isnull(qn[3,3])
@test isnull(qn[4,1])
@test isnull(qn[4,2])
@test isnull(qn[4,3])
sa=SharedArray(Nullable{Float64},(size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn=normalizeQuantiles(sa)
@test isnull(qn[1,1])
@test isnull(qn[1,2])
@test isnull(qn[1,3])
@test isnull(qn[2,1])
@test isnull(qn[2,2])
@test isnull(qn[2,3])
@test isnull(qn[3,1])
@test isnull(qn[3,2])
@test isnull(qn[3,3])
@test isnull(qn[4,1])
@test isnull(qn[4,2])
@test isnull(qn[4,3])


testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[4]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,1,4,0,2])

testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmOrder,naIncreasesRank=true,resultMatrix=true)
r[4]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,2,5,0,3])

testfloat = [ 2.0 2.0 8.0 0.0 7.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[4]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
r[4]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,1,3,0,2])

testfloat = [ 5.0 2.0 4.0 3.0 1.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([5,2,4,3,1])

testfloat = [ 2.0 2.0 0.0 2.0 2.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[3]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,1,0,1,1])

testfloat = [ 2.0 2.0 0.0 2.0 4.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[3]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,1,0,1,3])

testfloat = [ 2.0 2.0 0.0 2.0 4.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
r[3]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,1,0,1,2])

testfloat = [ 2.0 2.0 0.0 3.0 4.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[3]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,1,0,3,4])

testfloat = [ 2.0 2.0 0.0 3.0 4.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[3]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
r[3]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,1,0,2,3])

testfloat = [ 0.0 2.0 5.0 3.0 4.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r[1]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([0,2,5,3,4])

testfloat = [ 0.0 2.0 5.0 3.0 4.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
a[1]=Nullable{Float64}()
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
r[1]=Nullable{Int}(0)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([0,1,4,2,3])

testfloat = [ 2.0 2.0 2.0 2.0 2.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
(r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=true,resultMatrix=true)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([1,1,1,1,1])

testfloat = [ 2.0 2.0 2.0 2.0 2.0 ]
a=Array(Nullable{Float64},(size(testfloat,1),size(testfloat,2)));
a[:]=testfloat[:]
(r,m)=sampleRanks(a,tiesMethod=tmReverse,naIncreasesRank=true,resultMatrix=true)
r=[ Int(get(x)) for x in r ]
@test r==Array{Int}([5,4,3,2,1])

end # if VERSION >= v"0.4.0-"

if VERSION < v"0.4.0-"

using DataArrays

testfloat = [ 3.0 2.0 8.0 1.0 ; 4.0 5.0 6.0 2.0 ; 9.0 7.0 8.0 3.0 ; 5.0 2.0 8.0 4.0 ]
dafloat=DataArray(testfloat)
r=normalizeQuantiles(dafloat)
@test mean(r[:,1]) >= 4.8124 && mean(r[:,1]) <= 4.8126
@test mean(r[:,2]) >= 4.8124 && mean(r[:,2]) <= 4.8126
@test mean(r[:,3]) >= 4.8124 && mean(r[:,3]) <= 4.8126
@test mean(r[:,4]) >= 4.8124 && mean(r[:,4]) <= 4.8126
sa=SharedArray(Float64,(size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
r=normalizeQuantiles(sa)
@test mean(r[:,1]) >= 4.8124 && mean(r[:,1]) <= 4.8126
@test mean(r[:,2]) >= 4.8124 && mean(r[:,2]) <= 4.8126
@test mean(r[:,3]) >= 4.8124 && mean(r[:,3]) <= 4.8126
@test mean(r[:,4]) >= 4.8124 && mean(r[:,4]) <= 4.8126

testfloat = [ 3.5 2.0 8.1 1.0 ; 4.5 5.0 6.0 2.0 ; 9.0 7.6 8.2 3.0 ; 5.0 2.0 8.0 4.0 ]
dafloat=DataArray(testfloat)
r=normalizeQuantiles(dafloat)
@test mean(r[:,1]) >= 4.93124 && mean(r[:,1]) <= 4.93125
@test mean(r[:,2]) >= 4.93124 && mean(r[:,2]) <= 4.93125
@test mean(r[:,3]) >= 4.93124 && mean(r[:,3]) <= 4.93125
@test mean(r[:,4]) >= 4.93124 && mean(r[:,4]) <= 4.93125
sa=SharedArray(Float64,(size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
r=normalizeQuantiles(sa)
@test mean(r[:,1]) >= 4.93124 && mean(r[:,1]) <= 4.93125
@test mean(r[:,2]) >= 4.93124 && mean(r[:,2]) <= 4.93125
@test mean(r[:,3]) >= 4.93124 && mean(r[:,3]) <= 4.93125
@test mean(r[:,4]) >= 4.93124 && mean(r[:,4]) <= 4.93125

testfloat = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
check = [ 2.0 3.0 2.0 ; 4.0 6.0 4.0 ; 8.0 8.0 7.0 ; 6.0 3.0 7.0 ]
qn = normalizeQuantiles(testfloat)
@test qn == check
sa=SharedArray(Float64,(size(testfloat,1),size(testfloat,2)));
sa[:]=testfloat[:]
qn = normalizeQuantiles(sa)
@test qn == check

testint = [ 1 1 1 ; 1 1 1 ; 1 1 1 ]
qn = normalizeQuantiles(testint)
@test qn == testint

dafloat = DataArray(testfloat)
dacheck = DataArray(check)
qn = normalizeQuantiles(dafloat)
@test qn == check
sa=SharedArray(Float64,(size(dafloat,1),size(dafloat,2)));
sa[:]=dafloat[:]
qn = normalizeQuantiles(sa)
@test qn == check

daint = DataArray(testint)
qn = normalizeQuantiles(daint)
@test qn == daint

dafloat[2,2]=NA
qn = normalizeQuantiles(dafloat)
@test isa(qn[2,2],NAtype)
@test qn[1,2]==3.5
@test qn[2,1]==5.0

dafloat[2,:]=NA
qn = normalizeQuantiles(dafloat)
@test isa(qn[2,1],NAtype)
@test isa(qn[2,2],NAtype)
@test isa(qn[2,3],NAtype)

dafloat[3,1:2]=NA
qn = normalizeQuantiles(dafloat)
@test isa(qn[3,1],NAtype)
@test isa(qn[3,2],NAtype)

dafloat[1,:]=NA
dafloat[2,:]=NA
dafloat[3,:]=NA
dafloat[4,:]=NA
qn = normalizeQuantiles(dafloat)
@test isa(qn[1,1],NAtype)
@test isa(qn[1,2],NAtype)
@test isa(qn[1,3],NAtype)
@test isa(qn[2,1],NAtype)
@test isa(qn[2,2],NAtype)
@test isa(qn[2,3],NAtype)
@test isa(qn[3,1],NAtype)
@test isa(qn[3,2],NAtype)
@test isa(qn[3,3],NAtype)
@test isa(qn[4,1],NAtype)
@test isa(qn[4,2],NAtype)
@test isa(qn[4,3],NAtype)

end # if VERSION < v"0.4.0-"



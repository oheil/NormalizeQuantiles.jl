
using NormalizeQuantiles

using Base.Test

# write your own tests here
@test 1 == 1

if VERSION >= v"0.4.0-"

testfloat = [ 3.0 2.0 8.0 1.0 ; 4.0 5.0 6.0 2.0 ; 9.0 7.0 8.0 3.0 ; 5.0 2.0 8.0 4.0 ]
testfloat = [ 3.0 2.0 8.0 1.0 ; 4.0 5.0 6.0 2.0 ; 9.0 7.0 8.0 3.0 ; 5.0 2.0 8.0 4.0 ]
r=normalizeQuantiles(testfloat)
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

testfloat = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
check = [ 2.0 3.0 2.0 ; 4.0 6.0 4.0 ; 8.0 8.0 7.0 ; 6.0 3.0 7.0 ]
qn = normalizeQuantiles(testfloat)
@test qn == check

testint = [ 1 1 1 ; 1 1 1 ; 1 1 1 ]
qn = normalizeQuantiles(testint)
@test qn == testint

dafloat=Array{Nullable{Float64}}(testfloat)
dafloat[2,2]=Nullable{Float64}()
srand(0);qn = normalizeQuantiles(dafloat)
@test isnull(qn[2,2])

dafloat[2,:]=Nullable{Float64}()
srand(0);qn = normalizeQuantiles(dafloat)
@test isnull(qn[2,1])
@test isnull(qn[2,2])
@test isnull(qn[2,3])

dafloat[3,1:2]=Nullable{Float64}()
srand(0);qn = normalizeQuantiles(dafloat)
@test isnull(qn[3,1])
@test isnull(qn[3,2])

dafloat[1,:]=Nullable{Float64}()
dafloat[2,:]=Nullable{Float64}()
dafloat[3,:]=Nullable{Float64}()
dafloat[4,:]=Nullable{Float64}()
srand(0);qn = normalizeQuantiles(dafloat)
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

testfloat = [ 3.5 2.0 8.1 1.0 ; 4.5 5.0 6.0 2.0 ; 9.0 7.6 8.2 3.0 ; 5.0 2.0 8.0 4.0 ]
dafloat=DataArray(testfloat)
r=normalizeQuantiles(dafloat)
@test mean(r[:,1]) >= 4.93124 && mean(r[:,1]) <= 4.93125
@test mean(r[:,2]) >= 4.93124 && mean(r[:,2]) <= 4.93125
@test mean(r[:,3]) >= 4.93124 && mean(r[:,3]) <= 4.93125
@test mean(r[:,4]) >= 4.93124 && mean(r[:,4]) <= 4.93125

testfloat = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
check = [ 2.0 3.0 2.0 ; 4.0 6.0 4.0 ; 8.0 8.0 7.0 ; 6.0 3.0 7.0 ]
qn = normalizeQuantiles(testfloat)
@test qn == check

testint = [ 1 1 1 ; 1 1 1 ; 1 1 1 ]
qn = normalizeQuantiles(testint)
@test qn == testint

dafloat = DataArray(testfloat)
dacheck = DataArray(check)
qn = normalizeQuantiles(dafloat)
@test qn == check

daint = DataArray(testint)
qn = normalizeQuantiles(daint)
@test qn == daint

dafloat[2,2]=NA
srand(0);qn = normalizeQuantiles(dafloat)
@test isa(qn[2,2],NAtype)

dafloat[2,:]=NA
srand(0);qn = normalizeQuantiles(dafloat)
@test isa(qn[2,1],NAtype)
@test isa(qn[2,2],NAtype)
@test isa(qn[2,3],NAtype)

dafloat[3,1:2]=NA
srand(0);qn = normalizeQuantiles(dafloat)
@test isa(qn[3,1],NAtype)
@test isa(qn[3,2],NAtype)

dafloat[1,:]=NA
dafloat[2,:]=NA
dafloat[3,:]=NA
dafloat[4,:]=NA
srand(0);qn = normalizeQuantiles(dafloat)
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



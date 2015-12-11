
using NormalizeQuantiles
using Base.Test

# write your own tests here
@test 1 == 1

testfloat = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
check = [ 6.5  5.0  3.5 ; 3.5  5.0  6.5 ; 6.5  3.5  5.0 ; 5.0  3.5  6.5 ]
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



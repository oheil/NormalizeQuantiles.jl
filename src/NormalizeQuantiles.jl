module NormalizeQuantiles

export normalizeQuantiles

export sampleRanks
export qnTiesMethods,tmMin,tmMax,tmOrder,tmReverse,tmRandom,tmAverage

using Distributed
using SharedArrays
using Random
using Statistics

@enum qnTiesMethods tmMin tmMax tmOrder tmReverse tmRandom tmAverage

function checkForNotANumber(x::Any)
    (!isa(x,Integer) && !isa(x,Real)) || isnan(x)
end

@doc "
### qnmatrix::Array{Float64} function normalizeQuantiles(matrix::AbstractArray)
Calculate the quantile normalized data for the input matrix

Parameter:
    matrix::AbstractArray
The input data as an array of values interpreted as matrix(rows,columns)

Return value: 
    qnmatrix::Array{Float64}
The quantile normalized data as Array{Float64}

Example:

    using NormalizeQuantiles

    array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
    qn = normalizeQuantiles(array)

    row = 2
    column = 2
    array=convert(Array{Any},array)
    array[row,column] = missing
    qn = normalizeQuantiles(array)
"
function normalizeQuantiles(matrix::AbstractArray)
    if ndims(matrix) > 2
        throw(ArgumentError("normalizeQuantiles expects an array of dimension 2"))
    end
    nrows=size(matrix,1)
    ncols=size(matrix,2)
    # preparing the result matrix
    qnmatrix=SharedArray{Float64}(nrows,ncols)
    if ncols>0 && nrows>0
        # foreach column: sort the values without NAs; put NAs (if any) back into sorted list
        NormalizeQuantiles.sortColumns!(matrix,qnmatrix)
        # foreach row: set all values to the mean of the row, except NAs
        NormalizeQuantiles.meanRows!(qnmatrix)
        # foreach column: equal values in original column should all be mean of normalized values
        # foreach column: reorder the values back to the original order
        NormalizeQuantiles.equalValuesInColumnAndOrderToOriginal!(matrix,qnmatrix,nrows)
    end
    convert(Array{Float64},qnmatrix)
end

function sortColumns!(matrix::AbstractArray,qnmatrix::SharedArray{Float64})
    tcol=1
    @inbounds @sync @distributed for scolumn in eachindex(matrix[end,:])
        sortcol=[ NormalizeQuantiles.checkForNotANumber(x) ? NaN : Float64(x) for x in matrix[:,scolumn] ]
        missingIndices=findall(isnan.(sortcol))
        sort!(sortcol)
        #putting original NaNs back into place:
        nMissPos=lastindex(missingIndices)
        delta=nMissPos
        index=lastindex(sortcol)
        while nMissPos>0
            missingPos=missingIndices[nMissPos]
            if index==missingPos
                sortcol[index]=NaN
                nMissPos-=1
                delta-=1
            else
                sortcol[index]=sortcol[index-delta]
            end
            index-=1
        end
        qnmatrix[:,tcol]=sortcol
        tcol+=1
    end
end

function meanRows!(qnmatrix::SharedArray{Float64})
    @inbounds @sync @distributed for srow = eachindex(qnmatrix[:,end])
        goodIndices=.!isnan.(qnmatrix[srow,:])
        rowView=view(qnmatrix,srow,goodIndices)      
        #rowmean=mean(rowView)
        #
        #in julia function sum the order of summing up the elements can vary on different
        #types of AbstractArray (e.g. qnmatrix[row,goodIndices] and rowView). Summing over
        #a large number of floats in different order yield different results because of 
        #floating point precision, so we calculate the sum in a well defined way:
        lrow=length(rowView)
        sum=0.0
        for i in eachindex(rowView)
            sum+=rowView[i]
        end
        rowmean=sum/lrow
        rowView.=rowmean
    end
end

function equalValuesInColumnAndOrderToOriginal!(matrix::AbstractArray,qnmatrix::SharedArray{Float64},nrows)
    tcol=1
    @inbounds @sync @distributed for scolumn in eachindex(matrix[end,:])
        goodIndices=.!isnan.(qnmatrix[:,tcol])
        #matrix can be an OffsetArray
        colview=view(matrix,collect(eachindex(matrix[:,scolumn]))[goodIndices],scolumn)
        sortp=sortperm(Float64.(colview))
        if length(sortp)>0
            NormalizeQuantiles.setMeanForEqualOrigValues!(colview[sortp],qnmatrix,tcol,goodIndices)
        end
        qnmatrix[(1:nrows)[goodIndices][sortp],tcol]=qnmatrix[goodIndices,tcol]
        tcol+=1
    end
end

function setMeanForEqualOrigValues!(sortedArrayNoNAs::AbstractArray,qnmatrix::SharedArray{Float64},column::Int,goodIndices)
    nrows=length(sortedArrayNoNAs)
    foundIndices=zeros(Int,nrows)
    goodIndices2=findall(goodIndices)
    count=1
    lastValue=sortedArrayNoNAs[1]
    for i in 2:nrows
        nextValue=sortedArrayNoNAs[i]
        foundIndices[count]=goodIndices2[i-1]
        if nextValue==lastValue
            count+=1
        else
            if count>1
                qnmatrix[foundIndices[1:count],column].=mean(qnmatrix[foundIndices[1:count],column])
                count=1
            end
        end
        lastValue=nextValue
    end
    foundIndices[count]=goodIndices2[nrows]
    if count>1
        qnmatrix[foundIndices[1:count],column].=mean(qnmatrix[foundIndices[1:count],column])
    end
end

@doc "
### (Array{Union{Missing,Int}},Dict{Int,Array{Int}}) sampleRanks(array::AbstractArray;tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)

Calculate ranks of the values of a given vector.

Parameters:

    array: the input array
    tiesMethod: the method how ties (equal values) are treated
       possible values: tmMin tmMax tmOrder tmReverse tmRandom tmAverage
       default is tmMin
    naIncreasesRank: if true than any NA increases the following ranks by 1
    resultMatrix: if true than return a dictionary of rank keys and array of indices values

Example:
    
    using NormalizeQuantiles
    
    a = [ 5.0 2.0 4.0 3.0 1.0 ]
    
    (r,m)=sampleRanks(a)

    (r,m)=sampleRanks(a,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
    
r is the vector of ranks.

m is a dictionary with rank as keys and as value the indices of all values of this rank.

"
function sampleRanks(array::AbstractArray;tiesMethod::qnTiesMethods=tmMin,naIncreasesRank::Bool=false,resultMatrix::Bool=false)
    nrows=length(array)
    naCounts=zeros(Int,nrows)
    goodIndices=falses(nrows)
    naCount=0
    reducedIndex=1
    goodIndex=1
    for arrayIndex in eachindex(array)
        if NormalizeQuantiles.checkForNotANumber(array[arrayIndex])
            naCount+=1
        else
            goodIndices[goodIndex]=true
            naCounts[reducedIndex]=naCount
            reducedIndex+=1
        end
        goodIndex+=1
    end
    reducedArraySorted=Float64.(array[goodIndices])
    reducedArraySortedIndices=sortperm(reducedArraySorted)
    reducedArraySorted=reducedArraySorted[reducedArraySortedIndices]
    result=Array{Union{Missing,Int}}(missing,nrows)
    rankMatrix=Dict{Int,Array{Int}}()
    group = Array{Int,1}()
    firstFound = true
    lastFound = NaN
    nextRank=1
    rankIncrement=0
    doIncreaseRank=false
    headingNA=false
    groupIndex=1
    offset=firstindex(array)-groupIndex
    for resultIndex in eachindex(array)
        if goodIndices[resultIndex]
            if headingNA
                headingNA=false
                if doIncreaseRank
                    nextRank+=rankIncrement
                    rankIncrement=0
                    doIncreaseRank=false
                end
            end
            reducedArrayIndex=reducedArraySortedIndices[groupIndex]
            if !firstFound && lastFound != reducedArraySorted[groupIndex]
                nextRank = NormalizeQuantiles.setRank!(group,nextRank,offset,tiesMethod,result,resultMatrix,rankMatrix)
                group = [naCounts[reducedArrayIndex]+reducedArrayIndex+offset]
                if doIncreaseRank
                    nextRank+=rankIncrement
                    rankIncrement=0
                    doIncreaseRank=false
                end
            else
                push!(group,naCounts[reducedArrayIndex]+reducedArrayIndex+offset)
            end
            lastFound = reducedArraySorted[groupIndex]
            firstFound = false
            groupIndex+=1
        else
            if naIncreasesRank
                doIncreaseRank=true
                rankIncrement+=1
            end
            if firstFound
                headingNA=true
            end
        end
    end
    NormalizeQuantiles.setRank!(group,nextRank,offset,tiesMethod,result,resultMatrix,rankMatrix)
    (result,rankMatrix)
end 

function setRank!(group::Array{Int},nextRank::Int,offset::Int,tiesMethod::qnTiesMethods,result::Array{Union{Missing,Int}},resultMatrix::Bool,rankMatrix::Dict{Int,Array{Int}})
    ranksCount=length(group)
    ranks=nextRank:(nextRank+ranksCount-1)
    if tiesMethod==tmMin
        minRank=minimum(ranks)
        result[group.-offset].=minRank
        if resultMatrix
            rankMatrix[minRank]=group
        end
        nextRank+=1
    elseif tiesMethod==tmMax
        maxRank=maximum(ranks)
        result[group.-offset].=maxRank
        if resultMatrix
            rankMatrix[maxRank]=group
        end
        nextRank=maxRank+1
    elseif tiesMethod==tmOrder
        maxRank=maximum(ranks)
        result[group.-offset]=ranks
        if resultMatrix
            for rankIndex in 1:length(ranks)
                rankMatrix[ranks[rankIndex]]=[group[rankIndex]]
            end
        end
        nextRank=maxRank+1
    elseif tiesMethod==tmReverse
        maxRank=maximum(ranks)
        ranks=reverse(ranks,dims=1)
        result[group.-offset]=ranks
        if resultMatrix
            for rankIndex in 1:length(ranks)
                rankMatrix[ranks[rankIndex]]=[group[rankIndex]]
            end
        end
        nextRank=maxRank+1
    elseif tiesMethod==tmRandom
        maxRank=maximum(ranks)
        ranks=ranks[randperm(ranksCount)]
        result[group.-offset]=ranks
        if resultMatrix
            for rankIndex in 1:length(ranks)
                rankMatrix[ranks[rankIndex]]=[group[rankIndex]]
            end
        end
        nextRank=maxRank+1
    elseif tiesMethod==tmAverage
        rankMean=round(Int,mean(ranks))
        result[group.-offset].=rankMean
        if resultMatrix
            rankMatrix[rankMean]=group
        end
        nextRank=rankMean+1
    end
    nextRank
end

end # module

module NormalizeQuantiles

export normalizeQuantiles

export sampleRanks
export qnTiesMethods,tmMin,tmMax,tmOrder,tmReverse,tmRandom,tmAverage

macro SharedArray(mytype,mysize)
	if VERSION >= v"0.6.0-"
		return :( SharedArray{$(esc(mytype))}($(esc(mysize))) )
	end # if VERSION >= v"0.6.0-"
	if VERSION >= v"0.4.0-"
		return :( SharedArray($(esc(mytype)),$(esc(mysize))) )
	end # if VERSION >= v"0.4.0-"
end

@enum qnTiesMethods tmMin tmMax tmOrder tmReverse tmRandom tmAverage

@doc "
### qnmatrix::Array{Float64} function normalizeQuantiles(matrix::Array{Float64})

Method for input type Array{Float64}
" ->
function normalizeQuantiles(matrix::Array{Float64})
    damatrix=Array{Nullable{Float64}}(matrix)
    r=normalizeQuantiles(damatrix)
	nan_indices=[ isnull(x) for x in vec(r) ]
	r[nan_indices]=NaN
	convert(Array{Float64},reshape([get(r[i]) for i=1:length(r)],size(r)))
end

@doc "
### qnmatrix::Array{Float64} function normalizeQuantiles(matrix::Array{Int})

Method for input type Array{Int}
" ->
function normalizeQuantiles(matrix::Array{Int})
    dafloat=Array{Nullable{Float64}}(convert(Array{Float64},matrix))
    r=normalizeQuantiles(dafloat)
	nan_indices=[ isnull(x) for x in vec(r) ]
	r[nan_indices]=NaN
	convert(Array{Float64},reshape([get(r[i]) for i=1:length(r)],size(r)))
end

@doc "
### qnmatrix::Array{Nullable{Float64}} function normalizeQuantiles(matrix::Array{Nullable{Int}})

Method for input type Array{Nullable{Int}}
" ->
function normalizeQuantiles(matrix::Array{Nullable{Int}})
    nullable=Array{Nullable{Float64}}(matrix)
    normalizeQuantiles(nullable)
end

@doc "
### qnmatrix::Array{Nullable{Float64}} function normalizeQuantiles(matrix::Array{Nullable{Float64}})
Calculate the quantile normalized data for the input matrix

Parameter:
    matrix::Array{Nullable{Float64}}
The input data as a Array{Nullable{Float64}} of float values interpreted as Array{Nullable{Float64}}(rows,columns)

Return value: 
    qnmatrix::Array{Nullable{Float64}}
The quantile normalized data as Array{Nullable{Float64}}

Examples:

    using NormalizeQuantiles

    array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]

    a = Array{Nullable{Float64}}(array)

    qn = normalizeQuantiles(a)


    column = 2

    row = 2

    a[row,column] = Nullable{Float64}()

    qn = normalizeQuantiles(a)

" ->
function normalizeQuantiles(matrix::Array{Nullable{Float64}})
	nan_indices=[ isnull(x) || isnan(get(x)) for x in vec(matrix) ]
	matrix[nan_indices]=Nullable{Float64}()
    nrows=size(matrix,1)
    ncols=size(matrix,2)
	# preparing the result matrix
    qnmatrix=Array{Nullable{Float64}}((nrows,ncols))
	if ncols>0 && nrows>0
		# foreach column: sort the values without NAs; put NAs (if any) back into sorted list
		sortColumns(matrix,qnmatrix,nrows,ncols)
		# foreach row: set all values to the mean of the row, except NAs
		meanRows(qnmatrix,nrows)
		# foreach column: equal values in original column should all be mean of normalized values
		# foreach column: reorder the values back to the original order
		equalValuesInColumnAndOrderToOriginal(matrix,qnmatrix,nrows,ncols)
	end
    qnmatrix
end

@doc "
### qnmatrix::SharedArray{Float64} function normalizeQuantiles(matrix::SharedArray{Float64})

Method for input type SharedArray{Float64}
" ->
function normalizeQuantiles(matrix::SharedArray{Float64})
    #nullable=SharedArray(Nullable{Float64},(size(matrix,1),size(matrix,2)))
	nullable=@SharedArray(Nullable{Float64},(size(matrix,1),size(matrix,2)))
	nullable[:]=matrix[:]
    r=normalizeQuantiles(nullable)
	#nullable=SharedArray(Nullable{Float64},(0,0))
	nullable=@SharedArray(Nullable{Float64},(0,0))
	#ra=SharedArray(Float64,(size(r,1),size(r,2)))
	ra=@SharedArray(Float64,(size(r,1),size(r,2)))
	ra[:]=convert(Array{Float64},reshape([get(r[i]) for i=1:length(r)],size(r)))[:]
	#r=SharedArray(Nullable{Float64},(0,0))
	r=@SharedArray(Nullable{Float64},(0,0))
	ra
end

@doc "
### qnmatrix::SharedArray{Float64} function normalizeQuantiles(matrix::SharedArray{Int})

Method for input type SharedArray{Int}
" ->
function normalizeQuantiles(matrix::SharedArray{Int})
    #nullable=SharedArray(Nullable{Float64},(size(matrix,1),size(matrix,2)))
	nullable=@SharedArray(Nullable{Float64},(size(matrix,1),size(matrix,2)))
	nullable[:]=[ Float64(x) for x in matrix ][:]
    r=normalizeQuantiles(nullable)
	#nullable=SharedArray(Nullable{Float64},(0,0))
	nullable=@SharedArray(Nullable{Float64},(0,0))
	#ra=SharedArray(Float64,(size(r,1),size(r,2)))
	ra=@SharedArray(Float64,(size(r,1),size(r,2)))
	ra[:]=convert(Array{Float64},reshape([get(r[i]) for i=1:length(r)],size(r)))[:]
	#r=SharedArray(Nullable{Float64},(0,0))
	r=@SharedArray(Nullable{Float64},(0,0))
	ra
end

@doc "
### qnmatrix::SharedArray{Nullable{Float64}} function normalizeQuantiles(matrix::SharedArray{Nullable{Int}})

Method for input type SharedArray{Int}
" ->
function normalizeQuantiles(matrix::SharedArray{Nullable{Int}})
	#nullable=SharedArray(Nullable{Float64},(size(matrix,1),size(matrix,2)))
	nullable=@SharedArray(Nullable{Float64},(size(matrix,1),size(matrix,2)))
	nullable[:]=matrix[:]
	normalizeQuantiles(nullable)
end

@doc "
### qnmatrix::SharedArray{Nullable{Float64}} function normalizeQuantiles(matrix::SharedArray{Nullable{Float64}})

Quantile normalization using multiple cores (see ?normalizeQuantiles)

Example:

	addprocs()
	
	using NormalizeQuantiles
	
    array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]

    a = Array{Nullable{Float64}}(array)
	
	sa = SharedArray{Nullable{Float64}}((size(a,1),size(a,2)))
		
	sa[:]=a[:]

    qn = normalizeQuantiles(sa)

" ->
function normalizeQuantiles(matrix::SharedArray{Nullable{Float64}})
	local nrows
	nan_indices=[ isnull(x) || isnan(get(x)) for x in vec(matrix) ]
	matrix[nan_indices]=Nullable{Float64}()
    nrows=size(matrix,1)
    ncols=size(matrix,2)
	# preparing the result matrix
    #qnmatrix=SharedArray(Nullable{Float64},(nrows,ncols))
	qnmatrix=@SharedArray(Nullable{Float64},(nrows,ncols))
	if ncols>0 && nrows>0
		# foreach column: sort the values without NAs; put NAs (if any) back into sorted list
		multicoreSortColumns(matrix,qnmatrix,nrows,ncols)
		# foreach row: set all values to the mean of the row, except NAs
		multicoreMeanRows(qnmatrix,nrows,ncols)
		# foreach column: equal values in original column should all be mean of normalized values
		# foreach column: reorder the values back to the original order
		multicoreEqualValuesInColumnAndOrderToOriginal(matrix,qnmatrix,nrows,ncols)
	end
    qnmatrix
end

function sortColumns(matrix::Array{Nullable{Float64}},qnmatrix::Array{Nullable{Float64}},nrows,ncols)
	for column = 1:ncols
		indices=[ !isnull(x) for x in vec(matrix[:,column]) ]
		sortcol=vec(matrix[:,column])[indices]
		sortcol=[Float64(get(x)) for x in sortcol]
		sort!(sortcol)
		sortcol=Array{Nullable{Float64}}(sortcol)
		#naindices=(1:nrows)[!indices]
		naindices=(1:nrows)[ convert(Array{Bool},reshape([!i for i in indices],size(indices))) ]
		empty=sum(indices)==0
		for napos in naindices
			if empty
				empty = false
				sortcol=Array{Nullable{Float64}}([Nullable{Float64}()])
			else
				sortcol=vcat(sortcol[1:napos-1],Nullable{Float64}(),sortcol[napos:end])
			end
		end
		qnmatrix[:,column]=sortcol
	end
end

function multicoreSortColumns(matrix::SharedArray{Nullable{Float64}},qnmatrix::SharedArray{Nullable{Float64}},nrows,ncols)
	@sync @parallel for column = 1:ncols
		indices=[ !isnull(x) for x in vec(matrix[:,column]) ]
		sortcol=vec(matrix[:,column])[indices]
		sortcol=[Float64(get(x)) for x in sortcol]
		sort!(sortcol)
		sortcol=Array{Nullable{Float64}}(sortcol)
		#naindices=(1:nrows)[!indices]
		naindices=(1:nrows)[ convert(Array{Bool},reshape([!i for i in indices],size(indices))) ]
		empty=sum(indices)==0
		for napos in naindices
			if empty
				empty = false
				sortcol=Array{Nullable{Float64}}([Nullable{Float64}()])
			else
				sortcol=vcat(sortcol[1:napos-1],Nullable{Float64}(),sortcol[napos:end])
			end
		end
		qnmatrix[:,column]=sortcol
	end
end

function meanRows(qnmatrix::Array{Nullable{Float64}},nrows)
	for row = 1:nrows
		indices=[ !isnull(x) for x in qnmatrix[row,:] ]
		#nacount=sum(!indices)
		naindices=convert(Array{Bool},reshape([!i for i in indices],size(indices)))
		nacount=sum(naindices)
		rowmean=mean([Float64(get(x)) for x in qnmatrix[row,indices]])
		qnmatrix[row,:]=Nullable{Float64}(rowmean)
		#nacount>0?qnmatrix[row,!indices]=Nullable{Float64}():false
		nacount>0?qnmatrix[row,naindices]=Nullable{Float64}():false
	end
end

function multicoreMeanRows(qnmatrix::SharedArray{Nullable{Float64}},nrows,ncols)
	@sync @parallel for row = 1:nrows
		indices=[ !isnull(x) for x in qnmatrix[row,:] ]
		#nacount=sum(!indices)
		naindices=convert(Array{Bool},reshape([!i for i in indices],size(indices)))
		nacount=sum(naindices)
		rowmean=mean([Float64(get(x)) for x in qnmatrix[row,indices]])
		qnmatrix[row,:]=Nullable{Float64}(rowmean)
		nacount>0?qnmatrix[row,naindices]=Nullable{Float64}():false
	end
end

function equalValuesInColumn(matrix::Array{Nullable{Float64}},qnmatrix::Array{Nullable{Float64}},nrows,ncols)
	for column = 1:ncols
		indices=[ !isnull(x) for x in matrix[:,column] ]
		sortp=[ Float64(get(x)) for x in vec(matrix[:,column])[indices] ]
		sortp=sortperm(sortp)
		#nacount=sum(!indices)
		naindices=convert(Array{Bool},reshape([!i for i in indices],size(indices)))
		nacount=sum(naindices)
		sortcol=matrix[:,column][indices][sortp]
		ranks=Array(Int,(length(sortcol),1))
		if nacount < nrows
			ranks[1]=1
			lastrank=1
			lastvalue=sortcol[1]
			for i in 2:length(sortcol)
				nextvalue=sortcol[i]
				get(nextvalue)==get(lastvalue)?ranks[i]=ranks[i-1]:ranks[i]=ranks[i-1]+1
				lastrank=ranks[i]
				lastvalue=sortcol[i]
			end
			indices=1:nrows
			naindices=[ isnull(x) for x in qnmatrix[:,column] ]
			#indices=indices[!naindices]
			indices=indices[ convert(Array{Bool},reshape([!i for i in naindices],size(naindices))) ]
			for i in 1:lastrank
				values=i.==vec(ranks)
				qnmatrix[indices[values],column]=mean([ get(x) for x in qnmatrix[indices[values],column] ])
			end
		end
	end
end

function orderToOriginal(matrix::Array{Nullable{Float64}},qnmatrix::Array{Nullable{Float64}},nrows,ncols)
	for column = 1:ncols
		indices=[ !isnull(x) for x in vec(matrix[:,column]) ]
		sortp=[ Float64(get(x)) for x in vec(matrix[:,column])[indices] ]
		sortp=sortperm(sortp)
		indices2=[ !isnull(x) for x in vec(qnmatrix[:,column]) ]
		qncol=Array{Nullable{Float64}}(nrows,1)
		fill!(qncol,Nullable{Float64}())
		qncol[(1:nrows)[indices][sortp]]=vec(qnmatrix[(1:nrows)[indices2],column])
		qnmatrix[:,column]=qncol
	end
end

function multicoreEqualValuesInColumnAndOrderToOriginal(matrix::SharedArray{Nullable{Float64}},qnmatrix::SharedArray{Nullable{Float64}},nrows,ncols)
	@sync @parallel for column = 1:ncols
		indices=[ !isnull(x) for x in vec(matrix[:,column]) ]
		sortp=[ Float64(get(x)) for x in vec(matrix[:,column])[indices] ]
		sortp=sortperm(sortp)
		indices2=[ !isnull(x) for x in vec(qnmatrix[:,column]) ]
		if length(matrix[:,column][indices][sortp])>0
			allranks=Dict{Int,Array{Int}}()
			sizehint!(allranks,nrows)
			rankColumns=getRankMatrix(matrix[:,column][indices][sortp],allranks,indices)
			for i in 1:rankColumns
				rankIndices=unique(allranks[i])
				qnmatrix[rankIndices,column]=mean([ get(x) for x in qnmatrix[rankIndices,column] ])
			end
		end
		qncol=Array{Nullable{Float64}}(nrows,1)
		fill!(qncol,Nullable{Float64}())
		qncol[(1:nrows)[indices][sortp]]=vec(qnmatrix[(1:nrows)[indices2],column])
		qnmatrix[:,column]=qncol
	end
end

function equalValuesInColumnAndOrderToOriginal(matrix::Array{Nullable{Float64}},qnmatrix::Array{Nullable{Float64}},nrows,ncols)
	for column = 1:ncols
		indices=[ !isnull(x) for x in vec(matrix[:,column]) ]
		sortp=[ Float64(get(x)) for x in vec(matrix[:,column])[indices] ]
		sortp=sortperm(sortp)
		indices2=[ !isnull(x) for x in vec(qnmatrix[:,column]) ]
		if length(matrix[:,column][indices][sortp])>0
			allranks=Dict{Int,Array{Int}}()
			sizehint!(allranks,nrows)
			rankColumns=getRankMatrix(matrix[:,column][indices][sortp],allranks,indices)
			for i in 1:rankColumns
				rankIndices=unique(allranks[i])
				qnmatrix[rankIndices,column]=mean([ get(x) for x in qnmatrix[rankIndices,column] ])
			end
		end
		qncol=Array{Nullable{Float64}}(nrows,1)
		fill!(qncol,Nullable{Float64}())
		qncol[(1:nrows)[indices][sortp]]=vec(qnmatrix[(1:nrows)[indices2],column])
		qnmatrix[:,column]=qncol
	end
end

function getRankMatrix(sortedArrayNoNAs::Array{Nullable{Float64}},allranks::Dict{Int,Array{Int}},indices::Array{Bool})
	rankColumns=0
	nrows=length(sortedArrayNoNAs)
	lastvalue=sortedArrayNoNAs[1]
	indices2=(1:length(indices))[indices]
	count=1
	for i in 2:nrows
		nextvalue=sortedArrayNoNAs[i]
		if !isnull(nextvalue) && !isnull(lastvalue) && get(nextvalue)==get(lastvalue)
			if haskey(allranks,rankColumns+1)
				allranks[rankColumns+1]=vcat(allranks[rankColumns+1],Array{Int}([indices2[i-1],indices2[i]]))
			else
				allranks[rankColumns+1]=Array{Int}([indices2[i-1],indices2[i]])
			end
			count+=1
		else
			if count>1
				rankColumns+=1
			end
			count=1
		end
		lastvalue=sortedArrayNoNAs[i]
	end
	if count>1
		rankColumns+=1
	end
	rankColumns
end

@doc "
### (Array{Int},Dict{Int,Array{Int}}) sampleRanks(array::Array{Int};tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)

" ->
function sampleRanks(array::Array{Int};tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)
	nullable=Array{Nullable{Float64}}(Array{Float64}(array))
	(rn,m)=sampleRanks(nullable,tiesMethod=tiesMethod,naIncreasesRank=naIncreasesRank,resultMatrix=resultMatrix)
	r=convert(Array{Int},reshape([get(rn[i]) for i=1:length(rn)],size(rn)))
	(r,m)
end

@doc "
### (Array{Int},Dict{Int,Array{Int}}) sampleRanks(array::Array{Float64};tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)

" ->
function sampleRanks(array::Array{Float64};tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)
	nullable=Array{Nullable{Float64}}(array)
	(rn,m)=sampleRanks(nullable,tiesMethod=tiesMethod,naIncreasesRank=naIncreasesRank,resultMatrix=resultMatrix)
	r=convert(Array{Int},reshape([get(rn[i]) for i=1:length(rn)],size(rn)))
	(r,m)
end

@doc "
### (Array{Nullable{Int}},Dict{Int,Array{Int}}) sampleRanks(array::Array{Nullable{Int}};tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)

" ->
function sampleRanks(array::Array{Nullable{Int}};tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)
	nullable=Array{Nullable{Float64}}(array)
	sampleRanks(nullable,tiesMethod=tiesMethod,naIncreasesRank=naIncreasesRank,resultMatrix=resultMatrix)
end

@doc "
### (Array{Nullable{Int}},Dict{Int,Array{Int}}) sampleRanks(array::Array{Nullable{Float64}};tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)

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
	
	n = Array{Nullable{Float64}}(a)

    (r,m)=sampleRanks(n)

    (r,m)=sampleRanks(n,tiesMethod=tmMin,naIncreasesRank=false,resultMatrix=true)
	
r is the vector of ranks.

m is a dictionary with rank as keys and as value the indices of all values of this rank.

" ->
function sampleRanks(array::Array{Nullable{Float64}};tiesMethod::qnTiesMethods=tmMin,naIncreasesRank=false,resultMatrix=false)
	nan_indices=[ isnull(x) || isnan(get(x)) for x in vec(array) ]
	array[nan_indices]=Nullable{Float64}()
	nrows=length(array)
	indices=[ !isnull(x) for x in array ]
	reducedArray=[ Float64(get(x)) for x in array[indices] ]
	sortp=sortperm(reducedArray)
	result=Array{Nullable{Int}}(nrows)
	result[:]=Nullable{Int}()
	#resultMatrix?begin rankMatrix=Dict{Int,Array{Int}}();sizehint!(rankMatrix,nrows) end:rankMatrix=nothing
	rankMatrix=Dict{Int,Array{Int}}()
	if resultMatrix
		sizehint!(rankMatrix,nrows)
	end	
	#indices2=(1:nrows)[indices][sortp]
	indices2=reshape((1:nrows),(1,nrows))[indices[:]][sortp]
	rank=1
	narank=0
	lastvalue=reducedArray[sortp[1]]
	ties=Array{Int}(0)
	tieIndices=Array{Int}(0)
	tiesCount=0
	index=1
	for i in 1:(nrows+1)
		last=i>nrows
		if !last 
			newvalue=reducedArray[sortp[index]]
		end
		if !last && !indices[i]
			if naIncreasesRank
				rank+=1
				tiesCount>0?narank+=1:false
			end
		else
			if last || newvalue != lastvalue
				if tiesMethod==tmMin
					ties[:]=minimum(ties)
					rank=ties[end]+narank+1
				elseif tiesMethod==tmMax
					ties[:]=maximum(ties)
					rank=ties[end]+narank+1
				elseif tiesMethod==tmReverse
					ties=flipdim(ties,1)
					rank=ties[1]+narank+1
				elseif tiesMethod==tmRandom
					rank=ties[end]+narank+1
					ties=ties[randperm(tiesCount)]
				elseif tiesMethod==tmAverage
					ties[:]=round(Int,mean(ties))
					rank=ties[end]+narank+1
				end
				narank=0
				for j in 1:tiesCount
					if resultMatrix
						if haskey(rankMatrix,ties[j])
							rankMatrix[ties[j]]=vcat(rankMatrix[ties[j]],tieIndices[j])
						else
							rankMatrix[ties[j]]=Array{Int}([tieIndices[j]])
						end
					end
					result[tieIndices[j]]=ties[j]
				end
				ties=Array{Int}(0)
				tieIndices=Array{Int}(0)
				tiesCount=0
			end
			if !last
				tieIndices=vcat(tieIndices,Array{Int}([indices2[index]]))
				ties=vcat(ties,Array{Int}([rank]))
				tiesCount+=1
				rank+=1
				lastvalue=newvalue
				index+=1
			end
		end
	end
	(result,rankMatrix)
end

end # module

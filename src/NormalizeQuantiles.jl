module NormalizeQuantiles

export normalizeQuantiles

using DataArrays

if isa(1.0,Float64)
	"Float is a type alias to Float64"
	typealias Float Float64
else
	"Float is a type alias to Float32"
	typealias Float Float32
end

"""
### qnmatrix::DataArray{Float} function normalizeQuantiles(matrix::Array{Float})

Method for input type Array{Float}
"""
function normalizeQuantiles(matrix::Array{Float})
    damatrix=DataArray(matrix)
    normalizeQuantiles(damatrix)
end

"""
### qnmatrix::DataArray{Float} function normalizeQuantiles(matrix::Array{Int})

Method for input type Array{Int}
"""
function normalizeQuantiles(matrix::Array{Int})
    dafloat=DataArray(convert(Array{Float},matrix))
    normalizeQuantiles(dafloat)
end

"""
### qnmatrix::DataArray{Float} function normalizeQuantiles(matrix::DataArray{Int})

Method for input type DataArray{Int}
"""
function normalizeQuantiles(matrix::DataArray{Int})
    dafloat=convert(DataArray{Float},matrix)
    normalizeQuantiles(dafloat)
end

"""
### qnmatrix::DataArray{Float} function normalizeQuantiles(matrix::DataArray{Float})
Calculate the quantile normalized data for the input matrix

Parameter:
    matrix::DataArray{Float}
The input data as a DataArray of float values interpreted as DataArray(columns,rows)

Return value: 
    qnmatrix::DataArray{Float}
The quantile normalized data as DataArray{Float} 

Type Float:
	Float is a type alias to Float64 or Float32

Examples:

    using NormalizeQuantiles

    using DataArrays  

    array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]

    da = DataArray(array)

    qn = normalizeQuantiles(da)


    column = 2

    row = 2

    da[column,row] = NA

    qn = normalizeQuantiles(da)

"""
function normalizeQuantiles(matrix::DataArray{Float})
    ncols=size(matrix,1)
    nrows=size(matrix,2)
	# preparing the result matrix
    qnmatrix=DataArray(Float,(ncols,nrows))
	if ncols>0 && nrows>0
		# foreach column: sort the values without NAs; randomly distribute NAs (if any) into sorted list
		for column = 1:ncols
			sortp=sortperm(vec(matrix[column,:]))
			naindices=[ isa(x,NAtype) for x in matrix[column,:][sortp] ]
			nacount=sum(naindices)
			sortcol=matrix[column,:][sortp[!naindices]]
			for n = 1:nacount
				lcol=length(sortcol)
				if lcol==0
					napos=1
					sortcol=DataArray([1.0])
				else
					napos=rand(1:(lcol+1))
					sortcol=vcat(sortcol[1:napos-1],1.0,sortcol[napos:lcol])
				end
				sortcol[napos]=NA
			end
			qnmatrix[column,:]=sortcol
		end
		# foreach row: set all values to the mean of the row, except NAs
		for row = 1:nrows
			naindices=[ isa(x,NAtype) for x in qnmatrix[:,row] ]
			nacount=sum(naindices)
			qnmatrix[:,row]=mean(qnmatrix[!naindices,row])
			nacount>0?qnmatrix[naindices,row]=NA:false
		end
		# foreach column: reorder the values back to the original order
		for column = 1:ncols
			sortp=sortperm(vec(matrix[column,:]))
			naindices=[ isa(x,NAtype) for x in matrix[column,:][sortp] ]
			naindices2=[ isa(x,NAtype) for x in qnmatrix[column,:] ]
			nacount=sum(naindices)
			qncol=qnmatrix[column,:]
			for i in 1:length(sortp[!naindices])
				qncol[sortp[!naindices][i]]=qnmatrix[column,:][:,!naindices2][i]
			end
			for i in 1:length(sortp[naindices])
				qncol[sortp[naindices][i]]=NA
			end
			qnmatrix[column,:]=qncol
		end
	end
    qnmatrix
end

end # module

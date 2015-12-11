module NormalizeQuantiles

export normalizeQuantiles

using DataArrays

if isa(1.0,Float64)
	typealias Float Float64
else
	typealias Float Float32
end

function normalizeQuantiles(matrix::Array{Float})
    damatrix=DataArray(matrix)
    normalizeQuantiles(damatrix)
end

function normalizeQuantiles(matrix::Array{Int})
    dafloat=DataArray(convert(Array{Float},matrix))
    normalizeQuantiles(dafloat)
end

function normalizeQuantiles(matrix::DataArray{Int})
    dafloat=convert(DataArray{Float},matrix)
    normalizeQuantiles(dafloat)
end

#' @description
#' calculate the quantile normalized data for the input matrix
#'
#' @param matrix::DataArray{Float} The input data as a DataArray of float values interpreted as DataArray(columns,rows)
#'
#' @returns qnmatrix::DataArray{Float}  The quantile normalized data as DataArray{Float} 
#'
#' @examples
#'
#' using NormalizeQuantiles
#' using DataArrays
#' 
#' array = [ 3.0 2.0 1.0 ; 4.0 5.0 6.0 ; 9.0 7.0 8.0 ; 5.0 2.0 8.0 ]
#' da = DataArray(array)
#' qn = normalizeQuantiles(da)
#' 
#' column = 2
#' row = 2
#' da[column,row] = NA
#' qn = normalizeQuantiles(da)
#' 
function normalizeQuantiles(matrix::DataArray{Float})
    ncols=size(matrix,1)
    nrows=size(matrix,2)
    qnmatrix=DataArray(Float,(ncols,nrows))
    for column = 1:ncols
        sortp=sortperm(vec(matrix[column,:]))
        naindices=[ isa(x,NAtype) for x in matrix[column,sortp] ]
        nacount=length(matrix[column,naindices])
        sortcol=matrix[column,sortp[!naindices]]
        for n = 1:nacount
            lcol=length(sortcol)
            if lcol==0
                napos=1
                sortcol=DataArray([1.0])
            else
                napos=rand(1:(lcol+1))
                sortcol=DataArray(vcat(sortcol[1:napos-1],1.0,sortcol[napos:lcol]))
            end
            sortcol[napos]=NA
        end
        qnmatrix[column,:]=sortcol
    end
    for row = 1:nrows
        naindices=[ isa(x,NAtype) for x in qnmatrix[:,row] ]
        qnmatrix[:,row]=mean(qnmatrix[!naindices,row])
        qnmatrix[naindices,row]=NA
    end
    for column = 1:ncols
        sortp=sortperm(vec(matrix[column,:]))
        naindices=[ isa(x,NAtype) for x in matrix[column,sortp] ]
        qnnaindices=[ isa(x,NAtype) for x in qnmatrix[column,:] ]
        qnmatrix[column,sortp[!naindices]]=qnmatrix[column,!qnnaindices]
        qnmatrix[column,sortp[naindices]]=NA
    end
    qnmatrix
end

end # module

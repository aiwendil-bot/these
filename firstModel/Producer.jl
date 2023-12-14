using Geodesy, DelimitedFiles
include("Client.jl")

struct Producer
    name::String
    coordinates::LatLon{Float64}
    timeWindows::Vector{Vector{Int64}}
    capacity::Number #struct Vehicle ? si flotte hétérogène
    numberOfProducts::Int64
end

function producerFromClientCSV

end
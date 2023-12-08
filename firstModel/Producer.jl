using Geodesy
include("Client.jl")

struct Producer
    coordinates::LatLon
    clients::Vector{Client}
    timeWindows::Vector{Vector{Int64}}
    capacity::Number #struct Vehicle ? si flotte hétérogène
    numberOfProducts::Int64
end

function initializeProducer()::Producer

end
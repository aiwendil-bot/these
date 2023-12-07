using Geodesy, Client, timeWindows

struct Producer
    coordinates::LatLon
    clients::Vector{Client}
    timeWindows::Vector{Vector{Float16}}
    capacity::Number #struct Vehicle ? si flotte hétérogène
end

function initializeProducer()::Producer

end
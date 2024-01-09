struct Producer
    name::String
    coordinates::LatLon{Float64}
    timeWindows::Vector{Vector{Int64}}
    capacity::Number #struct Vehicle ? si flotte hétérogène
    numberOfProducts::Int64
end

struct Client
    coordinates::LatLon{Float64}
    demands::Vector{Float16}
    timeWindows::Vector{Vector{Int64}}
end


struct Producer_mutualisation
    name::String
    coordinates::LatLon{Float64}
    timeWindows::Vector{Int64}
    capacity::Int64 #struct Vehicle ? si flotte hétérogène
end

struct Client_mutualisation
    producers::Vector{Producer_mutualisation}
    coordinates::LatLon{Float64}
    demands::Vector{Float16}
    timeWindows::Vector{Int64}
end

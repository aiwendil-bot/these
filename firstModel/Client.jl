struct Client
    coordinates::LatLon
    demands::Vector{Float16}
    timeWindows::Vector{Vector{Float16}}
end
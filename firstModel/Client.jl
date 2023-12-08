struct Client
    coordinates::LatLon
    demands::Vector{Float16}
    timeWindows::Vector{Vector{Int64}}
end
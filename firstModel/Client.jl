using DelimitedFiles, DataFrames, Geodesy, CSV

struct Client
    coordinates::LatLon{Float64}
    demands::Vector{Float16}
    timeWindows::Vector{Vector{Int64}}
end

function clientsFromCSV(input::String)::Vector{Client}

end


using CSV, DataFrames, Geodesy, Random, PyCall, StatsBase
include("Producer_mutualisation.jl")
include("..\\utils\\generateInstances\\generateRandomClients.jl")
include("modele_mutualisation_v1.jl")
include("..\\utils\\views\\visualizeRoutes.jl")
include("..\\utils\\conversions.jl")
include("Instance_mutualisation.jl")
include("..\\utils\\views\\affichagesTerminal\\terminal_mutualisation_v1.jl")
Random.seed!(1234)

function main()

    nbOfDays = 5
    capacityProducers::Int64 = 50
    nbOfProducers = 3
    nbOfClients = 5
    radiusMinInMeters = 3000
    radiusMaxInMeters = 25000
    maxOfWindows = 5

    colors = ["black", "blue","BlueViolet", "Brown", "Chocolate", "Crimson", "DarkBlue", "DarkGreen",
    "DarkMagenta", "DarkRed", "FireBrick", "Green", "Indigo", "Maroon", "MediumBlue", "MidnightBlue", "Navy",
    "Purple", "Sienna", "Red", "Gainsboro", "DarkOrchid", "DarkOrange", "DarkViolet"]

    colorsProducers = ["red", "darkblue", "darkgreen", "darkorange", "Purple"]

    defaultProducerTWs= [i for i in 1:10]
    producers_DF = DataFrame(CSV.File("data\\cleanProducers.csv"))
    #producers_indices = sample(1:nrow(producers_DF),nbOfProducers,replace=false)
    #producers_indices = [105, 101, 18, 5, 56]
    producers_indices = [105,101,18]
    producers = [Producer_mutualisation(
        producers_DF[p,1],
        LatLon(producers_DF[p,2],producers_DF[p,3]),
        defaultProducerTWs,
        capacityProducers
    ) for p in producers_indices]

    producersPerClient = [sample(producers,rand(1:nbOfProducers),replace=false) for c in 1:nbOfClients]

    clients = generateRandomClients_mutualisation(    
        producers,
        producersPerClient,
        [radiusMinInMeters, radiusMaxInMeters],
        nbOfClients, 
        maxOfWindows, 
        nbOfDays)

    instance = Instance_mutualisation(producers, clients, producersPerClient)

    coordinates = DataFrame(name=String[],latitude=Float64[], longitude=Float64[])

    for p in producers_indices
        push!(coordinates, (producers_DF[p,1],producers_DF[p,2],producers_DF[p,3]))
    end

    for c in eachindex(clients)
        push!(coordinates, ("client_$c",clients[c].coordinates.lat,clients[c].coordinates.lon))
    end

    pathCSV = "data\\mutualisation\\$(nbOfProducers)_producers_$(nbOfClients)_clients.csv"
    pathMap = "out\\mutualisation\\$(nbOfProducers)_producers_$(nbOfClients)_clients.html"
    
    CSV.write(pathCSV,  coordinates)

    for i in eachindex(clients)
        println("client_$i")
        for producer in producersPerClient[i]
            println("\t", producer.name)
        end
    end
    
    res = mutualisationModel(instance)

    displayMutualisation(instance.producers, instance.clients, producersPerClient, res)

    visualizeRoutes_mutualisation_v1(pathCSV, res, pathMap, colorsProducers)

end

main()
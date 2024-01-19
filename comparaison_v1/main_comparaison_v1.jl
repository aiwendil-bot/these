using CSV, DataFrames, Geodesy, Random, PyCall, StatsBase, Logging
include("..\\demi_journees_mutualisation\\Producer_mutualisation.jl")
include("..\\utils\\generateInstances\\generateRandomClients.jl")
include("..\\demi_journees_mutualisation\\modele_mutualisation_v1.jl")
include("..\\utils\\views\\visualizeRoutes.jl")
include("..\\utils\\conversions.jl")
include("..\\demi_journees_mutualisation\\Instance_mutualisation.jl")
include("..\\utils\\views\\affichagesTerminal\\terminal_mutualisation_v1.jl")
include("..\\firstModel_demi_journees\\Producer_demijournees.jl")
include("..\\firstModel_demi_journees\\MTCVRPMTW-demi-journées.jl")
include("..\\firstModel_demi_journees\\Instance_MTCVRPMTW_demi_journees.jl")
include("..\\utils\\views\\affichagesTerminal\\terminal_demi_journees.jl")
#Random.seed!(1234)

function main()

    nbOfDays = 5
    capacityProducers = 50
    nbOfProducers = 3
    nbOfClients = 5
    radiusMinInMeters = 3000
    radiusMaxInMeters = 25000
    maxOfWindows = 5
    #time_limit = 30.0

    colors = ["black", "blue","BlueViolet", "Brown", "Chocolate", "Crimson", "DarkBlue", "DarkGreen",
    "DarkMagenta", "DarkRed", "FireBrick", "Green", "Indigo", "Maroon", "MediumBlue", "MidnightBlue", "Navy",
    "Purple", "Sienna", "Red", "Gainsboro", "DarkOrchid", "DarkOrange", "DarkViolet"]

    colorsProducers = ["red", "darkblue", "darkgreen", "purple", "Purple"]

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
    
    instance_mutualisation = Instance_mutualisation(producers, clients, producersPerClient)
    clientsPerProducer = [[clients[c] for c in eachindex(instance_mutualisation.clients) if (producers[p] in producersPerClient[c])] for p in eachindex(instance_mutualisation.producers)]

    coordinates = DataFrame(name=String[],latitude=Float64[], longitude=Float64[])

    for p in producers_indices
        push!(coordinates, (producers_DF[p,1],producers_DF[p,2],producers_DF[p,3]))
    end

    for c in eachindex(clients)
        push!(coordinates, ("client_$c",clients[c].coordinates.lat,clients[c].coordinates.lon))
    end

    pathCSV = "data\\comparaison\\$(nbOfProducers)_producers_$(nbOfClients)_clients.csv"
    pathMap = "out\\comparaison\\$(nbOfProducers)_producers_$(nbOfClients)_clients_mutualise.html"
    
    CSV.write(pathCSV,  coordinates)

    for i in eachindex(clients)
        println("client_$i")
        for producer in producersPerClient[i]
            println("\t", producer.name, " demande : $(clients[i].demands[findfirst(x -> x.coordinates == producer.coordinates, producers)])")
        end
    end

    #individuel

    res_individuels = []
    files_individuels = Vector{String}(undef, length(producers_indices))
    instances_individuelles = []

    for p in eachindex(producers_indices)

        producer = Producer_demijournees(
            producers_DF[producers_indices[p],1],
            LatLon(producers_DF[producers_indices[p],2],producers_DF[producers_indices[p],3]),
            defaultProducerTWs,
            capacityProducers,
            1
        )

        clients_indiv = [Client_demijournee(
            client.coordinates,
            [client.demands[p]],
            client.timeWindows
        ) for client in clientsPerProducer[p]]

        instance_indiv = Instance_MTCVRPMTW_demi_journees(producer, clients_indiv)
        push!(instances_individuelles, instance_indiv)
        coordinates = DataFrame(name=String[],latitude=Float64[], longitude=Float64[])
        push!(coordinates, (producers_DF[producers_indices[p],1],producers_DF[producers_indices[p],2],producers_DF[producers_indices[p],3]))
        for i in eachindex(clients_indiv)
            push!(coordinates, ("client_$(findfirst(x-> x.coordinates == clients_indiv[i].coordinates, clients))",clients_indiv[i].coordinates.lat,clients_indiv[i].coordinates.lon))
        end
    
        CSV.write("data\\comparaison\\$(producer.name)_$(length(clients_indiv))_clients_demi_journées.csv",  coordinates)
        @info "resolution de l'instance $(producers_DF[producers_indices[p],1]) ..."
        time1 = time()
        res_v2 = MTCVRPMTW_v2(instance_indiv)
        time2 = time()
        @info "instance résolue en $(round(time2 - time1,digits=2)) secondes"
        push!(res_individuels,res_v2)
        files_individuels[p] = "data\\comparaison\\$(producer.name)_$(length(clients_indiv))_clients_demi_journées.csv"
    end
    
    visualizeRoutes_individuel(instance_mutualisation, pathCSV, files_individuels, res_individuels, "out\\comparaison\\$(nbOfProducers)_producers_$(nbOfClients)_clients_indiv.html", colorsProducers)

    #mutualisation
    @info "resolution de l'instance mutualisée ..."
    res_mutualisation = mutualisationModel(instance_mutualisation)

    visualizeRoutes_mutualisation_v1(pathCSV, res_mutualisation, pathMap, colorsProducers)

    for p in 1:nbOfProducers
        current_coordinates = DataFrame(CSV.File(files_individuels[p], delim=','))
        current_clients = current_coordinates[2:nrow(current_coordinates),1]
        displayDemiJournees_v2(current_clients,instances_individuelles[p].clients, res_individuels[p])
    end
    displayMutualisation(instance_mutualisation.producers, instance_mutualisation.clients, producersPerClient, res_mutualisation)
    println("\n","distances parcourues : \n")
    println("organisation individuelle : ", sum([res_individuels[p][2] for p in 1:nbOfProducers]))
    println("avec mutualisation : ", res_mutualisation[2])

end

main()
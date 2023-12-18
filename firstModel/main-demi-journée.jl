using CSV, DataFrames, Geodesy, Random, PyCall
include("Producer_demijournees.jl")
include("Instance_MTCVRPMTW.jl")
include("..\\data\\generateRandomClients.jl")
include("MTCVRPMTW-demi-journées.jl")
include("..\\views\\visualizeRoutes.jl")
include("utils.jl")
include("Instance_MTCVRPMTW_variant.jl")
include("..\\views\\affichagesTerminal\\terminal_demi_journees.jl")
Random.seed!(1234)

function main()

    nbOfDays = 5
    capacityProducer = 50
    nbOfProducts = 5
    radiusMinInMeters = 20000
    radiusMaxInMeters = 25000
    nbOfClients = 5
    maxOfWindows = 3

    colors = ["black", "blue","BlueViolet", "Brown", "Chocolate", "Crimson", "DarkBlue", "DarkGreen",
    "DarkMagenta", "DarkRed", "FireBrick", "Green", "Indigo", "Maroon", "MediumBlue", "MidnightBlue", "Navy",
    "Purple", "Sienna", "Red", "Gainsboro", "DarkOrchid", "DarkOrange", "DarkSlateGray", "DarkViolet"]

    defaultProducerTWs= [i for i in 1:10] #journées entières 8-18h
    producers = DataFrame(CSV.File("data\\cleanProducers.csv"))
    producer = Producer_demijournees(
        producers[3,1],
        LatLon(producers[3,2],producers[3,3]),
        defaultProducerTWs,
        capacityProducer,
        nbOfProducts
    )

    clients = generateRandomClients_demijournees(    
        producer,
        [radiusMinInMeters, radiusMaxInMeters],
        nbOfClients, 
        maxOfWindows, 
        nbOfDays)

    instance = Instance_MTCVRPMTW_demi_journees(producer, clients)

    coordinates = DataFrame(name=String[],latitude=Float64[], longitude=Float64[])
    push!(coordinates, (producers[3,1],producers[3,2],producers[3,3]))
    for i in eachindex(clients)
        push!(coordinates, ("client_$i",clients[i].coordinates.lat,clients[i].coordinates.lon))
    end
    
    CSV.write("data\\$(producer.name)_$(nbOfClients)_clients_demi_journées.csv",  coordinates)

    res = MTCVRPMTW(instance)

    displayDemiJournees(instance.clients, res)

    visualizeRoutes_demijournees("data\\$(producer.name)_$(nbOfClients)_clients_demi_journées.csv", res, "views\\$(producer.name)_$(nbOfClients)_clients_demi_journées.html", colors)

end

main()
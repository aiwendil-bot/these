using CSV, DataFrames, Geodesy, Random, PyCall
include("Producer_demijournees.jl")
include("..\\utils\\generateInstances\\generateRandomClients.jl")
include("MTCVRPMTW-demi-journées.jl")
include("..\\utils\\views\\visualizeRoutes.jl")
include("..\\utils\\conversions.jl")
include("Instance_MTCVRPMTW_demi_journees.jl")
include("..\\utils\\views\\affichagesTerminal\\terminal_demi_journees.jl")
#Random.seed!(1234)

function main()

    nbOfDays = 5
    capacityProducer = 50
    nbOfProducts = 5
    radiusMinInMeters = 3000
    radiusMaxInMeters = 25000
    nbOfClients = 5
    maxOfWindows = 5

    colors = ["black", "blue","BlueViolet", "Brown", "Chocolate", "Crimson", "DarkBlue", "DarkGreen",
    "DarkMagenta", "DarkRed", "FireBrick", "Green", "Indigo", "Maroon", "MediumBlue", "MidnightBlue", "Navy",
    "Purple", "Sienna", "Red", "Gainsboro", "DarkOrchid", "DarkOrange", "DarkViolet"]

    colorsWeek = ["violet","darkviolet", "dodgerblue", "darkblue", "limegreen", "darkgreen", "orange", "darkorange", "red", "firebrick"]

    defaultProducerTWs= [i for i in 1:10]
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
    res_v2 = MTCVRPMTW_v2(instance)

    displayDemiJournees_v2(instance.clients, res_v2)

    visualizeRoutes_demijournees("data\\$(producer.name)_$(nbOfClients)_clients_demi_journées.csv", res_v2, "out\\firstModel_demi_journees\\$(producer.name)_$(nbOfClients)_clients_demi_journées_v2.html", colorsWeek)

end

main()
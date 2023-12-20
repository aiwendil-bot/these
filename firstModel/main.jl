using CSV, DataFrames, Geodesy, Random, PyCall
include("Client.jl")
include("Producer.jl")
include("Instance_MTCVRPMTW.jl")
include("..\\data\\generateRandomClients.jl")
include("MTCVRPMTW.jl")
include("..\\views\\visualizeRoutes.jl")
include("utils.jl")
include("..\\views\\affichagesTerminal\\terminal_timewindows.jl")

Random.seed!(1234)

function main()

    nbOfDays = 5
    capacityProducer = 50
    nbOfProducts = 5
    radiusMinInMeters = 2000
    radiusMaxInMeters = 10000
    nbOfClients = 7
    sizeOfWindows = 120
    maxOfWindows = 3

    colors = ["black", "blue","BlueViolet", "Brown", "Chocolate", "Crimson", "DarkBlue", "DarkGreen",
    "DarkMagenta", "DarkRed", "FireBrick", "Green", "Indigo", "Maroon", "MediumBlue", "MidnightBlue", "Navy",
    "Purple", "Sienna", "Red", "Gainsboro", "DarkOrchid", "DarkOrange", "DarkViolet"]

    defaultProducerTWs= [[j*24*60+8*60,j*24*60+18*60] for j in 0:nbOfDays] #journées entières 8-18h
    producers = DataFrame(CSV.File("data\\cleanProducers.csv"))
    producer = Producer(
        producers[3,1],
        LatLon(producers[3,2],producers[3,3]),
        defaultProducerTWs,
        capacityProducer,
        nbOfProducts
    )

    clients = generateRandomClients(    
        producer,
        [radiusMinInMeters, radiusMaxInMeters],
        nbOfClients,
        sizeOfWindows, 
        maxOfWindows, 
        nbOfDays)

    instance = Instance_MTCVRPMTW(producer, clients, sizeOfWindows)

    coordinates = DataFrame(name=String[],latitude=Float64[], longitude=Float64[])
    push!(coordinates, (producers[3,1],producers[3,2],producers[3,3]))
    for i in eachindex(clients)
        push!(coordinates, ("client_$i",clients[i].coordinates.lat,clients[i].coordinates.lon))
    end
    
    CSV.write("data\\$(producer.name)_$(nbOfClients)_clients.csv",  coordinates)

    res = MTCVRPMTW(instance)

    displayTimeWindows(instance, res, maxOfWindows)

    visualizeRoutes("data\\$(producer.name)_$(nbOfClients)_clients.csv", res, "views\\$(producer.name)_$(nbOfClients)_clients.html", colors)

end

main()
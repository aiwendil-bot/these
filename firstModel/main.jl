using CSV, DataFrames, Geodesy, Random, PyCall
include("Client.jl")
include("Producer.jl")
include("Instance_MTCVRPMTW.jl")
include("..\\data\\generateRandomClients.jl")
include("MTCVRPMTW.jl")
include("..\\views\\visualizeRoutes.jl")
include("utils.jl")

#Random.seed!(1234)

function main()

    nbOfDays = 5
    capacityProducer = 50
    nbOfProducts = 5
    radiusInMeters = 5000
    nbOfClients = 4
    sizeOfWindows = 120
    maxOfWindows = 3

    matplotlib = pyimport("matplotlib")
    colors_matplotlib = collect(keys(Dict{String,String}(matplotlib.colors.CSS4_COLORS)))
    colors = deleteat!(colors_matplotlib, findall(x->x in ["pink", "lightcoral", "beige", 
    "slategray","greenyellow","lightpink","ghostwhite","ivory","snow","lightgrey","lightgray","white","floralwhite",],colors_matplotlib))

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
        radiusInMeters,
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

    visualizeRoutes("data\\$(producer.name)_$(nbOfClients)_clients.csv", res, "views\\$(producer.name)_$(nbOfClients)_clients.html", colors)

end

main()
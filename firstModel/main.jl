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
    radiusMinInMeters = 2000
    radiusMaxInMeters = 10000
    nbOfClients = 5
    sizeOfWindows = 120
    maxOfWindows = 3

    matplotlib = pyimport("matplotlib")
    colors_matplotlib = collect(keys(Dict{String,String}(matplotlib.colors.CSS4_COLORS)))
    colors = deleteat!(colors_matplotlib, findall(x->x in ["pink", "lightcoral", "beige", 
    "slategray","greenyellow","lightpink","ghostwhite","ivory","snow","lightgrey","lightgray","white","floralwhite",],colors_matplotlib))

    colors = ["black", "blue","BlueViolet", "Brown", "Chocolate", "Crimson", "DarkBlue", "DarkGreen",
    "DarkMagenta", "DarkRed", "FireBrick", "Green", "Indigo", "Maroon", "MediumBlue", "MidnightBlue", "Navy",
    "Purple", "Sienna", "Red", "Gainsboro", "DarkOrchid", "DarkOrange", "DarkSlateGray", "DarkViolet"]

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

    visualizeRoutes("data\\$(producer.name)_$(nbOfClients)_clients.csv", res, "views\\$(producer.name)_$(nbOfClients)_clients.html", colors)

    println("capacité : $capacityProducer")
    println("taille des créneaux : $sizeOfWindows minutes")
    println("nombre max de créneaux pour un client : $maxOfWindows")
    times = [minutesToDayHourMinutes(trunc(Int64,sum(value.(res[5][i,:])))) for i in 1:nrow(coordinates)]
    x, y, w = res[2], res[3], res[5]
    tournees = [[i for i in axes(y, 1) if y[i,r] > 0.1 ] for r in axes(y, 2)]

    function fun(i,k,res)
        for j in tournees[k]
            if (i != j && i != size(y,1) && j != 1 && (i,j) != (1, size(y,1)))
                if (x[i,j,k] > 0.1)
                    return vcat([i], fun(j,k,res))
                end
            end
        end
        return res
    end

    tourneesRightOrder = [fun(1,r,[]) for r in axes(y,2)]
    toursProducer = [r for r in axes(y,2)]
    dayHoursMinutesProducer = [[minutesToDayHourMinutes(trunc(Int64,value(w[1,toursProducer[r]]))), minutesToDayHourMinutes(trunc(Int64,value(w[size(y,1),toursProducer[r]])+1)) ] for r in eachindex(toursProducer)]


    for t in eachindex(tourneesRightOrder)
        if (!isempty(tourneesRightOrder[t]))
            println("tournée n°$t :", join("client_$(c-1), " for c in tourneesRightOrder[t][2:end]), days[dayHoursMinutesProducer[t][1][1]], " "  ,"$(dayHoursMinutesProducer[t][1][2]):$(dayHoursMinutesProducer[t][1][3]) - $(dayHoursMinutesProducer[t][2][2]):$(dayHoursMinutesProducer[t][2][3])")
        end
    end

    for i in eachindex(clients)
        println("client_$i, demande totale : $(sum(clients[i].demands)), desservi le $(days[times[i+1][1]]), $(times[i+1][2]):$(times[i+1][3])")
        println("créneaux :")
        for tw in clients[i].timeWindows
            println("\t $(days[tw[1]]), $(tw[2]):$(tw[3]) - $(tw[2]+(sizeOfWindows÷60)):$(tw[3])")
        end
    end
end

main()
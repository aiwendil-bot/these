using PyCall, Random, DataFrames, CSV, StatsBase, Geodesy, DelimitedFiles, Distributions
include("..\\..\\firstModel\\Producer.jl")
include("..\\..\\firstModel_demi_journees\\Producer_demijournees.jl")

function generateRandomClients(   
    producer::Producer,
    radiusRange::Vector{Int64},
    nbOfGenerated::Int64,
    sizeOfWindows::Int64, 
    maxOfWindows::Int64, 
    nbOfDays::Int64)::Vector{Client}

    producerCoordinatesFloat = [producer.coordinates.lat, producer.coordinates.lon]

    coordinates::Vector{LatLon{Float64}} = generatePointsWithinRadius(producerCoordinatesFloat, radiusRange, nbOfGenerated)
    demands::Vector{Vector{Float64}} = generateDemands(producer.numberOfProducts, nbOfGenerated, producer.capacity)
    timeWindows::Vector{Vector{Vector{Int64}}} = generateTimeWindows(nbOfGenerated, sizeOfWindows, maxOfWindows, nbOfDays) 

    open("data\\$(producer.name)_$(nbOfGenerated)_clients.txt", "w") do f
        write(f, "$(producer.name), $(producer.numberOfProducts), $sizeOfWindows, $maxOfWindows, $nbOfDays \n")
        for i in 1:nbOfGenerated
            write(f,"$(coordinates[i]), $(demands[i]), $(timeWindows[i]) \n" )
        end
    end
    
    [Client(coordinates[i], demands[i], timeWindows[i]) for i in 1:nbOfGenerated]
    
end

function generateRandomClients_demijournees(  
    producer::Producer_demijournees,
    radiusRange::Vector{Int64},
    nbOfGenerated::Int64,
    maxOfWindows::Int64, 
    nbOfDays::Int64)::Vector{Client_demijournee}

    producerCoordinatesFloat = [producer.coordinates.lat, producer.coordinates.lon]

    coordinates::Vector{LatLon{Float64}} = generatePointsWithinRadius(producerCoordinatesFloat, radiusRange, nbOfGenerated)
    demands::Vector{Vector{Float64}} = generateDemands(producer.numberOfProducts, nbOfGenerated, producer.capacity)
    nbOfWindows = [rand(1:maxOfWindows) for i in 1:nbOfGenerated]
    timeWindows::Vector{Vector{Int64}} = [sort(sample(1:(nbOfDays*2),nbOfWindows[i],replace = false)) for i in 1:nbOfGenerated]
    
    [Client_demijournee(coordinates[i], demands[i], timeWindows[i]) for i in 1:nbOfGenerated]
    
end

function generatePointsWithinRadius(center::Vector{Float64}, radiusRange::Vector{Int64}, nbOfGenerated::Int64)::Vector{LatLon{Float64}}

    geodesic = pyimport("geopy.distance")
    res = Vector{LatLon{Float64}}(undef, nbOfGenerated)

    for i in 1:nbOfGenerated
        radius_in_kilometers = 0.001 .* radiusRange
        random_distance = rand(Uniform( radius_in_kilometers[1],radius_in_kilometers[2]))
        random_bearing = rand() * 360
        point = geodesic.distance(kilometers=random_distance).destination(center, random_bearing)
        res[i] = LatLon(point[1], point[2])
    end 

    return res
    
end

function generateDemands(nbOfProducts::Int64, nbOfGenerated, capacityMax::Int64)::Vector{Vector{Float64}}

    return [[rand() * capacityMax / nbOfProducts for j in 1:nbOfProducts] for i in 1:nbOfGenerated]
    
end

function generateTimeWindows(nbOfGenerated::Int64, sizeOfWindows::Int64, maxOfWindows, nbOfDays::Int64)::Vector{Vector{Vector{Int64}}}

    res = Vector{Vector{Vector{Int64}}}(undef, nbOfGenerated)

    for i in 1:nbOfGenerated

        nbOfWindows = rand(1:maxOfWindows)
        chosenDays = sample(0:(nbOfDays-1),nbOfWindows,replace=false)
        windows = Vector{Vector{Int64}}(undef, nbOfWindows)
        
        for j in 1:nbOfWindows

            chosenStartOfWindow = rand(8*60:(18*60-sizeOfWindows)) #début 8h et fin 18h
            hourStart, minuteStart = chosenStartOfWindow ÷ 60, chosenStartOfWindow % 60
            window = [chosenDays[j], hourStart, minuteStart]
            windows[j] = window
            
        end
        res[i] = windows
    end
    res
end

#=
producer = Producer(LatLon(47.347652435302734,0.6589514017105103),[[[600,1020]]],50,3)

generateRandomClients(producer,5000,20,120,3,5)
=#
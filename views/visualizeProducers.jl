using PyCall, DataFrames, CSV


function visualizeProducers(input::String, output::String)
    folium = pyimport("folium")
    m = folium.Map(location=[47.383333, 0.683333],
        zoom_start=11)

    coordinates = DataFrame(CSV.File(input, delim=','))
    for i in 1:nrow(coordinates)
        myloc = coordinates[i,:]
        popuptxt = string(i) * "\t" * myloc["nom"] * "\t" * string(myloc["latitude"]) *  "\t" * string(myloc["longitude"]) *  "\t"
        myicon= folium.CircleMarker(radius=5,color="blue",fill=true,location=[myloc["latitude"], myloc["longitude"]], popup=popuptxt).add_to(m)

    end
    m.save(output)
end

function visualizeProducerAndClient(input::String, res)
    folium = pyimport("folium")
    coordinates = DataFrame(CSV.File(input, delim=','))

    y, w = res[3], res[5]

    times = [minutesToDayHourMinutes(trunc(Int64,sum(value.(w[i,:])))) for i in 1:nrow(coordinates)]
    toursClients = [r for r in axes(y,2), i in 2:nrow(coordinates) if (y[i,r] > 0.1)]

    toursProducer = [r for r in axes(y,2) if (y[1,r] > 0.1)]

    stringTWsProducer = ["tour n°$(toursProducer[r]) : $(minutesToDayHourMinutes(trunc(Int64,value(w[1,toursProducer[r]])))) - $(minutesToDayHourMinutes(trunc(Int64,value(w[size(y,1),toursProducer[r]])+1))) \n" for r in eachindex(toursProducer)]

    days = Dict{Int64,String}(0 => "lundi", 1 => "mardi", 2 => "mercredi", 3 => "jeudi", 4 => "vendredi", 5 => "samedi", 6 => "dimanche")

    m = folium.Map(location=[coordinates[2,2],coordinates[2,3]],
        zoom_start=11)

    

    #PRODUCER

    myloc = coordinates[1,:]
    popuptxt = myloc["name"] * "\t" * string(myloc["latitude"]) *  "\t" * string(myloc["longitude"]) * join(stringTWsProducer)
    folium.Marker(location=[myloc["latitude"], myloc["longitude"]], popup=popuptxt,icon=folium.Icon(icon="seedling",color = "green",prefix = "fa"),).add_to(m)
    
    
    #CLIENTS

    for i in 2:nrow(coordinates)
        myloc = coordinates[i,:]
        popuptxt = myloc["name"] * "\t" * string(myloc["latitude"]) *  "\t" * string(myloc["longitude"]) *  "\t" * "tour n°$(toursClients[i-1]) " * "\t" *"$(days[times[i][1]]), $(times[i][2]):$(times[i][3])"
        folium.Marker(location=[myloc["latitude"], myloc["longitude"]], popup=popuptxt,icon=folium.Icon(icon="person", color = "blue",prefix="fa")).add_to(m)

    end
    m
end
using PyCall, DataFrames, CSV

function visualizeProducers(input::String, output::String)
    folium = pyimport("folium")
    m = folium.Map(location=[47.54589 1.15491],
        zoom_start=8)
 

    coordinates = DataFrame(CSV.File(input, delim=','))
    for i in 1:nrow(coordinates)
        myloc = coordinates[i,:]
        popuptxt = string(i) * "\t" * myloc["nom"] * "\t" * string(myloc["latitude"]) *  "\t" * string(myloc["longitude"]) *  "\t"
        folium.Marker(location=[myloc["latitude"], myloc["longitude"]], popup=popuptxt,icon=folium.Icon(icon="seedling",color = "green",prefix = "fa"),).add_to(m)
    end
    m.save(output)
end

function visualizeProducerAndClient(input::String, toursProducer, toursClients,w,times)
    folium = pyimport("folium")
    coordinates = DataFrame(CSV.File(input, delim=','))

    dayHoursMinutesProducer = [[minutesToDayHourMinutes(trunc(Int64,value(w[1,toursProducer[r]]))), minutesToDayHourMinutes(trunc(Int64,value(w[size(coordinates,1)+1,toursProducer[r]])+1)) ] for r in eachindex(toursProducer)]

    stringTWsProducer = ["tour n°$(toursProducer[r]) : $(days[dayHoursMinutesProducer[r][1][1]]), $(dayHoursMinutesProducer[r][1][2]):$(dayHoursMinutesProducer[r][1][3]) - $(dayHoursMinutesProducer[r][2][2]):$(dayHoursMinutesProducer[r][2][3]) \n" for r in eachindex(toursProducer)]

    m = folium.Map(location=[coordinates[1,2],coordinates[1,3]],
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


function visualizeProducerAndClient_demijournees(input::String, daysClients, toursClients, q)
    folium = pyimport("folium")
    coordinates = DataFrame(CSV.File(input, delim=','))

    m = folium.Map(location=[coordinates[1,2],coordinates[1,3]],
        zoom_start=11)
    #PRODUCER

    myloc = coordinates[1,:]
    popuptxt = myloc["name"] * "\t" * string(myloc["latitude"]) *  "\t" * string(myloc["longitude"]) 
    folium.Marker(location=[myloc["latitude"], myloc["longitude"]], popup=popuptxt,icon=folium.Icon(icon="seedling",color = "green",prefix = "fa"),).add_to(m)
    
    #CLIENTS

    for i in 2:nrow(coordinates)
        myloc = coordinates[i,:]
        popuptxt = myloc["name"] * "\t" * string(myloc["latitude"]) *  "\t" * string(myloc["longitude"]) *  "\t" * "tour n°$(toursClients[i-1])" * "\t" *daysStrings[daysClients[i-1]]
        folium.Marker(location=[myloc["latitude"], myloc["longitude"]], popup=popuptxt,icon=folium.Icon(icon="person", color = "blue",prefix="fa")).add_to(m)

    end
    m
end
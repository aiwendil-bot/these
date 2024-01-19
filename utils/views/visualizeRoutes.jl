using PyCall, StatsBase
include("visualizeProducers.jl")
include("..\\..\\firstModel\\MTCVRPMTW.jl")
include("..\\..\\firstModel_demi_journees\\MTCVRPMTW-demi-journées.jl")
include("..\\..\\demi_journees_mutualisation\\modele_mutualisation_v1.jl")

function visualizeRoutes(input::String, res, output::String, colors)

    coordinates = DataFrame(CSV.File(input, delim=','))
    corresp = vcat([i for i in 1:nrow(coordinates)],[1])
    instance, w, routes, toursProducer, toursClients,times = res[1], res[4], res[5], res[6],res[7],res[9]

    folium = pyimport("folium")

    m = visualizeProducerAndClient(input, toursProducer, toursClients, w, times)

    colors_sample = sample(colors,length(instance.clients),replace=false)

    for r in eachindex(routes)
        scpoints = vcat([(coordinates[corresp[1],2], coordinates[corresp[1],3])], [(coordinates[corresp[i],2], coordinates[corresp[i],3]) for i in routes[r]])
        folium.PolyLine(scpoints,color=colors_sample[r], weight=2.5, opacity=0.8).add_to(m)
    end

    m.save(output)
end

function visualizeRoutes_demijournees(input::String, res, output::String, colors)

    coordinates = DataFrame(CSV.File(input, delim=','))
    corresp = vcat([i for i in 1:nrow(coordinates)],[1])
    instance, demands, routes, days, toursClients,daysRoutes = res[1], res[4], res[5], res[6], res[7], res[10]

    folium = pyimport("folium")
    m = visualizeProducerAndClient_demijournees(input, days, toursClients, demands)

    for r in eachindex(routes)
        scpoints = vcat([(coordinates[corresp[1],2], coordinates[corresp[1],3])], [(coordinates[corresp[i],2], coordinates[corresp[i],3]) for i in routes[r]])
        folium.PolyLine(scpoints,color=colors[daysRoutes[r]], weight=2.5, opacity=0.8).add_to(m)
    end

    m.save(output)
end

function visualizeRoutes_mutualisation_v1(input::String, res, output::String, colors)

    coordinates = DataFrame(CSV.File(input, delim=','))
    instance, demands, routes, whoServedWhoAndWhen, daysRoutes = res[1], res[4], res[5], res[6], res[9]

    folium = pyimport("folium")
    m = visualizeProducerAndClient_mutualisation_v1(input, instance, whoServedWhoAndWhen, demands, colors)

    for p in eachindex(routes)
        if (!isempty(routes[p]))
            for r in eachindex(routes[p])
                scpoints = vcat([(coordinates[p,2], coordinates[p,3])], [(coordinates[i,2], coordinates[i,3]) for i in routes[p][r]])
                folium.PolyLine(scpoints,color=colors[p], weight=2.5, opacity=0.8).add_to(m)
            end
        end
    end

    m.save(output)
end

function visualizeRoutes_individuel(instance, input::String, files_individuels,
    res_individuels, output::String, colors)

    folium = pyimport("folium")

    nbOfProducers = length(instance.producers)
    coordinates = DataFrame(CSV.File(input, delim=','))

    lat_moyenne = sum([coordinates[i,2] for i in 1:nrow(coordinates)]) / nrow(coordinates)
    long_moyenne = sum([coordinates[i,3] for i in 1:nrow(coordinates)]) / nrow(coordinates)

    m = folium.Map(location=[lat_moyenne,long_moyenne],
        zoom_start=11)

    for p in 1:nbOfProducers
        myloc = coordinates[p,:]
        popuptxt = myloc["name"] * "\t" * string(myloc["latitude"]) *  "\t" * string(myloc["longitude"]) 
        folium.Marker(location=[myloc["latitude"], myloc["longitude"]], popup=popuptxt,icon=folium.Icon(icon="seedling",color = colors[p],prefix = "fa"),).add_to(m)
    end
    #CLIENTS

    function clientStrings()
        res::Vector{String} = fill("",length(instance.clients))
        for c in eachindex(instance.clients)
            for p in eachindex(instance.producers)
                current_coordinates = DataFrame(CSV.File(files_individuels[p], delim=','))
                current_clients = current_coordinates[2:nrow(current_coordinates),1]
                res_indiv = res_individuels[p]
                if ("client_$c" in current_clients)
                    res[c] *= "$(daysStrings[res_indiv[6][findfirst(x -> x == "client_$c", current_clients)]]) par $(instance.producers[p].name), demande : $(res_indiv[4][findfirst(x -> x == "client_$c", current_clients)+1])"
                    res[c] *= "\t"
                end
            end
        end
        res
    end

    clientStrings = clientStrings()
    
    for i in (nbOfProducers + 1):nrow(coordinates)
        myloc = coordinates[i,:]
        popuptxt = myloc["name"] * "\t" * string(myloc["latitude"]) *  "\t" * string(myloc["longitude"]) * clientStrings[i - nbOfProducers]
        folium.Marker(location=[myloc["latitude"], myloc["longitude"]], popup=popuptxt,icon=folium.Icon(icon="person", color = "blue",prefix="fa")).add_to(m)
    end

    for p in eachindex(instance.producers)

        coordinates_indiv = DataFrame(CSV.File(files_individuels[p], delim=','))
        corresp = vcat([i for i in 1:nrow(coordinates_indiv)],[1])
        instance, demands, routes, days, toursClients,daysRoutes = res_individuels[p][1], res_individuels[p][4], 
                                                                   res_individuels[p][5], res_individuels[p][6], res_individuels[p][7], res_individuels[p][10]

        for r in eachindex(routes)
            scpoints = vcat([(coordinates_indiv[corresp[1],2], coordinates_indiv[corresp[1],3])], [(coordinates_indiv[corresp[i],2], coordinates_indiv[corresp[i],3]) for i in routes[r]])
            folium.PolyLine(scpoints,color=colors[p], weight=2.5, opacity=0.8).add_to(m)
        end
    end

    m.save(output)

end
using PyCall, StatsBase
include("visualizeProducers.jl")
include("..\\firstModel\\MTCVRPMTW.jl")
include("..\\firstModel\\MTCVRPMTW-demi-journées.jl")

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
    instance, q, routes, days, toursClients = res[1], res[4], res[5], res[6], res[7]

    folium = pyimport("folium")
    m = visualizeProducerAndClient_demijournees(input, days, toursClients, q)

    colors_sample = sample(colors,length(instance.clients),replace=false)

    for r in eachindex(routes)
        scpoints = vcat([(coordinates[corresp[1],2], coordinates[corresp[1],3])], [(coordinates[corresp[i],2], coordinates[corresp[i],3]) for i in routes[r]])
        folium.PolyLine(scpoints,color=colors_sample[r], weight=2.5, opacity=0.8).add_to(m)
    end

    m.save(output)
end


#=
test = Producer(LatLon(47.347652435302734,0.6589514017105103),
[Client(LatLon(47.36783981323242,0.684602677822113),[15.0, 0.0],[[600,720]]), 
Client(LatLon(47.3904758,0.692027), [0.0,10.0],[[900,1020]])],
[[600,1020]],30,2)

res = MTCVRPMTW(test)
visualizeRoutes("data\\smallTest.csv", res, "views\\smallTest.html")
=#
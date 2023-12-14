using PyCall, StatsBase
include("visualizeProducers.jl")
include("..\\firstModel\\MTCVRPMTW.jl")

function visualizeRoutes(input::String, res, output::String, colors)

    coordinates = DataFrame(CSV.File(input, delim=','))
    corresp = vcat([i for i in 1:nrow(coordinates)],[1])
    x, y, z, w = res[2], res[3], res[4], res[5]
    
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

    folium = pyimport("folium")

    m = visualizeProducerAndClient(input, res)

    colors_sample = sample(colors,size(y,2),replace=false)

    for r in axes(y,2)
        scpoints = vcat([(coordinates[corresp[1],2], coordinates[corresp[1],3])], [(coordinates[corresp[i],2], coordinates[corresp[i],3]) for i in tourneesRightOrder[r]])
        push!(scpoints,((coordinates[corresp[1],2], coordinates[corresp[1],3])))
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
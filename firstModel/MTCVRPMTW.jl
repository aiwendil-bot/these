using JuMP, CPLEX
include("Producer.jl")
include("Instance_MTCVRPMTW.jl")

function MTCVRPMTW(instance::Instance_MTCVRPMTW)

    C::Vector{Int8} = [i for i in 2:(length(instance.clients)+1)] #indices clients
    R::Vector{Int8} = [i for i in 1:length(instance.clients)] #indices trips
    M::Vector{Int8} = [i for i in 1:length(instance.producer.numberOfProducts)] #indices produits

    bigM::Int64 = 10080 #nb de minutes en 1 semaine 

    V::Vector{Int8} = collect(1:(length(C)+2)) # sommets clients et producer dupliqué
    nbOfVertices::Int64 = length(V)

    A::Vector{Tuple{Int64,Int64}}=[(i,j) for i in V for j in V if (i != j && i != nbOfVertices && j != 1 && (i,j) != (1,nbOfVertices))] #arcs
    speed = 70 / 60 #km/h en km/min

    t = zeros(Float64, nbOfVertices, nbOfVertices)
    coordinates::Vector{LatLon{Float64}} = vcat(instance.producer.coordinates, [instance.clients[i-1].coordinates for i in C], instance.producer.coordinates)

    for i in 1:(nbOfVertices-1), j in (i+1):nbOfVertices
        dist_ij = euclidean_distance(coordinates[i], coordinates[j]) / 1000 # km
        t[i,j] = t[j,i] = dist_ij / speed #minute
    end

    TW = vcat([instance.producer.timeWindows], 
    [[[dayHourMinutesToMinutes(instance.clients[i-1].timeWindows[j]), dayHourMinutesToMinutes(instance.clients[i-1].timeWindows[j]) + instance.sizeOfTWInMin] for j in eachindex(instance.clients[i-1].timeWindows)] for i in C], 
    [instance.producer.timeWindows]) #vecteur des TW (dépôt dupliqué et clients)
    nbOfTW = length.(TW)

    model = Model(CPLEX.Optimizer)

    #------------ VARIABLES --------------------------------------
    
    @variable(model, x[i in V, j in V, r in R ; (i,j) in A], Bin)

    @variable(model, z[i in V,a = 1:nbOfTW[i],r in R], Bin)

    @variable(model, 0 <= w[i in V, r in R] <= bigM)

    #------------ OBJECTIVE ---------------------------------------

    @objective(model, Min, sum([w[nbOfVertices, r]- w[1, r]  for r in R]))

    #------------ CONSTRAINTS -------------------------------------

    @constraint(model, base_name= "1_$i" ,[i in C], sum(x[i,j,r] for r in R for j in V if (i,j) in A) == 1)

    @constraint(model,base_name= "2_$(i)_$r", [i in C, r in R], sum(x[i,j,r] for j in V if (i,j) in A) == sum(x[j,i,r] for j in V if (j,i) in A))

    @constraint(model,base_name= "3_$r", [r in R], sum(x[1,i,r] for i in V if (1,i) in A ) == sum(x[i,nbOfVertices,r] for i in V if (i,nbOfVertices) in A))

    @constraint(model,base_name=  "4_$r",[r in R], sum(x[1,i,r] for i in V if (1,i) in A ) <= 1)

    @constraint(model,base_name=  "5_$r", [r in R], sum(x[i,nbOfVertices,r] for i in V if (i,nbOfVertices) in A) <=1)

    @constraint(model, base_name= "6_$r", [r in R], sum(sum(instance.clients[i-1].demands) * x[i,j,r] for i in C for j in V if (i,j) in A) <= instance.producer.capacity)

    @constraint(model,base_name= "7_$(i)_$r", [i in V[1:(end-1)], r in R], sum(z[i,a,r] for a in 1:nbOfTW[i]) == sum(x[i,j,r] for j in V if (i,j) in A))

    @constraint(model,base_name= "8_$a",[a in 1:nbOfTW[1] ,r in R], z[1,a,r] == z[nbOfVertices, a , r])

    @constraint(model,base_name=  "9_$(i)_$r",[i in V, r in R], sum(z[i,a,r]*TW[i][a][1] for a in 1:nbOfTW[i]) <= w[i,r])

    @constraint(model,base_name=  "10_$(i)_$r", [i in V, r in R], w[i,r] <= sum(z[i,a,r]*TW[i][a][2] for a in 1:nbOfTW[i]))

    @constraint(model, base_name= "11_$(i)_$(j)_$r", [(i,j) in A, r in R], w[i,r] + t[i,j] <= w[j,r] + (1 - x[i,j,r]) * bigM)

    @constraint(model, [r in R[1:end-1]], w[nbOfVertices, r] <= w[1, r+1] )

    optimize!(model)

    function route(i,r,res)
        if (i == V[end])
            return vcat([i], res)
        end
        for j in V 
            if (i,j) in A
                if (value(x[i,j,r]) > 0.1)
                    return vcat([i],route(j,r,res))
                end
            end
        end
        return res
    end

    routes = [route(1,r,[]) for r in R]   
    toursClients = [r for i in C for r in eachindex(routes) if i in routes[r]]
    toursProducer = [r for r in R if (sum(value(x[1,j,r]) for j in V if (1,j) in A) > 0.1)]
    dureesRoutes = [sum(value(x[i,j,r])*t[i,j] for (i,j) in A) for r in R]
    times = [minutesToDayHourMinutes(trunc(Int64,sum(value.(w[i,:])))) for i in 1:(length(instance.clients)+1)]

    return [instance, objective_value(model), value.(x), value.(w), routes, toursProducer, toursClients, dureesRoutes,times]
end
#=
test = Producer(LatLon(47.347652435302734,0.6589514017105103),
[Client(LatLon(47.36783981323242,0.684602677822113),[15.0, 0.0],[[600,720]]), 
Client(LatLon(47.3904758,0.692027), [0.0,10.0],[[900,1020]])],
[[600,1020]],30,2)

MTCVRPMTW(test)
=#

using JuMP, GLPK
include("Producer.jl")
include("Instance_MTCVRPMTW.jl")

function MTCVRPMTW(instance::Instance_MTCVRPMTW)

    C::Vector{Int8} = [i for i in 2:(length(instance.clients)+1)] #indices clients
    R::Vector{Int8} = [i for i in 1:length(instance.clients)] #indices trips
    M::Vector{Int8} = [i for i in 1:length(instance.producer.numberOfProducts)] #indices produits
    display(M)
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

    model = Model(GLPK.Optimizer)

    #------------ VARIABLES --------------------------------------
    
    @variable(model, x[i in V, j in V, r in R ; (i,j) in A], Bin)

    @variable(model, y[i in V, r in R], Bin)

    @variable(model, z[i in V,a = 1:nbOfTW[i],r in R], Bin)

    @variable(model, 0 <= w[i in V, r in R] <= bigM)

    #------------ OBJECTIVE ---------------------------------------

    @objective(model, Min, sum([w[nbOfVertices, r]- w[1, r]  for r in R]))

    #------------ CONSTRAINTS -------------------------------------

    @constraint(model, [i in C], sum(y[i,r] for r in R) == 1)

    @constraint(model, [i in C, r in R], sum(x[i,j,r] for j in V if (i,j) in A) == y[i,r])

    @constraint(model, [i in C, r in R], sum(x[j,i,r] for j in V if (j,i) in A) == y[i,r])

    @constraint(model, [r in R], sum(x[1,i,r] for i in V if (1,i) in A ) == y[1,r])

    @constraint(model, [r in R], sum(x[i,nbOfVertices,r] for i in V if (i,nbOfVertices) in A) == y[nbOfVertices, r] )

    @constraint(model, [r in R], sum(sum(instance.clients[i-1].demands) * y[i,r] for i in C) <= instance.producer.capacity)

    @constraint(model, [i in V, r in R], sum(z[i,a,r] for a in 1:nbOfTW[i]) == y[i,r])

    @constraint(model,[a in 1:nbOfTW[1] ,r in R], z[1,a,r] == z[nbOfVertices, a , r])

    @constraint(model, [i in V, r in R], sum(z[i,a,r]*TW[i][a][1] for a in 1:nbOfTW[i]) <= w[i,r])

    @constraint(model, [i in V, r in R], w[i,r] <= sum(z[i,a,r]*TW[i][a][2] for a in 1:nbOfTW[i]))

    @constraint(model, [(i,j) in A, r in R], w[i,r] + t[i,j] <= w[j,r] + (1 - x[i,j,r]) * bigM)

    @constraint(model, [r in R[1:end-1]], w[nbOfVertices, r] <= w[1, r+1] )

    #println(model)
    optimize!(model)

    function route(i,r,res)
        if (i == V[end])
            return vcat([i], res)
        end
        for j in V 
            if (i,j) in A
                if (value(x[i,j,r,d]) > 0.1)
                    return vcat([i],route(j,r,res))
                end
            end
        end
        return res
    end

    routes = [route(1,r,[]) for r in R]   
    toursClients = [r for i in C for r in eachindex(routes) if i in routes[r]]

    dureesRoutes = [sum(value(x[i,j,r])*t[i,j] for (i,j) in A) for r in R]

    return [objective_value(model), value.(x), value.(y), value.(z), w, routes, toursClients, dureesRoutes]
end
#=
test = Producer(LatLon(47.347652435302734,0.6589514017105103),
[Client(LatLon(47.36783981323242,0.684602677822113),[15.0, 0.0],[[600,720]]), 
Client(LatLon(47.3904758,0.692027), [0.0,10.0],[[900,1020]])],
[[600,1020]],30,2)

MTCVRPMTW(test)
=#

using JuMP, GLPK
include("Producer.jl")
include("Instance_MTCVRPMTW_variant.jl")

function MTCVRPMTW(instance::Instance_MTCVRPMTW_demi_journees)

    C::Vector{Int8} = [i for i in 2:(length(instance.clients)+1)] #indices clients
    R::Vector{Int8} = [i for i in 1:length(instance.clients)] #indices trips
    M::Vector{Int8} = [i for i in 1:length(instance.producer.numberOfProducts)] #indices produits
    D::Vector{Int8} = [i for i in 1:2]

    V::Vector{Int8} = collect(1:(length(C)+2)) # sommets clients et producer dupliqué
    nbOfVertices::Int64 = length(V)

    A::Vector{Tuple{Int64,Int64}}=[(i,j) for i in V for j in V if (i != j && i != nbOfVertices && j != 1 && (i,j) != (1,nbOfVertices))] #arcs
    speed = 70 / 60 #km/h en km/min
    Tmax = 240

    t = zeros(Float64, nbOfVertices, nbOfVertices)
    coordinates::Vector{LatLon{Float64}} = vcat(instance.producer.coordinates, [instance.clients[i-1].coordinates for i in C], instance.producer.coordinates)

    for i in 1:(nbOfVertices-1), j in (i+1):nbOfVertices
        dist_ij = euclidean_distance(coordinates[i], coordinates[j]) / 1000 # km
        t[i,j] = t[j,i] = dist_ij / speed #minute
    end

    TW = vcat([instance.producer.timeWindows],
    [instance.clients[i].timeWindows for i in eachindex(instance.clients)]
    ,[instance.producer.timeWindows]) #vecteur des TW (dépôt dupliqué et clients)
    
    demands = vcat([0],[sum(instance.clients[i].demands) for i in eachindex(instance.clients)],[0])

    model = Model(GLPK.Optimizer)

    #------------ VARIABLES --------------------------------------
    @variable(model, x[i in V, j in V, r in R, d in D ; (i,j) in A], Bin)

    @variable(model, 0 <= q[i in V, r in R, d in D] <= instance.producer.capacity)

    #------------ OBJECTIVE ---------------------------------------

    @objective(model, Min, sum([x[i,j,r,d]*t[i,j] for (i,j) in A, r in R, d in D]))

    #------------ CONSTRAINTS -------------------------------------

    @constraint(model, [i in C], sum(x[i,j,r,d] for r in R, d in TW[i], j in V if (i,j) in A) == 1)

    @constraint(model, [i in C, r in R, d in D], sum(x[i,j,r,d] for j in V if (i,j) in A) == sum(x[j,i,r,d] for j in V if (j,i) in A))

    @constraint(model, [r in R], sum(x[1,i,r,d] for d in D for i in V if (1,i) in A ) == sum(x[i,nbOfVertices,r,d] for d in D for i in V if (i,nbOfVertices) in A))

    @constraint(model, [r in R], sum(x[1,i,r,d] for d in D for i in V if (1,i) in A ) <= 1)

    @constraint(model, [r in R], sum(x[i,nbOfVertices,r,d] for d in TW[end] for i in V if (i,nbOfVertices) in A) <= 1 )

    @constraint(model, [d in D], sum([x[i,j,r,d] * t[i,j] for r in R, (i,j) in A]) <= Tmax)

    @constraint(model, [(i,j) in A, r in R, d in union(TW[i],TW[j])], q[i,r,d] + demands[i] <= q[j,r,d] + (1 - x[i,j,r,d]) * instance.producer.capacity)

    println(model)
    optimize!(model)
    function day(i)
        for j in V
            if (i,j) in A
                for r in R
                    for d in D
                        if (value(x[i,j,r,d]) > 0.1)
                            return d 
                        end
                    end
                end
            end
        end
    end
    
    function route(i,r,res)
        if (i == V[end])
            return vcat([i], res)
        end
        for j in V 
            if (i,j) in A
                if (maximum([value(x[i,j,r,d]) for d in D]) > 0.1)
                    return vcat([i],route(j,r,res))
                end
            end
        end
        return res
    end

    routes = [route(1,r,[]) for r in R]  
    display(routes) 
    days = [day(i) for i in 2:(length(instance.clients)+1)]
    toursClients = [r for i in C for r in eachindex(routes) if i in routes[r]]

    dureesRoutes = [sum(value(x[i,j,r,d])*t[i,j] for (i,j) in A for d in D) for r in R]
    dureesParDemiJournee = [sum(value(x[i,j,r,d])*t[i,j] for (i,j) in A for r in R) for d in D]

    return [instance, objective_value(model), value.(x), value.(q), routes, days, toursClients, dureesRoutes, dureesParDemiJournee]
end

function MTCVRPMTW_v2(instance::Instance_MTCVRPMTW_demi_journees)

    M::Vector{Int8} = [i for i in 1:length(instance.producer.numberOfProducts)] #indices produits
    D::Vector{Int8} = [i for i in 1:10]

    N::Vector{Int8} = collect(1:(length(C)+1)) # sommets clients et producer dupliqué
    nbOfVertices::Int64 = length(N)

    speed = 70 / 60 #km/h en km/min
    Tmax = 240

    T = zeros(Float64, nbOfVertices, nbOfVertices)
    coordinates::Vector{LatLon{Float64}} = vcat(instance.producer.coordinates, [instance.clients[i-1].coordinates for i in 2:nbOfVertices])

    for i in 1:(nbOfVertices-1), j in (i+1):nbOfVertices
        dist_ij = euclidean_distance(coordinates[i], coordinates[j]) / 1000 # km
        T[i,j] = T[j,i] = dist_ij / speed #minute
    end

    display(T)

    TW = vcat([instance.producer.timeWindows],
    [instance.clients[i].timeWindows for i in eachindex(instance.clients)]) #vecteur des TW (dépôt dupliqué et clients)

    display(TW)
    
    demands = vcat([0],[sum(instance.clients[i].demands) for i in eachindex(instance.clients)])

    model = Model(GLPK.Optimizer)

    #------------ VARIABLES --------------------------------------
    @variable(model, x[i in N, j in N, d in D ], Bin)

    @variable(model, xx[i in N[2:end], j in N[2:end], d in D], Bin)

    @variable(model, 0 <= q[i in N, d in TW[i]] <= instance.producer.capacity)

    @variable(model, T[1,i] <= t[i in N[2:end], d in TW[i]] <= Tmax - T[i, 1])

    #------------ OBJECTIVE ---------------------------------------

    @objective(model, Min, sum([x[i,j,d]*T[i,j] for i in N for j in N for d in D]))

    #------------ CONSTRAINTS -------------------------------------

    @constraint(model, [i in N[2:end]], sum(x[i,j,d] for d in TW[i] for j in N) == 1)

    @constraint(model, [i in N[2:end], d in D], sum(x[i,j,d] for j in N) == sum(x[j,i,d] for j in N))

    @constraint(model, [i in N[2:end], j in N, d in intersect(TW[i],TW[j])], q[i,d] + demands[i] <= q[j,d] + (1 - x[i,j,d]) * instance.producer.capacity)

    @constraint(model, [i in N[2:end], j in N[2:end], d in intersect(TW[i],TW[j])], t[i,d] + T[i,j] <= t[j,d] + (1-x[i,j,d])*Tmax)

    @constraint(model, [i in N[2:end], j in N[2:end], d in intersect(TW[i],TW[j])], t[i,d] + T[i,1] + T[1,j] <= t[j,d] + Tmax * (1-xx[i,j,d]) )

    @constraint(model, [i in N[2:end], d in D], sum([xx[i,j,d] for j in N[2:end]]) <= x[i,1,d])

    @constraint(model, [j in C, d in D], sum([xx[i,j,d] for i in C]) <= x[1,j,d])

    @constraint(model, [d in D], sum([x[1,j,d] for j in C] ) <= 1 + sum([xx[i,j,d] for i in C for j in C]))

    @constraint(model, [i in C], T[1,i] <= sum(t[i,d] for d in D) <= Tmax)

    #println(model)
    optimize!(model)

    function day(i)
        for j in V
            if (i,j) in A
                for d in D
                    if (value(x[i,j,d]) > 0.1)
                        return d 
                    end
                end
            end
        end
    end

    for i in x 
        if (value(i) > 0.1)
            println(i," ", value(i))
        end
    end

    display(demands)


    for i in t 
        println(i, " ", value(i))
    end

    for i in q
        println(i, " ", value(i))
    end

    function route(i,res)
        for j in V
            if (i,j) in A
                if (maximum([value(x[i,j,d]) for d in D]) > 0.1)
                    return vcat([i], route(j,res))
                end
            end
        end
        if (i == V[end])
            return vcat([i],res)
        end
        return res
    end
    
    function routes(k,tournee)

        if (maximum([value(x[1,k,d]) for d in D]) > 0.1)
            return vcat([1],route(k,[]))
        end

        return tournee
    end

    function dureeRoute(vector)
        return sum([T[vector[i],vector[i+1]] for i in 1:(length(vector)-1)])
    end

    tournees = filter!(x -> length(x) > 0, [routes(k,[]) for k in 2:(length(V)-1)])
    display(tournees)
    days = [day(i) for i in 2:(length(instance.clients)+1)]
    toursClients = [r for i in C for r in eachindex(tournees) if i in tournees[r]]

    dureesRoutes = [dureeRoute(tour) for tour in tournees]
    dureesParDemiJournee = [sum(value(x[i,j,d])*T[i,j] for (i,j) in A) for d in D]

    return [instance, objective_value(model), value.(x), value.(q), tournees, days, toursClients, dureesRoutes, dureesParDemiJournee]
end
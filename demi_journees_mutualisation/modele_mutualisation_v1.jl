using JuMP, GLPK, CPLEX
include("Instance_mutualisation.jl")

function mutualisationModel(instance::Instance_mutualisation, time_limit::Float64)

    P::Vector{Int8} = [i for i in eachindex(instance.producers)]
    C::Vector{Int8} = [length(P) + i for i in eachindex(instance.clients)]
    D::Vector{Int8} = [i for i in 1:10]

    N::Vector{Int8} = vcat(P,C)

    nbOfVertices::Int64 = length(N)
    nbOfProducers::Int64 = length(P)

    producersPerClient = [[p for p in P if (instance.producers[p] in instance.producersPerClient[c])] for c in eachindex(instance.clients)]
    clientsPerProducer = [[c for c in eachindex(instance.clients) if (instance.producers[p] in instance.producersPerClient[c])] for p in eachindex(instance.producers)]

    speed = 70 / 60 #km/h en km/min
    Tmax = 240

    T = zeros(Float64, nbOfVertices, nbOfVertices)
    coordinates::Vector{LatLon{Float64}} = vcat([instance.producers[p].coordinates for p in eachindex(instance.producers)],
                                                [instance.clients[c].coordinates for c in eachindex(instance.clients)])

    for i in 1:(nbOfVertices-1), j in (i+1):nbOfVertices
        dist_ij = euclidean_distance(coordinates[i], coordinates[j]) / 1000 # km
        T[i,j] = T[j,i] = dist_ij / speed #minute
    end

    TW = vcat([instance.producers[p].timeWindows for p in eachindex(instance.producers)], [instance.clients[i].timeWindows for i in eachindex(instance.clients)])
    
    demands = [sum(instance.clients[i].demands) for i in eachindex(instance.clients)]

    model = Model(CPLEX.Optimizer)

    #set_time_limit_sec(model, time_limit)
    #set_attribute(model, "CPX_PARAM_MIPDISPLAY", 1)

    #------------ VARIABLES --------------------------------------
    @variable(model, x[p in P, i in N, j in N, d in D ], Bin)

    @variable(model, y[p in P, c in C, d in TW[c]], Bin)

    @variable(model, z[p in P, q in P, d in D], Bin)

    @variable(model, w[p in P, q in P, c in C, d in D, dd in TW[c] ; p != q && d <= dd], Bin)

    @variable(model, ww[p in P, q in P, c in C, d in D, dd in TW[c] ; p != q && d <= dd], Bin)

    @variable(model, 0 <= q[p in P, i in N, d in D] <= instance.producers[p].capacity)

    @variable(model, 0 <= t[p in P, i in N, d in D ; i != p] <= Tmax - T[i, p])

    #------------ OBJECTIVE ---------------------------------------

    @objective(model, Min, sum([x[p,i,j,d]*T[i,j] for p in P for i in N for j in N for d in D]))

    #------------ CONSTRAINTS -------------------------------------

    @constraint(model, [c in C], sum(x[p,c,j,d] for p in P for d in TW[c] for j in N) >= 1)

    @constraint(model, [p in P, d in D], sum([x[p,p,j,d] for j in N if j != p]) <= 1) 

    @constraint(model, [c in C, p in producersPerClient[c - nbOfProducers]], sum([y[p,c,d] for d in TW[c]]) + 
                sum([w[p,q,c,d,dd] for d in D for dd in TW[c] for q in P if (d <= dd && q !=p)]) +
                sum([ww[p,q,c,d,dd] for d in D for dd in TW[c] for q in P if (d <= dd && q !=p)])>= 1)

    @constraint(model, [p in P, i in N, d in D ; i != p], sum(x[p,i,j,d] for j in N) == sum(x[p,j,i,d] for j in N))

    @constraint(model, [p in P, u in P, j in N, d in D ; p != u && u != j], q[p,u,d] - sum([ w[p,u,c,d,dd] * instance.clients[c - nbOfProducers].demands[p] for c in C for dd in TW[c] if d <= dd]) 
                                                                        + sum([ww[u,p,c,d,dd] * instance.clients[c - nbOfProducers].demands[u] for c in C for dd in TW[c] if d <= dd])                                                                                
    <= q[p,j,d] + (1 - x[p,u,j,d]) * instance.producers[p].capacity)

    @constraint(model,[p in P, j in N, d in D ; p != j], sum([y[p,c,d] * instance.clients[c - nbOfProducers].demands[p] for c in C if d in TW[c]])
                                                        + sum([w[p,pp,c,d,dd]*instance.clients[c - nbOfProducers].demands[p] for pp in P for c in C for dd in TW[c] if (d <= dd && p != pp)])
                                                        + sum([ww[pp,p,c,dd,d]*instance.clients[c - nbOfProducers].demands[pp] for c in C for pp in P for dd in D if (d in TW[c] && p != pp && dd <= d)])
                                                        + sum([w[pp,p,c,dd,d]*instance.clients[c - nbOfProducers].demands[pp] for c in C for pp in P for dd in D if (d in TW[c] && dd <= d && p != pp)])
                                                        <= q[p,j,d] + (1-x[p,p,j,d])*instance.producers[p].capacity)

    @constraint(model, [p in P, i in N, j in N, d in D ; i != p && j != p], t[p,i,d] + T[i,j] <= t[p,j,d] + (1-x[p,i,j,d])*Tmax)
   
    @constraint(model, [p in P, q in P, c in C, d in TW[c] ; p != q], t[p,q,d] <= t[q,c,d] + (1-w[p,q,c,d,d]) * Tmax)

    @constraint(model, [p in P, q in P, c in C, d in TW[c] ; p != q], t[q,p,d] <= t[q,c,d] + (1-ww[p,q,c,d,d]) * Tmax)

    @constraint(model, [p in P, c in C, d in TW[c]], sum([x[p,i,c,d] for i in N]) == y[p,c,d])
    
    @constraint(model, [p in P, c in C, d in TW[c]], sum([x[p,c,i,d] for i in N]) == y[p,c,d])
    
    @constraint(model, [p in P, q in P, d in D ; p != q], sum([x[p,u,q,d] for u in N]) == z[p,q,d])

    @constraint(model, [p in P, q in P, d in D ; p != q], sum([x[p,q,u,d] for u in N]) == z[p,q,d])

    @constraint(model, [p in P, d in D], z[p,p,d] == 0)

    @constraint(model, [p in P, d in D, i in N], x[p,i,i,d] == 0)

    @constraint(model, [p in P, q in P, d in D ; p != q], sum([x[p,c,q,d] for c in C]) == 0)

    @constraint(model, [p in P, c in C, d in D], sum([x[p,c,q,d] for q in P if p != q]) == 0)

    @constraint(model, [p in P, q in P, c in C, d in D, dd in TW[c] ; p != q && d <= dd], w[p,q,c,d,dd] >= z[p,q,d] + y[q,c,dd] - 1)

    @constraint(model, [p in P, q in P, c in C, d in D, dd in TW[c] ; p != q && d <= dd], w[p,q,c,d,dd] <= z[p,q,d])

    @constraint(model, [p in P, q in P, c in C, d in D, dd in TW[c] ; p != q && d <= dd], w[p,q,c,d,dd] <= y[q,c,dd])

    @constraint(model, [p in P, q in P, c in C, d in D, dd in TW[c] ; p != q && d <= dd], ww[p,q,c,d,dd] >= z[q,p,d] + y[q,c,dd] - 1)

    @constraint(model, [p in P, q in P, c in C, d in D, dd in TW[c] ; p != q && d <= dd], ww[p,q,c,d,dd] <= z[q,p,d])

    @constraint(model, [p in P, q in P, c in C, d in D, dd in TW[c] ; p != q && d <= dd], ww[p,q,c,d,dd] <= y[q,c,dd])

    @constraint(model, [p in P, q in P, c in C; p != q], sum([w[p,q,c,d,dd] for d in D for dd in TW[c] if d <= dd]) + sum([ww[p,q,c,d,dd] for d in D for dd in TW[c] if d <= dd]) <= 1)

    optimize!(model)

    if termination_status(model) == OPTIMAL
        @info "la solution mutualisée est optimale"
    elseif termination_status(model) == TIME_LIMIT && has_values(model)
        @warn "la solution mutualisée est suboptimale à cause de la limite de temps"
    else
        error("The model was not solved correctly.")
    end

    function day(p,i)
        for j in N
            for d in D
                if (value(x[p,i,j,d]) > 0.1 && i != p)
                    return [p,d] 
                end
            end
        end
        return [0,0]
    end

    function route(p,i,res)
        for j in N
            if (maximum([value(x[p,i,j,d]) for d in D]) > 0.1)
                if (j == p)
                    return vcat([i,j],res) 
                else
                    return vcat([i], route(p,j,res))
                end
            end
        end
        return res
    end
    
    function routes(p,k,tournee)

        if (maximum([value(x[p,p,k,d]) for d in D]) > 0.1)
            return vcat([p],route(p,k,[]))
        end

        return tournee
    end

    function dureeRoute(vector)
        return sum([T[vector[i],vector[i+1]] for i in 1:(length(vector)-1)])
    end

    for i in x
        if (value(i) > 0.1)
            println(i)
        end
    end

    for i in q
        if (value(i) > 0.1)
            println(i, value(i))
        end
    end

    tournees = [filter!(x -> length(x) > 0, [routes(p,k,[]) for k in N]) for p in P]
    #display(tournees)
    whoServedWhoAndWhen = [[day(p,i) for p in P] for i in N]
    display(whoServedWhoAndWhen)
    whoServedWho = [[p for p in eachindex(tournees) if !isempty(tournees[p]) && i in reduce(vcat,tournees[p]) && i != p] for i in N] #quel producteur a desservi chaque client
    #display(visitDays)
    daysRoutes = [day(tour[1],tour[2])[2] for p in eachindex(tournees) for tour in tournees[p]]
    #display(daysRoutes)
    dureesRoutes = [dureeRoute(tour) for p in tournees for tour in p]
    dureesParDemiJourneeParProducer = [[sum(value(x[p,i,j,d])*T[i,j] for i in N for j in N) for p in P] for d in D]

    return [instance, objective_value(model), value.(x), demands, tournees, whoServedWhoAndWhen, dureesRoutes, dureesParDemiJourneeParProducer, daysRoutes]
end
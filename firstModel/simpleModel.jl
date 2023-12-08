using JuMP, GLPK
include("Producer.jl")

function MTCVRPMTW(producer::Producer)

    C::Vector{Int8} = [i for i in 2:(length(producer.clients)+1)] #indices clients
    R::Vector{Int8} = [i for i in 1:length(producer.clients)] #indices trips
    M::Vector{Int8} = [i for i in 1:length(producer.numberOfProducts)] #indices produits

    bigM::Int64 = 10080 #nb de minutes en 1 semaine 

    V::Vector{Int8} = [i for i in 1:(length(C)+2)] # sommets clients et producer dupliqué
    A::Vector{Tuple{Int64,Int64}}=[(i,j) for i in V for j in V if (i != j && i != length(C) + 2 && j != 1 && (i,j) != (1,length(C)+2))] #arcs

    speed = 70 / 60 #km/h en km/min

    t = zeros(Float64, length(V), length(V))
    coordinates::Vector{LatLon} = vcat([producer.coordinates], [producer.clients[i-1].coordinates for i in C], producer.coordinates)

    for i in 1:(length(V)-1), j in (i+1):length(V)
        dist_ij = euclidean_distance(coordinates[i], coordinates[j]) / 1000 # km
        t[i,j] = t[j,i] = dist_ij / speed #minute
    end

    TW = vcat([producer.timeWindows], [producer.clients[i-1].timeWindows for i in C], [producer.timeWindows])
    nbOfTW = [length(i) for i in TW]

    model = Model(GLPK.Optimizer)

    #------------ VARIABLES --------------------------------------
    @variable(model, x[i in V, j in V, r in R ; (i,j) in A], Bin)

    @variable(model, y[i in C, r in R], Bin)

    @variable(model, z[i in V,a = 1:nbOfTW[i],r in R], Bin)

    @variable(model, 0 <= w[i in V, r in R] <= bigM)

    #------------ OBJECTIVE ---------------------------------------

    @objective(model, Min, sum(x[i,j,r]*t[i,j] for r in R, (i,j) in A))

    #------------ CONSTRAINTS -------------------------------------

    @constraint(model, [i in C], sum(y[i,r] for r in R) == 1)

    @constraint(model, [i in C, r in R], sum(x[i,j,r] for j in V if (i,j) in A) == y[i,r])

    @constraint(model, [i in C, r in R], sum(x[j,i,r] for j in V if (j,i) in A) == y[i,r])

    @constraint(model, [r in R], sum(producer.clients[i-1].demands[m] * y[i,r] for m in M, i in C) <= producer.capacity)

    @constraint(model, [i in C, r in R], sum(z[i,a,r] for a in 1:nbOfTW[i]) == y[i,r])

    @constraint(model, [i in [1,length(V)], r in R], sum(z[i,a,r] for a in 1:nbOfTW[i]) >= 1)

    @constraint(model, [i in V, r in R], sum(z[i,a,r]*TW[i][a][1] for a in 1:nbOfTW[i]) <= w[i,r])

    @constraint(model, [i in V, r in R], w[i,r] <= sum(z[i,a,r]*TW[i][a][2] for a in 1:nbOfTW[i]))


    @constraint(model, [(i,j) in A, r in R], w[i,r] + t[i,j] <= w[j,r] + (1 - x[i,j,r]) * bigM)

    println(model)

    optimize!(model)

    print(objective_value(model))
    display(value.(y))
    display(value.(w))
    for i in z 
        if (value(i) >0)
        println(i, value(i))
        end
    end

    for i in w
        if (value(i) >0)
        println(i,value(i))
        end
    end
    for i in x
        if (value(i) >0)
        println(i,value(i))
        end
    end
    display(t)
end

test = Producer(LatLon(47.347652435302734,0.6589514017105103),
[Client(LatLon(47.36783981323242,0.684602677822113),[15.0, 0.0],[[600,720]]), 
Client(LatLon(47.3904758,0.692027), [0.0,10.0],[[900,1020]])],
[[600,1020]],30,2)

MTCVRPMTW(test)
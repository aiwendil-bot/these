function displayDemiJournees(clients, res)

    routes, daysClients, toursClients, dureesRoutes, dureeDemiJournees = res[5], res[6], res[7], res[8], res[9] 

    function routesStrings(r)::String
        res = ""
        for i in routes[r]
            if (i == 1)
                res *= " producer,"
            else
                res *= " client_$(i-1),"
            end
        end
        return res
    end
    # disponibilités

    for i in eachindex(clients)
        println("client_$i, demande totale : $(sum(clients[i].demands)), créneaux possibles : ", join(["$(daysStrings[j]), " for j in clients[i].timeWindows]))
        println("\t livré le $(daysStrings[daysClients[i]]) par le tour n°$(toursClients[i])")
    end
    
    # routes

    for r in eachindex(routes)
        if (!isempty(routes[r]))
            println("tournée n°$r :", routesStrings(r))
            println("\t temps total : ",round(dureesRoutes[r],digits=2)," minutes")
        end
    end

    for d in eachindex(dureeDemiJournees)
        println(daysStrings[d], " : $(round(dureeDemiJournees[d],digits=2)) minutes")
    end

end

function displayDemiJournees_v2(current_clients, clients, res)

    routes, daysClients, toursClients, dureesRoutes, dureeDemiJournees = res[5], res[6], res[7], res[8], res[9] 

    function routesStrings(r)::String
        res = ""
        for i in routes[r]
            if (i == 1 || i == length(clients) + 2)
                res *= " producer,"
            else
                res *= " $(current_clients[i-1]),"
            end
        end
        return res
    end
    # disponibilités

    for i in eachindex(clients)
        println("$(current_clients[i]), demande totale : $(sum(clients[i].demands)), créneaux possibles : ", join(["$(daysStrings[j]), " for j in clients[i].timeWindows]))
        println("\t desservi le $(daysStrings[daysClients[i]]) par le tour n°$(toursClients[i])")
    end
    
    # routes

    for r in eachindex(routes)
        if (!isempty(routes[r]))
            println("tournée n°$r :", routesStrings(r))
            println("\t temps total : ",round(dureesRoutes[r],digits=2)," minutes")
        end
    end

    for d in eachindex(dureeDemiJournees)
        println(daysStrings[d], " : $(round(dureeDemiJournees[d],digits=2)) minutes")
    end

end
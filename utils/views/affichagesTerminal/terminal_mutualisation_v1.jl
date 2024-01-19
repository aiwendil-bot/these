function displayMutualisation(producers, clients, producersPerClient, res)

    instance, routes, whoServedWhoAndWhen, dureesRoutes, dureeDemiJournees, daysRoutes = res[1], res[5], res[6], res[7], res[8], res[9]

    function routesStrings(p,r)::String
        res = ""
        for i in routes[p][r]
            if (i <= length(producers))
                res *= producers[i].name
            else
                res *= " client_$(i-length(producers)),"
            end
        end
        return res
    end

    # disponibilités

    for i in eachindex(producers)
        println(producers[i].name, " : ")
        println(visitDays(instance,whoServedWhoAndWhen,i))
    end


    for i in eachindex(clients)
        println("client_$i, demande totale : $(sum(clients[i].demands)), créneaux possibles : ", join(["$(daysStrings[j]), " for j in clients[i].timeWindows]))
        println(visitDays(instance, whoServedWhoAndWhen,i+length(producers)))
    end
    
    # routes
    println("\n", "tournées : ", "\n")
    routeNumero = 1
    for p in eachindex(routes)
        if (!isempty(routes[p]))
            for r in eachindex(routes[p])
                println(routesStrings(p,r))
                println("\t le $(daysStrings[daysRoutes[routeNumero]]), temps total : ",round(dureesRoutes[routeNumero],digits=2)," minutes")
                routeNumero += 1
            end
        end
    end

    for d in eachindex(dureeDemiJournees)
        println(daysStrings[d], " : $(round(sum(dureeDemiJournees[d]),digits=2)) minutes")
    end

end
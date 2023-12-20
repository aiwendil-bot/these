function displayTimeWindows(instance, res,maxOfWindows)

    w, routes, toursClients, dureesRoutes,times = res[4], res[5], res[7], res[8], res[9]
    dayHoursMinutesProducer = [[minutesToDayHourMinutes(trunc(Int64,w[1,r])), minutesToDayHourMinutes(trunc(Int64,w[length(instance.clients)+2,r]+1)) ] for r in eachindex(routes)]
    display(dayHoursMinutesProducer)
    function routesStrings(r)::String
        res = ""
        for i in routes[r]
            if (i == 1 || i == length(instance.clients) + 2)
                res *= " producer,"
            else
                res *= " client_$(i-1),"
            end
        end
        res *= days[dayHoursMinutesProducer[r][1][1]] * " "
        return res *= "$(dayHoursMinutesProducer[r][1][2]):$(dayHoursMinutesProducer[r][1][3]) - $(dayHoursMinutesProducer[r][2][2]):$(dayHoursMinutesProducer[r][2][3])"
    end

    println("capacité : $(instance.producer.capacity)")
    println("taille des créneaux : $(instance.sizeOfTWInMin) minutes")
    println("nombre max de créneaux pour un client : $maxOfWindows")


    for r in eachindex(routes)
        if (!isempty(routes[r]))
            println(routesStrings(r))
            println("\t temps total : ",round(dureesRoutes[r],digits=2)," minutes")
        end
    end

    for i in eachindex(instance.clients)
        println("client_$i, demande totale : $(sum(instance.clients[i].demands)), desservi le $(days[times[i+1][1]]), $(times[i+1][2]):$(times[i+1][3]) par le tour n°$(toursClients[i])")
        println("créneaux :")
        for tw in instance.clients[i].timeWindows
            println("\t $(days[tw[1]]), $(tw[2]):$(tw[3]) - $(tw[2]+(instance.sizeOfTWInMin÷60)):$(tw[3])")
        end
    end

end
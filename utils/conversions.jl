function dayHourMinutesToMinutes(timeInDayHourMinute::Vector{Int64})::Int64
    timeInDayHourMinute[1]*24*60 + timeInDayHourMinute[2]*60 + timeInDayHourMinute[3]
end

function minutesToDayHourMinutes(timeInMinutes::Int64)::Vector{Int64}

    days = timeInMinutes ÷ (24*60)
    hours = (timeInMinutes % (24*60)) ÷ 60
    minutes = (timeInMinutes % (24*60)) % 60

    return [days, hours, minutes]

end

days::Dict{Int64,String} = Dict{Int64,String}(0 => "lundi", 1 => "mardi", 2 => "mercredi", 3 => "jeudi", 4 => "vendredi", 5 => "samedi", 6 => "dimanche")

function matinaprem(i)::String
    if (i%2 == 0) "matin" else "après-midi"
    end
end

daysStrings = [days[i÷2] * " " * matinaprem(i) for i in 0:9]

function visitDays(instance, whoServedWhoAndWhen,i)::String
    res = ""
    for d in eachindex(whoServedWhoAndWhen[i])
        if whoServedWhoAndWhen[i][d][2] > 0
            res *= "visité le $(daysStrings[whoServedWhoAndWhen[i][d][2]]) par $(instance.producers[whoServedWhoAndWhen[i][d][1]].name) \n"
        end
    end
    return res
end
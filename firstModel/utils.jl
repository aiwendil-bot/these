function dayHourMinutesToMinutes(timeInDayHourMinute::Vector{Int64})::Int64
    timeInDayHourMinute[1]*24*60 + timeInDayHourMinute[2]*60 + timeInDayHourMinute[3]
end

function minutesToDayHourMinutes(timeInMinutes::Int64)::Vector{Int64}

    days = timeInMinutes ÷ (24*60)
    hours = (timeInMinutes % (24*60)) ÷ 60
    minutes = (timeInMinutes % (24*60)) % 60

    return [days, hours, minutes]

end
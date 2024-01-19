struct Instance_mutualisation
    producers::Vector{Producer_mutualisation}
    clients::Vector{Client_mutualisation}
    producersPerClient::Vector{Vector{Producer_mutualisation}}
end
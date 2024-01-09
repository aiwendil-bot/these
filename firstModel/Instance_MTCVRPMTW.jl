include("Producer.jl")

struct Instance_MTCVRPMTW
    producer::Producer
    clients::Vector{Client}
    sizeOfTWInMin::Int64 #taille fixe pour tous les clients
end
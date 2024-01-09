using CSV, DataFrames, DelimitedFiles

df = DataFrame(CSV.File("data\\producteurs.txt", delim=','))
new = DataFrame(nom=String[], latitude=Float64[], longitude=Float64[])
for i in 1:nrow(df)
    skipped = collect(skipmissing(df[i,:]))
    if (skipped[end-1] != "null") && (skipped[end-1] != "null")
        if (typeof(skipped[end-1]) == Float64 || typeof(skipped[end]) == Float64)
            push!(new,(skipped[2], skipped[end-1],skipped[end]))
        else
            push!(new,(skipped[2], parse(Float64,skipped[end-1]),parse(Float64,skipped[end])))
        end
    end
end

CSV.write("data/cleanProducers.csv", new)
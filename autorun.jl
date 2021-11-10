todo = 8:8:50

for doing ∈ todo
    println(doing)
    try
        run(`julia aespa.jl $doing`)
    catch LoadError
        open("./error $doing.txt", "w")
    end
end
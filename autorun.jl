todo = parse(Int64, ARGS[1]):10:290
# todo = 201:203

for doing ∈ todo
    println(doing)
    try
        run(`julia aespa.jl $doing`)
    catch LoadError
        open("./error $doing.txt", "w")
    end
end
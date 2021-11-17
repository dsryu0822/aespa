todo = parse(Int64, ARGS[1]):8:200
# todo = [1,51,101,151]

for doing ∈ todo
    println(doing)
    try
        run(`julia aespa.jl $doing`)
    catch LoadError
        open("./error $doing.txt", "w")
    end
end
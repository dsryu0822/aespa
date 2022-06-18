# todo = parse(Int64, ARGS[1]):6:30
# todo = parse(Int64, ARGS[1]):10:310

using Base.Threads
@threads for doing ∈ 1:51
# todo = parse(Int64, ARGS[1]):7:102
# for doing ∈ todo
    println(doing)
    try
        run(`julia aespa.jl $doing`)
    catch LoadError
        open("../../바탕 화면/error $doing.txt", "w")
    end
end
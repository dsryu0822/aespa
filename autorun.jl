# todo = parse(Int64, ARGS[1]):6:30
# todo = parse(Int64, ARGS[1]):10:310
using Dates
using Base.Threads

tic = now()

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
toc = now()

tictoc = open("success.log","w")
println(tictoc, tic)
println(tictoc, toc)
println(tictoc, Dates.canonicalize(toc - tic))
close(tictoc)
run(`rclone copy success.log sickleft:"OneDrive/바탕 화면"`)
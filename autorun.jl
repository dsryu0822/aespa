# todo = parse(Int64, ARGS[1]):6:30
# todo = parse(Int64, ARGS[1]):10:310
using Dates
using Base.Threads

tic = now()

@threads for doing ∈ 1:33
# todo = parse(Int64, ARGS[1]):7:102
# for doing ∈ todo
    println(doing)
    try
        run(`julia aespa.jl $doing`)
    catch LoadError
        error_report = open("fail.log", "a")
        println(error_report, "$(now()): error in $doing")
        close(error_report)
        run(`rclone copy fail.log sickleft:"OneDrive/바탕 화면"`)
    end
end
toc = now()

tictoc = open("success.log","w")
println(tictoc, tic)
println(tictoc, toc)
println(tictoc, Dates.canonicalize(toc - tic))
close(tictoc)
run(`rclone copy success.log sickleft:"OneDrive/바탕 화면"`)
run(`python mailing.py $Env:naver`)
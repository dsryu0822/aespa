# todo = parse(Int64, ARGS[1]):6:30
# todo = parse(Int64, ARGS[1]):10:310
using Dates
using Base.Threads

tic = now()

@threads for doing ∈ 1:(5*11)
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

using SMTPClient
opt = SendOptions(
  isSSL = true,
  username = "rmsmsgood",
  passwd = "e=$(floor(exp(1),digits = 6))")
#Provide the message body as RFC5322 within an IO
body = IOBuffer(
  "Date: $now() \r\n" *
#   "Date: Fri, 18 Oct 2013 21:44:29 +0100\r\n" *
  "From: server2 <rmsmsgood@naver.com>\r\n" *
  "To: dsryu0822@kakao.com\r\n" *
  "Subject: simulation over\r\n" *
  "\r\n" *
  "$tic\r\n" *
  "$toc\r\n" *
  "$(Dates.canonicalize(toc - tic))" *
  "\r\n")
url = "smtps://smtp.naver.com:465"
rcpt = ["<dsryu0822@kakao.com>"]
from = "<rmsmsgood@naver.com>"
resp = send(url, rcpt, from, body, opt)
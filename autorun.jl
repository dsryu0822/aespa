begin
  using XLSX, CSV, DataFrames
  while true
    try
      cached_schedule = XLSX.readtable(string(@__DIR__) * "/schedule.xlsx", "schedule")
      CSV.write("cached_schedule.csv", cached_schedule)
      break
    catch SystemError
      print(".")
    end
  end

  using Dates
  tic = now()

  if Base.ENV["USERDOMAIN"] == "CHAOS1"
    todo = 1:100
  elseif Base.ENV["USERDOMAIN"] == "CHAOS2"
    todo = 101:200
  elseif Base.ENV["USERDOMAIN"] == "SICKRIGHT"
    todo = 201:205
  end
  print("$todo ")

  Threads.@threads for doing ∈ todo
      try
          run(`julia aespa.jl $doing`)
      catch LoadError
          @warn "$doing"
          error_report = open("fail.log", "a")
          println(error_report, "$(Base.ENV["USERDOMAIN"]) $(now()): error in $doing")
          close(error_report)
      end
  end
  toc = now()

  # tictoc = open("success.log","w")
  # println(tictoc, tic)
  # println(tictoc, toc)
  # println(tictoc, Dates.canonicalize(toc - tic))
  # close(tictoc)
  # run(`rclone copy success.log sickleft:"OneDrive/바탕 화면"`)

  using SMTPClient
  opt = SendOptions(
    isSSL = true,
    username = "rmsmsgood",
    passwd = "$(Base.ENV["naver"])")
  #Provide the message body as RFC5322 within an IO
  body = IOBuffer(
    "Date: $now() \r\n" *
    "From: $(Base.ENV["USERDOMAIN"]) <rmsmsgood@naver.com>\r\n" *
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
end

run(`7z a C:/saved/simulated_$(Base.ENV["USERDOMAIN"]).7z C:/simulated`)

# if isfile("fail.log")
#   try
#     run(`rclone copy $(@__DIR__)/fail.log sickleft:"OneDrive/바탕 화면"`)
#   catch LoadError
#     @warn "Network Error!"
#   end
# end


using Ripserer, DataFrames, CSV, Plots

x = CSV.read("D:/simulated/E10/0003 ndws.csv", DataFrame) |> Matrix
result3 = ripserer([X for X in eachcol(x)]; dim_max = 3)
plot(result3)

x = CSV.read("D:/simulated/E10/0006 ndws.csv", DataFrame) |> Matrix
result6 = ripserer([X for X in eachcol(x)]; dim_max = 3)
plot(result6)

x = CSV.read("D:/simulated/E10/0009 ndws.csv", DataFrame) |> Matrix
result9 = ripserer([X for X in eachcol(x)]; dim_max = 3)
plot(result9)
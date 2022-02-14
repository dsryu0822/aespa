@time using CSV, XLSX, DataFrames, StatsBase, Statistics
@time using Plots, Plots.PlotMeasures, LaTeXStrings, StatsPlots
default()

over50(ndwi) = vec(maximum(ndwi, dims = 1) .> 50)

schedules = DataFrame(XLSX.readtable("C:/Users/rmsms/OneDrive/lab/aespa//schedule.xlsx", "schedule")...)

# try
#     ntwk = CSV.read("D:/simulated/ntwk.csv", DataFrame)
# finally
#     print("ntwk load")
# end

import_dir = "D:/simulated/"
export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

color_ = Dict("00" => :black, "0V" => colorant"#C00000", "M0" => colorant"#0070C0", "MV" => colorant"#7030A0")
shape_ = Dict("00" => :+, "0V" => :x, "M0" => :circle, "MV" => :star5)
label_ = Dict("00" => "No control", "0V" => "Vaccination", "M0" => "Restriction", "MV" => "Both control")

te_color_ = Dict(
    "S" => colorant"#FFC000",
    "E" => colorant"#ED7D31",
    "I" => colorant"#C00000",
    "R" => colorant"#A5A5A5",
    "V" => colorant"#70AD47")
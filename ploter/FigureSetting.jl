@time using CSV, XLSX, DataFrames, StatsBase, Statistics
@time using Plots, LaTeXStrings, StatsPlots
default()

schedules = DataFrame(XLSX.readtable("C:/Users/rmsms/OneDrive/lab/aespa//schedule.xlsx", "schedule")...)
import_dir = "D:/simulated/"
export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

color_ = Dict("00" => :black, "0V" => colorant"#C00000", "M0" => colorant"#0070C0", "MV" => colorant"#7030A0")
shape_ = Dict("00" => :+, "0V" => :x, "M0" => :circle, "MV" => :star5)
label_ = Dict("00" => "No control", "0V" => "Vaccination", "M0" => "Restriction", "MV" => "Both control")
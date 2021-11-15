@time using CSV, XLSX, DataFrames, StatsBase, Statistics
@time using Plots, LaTeXStrings, StatsPlots
# default(markeralpha = 0.5, markerstrokewidth = 0)
default()
default(linealpha = 0.5, ylims = (0,3))

schedules = DataFrame(XLSX.readtable("C:/Users/rmsms/OneDrive/lab/aespa//schedule.xlsx", "schedule")...)
import_dir = "D:/simulated/"
export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

color_ = Dict("00" => :black, "0V" => :red, "M0" => :blue, "MV" => :purple)
shape_ = Dict("00" => :circle, "0V" => :x, "M0" => :+, "MV" => :star5)

# todo = (1:50) .+ 0

plot_RT00 = plot(legend = :none, size = (700,300),
 xlabel = L"T", ylabel = L"R_{T}")
plot_RT0V = plot(legend = :none, size = (700,300),
 xlabel = L"T", ylabel = L"R_{T}")
plot_RTM0 = plot(legend = :none, size = (700,300),
 xlabel = L"T", ylabel = L"R_{T}")
plot_RTMV = plot(legend = :none, size = (700,300),
 xlabel = L"T", ylabel = L"R_{T}")
println("ready")


doing = 5
scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]

strands00 = Array{Float64}[]
strands0V = Array{Float64}[]
strandsM0 = Array{Float64}[]
strandsMV = Array{Float64}[]
for seed_number ∈ cnfg.first_seed:cnfg.last_seed
    if CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:T] != cnfg.end_time
        continue
    end
    push!(strands00, CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame).Rt)
    push!(strands0V, CSV.read(import_dir * scenario.name * "/0V" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame).Rt)
    push!(strandsM0, CSV.read(import_dir * scenario.name * "/M0" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame).Rt)
    push!(strandsMV, CSV.read(import_dir * scenario.name * "/MV" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame).Rt)
end

plot!(plot_RT00, strands00, color = :black, label = :none); png(export_dir * "마 00.png")
plot!(plot_RT0V, strands0V, color = :red, label = :none); png(export_dir * "마 0V.png")
plot!(plot_RTM0, strandsM0, color = :blue, label = :none); png(export_dir * "마 M0.png")
plot!(plot_RTMV, strandsMV, color = :purple, label = :none); png(export_dir * "마 MV.png")

plot(plot_RT00, plot_RT0V, plot_RTM0, plot_RTMV, layout = (4,1), size = (800,900))
png(export_dir * "마.png")
@time using CSV, XLSX, DataFrames, StatsBase
@time using Plots, LaTeXStrings, StatsPlots
default(markeralpha = 0.5, markerstrokewidth = 0)

schedules = DataFrame(XLSX.readtable("C:/Users/rmsms/OneDrive/lab/aespa//schedule.xlsx", "schedule")...)
import_dir = "D:/simulated/"
export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

todo = 1:50

plot_bifurcation = plot(legend = :outertopright, size = (700,500),
 xlabel = L"\sigma", ylabel = L"R(200)")
for doing ∈ todo
scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]

smry00 = DataFrame(T = Int64[], T0 = Int64[], RT1 = Int64[], VT1 = Int64[], RTend = Int64[], VTend = Int64[])
smry0V = DataFrame(T = Int64[], T0 = Int64[], RT1 = Int64[], VT1 = Int64[], RTend = Int64[], VTend = Int64[])
smryM0 = DataFrame(T = Int64[], T0 = Int64[], RT1 = Int64[], VT1 = Int64[], RTend = Int64[], VTend = Int64[])
smryMV = DataFrame(T = Int64[], T0 = Int64[], RT1 = Int64[], VT1 = Int64[], RTend = Int64[], VTend = Int64[])
for seed_number ∈ cnfg.first_seed:cnfg.last_seed
    if CSV.read(import_dir * scenario.name * "/00/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:T] != cnfg.end_time
        continue
    end
    push!(smry00, CSV.read(import_dir * scenario.name * "/00/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
    push!(smry0V, CSV.read(import_dir * scenario.name * "/0V/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
    push!(smryM0, CSV.read(import_dir * scenario.name * "/M0/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
    push!(smryMV, CSV.read(import_dir * scenario.name * "/MV/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
end

scatter!(plot_bifurcation, repeat([cnfg.σ], length(smryMV.RTend)), smry00.RTend, color = :black, label = :none, markershape = :circle)
scatter!(plot_bifurcation, repeat([cnfg.σ], length(smryMV.RTend)), smry0V.RTend, color = :red, label = :none, markershape = :x)
scatter!(plot_bifurcation, repeat([cnfg.σ], length(smryMV.RTend)), smryM0.RTend, color = :blue, label = :none, markershape = :+)
scatter!(plot_bifurcation, repeat([cnfg.σ], length(smryMV.RTend)), smryMV.RTend, color = :purple, label = :none, markershape = :star5)

print(".")
end
png(plot_bifurcation, export_dir * "다.png")

# gif(animation, export_dir * "tevl.gif")
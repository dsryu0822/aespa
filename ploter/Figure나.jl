@time using CSV, XLSX, DataFrames
@time using Plots, LaTeXStrings, StatsPlots
default(markeralpha = 0.5, markerstrokewidth = 0)

schedules = DataFrame(XLSX.readtable("C:/Users/rmsms/OneDrive/lab/aespa//schedule.xlsx", "schedule")...)
import_dir = "D:/simulated/"
export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

todo = 1:50

animation = @animate for doing ∈ todo
scenario = schedules[doing,:]

cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
plot_cluster = plot(legend = :outertopright,
 xlims = (0,200), ylims = (0, 10000),
 xlable = L"T_{1}", ylabel = L"R(T_{1})",
 size = (700,500), title = "σ = $(cnfg.σ)")

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

@df smry00 scatter!(plot_cluster, :T0, :RT1, color = :black, label = "Null", markershape = :+)
@df smry0V scatter!(plot_cluster, :T0, :RT1, color = :red, label = "vaccin only", markershape = :hexagon)
@df smryM0 scatter!(plot_cluster, :T0, :RT1, color = :blue, label = "control only", markershape = :diamond)
@df smryMV scatter!(plot_cluster, :T0, :RT1, color = :purple, label = "Full", markershape = :star5)

png(plot_cluster, export_dir * scenario.name * " 나.png")
println()
end

gif(animation, export_dir * "나.gif", fps = 4)
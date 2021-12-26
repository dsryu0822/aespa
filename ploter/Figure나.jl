@time include("FigureSetting.jl")

default(markeralpha = 0.5, markerstrokewidth = 0)

todo = 1:50

animation = @animate for doing ∈ todo
scenario = schedules[doing,:]

cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
plot_cluster = plot(legend = :outertopright,
#  xlims = (0,200), ylims = (0, 100000),
 xlable = L"T_{1}", ylabel = L"R(200)",
 size = (700,500), title = "σ = $(cnfg.σ)")

smry00 = DataFrame(Tend = Int64[], Rend = Int64[], peaktime = Int64[], peaksize = Int64[], T1 = Int64[], RT1 = Int64[], VT1 = Int64[])
smry0V = DataFrame(Tend = Int64[], Rend = Int64[], peaktime = Int64[], peaksize = Int64[], T1 = Int64[], RT1 = Int64[], VT1 = Int64[])
smryM0 = DataFrame(Tend = Int64[], Rend = Int64[], peaktime = Int64[], peaksize = Int64[], T1 = Int64[], RT1 = Int64[], VT1 = Int64[])
smryMV = DataFrame(Tend = Int64[], Rend = Int64[], peaktime = Int64[], peaksize = Int64[], T1 = Int64[], RT1 = Int64[], VT1 = Int64[])
for seed_number ∈ cnfg.first_seed:cnfg.last_seed
    if CSV.read(import_dir * scenario.name * "/00/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:Tend] < 200
        continue
    end
    push!(smry00, CSV.read(import_dir * scenario.name * "/00/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
    push!(smry0V, CSV.read(import_dir * scenario.name * "/0V/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
    push!(smryM0, CSV.read(import_dir * scenario.name * "/M0/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
    push!(smryMV, CSV.read(import_dir * scenario.name * "/MV/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
end

@df smry00 scatter!(plot_cluster, :peaktime, :peaksize, color = :black, label = "Null", markershape = :+)
@df smry0V scatter!(plot_cluster, :peaktime, :peaksize, color = colorant"#C00000", label = "vaccin only", markershape = :hexagon)
@df smryM0 scatter!(plot_cluster, :peaktime, :peaksize, color = colorant"#0070C0", label = "control only", markershape = :diamond)
@df smryMV scatter!(plot_cluster, :peaktime, :peaksize, color = colorant"#7030A0", label = "Full", markershape = :star5)

png(export_dir * "나 " * scenario.name * ".png")
print(".")
end

gif(animation, export_dir * "나.gif", fps = 4)
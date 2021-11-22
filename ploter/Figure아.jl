include("FigureSetting.jl")

todo = [3,9,27]

doing = 27
seed_number = 2
scenario = schedules[doing,:]
    cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]

tevl00 = CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
ndwf00 = CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) ndwf.csv", DataFrame)

tevlM0 = CSV.read(import_dir * scenario.name * "/M0" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
ndwfM0 = CSV.read(import_dir * scenario.name * "/M0" * "/$(lpad(seed_number, 4, '0')) ndwf.csv", DataFrame)

plot_ForceOfInfection = plot(title = "Force of Infection SI, σ = $(cnfg.σ)")
plot!(ndwf00.x4, color = color_["00"], label = "00, node 4")
plot!(ndwf00.x5, color = color_["00"], label = "00, node 5")
plot!(ndwfM0.x4, color = color_["M0"], label = "M0, node 4")
plot!(ndwfM0.x5, color = color_["M0"], label = "M0, node 5")
png(export_dir * "아 $(cnfg.σ) (a).png")

plot_Flux00 = plot()
plot!(tevl00.S_influx_, color = color_["00"], label = "00, Influx")
plot!(tevl00.S_outflux_, color = color_["00"], label = "00, Outflux", ls = :dot)
plot_FluxM0 = plot()
plot!(tevlM0.S_influx_, color = color_["M0"], label = "M0, Influx")
plot!(tevlM0.S_outflux_, color = color_["M0"], label = "M0, Outflux", ls = :dot)
plot_Flux = plot(plot_Flux00, plot_FluxM0 ,plot_title = "Outflux, Influx on two hubs of S, σ = $(cnfg.σ)")
png(export_dir * "아 $(cnfg.σ) (b).png")

# plot_FluxRatio = plot(title = "FluxRatio = Outflux / Influx on two hubs of S, σ = $(cnfg.σ)")
# plot!(tevl00.S_influx_ ./ tevl00.S_outflux_, color = color_["00"], label = "00")
# plot!(tevlM0.S_influx_ ./ tevlM0.S_outflux_, color = color_["M0"], label = "M0")
# png(export_dir * "아 $(cnfg.σ) (c).png")

doing = 9
seed_number = 3
scenario = schedules[doing,:]
    cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]

tevl00 = CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
ndwf00 = CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) ndwf.csv", DataFrame)

tevlM0 = CSV.read(import_dir * scenario.name * "/M0" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
ndwfM0 = CSV.read(import_dir * scenario.name * "/M0" * "/$(lpad(seed_number, 4, '0')) ndwf.csv", DataFrame)

plot_ForceOfInfection = plot(title = "Force of Infection SI, σ = $(cnfg.σ)")
plot!(ndwf00.x4, color = color_["00"], label = "00, node 4")
plot!(ndwf00.x5, color = color_["00"], label = "00, node 5")
plot!(ndwfM0.x4, color = color_["M0"], label = "M0, node 4")
plot!(ndwfM0.x5, color = color_["M0"], label = "M0, node 5")
png(export_dir * "아 $(cnfg.σ) (a).png")

plot_Flux00 = plot()
plot!(tevl00.S_influx_, color = color_["00"], label = "00, Influx")
plot!(tevl00.S_outflux_, color = color_["00"], label = "00, Outflux", ls = :dot)
plot_FluxM0 = plot()
plot!(tevlM0.S_influx_, color = color_["M0"], label = "M0, Influx")
plot!(tevlM0.S_outflux_, color = color_["M0"], label = "M0, Outflux", ls = :dot)
plot_Flux = plot(plot_Flux00, plot_FluxM0, plot_title = "Outflux, Influx on two hubs of S, σ = $(cnfg.σ)")
png(export_dir * "아 $(cnfg.σ) (b).png")

# plot_FluxRatio = plot(title = "FluxRatio = Outflux / Influx on two hubs of S, σ = $(cnfg.σ)")
# plot!(tevl00.S_influx_ ./ tevl00.S_outflux_, color = color_["00"], label = "00")
# plot!(tevlM0.S_influx_ ./ tevlM0.S_outflux_, color = color_["M0"], label = "M0")
# png(export_dir * "아 $(cnfg.σ) (c).png")

doing = 3
seed_number = 1
scenario = schedules[doing,:]
    cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]

tevl00 = CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
ndwf00 = CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) ndwf.csv", DataFrame)

tevlM0 = CSV.read(import_dir * scenario.name * "/M0" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
ndwfM0 = CSV.read(import_dir * scenario.name * "/M0" * "/$(lpad(seed_number, 4, '0')) ndwf.csv", DataFrame)

plot_ForceOfInfection = plot(title = "Force of Infection SI, σ = $(cnfg.σ)")
plot!(ndwf00.x4, color = color_["00"], label = "00, node 4")
plot!(ndwf00.x5, color = color_["00"], label = "00, node 5")
plot!(ndwfM0.x4, color = color_["M0"], label = "M0, node 4")
plot!(ndwfM0.x5, color = color_["M0"], label = "M0, node 5")
png(export_dir * "아 $(cnfg.σ) (a).png")

plot_Flux00 = plot()
plot!(tevl00.S_influx_, color = color_["00"], label = "00, Influx")
plot!(tevl00.S_outflux_, color = color_["00"], label = "00, Outflux", ls = :dot)
plot_FluxM0 = plot()
plot!(tevlM0.S_influx_, color = color_["M0"], label = "M0, Influx")
plot!(tevlM0.S_outflux_, color = color_["M0"], label = "M0, Outflux", ls = :dot)
plot_Flux = plot(plot_Flux00, plot_FluxM0, plot_title = "Outflux, Influx on two hubs of S, σ = $(cnfg.σ)")
png(export_dir * "아 $(cnfg.σ) (b).png")

# plot_FluxRatio = plot(title = "FluxRatio = Outflux / Influx on two hubs of S, σ = $(cnfg.σ)")
# plot!(tevl00.S_influx_ ./ tevl00.S_outflux_, color = color_["00"], label = "00")
# plot!(tevlM0.S_influx_ ./ tevlM0.S_outflux_, color = color_["M0"], label = "M0")
# png(export_dir * "아 $(cnfg.σ) (c).png")

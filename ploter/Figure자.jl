include("FigureSetting.jl")
default(linewidth = 2)

doing = 09
seed_number = 3
scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]

tevl0V = CSV.read(import_dir * scenario.name * "/0V" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
plot(title = "σ = $(cnfg.σ)")
plot!(tevl0V.S_influx_, color = color_["0V"], label = "0V, S_influx")
plot!(tevl0V.I_outflux_ .+ tevl0V.E_outflux_, color = color_["0V"], label = "0V, I+E_outflux")

tevlMV = CSV.read(import_dir * scenario.name * "/MV" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
plot(title = "σ = $(cnfg.σ)")
plot!(tevlMV.S_influx_, color = color_["MV"], label = "MV, S_influx")
plot!(tevlMV.I_outflux_ .+ tevlMV.E_outflux_, color = color_["MV"], label = "MV, I+E_outflux")

plot(title = "σ = $(cnfg.σ)")
plot!(tevl0V.n_E_, color = color_["0V"], label = "0V, n_E")
plot!(tevlMV.n_E_, color = color_["MV"], label = "MV, n_E")

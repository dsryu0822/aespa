include("FigureSetting.jl")

default(ylabel = "Relative Frequency", markerstrokewidth = 0, ylims = (0,0.6))

doing = 254
scenario = schedules[doing,:]

가아254 = plot(size = (400,400), legend = :topleft)

for k in ["00", "0V", "M0", "MV"]

relative_frequency = zeros(scenario.N)
for seed_number in scenario.first_seed:scenario.last_seed
    if CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:Tend] < 100 # cnfg.end_time
        continue
    end
    ndwi = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndwi.csv", DataFrame) |> Matrix
    relative_frequency += over50(ndwi)
end

relative_frequency = relative_frequency ./ scenario.last_seed
scatter!(가아254, ntwk.closeness, relative_frequency,
    label = k, xlabel = "closeness", title = "σ = $(scenario.σ)",
    markeralpha = 0.5, markershape = shape_[k], markercolor = color_[k])

end

png(가아254, export_dir * "가아254.png")

# -------------------------------------

doing = 270
scenario = schedules[doing,:]

가아270 = plot(size = (400,400), legend = :topleft)

for k in ["00", "0V", "M0", "MV"]

relative_frequency = zeros(scenario.N)
for seed_number in scenario.first_seed:scenario.last_seed
    if CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:Tend] < 100 # cnfg.end_time
        continue
    end
    ndwi = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndwi.csv", DataFrame) |> Matrix
    relative_frequency += over50(ndwi)
end

relative_frequency = relative_frequency ./ scenario.last_seed
scatter!(가아270, ntwk.closeness, relative_frequency,
    label = k, xlabel = "closeness", title = "σ = $(scenario.σ)",
    markeralpha = 0.5, markershape = shape_[k], markercolor = color_[k])

end

png(가아270, export_dir * "가아270.png")
include("FigureSetting.jl")

default(ylims = (0,700), yticks = [50, 350, 700])
seed_number = 11

doing = 255

k = "0V"
scenario = schedules[doing,:]
ndwi = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndwi.csv", DataFrame) |> Matrix
가마0V255 = plot(ndwi[1:200,over50(ndwi)], linewidth = 2, label = :none, alpha = 0.5, color = color_[k])#, fill = 0, fillalpha = 0.1); 가마255

k = "MV"
scenario = schedules[doing,:]
ndwi = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndwi.csv", DataFrame) |> Matrix
가마MV255 = plot(ndwi[1:200,over50(ndwi)], linewidth = 2, label = :none, alpha = 0.5, color = color_[k])#, fill = 0, fillalpha = 0.1); 가마255

가마255 = plot(가마0V255, 가마MV255, layout = (2,1))

doing = 275

k = "0V"
scenario = schedules[doing,:]
ndwi = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndwi.csv", DataFrame) |> Matrix
가마0V275 = plot(ndwi[1:200,over50(ndwi)], linewidth = 2, label = :none, alpha = 0.5, color = color_[k])#, fill = 0, fillalpha = 0.1); 가마255

k = "MV"
scenario = schedules[doing,:]
ndwi = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndwi.csv", DataFrame) |> Matrix
가마MV275 = plot(ndwi[1:200,over50(ndwi)], linewidth = 2, label = :none, alpha = 0.5, color = color_[k])#, fill = 0, fillalpha = 0.1); 가마255

가마275 = plot(가마0V275, 가마MV275, layout = (2,1))

가마 = plot(가마255, 가마275, plot_title = "")
png(가마, export_dir * "가마.png")
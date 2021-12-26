include("FigureSetting.jl")

default()
default(linewidth = 2, size = (600,200), legend = :none,
 xticks = 0:50:200, xlims = (0,200))


doing = 260
seed_number = 9

k = "00"

절대 = plot(ylabel = "Number")
상대 = plot(yticks = [0,1], ylims = (0,1), ylabel = "Proportion")

scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)

plot!(절대, tevl.n_E_, color = te_color_["E"], label = "E", linestyle = :dash)
plot!(절대, tevl.n_I_, color = te_color_["I"], label = "I")

plot!(상대, tevl.n_S_ ./ cnfg.n, color = te_color_["S"], label = "S")
plot!(상대, tevl.n_R_ ./ cnfg.n, color = te_color_["R"], label = "R")
plot!(상대, tevl.n_V_ ./ cnfg.n, color = te_color_["V"], label = "V")

plot(절대,상대, left_margin = 16px, size = (800,200))
png(export_dir * "가다" * k * ".png")


k = "M0"

절대 = plot(ylabel = "Number")
상대 = plot(yticks = [0,1], ylims = (0,1), ylabel = "Proportion")

scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)

plot!(절대, tevl.n_E_, color = te_color_["E"], label = "E", linestyle = :dash)
plot!(절대, tevl.n_I_, color = te_color_["I"], label = "I")

plot!(상대, tevl.n_S_ ./ cnfg.n, color = te_color_["S"], label = "S")
plot!(상대, tevl.n_R_ ./ cnfg.n, color = te_color_["R"], label = "R")
plot!(상대, tevl.n_V_ ./ cnfg.n, color = te_color_["V"], label = "V")

plot(절대,상대, left_margin = 16px, size = (800,200))
png(export_dir * "가다" * k * ".png")


k = "MV"

절대 = plot(ylabel = "Number", ylims = (0,1000))
상대 = plot(yticks = [0,1], ylims = (0,1), ylabel = "Proportion")

scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)

plot!(절대, tevl.n_E_, color = te_color_["E"], label = "E", linestyle = :dash)
plot!(절대, tevl.n_I_, color = te_color_["I"], label = "I")

plot!(상대, tevl.n_S_ ./ cnfg.n, color = te_color_["S"], label = "S")
plot!(상대, tevl.n_R_ ./ cnfg.n, color = te_color_["R"], label = "R")
plot!(상대, tevl.n_V_ ./ cnfg.n, color = te_color_["V"], label = "V")

plot(절대,상대, left_margin = 16px, size = (800,216), xlabel = L"T", bottom_margin = 16px)
png(export_dir * "가다" * k * ".png")
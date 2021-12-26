include("FigureSetting.jl")

default()

function whyihavetodothis(seed_number, k)
    ndws = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndws.csv", DataFrame)
    ndwi = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndwi.csv", DataFrame)
    ndwsdivndwi = ndws ./ ndwi
    ndwsdivndwi = ifelse.(isnan.(ndwsdivndwi), 0, ndwsdivndwi)
    return sum(Matrix(ndwsdivndwi), dims = 2)
end

seed_number = 11

doing = 255

가라255 = plot()

k = "0V"
scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)
plot!(가라255, tevl.n_I_, fill = 0, fillalpha = 0.5, linewidth = 2, color = color_[k], label = label_[k])
# plot!(가라255, whyihavetodothis(seed_number, k), fill = 0, fillalpha = 0.5, linewidth = 2, color = color_[k], label = label_[k], xlims = (0,300))


k = "MV"
scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)
plot!(가라255, tevl.n_I_, fill = 0, fillalpha = 0.5, linewidth = 2, color = color_[k], label = label_[k])
# plot!(가라255, whyihavetodothis(seed_number, k), fill = 0, fillalpha = 0.5, linewidth = 2, color = color_[k], label = label_[k], xlims = (0,300))


doing = 275

가라275 = plot()

k = "0V"
scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)
plot!(가라275, tevl.n_I_, fill = 0, fillalpha = 0.5, linewidth = 2, color = color_[k], label = label_[k])
# plot!(가라275, whyihavetodothis(seed_number, k), fill = 0, fillalpha = 0.5, linewidth = 2, color = color_[k], label = label_[k], xlims = (0,300))

k = "MV"
scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)
plot!(가라275, tevl.n_I_, fill = 0, fillalpha = 0.5, linewidth = 2, color = color_[k], label = label_[k])
# plot!(가라275, whyihavetodothis(seed_number, k), fill = 0, fillalpha = 0.5, linewidth = 2, color = color_[k], label = label_[k], xlims = (0,300))

plot(가라255, 가라275, layout = (1,2), size = (1200,300))


# plot!(절대, tevl.n_E_, color = te_color_["E"], label = "E", linestyle = :dash)
# plot!(절대, tevl.n_I_, color = te_color_["I"], label = "I")

# plot!(상대, tevl.n_S_ ./ cnfg.n, color = te_color_["S"], label = "S")
# plot!(상대, tevl.n_R_ ./ cnfg.n, color = te_color_["R"], label = "R")
# plot!(상대, tevl.n_V_ ./ cnfg.n, color = te_color_["V"], label = "V")

# plot(절대,상대, left_margin = 16px, size = (800,200))
# png(export_dir * "가다" * k * ".png")



# 절대 = plot(ylabel = "Number")
# 상대 = plot(yticks = [0,1], ylims = (0,1), ylabel = "Proportion")

# scenario = schedules[doing,:]
# cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
# tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
# smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)

# plot!(절대, tevl.n_E_, color = te_color_["E"], label = "E", linestyle = :dash)
# plot!(절대, tevl.n_I_, color = te_color_["I"], label = "I")

# plot!(상대, tevl.n_S_ ./ cnfg.n, color = te_color_["S"], label = "S")
# plot!(상대, tevl.n_R_ ./ cnfg.n, color = te_color_["R"], label = "R")
# plot!(상대, tevl.n_V_ ./ cnfg.n, color = te_color_["V"], label = "V")

# plot(절대,상대, left_margin = 16px, size = (800,200))
# png(export_dir * "가다" * k * ".png")


# k = "MV"

# 절대 = plot(ylabel = "Number", ylims = (0,1000))
# 상대 = plot(yticks = [0,1], ylims = (0,1), ylabel = "Proportion")

# scenario = schedules[doing,:]
# cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
# tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
# smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)

# plot!(절대, tevl.n_E_, color = te_color_["E"], label = "E", linestyle = :dash)
# plot!(절대, tevl.n_I_, color = te_color_["I"], label = "I")

# plot!(상대, tevl.n_S_ ./ cnfg.n, color = te_color_["S"], label = "S")
# plot!(상대, tevl.n_R_ ./ cnfg.n, color = te_color_["R"], label = "R")
# plot!(상대, tevl.n_V_ ./ cnfg.n, color = te_color_["V"], label = "V")

# plot(절대,상대, left_margin = 16px, size = (800,216), xlabel = L"T", bottom_margin = 16px)
# png(export_dir * "가다" * k * ".png")
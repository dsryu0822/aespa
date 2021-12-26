include("FigureSetting.jl")

default(xlims = (0,200), linewidth = 2, alpha = 0.5, label = :none)

seed_number = 11

doing = 255

k = "M0"
scenario = schedules[doing,:]
tevl = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
ndwi = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) ndwi.csv", DataFrame) |> Matrix

plot(
    plot(tevl.n_I_, color = color_[k], ylabel = L"I(T)"),
    plot(ndwi, xlabel = L"T", color = color_[k], ylabel = L"I_{u}(T)"),
    layout = (2,1), size = (400, 400))

png(export_dir * "가바.png")
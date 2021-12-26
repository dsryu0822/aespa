include("FigureSetting.jl")

todo = 251:275
σ_axis = schedules.σ[todo]

default(markeralpha = 0.5, markerstrokewidth = 0,
 xticks = [0.02, 0.072, 0.1], yticks = 0:0.2:0.6, ylims = (0,0.7),
 legend = :right, size = (600,300),
 xlabel = L"\sigma", ylabel = L"R(\infty) / n")

하 = plot()
가가 = plot()

for k ∈ ["00", "0V", "M0", "MV"]

Q₃  = zeros(length(todo))
M   = zeros(length(todo))
Q₁  = zeros(length(todo))

for (sigma, doing) ∈ enumerate(todo)
    scenario = schedules[doing,:]
    cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
    raw = CSV.read(import_dir * scenario.name * "/00/0001 smry.csv", DataFrame)[[false],:]
    for seed_number ∈ cnfg.first_seed:cnfg.last_seed
        if CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:Tend] < 100 # cnfg.end_time
            continue
        end
        push!(raw, CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
    end
    Q₁[sigma] , M[sigma], Q₃[sigma] = quantile(raw.Rend ./ cnfg.n, [.10, .50, .90])
    
    num_raw = nrow(raw)
    σ_vertical = repeat([cnfg.σ], num_raw)
    scatter!(하, σ_vertical, raw.Rend ./ cnfg.n, alpha = 0.5, color = color_[k], label = :none, markershape = shape_[k])
    print(".")
end
plot!(가가, σ_axis, Q₃, fillrange = Q₁, linealpha = 0, label = :none, color = color_[k], alpha = 0.2)
plot!(가가, σ_axis, M, label = label_[k], color = color_[k], markershape = shape_[k], alpha = 0.5)
plot!(하, σ_axis, Q₃, fillrange = Q₁, linealpha = 0, label = :none, color = color_[k], alpha = 0.2)
plot!(하, σ_axis, M, label = label_[k], color = color_[k], markershape = shape_[k], alpha = 0.5)

println()
end
png(하, export_dir * "하.png")
png(가가, export_dir * "가가.png")
include("FigureSetting.jl")

todo = 201:250
σ_axis = schedules.σ[todo]

default(markeralpha = 0.5, markerstrokewidth = 0,
 xaxis = :log, xticks = 10 .^[-3.,-2.,-1.], yticks = 0:0.2:0.6, ylims = (0,0.7),
 legend = :topleft, size = (600,300),
 xlabel = L"\sigma", ylabel = L"R(\infty) / n")


차 = plot()
카 = plot()
타 = plot()

Q₃  = zeros(length(todo))
M   = zeros(length(todo))
Q₁  = zeros(length(todo))

for k ∈ ["00", "0V", "M0", "MV"]
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
    Q₁[sigma] , M[sigma], Q₃[sigma] = quantile(raw.RTend ./ cnfg.n, [.10, .50, .90])
    
    num_raw = nrow(raw)
    σs = repeat([cnfg.σ], num_raw)
    scatter!(차, σs, raw.RTend ./ cnfg.n, alpha = 0.5, color = color_[k], label = :none, markershape = shape_[k])
    if k[[1]] == "M"
        scatter!(타, σs ./ 10, raw.RTend ./ cnfg.n, alpha = 0.5, color = color_[k], label = :none, markershape = shape_[k])
    else
        scatter!(타, σs, raw.RTend ./ cnfg.n, alpha = 0.5, color = color_[k], label = :none, markershape = shape_[k])
    end

    print(".")
end
println(k)
plot!(카, σ_axis, Q₃, fillrange = Q₁, linealpha = 0, label = :none, color = color_[k], alpha = 0.2)
plot!(카, σ_axis, M, label = label_[k], color = color_[k], markershape = shape_[k], alpha = 0.5)
end

png(차, export_dir * "차.png")
png(카, export_dir * "카.png")
png(타, export_dir * "타.png")
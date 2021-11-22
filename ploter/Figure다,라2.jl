@time include("FigureSetting.jl")

default(markeralpha = 0.5, markerstrokewidth = 0,
 xticks = 0:0.2:0.6, yticks = 0:0.2:0.6, ylims = (0,0.7),
 legend = :outertopright, size = (700,500),
 xlabel = L"\sigma", ylabel = L"R(\infty) / n")
default()


todo = (1:50) .+ 0

plot_bifurcation1 = plot()
plot_bifurcation2 = plot()
println("ready")

for k ∈ ["00", "0V", "M0", "MV"]

Q₃  = zeros(length(todo))
M   = zeros(length(todo))
Q₁  = zeros(length(todo))

for (sigma, doing) ∈ enumerate(todo)
    scenario = schedules[doing,:]
    cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
    raw = DataFrame(Tend = Int64[], RTend = Int64[], peaktime = Int64[], peaksize = Int64[],
     incidence5 = Int64[], incidence4 = Int64[], HIR = Float64[],
     T1 = Int64[], RT1 = Int64[], VT1 = Int64[])
    for seed_number ∈ cnfg.first_seed:cnfg.last_seed
        if CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:Tend] < 100 # cnfg.end_time
            continue
        end
        push!(raw, CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:])
    end
    # Q₁[sigma] , M[sigma], Q₃[sigma] = quantile(raw.RTend ./ cnfg.n, [.10, .50, .90])
    Q₁[sigma] , M[sigma], Q₃[sigma] = quantile(raw.peaksize, [.10, .50, .90])
    
    num_raw = nrow(raw)
    σ_axis = repeat([cnfg.σ], num_raw)
    # scatter!(plot_bifurcation1, σ_axis, raw.RTend ./ cnfg.n, alpha = 0.5, color = color_[k], label = :none, markershape = shape_[k])
    scatter!(plot_bifurcation1, σ_axis, raw.peaksize, alpha = 0.5, color = color_[k], label = :none, markershape = shape_[k])
    print(".")
end
# IQR = Q₃ - Q₁
# U   = Q₃ + 1.5IQR
# L   = Q₁ - 1.5IQR
plot!(plot_bifurcation2, 0.01:0.01:0.5, Q₃, fillrange = Q₁, linealpha = 0, label = :none, color = color_[k], alpha = 0.2)
plot!(plot_bifurcation2, 0.01:0.01:0.5, M, label = k, color = color_[k], markershape = shape_[k], alpha = 0.5)

println()
end
png(plot_bifurcation1, export_dir * "다 peaksize.png")
png(plot_bifurcation2, export_dir * "라 peaksize.png")

# plot(0.01:0.01:0.5, Q₃)

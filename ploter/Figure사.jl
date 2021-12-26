@time include("FigureSetting.jl")

default(markeralpha = 0.5, markerstrokewidth = 0)

todo = (1:10) .+ 0

plot_bifurcation1 = plot(legend = :outertopright, size = (700,500),
 xlabel = L"\sigma", ylabel = L"HIR")
plot_bifurcation2 = plot(legend = :outertopright, size = (700,500),
 xlabel = L"\sigma", ylabel = L"HIR")
println("ready")

for k ∈ keys(color_)

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
    # println(quantile(raw.Rend ./ cnfg.n, [.25, .50, .75]))
    Q₁[sigma] , M[sigma], Q₃[sigma] = quantile(raw.HIR, [.25, .50, .75])
    
    num_raw = nrow(raw)
    σ_axis = repeat([cnfg.σ], num_raw)
    scatter!(plot_bifurcation1, σ_axis, raw.HIR, alpha = 0.5, color = color_[k], label = :none, markershape = shape_[k])
    print(".")
end


IQR = Q₃ - Q₁
U   = Q₃ + 1.5IQR
L   = Q₁ - 1.5IQR

plot!(plot_bifurcation2, 0.01:0.01:0.1, Q₃, fillrange = Q₁, linealpha = 0, label = :none, color = color_[k], alpha = 0.2)
# plot!(plot_bifurcation2, U, fillrange = L, linealpha = 0, label = :none, color = color_[k], alpha = 0.2)
plot!(plot_bifurcation2, 0.01:0.01:0.1, M, label = k, color = color_[k], markershape = shape_[k], alpha = 0.5)
# quantile(smry00.Rend ./ cnfg.n, [.25, .50, .75])
println()
end
png(plot_bifurcation1, export_dir * "사.png")
png(plot_bifurcation2, export_dir * "사2.png")  

# gif(animation, export_dir * "tevl.gif")
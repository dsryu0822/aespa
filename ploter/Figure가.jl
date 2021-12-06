@time include("FigureSetting.jl")

default(xlims = (0,1000), xticks = 0:200:1000, linealpha = 0.2, linewidth = 2)

todo = 1:50

animation = @animate for doing ∈ todo
scenario = schedules[doing,:]

cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
plot_tevl_I = plot(legend = :topright,
 ylims = (0, 7500), yticks = 0:2500:7500,
 ylabel = L"\textrm{Number\ of\ Cases\ } I(T)", title = "σ = $(cnfg.σ)")
plot_tevl_R = plot(legend = :none, ylims = (0, 0.7), yticks = 0:0.2:0.7,
 xlabel = L"T", ylabel = L"\textrm{Cummulative\ Cases\ } R(T)")

plot!(plot_tevl_I, -2:-1, color = :black, label = "No control",
 markershape = :square, markerstrokewidth = 0, markeralpha = 0.5)
plot!(plot_tevl_I, -2:-1, color = colorant"#C00000", label = "Vaccination",
 markershape = :square, markerstrokewidth = 0, markeralpha = 0.5)
plot!(plot_tevl_I, -2:-1, color = colorant"#0070C0", label = "Restriction",
 markershape = :square, markerstrokewidth = 0, markeralpha = 0.5)
plot!(plot_tevl_I, -2:-1, color = colorant"#7030A0", label = "Both control",
 markershape = :square, markerstrokewidth = 0, markeralpha = 0.5)

# legend_flag = false
for seed_number ∈ cnfg.first_seed:cnfg.last_seed
    smry = CSV.read(import_dir * scenario.name * "/00/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:]
    if smry.Tend > 100
        print("O")
    else
        print("X")
    end
    tevl00 = CSV.read(import_dir * scenario.name * "/00/" * "$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
    tevl0V = CSV.read(import_dir * scenario.name * "/0V/" * "$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
    tevlM0 = CSV.read(import_dir * scenario.name * "/M0/" * "$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
    tevlMV = CSV.read(import_dir * scenario.name * "/MV/" * "$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)

    plot!(plot_tevl_I, tevl00.n_I_, color = :black, label = :none)
    plot!(plot_tevl_I, tevl0V.n_I_, color = colorant"#C00000", label = :none)
    plot!(plot_tevl_I, tevlM0.n_I_, color = colorant"#0070C0", label = :none)
    plot!(plot_tevl_I, tevlMV.n_I_, color = colorant"#7030A0", label = :none)
    
    plot!(plot_tevl_R, tevl00.n_R_ ./ cnfg.n, color = :black)
    plot!(plot_tevl_R, tevl0V.n_R_ ./ cnfg.n, color = colorant"#C00000")
    plot!(plot_tevl_R, tevlM0.n_R_ ./ cnfg.n, color = colorant"#0070C0")
    plot!(plot_tevl_R, tevlMV.n_R_ ./ cnfg.n, color = colorant"#7030A0")
end

plot(plot_tevl_I, plot_tevl_R, layout = (2,1))
png(export_dir * "가 " * scenario.name * ".png")
println()
end

gif(animation, export_dir * "가.gif", fps = 4)
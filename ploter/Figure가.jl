@time using CSV, XLSX, DataFrames
@time using Plots, LaTeXStrings
default()
default(xlims = (0,1000), xticks = 0:200:1000, linealpha = 0.2, linewidth = 2)

schedules = DataFrame(XLSX.readtable("C:/Users/rmsms/OneDrive/lab/aespa//schedule.xlsx", "schedule")...)
import_dir = "D:/simulated/"
export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

todo = 1:50

animation = @animate for doing ∈ todo
scenario = schedules[doing,:]

cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
plot_tevl_I = plot(legend = :topright,
 ylims = (0, 7500), yticks = 0:2500:7500,
 ylabel = L"I(T)", title = "σ = $(cnfg.σ)")
plot_tevl_R = plot(legend = :none, ylims = (0, 0.7), yticks = 0:0.2:0.7,
 xlabel = L"T", ylabel = L"R(T)")

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

    # if !legend_flag
    #     plot!(plot_tevl_I, tevl00.I, color = :black, label = "No control")
    #     plot!(plot_tevl_I, tevl0V.I, color = colorant"#C00000", label = "Vaccination")
    #     plot!(plot_tevl_I, tevlM0.I, color = colorant"#0070C0", label = "Restriction")
    #     plot!(plot_tevl_I, tevlMV.I, color = colorant"#7030A0", label = "Both control")
    #     legend_flag = true
    # else
        plot!(plot_tevl_I, tevl00.I, color = :black, label = :none)
        plot!(plot_tevl_I, tevl0V.I, color = colorant"#C00000", label = :none)
        plot!(plot_tevl_I, tevlM0.I, color = colorant"#0070C0", label = :none)
        plot!(plot_tevl_I, tevlMV.I, color = colorant"#7030A0", label = :none)
    # end
    
    plot!(plot_tevl_R, tevl00.R ./ cnfg.n, color = :black)
    plot!(plot_tevl_R, tevl0V.R ./ cnfg.n, color = colorant"#C00000")
    plot!(plot_tevl_R, tevlM0.R ./ cnfg.n, color = colorant"#0070C0")
    plot!(plot_tevl_R, tevlMV.R ./ cnfg.n, color = colorant"#7030A0")
end

plot(plot_tevl_I, plot_tevl_R, layout = (2,1))
png(export_dir * "가 " * scenario.name * ".png")
println()
end

gif(animation, export_dir * "가.gif", fps = 4)
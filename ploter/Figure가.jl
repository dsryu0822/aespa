@time using CSV, XLSX, DataFrames
@time using Plots, LaTeXStrings

schedules = DataFrame(XLSX.readtable("C:/Users/rmsms/OneDrive/lab/aespa//schedule.xlsx", "schedule")...)
import_dir = "D:/simulated/"
export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

todo = 1:50

animation = @animate for doing ∈ todo
scenario = schedules[doing,:]

cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]
plot_tevl_I = plot(legend = :topleft, ylims = (0, 10000), ylabel = L"I(T)", title = "σ = $(cnfg.σ)")
plot_tevl_R = plot(legend = :none, ylims = (0, 70000), ylabel = L"R(T)")
plot_tevl_Rt = plot(legend = :none, ylims = (0, 4), ylabel = L"\mathcal{R}_T")

legend_flag = false
for seed_number ∈ cnfg.first_seed:cnfg.last_seed
    smry = CSV.read(import_dir * scenario.name * "/00/" * "$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:]
    if smry.T == cnfg.end_time
        print("O")
    else
        print("X")
    end
    tevl00 = CSV.read(import_dir * scenario.name * "/00/" * "$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
    tevl0V = CSV.read(import_dir * scenario.name * "/0V/" * "$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
    tevlM0 = CSV.read(import_dir * scenario.name * "/M0/" * "$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
    tevlMV = CSV.read(import_dir * scenario.name * "/MV/" * "$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)

    if !legend_flag
        plot!(plot_tevl_I, tevl00.I, linealpha = 0.5, color = :black, label = "Null")
        plot!(plot_tevl_I, tevl0V.I, linealpha = 0.5, color = :red, label = "vaccin only")
        plot!(plot_tevl_I, tevlM0.I, linealpha = 0.5, color = :blue, label = "control only")
        plot!(plot_tevl_I, tevlMV.I, linealpha = 0.5, color = :purple, label = "Full")
        legend_flag = true
    else
        plot!(plot_tevl_I, tevl00.I, linealpha = 0.5, color = :black, label = :none)
        plot!(plot_tevl_I, tevl0V.I, linealpha = 0.5, color = :red, label = :none)
        plot!(plot_tevl_I, tevlM0.I, linealpha = 0.5, color = :blue, label = :none)
        plot!(plot_tevl_I, tevlMV.I, linealpha = 0.5, color = :purple, label = :none)
    end

    plot!(plot_tevl_R, tevl00.R, linealpha = 0.5, color = :black)
    plot!(plot_tevl_R, tevl0V.R, linealpha = 0.5, color = :red)
    plot!(plot_tevl_R, tevlM0.R, linealpha = 0.5, color = :blue)
    plot!(plot_tevl_R, tevlMV.R, linealpha = 0.5, color = :purple)
    
    # plot!(plot_tevl_Rt, tevl00.Rt, linealpha = 0.5, color = :black)
    # plot!(plot_tevl_Rt, tevl0V.Rt, linealpha = 0.5, color = :red)
    # plot!(plot_tevl_Rt, tevlM0.Rt, linealpha = 0.5, color = :blue)
    # plot!(plot_tevl_Rt, tevlMV.Rt, linealpha = 0.5, color = :purple)
end

plot(plot_tevl_I, plot_tevl_R, layout = (2,1))
# plot(plot_tevl_I, plot_tevl_R, plot_tevl_Rt, layout = (2,1), size = (400,800))
png(export_dir * "가 " * scenario.name * ".png")
println()
end

gif(animation, export_dir * "가.gif", fps = 4)
@time using CSV, XLSX, DataFrames, StatsBase, Statistics
@time using Plots, LaTeXStrings, StatsPlots
# default(markeralpha = 0.5, markerstrokewidth = 0)
default()
default(linealpha = 0.5, linewidth = 2, fillalpha = 0.2, 
 yticks = 0:2,
 label = :none, xlabel = L"T", ylabel = L"R_{T}", ylims = (0,2))

schedules = DataFrame(XLSX.readtable("C:/Users/rmsms/OneDrive/lab/aespa//schedule.xlsx", "schedule")...)
import_dir = "D:/simulated/"
export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

color_ = Dict("00" => :black, "0V" => colorant"#C00000", "M0" => colorant"#0070C0", "MV" => colorant"#7030A0")
shape_ = Dict("00" => :+, "0V" => :x, "M0" => :circle, "MV" => :star5)

# todo = (1:50) .+ 0

plot_RT00 = plot(legend = :none, size = (700,300),
 xlabel = L"T", ylabel = L"R_{T}")
plot_RT0V = plot(legend = :none, size = (700,300),
 xlabel = L"T", ylabel = L"R_{T}")
plot_RTM0 = plot(legend = :none, size = (700,300),
 xlabel = L"T", ylabel = L"R_{T}")
plot_RTMV = plot(legend = :none, size = (700,300),
 xlabel = L"T", ylabel = L"R_{T}")
println("ready")


doing = 5
scenario = schedules[doing,:]
cnfg = CSV.read(import_dir * scenario.name * "/cnfg.csv", DataFrame)[1,:]

strands00 = Array{Float64}[]
strands0V = Array{Float64}[]
strandsM0 = Array{Float64}[]
strandsMV = Array{Float64}[]
for seed_number ∈ cnfg.first_seed:cnfg.last_seed
    if CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:Tend] < 200
        continue
    end
    push!(strands00, CSV.read(import_dir * scenario.name * "/00" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame).Rt[1:200])
    push!(strands0V, CSV.read(import_dir * scenario.name * "/0V" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame).Rt[1:200])
    push!(strandsM0, CSV.read(import_dir * scenario.name * "/M0" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame).Rt[1:200])
    push!(strandsMV, CSV.read(import_dir * scenario.name * "/MV" * "/$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame).Rt[1:200])
end



function summarizer(array2d, func)
    n = length(array2d)
    m = length(array2d[1])
    
    column = []
    for i in 1:m
        row = []
        for j in 1:n
            push!(row, array2d[j][i])
        end
        push!(column, func(row))
    end
    return column
end

Q95(x) = quantile(x, .95)
Q05(x) = quantile(x, .05)


plot_RT00 = plot(summarizer(strands00, median), color = :black)
plot!(plot_RT00, summarizer(strands00, Q05), label = :none, color = :black,
 fill = summarizer(strands00, Q95), linewidth = 0)
png(export_dir * "마 00.png")

plot_RT0V = plot(summarizer(strands0V, median), color = colorant"#C00000")
plot!(plot_RT0V, summarizer(strands0V, Q05), label = :none, color = colorant"#C00000",
 fill = summarizer(strands00, Q95), linewidth = 0)
png(export_dir * "마 0V.png")

plot_RTM0 = plot(summarizer(strandsM0, median), color = colorant"#0070C0")
plot!(plot_RTM0, summarizer(strandsM0, Q05), label = :none, color = colorant"#0070C0",
 fill = summarizer(strands00, Q95), linewidth = 0)
png(export_dir * "마 M0.png")

plot_RTMV = plot(summarizer(strandsMV, median), color = colorant"#7030A0")
plot!(plot_RTMV, summarizer(strandsMV, Q05), label = :none, color = colorant"#7030A0",
 fill = summarizer(strandsMV, Q95), linewidth = 0)
png(export_dir * "마 MV.png")


# plot!(plot_RT00, strands00, color = :black, label = :none); png(export_dir * "마 00.png")
# plot!(plot_RT0V, strands0V, color = colorant"#C00000", label = :none); png(export_dir * "마 0V.png")
# plot!(plot_RTM0, strandsM0, color = colorant"#0070C0", label = :none); png(export_dir * "마 M0.png")
# plot!(plot_RTMV, strandsMV, color = colorant"#7030A0", label = :none); png(export_dir * "마 MV.png")

plot(plot_RT00, plot_RT0V, plot_RTM0, plot_RTMV, layout = (4,1), size = (800,900))
png(export_dir * "마.png")
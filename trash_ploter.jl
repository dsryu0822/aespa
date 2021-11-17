@time using Plots, LaTeXStrings
@time using CSV, DataFrames
@time using Statistics

default(alpha = 0.2)

last_seed = 30

directory = "D:/trash 0.20/"; cd(directory); println(pwd())
scenario_list = ["00", "0V", "M0", "MV"]
# scenario_list = ["00"]
scenario_color = Dict([
    "00" => :black,
    "0V" => colorant"#C00000",
    "M0" => colorant"#0070C0",
    "MV" => colorant"#7030A0"]
)
scenario_shape = Dict([
    "00" => :circle,
    "0V" => :utriangle,
    "M0" => :square,
    "MV" => :star]
)

l = @layout [[I; R; Rt] RV]

plot_tevl_I = plot(ylabel = L"I(T)")
plot_tevl_R = plot(ylabel = L"R(T)")
plot_tevl_Rt = plot(xlabel = L"T", ylabel = L"R_T")
plot_smry_RV = plot(xlabel = L"\#R", ylabel = L"\#V", size = (500,500))

plot_trng_I = plot(ylabel = L"I(T)")
plot_trng_R = plot(ylabel = L"R(T)")
plot_trng_Rt = plot(xlabel = L"T", ylabel = L"R_T")

tevl_I = zeros(200, last_seed)
tevl_R = zeros(200, last_seed)
tevl_Rt = zeros(200, last_seed)
smry_0V = zeros(last_seed, 2)
smry_MV = zeros(last_seed, 2)

for scenario_code ∈ scenario_list, seed_number ∈ 1:last_seed

temp_tevl = CSV.read("./$scenario_code//$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
if length(temp_tevl.I) != 200 continue end
tevl_I[:, seed_number] = temp_tevl.I
tevl_R[:, seed_number] = temp_tevl.R
tevl_Rt[:, seed_number] = temp_tevl.Rt

plot!(plot_tevl_I,
    temp_tevl.I,
    color = scenario_color[scenario_code],
    label = ""
)
plot!(plot_tevl_R,
    temp_tevl.R,
    color = scenario_color[scenario_code],
    label = ""
)
plot!(plot_tevl_Rt,
    temp_tevl.Rt,
    color = scenario_color[scenario_code],
    label = ""
)
if scenario_code == "0V" || scenario_code == "MV"
    temp_smry = CSV.read("./$scenario_code//$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)
    scatter!(plot_smry_RV,
        temp_smry.R/(10^5), temp_smry.V/(10^5),
        color = scenario_color[scenario_code],
        markershape = scenario_shape[scenario_code],
        label = "",
        markerstrokewidth = 0,
        alpha = 0.8
    )
    if scenario_code == "0V"
        smry_0V[seed_number, 1] = temp_smry.R[1]/(10^5)
        smry_0V[seed_number, 2] = temp_smry.V[1]/(10^5)
    end
    if scenario_code == "MV"
        smry_MV[seed_number, 1] = temp_smry.R[1]/(10^5)
        smry_MV[seed_number, 2] = temp_smry.V[1]/(10^5)
    end
end

if seed_number == last_seed
    mean_I = mean(tevl_I, dims = 2)
    std_I = std(tevl_I, dims = 2)
    plot!(plot_trng_I, mean_I + std_I, fillrange = mean_I - std_I,
    color = scenario_color[scenario_code], linealpha = 0.2,
    label = "")

    mean_R = mean(tevl_R, dims = 2)
    std_R = std(tevl_R, dims = 2)
    plot!(plot_trng_R, mean_R + std_R, fillrange = mean_R - std_R,
    color = scenario_color[scenario_code], linealpha = 0.2,
    label = "")

    mean_Rt = mean(tevl_Rt, dims = 2)
    std_Rt = std(tevl_Rt, dims = 2)
    plot!(plot_trng_Rt, mean_Rt + std_Rt, fillrange = mean_Rt - std_Rt,
    color = scenario_color[scenario_code], linealpha = 0.2,
    label = "")
end
end

plot_smry_RV; png(plot_smry_RV, "plot_smry_RV")

plot(
    plot_tevl_I,
    plot_tevl_R,
    plot_tevl_Rt,
    layout = (3,1), size = (600,800)
); png("plot_tevl")

plot(
    plot_trng_I,
    plot_trng_R,
    plot_trng_Rt,
    layout = (3,1), size = (600,800)
); png("plot_trng")

using StatsPlots
using Statistics
boxplot(smry_0V[:,2], color = colorant"#C00000", label = "0V", size = (400,400))
boxplot!(smry_MV[:,2], color = colorant"#7030A0", label = "MV")
png("box_V")

boxplot(smry_0V[:,1], color = colorant"#C00000", label = "0V", size = (400,400))
boxplot!(smry_MV[:,1], color = colorant"#7030A0", label = "MV")
png("box_R")

plot(rand(10), linealpha = 0)
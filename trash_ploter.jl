@time using Plots
@time using CSV, DataFrames
@time using LaTeXStrings

default(alpha = 0.2)

directory = "D:/trash/"; cd(directory); println(pwd())
scenario_list = ["00", "0V", "M0", "MV"]
# scenario_list = ["00"]
scenario_color = Dict([
    "00" => :black,
    "0V" => :red,
    "M0" => :blue,
    "MV" => :purple]
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

for seed_number ∈ 1:30, scenario_code ∈ scenario_list
temp_tevl = CSV.read("./$scenario_code//$(lpad(seed_number, 4, '0')) tevl.csv", DataFrame)
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
    if temp_smry.T0[1] < 150
        scatter!(plot_smry_RV,
            temp_smry.R/(10^5), temp_smry.V/(10^5),
            color = scenario_color[scenario_code],
            markershape = scenario_shape[scenario_code],
            label = "",
            markerstrokewidth = 0,
            alpha = 0.8
        )
    end
end
end

plot_smry_RV; png(plot_smry_RV, "plot_smry_RV")

plot(
    plot_tevl_I,
    plot_tevl_R,
    plot_tevl_Rt,
    layout = (3,1), size = (600,800)
); png("plot_tevl")
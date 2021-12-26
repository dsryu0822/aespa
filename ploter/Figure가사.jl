include("FigureSetting.jl")

using Dates

default(linewidth = 2, linealpha = 0.5)

DATA = CSV.read("../owid-covid-data.csv", DataFrame)
location_ = unique(DATA.location)
for location in location_
    print(location * ", ")
end
window = Date("2020-02-01") .< DATA.date .< Date("2020-09-30")

country_ = ["South Korea", "Japan", "China"]
excepted = ["Europe", "European Union", "North America"]


가사2 = plot(ylabel = "Incidence Cases", xlims = (0,200), ylims = (0,Inf), xlabel = L"T", legend = :outertopright)
TEMP = zeros(241)
for country in location_
    if country ∈ excepted continue end
    try
        temp = DATA[window .& (DATA.location .== country), :new_cases]
        MAX = maximum(temp)
        if MAX > 20000 continue end
        TEMP = TEMP .+ temp
        plot!(가사2, temp, label = MAX > 5000 ? country : :none)
    catch LoadError
        print(country)
    end
end
가사1 = plot(TEMP, xlims = (0,200), label = "sum of below    ", legend = :outertopright)
가사  = plot(가사1, 가사2, layout = (2,1))
png(가사, export_dir * "가사.png")
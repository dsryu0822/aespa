@time begin
using XLSX, CSV, DataFrames
excuted_DIR = string(@__DIR__)
schedule = DataFrame(XLSX.readtable(excuted_DIR * "/schedule.xlsx", "schedule"))

using Crayons
using Random, Distributions, Statistics, StatsBase
using Graphs, NearestNeighbors
using JLD
# using Plots

include("src/lemma.jl")
include("src/main.jl")

# ------------------------------------------------------------------ directory

root = "C:/simulated/"
if !isdir(root) mkpath(root) end
cd(root); pwd()

# ------------------------------------------------------------------ setting

export_type = :CSV # :both, :CSV, :XLSX
if isempty(ARGS)
    doing = 10
else
    doing = parse(Int64, ARGS[1])
end
scenario = schedule[doing,:]
try
    mkpath(root * scenario.name)
    CSV.write(root * scenario.name * "/cnfg.csv", DataFrame(scenario), bom = true)
    cd(root * scenario.name)
catch
    @warn "some error occur!"
end

# ------------------------------------------------------------------ parameters

global number_of_host = 1
global θ = 10
global n = 800000
global end_time = 500

global temp_code = scenario.temp_code
global first_seed = scenario.first_seed
global last_seed = scenario.last_seed
global blockade = scenario.blockade / 100
global T0 = scenario.T0
global σ = scenario.σ
global β = scenario.β

global latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
global recovery_period = Weibull(3, 7.17)
global develop_period = Exponential(100)

global ID = 1:n
global δ = 0.01

realnetwork = load(excuted_DIR * "\\data_link.jld")
global NODE0 = realnetwork["adj_encoded"]

data = CSV.read(excuted_DIR * "\\data_node.csv",DataFrame)
global N = nrow(data)
global NODE_ID = 1:N
global XY = convert.(Float16, vcat(data.Longitude', data.Latitude'))
global city = data.City
global country = data.Country
global iata = data.IATA

default(markerstrokewidth = 0, alpha = 0.5, markersize = 3, size = (800,400))
countrynames = data.Country |> unique |> sort

a = - 125/30; b = 45a + 75;
global atlantic = XY[2,:] .< (a .* XY[1,:]) .+ b
end
# print("$doing ")

for seed_number ∈ first_seed:last_seed
        simulation(
        seed_number)
end
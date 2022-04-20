# @time using Dates
@time using CSV, XLSX, DataFrames
excuted_DIR = string(@__DIR__)
schedule = DataFrame(XLSX.readtable(excuted_DIR * "/schedule.xlsx", "schedule")...)

@time using Crayons
@time using Random, Distributions, Statistics, StatsBase
@time using Graphs, NearestNeighbors
@time using Plots

@time include("src/lemma.jl")
@time include("src/main.jl")

# ------------------------------------------------------------------ directory

root = "D:/simulated/"
if !isdir(root)
    mkpath(root)
end
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
    # mkpath(root * scenario.name * "/00")
    # mkpath(root * scenario.name * "/0V")
    # mkpath(root * scenario.name * "/M0")
    # mkpath(root * scenario.name * "/MV")
    CSV.write(root * scenario.name * "/cnfg.csv", DataFrame(scenario), bom = true)
    cd(root * scenario.name)
catch
    @warn "some error occur!"
end

# ------------------------------------------------------------------ parameters

global number_of_host = 1
global θ = 10

global network = scenario.network
global σ = scenario.σ
# global e_σ = scenario.e_σ
# global p_V = scenario.p_V
# global e_V = scenario.e_V
global β = scenario.β
global n = scenario.n
global end_time = scenario.end_time
global first_seed = scenario.first_seed
global last_seed = scenario.last_seed

global latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
global recovery_period = Weibull(3, 7.17)

global ID = 1:n
global δ = 0.05
global brownian = MvNormal(2, δ) # moving process

if network == "data"
    using JLD
    realnetwork = load(excuted_DIR * "\\data_link.jld")
    global NODE = realnetwork["adj_encoded"]
    
    data = CSV.read(excuted_DIR * "\\data_node.csv",DataFrame)
    global N = nrow(data)
    global NODE_ID = 1:N
    global XY = vcat(data.Longitude', data.Latitude')
    global city = data.City
    global country = data.Country
    global iata = data.IATA
    default(markerstrokewidth = 0, alpha = 0.5, markersize = 3, size = (800,400))
    countrynames = data.Country |> unique |> sort
end

@time for seed_number ∈ first_seed:last_seed
        simulation(
        seed_number)
end
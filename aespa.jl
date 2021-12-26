# @time using Dates
@time using CSV, XLSX, DataFrames
excuted_DIR = string(@__DIR__)
schedule = DataFrame(XLSX.readtable(excuted_DIR * "/schedule.xlsx", "schedule")...)

@time using Base.Threads
@time using Random, Distributions, Statistics
@time using Graphs, NearestNeighbors

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
doing = parse(Int64, ARGS[1])
# ------------------------------------------------------------------ setting

scenario = schedule[doing,:]
try
    mkpath(root * scenario.name)
    mkpath(root * scenario.name * "/00")
    mkpath(root * scenario.name * "/0V")
    mkpath(root * scenario.name * "/M0")
    mkpath(root * scenario.name * "/MV")
    CSV.write(root * scenario.name * "/cnfg.csv", DataFrame(scenario), bom = true)
    cd(root * scenario.name)
catch
    @warn "some error occur!"
end

# ------------------------------------------------------------------ parameters

global m = 3 # number of network link
global number_of_host = 1
global θ = 10

global network = scenario.network
global σ = scenario.σ
global e_σ = scenario.e_σ
global p_V = scenario.p_V
global e_V = scenario.e_V
global β = scenario.β
global n = scenario.n
global N = scenario.N
global δ = scenario.δ
global end_time = scenario.end_time
global first_seed = scenario.first_seed
global last_seed = scenario.last_seed

# σ = 0.025 # mobility
# e_σ = 0.1 # effect of moving control
# p_V = 0.005 # probability of vaccination
# e_V = 1.0 # effect of vaccination
# β = 0.02
# n = 1*10^5
# N = 10^2 # number of stage network
# δ = 0.01 # contact radius
# end_time = 200
# first_seed = 1
# last_seed = 30

global ID = 1:n
global brownian = MvNormal(2, 0.01) # moving process

if network == 0
    backbone = barabasi_albert(N, m, seed = 0)
    global NODE = Dict(1:N .=> backbone.fadjlist)
    CSV.write(root * "ntwk.csv", DataFrame(
        deg = degree(backbone),
        betweenness = betweenness_centrality(backbone),
        closeness = closeness_centrality(backbone),
        stress = stress_centrality(backbone)
        ))
elseif network == -1
    using JLD
    realnetwork = load(excuted_DIR * "/world_wide_flight_network.jld")
    global NODE = Dict(realnetwork["nodes"] .=> realnetwork["adj"])
end

global latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
global recovery_period = Weibull(3, 7.17)

@time for v ∈ [true, false], m ∈ [true, false]
    for seed_number ∈ first_seed:last_seed
        simulation(
        seed_number,
        moving = m,
        vaccin = v)
    end
end
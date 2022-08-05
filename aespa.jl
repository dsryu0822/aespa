@time begin
    using XLSX, CSV, DataFrames
    excuted_DIR = string(@__DIR__)
    schedule = DataFrame(XLSX.readtable(excuted_DIR * "/schedule.xlsx", "schedule"))

    using Crayons, Dates
    using Random, Distributions, StatsBase
    using NearestNeighbors, GLM
    using JLD2

    # include("src/lemma.jl")
    include("src/main.jl")

    # ------------------------------------------------------------------ directory

    root = "C:/simulated/"
    if !ispath(root) mkpath(root) end
    if !ispath("C:/saved/") mkpath("C:/saved/") end

    # ------------------------------------------------------------------ setting

    doing = isempty(ARGS) ? 50 : parse(Int64, ARGS[1])
    scenario = schedule[doing,:]
    if !ispath(root * scenario.name)
        mkpath(root * scenario.name)
        CSV.write(root * scenario.name * "/cnfg.csv", DataFrame(scenario), bom = true)
        preview = open(root * scenario.name * "/prvw.csv", "a")
        println(preview, "seed,time,max_tier,pandemic,slope,T,R")
        close(preview)
    end
    cd(root * scenario.name)

    # ------------------------------------------------------------------ parameters

    number_of_host = 1
    θ = 10
    n = 800000
    end_time = 500

    temp_code = scenario.temp_code
    first_seed = scenario.first_seed
    last_seed = scenario.last_seed
    blockade = scenario.blockade / 100
    T0 = scenario.T0
    σ = scenario.σ
    β = scenario.β

    latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
    recovery_period = Weibull(3, 7.17)
    # develop_period = Exponential(100)

    ID = 1:n
    δ = 0.01

    realnetwork = jldopen(excuted_DIR * "\\data_link.jld2")
    NODE0 = realnetwork["adj_encoded"]
    close(realnetwork)

    data = CSV.read(excuted_DIR * "\\data_node.csv",DataFrame)
    N = nrow(data)
    NODE_ID = 1:N
    XY = convert.(Float16, vcat(data.Longitude', data.Latitude'))
    country = data.Country
    # city = data.City
    # iata = data.IATA

    countrynames = data.Country |> unique |> sort
    degree = [sum(data.indegree[data.Country .== c]) for c in countrynames]

    a = - 125/30; b = 45a + 75;
    atlantic = XY[2,:] .< (a .* XY[1,:]) .+ b
end

for seed_number ∈ first_seed:last_seed
    simulation(seed_number)
end
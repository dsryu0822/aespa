begin
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

    doing = isempty(ARGS) ? 1 : parse(Int64, ARGS[1])
    flag_test = isempty(ARGS)
    scenario = schedule[doing,:]
    if !ispath(root * scenario.name)
        mkpath(root * scenario.name)
        CSV.write(root * scenario.name * "/cnfg.csv", DataFrame(scenario), bom = true)
        preview = open(root * scenario.name * "/cnfg.csv", "a")
        println(preview, "")
        println(preview, "seed,time,max_tier,pandemic,slope,T,n_T,network_parity")
        close(preview)
    end
    cd(root * scenario.name)

    # ------------------------------------------------------------------ parameters


    temp_code = scenario.temp_code
    first_seed = scenario.first_seed
    last_seed = scenario.last_seed
    blockade = scenario.blockade / 100
    σ = scenario.σ
    β = scenario.β
    # D = scenario.D # period of vaccin develop

    realnetwork = jldopen(excuted_DIR * "\\data_link.jld2")
        NODE0 = realnetwork["adj_encoded"]
    close(realnetwork)

    data = CSV.read(excuted_DIR * "\\data_node.csv",DataFrame)
    N = nrow(data)
    XY = convert.(Float16, vcat(data.Longitude', data.Latitude'))
    country = data.Country
    countrynames = data.Country |> unique |> sort
    indegree = [sum(data.indegree[data.Country .== c]) for c in countrynames]

    a = - 125/30; b = 45a + 75;
    atlantic = XY[2,:] .< (a .* XY[1,:]) .+ b
    
    print("$doing ")
    for seed_number ∈ first_seed:last_seed

        NODE_blocked = deepcopy(NODE0)

        Random.seed!(seed_number);
        # blocked = findall(rand(N) .< blockade)
        # for u in 1:N NODE_blocked[u][NODE_blocked[u] .∈ Ref(blocked)] .= u end
        # for u in 1:N
        #     if u in blocked
        #         NODE_blocked[u] .= u
        #     else
        #         NODE_blocked[u][NODE_blocked[u] .∈ Ref(blocked)] .= u
        #     end
        # end
        for u in 1:N NODE_blocked[u][rand(length(NODE_blocked[u])) .< blockade] .= u end
        
        simulation(
            seed_number
            , flag_test
            , blockade
            , σ
            , β
            , NODE0
            , NODE_blocked
            , N
            , XY
            , country
            , countrynames
            , indegree
            , atlantic
        )
    end
end
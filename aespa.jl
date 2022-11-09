begin
    # schedule = DataFrame(XLSX.readtable(excuted_DIR * "/schedule.xlsx", "schedule"))
    const doing = isempty(ARGS) ? 1 : parse(Int64, ARGS[1])

    using CSV, DataFrames
    using Crayons, Dates
    using Random, Distributions, StatsBase
    using NearestNeighbors, GLM
    using JLD2

    include("src/main.jl")
    include("src/sub.jl")

    const excuted_DIR = string(@__DIR__)
    const schedule = CSV.read("cached_schedule.csv", DataFrame)

    # ------------------------------------------------------------------ directory

    const root = "C:/simulated/"
    if !ispath(root) mkpath(root) end
    if !ispath("C:/saved/") mkpath("C:/saved/") end

    # ------------------------------------------------------------------ setting
    const scenario = schedule[doing,:]
    if !ispath(root * scenario.name)
        mkpath(root * scenario.name)
        CSV.write(root * scenario.name * "/cnfg.csv", DataFrame(scenario), bom = true)
        preview = open(root * scenario.name * "/cnfg.csv", "a")
        println(preview, "")
        println(preview, "seed,time,T,n_R,network_parity,isescape,slope")
        close(preview)
    end
    cd(root * scenario.name)

    # ------------------------------------------------------------------ parameters

    if isempty(ARGS)
        flag_test = true
    else
        flag_test = isone(scenario.flag_test)
    end
    const temp_code = scenario.temp_code
    const first_seed = scenario.first_seed
    const last_seed = scenario.last_seed
    const blockade = scenario.blockade / 100
    const T0 = scenario.T0
    const σ = scenario.σ
    const β = scenario.β

    realnetwork = jldopen(excuted_DIR * "\\data_link.jld2")
        const NODE0 = realnetwork["adj_encoded"]
    close(realnetwork)

    data = CSV.read(excuted_DIR * "\\data_node.csv",DataFrame)
    const N = nrow(data)
    const XY = convert.(Float16, vcat(data.Longitude', data.Latitude'))
    const country = data.Country
    const countrynames = data.Country |> unique |> sort
    const indegree = [sum(data.indegree[data.Country .== c]) for c in countrynames]

    a = - 125/30; b = 45a + 75;
    const atlantic = XY[2,:] .< (a .* XY[1,:]) .+ b
    
    print("$doing ")
    for seed_number ∈ first_seed:last_seed

        NODE_blocked = deepcopy(NODE0)

        Random.seed!(seed_number);
        # for u in 1:N NODE_blocked[u][rand(length(NODE_blocked[u])) .< blockade] .= u end
        # for u in 1:N NODE_blocked[u][NODE_blocked[u] .∈ Ref(blocked)] .= u end
        # blocked = findall(rand(N) .< blockade)
        # for u in 1:N
        #     if !(u in blocked)
        #         NODE_blocked[u][NODE_blocked[u] .∈ Ref(blocked)] .= u
        #     else
        #         NODE_blocked[u] .= u
        #     end
        # end
        
        simulation(seed_number
            , flag_test
            , blockade
            , T0
            , σ
            , NODE0
            , NODE_blocked
        )
    end
end
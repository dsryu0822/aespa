# @time using Dates
@time include("lemma.jl")
@time using Random, Distributions, Statistics
@time using Graphs, NearestNeighbors
@time using DataFrames
@time using CSV, XLSX

deep_pop!(array) = isempty(array) ? 0 : pop!(array)

# ------------------------------------------------------------------ switches

export_type = :CSV # :both, :CSV, :XLSX

if !isdir("D:/trash/")
    mkpath("D:/trash/")
    mkpath("D:/trash/00")
    mkpath("D:/trash/0V")
    mkpath("D:/trash/M0")
    mkpath("D:/trash/MV")
end

# ------------------------------------------------------------------ parameters

# Breaktrough parameter. Vaccinated agents are infected with probability β/B.
breakthrough_infection = false; const B = 10

const n = 1*10^5
N = n ÷ 1000 # number of stage network
ID = 1:n
const m = 3 # number of network link
const number_of_host = 1
const end_time = 200

const β = 0.02
const vaccin_supply = 0.005 # probability of vaccination
const δ = 0.01 # contact radius

brownian = MvNormal(2, 0.01) # moving process
backbone = barabasi_albert(N, m)
NODE = backbone.fadjlist

latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)

# ------------------------------------------------------------------ Random Setting
function simulation(
    preed_sumber,
    seed_number;
    moving = false,
    vaccin = false)

    σ = 0.05 # mobility
    scenario = (moving ? 'M' : '0') * (vaccin ? 'V' : '0')
    directory = "D:/trash/$scenario/"
    Random.seed!(preed_sumber); println(seed_number)

    ######################## Initializaion

    n_S_ = Int64[]
    n_E_ = Int64[]
    n_I_ = Int64[]
    n_R_ = Int64[]
    n_V_ = Int64[]
    Rt_ = Float64[]

    # daily_ = Int64[]
    # NODE_I_ = zeros(Int64, end_time, N)


    transmission = DataFrame(
        T = Int64[],
        t = Int64[],
        node_id = Int64[],
        # x = Float16[],
        # y = Float16[],
        from = Int64[],
        to = Int64[],
        Break = Int64[]
    )
    non_transmission = copy(transmission)

    T = 0 # Macro timestep
    state = repeat(['S'], n) # using SEIR model
    host = rand(ID, number_of_host); state[host] .= 'I'

    LATENT = repeat([-1], n)
    RECOVERY = repeat([-1], n)
    RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1

    coordinate = rand(Float16, 2, n) # micro location
    LOCATION = rand(1:N, n) # macro location
for _ in 1:5 LOCATION = rand.(NODE[LOCATION]) end
@time while sum(state .== 'E') + sum(state .== 'I') > 0
    T += 1; if T > end_time break end
    if T == 32 Random.seed!(seed_number) end

    LATENT   .-= 1
    RECOVERY .-= 1
    bit_LATENT     = (LATENT   .== 0)
    bit_RECOVERY   = (RECOVERY .== 0)
    state[bit_LATENT  ] .= 'I'
    state[bit_RECOVERY] .= 'R'

    bit_S = (state .== 'S'); n_S = count(bit_S); push!(n_S_, n_S)
    bit_E = (state .== 'E'); n_E = count(bit_E); push!(n_E_, n_E)
    bit_I = (state .== 'I'); n_I = count(bit_I); push!(n_I_, n_I)
    bit_R = (state .== 'R'); n_R = count(bit_R); push!(n_R_, n_R)
    bit_V = (state .== 'V'); n_V = count(bit_V); push!(n_V_, n_V)

    if T > 0
        println("$T: |E: $(n_E_[T]) |I: $(n_I_[T]) |R:$(n_R_[T]) |V:$(n_V_[T])")
    end

    σ = 0.05 # mobility
    if n_I > 10
        if vaccin state[bit_S .& (rand(n) .< vaccin_supply)] .= 'V' end
        if moving σ = 0.005 end
    end
    moved = (rand(n) .< σ)
    LOCATION[moved] = rand.(NODE[LOCATION[moved]])

    NODE_I = unique(LOCATION[bit_I])
    for node in NODE_I
        bit_node = (LOCATION .== node)

        bit_micro_S = bit_node .& bit_S
        bit_micro_E = bit_node .& bit_E
        bit_micro_I = bit_node .& bit_I
        bit_micro_V = bit_node .& bit_V

        ID_S = ID[bit_micro_S]; n_micro_S = count(bit_micro_S)
        ID_E = ID[bit_micro_E]; n_micro_E = count(bit_micro_E)
        ID_I = ID[bit_micro_I]; n_micro_I = count(bit_micro_I)
        ID_V = ID[bit_micro_V]; n_micro_V = count(bit_micro_V)
        # NODE_I_[T, node] = n_micro_I
        for t in 1:24
            coordinate[:,ID_S] = mod.(coordinate[:,ID_S] + rand(brownian, n_micro_S), 1.0)
            coordinate[:,ID_E] = mod.(coordinate[:,ID_E] + rand(brownian, n_micro_E), 1.0)
            coordinate[:,ID_I] = mod.(coordinate[:,ID_I] + rand(brownian, n_micro_I), 1.0)
            coordinate[:,ID_V] = mod.(coordinate[:,ID_V] + rand(brownian, n_micro_V), 1.0)
            if (n_micro_S == 0) continue end # transmission I to S
            
            kdtreeI = KDTree(coordinate[:,ID_I])
            in_δ = inrange(kdtreeI, coordinate[:,ID_S], δ)
            contact = length.(in_δ)
            bit_infected = (rand(n_micro_S) .< (1 .- (1 - β).^contact))
            ID_infected = ID_S[bit_infected]
            
            n_infected = count(bit_infected)
            if n_infected > 0
                from_id = ID_I[deep_pop!.(shuffle.(in_δ))[bit_infected]]
                append!(transmission, DataFrame(
                    T = T, t = t, node_id = node,
                    # x = coordinate[1,from_id], y = coordinate[2,from_id],
                    from = from_id, to = ID_infected, Break = 0
                    ))
            end
            state[ID_infected] .= 'E'
            LATENT[ID_infected] .= round.(rand(latent_period, n_infected))
            RECOVERY[ID_infected] .= LATENT[ID_infected] + round.(rand(recovery_period, n_infected))
        end
        unique!(transmission, :to)

        infector_list = transmission[transmission.T .== T, :from]
        for defendant ∈ ID_I
            if defendant ∉ infector_list
                append!(non_transmission, DataFrame(
                    T = T, t = 0, node_id = node, #x = 0, y = 0,
                    from = defendant, to = 0, Break = 0
                    ))
            end
        end
    end
    
    now_I = ID[state .== 'I']
    push!(
        Rt_,
        isempty(now_I) ? 0 : nrow(transmission[transmission[:,:from] .∈ Ref(now_I),:]) / length(now_I))
end

    T0 = sufficientN(Rt_ .< 1)
    if n_S_[end] < (n - 1000)
    # if true
        seed = lpad(seed_number, 4, '0')
        
        time_evolution = DataFrame(hcat(n_S_, n_E_, n_I_, n_R_, n_V_, Rt_), ["S", "E", "I", "R", "V", "Rt"])
        append!(transmission, non_transmission); sort!(transmission, :T)   
        config = DataFrame(n = n, β = β, vaccin_supply = vaccin_supply, δ = δ, σ = σ, moving = moving, vaccin = vaccin)
        summary = DataFrame(T0 = T0, R = n_R_[T0], V = n_V_[T0])

        @time if export_type != :XLSX
            CSV.write(directory * "$seed tevl.csv", time_evolution)
            CSV.write(directory * "$seed trms.csv", transmission)
            CSV.write(directory * "$seed cnfg.csv", config, bom = true)
            CSV.write(directory * "$seed smry.csv", summary, bom = true)
        elseif export_type != :CSV
            XLSX.writetable(
                directory * "$seed.xlsx",
                time_evolution = ( collect(eachcol(time_evolution)), names(time_evolution) ),
                transmission = ( collect(eachcol(transmission)), names(transmission) ),
                config = ( collect(eachcol(config)), names(config) ),
                summary = ( collect(eachcol(summary)), names(summary) )
            )
        end
    end
end

for seed_number ∈ 1:1
    for v ∈ [true, false], m ∈ [true, false]
        simulation(
        1,seed_number,
        moving = m,
        vaccin = v)
    end
end
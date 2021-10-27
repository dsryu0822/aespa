# @time using Dates
@time using Graphs, NearestNeighbors
@time using Random, Distributions, Statistics
@time using DataFrames
@time using CSV, XLSX

deep_pop!(array) = isempty(array) ? 0 : pop!(array)

# ------------------------------------------------------------------ switches

export_type = :XLSX

if !isdir("D:/trash/")
    mkpath("D:/trash/")
    mkpath("D:/trash/00")
    mkpath("D:/trash/0V")
    mkpath("D:/trash/M0")
    mkpath("D:/trash/MV")
end
moving = false
vaccin = false
scenario = (moving ? 'M' : '0') * (vaccin ? 'V' : '0')
directory = "D:/trash/$scenario/"

# ------------------------------------------------------------------ parameters

breakthrough_infection = false

const n = 1*10^5
N = n ÷ 1000 # number of stage network
ID = 1:n
const m = 3 # number of network link
const number_of_host = 1
const end_time = 100

const β = 0.02
const B = 10 # Breaktrough parameter. Vaccinated agents are infected with probability β/B.
const vaccin_supply = 0.01 # probability of vaccination
const δ = 0.01 # contact radius

brownian = MvNormal(2, 0.01) # moving process
backbone = barabasi_albert(N, m)
NODE = backbone.fadjlist

latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)

# ------------------------------------------------------------------ Random Setting
function simulation(seed_number)
σ = 0.05 # mobility
Random.seed!(seed_number); println(seed_number)

n_S_ = Int64[]
n_E_ = Int64[]
n_I_ = Int64[]
n_R_ = Int64[]
n_V_ = Int64[]

# daily_ = Int64[]
# NODE_I_ = zeros(Int64, end_time, N)

INCUBATION = repeat([-1], n)
RECOVERY = repeat([-1], n)
state = repeat(['S'], n) # using SEIR model

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
host = rand(ID, number_of_host); state[host] .= 'I'
RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1
coordinate = rand(Float16, 2, n) # micro location
LOCATION = rand(1:N, n) # macro location
for _ in 1:5 LOCATION = rand.(NODE[LOCATION]) end
@time while sum(state .== 'E') + sum(state .== 'I') > 0
    T += 1; if T > end_time break end

    INCUBATION .-= 1
    RECOVERY   .-= 1
    bit_INCUBATION = (INCUBATION .== 0)
    bit_RECOVERY   = (RECOVERY   .== 0)
    state[bit_INCUBATION] .= 'I'
    state[bit_RECOVERY  ] .= 'R'

    bit_S = (state .== 'S'); n_S = count(bit_S); push!(n_S_, n_S)
    bit_E = (state .== 'E'); n_E = count(bit_E); push!(n_E_, n_E)
    bit_I = (state .== 'I'); n_I = count(bit_I); push!(n_I_, n_I)
    bit_R = (state .== 'R'); n_R = count(bit_R); push!(n_R_, n_R)
    bit_V = (state .== 'V'); n_V = count(bit_V); push!(n_V_, n_V)

    if T > 0
        println("$T: |E: $(n_E_[T]) |I: $(n_I_[T]) |R:$(n_R_[T]) |V:$(n_V_[T])")
    end

    moved = (rand(n) .< σ)
    if n_I > 100
        if vaccin state[bit_S .& (rand(n) .< vaccin_supply)] .= 'V' end
        if moving moved = (rand(n) .< σ/10) end
    end    
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
            kdtreeI = KDTree(coordinate[:,ID_I])

            if (n_micro_S == 0) continue end # transmission I to S
            in_δ = inrange(kdtreeI, coordinate[:,ID_S], δ)
            contact = length.(in_δ)
            bit_infected =  (rand(n_micro_S) .< (1 .- (1 - β).^contact))
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
            INCUBATION[ID_infected] .= round.(rand(latent_period, n_infected))
            RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, n_infected))
        end

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
end

if n_S_[end] < (n - 1000)
    seed = lpad(seed_number, 4, '0')
    
    time_evolution = DataFrame(hcat(n_S_, n_E_, n_I_, n_R_, n_V_), ["S", "E", "I", "R", "V"])

    unique!(transmission, :to)
    append!(transmission, non_transmission)
    sort!(transmission, :T)
    
    config = DataFrame(n = n, β = β, B = B, vaccin_supply = vaccin_supply, δ = δ, σ = σ, vaccin = vaccin, moving = moving)

    if export_type == :CSV
        CSV.write(directory * "$seed time_evolution.csv", time_evolution)
        CSV.write(directory * "$seed essential.csv", transmission)
        CSV.write(directory * "$seed info.csv", config, bom = true)
    elseif export_type == :XLSX
        @time XLSX.writetable(
            directory * "$seed.xlsx",
            time_evolution = ( collect(eachcol(time_evolution)), names(time_evolution) ),
            transmission = ( collect(eachcol(transmission)), names(transmission) ),
            config = ( collect(eachcol(config)), names(config) )
        )
    end
end

end

for seed_number in 1:10
    simulation(seed_number)
end
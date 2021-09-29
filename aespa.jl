# @time using Base.Threads
@time using Dates
@time using NearestNeighbors
@time using LightGraphs
@time using Random, Distributions, Statistics
@time using CSV, DataFrames
@time using Plots

visualization = false
directory = "D:/trash/"

# ------------------------------------------------------------------ parameters
const n = 100_000
N = n ÷ 1000 # number of stage network
ID = 1:n
const m = 3 # number of network link
const number_of_host = 1
const end_time = 100

const β = 0.02
const δ = σ = 0.01

brownian = MvNormal(2, 0.01) # moving process
incubation_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)

# ------------------------------------------------------------------ Random Setting
SEED = 1:10
ensemble = Int64[]
for seed_number ∈ SEED
Random.seed!(seed_number); println(seed_number)
NODE = barabasi_albert(N, m).fadjlist

S_ = Int64[]
E_ = Int64[]
I_ = Int64[]
R_ = Int64[]
daily_ = Int64[]

NODE_I_ = zeros(Int64, end_time, N)
entropy_ = zeros(Float64, end_time)
n_NODE_ = zeros(Int64, end_time, N)
n_NODE_I_ = zeros(Int64, end_time)
n_NODE_total_ = zeros(Int64, end_time)

INCUBATION = repeat([-1], n)
RECOVERY = repeat([-1], n)
state = repeat(['S'], n) # using SEIR model
host = rand(ID, number_of_host); state[host] .= 'I'
RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1

T = 0 # Macro timestep
coordinate = rand(Float16, 2, n) # micro location
LOCATION = rand(1:N, n) # macro location
for _ in 1:5
    LOCATION = rand.(NODE[LOCATION])
end

localtrajectory = DataFrame(
    agent_id = lpad(host[1],5,'0'),
    node_id = LOCATION[host],
    T = 0,
    t = 0,
    x = coordinate[1, host],
    y = coordinate[2, host],
    num_to = 0
    )
R₀_table = DataFrame(
    degree = 0,
    node_id = 0,
    T = 0,
    I0 = 0,
    I1 = 0
)

@time while sum(state .== 'E') + sum(state .== 'I') > 0
    T += 1; if T > end_time break end

    INCUBATION .-= 1
    RECOVERY   .-= 1
    bit_INCUBATION = (INCUBATION .== 0)
    bit_RECOVERY   = (RECOVERY   .== 0)
    state[bit_INCUBATION] .= 'I'
    state[bit_RECOVERY  ] .= 'R'

    bit_S = (state .== 'S'); n_S = count(bit_S); push!(S_, n_S)
    bit_E = (state .== 'E'); n_E = count(bit_E); push!(E_, n_E)
    bit_I = (state .== 'I'); n_I = count(bit_I); push!(I_, n_I)
    bit_R = (state .== 'R'); n_R = count(bit_R); push!(R_, n_R)

    if T > 0
        println("$T: |E: $(E_[T]) |I: $(I_[T]) |R:$(R_[T])")
    end

    moved = (rand(n) .< σ)
    LOCATION[moved] = rand.(NODE[LOCATION[moved]])

    NODE_I = unique(LOCATION[bit_I])
    for node in NODE_I
        bit_node = (LOCATION .== node)
        bit_micro_S = bit_node .& bit_S
        bit_micro_I = bit_node .& bit_I

        ID_S = ID[bit_micro_S]; n_micro_S = count(bit_micro_S)
        ID_I = ID[bit_micro_I]; n_micro_I = count(bit_micro_I)
        NODE_I_[T, node] = n_micro_I
        bit_infected = zeros(Bool,n_micro_S)
        for t in 1:24
            coordinate[:,ID_S] = mod.(coordinate[:,ID_S] + rand(brownian, n_micro_S), 1.0)
            coordinate[:,ID_I] = mod.(coordinate[:,ID_I] + rand(brownian, n_micro_I), 1.0)
            
            kdtreeI = KDTree(coordinate[:,ID_I])
            contact = length.(inrange(kdtreeI, coordinate[:,ID_S], δ))
            
            bit_infected =  bit_infected .| (rand(n_micro_S) .< (1 .- (1 - β).^contact))
            if length(ID_I) == 1
                one = ID_I[1]
                push!(localtrajectory,[lpad(one,5,'0'), LOCATION[one], T, t, coordinate[1, one], coordinate[2, one], count(bit_infected)])
            end
        end
        push!(R₀_table, [length(NODE[node]), node, T, n_micro_I, count(bit_infected)])

        ID_infected = ID_S[bit_infected]
        state[ID_infected] .= 'E'
        INCUBATION[ID_infected] .= round.(rand(incubation_period, count(bit_infected)))
        RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, count(bit_infected)))
    end
end

if R_[end] > 1000
    push!(ensemble, R_[end])
    time_evolution = DataFrame(hcat(S_, E_, I_, R_), ["S", "E", "I", "R"])
    time_evolution_nodewise = DataFrame(NODE_I_, :auto)
    CSV.write(directory * "$seed_number time_evolution.csv", time_evolution)
    CSV.write(directory * "$seed_number time_evolution_nodewise.csv", time_evolution_nodewise)
    delete!(localtrajectory, 1)
    CSV.write(directory * "$seed_number localtrajectory.csv", localtrajectory)
    delete!(R₀_table, 1)
    CSV.write(directory * "$seed_number R0_table.csv", R₀_table)

    if visualization
        plot_EI = plot(daily_, label = "daily", color= :orange, linestyle = :solid,
        size = (400, 300), dpi = 300, legend=:topright)
        xlabel!("T"); ylabel!("#")
        savefig(plot_EI, "$seed_number plot_daily.png")

        plot_R = plot(R_, label = "R", color= :black,
        size = (400, 300), dpi = 300, legend=:topleft)
        xlabel!("T"); ylabel!("#")
        savefig(plot_R, "$seed_number plot_R.png")
        
        corrupt = vec(sum(NODE_I_,dims=1))
        corrupt_value = corrupt[corrupt .> 0]
        plot(NODE_I_[1:1000,corrupt .> 0], label = ""); png(directory * "$seed_number time_evolution_nodewise.png")
        plot(entropy_[1:1000], label = "entropy", ylims = (-0.2,1.2)); png(directory * "$seed_number time_evolution_entropy.png")
        plot(n_NODE_I_[1:1000], label = "I in nodes"); png(directory * "$seed_number I in nodes.png")
    end
end

# autosave = open(directory * "0 autosave.csv", "a")
# try
#     println(autosave, Dates.now(), ", $seed_number, $(R_[end])")
# finally
#     close(autosave)
# end

end

# try
#     CSV.write(directory * "tatal summary.csv", DataFrame(hcat(SEED, ensemble), ["seed", "R"]))
# catch
#     print("no meaninful result!")
# end
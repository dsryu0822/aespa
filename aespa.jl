# @time using Profile
@time using Random
@time using Base.Threads
@time using Dates
@time using NearestNeighbors
@time using LightGraphs
@time using LinearAlgebra
@time using Distributions, Statistics
@time using Plots
# @time using CUDA
@time using CSV, DataFrames

test = true
visualization = false
directory = "D:/trash/"

# ------------------------------------------------------------------

# parameters
n = 100_000
# n = 5*10^7 # number of agent
N = n ÷ 1000 # number of stage network
m = 3 # number of network link
ID = 1:n
number_of_host = 1
end_time = 1000

β = 0.003 # infection rate
ε = 0.05

brownian = MvNormal(2, 0.01) # moving process
incubation_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)
mean(Weibull(3, 7.17))
std(Weibull(3, 7.17))

# ------------------------------------------------------------------
# Random Setting
SEED = 1:50
ensemble = Int64[]
for seed_number ∈ SEED
println(seed_number)
Random.seed!(seed_number);

S_ = Array{Int64, 1}()
E_ = Array{Int64, 1}()
I_ = Array{Int64, 1}()
R_ = Array{Int64, 1}()
daily_ = Array{Int64, 1}()
NODE_I_ = zeros(Int64, end_time, N)
entropy_ = zeros(Float64, end_time)
n_NODE_ = zeros(Int64, end_time, N)
n_NODE_I_ = zeros(Int64, end_time)
n_NODE_total_ = zeros(Int64, end_time)

INCUBATION = zeros(Int64, n) .- 1
RECOVERY = zeros(Int64, n) .- 1

NODE = barabasi_albert(N, m).fadjlist
# histogram(degree(watts_strogatz(n, 4, 0.5)))

state = Array{Char, 1}(undef, n); state .= 'S' # using SEIR model
host = rand(ID, number_of_host); state[host] .= 'I'
RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1

location = rand(2, n) # micro location
LOCATION = rand(1:N, n) # macro location
for _ in 1:10
    LOCATION = rand.(NODE[LOCATION])
end

T = 0 # Macro timestep
# @profview while sum(state .== 'E') + sum(state .== 'I') > 0
@time while sum(state .== 'E') + sum(state .== 'I') > 0
    T += 1
    if T > end_time break end

    INCUBATION .-= 1
    RECOVERY .-= 1
    bit_INCUBATION = (INCUBATION .== 0)
    bit_RECOVERY   = (RECOVERY   .== 0)
    state[bit_INCUBATION] .= 'I'
    state[bit_RECOVERY  ] .= 'R'
    # G[bit_RECOVERY] .= 0

    bit_S = (state .== 'S')
    bit_E = (state .== 'E')
    bit_I = (state .== 'I')
    bit_R = (state .== 'R')
    
    n_I = sum(bit_I)
    n_R = sum(bit_R)
    push!(S_, sum(bit_S))
    push!(E_, sum(bit_E))
    push!(I_, n_I)
    push!(R_, n_R)
    push!(daily_, sum(bit_INCUBATION))

    if T > 0
        println("$T: |E: $(E_[T]) |I: $(I_[T]) |R:$(R_[T])")
    end

    moved = (rand(n) .< ε)
    LOCATION[moved] = rand.(NODE[LOCATION[moved]])

    NODE_I = unique(LOCATION[bit_I])
    n_NODE_I_[T] = length(NODE_I)
    if n_NODE_I_[T] ≥ 40
        @threads for node in NODE_I
            bit_node = (LOCATION .== node)
            bit_micro_S = bit_node .& bit_S
            bit_micro_I = bit_node .& bit_I

            ID_S = ID[bit_micro_S]; num_micro_S = sum(bit_micro_S)
            ID_I = ID[bit_micro_I]; num_micro_I = sum(bit_micro_I)
            NODE_I_[T, node] = num_micro_I
            for t in 1:4
                location[:,ID_S] = mod.(location[:,ID_S] + rand(brownian, num_micro_S), 1.0)
                location[:,ID_I] = mod.(location[:,ID_I] + rand(brownian, num_micro_I), 1.0)

                kdtreeI = KDTree(location[:,ID_I])
                contact = length.(inrange(kdtreeI, location[:,ID_S], ε))

                bit_infected = rand(num_micro_S) .< (1 .- (1 - β).^contact)
                ID_infected = ID_S[bit_infected]
                
                state[ID_infected] .= 'E'
                INCUBATION[ID_infected] .= round.(rand(incubation_period, sum(bit_infected)))
                RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, sum(bit_infected)))
            end
        end
    else
        for node in NODE_I
            bit_node = (LOCATION .== node)
            bit_micro_S = bit_node .& bit_S
            bit_micro_I = bit_node .& bit_I

            ID_S = ID[bit_micro_S]; num_micro_S = sum(bit_micro_S)
            ID_I = ID[bit_micro_I]; num_micro_I = sum(bit_micro_I)
            NODE_I_[T, node] = num_micro_I
            for t in 1:4
                location[:,ID_S] = mod.(location[:,ID_S] + rand(brownian, num_micro_S), 1.0)
                location[:,ID_I] = mod.(location[:,ID_I] + rand(brownian, num_micro_I), 1.0)

                kdtreeI = KDTree(location[:,ID_I])
                contact = length.(inrange(kdtreeI, location[:,ID_S], ε))

                bit_infected = rand(num_micro_S) .< (1 .- (1 - β).^contact)
                ID_infected = ID_S[bit_infected]
                
                state[ID_infected] .= 'E'
                INCUBATION[ID_infected] .= round.(rand(incubation_period, sum(bit_infected)))
                RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, sum(bit_infected)))
            end
        end
    end
    entropy_[T] = entropy(NODE_I_[T, :] ./ n_I, sum(NODE_I_[T, :] .!= 0))
end

if R_[end] > 1000
    # plot_EI = plot(daily_, label = "daily", color= :orange, linestyle = :solid,
    # size = (400, 300), dpi = 300, legend=:topright)
    # xlabel!("T"); ylabel!("#")
    # savefig(plot_EI, "$seed_number plot_daily.png")

    # plot_R = plot(R_, label = "R", color= :black,
    # size = (400, 300), dpi = 300, legend=:topleft)
    # xlabel!("T"); ylabel!("#")
    # savefig(plot_R, "$seed_number plot_R.png")

    push!(ensemble, R_[end])
    time_evolution = DataFrame(hcat(S_, E_, I_, R_, daily_), ["S", "E", "I", "R", "daily"])
    time_evolution_nodewise = DataFrame(NODE_I_)
    CSV.write(directory * "$seed_number time_evolution.csv", time_evolution)
    CSV.write(directory * "$seed_number time_evolution_nodewise.csv", time_evolution_nodewise)
    corrupt = vec(sum(NODE_I_,dims=1))
    corrupt_value = corrupt[corrupt .> 0]
    plot(NODE_I_[1:1000,corrupt .> 0], label = "") #, color = :red, linealpha = corrupt_value/maximum(corrupt_value))
    png(directory * "$seed_number time_evolution_nodewise.png")
    plot(entropy_[1:1000], label = "entropy", ylims = (-0.2,1.2)) #, color = :red, linealpha = corrupt_value/maximum(corrupt_value))
    png(directory * "$seed_number time_evolution_entropy.png")
    plot(n_NODE_I_[1:1000], label = "I in nodes")
    png(directory * "$seed_number I in nodes.png")
end

autosave = open(directory * "0 autosave.csv", "a")
try
    println(autosave, Dates.now(), ", $seed_number, $(R_[end])")
finally
    close(autosave)
end


end

try
    CSV.write(directory * "0 summary.csv", DataFrame(hcat(SEED, ensemble), ["seed", "R"]))
catch
    print("no meaninful result!")
end
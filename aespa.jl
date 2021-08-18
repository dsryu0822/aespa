# @time using Profile
@time using Statistics
@time using Random
@time using Base.Threads
@time using Dates
@time using NearestNeighbors
@time using LightGraphs
@time using LinearAlgebra
@time using Distributions
@time using Plots
@time using CUDA
@time using CSV, DataFrames

test = true
visualization = false

# ------------------------------------------------------------------

# parameters
n = 100000
# n = 5*10^7 # number of agent
N = n ÷ 1000 # number of stage network
m = 3 # number of network link
ID = 1:n
number_of_host = 10

β = 0.005 # infection rate
ε = 0.05

θ = 550
δ = 450

brownian = MvNormal(2, 0.01) # moving process
incubation_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)

# ------------------------------------------------------------------


# PUBLIC = 50 # Public score

# reward_day = -10
# reward_macro = 15
# reward_micro = 1

# ------------------------------------------------------------------
# Random Setting
SEED = 1:1
ensemble = Int64[]
for seed_number ∈ SEED
println(seed_number)
Random.seed!(seed_number);

S_ = Array{Int64, 1}()
E_ = Array{Int64, 1}()
I_ = Array{Int64, 1}()
R_ = Array{Int64, 1}()
daily_ = Array{Int64, 1}()

Ag_ = Array{Int64, 1}()
Pr_ = Array{Int64, 1}()
# Random Vector
# θ = rand(1:100, n)
# G = rand(1:100, n)

INCUBATION = zeros(Int64, n) .- 1
RECOVERY = zeros(Int64, n) .- 1

NODE = barabasi_albert(N, m).fadjlist

policy = rand(['A', 'P'], n) # 'A': Aggressive, 'P': Protective, 'R': Removed
state = Array{Char, 1}(undef, n); state .= 'S' # using SEIR model
host = rand(ID, number_of_host); state[host] .= 'I'
RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1
    
LOCATION = rand(0:N, n) # macro location
location = rand(2, n) # micro location

campaign_flag = false
T = 0 # Macro timestep
# @profview while sum(state .== 'E') + sum(state .== 'I') > 0
@time while sum(state .== 'E') + sum(state .== 'I') > 0
    T += 1
    if T > 1000 break end

    INCUBATION .-= 1
    RECOVERY .-= 1
    state[INCUBATION .== 0] .= 'I'
    bit_RECOVERY = (RECOVERY .== 0)
    state[bit_RECOVERY] .= 'R'
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
    push!(daily_, sum(INCUBATION .== 0))

    # G = G .+ reward_day
    if campaign_flag && (n_I < θ - δ)
        campaign_flag = false
    end
    if n_I > θ + δ
        campaign_flag = true
    end
    
    bit_A = (policy .== 'A')
    bit_P = (policy .== 'P')
    
    transition = rand(n)
    policy[bit_P .& (transition .< 0.05)] .= 'A'
    if campaign_flag
        policy[bit_A .& (transition .< 0.1)] .= 'P'
    else
        policy[bit_A .& (transition .< 0.05)] .= 'P'
    end

    bit_R = (state .== 'R')
    policy[bit_R] .= 'P'
    bit_A = (policy .== 'A')
    bit_P = (policy .== 'P')
    # if campaign_flag
    #     campaign = 5*log(n_I)
    # else
    #     campaign = 0
    # end
    # # println(campaign)
    # δ = G .+ campaign
    # δ = G .+ 20(n_I > 1000)
    
    # policy .= 'P'
    # policy[δ .< θ] .= 'A'

    for id in ID[bit_A]
        if LOCATION[id] > 0
            if rand() < ε
                LOCATION[id] = rand(NODE[LOCATION[id]])
            end
        else
            LOCATION[id] *= -1
        end
        # G[id] += reward_macro
    end
    LOCATION[bit_P] = -abs.(LOCATION[bit_P])

    bit_staged = (LOCATION .> 0)
    ID_staged = ID[bit_staged]
    n_staged = length(ID_staged)

    # push!(Re_, sum(policy1))
    # push!(δ_, mean(δ))
    push!(Ag_, sum(bit_A))
    push!(Pr_, sum(bit_P))

    if T > 0
        println("$T-Staged: $n_staged |E: $(E_[T]) |I: $(I_[T]) |R:$(R_[T])")
    end

    bit_macro_S = (bit_staged .& bit_S)
    bit_macro_I = (bit_staged .& bit_I)
    NODE_I = unique(LOCATION[bit_macro_I])
    NODE_I = NODE_I[NODE_I .> 0]
    if length(NODE_I) ≥ 40
        @threads for node in NODE_I
            bit_node = (LOCATION .== node)
            bit_micro_S = bit_node .& bit_macro_S
            bit_micro_I = bit_node .& bit_macro_I

            ID_S = ID[bit_micro_S]
            ID_I = ID[bit_micro_I]
            for t in 1:4
                location[:,ID_S] = mod.(location[:,ID_S] + rand(brownian, sum(bit_micro_S)), 1.0)
                location[:,ID_I] = mod.(location[:,ID_I] + rand(brownian, sum(bit_micro_I)), 1.0)

                kdtreeI = KDTree(location[:,ID_I])
                contact = length.(inrange(kdtreeI, location[:,ID_S], ε))

                bit_infected = rand(sum(bit_micro_S)) .< (1 .- (1 - β).^contact)
                ID_infected = ID_S[bit_infected]
                
                state[ID_infected] .= 'E'
                INCUBATION[ID_infected] .= round.(rand(incubation_period, sum(bit_infected)))
                RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, sum(bit_infected)))
            end
        end
    else
        for node in NODE_I
            bit_node = (LOCATION .== node)
            bit_micro_S = bit_node .& bit_macro_S
            bit_micro_I = bit_node .& bit_macro_I

            ID_S = ID[bit_micro_S]
            ID_I = ID[bit_micro_I]
            for t in 1:4
                location[:,ID_S] = mod.(location[:,ID_S] + rand(brownian, sum(bit_micro_S)), 1.0)
                location[:,ID_I] = mod.(location[:,ID_I] + rand(brownian, sum(bit_micro_I)), 1.0)

                kdtreeI = KDTree(location[:,ID_I])
                contact = length.(inrange(kdtreeI, location[:,ID_S], ε))

                bit_infected = rand(sum(bit_micro_S)) .< (1 .- (1 - β).^contact)
                ID_infected = ID_S[bit_infected]
                
                state[ID_infected] .= 'E'
                INCUBATION[ID_infected] .= round.(rand(incubation_period, sum(bit_infected)))
                RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, sum(bit_infected)))
            end
        end
    end
end

if R_[end] > 1000
    # if visualization
    # plot_score = plot(PERSONAL_, label = "personal", color= :blue,
    #  size = (600, 200), dpi = 300, legend=:bottomleft)
    #  plot!(VALUE_, label = "value", color= :orange)
    # #  ylims!(0,100)
    # savefig(plot_score, "plot_score.png")

    plot_policy = plot(Ag_, label = "Ag", color= :red,
    size = (600, 200), dpi = 300, legend=:right)
    plot!(Pr_, label = "Pr", color= :blue)
    savefig(plot_policy, "$seed_number plot_policy.png")

    # plot_delta = plot(δ_, color= :orange, linestyle = :dash,
    #  size = (400, 300), dpi = 300, legend=:none)
    #  xlabel!("T"); ylabel!("δ")
    # savefig(plot_delta, "plot_delta.png")

    plot_EI = plot(daily_, label = "daily", color= :orange, linestyle = :solid,
    size = (400, 300), dpi = 300, legend=:topright)
    xlabel!("T"); ylabel!("#")
    savefig(plot_EI, "$seed_number plot_daily.png")

    plot_R = plot(R_, label = "R", color= :black,
    size = (400, 300), dpi = 300, legend=:topleft)
    xlabel!("T"); ylabel!("#")
    savefig(plot_R, "$seed_number plot_R.png")

    push!(ensemble, R_[end])
    time_evolution = DataFrame(hcat(S_, E_, I_, R_, daily_), ["S", "E", "I", "R", "daily"])
    CSV.write("$seed_number time_evolution.csv", time_evolution)
end

autosave = open("0 autosave.csv", "a")
try
    println(autosave, Dates.now(), ", $seed_number, $(R_[end])")
finally
    close(autosave)
end

end

try
    CSV.write("0 summary.csv", DataFrame(hcat(SEED, ensemble), ["seed", "R"]))
catch
    print("no meaninful result!")
end

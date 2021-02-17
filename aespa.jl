# @time using BenchmarkTools
@time using Profile
@time using Statistics
@time using Random
@time using Base.Threads
# @time using Dates
@time using Distances
@time using LinearAlgebra
@time using LightGraphs
@time using Distributions
@time using Plots

test = true
visualization = false

# ------------------------------------------------------------------

# variables
T = 0 # Macro timestep

# parameters
n = 10^5 # number of agent
N = n ÷ 1000 # number of stage network
m = 3 # number of network link

α = 0.3
β = 0.01 # infection rate
# invε = 10 # inverse-epsilon
ε² = 0.0025

fear_threshold = 100
fear_factor = 10

brownian = MvNormal(2, 0.05) # moving process
incubation_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)
noise = Cauchy(0,1)

for t in 1:20
    println(mean(rand(noise, 100,100)))
end

# ------------------------------------------------------------------

S_ = Array{Int64, 1}()
E_ = Array{Int64, 1}()
I_ = Array{Int64, 1}()
R_ = Array{Int64, 1}()

Ag_ = Array{Int64, 1}()
Ne_ = Array{Int64, 1}()
Pr_ = Array{Int64, 1}()
Re_ = Array{Int64, 1}()

PERSONAL_ = Array{Float64, 1}()
VALUE_ = Array{Float64, 1}()

ID = 1:n
# PUBLIC = 50 # Public score
protective = 0.1
neutral    = 0.5
aggressive = 0.9

reward_day = -11
reward_move = 5

# ------------------------------------------------------------------

# Random Setting
if test
    Random.seed!(0)
else
    Random.seed!();
end

# Random Vector
LpU = sort!(rand(1:100, n, 2), dims = 2)
L = LpU[:,1]
U = LpU[:,2]
value = personal = rand(1:100, n)

INCUBATION = zeros(Int64, n) .- 1
  RECOVERY = zeros(Int64, n) .- 1

G = barabasi_albert(N, m); NODE = G.fadjlist

state = Array{Char, 1}(undef, n); state .= 'S' # using SEIR model
policy = Array{Char, 1}(undef, n); policy .= 'N' # 'A': Aggressive, 'N': Neutral, 'P': Protective, 'R': Removed
host = rand(ID, 10); state[host] .= 'I'
RECOVERY[host] .= round.(rand(recovery_period, 10)) .+ 1

LOCATION = rand(0:N, n) # macro location
location = rand(2, n) # micro location
location_pixel = zeros(Int64, 2, n)

# ------------------------------------------------------------------
# @profview while sum(state .== 'E') + sum(state .== 'I') > 0
@time while sum(state .== 'E') + sum(state .== 'I') > 0
    T += 1

    INCUBATION .-= 1
    RECOVERY .-= 1
    state[INCUBATION .== 0] .= 'I'
    bit_RECOVERY = (RECOVERY .== 0)
    state[bit_RECOVERY] .= 'R'
    personal[bit_RECOVERY] .= 0

    personal = personal .+ reward_day

    n_I = sum(state .== 'I')
    value = ((1 - α) * value) .+ (α * personal) .+ fear_factor*(n_I > fear_threshold) 
    # value = (state .!= 'R') .* (value .+ (
    #     personal .+ 
    #     # fear_factor*(n_I > 100) .+
    #     fear_factor*(n_I > 1000)
    #     )) ./ 2

    policy[bit_RECOVERY] .= 'R'
    policy2 =       value .≤  L
    policy3 =  L .< value .≤  U
    policy4 =  U .< value

    # policy[policy1] .= 'R'
    policy[policy2] .= 'A'
    policy[policy3] .= 'N'
    policy[policy4] .= 'P'

    decision =
    aggressive * (policy2) .+
    neutral    * (policy3) .+
    protective * (policy4)
    for id in ID[policy .!= 'R']
        if rand() < decision[id]
            if LOCATION[id] == 0
                LOCATION[id] = rand(1:N)
            else
                LOCATION[id] = rand(NODE[LOCATION[id]]) # 이것도 스태틱하게 딱 저장해서 할 수 있을듯
            end
            personal[id] += reward_move
        else
            LOCATION[id] = 0
        end
    end

    bit_staged = (LOCATION .> 0)
    ID_staged = ID[bit_staged]
    n_staged = length(ID_staged)

    push!(S_, sum(state .== 'S'))
    push!(E_, sum(state .== 'E'))
    push!(I_, sum(state .== 'I'))
    push!(R_, sum(state .== 'R'))

    # push!(Re_, sum(policy1))
    push!(Ag_, sum(policy2))
    push!(Ne_, sum(policy3))
    push!(Pr_, sum(policy4))

    push!(VALUE_, mean(value))
    push!(PERSONAL_, mean(personal))
    print("T: $T - Staged: $n_staged | S: $(S_[T]) | E: $(E_[T]) | I: $(I_[T]) | R:$(R_[T])")
    println(" | Personal: $(PERSONAL_[T]) | Aggressive $(Ag_[T]) | Neutral: $(Ne_[T]) | Protective: $(Pr_[T]) |")

    for t in 1:8
        bit_macro_S = (state .== 'S')
        bit_macro_I = (state .== 'I')

        moved = ID_staged[rand(n_staged) .< decision[ID_staged]]
        LOCATION[moved] = rand.(NODE[LOCATION[moved]])
        personal[moved] .+= reward_move

        # for id in ID_staged
        #     if rand() < decision[id]
        #         LOCATION[id] = rand(NODE[LOCATION[id]])
        #         personal[id] += reward_move
        #     end
        # end

        NODE_I = setdiff(unique(LOCATION[bit_macro_I]), 0)
        if length(NODE_I) ≥ 40
            @threads for node in NODE_I
                bit_node = (LOCATION .== node)
                bit_S = bit_node .& bit_macro_S
                bit_I = bit_node .& bit_macro_I
                ID_S = ID[bit_S]
                ID_I = ID[bit_I]

                location[:,ID_S] = mod.(location[:,ID_S] + rand(brownian, sum(bit_S)), 1.0)
                location[:,ID_I] = mod.(location[:,ID_I] + rand(brownian, sum(bit_I)), 1.0)

                contact = vec(sum(pairwise(SqEuclidean(),location[:,ID_S],location[:,ID_I]) .< ε², dims=2))
                bit_infected = rand(sum(bit_S)) .< (1 .- (1 - β).^contact)
                ID_infected = ID_S[bit_infected]
                
                state[ID_infected] .= 'E'
                INCUBATION[ID_infected] .= round.(rand(incubation_period, sum(bit_infected)))
                RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, sum(bit_infected)))
            end
        else
            for node in NODE_I
                bit_node = (LOCATION .== node)
                bit_S = bit_node .& bit_macro_S
                bit_I = bit_node .& bit_macro_I
                ID_S = ID[bit_S]
                ID_I = ID[bit_I]
    
                location[:,ID_S] = mod.(location[:,ID_S] + rand(brownian, sum(bit_S)), 1.0)
                location[:,ID_I] = mod.(location[:,ID_I] + rand(brownian, sum(bit_I)), 1.0)
    
                contact = vec(sum(pairwise(SqEuclidean(),location[:,ID_S],location[:,ID_I]) .< ε², dims=2))
                bit_infected = rand(sum(bit_S)) .< (1 .- (1 - β).^contact)
                ID_infected = ID_S[bit_infected]
                
                state[ID_infected] .= 'E'
                INCUBATION[ID_infected] .= round.(rand(incubation_period, sum(bit_infected)))
                RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, sum(bit_infected)))
            end
        end
    end
end

mean(L[state .== 'R'])
mean(U[state .== 'R'])

mean(L[state .!= 'R'])
mean(U[state .!= 'R'])

# if visualization
plot_score = plot(PERSONAL_, label = "personal", color= :blue,
 size = (600, 200), dpi = 300, legend=:topright)
 plot!(VALUE_, label = "value", color= :orange)
savefig(plot_score, "plot_score.png")

plot_policy = plot(Re_, label = "Re", color= :black,
 size = (600, 200), dpi = 300, legend=:right)
 plot!(Ag_, label = "Ag", color= :red)
 plot!(Ne_, label = "Ne", color= :green)
 plot!(Pr_, label = "Pr", color= :blue)
savefig(plot_policy, "plot_policy.png")


plot_EI = plot(E_, label = "E", color= :orange, linestyle = :dash,
 size = (400, 300), dpi = 300, legend=:topright)
 plot!(I_, label = "I", color= :red)
 xlabel!("T"); ylabel!("#")
savefig(plot_EI, "plot_EI.png")

plot_R = plot(R_, label = "R", color= :black,
 size = (400, 300), dpi = 300, legend=:topleft)
 xlabel!("T"); ylabel!("#")
savefig(plot_R, "plot_R.png")

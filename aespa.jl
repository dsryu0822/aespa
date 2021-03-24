# @time using BenchmarkTools
@time using Profile
@time using Statistics
@time using Random
@time using Base.Threads
# @time using Dates
@time using NearestNeighbors
@time using LinearAlgebra
@time using LightGraphs
@time using Distributions
@time using Plots

test = true
visualization = false

# ------------------------------------------------------------------

# variables
global T = 0 # Macro timestep

# parameters
n = 10^6 # number of agent
N = n ÷ 1000 # number of stage network
m = 3 # number of network link

α = 1.0
β = 0.002 # infection rate
# invε = 10 # inverse-epsilon
ε = 0.05

brownian = MvNormal(2, 0.01) # moving process
incubation_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)

# ------------------------------------------------------------------

S_ = Array{Int64, 1}()
E_ = Array{Int64, 1}()
I_ = Array{Int64, 1}()
R_ = Array{Int64, 1}()

Ag_ = Array{Int64, 1}()
Ne_ = Array{Int64, 1}()
Pr_ = Array{Int64, 1}()
Re_ = Array{Int64, 1}()

FEAR_ = Array{Float64, 1}()
PERSONAL_ = Array{Float64, 1}()
VALUE_ = Array{Float64, 1}()

ID = 1:n
# PUBLIC = 50 # Public score
protective = 0.1
neutral    = 0.5
aggressive = 0.9

reward_day = -11
reward_macro = 20
reward_micro = 1

# ------------------------------------------------------------------

# Random Setting
if test
    global seed = 0
else
    global seed += 1
end
Random.seed!(seed);

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

fear_flag = false

# ------------------------------------------------------------------
# @profview while sum(state .== 'E') + sum(state .== 'I') > 0
@time while sum(state .== 'E') + sum(state .== 'I') > 0
    global T += 1

    INCUBATION .-= 1
    RECOVERY .-= 1
    state[INCUBATION .== 0] .= 'I'
    bit_RECOVERY = (RECOVERY .== 0)
    state[bit_RECOVERY] .= 'R'
    personal[bit_RECOVERY] .= 0

    n_I = sum(state .== 'I')
    n_R = sum(state .== 'R')
    push!(S_, sum(state .== 'S'))
    push!(E_, sum(state .== 'E'))
    push!(I_, n_I)
    push!(R_, n_R)

    personal = personal .+ reward_day
    if fear_flag && (n_I < 100)
        fear_flag = false
    elseif !fear_flag && (n_I > 1000)
        fear_flag = true
    end
    if fear_flag
        fear = 5*log(n_I)
    else
        fear = 0
    end
    println(fear)
    value = ((1 - α) * value) .+ (α * personal) .+ fear
    
    push!(PERSONAL_, mean(personal))
    push!(FEAR_, fear)
    push!(VALUE_, mean(value))
    #  rand(noise, n)

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
            personal[id] += reward_macro
        else
            LOCATION[id] = 0
        end
    end

    bit_staged = (LOCATION .> 0)
    ID_staged = ID[bit_staged]
    n_staged = length(ID_staged)


    # push!(Re_, sum(policy1))
    push!(Ag_, sum(policy2))
    push!(Ne_, sum(policy3))
    push!(Pr_, sum(policy4))

    print("$T-Staged: $n_staged |S: $(S_[T]) |E: $(E_[T]) |I: $(I_[T]) |R:$(R_[T])")
    println(" |Personal: $(PERSONAL_[T]) |Aggressive $(Ag_[T]) | Protective: $(Pr_[T]) |")

    for t in 1:8
        bit_macro_S = (state .== 'S')
        bit_macro_I = (state .== 'I')

        moved = ID_staged[rand(n_staged) .< decision[ID_staged]]
        LOCATION[moved] = rand.(NODE[LOCATION[moved]])
        personal[moved] .+= reward_micro

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

                kdtreeI = KDTree(location[:,ID_I])
                contact = length.(inrange(kdtreeI, location[:,ID_S], ε))

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

                kdtreeI = KDTree(location[:,ID_I])
                contact = length.(inrange(kdtreeI, location[:,ID_S], ε))

                bit_infected = rand(sum(bit_S)) .< (1 .- (1 - β).^contact)
                ID_infected = ID_S[bit_infected]
                
                state[ID_infected] .= 'E'
                INCUBATION[ID_infected] .= round.(rand(incubation_period, sum(bit_infected)))
                RECOVERY[ID_infected] .= INCUBATION[ID_infected] + round.(rand(recovery_period, sum(bit_infected)))
            end
        end
    end
end

# if visualization
plot_score = plot(PERSONAL_, label = "personal", color= :blue,
 size = (600, 200), dpi = 300, legend=:bottomleft)
 plot!(VALUE_, label = "value", color= :orange)
#  ylims!(0,100)
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

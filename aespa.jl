@time using BenchmarkTools
@time using Profile
@time using Statistics
@time using Base.Threads
# @time using Dates
@time using Random
@time using LinearAlgebra
@time using LightGraphs
@time using Distributions
@time using Plots

test = false
visualization = true

# ------------------------------------------------------------------

# variables
t = 0 # micro timestep
T = 0 # Macro timestep

# parameters
n = 5*10^7 # number of agent
N = n ÷ 500 # number of stage network
m = 3 # number of network link

β = 0.01 # infection rate
invε = 10 # inverse-epsilon

fear_threshold = 1000
fear_factor = 20

brownian = MvNormal(2, 0.05) # moving process
incubation_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)

# ------------------------------------------------------------------

ID = 1:n

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
# L = rand(1:50, n) # necessary or Lower bound
# U = L + rand(1:50, n) # sufficient or Upper bound
# personal = rand(1:100, n) # personal score
# value = zeros(Int64, n)
PUBLIC = 50 # Public score
protective = 0.1
neutral    = 0.5
aggressive = 0.9

reward_day = -7
reward_move = 3

INCUBATION = zeros(Int64, n) .- 1
  RECOVERY = zeros(Int64, n) .- 1

G = barabasi_albert(N, m)

state = Array{Char, 1}(undef, n); state .= 'S' # using SEIR model
# 'A': Aggressive, 'N': Neutral, 'P': Protective, 'R': Removed
policy = Array{Char, 1}(undef, n); policy .= 'N'
host = rand(ID, 10); state[host] .= 'I'
RECOVERY[host] .= round.(rand(recovery_period, 10)) .+ 1

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

# ------------------------------------------------------------------

LOCATION = rand(0:N, n) # macro location
# LOCATION[host] .= 1; # replace sampling
location = rand(2, n) # micro location
location_pixel = zeros(Int64, 2, n)

# ------------------------------------------------------------------
# @profview while sum(state .== 'E') + sum(state .== 'I') > 0
@time while sum(state .== 'E') + sum(state .== 'I') > 0
    T += 1

    INCUBATION .-= 1
    RECOVERY .-= 1
    state[INCUBATION .== 0] .= 'I'
    state[RECOVERY .== 0] .= 'R'

    personal = min.(100, max.(0, personal .+ reward_day))

    # value = (state .!= 'R') .*
    #  (((1 .+ (L .< personal) .+ (U .< personal)) .* personal) .+ value) ./ 2
    n_I = sum(state .== 'I')
    value = (state .!= 'R') .* (value .+ (
        personal .+ 
        fear_factor*(n_I > 100) .+
        fear_factor*(n_I > 1000)
        )) ./ 2

    policy1 =       value .== 0
    policy2 =  0 .< value .≤  L
    policy3 =  L .< value .≤  U
    policy4 =  U .< value

    policy[policy1] .= 'R'
    policy[policy2] .= 'A'
    policy[policy3] .= 'N'
    policy[policy4] .= 'P'

    decision =
    aggressive * (policy2) .+
    neutral    * (policy3) .+
    protective * (policy4)
    for id in ID[policy .!= 'R']
        if rand() < decision[id]
            if rand([true, false])
                if LOCATION[id] == 0
                    LOCATION[id] = rand(1:N)
                else
                    LOCATION[id] = rand(G.fadjlist[LOCATION[id]])
                end
                personal[id] += reward_move
            end
            personal[id] += reward_move
        else
            LOCATION[id] = 0
        end
    end

    ID_staged = ID[(LOCATION .> 0)]
    size_staged = length(ID_staged)

    push!(S_, sum(state .== 'S'))
    push!(E_, sum(state .== 'E'))
    push!(I_, sum(state .== 'I'))
    push!(R_, sum(state .== 'R'))

    push!(Re_, sum(policy1))
    push!(Ag_, sum(policy2))
    push!(Ne_, sum(policy3))
    push!(Pr_, sum(policy4))

    push!(VALUE_, mean(value))
    push!(PERSONAL_, mean(personal))
    println("T: $T - Staged: $size_staged | $(S_[T]) | $(E_[T]) | $(I_[T]) | $(R_[T]) | Value: $(PERSONAL_[T]) |")
    println("      Aggressive $(Ag_[T]) | Neutral: $(Ne_[T]) | Protective: $(Pr_[T]) |")

    for t in 1:8
        for id in ID_staged
            if rand() < decision[id]
                LOCATION[id] = rand(G.fadjlist[LOCATION[id]])
                personal[id] += reward_move
            end
        end

        # location[:,ID_staged] += rand(brownian, size_staged)
        # location_pixel = Int64.(ceil.(invε .* location))

        # print(LOCATION[state .== 'I'])
        @threads for node in unique(LOCATION[state .== 'I'])
            if node == 0 continue end
            bit_S = (LOCATION .== node) .& (state .== 'S')
            bit_I = (LOCATION .== node) .& (state .== 'I')
            ID_S = ID[bit_S]
            ID_I = ID[bit_I]

            location[:,ID_S] += rand(brownian, sum(bit_S))
            location[:,ID_I] += rand(brownian, sum(bit_I))

            location_pixel[:,ID_S] = Int64.(ceil.(invε .* location[:,ID_S]))
            location_pixel[:,ID_I] = Int64.(ceil.(invε .* location[:,ID_I]))

            for from in shuffle(ID_I)
                contated = 
                (location_pixel[1,from] .== location_pixel[1,ID_S]) .&
                (location_pixel[2,from] .== location_pixel[2,ID_S])
                if test print("$from → ") end
                for to in ID_S[contated]
                    if rand() < β
                        if test print("$to, ") end
                        state[to] = 'E'
                        INCUBATION[to] = round(rand(incubation_period))
                        RECOVERY[to] = INCUBATION[to] + round(rand(recovery_period))
                    end
                end
                if test println() end
            end
        end
    end
end

mean(L[state .== 'R'])
mean(U[state .== 'R'])

mean(L[state .!= 'R'])
mean(U[state .!= 'R'])


if visualization
    plot(PERSONAL_)
    plot(VALUE_)
    plot([E_, I_])
    plot(R_)
end

# using ProfileView
# ProfileView.view()

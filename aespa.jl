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
visualization = false

# ------------------------------------------------------------------

# variables
t = 0 # micro timestep
T = 0 # Macro timestep

# parameters
n = 10^6 # number of agent
N = n ÷ 500 # number of stage network
m = 3 # number of network link

β = 0.02 # infection rate
invε = 10 # inverse-epsilon

fear_threshold = 1000
fear_factor = 20

brownian = MvNormal(2, 0.05) # moving process
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

PERSONAL_ = Array{Float64, 1}()
VALUE_ = Array{Float64, 1}()

ID = 1:n
PUBLIC = 50 # Public score
protective = 0.1
neutral    = 0.5
aggressive = 0.9

reward_day = -7
reward_move = 3

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

G = barabasi_albert(N, m)

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
    state[RECOVERY .== 0] .= 'R'

    personal = min.(100, max.(0, personal .+ reward_day))

    # value = (state .!= 'R') .*
    #  (((1 .+ (L .< personal) .+ (U .< personal)) .* personal) .+ value) ./ 2
    n_I = sum(state .== 'I')
    value = (state .!= 'R') .* (value .+ (
        personal .+ 
        # fear_factor*(n_I > 100) .+
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
            if LOCATION[id] == 0
                LOCATION[id] = rand(1:N)
            else
                LOCATION[id] = rand(G.fadjlist[LOCATION[id]])
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

        @threads for node in setdiff(unique(LOCATION[state .== 'I']), 0)
            # if node == 0 continue end
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


plot_EI = plot(E_, label = "E", color= :red, linestyle = :dash,
 size = (400, 300), dpi = 300, legend=:topleft)
 plot!(I_, label = "I", color= :red)
 xlabel!("T"); ylabel!("#")
savefig(plot_EI, "plot_EI.png")

plot_R = plot(R_, label = "R", color= :black,
 size = (400, 300), dpi = 300, legend=:topleft)
 xlabel!("T"); ylabel!("#")
savefig(plot_R, "plot_R.png")
# end

# using ProfileView
# ProfileView.view()
# plot!(figure[2], sol,vars=(0,1),
# linestyle = :dash,  color = :black,
# label = "Theoretical", legend=:topleft)
# plot!(figure[2], 0.0:0.01:t, time_evolution,
# color = RGB(1.,94/255,0.), linewidth = 2, label = "Simulation",
# yscale = :log10, yticks = 10 .^(1:4))
# ylims!(figure[2], 0., 100.)
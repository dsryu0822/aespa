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

test = true
visualization = false

# ------------------------------------------------------------------

# variables
t = 0 # micro timestep
T = 0 # Macro timestep

# parameters
n = 10^3 # number of agent
N = n ÷ 10 # number of stage network
m = 3 # number of network link

β = 0.1 # infection rate
invε = 5 # inverse-epsilon
brownian = MvNormal(2, 0.05) # moving process
incubation_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)

# ------------------------------------------------------------------

ID = 1:n

# ------------------------------------------------------------------

# Random Setting
Random.seed!(0)

# Random Vector
L = rand(1:50, n) # necessary or Lower bound
U = L + rand(1:50, n) # sufficient or Upper bound
personal = rand(1:100, n) # personal score
value = zeros(Int64, n)
PUBLIC = 50 # Public score

INCUBATION = zeros(Int64, n) .- 1
  RECOVERY = zeros(Int64, n) .- 1

G = barabasi_albert(N, m)

state = Array{Char, 1}(undef, n); state .= 'S' # using SEIR model
# 'A': Aggressive, 'N': Neutral, 'P': Protective, 'R': Removed
policy = Array{Char, 1}(undef, n); policy .= 'N'
host = rand(ID, 10); state[host] .= 'I'
RECOVERY[host] .= round(rand(recovery_period))

S_ = Array{Int64, 1}()
E_ = Array{Int64, 1}()
I_ = Array{Int64, 1}()
R_ = Array{Int64, 1}()

# ------------------------------------------------------------------

LOCATION = zeros(Int64, n) # macro location
LOCATION[host] .= 1; LOCATION[rand(1:n, Int(4n//5))] .= 1; # replace sampling
location = rand(2, n) # micro location

# ------------------------------------------------------------------

ID_staged = ID[(LOCATION .> 0)]
size_staged = length(ID_staged)

while sum(state .== 'E') + sum(state .== 'I') > 0
    T += 1
    INCUBATION .-= 1
    RECOVERY .-= 1
    state[INCUBATION .== 0] .= 'I'
    state[RECOVERY .== 0] .= 'R'

    push!(S_, sum(state .== 'S'))
    push!(E_, sum(state .== 'E'))
    push!(I_, sum(state .== 'I'))
    push!(R_, sum(state .== 'R'))

    println("T: $T - $(S_[T]) | $(E_[T]) | $(I_[T]) | $(R_[T]) |")

    value = (state .!= 'R') .* (1 .+ (L .< personal) .+ (U .< personal)) .* personal
    policy[value .== 0]  .= 'R'
    policy[value .> 0]   .= 'A'
    policy[value .> 100] .= 'N'
    policy[value .> 200] .= 'P'

    for t in 1:1
        location[:,ID_staged] += rand(brownian, size_staged)
        location_pixel = Int.(ceil.(invε .* location))

        for node in [1]
            bit_I = (LOCATION .== node) .& (state .== 'I')
            ID_I = ID[bit_I]

            bit_S = (LOCATION .== node) .& (state .== 'S')
            ID_S = ID[bit_S]

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

if visualization
    plot([S_, E_, I_, R_])
end


function simulation(seed_number::Int64
    , blockade
    , σ
    , β
    # , D
    , NODE0
    , NODE_blocked
    , N
    , XY
    , country
    , countrynames
    , indegree
    , atlantic
)

    number_of_host = 1
    n = 800000
    end_time = 500
    T0 = 50

    latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
    recovery_period = Weibull(3, 7.17)

    ID = 1:n
    δ = 0.01
    seed = lpad(seed_number, 4, '0')

    n_S_ = Int64[]
    n_E_ = Int64[]
    n_I_ = Int64[]
    n_R_ = Int64[]
    n_V_ = Int64[]
    n_RECOVERY_ = Int64[]
    n_I_tier = zeros(Int64, end_time, 1)
    n_V_tier = zeros(Int64, end_time, 1)

    ndws_n_I_ = DataFrame([[] for _ = countrynames] , countrynames)
    ndws_n_RECOVERY_ = DataFrame([[] for _ = countrynames] , countrynames)


    T = 0 # Macro timestep
    state = fill('S', n) # using SEIR model
    LATENT = fill(-1, n)
    RECOVERY = fill(-1, n)
    TIER = zeros(Int64, n)
    # T_D = [end_time] # Timing of vaccin develop
   
    Random.seed!(seed_number);
    bit_movable = .!(rand(n) .< blockade)

    NODE = copy(NODE0)
    LOCATION = sample(1:N, Weights(data.indegree), n)
    for _ in 1:10 LOCATION = rand.(NODE[LOCATION]) end

    host = rand(ID, number_of_host)
    state[host] .= 'I'
    TIER[host]  .=  1
    LOCATION[host] .= 2935 # Wuhan, China
    RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1

    coordinate = XY[:,LOCATION] + (Float16(0.1) * randn(Float16, 2, n))

while T < end_time
    T += 1

    LATENT   .-= 1; bit_LATENT   = (LATENT   .== 0); state[bit_LATENT  ] .= 'I'
    RECOVERY .-= 1; bit_RECOVERY = (RECOVERY .== 0); state[bit_RECOVERY] .= 'R'

    TIER[bit_LATENT .&& (rand(n) .< 0.00001)] .+= 1 # Variant Virus

    bit_S = (state .== 'S'); n_S = count(bit_S); push!(n_S_, n_S);
    bit_E = (state .== 'E'); n_E = count(bit_E); push!(n_E_, n_E);
    bit_I = (state .== 'I'); n_I = count(bit_I); push!(n_I_, n_I);
    bit_R = (state .== 'R'); n_R = count(bit_R); push!(n_R_, n_R);
    bit_V = (state .== 'V'); n_V = count(bit_V); push!(n_V_, n_V);

    T == 1 ? push!(n_RECOVERY_, 0) : push!(n_RECOVERY_, n_RECOVERY_[end] + count(bit_RECOVERY))
    push!(ndws_n_I_, [sum(bit_I .&& (country[LOCATION] .== c)) for c in countrynames])
    push!(ndws_n_RECOVERY_, [sum(bit_RECOVERY .&& (country[LOCATION] .== c)) for c in countrynames]) # It has to be cumsumed

    while size(n_I_tier)[2] < maximum(TIER)
        n_I_tier = [n_I_tier zeros(Int64, end_time, 1)]
        # n_V_tier = [n_V_tier zeros(Int64, end_time, 1)]
        # push!(T_D, T + D)
    end
    n_I_tier[T, :] = [count(bit_I .&& (TIER .== tier)) for tier in 1:maximum(TIER)]'
    # n_V_tier[T, :] = [count(bit_V .&& (TIER .== tier)) for tier in 1:maximum(TIER)]'

    if n_E + n_I == 0 break end


    # for (tier, t_d) in enumerate(T_D)
    #     bit_vaccinated = ((TIER .< tier) .&& (rand(n) .< 0.01))
    #     if T > t_d
    #         state[bit_vaccinated] .= 'V'
    #         TIER[bit_vaccinated] .= tier
    #     end
    # end

    bit_passed = (((rand(n) .< σ) .&& .!bit_I) .|| ((rand(n) .< σ/100) .&& bit_I))
    if T == T0       NODE = NODE_blocked               end
    if T >= T0 bit_passed = bit_passed .&& bit_movable end
    LOCATION[bit_passed] = rand.(NODE[LOCATION[bit_passed]])
    coordinate = XY[:,LOCATION] + (Float16(0.1) * randn(Float16, 2, n))

    bit_atlantic = atlantic[LOCATION]
    bit_wuhan = (LOCATION .== 2935)
    bit_china = (country[LOCATION] .== "China")

    phase = 0
    flag_wuhan = false
    for bit_actual ∈ [bit_china, bit_atlantic, .!bit_atlantic]
        phase += 1
        if phase == 1
            if count(bit_I .&& .!bit_wuhan) |> iszero
                flag_wuhan = true
            else
                continue
            end
        end

        for tier in 1:maximum(TIER)
            β_ = (tier ∈ [2,3,5,7,11,13,17,19] ? β : 2β)

            ID_infectious = findall(bit_actual .&& (bit_I .&& (TIER .== tier)))
            if isempty(ID_infectious) continue end
            ID_susceptibl = findall(bit_actual .&& (bit_S .|| ((bit_R .|| bit_V) .&& (TIER .< tier))))
            
            kdtreeI = KDTree(coordinate[:,ID_infectious])

            in_δ = inrange(kdtreeI, coordinate[:,ID_susceptibl], δ)
            contact = length.(in_δ)
        
            bit_infected = (rand(length(ID_susceptibl)) .< (1 .- (1 - β_).^contact))
            ID_infected = ID_susceptibl[bit_infected]

            n_infected = count(bit_infected)
            state[ID_infected] .= 'E'
            LATENT[ID_infected] .= round.(rand(latent_period, n_infected))
            RECOVERY[ID_infected] .= LATENT[ID_infected] + round.(rand(recovery_period, n_infected))
            TIER[ID_infected] .= tier
        end
        if flag_wuhan break end
        
    end
end
ndws_n_RECOVERY_[:,:] = cumsum(Matrix(ndws_n_RECOVERY_), dims = 1)
ndwr = collect(ndws_n_RECOVERY_[end,:])
n_I_tier = DataFrame(n_I_tier, :auto)
max_tier = maximum(TIER)
R = n_RECOVERY_[T]
# V = n_V_[T]
time_evolution = DataFrame(; n_S_, n_E_, n_I_, n_R_, n_V_, n_RECOVERY_)
network_parity = mod(sum(length.(NODE_blocked)),2)

DATA = DataFrame(log_degree = log10.(indegree), log_R = log10.(collect(ndws_n_RECOVERY_[T,:])))
DATA = DATA[DATA.log_R .> 2,:]
log_degree = DATA.log_degree
     log_R = DATA.log_R

pandemic = nrow(DATA) > 10
# pandemic = (((ndws_n_RECOVERY_."China")[T] / n_RECOVERY_[T]) < 0.5)

if pandemic
    print(Crayon(foreground = :red), "$seed-($blockade)")
elseif n_R_[T] > 1000
    print(Crayon(foreground = :yellow), "$seed-($blockade)")
else
    print(Crayon(foreground = :green), "$seed-($blockade)")
end
# print(",$V")
print(Crayon(reset = true), " ")

(_, slope) = pandemic ? coef(lm(@formula(log_R ~ log_degree), DATA)) : (0,0)

jldsave("$seed rslt.jld2";
        max_tier, pandemic, slope, T, R, ndwr, # NODE_blocked, V,
        time_evolution, n_I_tier, #n_V_tier,
        log_degree, log_R, network_parity
        )

preview = open("cnfg.csv", "a")
println(preview, "$seed,$(now()),$max_tier,$pandemic,$slope,$T,$R")
close(preview)
        
# summary = DataFrame(
#     Tend = T, Rend = n_R_[T], Vend = n_V_[T], Recovery = n_RECOVERY_[T],
#     max_tier = max_tier,
#     pandemic = pandemic,
#     slope = slope,
# )

# CSV.write("./$seed smry.csv", summary, bom = true)
# CSV.write("./$seed tevl.csv", time_evolution)
# CSV.write("./$seed tier.csv", n_I_tier)
# CSV.write("./$seed ndwi.csv", ndws_n_I_)
# CSV.write("./$seed ndwr.csv", ndws_n_RECOVERY_)

end
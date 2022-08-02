function simulation(seed_number::Int64)
    seed = lpad(seed_number, 4, '0')
    flag_trms = false

    n_S_ = Int64[]
    n_E_ = Int64[]
    n_I_ = Int64[]
    n_R_ = Int64[]
    n_V_ = Int64[]
    n_RECOVERY_ = Int64[]
    n_I_tier = zeros(Int64, end_time, 1)

    ndws_n_I_ = DataFrame([[] for _ = countrynames] , countrynames)
    ndws_n_RECOVERY_ = DataFrame([[] for _ = countrynames] , countrynames)

    ####################################################################

    # transmission = DataFrame(
    #     T = Int64[],
    #     # t = Int64[],
    #     country = [],
    #     city = [],
    #     iata = [],
    #     from = [],
    #     to = []
    # )
    # non_transmission = copy(transmission)
    ####################################################################

    T = 0 # Macro timestep
    state = fill('S', n) # using SEIR model
    LATENT = fill(-1, n)
    RECOVERY = fill(-1, n)
    TIER = zeros(Int64, n)
   
    Random.seed!(seed_number);
    Ref_blocked = Ref(NODE_ID[rand(length(NODE_ID)) .< blockade])

    # LOCATION = rand(NODE_ID, n)
    NODE = copy(NODE0)
    LOCATION = sample(NODE_ID, Weights(data.indegree), n)
    for _ in 1:10 LOCATION = rand.(NODE[LOCATION]) end
    # initial_population = [count(LOCATION .== node) for node in NODE_ID]
    # CSV.write("./$seed init.csv", DataFrame(initial_population = initial_population))

    # plot(size = (800,400), aspect_ratio = 1)
    # scatter!(eachrow(XY[:,atlantic])..., msw = 0, alpha = 0.5, label = :none)
    # scatter!(eachrow(XY[:,.!atlantic])..., msw = 0, alpha = 0.5, label = :none)

    host = rand(ID, number_of_host)
    state[host] .= 'I'
    TIER[host]  .=  1
    LOCATION[host] .= 2935 # Wuhan, China
    RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1

    coordinate = XY[:,LOCATION] + (Float16(0.1) * randn(Float16, 2, n))
    # worldmap = scatter(XY[1,:], XY[2,:], label = "airport", legend = :bottomleft)

    bit_movable = .!(rand(n) .< blockade)
    NODE2 = copy(NODE0)
    for u in NODE_ID
        NODE2[u][NODE2[u] .∈ Ref_blocked] .= u
    end

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
    end; n_I_tier[T, :] = [count(bit_I .&& (TIER .== tier)) for tier in 1:maximum(TIER)]'

    if n_E + n_I == 0 break end

    # println("$T: |E: $(n_E_[T]) |I: $(n_I_[T]) |RECOVERY:$(n_RECOVERY_[T])")
    # println("                               maximal tier: $(maximum(TIER))")

    bit_passed = (((rand(n) .< σ) .&& .!bit_I) .|| ((rand(n) .< σ/100) .&& bit_I))
    if T == T0       NODE = NODE2                      end
    if T >= T0 bit_passed = bit_passed .&& bit_movable end
    LOCATION[bit_passed] = rand.(NODE[LOCATION[bit_passed]])
    coordinate = XY[:,LOCATION] + (Float16(0.1) * randn(Float16, 2, n))

    bit_atlantic = atlantic[LOCATION]
    bit_wuhan = (LOCATION .== 2935)
    bit_china = (country[LOCATION] .== "China")

    flag_wuhan = false
    for bit_actual ∈ [bit_china, bit_atlantic, .!bit_atlantic]
        if count(bit_I .&& .!bit_wuhan) |> iszero
            flag_wuhan = true
        else
            continue
        end

        for tier in maximum(TIER):-1:1
            β_ = (tier ∈ [2,3,5,7,11,13,17,19] ? β : 2β)

            ID_infectious = findall(bit_actual .&& (bit_I .&& (TIER .== tier)))
            if isempty(ID_infectious) continue end
            ID_susceptibl = findall(bit_actual .&& (bit_S .|| (bit_R .&& (TIER .< tier)))) # bit_V will be come
            
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

            # if flag_trms && n_infected > 0
            #     ID_from = ID_infectious[deep_pop!.(shuffle.(in_δ))[bit_infected]]
            #     append!(transmission, DataFrame(
            #         T = T,
            #         country = country[LOCATION[ID_infected]],
            #         city = city[LOCATION[ID_infected]],
            #         iata = iata[LOCATION[ID_infected]],
            #         from = ID_from, to = ID_infected
            #         ))
            # end
        end
        if flag_wuhan break end
        
    end
    if flag_trms unique!(transmission, :to) end

    # infector_list = transmission[transmission.T .== T, :from]
    # for defendant ∈ ID_infectious
    #     if defendant ∉ infector_list
    #         append!(non_transmission, DataFrame(
    #             T = T, t = 0, node_id = node, #x = 0, y = 0,
    #             from = defendant, to = 0, Break = 0
    #             ))
    #     end
    # end
end
ndws_n_RECOVERY_[:,:] = cumsum(Matrix(ndws_n_RECOVERY_), dims = 1)
n_I_tier = DataFrame(n_I_tier, :auto)
max_tier = maximum(TIER)
slope = 0

pandemic = (((ndws_n_RECOVERY_."China")[T] / n_RECOVERY_[T]) < 0.5)

if pandemic
    print(Crayon(foreground = :red), "$seed-($blockade)")
elseif n_R_[T] < 2000
    print(Crayon(foreground = :yellow), "$seed-($blockade)")
else
    print(Crayon(foreground = :green), "$seed-($blockade)")
end
print(Crayon(reset = true), " ")

if pandemic
    DATA = DataFrame(
        log_degree = log10.(degree),
        log_R = log10.(collect(ndws_n_RECOVERY_[T,:]))
    )
    DATA = DATA[DATA.log_R .> 2,:]
    (_, slope) = coef(lm(@formula(log_R ~ log_degree), DATA))
else
    DATA = DataFrame()
end

time_evolution = DataFrame(; n_S_, n_E_, n_I_, n_R_, n_V_, n_RECOVERY_)

# summary = DataFrame(
#     Tend = T, Rend = n_R_[T], Vend = n_V_[T], Recovery = n_RECOVERY_[T],
#     max_tier = max_tier,
#     pandemic = pandemic,
#     slope = slope,
# )

jldsave("$seed smry.jld2"; time_evolution, n_I_tier, DATA,
        max_tier, pandemic, slope, T, R = n_RECOVERY_[T])

# CSV.write("./$seed smry.csv", summary, bom = true)
# CSV.write("./$seed tevl.csv", time_evolution)
# CSV.write("./$seed tier.csv", n_I_tier)
# CSV.write("./$seed ndwi.csv", ndws_n_I_)
# CSV.write("./$seed ndwr.csv", ndws_n_RECOVERY_)

if flag_trms
    append!(transmission, non_transmission)
    sort!(transmission, :T)
    CSV.write("./$seed trms.csv", transmission)
end

end
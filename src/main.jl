function simulation(seed_number)

    Random.seed!(seed_number);
    NODE = copy(NODE0)
    seed = lpad(seed_number, 4, '0')
    flag_trms = false

    ####################################################################

    n_S_ = Int64[]
    n_E_ = Int64[]
    n_I_ = Int64[]
    n_R_ = Int64[]
    n_V_ = Int64[]
    n_RECOVERY_ = Int64[]
    n_I_tier = zeros(Int64, end_time, 1)

    ndws_n_I_ = DataFrame([[] for _ = countrynames] , countrynames)
    ndws_n_RECOVERY_ = DataFrame([[] for _ = countrynames] , countrynames)


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
    
    # LOCATION = rand(NODE_ID, n)
    LOCATION = sample(NODE_ID, Weights(data.indegree), n)
    for _ in 1:10 LOCATION = rand.(NODE[LOCATION]) end
    # initial_population = [count(LOCATION .== node) for node in NODE_ID]
    # CSV.write("./$seed init.csv", DataFrame(initial_population = initial_population))

    # plot(size = (800,400), aspect_ratio = 1)
    # scatter!(eachrow(XY[:,bit_left])..., msw = 0, alpha = 0.5, label = :none)
    # scatter!(eachrow(XY[:,.!bit_left])..., msw = 0, alpha = 0.5, label = :none)

    host = rand(ID, number_of_host)
    state[host] .= 'I'
    LOCATION[host] .= 2935 # Wuhan, China
    RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1
    TIER[host] .= 1

    coordinate = XY[:,LOCATION] + (0.1 * randn(2, n))
    # worldmap = scatter(XY[1,:], XY[2,:], label = "airport", legend = :bottomleft)

    bit_movable = .!(rand(n) .< blockade)
    Ref_blocked = Ref(NODE_ID[rand(length(NODE_ID)) .< blockade])
    NODE2 = copy(NODE0)
    for u in NODE_ID
        NODE2[u][NODE2[u] .∈ Ref_blocked] .= u
    end

# movie = @animate 
print(">")
while T < end_time
    T += 1
    # plot_fm = scatter(worldmap, coordinate[1,ID_infectious], coordinate[2,ID_infectious], label = :none,
    #     markersize = 2)
    # plot_te = plot()
    # for x_ in eachcol(n_I_tier)
    #     plot_te!(x_)
    # end
    # plot_2 = plot(plot_fm, plot_te)

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
    if T ≥ T0
        NODE = NODE2
        bit_passed = bit_passed .&& bit_movable
    end
    LOCATION[bit_passed] = rand.(NODE[LOCATION[bit_passed]])
    coordinate = XY[:,LOCATION] + (0.1 * randn(2, n))

    for bit_atlantic in [atlantic[LOCATION], .!atlantic[LOCATION]]
    for tier in maximum(TIER):-1:1
        tier ∈ [2,3,5,7,11,13,17,19] ? β_ = β : β_ = 2β

        ID_infectious = findall(bit_atlantic .&& bit_I .&& (TIER .== tier))
        ID_susceptibl = findall(bit_atlantic .&& bit_S .|| (bit_R .&& (TIER .< tier))) # bit_V will be come
    
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

        if flag_trms && n_infected > 0
            ID_from = ID_infectious[deep_pop!.(shuffle.(in_δ))[bit_infected]]
            append!(transmission, DataFrame(
                T = T,
                country = country[LOCATION[ID_infected]],
                city = city[LOCATION[ID_infected]],
                iata = iata[LOCATION[ID_infected]],
                from = ID_from, to = ID_infected
                ))
        end
    end
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
max_tier = maximum(TIER)
print(Crayon(foreground = :light_gray), ": $(n_RECOVERY_[T]), ")

if flag_trms
    append!(transmission, non_transmission)
    sort!(transmission, :T)
    CSV.write("./$seed trms.csv", transmission)
end
time_evolution = DataFrame(;
    n_S_, n_E_, n_I_, n_R_, n_V_
    , n_RECOVERY_
# , RT_, contact_, SI_
)
summary = DataFrame(
    Tend = T, Rend = n_R_[T], Vend = n_V_[T], Recovery = n_RECOVERY_[T], max_tier = max_tier,
    USend = (ndws_n_RECOVERY_."United States")[T],
    UKend = (ndws_n_RECOVERY_."United Kingdom")[T],
    KRend = (ndws_n_RECOVERY_."Korea, Rep.")[T],
    CNend = (ndws_n_RECOVERY_."China")[T]
)
ndws_n_RECOVERY_[:,:] = cumsum(Matrix(ndws_n_RECOVERY_), dims = 1)

CSV.write("./$seed tevl.csv", time_evolution)
CSV.write("./$seed ndwi.csv", ndws_n_I_)
CSV.write("./$seed ndwr.csv", ndws_n_RECOVERY_)
CSV.write("./$seed smry.csv", summary, bom = true)
CSV.write("./$seed tier.csv", DataFrame(n_I_tier, :auto))
# if n_R_[T] > 1000
#     mp4(movie, "./$seed muvi.mp4", fps = 10)
#     png(plot(n_I_, label = "I"), "./$seed tevl.png")
# end
end
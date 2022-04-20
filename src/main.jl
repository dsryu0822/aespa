function simulation(
    seed_number;
    vaccin = false,
    video = false)

    Random.seed!(seed_number);
    seed = lpad(seed_number, 4, '0')

    ####################################################################

    n_S_ = Int64[]
    n_E_ = Int64[]
    n_I_ = Int64[]
    n_R_ = Int64[]
    n_V_ = Int64[]

    transmission = DataFrame(
        T = Int64[],
        # t = Int64[],
        country = [],
        city = [],
        iata = [],
        from = [],
        to = []
    )
    non_transmission = copy(transmission)
    ndws_n_ = DataFrame([[] for _ = countrynames] , countrynames)

    ####################################################################

    T = 0 # Macro timestep
    state = fill('S', n) # using SEIR model
    LATENT = fill(-1, n)
    RECOVERY = fill(-1, n)
    
    # LOCATION = rand(NODE_ID, n)
    LOCATION = sample(NODE_ID, Weights(data.indegree), n)
    for _ in 1:10 LOCATION = rand.(NODE[LOCATION]) end
    # initial_population = [count(LOCATION .== node) for node in NODE_ID]
    # CSV.write("./$seed init.csv", DataFrame(initial_population = initial_population))
    # scatter(collect(data.indegree), initial_population)
    # scatter!(coordinate[1,:], coordinate[2,:], label = :none,
    #     markersize = 1, markercolor = :red)
    
    host = rand(ID, number_of_host)
    state[host] .= 'I'
    LOCATION[host] .= 2935 # Wuhan, China
    RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1

    coordinate = XY[:,LOCATION] + randn(2, n)
    worldmap = scatter(XY[1,:], XY[2,:], label = "airport", legend = :bottomleft)
    
movie = @animate while T < end_time
    T += 1

    LATENT   .-= 1
    RECOVERY .-= 1
    bit_LATENT     = (LATENT   .== 0)
    bit_RECOVERY   = (RECOVERY .== 0)
    state[bit_LATENT  ] .= 'I'
    state[bit_RECOVERY] .= 'R'

    bit_S = (state .== 'S'); n_S = count(bit_S); push!(n_S_, n_S); ID_S = findall(bit_S)
    bit_E = (state .== 'E'); n_E = count(bit_E); push!(n_E_, n_E);
    bit_I = (state .== 'I'); n_I = count(bit_I); push!(n_I_, n_I); ID_I = findall(bit_I)
    bit_R = (state .== 'R'); n_R = count(bit_R); push!(n_R_, n_R);
    bit_V = (state .== 'V'); n_V = count(bit_V); push!(n_V_, n_V);

    push!(ndws_n_, [sum(bit_I .&& (country[LOCATION] .== c)) for c in countrynames])
    if n_E + n_I == 0 break end

    # println("$T: |E: $(n_E_[T]) |I: $(n_I_[T]) |R:$(n_R_[T]) |V:$(n_V_[T])")

    moved = (rand(n) .< σ) .&& .!bit_I
    LOCATION[moved] = rand.(NODE[LOCATION[moved]])
    moved = (rand(n) .< σ/100) .&& bit_I
    LOCATION[moved] = rand.(NODE[LOCATION[moved]])
    coordinate = XY[:,LOCATION] + randn(2, n)

    frame = scatter(worldmap, coordinate[1,ID_I], coordinate[2,ID_I], label = :none,
        markersize = 2)

    kdtreeI = KDTree(coordinate[:,ID_I])
            
    in_δ = inrange(kdtreeI, coordinate[:,ID_S], δ)
    contact = length.(in_δ)

    bit_infected = (rand(n_S) .< (1 .- (1 - β).^contact))
    ID_infected = ID_S[bit_infected]
            
    n_infected = count(bit_infected)
    state[ID_infected] .= 'E'
    LATENT[ID_infected] .= round.(rand(latent_period, n_infected))
    RECOVERY[ID_infected] .= LATENT[ID_infected] + round.(rand(recovery_period, n_infected))

    if n_infected > 0
        from_id = ID_I[deep_pop!.(shuffle.(in_δ))[bit_infected]]
        append!(transmission, DataFrame(
            T = T,
            country = country[LOCATION[ID_infected]],
            city = city[LOCATION[ID_infected]],
            iata = iata[LOCATION[ID_infected]],
            from = from_id, to = ID_infected
            ))
    end
    unique!(transmission, :to)

    # infector_list = transmission[transmission.T .== T, :from]
    # for defendant ∈ ID_I
    #     if defendant ∉ infector_list
    #         append!(non_transmission, DataFrame(
    #             T = T, t = 0, node_id = node, #x = 0, y = 0,
    #             from = defendant, to = 0, Break = 0
    #             ))
    #     end
    # end
end

print(Crayon(foreground = :light_gray), ": $(n_R_[T]), ")

if seed_number != 0 append!(transmission, non_transmission); sort!(transmission, :T) end
time_evolution = DataFrame(;
    n_S_, n_E_, n_I_, n_R_, n_V_
# , RT_, contact_, SI_
)

summary = DataFrame(
    Tend = T, Rend = n_R_[T], Vend = n_V_[T]
)
CSV.write("./$seed trms.csv", transmission)
CSV.write("./$seed tevl.csv", time_evolution)
CSV.write("./$seed ndws.csv", ndws_n_)
CSV.write("./$seed smry.csv", summary, bom = true)
if n_R_[T] > 1000
    mp4(movie, "./$seed muvi.mp4", fps = 10)
    png(plot(n_I_, label = "I"), "./$seed tevl.png")
end
end
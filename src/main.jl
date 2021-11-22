function simulation(
    seed_number;
    moving = false,
    vaccin = false)

    folder = (moving ? 'M' : '0') * (vaccin ? 'V' : '0')
    Random.seed!(seed_number); print(seed_number)

    ####################################################################

    n_S_ = Int64[]
    n_E_ = Int64[]
    n_I_ = Int64[]
    n_R_ = Int64[]
    n_V_ = Int64[]
    n_hub_ = Int64[]

    RT_ = Float64[]

    S_influx_ = Int64[]
    I_influx_ = Int64[]
    E_influx_ = Int64[]
    R_influx_ = Int64[]
    V_influx_ = Int64[]

    S_outflux_ = Int64[]
    I_outflux_ = Int64[]
    E_outflux_ = Int64[]
    R_outflux_ = Int64[]
    V_outflux_ = Int64[]

    if seed_number != 0 n_NODE_S_ = zeros(Int64, end_time, N) end
    if seed_number != 0 n_NODE_I_ = zeros(Int64, end_time, N) end

    transmission = DataFrame(
        T = Int64[],
        t = Int64[],
        node_id = Int64[],
        from = Int64[],
        to = Int64[],
        Break = Int64[]
    )
    non_transmission = copy(transmission)

    ####################################################################

    T = 0 # Macro timestep
    state = repeat(['S'], n) # using SEIR model
    host = rand(ID, number_of_host); state[host] .= 'I'

    LATENT = repeat([-1], n)
    RECOVERY = repeat([-1], n)
    RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1

    coordinate = rand(Float16, 2, n) # micro location
    LOCATION = rand(1:N, n) # macro location
    for _ in 1:5 LOCATION = rand.(NODE[LOCATION]) end

while sum(state .== 'E') + sum(state .== 'I') > 0
    if T ≥ end_time
        break
    else
        T += 1
    end
    # if T == 38 Random.seed!(seed_number) end

    LATENT   .-= 1
    RECOVERY .-= 1
    bit_LATENT     = (LATENT   .== 0)
    bit_RECOVERY   = (RECOVERY .== 0)
    state[bit_LATENT  ] .= 'I'
    state[bit_RECOVERY] .= 'R'

    bit_S = (state .== 'S'); n_S = count(bit_S); push!(n_S_, n_S)
    bit_E = (state .== 'E'); n_E = count(bit_E); push!(n_E_, n_E)
    bit_I = (state .== 'I'); n_I = count(bit_I); push!(n_I_, n_I)
    bit_R = (state .== 'R'); n_R = count(bit_R); push!(n_R_, n_R)
    bit_V = (state .== 'V'); n_V = count(bit_V); push!(n_V_, n_V)
    bit_hub = ((LOCATION .== 5) .| (LOCATION .== 4)) ; n_hub = count(bit_hub); push!(n_hub_, n_hub)

    # if T > 0
    #     println("$T: |E: $(n_E_[T]) |I: $(n_I_[T]) |R:$(n_R_[T]) |V:$(n_V_[T])")
    # end

    mobility = σ
    if n_I > θ
        if vaccin state[bit_S .& (rand(n) .< p_V)] .= 'V' end
        if moving mobility = σ*e_σ end
    end
    moved = (rand(n) .< mobility)
    bit_in = (moved .& bit_hub)
    push!(S_outflux_, count(bit_in .& bit_S))
    push!(E_outflux_, count(bit_in .& bit_E))
    push!(I_outflux_, count(bit_in .& bit_I))
    push!(R_outflux_, count(bit_in .& bit_R))
    push!(V_outflux_, count(bit_in .& bit_V))

    LOCATION[moved] = rand.(NODE[LOCATION[moved]])
    bit_out = (moved .& .!(bit_hub)) .& ((LOCATION .== 5) .| (LOCATION .== 4))
    push!(S_influx_, count(bit_out .& bit_S))
    push!(E_influx_, count(bit_out .& bit_E))
    push!(I_influx_, count(bit_out .& bit_I))
    push!(R_influx_, count(bit_out .& bit_R))
    push!(V_influx_, count(bit_out .& bit_V))

    NODE_I = unique(LOCATION[bit_I])
    for node in NODE_I
        bit_node = (LOCATION .== node); n_micro = count(bit_node)

        bit_micro_S = bit_node .& bit_S
        # bit_micro_E = bit_node .& bit_E
        bit_micro_I = bit_node .& bit_I
        bit_micro_V = bit_node .& bit_V

        ID_S = ID[bit_micro_S]; n_micro_S = count(bit_micro_S)
        # ID_E = ID[bit_micro_E]; n_micro_E = count(bit_micro_E)
        ID_I = ID[bit_micro_I]; n_micro_I = count(bit_micro_I)
        ID_V = ID[bit_micro_V]; n_micro_V = count(bit_micro_V)

        if seed_number != 0 n_NODE_S_[T, node] = n_micro_S end
        if seed_number != 0 n_NODE_I_[T, node] = n_micro_I end
        for t in 1:24
            coordinate[:,bit_node] = mod.(coordinate[:,bit_node] + rand(brownian, n_micro), 1.0)
            kdtreeI = KDTree(coordinate[:,ID_I])
            
            if (n_micro_S == 0) continue end # transmission I to S
            in_δ = inrange(kdtreeI, coordinate[:,ID_S], δ)
            contact = length.(in_δ)
            bit_infected = (rand(n_micro_S) .< (1 .- (1 - β).^contact))
            ID_infected = ID_S[bit_infected]
            
            n_infected = count(bit_infected)
            if n_infected > 0
                from_id = ID_I[deep_pop!.(shuffle.(in_δ))[bit_infected]]
                append!(transmission, DataFrame(
                    T = T, t = t, node_id = node,
                    from = from_id, to = ID_infected, Break = 0
                    ))
            end
            state[ID_infected] .= 'E'
            LATENT[ID_infected] .= round.(rand(latent_period, n_infected))
            RECOVERY[ID_infected] .= LATENT[ID_infected] + round.(rand(recovery_period, n_infected))

            if (n_micro_V == 0) continue end # transmission I to V
            in_δ = inrange(kdtreeI, coordinate[:,ID_V], δ)
            contact = length.(in_δ)
            bit_infected = (rand(n_micro_V) .< (1 .- (1 - β*e_V).^contact))
            ID_infected = ID_V[bit_infected]
            
            n_infected = count(bit_infected)
            if n_infected > 0
                from_id = ID_I[deep_pop!.(shuffle.(in_δ))[bit_infected]]
                append!(transmission, DataFrame(
                    T = T, t = t, node_id = node,
                    from = from_id, to = ID_infected, Break = 1
                    ))
            end
            state[ID_infected] .= 'E'
            LATENT[ID_infected] .= round.(rand(latent_period, n_infected))
            RECOVERY[ID_infected] .= LATENT[ID_infected] + round.(rand(recovery_period, n_infected))
        end
        unique!(transmission, :to)

        infector_list = transmission[transmission.T .== T, :from]
        for defendant ∈ ID_I
            if defendant ∉ infector_list
                append!(non_transmission, DataFrame(
                    T = T, t = 0, node_id = node, #x = 0, y = 0,
                    from = defendant, to = 0, Break = 0
                    ))
            end
        end
    end
    
    now_I = ID[state .== 'I']
    push!(
        RT_,
        isempty(now_I) ? 0 : nrow(transmission[transmission[:,:from] .∈ Ref(now_I),:]) / length(now_I))
end

    T1 = sufficientN(RT_ .< 1)
    peaktime = argmax(n_I_)
    peaksize = maximum(n_I_)
    # if T == end_time
    print(": $(n_R_[T]), ")
    if true
        seed = lpad(seed_number, 4, '0')
        
        node_incidence = transmission.node_id                                                       # 01
        if seed_number != 0 append!(transmission, non_transmission); sort!(transmission, :T) end    # 02
        time_evolution = DataFrame(
n_S_ = n_S_, n_E_ = n_E_, n_I_ = n_I_, n_R_ = n_R_, n_V_ = n_V_, n_hub_ = n_hub_, RT_ = RT_,
S_influx_ = S_influx_, I_influx_ = I_influx_, E_influx_ = E_influx_, R_influx_ = R_influx_, V_influx_ = V_influx_,
S_outflux_ = S_outflux_, I_outflux_ = I_outflux_, E_outflux_ = E_outflux_, R_outflux_ = R_outflux_, V_outflux_ = V_outflux_
        )

        # node_incidence = transmission[transmission.to .> 0,:node_id]
        count_node_incidence = [count(node_incidence .== node_id) for node_id ∈ 1:N]
        incidence5 = count_node_incidence[5]                                                        # 03
        incidence4 = count_node_incidence[4]
        hub_incidence_rate = (incidence5 + incidence4) / sum(count_node_incidence)
        incidence_entropy = entropy(count_node_incidence ./ sum(count_node_incidence), N)

        summary = DataFrame(Tend = T, RTend = n_R_[T], peaktime = peaktime, peaksize = peaksize,
         incidence5 = incidence5, incidence4 = incidence4, HIR = hub_incidence_rate,
         incidence_entropy = incidence_entropy,
         T1 = T1, RT1 = n_R_[T1], VT1 = n_V_[T1])

        if export_type != :XLSX
            if seed_number != 0 CSV.write("./$folder/$seed trms.csv", transmission) end
            if seed_number != 0 CSV.write("./$folder/$seed ndwi.csv", DataFrame(n_NODE_S_, :auto)) end
            if seed_number != 0 CSV.write("./$folder/$seed ndws.csv", DataFrame(n_NODE_I_, :auto)) end
            if seed_number != 0 CSV.write("./$folder/$seed ndwf.csv", DataFrame(n_NODE_S_ .* n_NODE_I_, :auto)) end # Force of infection
            CSV.write("./$folder/$seed tevl.csv", time_evolution)
            CSV.write("./$folder/$seed smry.csv", summary, bom = true)
        elseif export_type != :CSV
            XLSX.writetable(
                "./$folder/$seed.xlsx",
                time_evolution = ( collect(eachcol(time_evolution)), names(time_evolution) ),
                transmission = ( collect(eachcol(transmission)), names(transmission) ),
                config = ( collect(eachcol(config)), names(config) ),
                summary = ( collect(eachcol(summary)), names(summary) )
            )
        end
    end
end
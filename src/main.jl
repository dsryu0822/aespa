function simulation(
    seed_number;
    moving = false,
    vaccin = false)

    folder = (moving ? 'M' : '0') * (vaccin ? 'V' : '0')
    Random.seed!(seed_number);
    if folder == "00"
        print(Crayon(foreground = :white), seed_number)
    elseif folder == "0V"
        print(Crayon(foreground = :light_red), seed_number)
    elseif folder == "M0"
        print(Crayon(foreground = :light_blue), seed_number)
    elseif folder == "MV"
        print(Crayon(foreground = :magenta), seed_number)
    end
    seed = lpad(seed_number, 4, '0')

    ####################################################################

    n_S_ = Int64[]
    n_E_ = Int64[]
    n_I_ = Int64[]
    n_R_ = Int64[]
    n_V_ = Int64[]

    # RT_ = Float64[]
    # contact_ = Int64[]
    # SI_ = Int64[]

    n_NODE_n_ = DataFrame(zeros(Int64, end_time, N), NODE_ID)
    n_NODE_S_ = DataFrame(zeros(Int64, end_time, N), NODE_ID)
    n_NODE_E_ = DataFrame(zeros(Int64, end_time, N), NODE_ID)
    n_NODE_I_ = DataFrame(zeros(Int64, end_time, N), NODE_ID)
    n_NODE_R_ = DataFrame(zeros(Int64, end_time, N), NODE_ID)
    n_NODE_V_ = DataFrame(zeros(Int64, end_time, N), NODE_ID)

    transmission = DataFrame(
        T = Int64[],
        t = Int64[],
        node_id = [],
        from = [],
        to = [],
        Break = Int64[]
    )
    non_transmission = copy(transmission)

    ####################################################################

    T = 0 # Macro timestep
    state = fill('S', n) # using SEIR model
    LATENT = fill(-1, n)
    RECOVERY = fill(-1, n)

    coordinate = rand(Float16, 2, n) + rand(Int16, 2, n)

    if metapopulation == :euler
        LOCATION = rand(NODE_ID, n)
        for _ in 1:5 LOCATION = rand.(getindex.(Ref(NODE),LOCATION)) end
        host = rand(ID, number_of_host)
    else
        country = sample(NODE_ID, Weights(initial_population), n) # macro location
        LOCATION = copy(country)
        host = rand(ID[LOCATION .== "China"], number_of_host)
    end
    state[host] .= 'I'
    RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1
    
while T < end_time
    T += 1

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
    if n_E + n_I == 0 break end

    # println("$T: |E: $(n_E_[T]) |I: $(n_I_[T]) |R:$(n_R_[T]) |V:$(n_V_[T])")

    mobility = σ
    if n_I > θ
        if vaccin state[bit_S .& (rand(n) .< p_V)] .= 'V' end
        if moving mobility = σ*e_σ end
    end
    moved = (rand(n) .< mobility)

    if metapopulation == :lagrange
        comeback = (rand(n) .< 0.1)
        LOCATION[comeback] .= country[comeback]
        LOCATION[moved] = rand.(getindex.(Ref(NODE),LOCATION[moved]))
    elseif metapopulation == :euler
        # LOCATION[moved] = rand.(NODE[LOCATION[moved]])
        LOCATION[moved] = rand.(getindex.(Ref(NODE),LOCATION[moved]))
    elseif metapopulation == :swap
        DESTINATION = rand.(getindex.(Ref(NODE),LOCATION[moved]))
        go_ID = ID[moved]
        go_LOCATION = LOCATION[go_ID]
        come_candidate = Dict()
        for node in NODE_ID
            push!(come_candidate, node => setdiff(ID[LOCATION .== node], go_ID))
        end
        for (go_id, go_location, desination) in zip(go_ID, go_LOCATION, DESTINATION)
            if !isempty(come_candidate[desination])
                come_id = pop!(come_candidate[desination])
                LOCATION[come_id] = go_location
                LOCATION[go_id] = desination
                # coordinate[:, come_id] += rand(Int64,2)
                # coordinate[:, go_id] += rand(Int64,2)
            end
        end        
    end

    # contact_t = 0
    # SI_t = 0
    NODE_I = unique(LOCATION[bit_I])
    for node in NODE_I
    # for node in NODE_ID
        bit_node    = (LOCATION.==node);                       ; n_micro_n = count(bit_node   ); n_NODE_n_[T, node] = n_micro_n
        bit_micro_S = bit_node .& bit_S; ID_S = ID[bit_micro_S]; n_micro_S = count(bit_micro_S); n_NODE_S_[T, node] = n_micro_S
        bit_micro_I = bit_node .& bit_I; ID_I = ID[bit_micro_I]; n_micro_I = count(bit_micro_I); n_NODE_I_[T, node] = n_micro_I
        bit_micro_V = bit_node .& bit_V; ID_V = ID[bit_micro_V]; n_micro_V = count(bit_micro_V); n_NODE_V_[T, node] = n_micro_V
        bit_micro_R = bit_node .& bit_R;                       ; n_micro_R = count(bit_micro_R); n_NODE_R_[T, node] = n_micro_R
      # bit_micro_E = bit_node .& bit_E; ID_E = ID[bit_micro_E]; n_micro_E = count(bit_micro_E); n_NODE_E_[T, node] = n_micro_E

        # SI_t += n_micro_S*n_micro_I

        # if seed_number != 0 n_NODE_S_[T, node] = n_micro_S end
        # if seed_number != 0 n_NODE_I_[T, node] = n_micro_I end
        for t in 1:5
            # coordinate[:,bit_node] = mod.(coordinate[:,bit_node] + randn(Float16, 2, n_micro_n), area[node])
            coordinate[:,bit_node] = mod.(coordinate[:,bit_node] + 0.01randn(Float16, 2, n_micro_n), 1)

            if n_micro_I == 0 continue end
            kdtreeI = KDTree(coordinate[:,ID_I])
            
            if (n_micro_S == 0) continue end # transmission I to S
            in_δ = inrange(kdtreeI, coordinate[:,ID_S], δ)
            contact = length.(in_δ)
            # contact_t += sum(contact)

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

            if !(e_V > 0) continue end # for efficient simulation
            if (n_micro_V == 0) continue end # transmission I to V
            in_δ = inrange(kdtreeI, coordinate[:,ID_V], δ)
            contact = length.(in_δ)
            # contact_t += sum(contact)

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
    # push!(contact_, contact_t)
    # push!(SI_, SI_t)

    # now_I = ID[state .== 'I']
    # push!(
    #     RT_,
    #     isempty(now_I) ? 0 : nrow(transmission[transmission[:,:from] .∈ Ref(now_I),:]) / length(now_I))
end

bit_R = (state .== 'R')
for node in NODE_ID
    n_NODE_R_[T, node] = count((LOCATION .== node) .& bit_R)
end

print(Crayon(foreground = :light_gray), ": $(n_R_[T]), ")
# T1 = sufficientN(RT_ .< 1)
peaktime = argmax(n_I_)
peaksize = maximum(n_I_)
# if T == end_time
# if true

# fromby = groupby(transmission, :from)
# agent_id = Int64[]
# node_id = []
# home = Int64[]
# away = Int64[]
# for agent ∈ fromby
#     node_infected = agent.node_id[1]
#     push!(agent_id, agent.from[1])
#     push!(node_id, node_infected)
#     push!(home, count(agent.node_id .== node_infected))
#     push!(away, count(agent.node_id .!= node_infected))
# end
# case = home .+ away
# agent_seconarycases = DataFrame(; agent_id, node_id, case, home, away)

if seed_number != 0 append!(transmission, non_transmission); sort!(transmission, :T) end
time_evolution = DataFrame(;
    n_S_, n_E_, n_I_, n_R_, n_V_
# , RT_, contact_, SI_
)

# count_node_incidence = [count(node_incidence .== node_id) for node_id ∈ 1:N]
# incidence5 = count_node_incidence[5]
# incidence4 = count_node_incidence[4]
# hub_incidence_rate = (incidence5 + incidence4) / sum(count_node_incidence)
# incidence_entropy = entropy(count_node_incidence ./ sum(count_node_incidence), N)

summary = DataFrame(
    Tend = T, Rend = n_R_[T], Vend = n_V_[T]
    , peaktime = peaktime, peaksize = peaksize
    # incidence5 = incidence5, incidence4 = incidence4, HIR = hub_incidence_rate,
    # incidence_entropy = entropy_[T], incidence_var = var_[T],
    # T1 = T1, RT1 = n_R_[T1], VT1 = n_V_[T1],
    # , home = sum(home), away = sum(away)
)

# if export_type != :XLSX
CSV.write("./$folder/$seed n_NODE_n_.csv", n_NODE_n_[1:T, :])
CSV.write("./$folder/$seed n_NODE_S_.csv", n_NODE_S_[1:T, :])
CSV.write("./$folder/$seed n_NODE_E_.csv", n_NODE_E_[1:T, :])
CSV.write("./$folder/$seed n_NODE_I_.csv", n_NODE_I_[1:T, :])
CSV.write("./$folder/$seed n_NODE_R_.csv", n_NODE_R_[1:T, :])
CSV.write("./$folder/$seed n_NODE_V_.csv", n_NODE_V_[1:T, :])
CSV.write("./$folder/$seed trms.csv", transmission)
# CSV.write("./$folder/$seed agnt.csv", agent_seconarycases)
CSV.write("./$folder/$seed tevl.csv", time_evolution)
CSV.write("./$folder/$seed smry.csv", summary, bom = true)
# elseif export_type != :CSV
#     XLSX.writetable(
#         "./$folder/$seed.xlsx",
#         time_evolution = ( collect(eachcol(time_evolution)), names(time_evolution) ),
#         transmission = ( collect(eachcol(transmission)), names(transmission) ),
#         config = ( collect(eachcol(config)), names(config) ),
#         summary = ( collect(eachcol(summary)), names(summary) )
#     )
# end
# end
end
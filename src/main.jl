function simulation(seed_number::Int64
    , flag_test
    , blockade
    , T0
    , σ
    , β
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
    # T0 = 50

    NODE = copy(NODE0)
    latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
    recovery_period = Weibull(3, 7.17)

    δ = 0.018
    seed = lpad(seed_number, 4, '0')

    n_I_tier = zeros(Int64, end_time, 1)
    ndwi_ = DataFrame([Int64[] for _ = countrynames] , countrynames)
    ndwt_ = DataFrame([Int64[] for _ = countrynames] , countrynames)
    TE = DataFrame(n_S_ = Int64[], n_E_ = Int64[], n_I_ = Int64[], n_R_ = Int64[], n_T_ = Int64[], n_M_ = Int64[]) # Time evolution
    BD = DataFrame(T = Int64[], strain = Int64[], tier = Int64[], location = Int64[], prey = Int64[]) # Birth-death

    T = 0 # Macro timestep
    state    = fill('S', n) # using SEIR model
    LATENT   = fill(-1, n)
    RECOVERY = fill(-1, n)
    TIER     = fill(-1, n)
    STRAIN   = zeros(Int64, n)
    n_T = 0 # number of cummulative total cases. see the update process for `RECOVERY`
    first_escape = Int64[]
    flag_escape = false
    
    Random.seed!(seed_number);
    # bit_movable = .!(rand(n) .< blockade)

    LOCATION = sample(1:N, Weights(data.indegree), n)
    for _ in 1:10 LOCATION = rand.(NODE[LOCATION]) end

             host   = rand(1:n, number_of_host)
       state[host] .= 'I'
        TIER[host] .=  0
    LOCATION[host] .= 2935 # Wuhan, China
    RECOVERY[host] .= round.(rand(recovery_period, number_of_host)) .+ 1
      STRAIN[host]  = host

    push!(BD, [1, host[1], 0, 2935, count(LOCATION .== 2935)]) # birth-death matrix, [T strain tier location] location 0 means death
    pregenogram = [0 => host[1]]
    alive_strain = [host[1]]

    coordinate = XY[:,LOCATION] + (Float16(0.1) * randn(Float16, 2, n))
    bits_C = [(country[LOCATION] .== c) for c in countrynames]
    
while T < end_time
    T += 1

    @inbounds LATENT   .-= 1; bit_LATENT   = (LATENT   .== 0); state[bit_LATENT  ] .= 'I'
    @inbounds RECOVERY .-= 1; bit_RECOVERY = (RECOVERY .== 0); state[bit_RECOVERY] .= 'R'; n_T += count(bit_RECOVERY)
                             state[alive_strain ∩ findall(bit_RECOVERY)] .= 'X' # exception, coding issue

    @inbounds bit_S = (state .== 'S'); n_S = count(bit_S)
    @inbounds bit_E = (state .== 'E'); n_E = count(bit_E)
    @inbounds bit_I = (state .== 'I'); n_I = count(bit_I)
    @inbounds bit_R = (state .== 'R'); n_R = count(bit_R)
    push!(ndwi_, [sum(       bit_I .&& c) for c in bits_C])
    push!(ndwt_, [sum(bit_RECOVERY .&& c) for c in bits_C]) # It should be cumsummed

    new_strain = findall(bit_LATENT .&& (rand(n) .< -0.00001))
    append!(pregenogram, STRAIN[new_strain] .=> new_strain)
    append!(alive_strain, new_strain)
    TIER[new_strain] .+= 1 # Variant Virus
    STRAIN[new_strain] .= new_strain # Variant Virus
    for strain in new_strain
        prey = count((LOCATION .== LOCATION[strain]) .&& (TIER .< TIER[strain]) .&& (bit_S .|| bit_R))
        push!(BD, [T, strain, TIER[strain], LOCATION[strain], prey])
    end

    while size(n_I_tier)[2] ≤ maximum(TIER)
        n_I_tier = [n_I_tier zeros(Int64, end_time, 1)]
    end
    n_I_tier[T, :] = [count(bit_I .&& (TIER .== tier)) for tier in 0:maximum(TIER)]'

    lost_strain = setdiff(alive_strain, STRAIN[bit_E .|| bit_I])
    for strain in lost_strain
        prey = count((LOCATION .== LOCATION[strain]) .&& (TIER .< TIER[strain]) .&& (bit_S .|| bit_R))
        push!(BD, [T, strain, TIER[strain], 0, prey])
    end
    setdiff!(alive_strain, lost_strain)

    if n_E + n_I == 0 break end

    
    __LOCATION = deepcopy(LOCATION)
    bit_passed = (((rand(n) .< σ) .&& .!bit_I) .|| ((rand(n) .< σ/100) .&& bit_I))
    if T == T0       NODE = NODE_blocked               end
    # if T >= T0 bit_passed = bit_passed .&& bit_movable end
    LOCATION[bit_passed] = rand.(NODE[LOCATION[bit_passed]])
    bit_moved = (LOCATION .!= __LOCATION); n_M = count(bit_moved)
    coordinate[:, bit_moved] .= XY[:,LOCATION[bit_moved]] .+ (Float16(0.1) * randn(Float16, 2, count(bit_moved)))

    push!(TE, [n_S, n_E, n_I, n_R, n_T, n_M])
    if !flag_escape && count(bit_moved .&& bit_I) > 0
        first_escape = LOCATION[bit_moved .&& bit_I]
        flag_escape = true
    end

    bit_atlantic = atlantic[LOCATION]
    bit_wuhan = (LOCATION .== 2935)
    bit_china = (country[LOCATION] .== "China")

    phase = 0
    flag_wuhan = false
    if flag_test println("$(now()) T: $T - n_I: $n_I") end
    for bit_actual ∈ [bit_china, bit_atlantic, .!bit_atlantic]
        phase += 1
        if phase == 1
            if count(bit_I .&& .!bit_wuhan) |> iszero
                flag_wuhan = true
            else
                continue
            end
        end

        for strain in alive_strain
            tier = TIER[strain]
            # β_ = (tier ∈ [2,3,5,7,11,13,17,19,23,29,31,37] ? 2 : 1) * β
            # β_ = (2-(mod(tier,2))) * β
            β_ = β

            ID_infectious = findall(bit_actual .&& (bit_I .&& (STRAIN .== strain)))
            if isempty(ID_infectious) continue end
            ID_susceptibl = findall(bit_actual .&& (bit_S .|| (bit_R .&& (TIER .< tier))))
            
            kdtreeI = KDTree(coordinate[:,ID_infectious])

            in_δ = inrange(kdtreeI, coordinate[:,ID_susceptibl], δ)
            contact = length.(in_δ)
        
            bit_infected = (rand(length(ID_susceptibl)) .< (1 .- (1 - β_).^contact))
            n_infected = count(bit_infected)

                     ID_infected   = ID_susceptibl[bit_infected]
               state[ID_infected] .= 'E'
              LATENT[ID_infected] .= round.(rand(latent_period, n_infected))
            RECOVERY[ID_infected] .= LATENT[ID_infected] + round.(rand(recovery_period, n_infected))
                TIER[ID_infected] .= tier
              STRAIN[ID_infected] .= strain
            if flag_test println("              & $(length(ID_infected)) at $phase of $strain") end
        end
        if flag_wuhan break end
        
    end
end
for strain in alive_strain
    prey = count((LOCATION .== LOCATION[strain]) .&& (TIER .< TIER[strain]) .&& (state .== 'S' .|| state .== 'R'))
    push!(BD, [T, strain, TIER[strain], 0, prey])
end

max_tier = maximum(TIER)
ndwt_ = cumsum(Matrix(ndwt_), dims = 1)
ndwt = collect(ndwt_[end,:])
DATA = DataFrame(log_degree = log10.(indegree), log_R = log10.(ndwt))
log_degree = DATA.log_degree
     log_R = DATA.log_R
  isescape = count(log_R .> 0) > 1
    
print(rgb3(1 - logistic(log10(n_T), 4, 1)), "$seed-($blockade) ", Crayon(reset = true))

(_, slope) = isescape ? lm(@formula(log_R ~ log_degree), DATA[DATA.log_R .> 0,:], wts = log_R[DATA.log_R .> 0]) |> coef : (0,0)
slope = ReLu(slope)
network_parity = mod(sum(sum.(NODE_blocked)),2)

jldsave("$seed rslt.jld2";
        T, n_T, max_tier, network_parity, isescape,
        slope, ndwt, ndwt_, first_escape,
        n_I_tier, BD, pregenogram, TE, DATA
        )
if flag_test
        jldsave("$seed test.jld2";
        ndwi_
        )
end

preview = open("cnfg.csv", "a")
println(preview, "$seed,$(now()),$max_tier,$isescape,$slope,$T,$n_T,$network_parity")
close(preview)
end
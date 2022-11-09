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

    n = 800000
    end_time = flag_test ? 100 : 500
    # T0 = 50

    NODE = copy(NODE0)
    latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
    recovery_period = Weibull(3, 7.17)

    δ = 0.018
    seed = lpad(seed_number, 4, '0')

    ndwi_  = DataFrame([Int32[] for _ = countrynames] , countrynames)
    ndwt_  = DataFrame([Int32[] for _ = countrynames] , countrynames)
    n_S_   = Int32[]
    n_E_   = Int32[]
    n_I_   = Int32[]
    n_R_   = Int32[]
    n_M_   = Int32[]
    beta0_ = Float16[]
    beta1_ = Float16[]

    T = 0 # Macro timestep
    state    = fill('S', n) # using SEIR model
    LATENT   = fill( -1, n)
    RECOVERY = fill( -1, n)
    FROM     = zeros(Int32, n)
    WHERE    = zeros(Int16, n)
    WHEN     = zeros(Int16, n)
    LON      = zeros(Float16, n)
    LAT      = zeros(Float16, n)
    
    Random.seed!(seed_number);
    bit_movable = .!(rand(n) .< blockade)

    LOCATION = sample(1:N, Weights(data.indegree), n)
    for _ in 1:10 LOCATION = rand.(NODE[LOCATION]) end

             host  = rand(1:n)
       state[host] = 'I'
    LOCATION[host] = 2935 # Wuhan, China
    RECOVERY[host] = round.(rand(recovery_period)) .+ 1
        FROM[host] = -1
       WHERE[host] = 2935
        WHEN[host] = 1

    coordinate = XY[:,LOCATION] + (Float16(0.1) * randn(Float16, 2, n))
    bits_C = [(country[LOCATION] .== c) for c in countrynames]    
    LON[host] = coordinate[1,host]
    LAT[host] = coordinate[2,host]

while T < end_time
    T += 1

    @inbounds LATENT   .-= 1; bit_LATENT   = (LATENT   .== 0); state[bit_LATENT  ] .= 'I'
    @inbounds RECOVERY .-= 1; bit_RECOVERY = (RECOVERY .== 0); state[bit_RECOVERY] .= 'R'
    WHEN[bit_LATENT] .= T
    LON[bit_LATENT] .= coordinate[1,bit_LATENT]
    LAT[bit_LATENT] .= coordinate[2,bit_LATENT]

    @inbounds bit_S = (state .== 'S'); n_S = count(bit_S); push!(n_S_, n_S)
    @inbounds bit_E = (state .== 'E'); n_E = count(bit_E); push!(n_E_, n_E)
    @inbounds bit_I = (state .== 'I'); n_I = count(bit_I); push!(n_I_, n_I)
    @inbounds bit_R = (state .== 'R'); n_R = count(bit_R); push!(n_R_, n_R)
    push!(ndwi_, [count(       bit_I .&& c) for c in bits_C])
    push!(ndwt_, [count(bit_RECOVERY .&& c) for c in bits_C]) # It should be cumsummed

    __LOCATION = deepcopy(LOCATION)
    @inbounds bit_passed = (((rand(n) .< σ) .&& .!bit_I) .|| ((rand(n) .< σ/100) .&& bit_I))
    if T >= T0 bit_passed = bit_passed .&& bit_movable end
    @inbounds LOCATION[bit_passed] = rand.(NODE[LOCATION[bit_passed]])
    @inbounds bit_moved = (LOCATION .!= __LOCATION); push!(n_M_, count(bit_moved))
    @inbounds coordinate[:, bit_moved] .= XY[:,LOCATION[bit_moved]] .+ (Float16(0.1) * randn(Float16, 2, count(bit_moved)))

    if iszero(n_E + n_I) break end


    if flag_test
        println("$(now()) T: $T - n_I: $n_I")

        DATA = DataFrame(log_degree = log10.(indegree), log_R = log10.(collect(ndwt_[end,:])))
        log_degree = DATA.log_degree
             log_R = DATA.log_R
          isescape = count(log_R .> 0) > 1
        (beta0, beta1) = isescape ? lm(@formula(log_R ~ log_degree), DATA[DATA.log_R .> 0,:], wts = log_R[DATA.log_R .> 0]) |> coef : (0,0)
        push!(beta0_, beta0)
        push!(beta1_, beta1)
    end


    @inbounds bit_atlantic = atlantic[LOCATION]
    @inbounds bit_wuhan = (LOCATION .== 2935)
    @inbounds bit_china = (country[LOCATION] .== "China")
    bits_local = (count(bit_I .&& .!bit_wuhan) |> iszero) ? [bit_china] : [bit_atlantic, .!bit_atlantic]

    for bit_actual ∈ bits_local
        __β = deepcopy(β)

        ID_infectious = findall(bit_actual .&& bit_I)
        if isempty(ID_infectious) continue end
        ID_susceptibl = findall(bit_actual .&& bit_S)
        
        kdtreeI = KDTree(coordinate[:,ID_infectious])

        in_δ = inrange(kdtreeI, coordinate[:,ID_susceptibl], δ)
        n_contact = length.(in_δ)
        ID_from = [arr |> isempty ? 0 : ID_infectious[rand(arr)] for arr ∈ in_δ]
    
        bit_infected = (rand(length(ID_susceptibl)) .< (1 .- (1 - __β).^n_contact))
        n_infected = count(bit_infected)

        @inbounds          ID_infected   = ID_susceptibl[bit_infected]
        @inbounds    state[ID_infected] .= 'E'
        @inbounds   LATENT[ID_infected] .= round.(rand(latent_period, n_infected))
        @inbounds RECOVERY[ID_infected] .= LATENT[ID_infected] + round.(rand(recovery_period, n_infected))
        @inbounds     FROM[ID_infected] .= ID_from[bit_infected]
        @inbounds    WHERE[ID_infected] .= LOCATION[ID_infected]
        if flag_test print(".") end
    end
end
n_R = n_R_[end]
ndwt_ = cumsum(Matrix(ndwt_), dims = 1)
ndwt = collect(ndwt_[end,:])
TimeEvolution = DataFrame(; n_S_, n_E_, n_I_, n_R_, n_M_)
DATA = DataFrame(log_degree = log10.(indegree), log_R = log10.(ndwt))
log_degree = DATA.log_degree
     log_R = DATA.log_R
  isescape = count(log_R .> 0) > 1

print(rgb3(1 - logistic(log10(n_R), 4, 1)), "$seed-($blockade) ", Crayon(reset = true))

try
    (_, slope) = isescape ? lm(@formula(log_R ~ log_degree), DATA[DATA.log_R .> 0,:], wts = log_R[DATA.log_R .> 0]) |> coef : (0,0)
catch LoadError
    println(Crayon(foreground = :red), "LoadError at $seed", Crayon(reset = true))
    slope = 0
end
slope = ReLU(slope)
network_parity = mod(sum(sum.(NODE_blocked)),2)

jldsave("$seed rslt.jld2";
        T, n_R, network_parity, isescape,
        slope, ndwt, ndwt_,
        TimeEvolution, DATA
        )
if flag_test
    jldsave("$seed adtn.jld2";
            host, FROM, WHERE, WHEN, LON, LAT, ndwi_, beta0_, beta1_
            )
end

preview = open("cnfg.csv", "a")
println(preview, "$seed,$(now()),$T,$n_R,$network_parity,$isescape,$slope")
close(preview)
end
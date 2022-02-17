@time using Random, Distributions
@time using NearestNeighbors
@time using DataFrames
@time using Plots
@time using Graphs, GraphRecipes

l = @layout [p1{0.7w} [p2 ; p3 ; p4]]

function SIR(seed; β = 0.02, μ = 0.2, τ = 0.3,
    seasonality = false,
    vaccination = false)
    L = 1000
    network_size = L ÷ 5
    binding = MvNormal((L ÷ 20) * [1 0; 0 1])
    total_pop = 10^5
    state = ['S' for _ in 1:total_pop]

n_S_ = Int64[]
n_E_ = Int64[]
n_I_ = Int64[]
n_R_ = Int64[]
n_V_ = Int64[]
n_β_ = []
Random.seed!(seed)

host = rand(1:total_pop)
state[host] = 'I'

# node_Rloc = L * rand(MvTDist(1,[1 0; 0 1]),network_size)

backbone, _, node_Rloc = euclidean_graph(network_size, 2; seed = 1, L=L, cutoff = 120)
# backbone = erdos_renyi(network_size, backbone.ne, seed = 1)
# backbone = barabasi_albert(network_size, 2)

plot_backbone = graphplot(backbone, x = node_Rloc[1,:], y = node_Rloc[2,:], alpha = 0.5,
                legend = :none)
scatter!(plot_backbone, node_Rloc[1,:], node_Rloc[2,:], color = :white)

agnt_Nloc = rand(1:network_size, total_pop) # Network location
for _ in 1:5
    agnt_Nloc = rand.(backbone.fadjlist[agnt_Nloc])
end
agnt_Rloc = node_Rloc[:,agnt_Nloc] .+ rand(binding, total_pop)     # Real location

maxitr = 1000
animation = @animate for T in 1:maxitr
    bit_S = state .== 'S'; ID_S = findall(bit_S); n_S = count(bit_S); push!(n_S_, n_S)
    bit_E = state .== 'E'; ID_E = findall(bit_E); n_E = count(bit_E); push!(n_E_, n_E)
    bit_I = state .== 'I'; ID_I = findall(bit_I); n_I = count(bit_I); push!(n_I_, n_I); ID_nonI = findall(.!bit_I);
    bit_R = state .== 'R'; ID_R = findall(bit_R); n_R = count(bit_R); push!(n_R_, n_R)
    bit_V = state .== 'V'; ID_V = findall(bit_V); n_V = count(bit_V); push!(n_V_, n_V)
    println("T: $T, n_S: $n_S, n_I: $n_I, n_R: $n_R")
    if iszero(n_I)
        if n_R < 100
            return nothing
        else
            break
        end
    end

    if seasonality != false
        β = β + 0.0001 * sin(seed + 0.1T)
        push!(n_β_, β)
    elseif vaccination
        state[bit_S .& (rand(total_pop) .< 0.0001)] .= 'V'
    end

    moved_nonI = ID_nonI[rand(length(ID_nonI)) .< 0.1]
    moved_I = ID_I[rand(n_I) .< 0.01]
    for t in 1:1
        agnt_Nloc[moved_nonI] = rand.(backbone.fadjlist[agnt_Nloc[moved_nonI]])
        agnt_Nloc[moved_I] = rand.(backbone.fadjlist[agnt_Nloc[moved_I]])
    end
    # println("                                               $(length(moved_I)) moved!")
    # agnt_Nloc = rand.(backbone.fadjlist[agnt_Nloc])
    # α = rand(2,total_pop)
    # agnt_Rloc = ((1 .+α).*agnt_Rloc .+ (1 .-α).*node_Rloc[:,agnt_Nloc])./2 .+ rand(binding, total_pop)
    agnt_Rloc = node_Rloc[:,agnt_Nloc] .+ rand(binding, total_pop)


    # sctr = scatter(plot_backbone,
    #         agnt_Rloc[1,bit_S], agnt_Rloc[2,bit_S], label = "S",
    #         color = :black, ma = 0.5, msw = 0, ms = 2)
    # scatter!(agnt_Rloc[1,bit_R], agnt_Rloc[2,bit_R], label = "R",
    #         color = :blue, ma = 0.1, msw = 0, ms = 2)
    sctr = scatter(plot_backbone, agnt_Rloc[1,bit_I], agnt_Rloc[2,bit_I], label = "I",
            color = :red, ma = 0.5, msw = 0, ms = 3)
    # annotate!(agnt_Rloc[1,bit_I], agnt_Rloc[2,bit_I], "$T", annotationcolor = :red)

    te_R = plot(n_R_, label = "R", legend = :bottomright, linealpha = 0.5, linewidth = 2, color = :blue, xlims = (1,maxitr))
    te_I = plot(n_I_, label = "I", legend = :topright, linealpha = 0.5, linewidth = 2, color = :red, xlims = (1,maxitr))
    # new = plot(sctr, te_R, te_I, layout = l, size = (1600,900))
    if seasonality
        te_β = plot(n_β_, label = "β", legend = :topright, linealpha = 0.5, linewidth = 2, xlims = (1,maxitr))
        new = plot(sctr, te_R, te_I, te_β, layout = l, size = (1600,900))
    elseif vaccination
        te_V = plot(n_V_, label = "V", legend = :topright, linealpha = 0.5, linewidth = 2, xlims = (1,maxitr))
        new = plot(sctr, te_R, te_I, te_V, layout = l, size = (1600,900))
    else
        new = plot(sctr, te_R, te_I, plot(), layout = l, size = (1600,900))
    end

    # agnt_Nloc = rand.(backbone.fadjlist[agnt_Nloc])
    # agnt_Rloc = node_Rloc[:,agnt_Nloc] .+ rand(binding, total_pop)     # Real location

    kdtree_I = KDTree(agnt_Rloc[:,bit_I])
    n_contact = length.(inrange(kdtree_I, agnt_Rloc[:,bit_S], 3.0))
    bit_infected = rand(count(bit_S)) .< 1 .- (1 - β).^n_contact
    state[ID_S[bit_infected]] .= 'E'

    recovered = ID_I[rand(n_I) .< μ]
    state[recovered] .= 'R'
    infected = ID_E[rand(n_E) .< τ]
    state[infected] .= 'I'
end
return animation
end

cd("D:/"); pwd()
for seed = 5:5
    animation = SIR(seed, β = 0.01)
    if !(animation |> isnothing)
        mp4(animation, "animation $seed.mp4", fps = 10)
    end
    println("-" ^ seed)
end
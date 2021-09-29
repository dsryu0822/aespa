using Distances
using StatsBase
using Random
using NearestNeighbors

Random.seed!(0);
ε = 0.1
N = 10^2
coordinate = rand(2, N);
state = sample(['S', 'I'], Weights([0.5, 0.5]), N);
S = coordinate[:, state .== 'S']
I = coordinate[:, state .== 'I']

# @time sum(pairwise(Euclidean(),S,I) .< ε, dims = 1)
@time kdtree = KDTree(I)
in_δ = inrange(kdtree, S, ε, true)


function deep_pop!(array)
    if isempty(array)
        return 0
    else
        return pop!(array)
    end 
end

in_δ0 = shuffle.(in_δ)
in_δ1 = deep_pop!.(in_δ0)
in_δ2 = copy(in_δ1); in_δ2[1] = 30

in_δ2 - in_δ1


contact0 = length.(in_δ)
bit_infected =  bit_infected .| (rand(n_micro_S) .< (1 .- (1 - β).^contact0))

contact0

x = hcat.(
    repeat([T], n_infected),
    repeat([node], n_infected),
    repeat([length(NODE[node])], n_infected),
    deep_pop!.(shuffle.(in_δ))[bit_infected],
    ID_infected
)


DataFrame(hcat(
    repeat([T,node,length(NODE[node])]', n_infected),
    ID_I[deep_pop!.(shuffle.(in_δ))[bit_infected]],
    ID_infected
    ), :auto)

append!(R₀_table, DataFrame(hcat(
    repeat([T,node,length(NODE[node])]', n_infected),
    ID_I[deep_pop!.(shuffle.(in_δ))[bit_infected]],
    ID_infected
    ), :auto))

append!(R₀_table, DataFrame(
    T = T,
    node_id = node,
    degree = length(NODE[node]),
    from = ID_I[deep_pop!.(shuffle.(in_δ))[bit_infected]],
    to = ID_infected
    ))
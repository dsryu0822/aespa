using Graphs, Random
m = 3
backbone = barabasi_albert(1000,3)

u = backbone.fadjlist .|> length |> argmax
dm = length(backbone.fadjlist[u]) - m

cutlink = shuffle(backbone.fadjlist[u])[1:dm]
for v ∈ cutlink
    rem_edge!(backbone, u, v)
end


using Graphs
using GraphRecipes, Plots, LaTeXStrings
default()

export_dir = "C:/Users/rmsms/OneDrive/lab/aespa/png/"

N = 100
m = 3

G = barabasi_albert(N, m, seed = 0)
argmax(length.(G.fadjlist))

G

k = degree(G)

r = abs.(k .- maximum(k) .+ 1); r = r ./ 50
θ = 2 * π * rand(N)

grap = plot(G, x = r .* cos.(θ), y = r .* sin.(θ),
 curves = false, size = (400,400), linealpha = 0.1,
 mc = :black, msw = 0)

hist = histogram(k, normalize = true,
 xlabel = L"\textrm{degree\ } k", ylabel = L"\textrm{probability\ } p(k)",
 alpha = 0.5, linewidth = 0, legend = :none, color = :black,
 xticks = 5:10:25, yticks = 0:0.1:0.2)

result = plot(grap, hist)
png(result, export_dir * "바.png")
using Plots
using DataFrames, CSV

cd("D:/simulated/"); pwd()
savedir = "c:/Users/rmsms/OneDrive/lab/aespa/png/"
last_seed = 30

그림_전체통제 = plot(legend = :none,
    title = "Global Control", xlabel = "guard probability", ylabel = "total recovered")
for param ∈ 0:10:100
    y축 = []
    for seed ∈ 1:last_seed
        push!(y축, CSV.read("AA$(lpad(param, 3, '0'))/$(lpad(seed, 4, '0')) smry.csv", DataFrame).Recovery[1])
    end
    scatter!(그림_전체통제, fill(param, last_seed), y축,  alpha = 0.5, color = :black)
end
그림_전체통제; png(그림_전체통제, savedir * "그림_전체통제.png")

last_seed = 10
그림_US통제 = plot(legend = :none,
    title = "US Control", xlabel = "guard probability", ylabel = "total recovered")
for param ∈ 10:10:100
    y축 = []
    for seed ∈ 1:last_seed
        push!(y축, CSV.read("US$(lpad(param, 3, '0'))/$(lpad(seed, 4, '0')) ndwr.csv", DataFrame)."United States"[end])
    end
    scatter!(그림_US통제, fill(param, last_seed), y축,  alpha = 0.5, color = :black)
end
그림_US통제; png(그림_US통제, savedir * "그림_US통제.png")


last_seed = 10
그림_UK통제 = plot(legend = :none,
    title = "UK Control", xlabel = "guard probability", ylabel = "total recovered")
for param ∈ 10:10:100
    y축 = []
    for seed ∈ 1:last_seed
        push!(y축, CSV.read("UK$(lpad(param, 3, '0'))/$(lpad(seed, 4, '0')) ndwr.csv", DataFrame)."United Kingdom"[end])
    end
    scatter!(그림_UK통제, fill(param, last_seed), y축,  alpha = 0.5, color = :black)
end
그림_UK통제; png(그림_UK통제, savedir * "그림_UK통제.png")


last_seed = 10
그림_KR통제 = plot(legend = :none,
    title = "KR Control", xlabel = "guard probability", ylabel = "total recovered")
for param ∈ 10:10:100
    y축 = []
    for seed ∈ 1:last_seed
        push!(y축, CSV.read("KR$(lpad(param, 3, '0'))/$(lpad(seed, 4, '0')) ndwr.csv", DataFrame)."Korea, Rep."[end])
    end
    scatter!(그림_KR통제, fill(param, last_seed), y축,  alpha = 0.5, color = :black)
end
그림_KR통제; png(그림_KR통제, savedir * "그림_KR통제.png")


last_seed = 10
그림_CN통제 = plot(legend = :none,
    title = "CN Control", xlabel = "guard probability", ylabel = "total recovered")
for param ∈ 10:10:100
    y축 = []
    for seed ∈ 1:last_seed
        push!(y축, CSV.read("CN$(lpad(param, 3, '0'))/$(lpad(seed, 4, '0')) ndwr.csv", DataFrame)."China"[end])
    end
    scatter!(그림_CN통제, fill(param, last_seed), y축,  alpha = 0.5, color = :black)
end
그림_CN통제; png(그림_CN통제, savedir * "그림_CN통제.png")


그림_전체KR통제 = plot(legend = :none,
    title = "Global(KR) Control", xlabel = "guard probability", ylabel = "total recovered")
for param ∈ 10:10:100
    y축 = []
    for seed ∈ 1:last_seed
        push!(y축, CSV.read("KR$(lpad(param, 3, '0'))/$(lpad(seed, 4, '0')) smry.csv", DataFrame).Recovery[1])
    end
    scatter!(그림_전체KR통제, fill(param, last_seed), y축,  alpha = 0.5, color = :black)
end
그림_전체KR통제; png(그림_전체KR통제, savedir * "그림_전체KR통제.png")

# @time using Dates
@time include("lemma.jl")
@time using Random, Distributions, Statistics
@time using Graphs, NearestNeighbors
@time using DataFrames
@time using CSV, XLSX

# ------------------------------------------------------------------ switches

export_type = :CSV # :both, :CSV, :XLSX

if !isdir("D:/trash/")
    mkpath("D:/trash/")
    mkpath("D:/trash/00")
    mkpath("D:/trash/0V")
    mkpath("D:/trash/M0")
    mkpath("D:/trash/MV")
end

# ------------------------------------------------------------------ parameters

const n = 1*10^5
N = n ÷ 1000 # number of stage network
ID = 1:n
const m = 3 # number of network link
const number_of_host = 1
const end_time = 200

const β = 0.02
const δ = 0.01 # contact radius
const σ = 0.025 # mobility
const B = 1.0 # Breaktrough parameter. Vaccinated agents are infected with probability β*B.
const vaccin_supply = 0.005 # probability of vaccination

brownian = MvNormal(2, 0.01) # moving process
backbone = barabasi_albert(N, m)
NODE = backbone.fadjlist

latent_period = Weibull(3, 7.17) # https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7014672/#__sec2title
recovery_period = Weibull(3, 7.17)

for seed_number ∈ 1:30
    for v ∈ [true, false], m ∈ [true, false]
        simulation(
        seed_number,
        moving = m,
        vaccin = v)
    end
end
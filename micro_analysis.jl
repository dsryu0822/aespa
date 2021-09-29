@time using LightGraphs
@time using Random, Distributions, Statistics
@time using CSV, DataFrames
@time using Plots; visualization = true

directory = "D:/trash/"
cd(directory)

seed2 = CSV.read("2 R0_table.csv", DataFrame)

seed2

seed2.to

unique(seed2.to)
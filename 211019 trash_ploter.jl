# 10월 중순, 이론통계학 중간고사를 앞두고 금요일 미팅에 대비해
# 백신 투여(0,1), 네트워크 통제(0,1)을 변인으로 네 가지 시나리
# 오를 비교하는 플랏을 준비

@time using Plots, DynamicsPlots
@time using CSV, DataFrames
@time using LaTeXStrings

directory = "D:/trash/"

te_ = Dict{Int, DataFrame}()
es_ = Dict{Int, DataFrame}()

R0_ = Dict{Int, Array{Float64}}()
Rt_ = Dict{Int, Array{Float64}}()

color_ = Dict{Int, Symbol}()
push!(color_, 0 => :black)
push!(color_, 1 => :red)
push!(color_, 2 => :blue)
push!(color_, 3 => :purple)

plot_R = plot(legend = :topleft, xlabel = "T", ylabel = L"\# R")
plot_I = plot(legend = :topleft, xlabel = "T", ylabel = L"\# I")
plot_R0 = plot(legend = :topright, xlabel = "T", ylabel = L"R_{0}", ylims = (0,4))
plot_Rt = plot(legend = :topright, xlabel = "T", ylabel = L"R_{t}", ylims = (0,4))

for idx ∈ 0:3
    push!(te_, idx => CSV.read(directory * "scenario$idx 0010 time_evolution.csv", DataFrame))
    timeevolution(te_[idx], legend = :inline); png(directory * "scenario$idx time_evolution.png")
    plot!(plot_R, te_[idx][:,:R], label = "scenario $idx", color = color_[idx])
    plot!(plot_I, te_[idx][:,:I], label = "scenario $idx", color = color_[idx])
    hline!(plot_I, [100], color = :black, label = :none)

    push!(es_, idx => CSV.read(directory * "scenario$idx 0010 essential.csv", DataFrame))
    R0 = Float64[]
    Rt = Float64[]
    for T0 ∈ 1:nrow(te_[idx])
        temp = es_[idx][es_[idx][:,:T] .≤ T0,:]
        push!(R0, nrow(temp[temp[:,:to] .> 0, :]) / nrow(unique(temp, :from)))

        infected_list = es_[idx][es_[idx][:,:T] .== T0,:from]
        temp2 = temp[temp[:,:from] .∈ Ref(infected_list),:]
        push!(Rt, nrow(temp2[temp2[:,:to] .> 0, :]) / nrow(unique(temp2, :from)))
    end
    push!(R0_, idx => R0)
    push!(Rt_, idx => Rt)
    plot!(plot_R0, R0_[idx], label = "scenario $idx", color = color_[idx])
    plot!(plot_Rt, Rt_[idx], label = "scenario $idx", color = color_[idx])
end

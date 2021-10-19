# 10월 중순, 이론통계학 중간고사를 앞두고 금요일 미팅에 대비해
# 백신 투여(0,1), 네트워크 통제(0,1)을 변인으로 네 가지 시나리
# 오를 비교하는 플랏을 준비

@time using Plots, DynamicsPlots
@time using CSV, DataFrames
@time using LaTeXStrings

directory = "D:/trash/"

te_ = Dict{Int, DataFrame}()
R0_ = Dict{Int, DataFrame}()
Rt_ = Dict{Int, Array{Float64}}()
color_ = Dict{Int, Symbol}()
push!(color_, 0 => :black)
push!(color_, 1 => :red)
push!(color_, 2 => :blue)
push!(color_, 3 => :purple)

plot_I = plot(legend = :topleft, xlabel = "T", ylabel = L"\# I")
plot_R = plot(legend = :topleft, xlabel = "T", ylabel = L"\# R")
plot_R0 = plot(legend = :topright, xlabel = "T", ylabel = L"R_{0}", ylims = (1,4))

for idx ∈ 0:3
    push!(te_, idx => CSV.read(directory * "scenario$idx 0010 time_evolution.csv", DataFrame))
    plot!(plot_I, te_[idx][:,:I], label = "scenario $idx", color = color_[idx])
    hline!(plot_I, [100], color = :black, label = :none)
    plot!(plot_R, te_[idx][:,:R], label = "scenario $idx", color = color_[idx])

    push!(R0_, idx => CSV.read(directory * "scenario$idx 0010 essential.csv", DataFrame))
    temp1 = R0_[idx]    
    Rt = Float64[]
    for T0 ∈ 1:100
        temp2 = temp1[temp1[:,1] .≤ T0,[:from]]
        push!(Rt, nrow(temp2) / nrow(unique(temp2)))
    end
    push!(Rt_, idx => Rt)
    plot!(plot_R0, Rt_[idx], label = "scenario $idx", color = color_[idx])
end
plot(plot_R0, [50,75,75,50,50], [2,2,3,3,2], color = :black)
plot(
    plot_R0, xlims = (50,75), ylims = (2,3),
    size = (400,400),
    title = L"$\max \Delta R_{60} \approx 0.2$")



    # push!(R0_, 0 => CSV.read(directory * "scenario0 0010 essential.csv", DataFrame))
# temp = R0_[0]

# temp = temp[temp.T .≤ 3,[:from]]
# Rt_ = nrow(temp) / nrow(unique(temp))
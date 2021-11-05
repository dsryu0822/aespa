using CSV, DataFrames
using Plots; Plots.plotly()
using StatsBase

realdata = CSV.read("korea.csv", DataFrame)
구분 = unique(realdata.gubun)

temp = replace.(realdata.stdDay, "2021년" => "21년")
temp = replace.(temp, "2020년" => "20년")
for i in 1:9
    temp = replace.(temp, "년 $(i)월" => "년 0$(i)월")
    temp = replace.(temp, "월 $(i)일" => "월 0$(i)일")
end
for i in lpad.(0:24, 2, "0")
    temp = replace.(temp, "일 $(i)시" => "")
end
temp = replace.(temp, "년 " => "")
temp = replace.(temp, "월 " => "")
realdata.stdDay = temp
sort!(realdata, :stdDay)

realdata

Plots.plotly()

time_evolution = plot()
for 지역 in 구분
    plot!(time_evolution, realdata[realdata.gubun .== 지역,:defCnt], label = 지역)
end
time_evolution

time_evolution = plot()
for 지역 in 구분
    if 지역 == "합계" continue end
    plot!(time_evolution, realdata[realdata.gubun .== 지역,:defCnt], label = 지역)
end
time_evolution

Plots.gr()

누적확진자 = DataFrame()
누적확진자["stdDay"] = unique(realdata.stdDay)
for 지역 in 구분
    누적확진자 = rightjoin(누적확진자, unique(realdata[realdata.gubun .== 지역,[1,3]],1), on = :stdDay)
    rename!(누적확진자, :defCnt => 지역)
end

일일확진자 = DataFrame(Matrix(누적확진자[2:end,2:end]) - Matrix(누적확진자[1:(end-1),2:end]))
일일확진자 = coalesce.(일일확진자,0)
일일확진자 = max.(일일확진자, 0)
rename!(일일확진자, 구분)
일일확진자 = hcat(DataFrame(stdDay = unique(누적확진자.stdDay)[2:end]),일일확진자)
일일확진자["합계"] = vec(sum(Matrix(일일확진자[2:(end-1)]), dims = 2))

time_evolution = plot()
for 지역 in 구분
    if 지역 == "합계" continue end
    plot!(time_evolution, 일일확진자[:,지역], label = 지역)
end
time_evolution

savefig(time_evolution,"time_evolution.html")

entropy_ = zeros(size(일일확진자)[1])
for i in 1:length(entropy_)
    entropy_[i] = entropy(collect(일일확진자[i,2:(end-1)]) ./ 일일확진자.합계[i],18)
end
plot(entropy_, ylims = (-0.1,1.1))
savefig("entropy.html")

CSV.write("일일확진자.csv", 일일확진자)
CSV.write("누적확진자.csv", 누적확진자)
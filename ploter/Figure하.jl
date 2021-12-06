include("FigureSetting.jl")

todo = 201:250
σ_axis = schedules.σ[todo]

default(markeralpha = 0.5, markerstrokewidth = 0,
 xaxis = :log, xticks = 10 .^[-3.,-2.,-1.], yticks = 0:0.2:0.6, ylims = (0,0.7),
 legend = :topleft, size = (600,300),
 xlabel = L"\sigma", ylabel = L"R(\infty) / n")

하 = plot()

doing = 250
k = "00"
seed_number = 3
scenario = schedules[doing,:]
raw = CSV.read(import_dir * scenario.name * "/00/0001 smry.csv", DataFrame)[[false],:]
CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)[1,:]
agnt = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) agnt.csv", DataFrame)
smry = CSV.read(import_dir * scenario.name * "/" * k * "/$(lpad(seed_number, 4, '0')) smry.csv", DataFrame)
histogram(agnt.case)

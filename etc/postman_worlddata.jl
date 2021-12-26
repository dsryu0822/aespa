using JSON

file = open("C:/Users/rmsms/OneDrive/바탕 화면/response.json")

ITEM = JSON.parse(file)

Active = []
for item in ITEM
    push!(Active, item["Active"])
end

plot(Active)
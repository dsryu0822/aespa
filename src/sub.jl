logistic(z, l, s) = 1 / (1 + exp(s * (-(z-l))))
# logistic(1000, 3, 1)

# using Crayons
# print(crayon"C25E5F", "color") # red, 194, 94, 95
# print(crayon"F4BF77", "color") # ylw, 244, 191, 119
# print(crayon"9BB26A", "color") # grn, 155, 178, 106

function rgb3(w)
    red = (194,  94,  95)
    ylw = (244, 191, 119)
    grn = (155, 178, 106)
    if w < 0.5
        w = 2w
        (r,g,b) = (red .* (1-w)) .+ (ylw .* w)
    else
        w = 2(w-0.5)
        (r,g,b) = (ylw .* (1-w)) .+ (grn .* w)
    end
    return Crayon(foreground = round.(Int64, (r,g,b)))
end

# for w in 10 .^ (0:1:7)
#     println(rgb3(1 - logistic(log10(w), 4, 1)), w)
# end
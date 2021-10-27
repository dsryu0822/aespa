function sufficientN(condition::BitArray)
    N =  argmax(cumsum(.!(condition)))
    if N < length(condition)
        return N + 1
    else
        @warn "There is no sufficient large N such that satisfy given condition"
        return length(condition)
    end
end

# x = rand(10)
sufficientN(x .< 0.6)
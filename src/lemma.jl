function sufficientN(condition::BitArray)
    N =  argmax(cumsum(.!(condition)))
    if N < length(condition)
        return N + 1
    else
        @warn "There is no sufficient large N such that satisfy given condition"
        return length(condition)
    end
end

deep_pop!(array) = isempty(array) ? 0 : pop!(array)

function round(x, scale)
    if x < 0 then
        return math.ceil(x * 10^scale) / 10^scale
    end
    return math.floor(x * 10^scale) / 10^scale
end

function roundVector(vector, scale)
    return Vector(
        round(vector.x, scale), 
        round(vector.y, scale),
        round(vector.z, scale)
    )
end

function round(x, scale)
    assert(type(x) == 'number' or type(x) == 'table', "Attempt to round value " .. tostring(x) .. ' with invalid type <' .. type(x) ..'>')
    
    if type(x) == 'table' then
        return Vector(
            round(x.x, scale), 
            round(x.y, scale),
            round(x.z, scale)
        )
    end
    
    if x < 0 then
        return math.ceil(x * 10^scale) / 10^scale
    end
    return math.floor(x * 10^scale) / 10^scale
end

function tableSize(t)
    local size = 0
    for i in pairs(t) do 
        size = size + 1 
    end
    return size
end

function tableKeys(t)
    local keys = {}
    for key, value in pairs(t) do 
        table.insert(keys, key)
    end
    return keys
end

function tableContains(t, elem)
    for i, value in ipairs(t) do 
        if value == elem then
            return true
        end
    end
    return false
end
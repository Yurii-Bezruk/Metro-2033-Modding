ROOT_BAG_GUID = 'c5c908'
BOARD_GUID = 'b6a25e'
ADMIN_BOARD_GUID = '68c9ad'

function onLoad()
    clearDeskExtensions()
end

function clearDeskExtensions()
    ADDITION_BOARDS = getObjectsFromGUIDs({'15ef07', '1c3b49', 'bb444e', '918452'})
    for _, b in ipairs(ADDITION_BOARDS) do
        b.setSnapPoints({})
    end
end

-- ------------------------------------------------------------
-- Util functions
-- ------------------------------------------------------------

function getObjectsFromGUIDs(guids)
    local objects = {}
    for i, guid in ipairs(guids) do
        objects[i] = getObjectFromGUID(guid)
    end
    return objects
end

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

function tableSize(t)
    local size = 0
    for i in pairs(t) do 
        size = size + 1 
    end
    return size
end

function tableContains(table, elem)
    for i, value in ipairs(table) do 
        if value == elem then
            return true
        end
    end
    return false
end

function tableKeys(t)
    local keys = {}
    for key, value in pairs(t) do 
        table.insert(keys, key)
    end
    return keys
end

-- ------------------------------------------------------------
-- Exporting functions
-- ------------------------------------------------------------
function roundVectorExported(args)
    return roundVector(args.vector, args.scale)
end

function tableContainsExported(args)
    return tableContains(args.table, args.elem)
end


function onLoad()
    clearTableExtensions()

    ROOT_BAG = getObjectFromGUID('c5c908')
    BOARD = getObjectFromGUID('b6a25e')
end

function clearTableExtensions()
    ADDITION_BOARDS = getObjectsFromGUIDs({'15ef07', '1c3b49', 'bb444e', '918452'})
    for _, b in ipairs(ADDITION_BOARDS) do
        b.setSnapPoints({})
    end
end

function onObjectStateChange(object, old_state_guid)
    ROOT_BAG.call('setScriptToObject', object)
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

-- params {Vector, int}
function roundVector(params)
    return Vector(
        round(params.vector.x, params.scale), 
        round(params.vector.y, params.scale),
        round(params.vector.z, params.scale)
    )
end

function size(t)
    local size = 0
    for i in pairs(t) do 
        size = size + 1 
    end
    return size
end

ROOT_BAG_GUID = 'c5c908'
BOARD_GUID = 'b6a25e'

function onLoad()
    clearTableExtensions()

    -- ------------------------------------------------------------
    -- Importing functions
    -- ------------------------------------------------------------
    ROOT_BAG = {
        obj = getObjectFromGUID(ROOT_BAG_GUID),
        setScriptToObject = function(self, object)
            return self.obj.call('setScriptToObject', object)
        end
    }

    BOARD = {
        obj = getObjectFromGUID(BOARD_GUID),
        findStationByName = function(self, name)
            return self.obj.call('findStationByNameExported', {name = name})
        end,
        highlight = function(self, position)
            self.obj.call('highlight', position)
        end
    }

    t = BOARD:findStationByName('dynamo')
    BOARD:highlight(t.position)
end

function clearTableExtensions()
    ADDITION_BOARDS = getObjectsFromGUIDs({'15ef07', '1c3b49', 'bb444e', '918452'})
    for _, b in ipairs(ADDITION_BOARDS) do
        b.setSnapPoints({})
    end
end

function onObjectStateChange(object, old_state_guid)
    ROOT_BAG:setScriptToObject(object)
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

function size(t)
    local size = 0
    for i in pairs(t) do 
        size = size + 1 
    end
    return size
end

-- ------------------------------------------------------------
-- Exporting functions
-- ------------------------------------------------------------
function roundVectorExported(args)
    return roundVector(args.vector, args.scale)
end

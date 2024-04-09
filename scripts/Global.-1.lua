ROOT_BAG_GUID = 'c5c908'
BOARD_GUID = 'b6a25e'
ADMIN_BOARD_GUID = '68c9ad'

Tag = {
    RESOURCE = 'RESOURCE',
    BULLET = 'BULLET',
    PORK = 'PORK',
    MUSHROOM = 'MUSHROOM',
    FRACTION_TOKEN = 'FRACTION_TOKEN'
}

function onLoad()
    clearDeskExtensions()
    
    ADMIN_BOARD = {
        obj = getObjectFromGUID(ADMIN_BOARD_GUID),
        findFractionByColor = function(self, color)
            local res = self.obj.call('findFractionByColorExported', color)
            return res.name, res.fraction
        end
    }
end

function clearDeskExtensions()
    local addition_desks = getObjectsFromGUIDs({'15ef07', '1c3b49', 'bb444e', '918452'})
    for _, b in ipairs(addition_desks) do
        b.setSnapPoints({})
    end
end

function onPlayerAction(player, action, targets)
    -- Spectators and Admins can do anything
    if tableContains({'White', 'Grey', 'Black'}, player.color) then
        return true
    end
    if action == Player.Action.Copy or action == Player.Action.Cut then
        return onCopy(player, targets)
    elseif action == Player.Action.Delete then
        return onDelete(player, targets)
    end
    
    return true
end

function onCopy(player, targets)
    -- Players can copy or cut only resources
    for i, object in ipairs(targets) do
        if not object.hasTag(Tag.RESOURCE) then
            return false
        end
    end
    return true
end

function onDelete(player, targets)    
    -- Players can delete only resources and their own fraction tokens
    local fractionName, fraction = ADMIN_BOARD:findFractionByColor(Color.fromString(player.color))
    for i, object in ipairs(targets) do
        if not (object.hasTag(Tag.RESOURCE) or object.hasTag(Tag.FRACTION_TOKEN)) then
            return false
        end
        if object.hasTag(Tag.FRACTION_TOKEN) and fractionName != object.getVar('FRACTION') then
            return false
        end
    end
    return true
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

function tableSize(table)
    local size = 0
    for i in pairs(table) do 
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
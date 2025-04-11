require("scripts.collections.List")

function Zone(guid)
    local zone = getObjectFromGUID(guid)
    assert(zone, "Object with guid '" .. guid .. "' not found")
    assert(zone.type == 'Scripting', "Object with guid '" .. guid .. "' has unsupported type '" .. zone.type .. "'")

    local self = {}
    
    self.getObjects = function()
        return List(zone.getObjects())
    end

    self.contains = function(obj)
        return obj and self.getObjects():map(|zoneObject| zoneObject.guid):contains(obj.guid)
    end

    self.isEmpty = function()
        return self.getObjects():size() == 0
    end

    self = setmetatable(self, {
        __index = zone
    })

    return self
end
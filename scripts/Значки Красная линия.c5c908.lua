local script = [[
    BOARD_GUID = Global.getVar('BOARD_GUID')
    CHANGED_STATE = false
    
    function onLoad()
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        BOARD = {
            obj = getObjectFromGUID(BOARD_GUID),
            findStationByPosition = function(self, position)
                res = self.obj.call('findStationByPositionExported', position)
                return res.name, res.station
            end,
            setOwner = function(self, name, owner)
                self.obj.call('setOwnerExported', {name=name, owner=owner})
            end,
            removeOwner = function(self, name, owner)
                self.obj.call('removeOwnerExported', {name=name})
            end
        }
        Production = BOARD.obj.getTable('Production')
    end

    function onDrop(player_color)        
        Wait.time(|| delayedOnDrop(), 0.5)
    end

    function delayedOnDrop()
        name, station = BOARD:findStationByPosition(self.getPosition())
        if station == nil then
            state = Production.GENERIC
        else
            state = station.production
            BOARD:setOwner(name, FRACTION)
            STATION = name
        end
        if state == self.getStateId() then
            return
        end
        CHANGED_STATE = true
        local newState = self.setState(state)
        newState.setLuaScript(self.getLuaScript())
        newState.setVar('FRACTION', FRACTION)
        newState.setVar('STATION', STATION)
    end

    function onPickUp(player_color)
        tryRemoveOwner()
    end

    function onDestroy()
        if not CHANGED_STATE then
            tryRemoveOwner()
        end
    end
    
    function tryRemoveOwner()
        if STATION != nil then
            BOARD:removeOwner(STATION)
        end
    end
]]

FRACTION_TOKEN_BAG_GUIDS = {
    reich = '6e9e5a',
    red_line = 'c5c908',
    bauman = 'e855f1',
    bandits = '33d809',
    arbats = 'e0ae4a',
    confederation = '6f710d'
}

function onObjectLeaveContainer(container, object)
    for name, guid in pairs(FRACTION_TOKEN_BAG_GUIDS) do
        if guid == container.guid then
            object.setLuaScript(script)
            object.setVar('FRACTION', name)
        end
    end
end

function setScriptToObject(object)
    object.setLuaScript(script)
end
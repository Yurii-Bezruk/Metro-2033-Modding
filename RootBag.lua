local script = [[  
    
    function onDrop(player_color)
        BOARD = Global.getVar('BOARD')
        Production = BOARD.getTable('Production')
        Wait.time(|| delayedOnDrop(), 0.5)
    end

    function delayedOnDrop()
        station = BOARD.call('findStationByPosition', self.getPosition())
        if station == nil then
            state = Production.GENERIC
        else
            state = station.production
        end
        if state == self.getStateId() then
            return
        end
        self.setState(state)        
    end
]]

FRACTION_TOKEN_BAG_GUIDS = {'e0ae4a', '33d809', '6e9e5a', 'c5c908', '6f710d', 'e855f1'}

function onObjectLeaveContainer(container, object)
    for i, guid in ipairs(FRACTION_TOKEN_BAG_GUIDS) do
        if guid == container.guid then
            object.setLuaScript(script)
        end
    end
end

function setScriptToObject(object)
    object.setLuaScript(script)
end



local script = [[
    BOARD_GUID = Global.getVar('BOARD_GUID')
    
    function onLoad()
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        BOARD = {
            obj = getObjectFromGUID(BOARD_GUID),
            findStationByPosition = function(self, position)
                res = self.obj.call('findStationByPositionExported', position)
                return res.name, res.station
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

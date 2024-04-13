local fractionTokenScript = [[
    BOARD_GUID = Global.getVar('BOARD_GUID')
    ROOT_BAG_GUID = Global.getVar('ROOT_BAG_GUID')
    CHANGED_STATE = false
    
    function onLoad(script_state)
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        BOARD = {
            obj = getObjectFromGUID(BOARD_GUID),
            findStationByPosition = function(self, position)
                res = self.obj.call('findStationByPositionExported', position)
                return res.name, res.station
            end,
            setOwner = function(self, name, owner, onLoad)
                self.obj.call('setOwnerExported', {name=name, owner=owner, onLoad=onLoad})
            end,
            removeOwner = function(self, name, owner)
                self.obj.call('removeOwnerExported', {name=name})
            end
        }
        ROOT_BAG = {
            obj = getObjectFromGUID(ROOT_BAG_GUID),
            putToTokenStorage = function(self, object)
                self.obj.call('putToTokenStorage', object)
            end,
            getFromTokenStorage = function(self, guid)
                return self.obj.call('getFromTokenStorageExported', {guid=guid})
            end,
            removeFromTokenStorage = function(self, guid)
                self.obj.call('removeFromTokenStorageExported', {guid=guid})
            end
        }
        Production = BOARD.obj.getTable('Production')
        Tag = Global.getTable('Tag')
        -- ------------------------------------------------------------
        -- Importing functions end
        -- ------------------------------------------------------------
        
        self.addTag(Tag.FRACTION_TOKEN)
        loadScriptState(script_state)
    end

    function loadScriptState(script_state)
        if script_state != nil and script_state != '' then
            script_state = JSON.decode(script_state)
            FRACTION = script_state.fraction
            STATION = script_state.station
            occupyStation(true)
        end
    end

    function onSave()
        return JSON.encode({
            fraction = FRACTION,
            station = STATION
        })
    end

    function onDrop(player_color)
        Wait.time(|| occupyStation(false), 0.5)
    end

    function occupyStation(onLoad)
        local station_name, station = BOARD:findStationByPosition(self.getPosition())
        if station == nil then
            state = Production.GENERIC
            STATION = nil
        else
            state = station.production
            BOARD:setOwner(station_name, FRACTION, onLoad)
            STATION = station_name
        end
        ROOT_BAG:putToTokenStorage(self)
        if state == self.getStateId() then
            return
        end
        CHANGED_STATE = true
        local newState = self.setState(state)
        newState.setLuaScript(self.getLuaScript())
    end

    function onPickUp(player_color)
        tryRemoveOwner()
    end

    function onDestroy()
        if not CHANGED_STATE then
            tryRemoveOwner()
        end
        Wait.time(function () 
            ROOT_BAG:removeFromTokenStorage(self.guid)
        end, 1)
    end

    function onStateChange(old_state_guid)
        local oldToken = ROOT_BAG:getFromTokenStorage(old_state_guid)
        FRACTION = oldToken.fraction
        STATION = oldToken.station
        ROOT_BAG:putToTokenStorage(self)
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
            object.setLuaScript(fractionTokenScript)
            object.setVar('FRACTION', name)
        end
    end
end

-- ------------------------------------------------------------
-- Token storage
-- ------------------------------------------------------------

TOKEN_STORAGE = {}

function putToTokenStorage(object)
    TOKEN_STORAGE[object.guid] = {
        fraction = object.getVar('FRACTION'),
        station = object.getVar('STATION')
    }
end

function getFromTokenStorage(guid)
    return TOKEN_STORAGE[guid]
end

function removeFromTokenStorage(guid)
    TOKEN_STORAGE[guid] = nil
end

-- ------------------------------------------------------------
-- Exporting functions
-- ------------------------------------------------------------

function getFromTokenStorageExported(args)
    return getFromTokenStorage(args.guid)
end

function removeFromTokenStorageExported(args)
    removeFromTokenStorage(args.guid)
end
require 'collections.Table'

local factionTokenScript = [[
    GAME_BOARD_GUID = Global.getVar('GAME_BOARD_GUID')
    ROOT_BAG_GUID = Global.getVar('ROOT_BAG_GUID')
    CHANGED_STATE = false
    
    function onLoad(script_state)
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        GAME_BOARD = {
            obj = getObjectFromGUID(GAME_BOARD_GUID),
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
        Production = GAME_BOARD.obj.getTable('Production')
        Tag = Global.getTable('Tag')
        -- ------------------------------------------------------------
        -- Importing functions end
        -- ------------------------------------------------------------
        
        self.addTag(Tag.FACTION_TOKEN)
        loadScriptState(script_state)
    end

    function loadScriptState(script_state)
        if script_state ~= nil and script_state ~= '' then
            script_state = JSON.decode(script_state)
            if script_state.faction ~= nil then
                FACTION = script_state.faction
            end
            STATION = script_state.station
            occupyStation(true)
        end
    end

    function onSave()
        return JSON.encode({
            faction = FACTION,
            station = STATION
        })
    end

    function onDrop(player_color)
        Wait.time(|| occupyStation(false), 0.5)
    end

    function occupyStation(onLoad)
        local station_name, station = GAME_BOARD:findStationByPosition(self.getPosition())
        if station == nil then
            state = Production.GENERIC
            STATION = nil
        else
            state = station.production
            GAME_BOARD:setOwner(station_name, FACTION, onLoad)
            STATION = station_name
        end
        ROOT_BAG:putToTokenStorage(self)
        if state == self.getStateId() then
            return
        end
        CHANGED_STATE = true
        local newState = self.setState(state)
        newState.setLuaScript(self.getLuaScript())
        newState.setVar('FACTION', FACTION)
    end

    function onPickUp(player_color)
        tryRemoveOwner()
    end

    function onDestroy()
        if not CHANGED_STATE then
            tryRemoveOwner()
        end
        Wait.time(|| ROOT_BAG:removeFromTokenStorage(self.guid), 1)
    end

    function onStateChange(old_state_guid)
        local oldToken = ROOT_BAG:getFromTokenStorage(old_state_guid)
        FACTION = oldToken.faction
        STATION = oldToken.station
        ROOT_BAG:putToTokenStorage(self)
    end
    
    function tryRemoveOwner()
        if STATION ~= nil then
            GAME_BOARD:removeOwner(STATION)
        end
    end
]]

FACTION_TOKEN_BAG_GUIDS = Table {
    reich = '6e9e5a',
    red_line = 'c5c908',
    bauman = 'e855f1',
    bandits = '33d809',
    arbats = 'e0ae4a',
    confederation = '6f710d'
}

function onObjectLeaveContainer(container, object)
    FACTION_TOKEN_BAG_GUIDS
        :filter(|name, guid| guid == container.guid)
        :keys()
        :forEach(|name| object.setLuaScript(factionTokenScript))
        :forEach(|name| object.setVar('FACTION', name))
end

-- ------------------------------------------------------------
-- Token storage
-- ------------------------------------------------------------

TOKEN_STORAGE = {}

function putToTokenStorage(object)
    TOKEN_STORAGE[object.guid] = {
        faction = object.getVar('FACTION'),
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
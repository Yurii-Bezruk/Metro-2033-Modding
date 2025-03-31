

-- If you reading this from the scripting window of Tabletop Simulator, then you will probably see a lot of 
-- auto-generated code (pasted by VSCode plugin). You can check the actual source code on my GitHub repository
-- https://github.com/Yurii-Bezruk/Metro-2033-Modding

require("scripts.collections.List")

-- Set to false during testing to make all stations available. 
-- Value of true allows to move only to seated players' zones
IGNORE_INACTIVE_ZONES = false

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
    -- ------------------------------------------------------------
    -- Importing functions
    -- ------------------------------------------------------------
    ADMIN_BOARD = {
        obj = getObjectFromGUID(ADMIN_BOARD_GUID),
        findFractionByColor = function(self, color)
            local res = self.obj.call('findFractionByColorExported', color)
            return res.name, res.fraction
        end
    }
    -- ------------------------------------------------------------
    -- Importing functions end
    -- ------------------------------------------------------------
    clearDeskExtensions()    
    promotePlayers()
end

function clearDeskExtensions()
    List{'15ef07', '1c3b49', 'bb444e', '918452'}
        :map(getObjectFromGUID)
        :forEach(|obj| obj.setSnapPoints {})
end

function promotePlayers()
    for player in List(Player.getPlayers()):iterator() do
        if not List{'White', 'Grey', 'Black'}:contains(player.color) and not player.promoted then
            player.promote()
        end
    end
end

function findPlayerByColor(color)
    return List(Player.getPlayers())
        :findFirst(|player| player.color == color)
end

function onPlayerChangeColor(color)
    if not List{'White', 'Grey', 'Black'}:contains(color) then
        local player = findPlayerByColor(color)
        if not player.promoted then
            player.promote()
        end
    end
end

function onPlayerAction(player, action, targets)
    -- Spectators and Admins can do anything
    if List{'White', 'Grey', 'Black'}:contains(player.color) then
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
    for object in List(targets):iterator() do
        if not object.hasTag(Tag.RESOURCE) then
            return false
        end
    end
    return true
end

function onDelete(player, targets)    
    -- Players can delete only resources and their own fraction tokens
    local fractionName, fraction = ADMIN_BOARD:findFractionByColor(Color.fromString(player.color))
    for object in List(targets):iterator() do
        if not (object.hasTag(Tag.RESOURCE) or object.hasTag(Tag.FRACTION_TOKEN)) then
            return false
        end
        if object.hasTag(Tag.FRACTION_TOKEN) and fractionName != object.getVar('FRACTION') then
            return false
        end
    end
    return true
end

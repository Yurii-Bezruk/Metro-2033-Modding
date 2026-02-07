require 'collections.List'
require 'collections.Table'
require 'objects.Zone'

local heroFigureScript = [[
    GAME_BOARD_GUID = Global.getVar('GAME_BOARD_GUID')
    ADMIN_BOARD_GUID = Global.getVar('ADMIN_BOARD_GUID')
    
    function onLoad()
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        GAME_BOARD = {
            obj = getObjectFromGUID(GAME_BOARD_GUID),
            highlightPossibleMoves = function(self, position, speed, heroName)
                self.obj.call('highlightPossibleMovesExported', {position=position, speed=speed, heroName=heroName})
            end,
            clearAllHighlights = function(self)
                self.obj.call('clearAllHighlights')
            end
        }
        ADMIN_BOARD = {
            obj = getObjectFromGUID(ADMIN_BOARD_GUID),
            getHeroSpeed = function(self, heroFigure)
                return self.obj.call('getHeroSpeed', heroFigure)
            end
        }
        -- ------------------------------------------------------------
        -- Importing functions end
        -- ------------------------------------------------------------
    end
    
    function onDrop(player_color)
        if canHighlight() then
            GAME_BOARD:clearAllHighlights()
        end
    end

    function onPickUp(player_color)
        if canHighlight() then
            local speed = ADMIN_BOARD:getHeroSpeed(self)
            GAME_BOARD:highlightPossibleMoves(self.getPosition(), speed, NAME)
        end
    end

    function canHighlight()
        local highlightedBy = GAME_BOARD.obj.getVar('HIGHLIGHTED_BY')
        if highlightedBy ~= nil and highlightedBy ~= NAME then
            return false
        end
        return true
    end
]]

local heroCardScript = [[
    ADMIN_BOARD_GUID = Global.getVar('ADMIN_BOARD_GUID')

    function onLoad()
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        ADMIN_BOARD = {
            obj = getObjectFromGUID(ADMIN_BOARD_GUID),
            assignHero = function(self, heroCard)
                self.obj.call('assignHero', heroCard)
            end
        }
        -- ------------------------------------------------------------
        -- Importing functions end
        -- ------------------------------------------------------------
    end
    
    function onDrop(player_color)
        Wait.time(|| ADMIN_BOARD:assignHero(self), 0.5)
    end
]]

local fractionBoardScript = [[
    GAME_BOARD_GUID = Global.getVar('GAME_BOARD_GUID')
    active = false

    function onLoad()
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        GAME_BOARD = {
            obj = getObjectFromGUID(GAME_BOARD_GUID),
            highlightPossibleAttacks = function(self, faction)
                self.obj.call('highlightPossibleAttacksExported', {faction=faction})
            end,
            clearAllHighlights = function(self)
                self.obj.call('clearAllHighlights')
            end
        }
        -- ------------------------------------------------------------
        -- Importing functions end
        -- ------------------------------------------------------------
    end

    function buttonClicked()
        if canHighlight() then
            active = not active
            if active then
                GAME_BOARD:highlightPossibleAttacks(FACTION)
            else    
                GAME_BOARD:clearAllHighlights()
            end
        end
    end

    function canHighlight()
        local highlightedBy = GAME_BOARD.obj.getVar('HIGHLIGHTED_BY')
        if highlightedBy ~= nil and highlightedBy ~= FACTION then
            return false
        end
        return true
    end
]]

function onLoad(script_state)
    for name, hero in pairs(heroes) do
        hero.figure.setLuaScript(heroFigureScript)
        hero.figure.setVar('NAME', name)
        hero.card = getObjectFromGUID(hero.card_guid)
        if hero.card ~= nil then
            hero.card.setLuaScript(heroCardScript)
        end
    end

    for name, faction in pairs(factions) do
        faction.board.UI.setXml(generateButton(faction))
        faction.board.setLuaScript(fractionBoardScript)
        faction.board.setVar('FACTION', name)
    end
    
    loadScriptState(script_state)
end

function generateButton(faction)
    return [[
        <button onClick = "buttonClicked" 
            position = "0 -1070 -60" 
            rotation = "180 0 0"
            width = "300" 
            height = "190" 
            fontSize = "60" 
            color = "]]..faction.color:toString()..[["
            outline = "black"
            outlineSize = "5"
        >Attack</button>
    ]]
end

function loadScriptState(script_state)
    if script_state ~= nil and script_state ~= '' then
        script_state = JSON.decode(script_state)
        for name, saved_hero in pairs(script_state) do
            heroes[name].faction = saved_hero.faction
        end
    end
end

function onSave()
    local hero_save_data = {}
    for name, hero in pairs(heroes) do
        if hero.faction ~= nil then
            hero_save_data[name] = {faction = hero.faction}
        end
    end
    return JSON.encode(hero_save_data)
end

-- ------------------------------------------------------------
-- Hero functions
-- ------------------------------------------------------------

function findHeroByCard(heroCard)
    local name, hero = heroes:findFirstPair(|name, hero| hero.card_guid == heroCard.guid)    
    hero.card = getObjectFromGUID(hero.card_guid)
    return name, hero
end

function getActiveHeroes()
    return heroes:filter(|name, hero| hero.faction ~= nil)
end

function assignHero(heroCard)
    local hero_name, hero = findHeroByCard(heroCard)
    if not HERO_FIGURE_START_ZONE.contains(hero.figure) then
        do return end
    end

    factions:filter(|name, faction| faction.hero_card_zone.contains(hero.card))
        :forEach(function(name, faction) 
            hero.figure.setPositionSmooth(faction.hero_figure_zone.getPosition(), false, false)
            hero.figure.setRotationSmooth(faction.rotation, false, false)
            hero.figure.setColorTint(faction.hero_color_tint)
            hero.faction = name
        end)
end

function deassignHero(heroCard, delay)
    local hero_name, hero = findHeroByCard(heroCard)
    if hero == nil then
        do return end
    end
    hero.figure.setColorTint(DEFAULT_COLOR_TINT)
    hero.faction = nil

    Wait.time(function ()
        local zone = HERO_FIGURES_ZONES:findFirst(|zone| zone.isEmpty())        
        hero.figure.setPositionSmooth(zone.getPosition(), false, false)
        hero.figure.setRotationSmooth(Vector(0, 270, 0), false, false)
    end, delay)
end

function getHeroSpeed(heroFigure)
    local name, hero = heroes:findFirstPair(|name, hero| hero.figure.guid == heroFigure.guid)
    local speed = hero.speed
    speed = speed + equipmentCount(name, 'locomotive')
    speed = speed - equipmentCount(name, 'rpk')
    return speed
end

function getEquipment(hero)
    if hero.faction == nil then
        return List{}
    end
    return factions[hero.faction].equipment_zone.getObjects()
end

function equipmentCount(hero_name, equip_name)
    return getEquipment(heroes[hero_name])
        :filter(|card| equipment[equip_name]:contains(card.guid))
        :size()
end

-- ------------------------------------------------------------
-- Event Handlers
-- ------------------------------------------------------------

function onObjectDrop(player_color, object)
    if object.type ~= 'Deck' then
        if HERO_CARD_START_ZONE.contains(object) then
            deassignHero(object, 0.85)
        end
    else
        -- if hero deck dropped to empty zone
        if HERO_CARD_START_ZONE.contains(object) then
            for i, heroCard in ipairs(object.getObjects()) do
                deassignHero(heroCard, i * 0.85)
            end
            do return end
        end
        -- if one part of deck dropped onto another part in the zone
        for i, heroCard in ipairs(object.getObjects()) do
            if HERO_CARD_START_ZONE.getObjects()
                    :filter(|obj| obj.type == 'Deck')
                    :anyMatch(|deck| deck.contains(heroCard)) then
                deassignHero(heroCard, i * 0.85)
            end            
        end
        -- otherwise invalid input, return
    end
end


function onObjectLeaveContainer(container, object)
    if HERO_CARD_START_ZONE.contains(container) then
        object.setLuaScript(heroCardScript)
    end
end

-- ------------------------------------------------------------
-- Game data
-- ------------------------------------------------------------

HERO_FIGURE_START_ZONE = Zone('9e4aaf')
HERO_FIGURES_ZONES = List{Zone('93c8a1'), Zone('49a450'), Zone('29f2ce'), Zone('2c6394'), Zone('f666bc'), Zone('41749f')}
HERO_CARD_START_ZONE = Zone('c5d6cc')
DEFAULT_COLOR_TINT = Color(0, 0, 0, 255)

heroes = Table {
    hunter = {
        figure = getObjectFromGUID('742d9b'),
        card_guid = '4e1b3f',
        speed = 3,
        power = 3
    },
    artyom = {
        figure = getObjectFromGUID('a75f15'),
        card_guid = 'b13aa9',
        speed = 3,
        power = 2
    },
    anna = {
        figure = getObjectFromGUID('f1bb37'),
        card_guid = '29873d',
        speed = 3,
        power = 3
    },
    miller = {
        figure = getObjectFromGUID('3b7793'),
        card_guid = '88f769',
        speed = 3,
        power = 2
    },
    khan = {
        figure = getObjectFromGUID('d6b5ec'),
        card_guid = '6eb1e5',
        speed = 3,
        power = 3
    },
    sasha = {
        figure = getObjectFromGUID('96a7f8'),
        card_guid = '6762c8',
        speed = 3,
        power = 2
    }
}

factions = Table {
    reich = {
        board = getObjectFromGUID('748f36'),
        color = Color.GREEN,
        hero_card_zone = Zone('4b7954'),
        hero_figure_zone = Zone('e63318'),
        hero_color_tint = Color(23 / 255, 208 / 255, 0, 200 / 255),
        rotation = Vector(0, 360, 0),
        equipment_zone = Zone('14224d')
    },
    red_line = {
        board = getObjectFromGUID('f12a81'),
        color = Color.RED,
        hero_card_zone = Zone('6bad7e'),
        hero_figure_zone = Zone('496490'),
        hero_color_tint = Color(238 / 255, 0, 0, 200 / 255),
        rotation = Vector(0, 360, 0),
        equipment_zone = Zone('3f41e8')
    },
    bauman = {
        board = getObjectFromGUID('dcc720'),
        color = Color.BROWN,
        hero_card_zone = Zone('038386'),
        hero_figure_zone = Zone('9bc8be'),
        hero_color_tint = Color(181 / 255, 79 / 255, 0, 200 / 255),
        rotation = Vector(0, 90, 0),
        equipment_zone = Zone('e2760f')
    },
    bandits = {
        board = getObjectFromGUID('e88538'),
        color = Color.YELLOW,
        hero_card_zone = Zone('7f3bc1'),
        hero_figure_zone = Zone('b0bfff'),
        hero_color_tint = Color(246 / 255, 255 / 255, 0, 200 / 255),
        rotation = Vector(0, 90, 0),
        equipment_zone = Zone('ed5942')
    },
    arbats = {
        board = getObjectFromGUID('0cadd1'),
        color = Color.BLUE,
        hero_card_zone = Zone('97d671'),
        hero_figure_zone = Zone('b12e2a'),
        hero_color_tint = Color(70 / 255, 0, 255 / 255, 200 / 255),
        rotation = Vector(0, 180, 0),
        equipment_zone = Zone('c6be1a')
    },
    confederation = {
        board = getObjectFromGUID('2095e4'),
        color = Color.ORANGE,
        hero_card_zone = Zone('a4ca9c'),
        hero_figure_zone = Zone('0b8381'),
        hero_color_tint = Color(255 / 255, 147 / 255, 0, 200 / 255),
        rotation = Vector(0, 180, 0),
        equipment_zone = Zone('6c3520')
    }
}

equipment = {
    akm = List{'6c763b', '3c5c36'},
    shotgun = List{'48d664', '2fd936'},
    geiger = List{'08fd93', '120ff8'},
    svd = List{'f71050', '7c51de'},
    rpk = List{'d74fbd', '786e02'},
    locomotive = List{'bdde07', '0dd68b'},
    flag = List{'0fbe3a', 'fba4fe'},
    grenade = List{'bd026e', 'fd2f18'},
    dynamite = List{'2bf6cc', '6d6817'}
}

-- ------------------------------------------------------------
-- Exporting functions
-- ------------------------------------------------------------

function equipmentCountExported(args)
    return equipmentCount(args.hero_name, args.equip_name)
end
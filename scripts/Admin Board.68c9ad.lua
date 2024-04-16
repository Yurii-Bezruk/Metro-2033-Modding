require("scripts.util.zones")

local heroFigureScript = [[
    BOARD_GUID = Global.getVar('BOARD_GUID')
    ADMIN_BOARD_GUID = Global.getVar('ADMIN_BOARD_GUID')
    
    function onLoad()
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        BOARD = {
            obj = getObjectFromGUID(BOARD_GUID),
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
            BOARD:clearAllHighlights()
        end
    end

    function onPickUp(player_color)
        if canHighlight() then
            local speed = ADMIN_BOARD:getHeroSpeed(self)
            BOARD:highlightPossibleMoves(self.getPosition(), speed, NAME)
        end
    end

    function canHighlight()
        local highlightedBy = BOARD.obj.getVar('HIGHLIGHTED_BY')
        if highlightedBy != nil and highlightedBy != NAME then
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
        Wait.time(function () 
            ADMIN_BOARD:assignHero(self)
        end, 0.5)
    end
]]

local fractionBoardScript = [[
    BOARD_GUID = Global.getVar('BOARD_GUID')
    active = false

    function onLoad()
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        BOARD = {
            obj = getObjectFromGUID(BOARD_GUID),
            highlightPossibleAttacks = function(self, fraction)
                self.obj.call('highlightPossibleAttacksExported', {fraction=fraction})
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
                BOARD:highlightPossibleAttacks(FRACTION)
            else    
                BOARD:clearAllHighlights()
            end
        end
    end

    function canHighlight()
        local highlightedBy = BOARD.obj.getVar('HIGHLIGHTED_BY')
        if highlightedBy != nil and highlightedBy != FRACTION then
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
        if hero.card != nil then
            hero.card.setLuaScript(heroCardScript)
        end
    end

    for name, fraction in pairs(fractions) do
        fraction.board.UI.setXml(generateButton(fraction))
        fraction.board.setLuaScript(fractionBoardScript)
        fraction.board.setVar('FRACTION', name)
    end
    
    loadScriptState(script_state)
end

function generateButton(fraction)
    return [[
        <button onClick = "buttonClicked" 
            position = "0 -1070 -60" 
            rotation = "180 0 0"
            width = "300" 
            height = "190" 
            fontSize = "60" 
            color = "]]..fraction.color:toString()..[["
            outline = "black"
            outlineSize = "5"
        >Attack</button>
    ]]
end

function loadScriptState(script_state)
    if script_state != nil and script_state != '' then
        script_state = JSON.decode(script_state)
        for name, saved_hero in pairs(script_state) do
            heroes[name].fraction = saved_hero.fraction
        end
    end
end

function onSave()
    local hero_save_data = {}
    for name, hero in pairs(heroes) do
        if hero.fraction != nil then
            hero_save_data[name] = {fraction = hero.fraction}
        end
    end
    return JSON.encode(hero_save_data)
end

-- ------------------------------------------------------------
-- Hero functions
-- ------------------------------------------------------------

function findHeroByCard(heroCard)
    for name, hero in pairs(heroes) do
        if hero.card_guid == heroCard.guid then
            hero.card = getObjectFromGUID(hero.card_guid)
            return name, hero
        end
    end
end

function findHeroByFigure(heroFigure)
    for name, hero in pairs(heroes) do
        if hero.figure.guid == heroFigure.guid then
            return name, hero
        end
    end
end

function findHeroByName(heroName)
    for name, hero in pairs(heroes) do
        if name == heroName then
            return hero
        end
    end
end

function getActiveHeroes()
    local activeHeroes = {}
    for name, hero in pairs(heroes) do
        if hero.fraction != nil then
            activeHeroes[name] = hero
        end
    end
    return activeHeroes
end

function assignHero(heroCard)
    local hero_name, hero = findHeroByCard(heroCard)
    if not zoneContain(HERO_FIGURE_START_ZONE, hero.figure) then
        do return end
    end
    for name, fraction in pairs(fractions) do
        if zoneContain(fraction.hero_card_zone, hero.card) then
            hero.figure.setPositionSmooth(fraction.hero_figure_zone.getPosition(), false, false)
            hero.figure.setRotationSmooth(fraction.rotation, false, false)
            hero.figure.setColorTint(fraction.hero_color_tint)
            hero.fraction = name
        end
    end
end

function deassignHero(heroCard, delay)
    local hero_name, hero = findHeroByCard(heroCard)
    if hero == nil then
        do return end
    end
    hero.figure.setColorTint(DEFAULT_COLOR_TINT)
    hero.fraction = nil

    Wait.time(function ()
        for i, guid in ipairs(HERO_FIGURES_ZONES_GUIDS) do
            local zone = getObjectFromGUID(guid)
            if #zone.getObjects() == 0 then
                hero.figure.setPositionSmooth(zone.getPosition(), false, false)
                hero.figure.setRotationSmooth(Vector(0, 270, 0), false, false)
            end
        end
    end, delay)
end

function getHeroSpeed(heroFigure)
    local name, hero = findHeroByFigure(heroFigure)
    local speed = hero.speed
    speed = speed + equipmentCount(name, 'locomotive')
    speed = speed - equipmentCount(name, 'rpk')
    return speed
end

function getEquipment(hero)
    if hero.fraction == nil then
        return {}
    end
    return fractions[hero.fraction].equipment_zone.getObjects()
end

function equipmentCount(hero_name, equip_name)
    local amount = 0
    local hero = findHeroByName(hero_name)
    for _, card in ipairs(getEquipment(hero)) do
        if card.guid == equipment[equip_name][1] or card.guid == equipment[equip_name][2] then
            amount = amount + 1
        end
    end
    return amount
end

-- ------------------------------------------------------------
-- Fraction functions
-- ------------------------------------------------------------

function findFractionByColor(color)
    for name, fraction in pairs(fractions) do
        if fraction.color == color then
            return name, fraction
        end
    end
end

-- ------------------------------------------------------------
-- Event Handlers
-- ------------------------------------------------------------

function onObjectDrop(player_color, object)
    if object.type != 'Deck' then
        if zoneContain(HERO_CARD_START_ZONE, object) then
            deassignHero(object, 0.85)
        end
    else
        -- if hero deck dropped to empty zone
        if zoneContain(HERO_CARD_START_ZONE, object) then
            for i, heroCard in ipairs(object.getObjects()) do
                deassignHero(heroCard, i * 0.85)
            end
            do return end
        end
        -- if one part of deck dropped onto another part in the zone
        for i, heroCard in ipairs(object.getObjects()) do
            if zoneDecksContain(HERO_CARD_START_ZONE, heroCard) then
                deassignHero(heroCard, i * 0.85)
            end
        end
        -- otherwise invalid input, return
    end
end


function onObjectLeaveContainer(container, object)
    if zoneContain(HERO_CARD_START_ZONE, container) then
        object.setLuaScript(heroCardScript)
    end
end

-- ------------------------------------------------------------
-- Game data
-- ------------------------------------------------------------

HERO_FIGURE_START_ZONE = getObjectFromGUID('9e4aaf')
HERO_FIGURES_ZONES_GUIDS = {'93c8a1', '49a450', '29f2ce', '2c6394', 'f666bc', '41749f'}
HERO_CARD_START_ZONE = getObjectFromGUID('c5d6cc')
DEFAULT_COLOR_TINT = Color(0, 0, 0, 255)

heroes = {
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

fractions = {
    reich = {
        board = getObjectFromGUID('748f36'),
        color = Color.GREEN,
        hero_card_zone = getObjectFromGUID('4b7954'),
        hero_figure_zone = getObjectFromGUID('e63318'),
        hero_color_tint = Color(23 / 255, 208 / 255, 0, 200 / 255),
        rotation = Vector(0, 360, 0),
        equipment_zone = getObjectFromGUID('14224d')
    },
    red_line = {
        board = getObjectFromGUID('f12a81'),
        color = Color.RED,
        hero_card_zone = getObjectFromGUID('6bad7e'),
        hero_figure_zone = getObjectFromGUID('496490'),
        hero_color_tint = Color(238 / 255, 0, 0, 200 / 255),
        rotation = Vector(0, 360, 0),
        equipment_zone = getObjectFromGUID('3f41e8')
    },
    bauman = {
        board = getObjectFromGUID('dcc720'),
        color = Color.BROWN,
        hero_card_zone = getObjectFromGUID('038386'),
        hero_figure_zone = getObjectFromGUID('9bc8be'),
        hero_color_tint = Color(181 / 255, 79 / 255, 0, 200 / 255),
        rotation = Vector(0, 90, 0),
        equipment_zone = getObjectFromGUID('e2760f')
    },
    bandits = {
        board = getObjectFromGUID('e88538'),
        color = Color.YELLOW,
        hero_card_zone = getObjectFromGUID('7f3bc1'),
        hero_figure_zone = getObjectFromGUID('b0bfff'),
        hero_color_tint = Color(246 / 255, 255 / 255, 0, 200 / 255),
        rotation = Vector(0, 90, 0),
        equipment_zone = getObjectFromGUID('ed5942')
    },
    arbats = {
        board = getObjectFromGUID('0cadd1'),
        color = Color.BLUE,
        hero_card_zone = getObjectFromGUID('97d671'),
        hero_figure_zone = getObjectFromGUID('b12e2a'),
        hero_color_tint = Color(70 / 255, 0, 255 / 255, 200 / 255),
        rotation = Vector(0, 180, 0),
        equipment_zone = getObjectFromGUID('c6be1a')
    },
    confederation = {
        board = getObjectFromGUID('2095e4'),
        color = Color.ORANGE,
        hero_card_zone = getObjectFromGUID('a4ca9c'),
        hero_figure_zone = getObjectFromGUID('0b8381'),
        hero_color_tint = Color(255 / 255, 147 / 255, 0, 200 / 255),
        rotation = Vector(0, 180, 0),
        equipment_zone = getObjectFromGUID('6c3520')
    }
}

equipment = {
    akm = {'6c763b', '3c5c36'},
    shotgun = {'48d664', '2fd936'},
    geiger = {'08fd93', '120ff8'},
    svd = {'f71050', '7c51de'},
    rpk = {'d74fbd', '786e02'},
    locomotive = {'bdde07', '0dd68b'},
    flag = {'0fbe3a', 'fba4fe'},
    grenade = {'bd026e', 'fd2f18'},
    dynamite = {'2bf6cc', '6d6817'}
}

-- ------------------------------------------------------------
-- Exporting functions
-- ------------------------------------------------------------

function equipmentCountExported(args)
    return equipmentCount(args.hero_name, args.equip_name)
end

function findFractionByColorExported(color)
    local name, fraction = findFractionByColor(color)
    return {name=name, fraction=fraction}
end
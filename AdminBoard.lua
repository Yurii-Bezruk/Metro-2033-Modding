local heroFigureScript = [[
    BOARD_GUID = Global.getVar('BOARD_GUID')
    ADMIN_BOARD_GUID = Global.getVar('ADMIN_BOARD_GUID')
    
    function onLoad()
        -- ------------------------------------------------------------
        -- Importing functions
        -- ------------------------------------------------------------
        BOARD = {
            obj = getObjectFromGUID(BOARD_GUID),
            highlightPossibleMoves = function(self, position, speed)
                self.obj.call('highlightPossibleMovesExported', {position=position, speed=speed})
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
    end
    
    function onDrop(player_color)
        BOARD:clearAllHighlights()
    end

    function onPickUp(player_color)
        local speed = ADMIN_BOARD:getHeroSpeed(self)
        BOARD:highlightPossibleMoves(self.getPosition(), speed)
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
    end
    
    function onDrop(player_color)
        Wait.time(|| delayedOnDrop(), 0.5)
    end

    function delayedOnDrop()
        ADMIN_BOARD:assignHero(self)
    end
]]

function onLoad()
    -- ------------------------------------------------------------
    -- Importing functions
    -- ------------------------------------------------------------
    Global = {
        obj = Global,
        tableContains = function(self, table, elem)
            return self.obj.call('tableContainsExported', {table=table, elem=elem})
        end
    }

    for name, hero in pairs(heroes) do
        hero.figure.setLuaScript(heroFigureScript)
        hero.card = getObjectFromGUID(hero.card_guid)
        if hero.card != nil then
            hero.card.setLuaScript(heroCardScript)
        end
    end
end

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

function assignHero(heroCard)
    local hero_name, hero = findHeroByCard(heroCard)
    if not zoneContain(hero_figure_start_zone, hero.figure) then
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
    hero.figure.setColorTint(default_color_tint)
    hero.fraction = nil

    Wait.time(function ()
        for i, guid in ipairs(hero_figures_zones_guids) do
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
    for _, card in ipairs(getEquipment(hero)) do
        if card.guid == equipment.locomotive[1] or card.guid == equipment.locomotive[2] then
            speed = speed + 1
        elseif card.guid == equipment.rpk[1] or card.guid == equipment.rpk[2] then
            speed = speed - 1
        end
    end
    return speed
end

function getEquipment(hero)
    if hero.fraction == nil then
        return {}
    end
    return fractions[hero.fraction].equipment_zone.getObjects()
end


-- ------------------------------------------------------------
-- Event Handlers
-- ------------------------------------------------------------

function onObjectDrop(player_color, object)
    if object.tag != 'Deck' then
        if zoneContain(hero_card_start_zone, object) then
            deassignHero(object, 0.85)
        end
    else
        -- if hero deck dropped to empty zone
        if zoneContain(hero_card_start_zone, object) then
            for i, heroCard in ipairs(object.getObjects()) do
                deassignHero(heroCard, i * 0.85)
            end
            do return end
        end
        -- if one part of deck dropped onto another part in the zone
        for i, heroCard in ipairs(object.getObjects()) do
            if zoneDecksContain(hero_card_start_zone, heroCard) then
                deassignHero(heroCard, i * 0.85)
            end
        end
        -- otherwise invalid input, return
    end
end


function onObjectLeaveContainer(container, object)
    if zoneContain(hero_card_start_zone, container) then
        object.setLuaScript(heroCardScript)
    end
end

-- ------------------------------------------------------------
-- Zone utils
-- ------------------------------------------------------------

function zoneContain(zone, object)
    return Global:tableContains(zone.getObjects(), object)
end

function zoneDecksContain(zone, object)
    for i, item in ipairs(zone.getObjects()) do
        if item.tag == 'Deck' then
            for j, card in ipairs(item.getObjects()) do
                if card.guid == object.guid then
                    return true
                end
            end
        end
    end
    return false
end

-- ------------------------------------------------------------
-- Game data
-- ------------------------------------------------------------

hero_figure_start_zone = getObjectFromGUID('9e4aaf')
hero_figures_zones_guids = {'93c8a1', '49a450', '29f2ce', '2c6394', 'f666bc', '41749f'}
hero_card_start_zone = getObjectFromGUID('c5d6cc')
default_color_tint = Color(0, 0, 0, 255)

heroes = {
    hunter = {
        figure = getObjectFromGUID('742d9b'),
        card_guid = 'e4d1a4',
        speed = 3,
        power = 3
    },
    artyom = {
        figure = getObjectFromGUID('a75f15'),
        card_guid = '2e08a6',
        speed = 3,
        power = 2
    },
    anna = {
        figure = getObjectFromGUID('f1bb37'),
        card_guid = 'c0c872',
        speed = 3,
        power = 3
    },
    melnik = {
        figure = getObjectFromGUID('3b7793'),
        card_guid = '0b73df',
        speed = 3,
        power = 2
    },
    han = {
        figure = getObjectFromGUID('d6b5ec'),
        card_guid = '5af6ee',
        speed = 3,
        power = 3
    },
    sasha = {
        figure = getObjectFromGUID('96a7f8'),
        card_guid = '897fa3',
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
    akm = {'4f93dc', '1c32fa'},
    shotgun = {'a617e4', 'ce73d3'},
    geiger = {'dd3603', 'cb7038'},
    svd = {'86db44', '63b5df'},
    rpk = {'dc70bd', '9f26b9'},
    locomotive = {'18302e', 'ac2450'},
    flag = {'2eb5e9', 'a08520'},
    grenade = {'f3b7cb', 'e20c78'},
    dynamite = {'79f781', 'f42d48'}
}

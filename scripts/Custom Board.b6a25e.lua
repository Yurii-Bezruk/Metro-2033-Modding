require("scripts.util.tables")
require("scripts.util.rounding")
require("scripts.util.circle")
require("scripts.util.Set")
require("scripts.util.Queue")

IGNORE_INACTIVE_ZONES = Global.getVar('IGNORE_INACTIVE_ZONES')
ADMIN_BOARD_GUID = Global.getVar('ADMIN_BOARD_GUID')

function onLoad()
    -- ------------------------------------------------------------
    -- Importing functions
    -- ------------------------------------------------------------
    ADMIN_BOARD = {
        obj = getObjectFromGUID(ADMIN_BOARD_GUID),
        getActiveHeroes = function(self)
            return self.obj.call('getActiveHeroes')
        end,
        equipmentCount = function(self, hero_name, equip_name)
            return self.obj.call('equipmentCountExported', {hero_name=hero_name, equip_name=equip_name})
        end
    }
    -- ------------------------------------------------------------
    -- Importing functions end
    -- ------------------------------------------------------------
end

-- ------------------------------------------------------------
-- Drawing
-- ------------------------------------------------------------

function clearAllHighlights()
    clearCircle(self)
end

function highlightPosition(position, color)
    if color == nil then
        color = Color.YELLOW
    end
    position = position:copy() * 0.485
    drawCircle(self, {
        radius    = 0.23, 
        color     = color,
        thickness = 0.04,
        position  = Vector(position.x, 0.6, position.z)
    })
end

-- ------------------------------------------------------------
-- Stations
-- ------------------------------------------------------------

function findStationByPosition(position)
    local position = roundVector(position, 2)
    for name, station in pairs(stations) do
        if station.position.x == position.x and station.position.z == position.z then
            return name, station
        end
    end
end

function findStationByName(name)
    return stations[name]
end

function highlight(name, color)
    highlightPosition(stations[name].position, color)
end

function setOwner(name, owner, onLoad)
    local available = true
    if not onLoad then
        available = stationAvailable(stations[name])
    end
    if available and (stations[name].type == StationType.NEUTRAL or stations[name].type == StationType.POLIS) then
        stations[name].owner = owner
    end
end

function removeOwner(name)
    stations[name].owner = nil
end

function getOwnedStations(fraction)
    local ownedStations = {}
    for name, station in pairs(stations) do
        if station.owner == fraction then
            table.insert(ownedStations, name)
        end
    end
    return ownedStations
end

function stationAvailable(station)
    if not IGNORE_INACTIVE_ZONES then
        return true
    end
    return station.type == StationType.POLIS
        or tableContains(getSeatedPlayers(), station.zone:toString())
end

-- ------------------------------------------------------------
-- Attacks highlightion for army
-- ------------------------------------------------------------

function highlightPossibleAttacks(fraction)
    local ownedStations = getOwnedStations(fraction)
    if #ownedStations == 0 then
        do return end
    end
    local activeHeroes = ADMIN_BOARD:getActiveHeroes()
    local possibleAttacks = Set()
    local occupiedStations = {}
    local abandonedOccupiedStations = {}
    local highlightLocomotive = false
    local heroStationName = nil
    local heroStation = nil

    for heroName, hero in pairs(activeHeroes) do
        if hero.fraction == fraction then
            -- saving station where our hero stands if he has locomotive
            if ADMIN_BOARD:equipmentCount(heroName, 'locomotive') > 0 then
                heroStationName, heroStation = findStationByPosition(hero.figure.getPosition())
            end
        else
            -- for other heroes
            local occupiedStationName, occupiedStation = findStationByPosition(hero.figure.getPosition())
            if occupiedStationName != nil then
                -- adding to occupied stations if they standing on our station 
                if tableContains(ownedStations, occupiedStationName) then
                    table.insert(occupiedStations, occupiedStationName)
                -- adding to abandoned stations if they standing abandoned station
                elseif occupiedStation.type == StationType.ABANDONED then
                    table.insert(abandonedOccupiedStations, occupiedStationName)
                end
            end
        end
    end

    -- if hero has locomotive and stands on neutral station then we count that station as ours
    if heroStation != nil and heroStation.owner == nil
        and (heroStation.type == StationType.NEUTRAL or heroStation.type == StationType.POLIS) then
            table.insert(ownedStations, heroStationName)
            highlightLocomotive = true
    end

    -- searching for all possible attacks from our stations
    for i, name in ipairs(ownedStations) do
        possibleAttacks:putAll(findPossibleAttacks(name, ownedStations, abandonedOccupiedStations))
    end

    possibleAttacks:removeAll(ownedStations)
    possibleAttacks:putAll(occupiedStations)
    if highlightLocomotive == true and stationAvailable(heroStation) then
        possibleAttacks:put(heroStationName)    
    end
    for i, name in ipairs(possibleAttacks:getValues()) do
        highlight(name)
    end
end

function findPossibleAttacks(name, ownedStations, abandonedOccupiedStations)
    local speed = 1
    local set = Set()
    local q = Queue()
    set:putAll(ownedStations)
    q:put({station=stations[name], name=name, speed=speed})
    
    while q.size > 0 do
        local next = q:pop()
        set:put(next.name)
    
        for neighbour_name, type in pairs(next.station.neighbours) do
            local neighbour = stations[neighbour_name]
            if stationAvailable(neighbour) and not set:contains(neighbour_name) then
                local nextSpeed = next.speed - 1
                if nextSpeed >= 0 then
                    if neighbour.type == StationType.GANZA then
                        putGanzaNeighbours(neighbour, nextSpeed, q)
                    elseif neighbour.type == StationType.POLIS then
                        putPolisNeighbours(neighbour, neighbour_name, nextSpeed, q)
                    elseif neighbour.type == StationType.NEUTRAL then
                        q:put({station=neighbour, name=neighbour_name, speed=nextSpeed})
                    elseif neighbour.type == StationType.ABANDONED and tableContains(abandonedOccupiedStations, neighbour_name) then
                        q:put({station=neighbour, name=neighbour_name, speed=nextSpeed})
                    end
                end
            end
        end
    end
    return set:getValues()
end

function putGanzaNeighbours(ganza, speed, q)
    for neighbour_name, type in pairs(ganza.neighbours) do
        if type == Neighbouring.TUNNEL then
            for travel_name, travel_type in pairs(stations[neighbour_name].neighbours) do 
                if travel_type == Neighbouring.PASSAGE 
                    and stationAvailable(stations[travel_name])
                    and stations[travel_name].type != StationType.ABANDONED then
                    q:put({station=stations[travel_name], name=travel_name, speed=speed})                
                end
            end
        end
    end
end

function putPolisNeighbours(polis, name, speed, q)
    q:put({station=polis, name=name, speed=speed})
    if polis.owner != nil then
        do return end
    end
    for neighbour_name, type in pairs(polis.neighbours) do
        if stations[neighbour_name].type == StationType.POLIS then
            q:put({station=stations[neighbour_name], name=neighbour_name, speed=speed})
            if stations[neighbour_name].owner == nil then
                for travel_name, travel_type in pairs(stations[neighbour_name].neighbours) do 
                    if stationAvailable(stations[travel_name]) then
                        q:put({station=stations[travel_name], name=travel_name, speed=speed})
                    end
                end
            end            
        elseif stationAvailable(stations[neighbour_name]) then
            q:put({station=stations[neighbour_name], name=neighbour_name, speed=speed})
        end
    end
end

-- ------------------------------------------------------------
-- Moves highlightion for hero
-- ------------------------------------------------------------

function highlightPossibleMoves(position, speed, isAnna)
    local origin_name, station = findStationByPosition(position)
    if station == nil then
        do return end
    end
    if stationAvailable(station) then 
        local possibleMoves = findPossibleMoves(origin_name, speed, isAnna)
        for _, station_name in ipairs(possibleMoves) do
            highlight(station_name)
        end
    end
    highlight(origin_name, Color.GREEN)
end

function findPossibleMoves(name, speed, isAnna)
    local set = Set()
    local q = Queue()
    q:put({station=stations[name], name=name, speed=speed})
    
    while q.size > 0 do
        local next = q:pop()
        set:put(next.name)
        for neighbour_name, type in pairs(next.station.neighbours) do
            local neighbour = stations[neighbour_name]
            if stationAvailable(neighbour) and not set:contains(neighbour_name) then
                if isAnna and type == Neighbouring.PASSAGE then
                    nextSpeed = next.speed
                else
                    nextSpeed = next.speed - 1
                end
                if nextSpeed >= 0 then
                    q:put({station=neighbour, name=neighbour_name, speed=nextSpeed})
                end
            end
        end
    end
    return set:getValues()
end

-- ------------------------------------------------------------
-- Stations data
-- ------------------------------------------------------------

Production = {
    BULLET = 1,
    PORK = 2, 
    MUSHROOM = 3,
    GENERIC = 4
}

Neighbouring = {
    TUNNEL = 'TUNNEL',
    PASSAGE = 'PASSAGE'
}

StationType = {
    NEUTRAL = 'NEUTRAL',
    POLIS = 'POLIS',
    GANZA = 'GANZA',
    ABANDONED = 'ABANDONED'
}

stations = {
    aeroport = {
        position = Vector(-9.13, 0.6, -8.30),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            dynamo = Neighbouring.TUNNEL
        }
    },
    dynamo = {
        position = Vector(-8.29, 0.6, -7.39),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            aeroport = Neighbouring.TUNNEL,
            belorusskaya_green = Neighbouring.TUNNEL
        }
    },
    belorusskaya_green = {
        position = Vector(-7.29, 0.6, -6.48),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            dynamo = Neighbouring.TUNNEL,
            mayakovskaya = Neighbouring.TUNNEL,
            belorusskaya_ganza = Neighbouring.PASSAGE
        }
    },
    belorusskaya_ganza = {
        position = Vector(-6.58, 0.6, -5.79),
        zone = Color.ORANGE,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            mendeleevskaya_ganza = Neighbouring.TUNNEL,
            barricadnaya_ganza = Neighbouring.TUNNEL,
            belorusskaya_green = Neighbouring.PASSAGE
        }
    },
    mendeleevskaya_grey = {
        position = Vector(-9.39, 0.6, -3.05),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            savelovskaya = Neighbouring.TUNNEL,
            tsvetnoy_bulvar = Neighbouring.TUNNEL,
            mendeleevskaya_ganza = Neighbouring.PASSAGE
        }
    },    
    mendeleevskaya_ganza = {
        position = Vector(-8.64, 0.6, -2.35),
        zone = Color.ORANGE,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            belorusskaya_ganza = Neighbouring.TUNNEL,
            dostoevskaya_ganza = Neighbouring.TUNNEL,
            mendeleevskaya_grey = Neighbouring.PASSAGE
        }
    },
    savelovskaya = {
        position = Vector(-10.62, 0.6, -3.06),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            mendeleevskaya_grey = Neighbouring.TUNNEL
        }
    },
    dostoevskaya_light_green = {
        position = Vector(-9.83, 0.6, 1.15),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            trubnaya = Neighbouring.TUNNEL,
            dostoevskaya_ganza = Neighbouring.PASSAGE
        }
    },
    dostoevskaya_ganza = {
        position = Vector(-8.83, 0.6, 1.13),
        zone = Color.GREEN,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            mendeleevskaya_ganza = Neighbouring.TUNNEL,
            prospect_mira_ganza = Neighbouring.TUNNEL,
            dostoevskaya_light_green = Neighbouring.PASSAGE
        }
    },
    prospect_mira_red = {
        position = Vector(-8.66, 0.6, 4.30),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            rizhskaya = Neighbouring.TUNNEL,
            suharevskaya = Neighbouring.TUNNEL,
            prospect_mira_ganza = Neighbouring.PASSAGE
        }
    },    
    prospect_mira_ganza = {
        position = Vector(-7.93, 0.6, 3.56),
        zone = Color.GREEN,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            dostoevskaya_ganza = Neighbouring.TUNNEL,
            komsomolskaya_ganza = Neighbouring.TUNNEL,
            prospect_mira_red = Neighbouring.PASSAGE
        }
    },
    rizhskaya = {
        position = Vector(-9.81, 0.6, 4.26),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            prospect_mira_red = Neighbouring.TUNNEL
        }
    },       
    komsomolskaya_red = {
        position = Vector(-7.28, 0.6, 6.16),
        zone = Color.RED,
        type = StationType.ABANDONED,
        production = Production.GENERIC,
        neighbours = {
            krasnoselskaya = Neighbouring.TUNNEL,
            kransnye_vorota = Neighbouring.TUNNEL,
            komsomolskaya_ganza = Neighbouring.PASSAGE
        }
    },
    komsomolskaya_ganza = {
        position = Vector(-6.58, 0.6, 5.48),
        zone = Color.RED,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            prospect_mira_ganza = Neighbouring.TUNNEL,
            kurskaya_ganza = Neighbouring.TUNNEL,
            komsomolskaya_red = Neighbouring.PASSAGE
        }
    },    
    krasnoselskaya = {
        position = Vector(-8.36, 0.6, 7.08),
        zone = Color.RED,
        type = StationType.ABANDONED,
        production = Production.GENERIC,
        neighbours = {
            komsomolskaya_red = Neighbouring.TUNNEL
        }
    },
    beregovaya = {
        position = Vector(-4.19, 0.6, -9.87),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            ulitsa_1905_goda = Neighbouring.TUNNEL
        }
    },
    ulitsa_1905_goda = {
        position = Vector(-3.35, 0.6, -9),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            beregovaya = Neighbouring.TUNNEL,
            barricadnaya_pink = Neighbouring.TUNNEL
        }
    },
    barricadnaya_ganza = {
        position = Vector(-2.56, 0.6, -8.20),
        zone = Color.ORANGE,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            belorusskaya_ganza = Neighbouring.TUNNEL,
            kievskaya_ganza = Neighbouring.TUNNEL,
            barricadnaya_pink = Neighbouring.PASSAGE
        }
    },
    barricadnaya_pink = {
        position = Vector(-2.55, 0.6, -7.18),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            ulitsa_1905_goda = Neighbouring.TUNNEL,
            pushkinskaya = Neighbouring.TUNNEL,
            barricadnaya_ganza = Neighbouring.PASSAGE
        }
    },
    pushkinskaya = {
        position = Vector(-2.66, 0.6, -3),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            barricadnaya_pink = Neighbouring.TUNNEL,
            kuznetskiy_most = Neighbouring.TUNNEL,
            chehovskaya = Neighbouring.PASSAGE,
            tverskaya = Neighbouring.PASSAGE
        }
    },
    chehovskaya = {
        position = Vector(-3.46, 0.6, -2.44),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            tsvetnoy_bulvar = Neighbouring.TUNNEL,
            borovitskaya = Neighbouring.TUNNEL,
            pushkinskaya = Neighbouring.PASSAGE,
            tverskaya = Neighbouring.PASSAGE
        }
    },
    tverskaya = {
        position = Vector(-2.67, 0.6, -1.97),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            mayakovskaya = Neighbouring.TUNNEL,
            teatralnaya = Neighbouring.TUNNEL,
            pushkinskaya = Neighbouring.PASSAGE,
            chehovskaya = Neighbouring.PASSAGE
        }
    },
    mayakovskaya = {
        position = Vector(-4.94, 0.6, -4.19),
        zone = Color.ORANGE,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            belorusskaya_green = Neighbouring.TUNNEL,
            tverskaya = Neighbouring.TUNNEL
        }
    },
    tsvetnoy_bulvar = {
        position = Vector(-6.09, 0.6, 0.06),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            mendeleevskaya_grey = Neighbouring.TUNNEL,
            chehovskaya = Neighbouring.TUNNEL,
            trubnaya = Neighbouring.PASSAGE
        }
    },
    trubnaya = {
        position = Vector(-6.11, 0.6, 1.09),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            dostoevskaya_light_green = Neighbouring.TUNNEL,
            sretenskiy_bulvar = Neighbouring.TUNNEL,
            tsvetnoy_bulvar = Neighbouring.PASSAGE
        }
    },
    suharevskaya = {
        position = Vector(-6.81, 0.6, 3.57),
        zone = Color.GREEN,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            prospect_mira_red = Neighbouring.TUNNEL,
            turgenevskaya = Neighbouring.TUNNEL
        }
    },
    kransnye_vorota = {
        position = Vector(-5.71, 0.6, 4.57),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            komsomolskaya_red = Neighbouring.TUNNEL,
            chistye_prudy = Neighbouring.TUNNEL
        }
    },
    chistye_prudy = {
        position = Vector(-4.82, 0.6, 3.56),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            kransnye_vorota = Neighbouring.TUNNEL,
            lubyanka = Neighbouring.TUNNEL,
            sretenskiy_bulvar = Neighbouring.PASSAGE,
            turgenevskaya = Neighbouring.PASSAGE
        }
    },
    sretenskiy_bulvar = {
        position = Vector(-4.35, 0.6, 2.63),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            trubnaya = Neighbouring.TUNNEL,
            chkalovskaya = Neighbouring.TUNNEL,
            chistye_prudy = Neighbouring.PASSAGE,
            turgenevskaya = Neighbouring.PASSAGE
        }
    },
    turgenevskaya = {
        position = Vector(-3.77, 0.6, 3.6),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            suharevskaya = Neighbouring.TUNNEL,
            kitay_gorod_orange = Neighbouring.TUNNEL,
            chistye_prudy = Neighbouring.PASSAGE,
            sretenskiy_bulvar = Neighbouring.PASSAGE
        }
    },
    lubyanka = {
        position = Vector(-2.52, 0.6, 1.38),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            chistye_prudy = Neighbouring.TUNNEL,
            ohotniy_ryad = Neighbouring.TUNNEL,
            kuznetskiy_most = Neighbouring.PASSAGE
        }
    },    
    kuznetskiy_most = {
        position = Vector(-1.84, 0.6, 2.14),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            pushkinskaya = Neighbouring.TUNNEL,
            kitay_gorod_pink = Neighbouring.TUNNEL,
            lubyanka = Neighbouring.PASSAGE
        }
    },
    ohotniy_ryad = {
        position = Vector(-0.98, 0.6, -0.25),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            lubyanka = Neighbouring.TUNNEL,
            biblioteka_imeni_lenina = Neighbouring.TUNNEL,
            teatralnaya = Neighbouring.PASSAGE,
            ploshad_revolutsii = Neighbouring.PASSAGE
        }
    },
    teatralnaya = {
        position = Vector(-0.24, 0.6, 0.49),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            tverskaya = Neighbouring.TUNNEL,
            novokuznetskaya = Neighbouring.TUNNEL,
            ohotniy_ryad = Neighbouring.PASSAGE,
            ploshad_revolutsii = Neighbouring.PASSAGE
        }
    },
    ploshad_revolutsii = {
        position = Vector(0.46, 0.6, 1.27),
        zone = Color.RED,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            kurskaya_purple = Neighbouring.TUNNEL,
            arbatskaya_purple = Neighbouring.TUNNEL,
            ohotniy_ryad = Neighbouring.PASSAGE,
            teatralnaya = Neighbouring.PASSAGE
        }
    },
    kitay_gorod_orange = {
        position = Vector(1.12, 0.6, 3.59),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            turgenevskaya = Neighbouring.TUNNEL,
            tretyakovskaya_orange = Neighbouring.TUNNEL,
            kitay_gorod_pink = Neighbouring.PASSAGE
        }
    },
    kitay_gorod_pink = {
        position = Vector(1.08, 0.6, 5.07),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            kuznetskiy_most = Neighbouring.TUNNEL,
            taganskaya_pink = Neighbouring.TUNNEL,
            kitay_gorod_orange = Neighbouring.PASSAGE
        }
    },
    kurskaya_ganza = {
        position = Vector(0.45, 0.6, 8),
        zone = Color.BROWN,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            komsomolskaya_ganza = Neighbouring.TUNNEL,
            taganskaya_ganza = Neighbouring.TUNNEL,
            kurskaya_purple = Neighbouring.PASSAGE,
            chkalovskaya = Neighbouring.PASSAGE
        }
    },
    kurskaya_purple = {
        position = Vector(0.46, 0.6, 9.01),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            ploshad_revolutsii = Neighbouring.TUNNEL,
            baumanskaya = Neighbouring.TUNNEL,
            kurskaya_ganza = Neighbouring.PASSAGE,
            chkalovskaya = Neighbouring.PASSAGE
        }
    },
    chkalovskaya = {
        position = Vector(1.32, 0.6, 8.48),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            sretenskiy_bulvar = Neighbouring.TUNNEL,
            rimskaya = Neighbouring.TUNNEL,
            kurskaya_ganza = Neighbouring.PASSAGE,
            kurskaya_purple = Neighbouring.PASSAGE
        }
    },
    baumanskaya = {
        position = Vector(-0.73, 0.6, 10.18),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            kurskaya_purple = Neighbouring.TUNNEL,
            electrozavodskaya = Neighbouring.TUNNEL
        }
    },
    electrozavodskaya = {
        position = Vector(-1.6, 0.6, 11.03),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            baumanskaya = Neighbouring.TUNNEL
        }
    },
    rimskaya = {
        position = Vector(3.48, 0.6, 9.7),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            chkalovskaya = Neighbouring.TUNNEL,
            krestyanskaya_zastava = Neighbouring.TUNNEL,
            ploshyad_illicha = Neighbouring.PASSAGE
        }
    },    
    ploshyad_illicha = {
        position = Vector(4.5, 0.6, 9.67),
        zone = Color.BROWN,
        type = StationType.ABANDONED,
        production = Production.GENERIC,
        neighbours = {
            marksistskaya = Neighbouring.TUNNEL,
            rimskaya = Neighbouring.PASSAGE
        }
    },    
    proletarskaya = {
        position = Vector(5.78, 0.6, 9.67),
        zone = Color.BROWN,
        type = StationType.ABANDONED,
        production = Production.GENERIC,
        neighbours = {
            taganskaya_pink = Neighbouring.TUNNEL,
            krestyanskaya_zastava = Neighbouring.PASSAGE
        }
    },
    krestyanskaya_zastava = {
        position = Vector(6.77, 0.6, 9.67),
        zone = Color.BROWN,
        type = StationType.ABANDONED,
        production = Production.GENERIC,
        neighbours = {
            rimskaya = Neighbouring.TUNNEL,
            proletarskaya = Neighbouring.PASSAGE
        }
    },
    taganskaya_pink = {
        position = Vector(3.54, 0.6, 7.54),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            kitay_gorod_pink = Neighbouring.TUNNEL,
            proletarskaya = Neighbouring.TUNNEL,
            taganskaya_ganza = Neighbouring.PASSAGE,
            marksistskaya = Neighbouring.PASSAGE
        }
    },
    taganskaya_ganza = {
        position = Vector(4.04, 0.6, 6.57),
        zone = Color.BROWN,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            kurskaya_ganza = Neighbouring.TUNNEL,
            paveletskaya_ganza = Neighbouring.TUNNEL,
            taganskaya_pink = Neighbouring.PASSAGE,
            marksistskaya = Neighbouring.PASSAGE
        }
    },    
    marksistskaya = {
        position = Vector(4.56, 0.6, 7.49),
        zone = Color.BROWN,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            ploshyad_illicha = Neighbouring.TUNNEL,
            tretyakovskaya_yellow = Neighbouring.TUNNEL,
            taganskaya_pink = Neighbouring.PASSAGE,
            taganskaya_ganza = Neighbouring.PASSAGE
        }
    },
    tretyakovskaya_yellow = {
        position = Vector(4.57, 0.6, 1.53),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            marksistskaya = Neighbouring.TUNNEL,
            tretyakovskaya_orange = Neighbouring.PASSAGE,
            novokuznetskaya = Neighbouring.PASSAGE
        }
    },    
    tretyakovskaya_orange = {
        position = Vector(4.09, 0.6, 0.61),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            kitay_gorod_orange = Neighbouring.TUNNEL,
            oktyabrskaya_orange = Neighbouring.TUNNEL,
            tretyakovskaya_yellow = Neighbouring.PASSAGE,
            novokuznetskaya = Neighbouring.PASSAGE
        }
    },
    novokuznetskaya = {
        position = Vector(5.12, 0.6, 0.57),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            teatralnaya = Neighbouring.TUNNEL,
            paveletskaya_green = Neighbouring.TUNNEL,
            tretyakovskaya_yellow = Neighbouring.PASSAGE,
            tretyakovskaya_orange = Neighbouring.PASSAGE
        }
    },
    borovitskaya = {
        position = Vector(1.26, 0.6, -2.42),
        zone = Color.BLACK,
        type = StationType.POLIS,
        production = Production.GENERIC,
        neighbours = {
            chehovskaya = Neighbouring.TUNNEL,
            polyanka = Neighbouring.TUNNEL,
            biblioteka_imeni_lenina = Neighbouring.PASSAGE,
            aleksandrovskiy_sad = Neighbouring.PASSAGE,
            arbatskaya_purple = Neighbouring.PASSAGE
        }
    },
    biblioteka_imeni_lenina = {
        position = Vector(0.52, 0.6, -1.68),
        zone = Color.BLACK,
        type = StationType.POLIS,
        production = Production.GENERIC,
        neighbours = {
            ohotniy_ryad = Neighbouring.TUNNEL,
            kropotkinskaya = Neighbouring.TUNNEL,
            borovitskaya = Neighbouring.PASSAGE,
            aleksandrovskiy_sad = Neighbouring.PASSAGE,
            arbatskaya_purple = Neighbouring.PASSAGE
        }
    },
    aleksandrovskiy_sad = {
        position = Vector(-0.24, 0.6, -2.42),
        zone = Color.BLACK,
        type = StationType.POLIS,
        production = Production.GENERIC,
        neighbours = {
            arbatskaya_blue = Neighbouring.TUNNEL,
            borovitskaya = Neighbouring.PASSAGE,
            biblioteka_imeni_lenina = Neighbouring.PASSAGE,
            arbatskaya_purple = Neighbouring.PASSAGE
        }
    },
    arbatskaya_purple = {
        position = Vector(0.5, 0.6, -3.22),
        zone = Color.BLACK,
        type = StationType.POLIS,
        production = Production.GENERIC,
        neighbours = {
            ploshad_revolutsii = Neighbouring.TUNNEL,
            smolenskaya_purple = Neighbouring.TUNNEL,
            borovitskaya = Neighbouring.PASSAGE,
            biblioteka_imeni_lenina = Neighbouring.PASSAGE,
            aleksandrovskiy_sad = Neighbouring.PASSAGE
        }
    },    
    arbatskaya_blue = {
        position = Vector(-0.14, 0.6, -4.11),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            aleksandrovskiy_sad = Neighbouring.TUNNEL,
            smolenskaya_blue = Neighbouring.TUNNEL
        }
    },    
    smolenskaya_purple = {
        position = Vector(0.54, 0.6, -5.2),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            arbatskaya_purple = Neighbouring.TUNNEL,
            kievskaya_purple = Neighbouring.TUNNEL
        }
    },
    smolenskaya_blue = {
        position = Vector(-0.07, 0.6, -5.85),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            arbatskaya_blue = Neighbouring.TUNNEL,
            kievskaya_blue = Neighbouring.TUNNEL
        }
    },    
    kievskaya_purple = {
        position = Vector(3.71, 0.6, -8.28),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            smolenskaya_purple = Neighbouring.TUNNEL,
            kievskaya_blue = Neighbouring.PASSAGE,
            kievskaya_ganza = Neighbouring.PASSAGE
        }
    },
    kievskaya_blue = {
        position = Vector(2.26, 0.6, -8.25),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            smolenskaya_blue = Neighbouring.TUNNEL,
            studencheskaya = Neighbouring.TUNNEL,
            kievskaya_purple = Neighbouring.PASSAGE,
            kievskaya_ganza = Neighbouring.PASSAGE
        }
    },
    kievskaya_ganza = {
        position = Vector(2.96, 0.6, -7.55),
        zone = Color.BLUE,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            barricadnaya_ganza = Neighbouring.TUNNEL,
            park_kultury_ganza = Neighbouring.TUNNEL,
            kievskaya_purple = Neighbouring.PASSAGE,
            kievskaya_blue = Neighbouring.PASSAGE
        }
    },    
    studencheskaya = {
        position = Vector(4.54, 0.6, -10.48),
        zone = Color.BLUE,
        type = StationType.ABANDONED,
        production = Production.GENERIC,
        neighbours = {
            kievskaya_blue = Neighbouring.TUNNEL
        }
    },
    park_kultury_ganza = {
        position = Vector(4.97, 0.6, -6.08),
        zone = Color.BLUE,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            kievskaya_ganza = Neighbouring.TUNNEL,
            oktyabrskaya_ganza = Neighbouring.TUNNEL,
            park_kultury_red = Neighbouring.PASSAGE
        }
    },
    park_kultury_red = {
        position = Vector(4.23, 0.6, -5.38),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            kropotkinskaya = Neighbouring.TUNNEL,
            frunzenskaya = Neighbouring.TUNNEL,
            park_kultury_ganza = Neighbouring.PASSAGE
        }
    },
    kropotkinskaya = {
        position = Vector(3.32, 0.6, -4.36),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            biblioteka_imeni_lenina = Neighbouring.TUNNEL,
            park_kultury_red = Neighbouring.TUNNEL
        }
    },
    frunzenskaya = {
        position = Vector(6.15, 0.6, -7.26),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            sportivnaya = Neighbouring.TUNNEL,
            park_kultury_red = Neighbouring.TUNNEL
        }
    },
    sportivnaya = {
        position = Vector(7.27, 0.6, -8.35),
        zone = Color.BLUE,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            frunzenskaya = Neighbouring.TUNNEL
        }
    },
    oktyabrskaya_ganza = {
        position = Vector(7.20, 0.6, -2.46),
        zone = Color.YELLOW,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            park_kultury_ganza = Neighbouring.TUNNEL,
            serpuhovskaya_ganza = Neighbouring.TUNNEL,
            oktyabrskaya_orange = Neighbouring.PASSAGE
        }
    },
    oktyabrskaya_orange = {
        position = Vector(6.45, 0.6, -1.76),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            tretyakovskaya_orange = Neighbouring.TUNNEL,
            shabolovskaya = Neighbouring.TUNNEL,
            oktyabrskaya_ganza = Neighbouring.PASSAGE
        }
    },
    shabolovskaya = {
        position = Vector(8.39, 0.6, -2.48),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            oktyabrskaya_orange = Neighbouring.TUNNEL
        }
    },
    serpuhovskaya_ganza = {
        position = Vector(7.43, 0.6, 1.09),
        zone = Color.YELLOW,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            oktyabrskaya_ganza = Neighbouring.TUNNEL,
            paveletskaya_ganza = Neighbouring.TUNNEL,
            serpuhovskaya_grey = Neighbouring.PASSAGE
        }
    },
    serpuhovskaya_grey = {
        position = Vector(8.5, 0.6, 1.07),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.MUSHROOM,
        neighbours = {
            tulskaya = Neighbouring.TUNNEL,
            polyanka = Neighbouring.TUNNEL,
            serpuhovskaya_ganza = Neighbouring.PASSAGE
        }
    },
    tulskaya = {
        position = Vector(9.76, 0.6, 1.12),
        zone = Color.YELLOW,
        type = StationType.ABANDONED,
        production = Production.GENERIC,
        neighbours = {
            serpuhovskaya_grey = Neighbouring.TUNNEL
        }
    },
    polyanka = {
        position = Vector(4.36, 0.6, -1.97),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            borovitskaya = Neighbouring.TUNNEL,
            serpuhovskaya_grey = Neighbouring.TUNNEL
        }
    },
    paveletskaya_ganza = {
        position = Vector(7.03, 0.6, 2.66),
        zone = Color.YELLOW,
        type = StationType.GANZA,
        production = Production.GENERIC,
        neighbours = {
            serpuhovskaya_ganza = Neighbouring.TUNNEL,
            taganskaya_ganza = Neighbouring.TUNNEL,
            paveletskaya_green = Neighbouring.PASSAGE
        }
    },
    paveletskaya_green = {
        position = Vector(7.77, 0.6, 3.38),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.BULLET,
        neighbours = {
            novokuznetskaya = Neighbouring.TUNNEL,
            avtozavodskaya = Neighbouring.TUNNEL,
            paveletskaya_ganza = Neighbouring.PASSAGE
        }
    },
    avtozavodskaya = {
        position = Vector(8.61, 0.6, 4.23),
        zone = Color.YELLOW,
        type = StationType.NEUTRAL,
        production = Production.PORK,
        neighbours = {
            paveletskaya_green = Neighbouring.TUNNEL
        }
    }
}

-- ------------------------------------------------------------
-- Exporting functions
-- ------------------------------------------------------------

function findStationByPositionExported(position)
    name, station = findStationByPosition(position)
    return {name = name, station = station}
end

function findStationByNameExported(args)
    return findStationByName(args.name)
end

function setOwnerExported(args)
    return setOwner(args.name, args.owner, args.onLoad)
end

function removeOwnerExported(args)
    return removeOwner(args.name)
end

function highlightPossibleMovesExported(args)
    return highlightPossibleMoves(args.position, args.speed, args.isAnna)
end

function highlightPossibleAttacksExported(args)
    return highlightPossibleAttacks(args.fraction)
end
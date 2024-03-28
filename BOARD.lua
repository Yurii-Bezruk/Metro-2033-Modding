-- ------------------------------------------------------------
-- Drawing
-- ------------------------------------------------------------

function clearAllHighlights()
  self.setVectorLines({})
end

function highlight(position)
    position = position:copy() * 0.485
    drawCircle({
        radius    = 0.2, 
        color     = Color(1, 1, 1),
        thickness = 0.02,
        position  = Vector(position.x, 0.6, position.z)
    })
end

function drawCircle(circle)
    local lines = self.getVectorLines()
    if lines == nil then lines = {} end
    lines = table.insert(lines, {
      points    = getCircleVectorPoints(circle.radius, circle.position),
      color     = circle.color,
      thickness = circle.thickness,
      rotation  = {0,-90, 0},
    })
    self.setVectorLines(lines)
end

function getCircleVectorPoints(radius, position)
    local steps = 32
    local d = 360 / steps
    local t = {}
    for i = 0, steps do
        table.insert(t, {
            position.x + (math.cos(math.rad(d * i)) * radius),
            position.y,
            position.z + (math.sin(math.rad(d * i)) * radius)
        })
    end
    return t
end


-- ------------------------------------------------------------
-- Stations
-- ------------------------------------------------------------

Production = {
    BULLET = 1,
    PORK = 2, 
    MUSHROOM = 3,
    GENERIC = 4
}

function findStationByPosition(position)   
    position = Global.call('roundVector', {vector=position, scale=2})
    for name, station in pairs(stations) do
        if station.position.x == position.x and station.position.z == position.z then
            return station
        end
    end
end

stations = {

    aeroport = {
        position = Vector(-9.13, 0.6, -8.30),
        production = Production.PORK
    },
    dynamo = {
        position = Vector(-8.29, 0.6, -7.39),
        production = Production.BULLET
    },
    belorusskaya_green = {
        position = Vector(-7.29, 0.6, -6.48),
        production = Production.MUSHROOM
    },
    belorusskaya_ganza = {
        position = Vector(-6.58, 0.6, -5.79),
        production = Production.GENERIC
    },
    mendeleevskaya_grey = {
        position = Vector(-9.39, 0.6, -3.05),
        production = Production.MUSHROOM
    },    
    mendeleevskaya_ganza = {
        position = Vector(-8.64, 0.6, -2.35),
        production = Production.GENERIC
    },
    savelovskaya = {
        position = Vector(-10.62, 0.6, -3.06),
        production = Production.BULLET
    },
    dostoevskaya_light_green = {
        position = Vector(-9.83, 0.6, 1.15),
        production = Production.BULLET
    },
    dostoevskaya_ganza = {
        position = Vector(-8.83, 0.6, 1.13),
        production = Production.GENERIC
    },
    prospect_mira_red = {
        position = Vector(-8.66, 0.6, 4.30),
        production = Production.PORK
    },    
    prospect_mira_ganza = {
        position = Vector(-7.93, 0.6, 3.56),
        production = Production.GENERIC
    },
    rizhskaya = {
        position = Vector(-9.81, 0.6, 4.26),
        production = Production.BULLET
    },       
    komsomolskaya_red = {
        position = Vector(-7.28, 0.6, 6.16),
        production = Production.GENERIC
    },
    komsomolskaya_ganza = {
        position = Vector(-6.58, 0.6, 5.48),
        production = Production.GENERIC
    },    
    krasnoselskaya = {
        position = Vector(-8.36, 0.6, 7.08),
        production = Production.GENERIC
    },
    beregovaya = {
        position = Vector(-4.19, 0.6, -9.87),
        production = Production.PORK
    },
    ulitsa_1905_goda = {
        position = Vector(-3.35, 0.6, -9),
        production = Production.MUSHROOM
    },
    barricadnaya_ganza = {
        position = Vector(-2.56, 0.6, -8.20),
        production = Production.GENERIC
    },
    barricadnaya_pink = {
        position = Vector(-2.55, 0.6, -7.18),
        production = Production.BULLET
    },
    pushkinskaya = {
        position = Vector(-2.66, 0.6, -3),
        production = Production.BULLET
    },
    chehovskaya = {
        position = Vector(-3.46, 0.6, -2.44),
        production = Production.PORK
    },
    tverskaya = {
        position = Vector(-2.67, 0.6, -1.97),
        production = Production.MUSHROOM
    },
    mayakovskaya = {
        position = Vector(-4.94, 0.6, -4.19),
        production = Production.PORK
    },
    tsvetnoy_bulvar = {
        position = Vector(-6.09, 0.6, 0.06),
        production = Production.PORK
    },
    trubnaya = {
        position = Vector(-6.11, 0.6, 1.09),
        production = Production.MUSHROOM
    },
    suharevskaya = {
        position = Vector(-6.81, 0.6, 3.57),
        production = Production.MUSHROOM
    },
    kransnye_vorota = {
        position = Vector(-5.71, 0.6, 4.57),
        production = Production.BULLET
    },
    chistye_prudy = {
        position = Vector(-4.82, 0.6, 3.56),
        production = Production.MUSHROOM
    },
    sretenskiy_bulvar = {
        position = Vector(-4.35, 0.6, 2.63),
        production = Production.PORK
    },
    turgenevskaya = {
        position = Vector(-3.77, 0.6, 3.6),
        production = Production.BULLET
    },
    lubyanka = {
        position = Vector(-2.49, 0.6, 1.43),
        production = Production.PORK
    },    
    kuznetskiy_most = {
        position = Vector(-1.83, 0.6, 2.09),
        production = Production.MUSHROOM
    },
    ohotniy_ryad = {
        position = Vector(-0.98, 0.6, -0.25),
        production = Production.BULLET
    },
    teatralnaya = {
        position = Vector(-0.24, 0.6, 0.49),
        production = Production.PORK
    },
    ploshad_revolutsii = {
        position = Vector(0.46, 0.6, 1.27),
        production = Production.MUSHROOM
    },
    kitay_gorod_orange = {
        position = Vector(1.12, 0.6, 3.59),
        production = Production.BULLET
    },
    kitay_gorod_pink = {
        position = Vector(1.08, 0.6, 5.07),
        production = Production.MUSHROOM
    },
    kurskaya_ganza = {
        position = Vector(0.45, 0.6, 8),
        production = Production.GENERIC
    },
    kurskaya_purple = {
        position = Vector(0.46, 0.6, 9.01),
        production = Production.MUSHROOM
    },
    chkalovskaya = {
        position = Vector(1.32, 0.6, 8.48),
        production = Production.BULLET
    },
    baumanskaya = {
        position = Vector(-0.73, 0.6, 10.18),
        production = Production.PORK
    },
    electrozavodskaya = {
        position = Vector(-1.6, 0.6, 11.03),
        production = Production.BULLET
    },
    rimskaya = {
        position = Vector(3.48, 0.6, 9.7),
        production = Production.PORK
    },    
    ploshyad_illicha = {
        position = Vector(4.5, 0.6, 9.67),
        production = Production.GENERIC
    },    
    proletarskaya = {
        position = Vector(5.78, 0.6, 9.67),
        production = Production.GENERIC
    },
    krestyanskaya_zastava = {
        position = Vector(6.77, 0.6, 9.67),
        production = Production.GENERIC
    },
    taganskaya_pink = {
        position = Vector(3.54, 0.6, 7.54),
        production = Production.PORK
    },
    taganskaya_ganza = {
        position = Vector(4.04, 0.6, 6.57),
        production = Production.GENERIC
    },    
    marksistskaya = {
        position = Vector(4.56, 0.6, 7.49),
        production = Production.MUSHROOM
    },
    tretyakovskaya_yellow = {
        position = Vector(4.57, 0.6, 1.53),
        production = Production.BULLET
    },    
    tretyakovskaya_orange = {
        position = Vector(4.09, 0.6, 0.61),
        production = Production.MUSHROOM
    },
    novokuznetskaya = {
        position = Vector(5.12, 0.6, 0.57),
        production = Production.PORK
    },
    borovitskaya = {
        position = Vector(1.26, 0.6, -2.42),
        production = Production.GENERIC
    },
    biblioteka_imeni_lenina = {
        position = Vector(0.52, 0.6, -1.68),
        production = Production.GENERIC
    },
    aleksandrovskiy_sad = {
        position = Vector(-0.24, 0.6, -2.42),
        production = Production.GENERIC
    },
    arbatskaya_purple = {
        position = Vector(0.5, 0.6, -3.22),
        production = Production.GENERIC
    },    
    arbatskaya_blue = {
        position = Vector(-0.14, 0.6, -4.11),
        production = Production.BULLET
    },    
    smolenskaya_purple = {
        position = Vector(0.53, 0.6, -5.18),
        production = Production.PORK
    },
    smolenskaya_blue = {
        position = Vector(-0.07, 0.6, -5.85),
        production = Production.PORK
    },    
    kievskaya_purple = {
        position = Vector(3.71, 0.6, -8.28),
        production = Production.BULLET
    },
    kievskaya_blue = {
        position = Vector(2.26, 0.6, -8.25),
        production = Production.MUSHROOM
    },
    kievskaya_ganza = {
        position = Vector(2.96, 0.6, -7.55),
        production = Production.GENERIC
    },    
    studencheskaya = {
        position = Vector(4.54, 0.6, -10.48),
        production = Production.GENERIC
    },
    park_kultury_ganza = {
        position = Vector(4.97, 0.6, -6.08),
        production = Production.GENERIC
    },
    park_kultury_red = {
        position = Vector(4.23, 0.6, -5.38),
        production = Production.PORK
    },
    kropotnitskaya = {
        position = Vector(3.32, 0.6, -4.36),
        production = Production.MUSHROOM
    },
    frunzenskaya = {
        position = Vector(6.15, 0.6, -7.26),
        production = Production.BULLET
    },
    sportivnaya = {
        position = Vector(7.27, 0.6, -8.35),
        production = Production.MUSHROOM
    },
    oktyabrskaya_ganza = {
        position = Vector(7.20, 0.6, -2.46),
        production = Production.GENERIC
    },
    oktyabrskaya_orange = {
        position = Vector(6.45, 0.6, -1.76),
        production = Production.PORK
    },    
    shabolovskaya = {
        position = Vector(8.39, 0.6, -2.48),
        production = Production.MUSHROOM
    },
    serpuhovskaya_ganza = {
        position = Vector(7.43, 0.6, 1.09),
        production = Production.GENERIC
    },
    serpuhovskaya_grey = {
        position = Vector(8.5, 0.6, 1.07),
        production = Production.MUSHROOM
    },    
    tulskaya = {
        position = Vector(9.76, 0.6, 1.12),
        production = Production.GENERIC
    },
    polyanka = {
        position = Vector(4.36, 0.6, -1.97),
        production = Production.BULLET
    },
    paveletskaya_ganza = {
        position = Vector(7.03, 0.6, 2.66),
        production = Production.GENERIC
    },
    paveletskaya_green = {
        position = Vector(7.77, 0.6, 3.38),
        production = Production.BULLET
    },
    avtozavodskaya = {
        position = Vector(8.61, 0.6, 4.23),
        production = Production.PORK
    }
}

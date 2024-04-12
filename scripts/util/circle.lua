
function clearCircle(object)
    object.setVectorLines({})
end

function drawCircle(object, circle)
    local lines = object.getVectorLines()
    if lines == nil then lines = {} end
    lines = table.insert(lines, {
        points    = getCircleVectorPoints(circle.radius, circle.position),
        color     = circle.color,
        thickness = circle.thickness,
        rotation  = {0,-90, 0},
    })
    object.setVectorLines(lines)
end

function getCircleVectorPoints(radius, position)
    local steps = 32
    local d = 360 / steps
    local vectorPoints = {}
    for i = 0, steps do
        table.insert(vectorPoints, {
            position.x + (math.cos(math.rad(d * i)) * radius),
            position.y,
            position.z + (math.sin(math.rad(d * i)) * radius)
        })
    end
    return vectorPoints
end
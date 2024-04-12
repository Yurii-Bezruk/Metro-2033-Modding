require("scripts.util.tables")

function zoneContain(zone, object)
    return tableContains(zone.getObjects(), object)
end

function zoneDecksContain(zone, object)
    for i, item in ipairs(zone.getObjects()) do
        if item.type == 'Deck' then
            for j, card in ipairs(item.getObjects()) do
                if card.guid == object.guid then
                    return true
                end
            end
        end
    end
    return false
end
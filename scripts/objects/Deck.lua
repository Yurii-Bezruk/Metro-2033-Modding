require("scripts.collections.List")

function Deck(guid)
    local deck = getObjectFromGUID(guid)
    assert(deck, "Object with guid '" .. guid .. "' not found")
    assert(deck.type == 'Deck', "Object with guid '" .. guid .. "' has unsupported type '" .. deck.type .. "'")

    local self = {}
    
    self.getObjects = function()
        return List(deck.getObjects())
    end

    self.contains = function(card)
        return card and self.getObjects():map(|obj| obj.guid):contains(card.guid)
    end

    self = setmetatable(self, {
        __index = deck
    })

    return self
end
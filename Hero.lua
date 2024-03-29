BOARD_GUID = Global.getVar('BOARD_GUID')
    
function onLoad()
    -- ------------------------------------------------------------
    -- Importing functions
    -- ------------------------------------------------------------
    BOARD = {
        obj = getObjectFromGUID(BOARD_GUID),
        highlightPossibleMoves = function(self, position, depth)
            self.obj.call('highlightPossibleMovesExported', {position=position, depth=depth})
        end,
        clearAllHighlights = function(self)
            self.obj.call('clearAllHighlights')
        end
    }
end

function onDrop(player_color)
    BOARD:clearAllHighlights() 
    --Wait.time(|| delayedOnDrop(), 0.5)
end

function delayedOnDrop()
    log('----------------')
    log(self.getPosition())
end

function onPickUp(player_color)
    --log('----------------')
    --log(self.getPosition())
    BOARD:highlightPossibleMoves(self.getPosition(), 3)
end

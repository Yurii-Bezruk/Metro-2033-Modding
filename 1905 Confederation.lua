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
end

function buttonClicked()
    active = not active
    if active then
        BOARD:highlightPossibleAttacks('confederation')
    else    
        BOARD:clearAllHighlights()
    end
end
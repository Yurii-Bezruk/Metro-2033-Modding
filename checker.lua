hero_guid = '742d9b'

function buttonClicked()
    local hero = getObjectFromGUID(hero_guid)
    log(hero.getTags())
end
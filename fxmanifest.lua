fx_version 'cerulean'
game 'gta5'

author 'Space V'

shared_scripts {
    'shared/types.lua',
    'shared/constants.lua',
}

client_scripts {
    'client/debug.lua',
    'client/helpers.lua',
    'client/cutscene.lua',
    'client/actors/ambient.lua',
    'client/actors/vagos.lua',
    'client/actors/lamar.lua',
    'client/actors/dialogue.lua',
    'client/overlay/credits.lua',
    'client/phases/setup.lua',
    'client/phases/shot1.lua',
    'client/phases/city.lua',
    'client/phases/race.lua',
    'client/phases/garage.lua',
    'client/phases/plane.lua',
    'client/phases/drive.lua',
    'client/phases/arrival.lua',
    'client/phases/finish.lua',
    'client/director.lua',
}

server_scripts {
    'server/main.lua',
}

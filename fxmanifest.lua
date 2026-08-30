fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'BWND_Bridge'
author 'BWND / Brandon'
description 'Universal framework compatibility layer for BWND_ resources (QBox / QBCore / ESX)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/log.lua',
    'shared/util.lua',
    'shared/detect.lua',
    'shared/hooks.lua',
}

server_scripts {
    'server/object.lua',
    'server/player.lua',
    'server/money.lua',
    'server/jobs.lua',
    'server/inventory.lua',
    'server/permissions.lua',
    'server/society.lua',
    'server/notify.lua',
    'server/events.lua',
    'server/exports.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua', -- comment this if not using qbox

    'client/object.lua',
    'client/player.lua',
    'client/inventory.lua',
    'client/vehicle.lua',
    'client/notify.lua',
    'client/target.lua',
    'client/events.lua',
    'client/exports.lua',
}

files {
    'init.lua',
    'config.lua',
    'shared/*.lua',
    'client/*.lua',
}

dependency 'ox_lib'

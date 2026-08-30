Bridge = Bridge or {}

function Bridge.GetConfig()
    return Bridge.Config
end

local CLIENT_API = {
    -- meta
    'GetInfo', 'GetConfig',
    -- player
    'GetPlayerData', 'IsLoggedIn', 'GetJob', 'GetGang', 'GetIdentifier',
    'GetCitizenId', 'GetPlayerName',
    -- inventory
    'GetItemCount', 'HasItem',
    -- vehicle
    'GetVehicleProperties', 'SetVehicleProperties',
    -- ui
    'Notify', 'ShowTextUI', 'HideTextUI', 'IsTextUIOpen', 'ProgressBar', 'SkillCheck',
    -- target
    'AddTargetModel', 'AddTargetEntity', 'AddBoxZone', 'RemoveZone', 'RemoveTargetModel',
    'RemoveTargetEntity', 'SetTargetingEnabled',
    -- helpers
    'MoneyType', 'Trim', 'NamesMatch', 'ResourceStarted', 'FirstStarted',
}

for _, name in ipairs(CLIENT_API) do
    local fn = Bridge[name]
    if type(fn) == 'function' then
        exports(name, fn)
    else
        Bridge.Warn(('client export "%s" has no implementation'):format(name))
    end
end

Bridge.Print('client exports registered (' .. #CLIENT_API .. ')')

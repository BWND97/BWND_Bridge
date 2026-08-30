Bridge = Bridge or {}

local SERVER_API = {
    -- meta
    'GetInfo', 'GetConfig',
    -- player
    'GetPlayer', 'GetPlayerByCitizenId', 'GetPlayerByIdentifier', 'GetSource',
    'GetIdentifier', 'GetCitizenId', 'GetLicense', 'GetPlayerName', 'GetPlayers',
    'IsPlayerLoaded', 'GetPlayerData',
    -- money
    'GetMoney', 'AddMoney', 'RemoveMoney', 'SetMoney', 'CanAfford', 'ChargePlayer',
    -- jobs
    'GetJob', 'GetGang', 'GetJobGrade', 'SetJob', 'SetGang', 'SetJobDuty', 'IsOnDuty',
    'GetJobs', 'GetGangs', 'GetGroupGrades', 'CountPlayersWithJob',
    -- inventory
    'GetItemCount', 'HasItem', 'AddItem', 'RemoveItem', 'CanCarryItem', 'GetItem',
    'GetInventory', 'GetItemLabel', 'SetItemMetadata', 'RegisterUsableItem',
    -- permissions
    'HasPermission', 'GetPlayerGroup',
    -- society
    'GetSocietyMoney', 'AddSocietyMoney', 'RemoveSocietyMoney',
    -- ui
    'Notify', 'ShowTextUI', 'HideTextUI',
    -- helpers
    'MoneyType', 'Trim', 'NamesMatch', 'ResourceStarted', 'FirstStarted',
}

function Bridge.GetConfig()
    return Bridge.Config
end

for _, name in ipairs(SERVER_API) do
    local fn = Bridge[name]
    if type(fn) == 'function' then
        exports(name, fn)
    else
        Bridge.Warn(('export "%s" has no implementation'):format(name))
    end
end

Bridge.Print('server exports registered (' .. #SERVER_API .. ')')

Bridge = Bridge or {}

function Bridge.GetPlayerData()
    local fw = Bridge.Framework

    if fw == 'qbx' and (QBX and QBX.PlayerData) then
        return QBX.PlayerData
    end

    if QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
        local ok, d = pcall(QBCore.Functions.GetPlayerData)
        if ok and type(d) == 'table' then return d end
    end

    if fw == 'esx' and ESX and ESX.GetPlayerData then
        local ok, d = pcall(ESX.GetPlayerData)
        if ok and type(d) == 'table' then return d end
    end

    return {}
end

function Bridge.IsLoggedIn()
    if Bridge.Framework == 'esx' then
        return (ESX and ESX.IsPlayerLoaded and ESX.IsPlayerLoaded()) == true
    end
    if LocalPlayer.state.isLoggedIn ~= nil then
        return LocalPlayer.state.isLoggedIn == true
    end
    local data = Bridge.GetPlayerData()
    return data ~= nil and (data.citizenid ~= nil or data.identifier ~= nil)
end

local function normaliseGroup(group)
    if type(group) ~= 'table' then return nil end
    local grade = group.grade
    local level, gname, gboss
    if type(grade) == 'table' then
        level, gname, gboss = tonumber(grade.level) or 0, grade.name, grade.isboss == true
    else
        level, gname, gboss = tonumber(grade) or 0, group.grade_name, group.isboss == true
    end
    local onduty = group.onduty
    if onduty == nil then onduty = group.onDuty end
    if onduty == nil then onduty = true end
    return {
        name = group.name,
        label = group.label,
        type = group.type,
        onduty = onduty == true,
        isboss = group.isboss == true or gboss,
        grade = { name = gname or ('Grade ' .. level), level = level, isboss = gboss },
    }
end

function Bridge.GetJob()
    return normaliseGroup(Bridge.GetPlayerData().job)
end

function Bridge.GetGang()
    if Bridge.Framework == 'esx' then return nil end
    return normaliseGroup(Bridge.GetPlayerData().gang)
end

function Bridge.GetIdentifier()
    local data = Bridge.GetPlayerData()
    return data.citizenid or data.identifier
end

Bridge.GetCitizenId = Bridge.GetIdentifier

function Bridge.GetPlayerName()
    local data = Bridge.GetPlayerData()
    local info = data.charinfo
    if info then
        local name = Bridge.Trim(('%s %s'):format(info.firstname or '', info.lastname or ''))
        if name ~= '' then return name end
    end
    if data.name then return data.name end
    if data.firstName or data.lastName then
        return Bridge.Trim(('%s %s'):format(data.firstName or '', data.lastName or ''))
    end

    if type(PlayerId) == 'function' and type(GetPlayerName) == 'function' then
        local ok, name = pcall(function() return GetPlayerName(PlayerId()) end)
        if ok and type(name) == 'string' and name ~= '' then return name end
    end

    local ok, name = pcall(function() return exports.BWND_Bridge:GetPlayerName() end)
    if ok and type(name) == 'string' and name ~= '' then return name end

    return 'Unknown'
end

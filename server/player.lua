Bridge = Bridge or {}

function Bridge.GetPlayer(id)
    return Bridge._getPlayerObject(id)
end

function Bridge.GetPlayerByCitizenId(citizenid)
    if Bridge.Framework == 'qbx' then
        return QBX and QBX:GetPlayerByCitizenId(citizenid) or nil
    elseif Bridge.Framework == 'qb' then
        return QBCore and QBCore.Functions.GetPlayerByCitizenId(citizenid) or nil
    elseif Bridge.Framework == 'esx' then
        return ESX and ESX.GetPlayerFromIdentifier(citizenid) or nil
    end
    return nil
end

function Bridge.GetPlayerByIdentifier(identifier)
    if Bridge.Framework == 'esx' then
        return ESX and ESX.GetPlayerFromIdentifier(identifier) or nil
    end
    return Bridge.GetPlayerByCitizenId(identifier)
end

function Bridge.GetSource(player)
    if type(player) == 'number' then return player end
    if type(player) ~= 'table' then return nil end
    if player.PlayerData then return player.PlayerData.source end   -- qbx / qb
    return player.source                                           -- esx
end

function Bridge.GetIdentifier(id)
    local p = Bridge._getPlayerObject(id)
    if not p then return nil end
    if p.PlayerData then return p.PlayerData.citizenid end
    return p.identifier
end

Bridge.GetCitizenId = Bridge.GetIdentifier

function Bridge.GetLicense(id, kind)
    kind = kind or 'license'
    local src = Bridge.AsSource(id) or Bridge.GetSource(Bridge._getPlayerObject(id))
    if not src then return nil end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local ident = GetPlayerIdentifier(src, i)
        if ident and ident:sub(1, #kind + 1) == (kind .. ':') then
            return ident
        end
    end
    return nil
end

function Bridge.GetPlayerName(id)
    local p = Bridge._getPlayerObject(id)
    if not p then
        local src = Bridge.AsSource(id)
        return src and GetPlayerName(src) or 'Unknown'
    end
    if p.PlayerData then
        local info = p.PlayerData.charinfo
        if info then
            local name = Bridge.Trim(('%s %s'):format(info.firstname or '', info.lastname or ''))
            if name ~= '' then return name end
        end
        return 'Unknown'
    end
    -- esx
    if p.getName then return p.getName() end
    return 'Unknown'
end

function Bridge.GetPlayers()
    if Bridge.Framework == 'qbx' then
        local ids = {}
        for src in pairs(QBX and QBX:GetQBPlayers() or {}) do ids[#ids + 1] = src end
        return ids
    elseif Bridge.Framework == 'qb' then
        local ids = {}
        for src in pairs(QBCore and QBCore.Functions.GetQBPlayers() or {}) do ids[#ids + 1] = src end
        return ids
    elseif Bridge.Framework == 'esx' then
        return ESX and ESX.GetPlayers() or {}
    end
    return {}
end

function Bridge.IsPlayerLoaded(id)
    return Bridge._getPlayerObject(id) ~= nil
end

function Bridge.GetPlayerData(id)
    local p = Bridge._getPlayerObject(id)
    if not p then return nil end

    local out = {
        job = Bridge.GetJob(id),
        gang = Bridge.GetGang(id),
        money = {
            cash = Bridge.GetMoney(id, 'cash'),
            bank = Bridge.GetMoney(id, 'bank'),
            black = Bridge.GetMoney(id, 'black'),
        },
    }

    if p.PlayerData then -- qbx / qb
        local pd = p.PlayerData
        local info = pd.charinfo or {}
        out.source = pd.source
        out.citizenid = pd.citizenid
        out.identifier = Bridge.GetLicense(pd.source, 'license')
        out.firstname = info.firstname
        out.lastname = info.lastname
        out.name = Bridge.Trim(('%s %s'):format(info.firstname or '', info.lastname or ''))
        out.metadata = pd.metadata or {}
        out.charinfo = info
    else -- esx
        out.source = p.source
        out.citizenid = p.identifier
        out.identifier = p.identifier
        out.name = (p.getName and p.getName()) or 'Unknown'
        local variables = p.variables or {}
        out.firstname = variables.firstName or (p.get and p.get('firstName'))
        out.lastname = variables.lastName or (p.get and p.get('lastName'))
        out.metadata = (p.getMeta and p.getMeta()) or {}
        out.charinfo = {
            firstname = out.firstname,
            lastname = out.lastname,
            phone = variables.phoneNumber,
        }
    end

    if out.name == nil or out.name == '' then out.name = 'Unknown' end
    return out
end

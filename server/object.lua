Bridge = Bridge or {}

QBX = nil      -- exports.qbx_core
QBCore = nil   -- qb-core core object
ESX = nil      -- es_extended shared object

local function resolve()
    if Bridge.Framework == 'qbx' then
        QBX = exports.qbx_core
        return QBX ~= nil
    elseif Bridge.Framework == 'qb' then
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        QBCore = ok and core or nil
        return QBCore ~= nil
    elseif Bridge.Framework == 'esx' then
        local ok, shared = pcall(function() return exports['es_extended']:getSharedObject() end)
        if not ok or not shared then
            -- Legacy ESX (< 1.9) has no export; fall back to the event.
            TriggerEvent('esx:getSharedObject', function(obj) shared = obj end)
        end
        ESX = shared
        return ESX ~= nil
    end
    return false
end

if not resolve() then
    CreateThread(function()
        local tries = 0
        while not resolve() and tries < 100 do
            tries = tries + 1
            Wait(100)
        end
        if Bridge.Framework ~= 'unknown' and not (QBX or QBCore or ESX) then
            Bridge.Error(('could not resolve the %s object after 10s'):format(Bridge.Framework))
        end
    end)
end

function Bridge.GetCoreObject()
    if Bridge.Framework == 'qbx' then return QBX end
    if Bridge.Framework == 'qb' then return QBCore end
    if Bridge.Framework == 'esx' then return ESX end
    return nil
end


function Bridge._getPlayerObject(id)
    if id == nil then return nil end

    if type(id) == 'table' then
        if id.PlayerData or id.source or id.identifier then return id end
        return nil
    end

    if Bridge.Framework == 'qbx' then
        if not QBX then return nil end
        return QBX:GetPlayer(id)                       -- accepts source or citizenid
    elseif Bridge.Framework == 'qb' then
        if not QBCore then return nil end
        local src = Bridge.AsSource(id)
        if src then
            return QBCore.Functions.GetPlayer(src)
        end
        return QBCore.Functions.GetPlayerByCitizenId(id)
    elseif Bridge.Framework == 'esx' then
        if not ESX then return nil end
        local src = Bridge.AsSource(id)
        if src then
            return ESX.GetPlayerFromId(src)
        end
        return ESX.GetPlayerFromIdentifier(id)
    end
    return nil
end

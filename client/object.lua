Bridge = Bridge or {}

QBCore = nil
ESX = nil

local function resolve()
    if Bridge.Framework == 'qbx' or Bridge.Framework == 'qb' then
        if not QBCore and GetResourceState('qb-core') ~= 'missing' then
            local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
            QBCore = (ok and type(core) == 'table') and core or nil
        end
        return Bridge.Framework == 'qbx' or QBCore ~= nil
    elseif Bridge.Framework == 'esx' then
        local ok, shared = pcall(function() return exports['es_extended']:getSharedObject() end)
        if not ok or not shared then
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
    end)
end

function Bridge.GetCoreObject()
    if Bridge.Framework == 'qbx' then return exports.qbx_core end
    if Bridge.Framework == 'qb' then return QBCore end
    if Bridge.Framework == 'esx' then return ESX end
    return nil
end

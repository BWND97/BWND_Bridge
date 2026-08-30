Bridge = Bridge or {}

local function emit(name, ...)
    TriggerEvent('BWND_Bridge:server:' .. name, ...)
end

local function resolveSrc(arg)
    if type(arg) == 'number' and arg > 0 then return arg end
    if type(arg) == 'table' and arg.PlayerData then return arg.PlayerData.source end
    local s = tonumber(source)
    if s and s > 0 then return s end
    return nil
end

if Bridge.IsQB then
    RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function(arg)
        local src = resolveSrc(arg)
        if not src then return end
        emit('playerLoaded', src, Bridge.GetPlayerData(src))
    end)

    RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(arg)
        local src = resolveSrc(arg)
        if src then emit('playerUnloaded', src) end
    end)

    RegisterNetEvent('QBCore:Server:OnJobUpdate', function(arg, job)
        local src = resolveSrc(arg)
        if not src then return end
        emit('jobUpdate', src, Bridge.GetJob(src) or job)
    end)

    RegisterNetEvent('QBCore:Server:OnGangUpdate', function(arg, gang)
        local src = resolveSrc(arg)
        if not src then return end
        emit('gangUpdate', src, Bridge.GetGang(src) or gang)
    end)

    RegisterNetEvent('QBCore:Server:SetDuty', function(arg, onDuty)
        local src = resolveSrc(arg)
        if not src then return end
        emit('dutyUpdate', src, onDuty == true, Bridge.GetJob(src))
    end)

elseif Bridge.Framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded', function(playerId)
        emit('playerLoaded', playerId, Bridge.GetPlayerData(playerId))
    end)

    RegisterNetEvent('esx:playerDropped', function(playerId, reason)
        emit('playerUnloaded', playerId)
        emit('playerDropped', playerId, reason)
    end)

    RegisterNetEvent('esx:setJob', function(playerId, job)
        emit('jobUpdate', playerId, Bridge.GetJob(playerId) or job)
        local onDuty = job and (job.onDuty ~= nil and job.onDuty or job.onduty)
        if onDuty ~= nil then
            emit('dutyUpdate', playerId, onDuty == true, job)
        end
    end)
end

if Bridge.Framework ~= 'esx' then
    AddEventHandler('playerDropped', function(reason)
        emit('playerUnloaded', source)
        emit('playerDropped', source, reason)
    end)
end

Bridge = Bridge or {}

local function emit(name, ...)
    TriggerEvent('BWND_Bridge:client:' .. name, ...)
end

if Bridge.IsQB then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        emit('playerLoaded')
    end)
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        emit('playerUnloaded')
    end)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
        emit('jobUpdate', Bridge.GetJob() or job)
        if job and job.onduty ~= nil then
            emit('dutyUpdate', job.onduty == true, job)
        end
    end)
    RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
        emit('gangUpdate', Bridge.GetGang() or gang)
    end)
    RegisterNetEvent('QBCore:Client:SetDuty', function(onDuty)
        emit('dutyUpdate', onDuty == true, Bridge.GetJob())
    end)

elseif Bridge.Framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded', function()
        emit('playerLoaded')
    end)
    RegisterNetEvent('esx:onPlayerLogout', function()
        emit('playerUnloaded')
    end)
    RegisterNetEvent('esx:setJob', function(job)
        emit('jobUpdate', Bridge.GetJob() or job)
        local onDuty = job and (job.onDuty ~= nil and job.onDuty or job.onduty)
        if onDuty ~= nil then
            emit('dutyUpdate', onDuty == true, job)
        end
    end)
end

Bridge = Bridge or {}

function Bridge.Notify(src, message, notifyType, duration)
    if not src or not message then return end
    notifyType = notifyType or 'inform'

    if Bridge.NotifySystem == 'ox_lib' then
        TriggerClientEvent('ox_lib:notify', src, {
            description = message,
            type = notifyType,
            duration = duration,
        })
        return
    end

    if Bridge.Framework == 'qbx' then
        exports.qbx_core:Notify(src, message, notifyType, duration)
    elseif Bridge.Framework == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, message, notifyType, duration)
    elseif Bridge.Framework == 'esx' then
        TriggerClientEvent('esx:showNotification', src, message)
    else
        TriggerClientEvent('ox_lib:notify', src, { description = message, type = notifyType, duration = duration })
    end
end

function Bridge.ShowTextUI(src, message, opts)
    if not src or not message then return end
    TriggerClientEvent('BWND_Bridge:client:showTextUI', src, message, opts)
end

function Bridge.HideTextUI(src)
    if not src then return end
    TriggerClientEvent('BWND_Bridge:client:hideTextUI', src)
end

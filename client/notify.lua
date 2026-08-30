Bridge = Bridge or {}

function Bridge.Notify(message, notifyType, duration)
    if not message then return end
    notifyType = notifyType or 'inform'

    if Bridge.NotifySystem == 'ox_lib' and lib and lib.notify then
        lib.notify({ description = message, type = notifyType, duration = duration })
        return
    end

    if Bridge.Framework == 'qbx' then
        exports.qbx_core:Notify(message, notifyType, duration)
    elseif Bridge.Framework == 'qb' and QBCore then
        QBCore.Functions.Notify(message, notifyType, duration)
    elseif Bridge.Framework == 'esx' and ESX then
        ESX.ShowNotification(message)
    elseif lib and lib.notify then
        lib.notify({ description = message, type = notifyType, duration = duration })
    end
end

local textUiOpen = false

function Bridge.ShowTextUI(message, opts)
    if not message then return end
    if Bridge.TextUISystem == 'ox_lib' and lib and lib.showTextUI then
        lib.showTextUI(message, opts)
        textUiOpen = true
        return
    end
    if Bridge.Framework == 'qbx' or Bridge.Framework == 'qb' then
        TriggerEvent('qb-core:client:DrawText', message, (opts and opts.position) or 'left')
        textUiOpen = true
        return
    end
    if Bridge.Framework == 'esx' and ESX and ESX.TextUI then
        ESX.TextUI(message)
        textUiOpen = true
    end
end

function Bridge.HideTextUI()
    if not textUiOpen then return end
    textUiOpen = false
    if Bridge.TextUISystem == 'ox_lib' and lib and lib.hideTextUI then
        lib.hideTextUI()
        return
    end
    if Bridge.Framework == 'qbx' or Bridge.Framework == 'qb' then
        TriggerEvent('qb-core:client:HideText')
        return
    end
    if Bridge.Framework == 'esx' and ESX and ESX.HideUI then
        ESX.HideUI()
    end
end

function Bridge.IsTextUIOpen()
    return textUiOpen
end

function Bridge.ProgressBar(opts)
    if lib and lib.progressBar then
        return lib.progressBar(opts) == true
    end
    if Bridge.IsQB and QBCore then
        local done, ok = false, false
        QBCore.Functions.Progressbar('bwnd_bridge_' .. GetGameTimer(), opts.label, opts.duration or 1000,
            false, opts.canCancel ~= false, {
                disableMovement = opts.disable and opts.disable.move,
                disableCarMovement = opts.disable and opts.disable.car,
                disableMouse = false,
                disableCombat = opts.disable and opts.disable.combat,
            }, opts.anim or {}, opts.prop or {}, {},
            function() ok = true done = true end,
            function() ok = false done = true end)
        while not done do Wait(0) end
        return ok
    end
    Wait(opts.duration or 1000)
    return true
end

--- @return boolean success
function Bridge.SkillCheck(difficulty, inputs)
    if lib and lib.skillCheck then
        return lib.skillCheck(difficulty or 'easy', inputs or { 'e' }) == true
    end
    Bridge.Warn('SkillCheck requires ox_lib; auto-passing')
    return true
end

if GetCurrentResourceName() == 'BWND_Bridge' then
    RegisterNetEvent('BWND_Bridge:client:showTextUI', function(message, opts)
        Bridge.ShowTextUI(message, opts)
    end)

    RegisterNetEvent('BWND_Bridge:client:hideTextUI', function()
        Bridge.HideTextUI()
    end)
end

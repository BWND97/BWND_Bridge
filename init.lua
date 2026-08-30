local SELF = 'BWND_Bridge'

if GetResourceState(SELF) == 'missing' then
    error(("[BWND_Bridge] '%s' @-included '@%s/init.lua' but BWND_Bridge is not installed")
        :format(GetCurrentResourceName(), SELF))
end

if not (Bridge and rawget(Bridge, '_bwndInit')) then
    Bridge = Bridge or {}
    rawset(Bridge, '_bwndInit', true)

    local IS_SERVER = IsDuplicityVersion() == true
    rawset(Bridge, 'Context', IS_SERVER and 'server' or 'client')
    function Bridge.IsServer() return IS_SERVER end
    function Bridge.IsClient() return not IS_SERVER end

    local hostExports = exports[SELF]

    -- --- static environment values -------------------------------------------------
    local STATIC = {
        Version = true, Framework = true, FrameworkResource = true, IsQB = true,
        Inventory = true, Target = true, NotifySystem = true, TextUISystem = true,
        VehiclePropsSystem = true, SocietySystem = true, Config = true,
    }

    local function hydrate()
        local ok, info = pcall(function() return hostExports:GetInfo() end)
        if ok and type(info) == 'table' then
            for k, v in pairs(info) do rawset(Bridge, k, v) end
            return type(rawget(Bridge, 'Framework')) == 'string'
        end
        return false
    end

    if not hydrate() then
        CreateThread(function()
            local tries = 0
            while not hydrate() and tries < 300 do tries = tries + 1; Wait(50) end
        end)
    end

    -- --- call proxy --------------------------------------------------------------------
    setmetatable(Bridge, {
        __index = function(t, key)
            if STATIC[key] then return nil end
            local fn = function(...) return hostExports[key](hostExports, ...) end
            rawset(t, key, fn)
            return fn
        end,
    })

    -- --- normalised lifecycle event  --------------------------------------------
    local PFX = IS_SERVER and 'BWND_Bridge:server:' or 'BWND_Bridge:client:'
    local function sub(ev, cb)
        if type(cb) ~= 'function' then return end
        return AddEventHandler(PFX .. ev, function(...) cb(...) end)
    end

    --- server: cb(src, playerData)   client: cb()
    function Bridge.OnPlayerLoaded(cb) return sub('playerLoaded', cb) end
    --- server: cb(src)               client: cb()
    function Bridge.OnPlayerUnloaded(cb) return sub('playerUnloaded', cb) end
    --- server: cb(src, reason)       (server only)
    function Bridge.OnPlayerDropped(cb) return sub('playerDropped', cb) end
    --- server: cb(src, job)          client: cb(job)
    function Bridge.OnJobUpdate(cb) return sub('jobUpdate', cb) end
    --- server: cb(src, gang)         client: cb(gang)
    function Bridge.OnGangUpdate(cb) return sub('gangUpdate', cb) end
    --- server: cb(src, onDuty, job)  client: cb(onDuty, job)
    function Bridge.OnDutyUpdate(cb) return sub('dutyUpdate', cb) end
end

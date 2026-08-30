-- =====================================================================================
-- BWND_Bridge - hook & event engine
-- =====================================================================================
-- This CfxLua build does NOT pass Lua functions through exports (a function arg
-- arrives as an empty table). So there are two ways to register a hook - neither
-- ever sends a function across a resource boundary:
--
--  A) INLINE CLOSURE  (needs  shared_script '@BWND_Bridge/shared/hooks.lua'  in
--     the hooking resource). Your closure stays in YOUR state; a string-only
--     dispatch export is created for you.
--
--        Bridge.Hooks.Register('BWND_Garages', 'beforeVehicleSpawn', function(data)
--            if Blacklist[data.src] then return { allow = false, reason = 'Barred.' } end
--        end)
--
--  B) EXPORT NAME  (no @-include needed).
--
--        exports('onGarageSpawn', function(data) ... end)
--        exports.BWND_Garages:RegisterHook('beforeVehicleSpawn', 'onGarageSpawn')
--
-- The OWNER (resource that fires hook points) calls `Bridge.ExposeHooks()` once
-- per state, then fires with the local `Bridge.Hooks.Run(name, payload)`.
--
-- Return contract (from the closure / named export):
--     nil | true                       -> allow, no change
--     false                            -> veto
--     { allow = false, reason = '..' }  -> veto with a reason
--     { <other keys> }                 -> allow; keys shallow-merge into payload (filter)
-- Filter via the RETURN, not by mutating the payload arg (it's a serialised copy).
-- Every call is pcall-wrapped; an errored hook is logged and treated as "allow".
--
-- Events: owner `Bridge.Hooks.Emit(name, payload)` -> TriggerEvent('<owner>:<name>'
-- , payload) (+ '<owner>:any'). Listen with AddEventHandler('<owner>:<name>', fn).
-- =====================================================================================

Bridge = Bridge or {}
do
    local existing = rawget(Bridge, 'Hooks')
    if type(existing) == 'table' and existing.Run then return end
end

local function log(msg)
    print(('^5[BWND_Bridge]^7 %s'):format(msg))
end

local function invoker()
    local f = GetInvokingResource
    local r = f and f()
    if r and r ~= '' then return r end
    return GetCurrentResourceName()
end

rawset(Bridge, 'Hooks', {})

local registry = {}   -- [name] = { { id, resource, export? , dispatch? }, ... }
local seq = 0

local function recordRegistration(name, exportName)
    local from = invoker()
    if type(name) ~= 'string' or name == '' then
        log(('^1RegisterHook REJECTED from %s: name must be a non-empty string^7'):format(from))
        return
    end
    seq = seq + 1
    local entry = { id = seq, resource = from }
    if type(exportName) == 'string' and exportName ~= '' then
        entry.export = exportName
    else
        entry.dispatch = true
    end
    local list = registry[name]
    if not list then list = {}; registry[name] = list end
    list[#list + 1] = entry
    log(('hook registered: "%s" <- %s%s  (%d now)'):format(
        name, from, entry.export and (':' .. entry.export) or ' (closure)', #list))
    return seq
end

function Bridge.Hooks.RemoveById(id)
    for _, list in pairs(registry) do
        for i = #list, 1, -1 do
            if list[i].id == id then table.remove(list, i); return true end
        end
    end
    return false
end

function Bridge.Hooks.RemoveByResource(resource)
    if not resource then return end
    for _, list in pairs(registry) do
        for i = #list, 1, -1 do
            if list[i].resource == resource then table.remove(list, i) end
        end
    end
end

function Bridge.Hooks.Run(name, payload)
    payload = payload or {}
    local list = registry[name]
    if not list or #list == 0 then return true, nil, payload end

    log(('running hook "%s" (%d)'):format(name, #list))

    local snapshot = {}
    for i = 1, #list do snapshot[i] = list[i] end

    for _, entry in ipairs(snapshot) do
        local ok, res = pcall(function()
            local p = exports[entry.resource]
            if entry.dispatch then
                return p:__bwndHookDispatch(name, payload)
            end
            return p[entry.export](p, payload)
        end)

        if not ok then
            print(('^1[BWND_Bridge] hook "%s" from %s errored:^7 %s')
                :format(name, entry.resource, tostring(res)))
        elseif res == false then
            return false, ('blocked by %s'):format(entry.resource), payload
        elseif type(res) == 'table' then
            if res.allow == false then
                return false, res.reason or ('blocked by %s'):format(entry.resource), payload
            end
            for k, v in pairs(res) do
                if k ~= 'allow' and k ~= 'reason' then payload[k] = v end
            end
        end
    end

    return true, nil, payload
end

function Bridge.Hooks.Count(name)
    local list = registry[name]
    return list and #list or 0
end

function Bridge.Hooks.Emit(name, payload)
    if type(name) ~= 'string' or name == '' then return end
    local owner = GetCurrentResourceName()
    TriggerEvent(('%s:%s'):format(owner, name), payload)
    TriggerEvent(('%s:any'):format(owner), name, payload)
end

function Bridge.Hooks.Expose()
    if Bridge.Hooks._exposed then return end
    Bridge.Hooks._exposed = true

    exports('RegisterHook', function(name, exportName) return recordRegistration(name, exportName) end)
    exports('RemoveHook', function(id) return Bridge.Hooks.RemoveById(id) end)
    exports('RunHook', function(name, payload) return Bridge.Hooks.Run(name, payload) end)
    exports('Emit', function(name, payload) return Bridge.Hooks.Emit(name, payload) end)

    AddEventHandler('onResourceStop', function(res)
        if res ~= GetCurrentResourceName() then
            Bridge.Hooks.RemoveByResource(res)
        end
    end)

    log(('hooks exposed for %s (%s)'):format(GetCurrentResourceName(),
        IsDuplicityVersion() and 'server' or 'client'))
end

function Bridge.ExposeHooks()
    return Bridge.Hooks.Expose()
end

local outbound = {}          -- [ownerRes .. '\0' .. name] = { [id] = fn, ... }
local outboundSeq = 0
local dispatchReady = false

local function ensureDispatch()
    if dispatchReady then return end
    dispatchReady = true
    -- Called BY a hook owner during its Run(). GetInvokingResource() == that owner.
    exports('__bwndHookDispatch', function(name, payload)
        local owner = invoker()
        local bucket = outbound[owner .. '\0' .. name]
        if not bucket then return nil end

        local changes
        for _, fn in pairs(bucket) do
            local ok, res = pcall(fn, payload)
            if not ok then
                print(('^1[BWND_Bridge] hook %s:%s errored:^7 %s'):format(owner, name, tostring(res)))
            elseif res == false then
                return false
            elseif type(res) == 'table' then
                if res.allow == false then
                    return { allow = false, reason = res.reason }
                end
                for k, v in pairs(res) do
                    if k ~= 'allow' and k ~= 'reason' then
                        changes = changes or {}
                        changes[k] = v
                        payload[k] = v   -- later closures in this bucket see the filtered value
                    end
                end
            end
        end
        return changes   -- delta table, or nil
    end)
end

function Bridge.Hooks.Register(owner, name, fn)
    if type(owner) ~= 'string' or type(name) ~= 'string' or type(fn) ~= 'function' then
        log('^1Bridge.Hooks.Register(owner: string, name: string, fn: function) - bad args^7')
        return
    end

    ensureDispatch()

    outboundSeq = outboundSeq + 1
    local key = owner .. '\0' .. name
    local bucket = outbound[key]
    if not bucket then bucket = {}; outbound[key] = bucket end
    bucket[outboundSeq] = fn

    local ok = pcall(function() exports[owner]:RegisterHook(name) end)
    if not ok then
        log(('^1Register: "%s" has no RegisterHook export - did it call Bridge.ExposeHooks()?^7'):format(owner))
        outbound[key][outboundSeq] = nil
        return
    end

    log(('hook -> %s:%s (local #%d)'):format(owner, name, outboundSeq))
    return outboundSeq
end

function Bridge.Hooks.Remove(localId)
    for _, bucket in pairs(outbound) do
        if bucket[localId] ~= nil then bucket[localId] = nil; return true end
    end
    return false
end

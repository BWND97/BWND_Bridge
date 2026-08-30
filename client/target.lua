Bridge = Bridge or {}

local TGT = Bridge.Target

local function qbStyleTarget()
    if TGT == 'core_focus' then return exports.core_focus end
    if TGT == 'qb-target' then return exports['qb-target'] end
    return nil
end

local function normGroups(g)
    if g == nil or type(g) == 'string' then return g end
    local isArray = false
    for k in pairs(g) do
        if type(k) == 'number' then isArray = true break end
    end
    if not isArray then return g end
    local map = {}
    for _, name in ipairs(g) do map[name] = 0 end
    return map
end

local function toNative(options)
    local out = {}
    for i = 1, #options do
        local o = options[i]
        local onSelect = o.onSelect
        local native = {
            label = o.label,
            icon = o.icon,
            name = o.name,
            distance = o.distance,
            job = normGroups(o.groups or o.job),
            gang = normGroups(o.gang),
            item = o.items or o.item,
            canInteract = o.canInteract,
            type = o.type,
        }

        if onSelect then
            native.action = function(entity, data)
                local payload = type(data) == 'table' and data or {}
                if payload.entity == nil then payload.entity = entity end
                if payload.coords == nil and entity and entity ~= 0 and DoesEntityExist(entity) then
                    payload.coords = GetEntityCoords(entity)
                end
                onSelect(payload)
            end
        else
            native.event = o.event
            native.serverEvent = o.serverEvent
        end

        out[i] = native
    end
    return out
end

local function distanceOf(options)
    return (options[1] and options[1].distance) or 2.5
end

function Bridge.AddTargetModel(models, options)
    if TGT == 'ox_target' then
        exports.ox_target:addModel(models, options)
        return
    end
    local t = qbStyleTarget()
    if t then
        t:AddTargetModel(models, { options = toNative(options), distance = distanceOf(options) })
    end
end

function Bridge.AddTargetEntity(entity, options)
    if TGT == 'ox_target' then
        if NetworkGetEntityIsNetworked(entity) then
            exports.ox_target:addEntity(NetworkGetNetworkIdFromEntity(entity), options)
        else
            exports.ox_target:addLocalEntity(entity, options)
        end
        return
    end
    local t = qbStyleTarget()
    if t then
        t:AddTargetEntity(entity, { options = toNative(options), distance = distanceOf(options) })
    end
end

function Bridge.AddBoxZone(name, coords, size, options, zoneOpts)
    zoneOpts = zoneOpts or {}
    if TGT == 'ox_target' then
        return exports.ox_target:addBoxZone({
            coords = coords,
            size = size,
            rotation = zoneOpts.heading or 0.0,
            debug = zoneOpts.debug,
            options = options,
        })
    end

    local t = qbStyleTarget()
    if not t then return nil end

    t:AddBoxZone(name, coords, size.x or 2.0, size.y or 2.0, {
        name = name,
        heading = zoneOpts.heading or 0.0,
        minZ = coords.z - (size.z or 2.0) / 2,
        maxZ = coords.z + (size.z or 2.0) / 2,
        debugPoly = zoneOpts.debug,
    }, {
        options = toNative(options),
        distance = distanceOf(options),
    })
    return name
end

function Bridge.RemoveZone(id)
    if TGT == 'ox_target' then
        exports.ox_target:removeZone(id)
        return
    end
    local t = qbStyleTarget()
    if t then t:RemoveZone(id) end
end

function Bridge.RemoveTargetModel(models, labels)
    if TGT == 'ox_target' then
        exports.ox_target:removeModel(models, labels)
        return
    end
    local t = qbStyleTarget()
    if t then t:RemoveTargetModel(models, labels) end
end

function Bridge.RemoveTargetEntity(entity, labels)
    if TGT == 'ox_target' then
        if NetworkGetEntityIsNetworked(entity) then
            exports.ox_target:removeEntity(NetworkGetNetworkIdFromEntity(entity), labels)
        else
            exports.ox_target:removeLocalEntity(entity, labels)
        end
        return
    end
    local t = qbStyleTarget()
    if t then t:RemoveTargetEntity(entity, labels) end
end

function Bridge.SetTargetingEnabled(state)
    if TGT == 'core_focus' then
        exports.core_focus:AllowTargeting(state ~= false)
    elseif TGT == 'ox_target' then
        exports.ox_target:disableTargeting(state == false)
    elseif TGT == 'qb-target' then
        if state == false then
            exports['qb-target']:AllowTargeting(false)
        else
            exports['qb-target']:AllowTargeting(true)
        end
    end
end

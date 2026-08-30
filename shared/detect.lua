Bridge = Bridge or {}

Bridge.Version = GetResourceMetadata('BWND_Bridge', 'version', 0) or '0.0.0'
Bridge.Context = Bridge.IsServer() and 'server' or 'client'

Bridge.IsHost = GetCurrentResourceName() == 'BWND_Bridge'

local cfg = Bridge.Config or {}

local FRAMEWORK_RESOURCES = {
    qbx = 'qbx_core',
    qb  = 'qb-core',
    esx = 'es_extended',
}

local function detectFramework()
    local pinned = cfg.Framework
    if pinned and pinned ~= 'auto' then
        return pinned, FRAMEWORK_RESOURCES[pinned] or pinned
    end
    -- Priority: QBox > QBCore > ESX.
    if Bridge.ResourceStarted('qbx_core') then return 'qbx', 'qbx_core' end
    if Bridge.ResourceStarted('qb-core') then return 'qb', 'qb-core' end
    if Bridge.ResourceStarted('es_extended') then return 'esx', 'es_extended' end
    return 'unknown', nil
end

Bridge.Framework, Bridge.FrameworkResource = detectFramework()

Bridge.IsQB = (Bridge.Framework == 'qbx' or Bridge.Framework == 'qb')

-- --- Inventory ------------------------------------------------------------------
local function detectInventory()
    local pinned = cfg.Inventory
    if pinned and pinned ~= 'auto' then return pinned end
    if Bridge.ResourceStarted('jaksam_inventory') then return 'jaksam_inventory' end
    if Bridge.ResourceStarted('ox_inventory') then return 'ox_inventory' end
    if Bridge.ResourceStarted('qb-inventory') then return 'qb-inventory' end
    if Bridge.ResourceStarted('qs-inventory') then return 'qs-inventory' end
    if Bridge.Framework == 'esx' then return 'esx' end
    return 'core'
end

Bridge.Inventory = detectInventory()

-- --- Target ------------------------------------------------------------------
local function detectTarget()
    local pinned = cfg.Target
    if pinned and pinned ~= 'auto' then return pinned end
    if Bridge.ResourceStarted('core_focus') then return 'core_focus' end
    if Bridge.ResourceStarted('ox_target') then return 'ox_target' end
    if Bridge.ResourceStarted('qb-target') then return 'qb-target' end
    return 'none'
end

Bridge.Target = detectTarget()

-- --- Notify / TextUI ------------------------------------------------------------
local hasOxLib = Bridge.ResourceStarted('ox_lib')

local function pickUiSystem(pinned)
    if pinned == 'ox_lib' then return 'ox_lib' end
    if pinned == 'framework' then return 'framework' end
    return hasOxLib and 'ox_lib' or 'framework'
end

Bridge.NotifySystem = pickUiSystem(cfg.Notify)
Bridge.TextUISystem = pickUiSystem(cfg.TextUI)

-- --- Vehicle properties ------------------------------------------------------------
local function detectVehicleProps()
    local pinned = cfg.VehicleProps
    if pinned and pinned ~= 'auto' then return pinned end
    if Bridge.ResourceStarted('jg-mechanic') then return 'jg-mechanic' end
    return 'ox_lib'
end

Bridge.VehiclePropsSystem = detectVehicleProps()

-- --- Society banking ------------------------------------------------------------
local function detectSociety()
    local pinned = cfg.Society
    if pinned and pinned ~= 'auto' then return pinned end
    if Bridge.ResourceStarted('Renewed-Banking') then return 'Renewed-Banking' end
    if Bridge.ResourceStarted('qb-banking') then return 'qb-banking' end
    if Bridge.ResourceStarted('qb-management') then return 'qb-management' end
    if Bridge.ResourceStarted('esx_society') then return 'esx_society' end
    return 'none'
end

Bridge.SocietySystem = detectSociety()

-- --- Static info payload (consumed by init.lua in every satellite resource) -------
function Bridge.GetInfo()
    return {
        Version = Bridge.Version,
        Framework = Bridge.Framework,
        FrameworkResource = Bridge.FrameworkResource,
        IsQB = Bridge.IsQB,
        Inventory = Bridge.Inventory,
        Target = Bridge.Target,
        NotifySystem = Bridge.NotifySystem,
        TextUISystem = Bridge.TextUISystem,
        VehiclePropsSystem = Bridge.VehiclePropsSystem,
        SocietySystem = Bridge.SocietySystem,
        Config = Bridge.Config,
    }
end

if Bridge.IsHost then
    CreateThread(function()
        Bridge.Print(('%s | framework=^3%s^7 inventory=^3%s^7 target=^3%s^7 notify=^3%s^7 vehProps=^3%s^7')
            :format(Bridge.Context, Bridge.Framework, Bridge.Inventory, Bridge.Target, Bridge.NotifySystem,
                Bridge.VehiclePropsSystem))
        if Bridge.Framework == 'unknown' then
            Bridge.Warn('no supported framework detected (qbx_core / qb-core / es_extended). Player/money/job calls will no-op.')
        end
    end)
end

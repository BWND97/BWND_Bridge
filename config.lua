-- =====================================================================================
-- BWND_Bridge - shared configuration
-- =====================================================================================
-- Every value defaults to 'auto', which means "detect it from the running resources".
-- Only pin something explicitly if auto-detection guesses wrong on your server.
-- =====================================================================================

Bridge = Bridge or {}

Bridge.Config = {
    -- 'auto' | 'qbx' | 'qb' | 'esx'
    Framework = 'auto',

    -- 'auto' | 'jaksam_inventory' | 'ox_inventory' | 'qb-inventory' | 'esx' | 'core'
    --  Detection order: jaksam_inventory, ox_inventory, qb-inventory, then
    --  framework-native. jaksam is preferred over its own (lossy) ox-compat shim.
    Inventory = 'auto',

    -- 'auto' | 'core_focus' | 'ox_target' | 'qb-target' | 'none'
    --  Detection order: core_focus, ox_target, qb-target. core_focus is used
    --  natively rather than through its own ox_target/qb-target emulation.
    Target = 'auto',

    -- Notifications:  'auto' | 'ox_lib' | 'framework'
    --  'auto' -> ox_lib if started, otherwise the framework's native notification.
    Notify = 'auto',

    -- Text UI (draw-text prompts):  'auto' | 'ox_lib' | 'framework'
    TextUI = 'auto',

    -- Vehicle property (de)serialisation:  'auto' | 'jg-mechanic' | 'ox_lib'
    --  'auto' -> jg-mechanic if started (keeps tuning/engine-swap data), else ox_lib.
    VehicleProps = 'auto',

    -- Society / job-bank accounts:
    -- 'auto' | 'qb-banking' | 'Renewed-Banking' | 'qb-management' | 'esx_society' | 'none'
    Society = 'auto',

    -- ESX account name that maps to Bridge's 'black' money type.
    BlackMoneyAccount = 'black_money',

    -- Print the detected environment on start and log every proxy miss.
    Debug = false,
}

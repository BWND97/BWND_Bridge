Bridge = Bridge or {}

local INV = Bridge.Inventory
local JAK = 'jaksam_inventory'

local function jak_count(id, item, metadata)
    local ok, res = pcall(function() return exports[JAK]:getTotalItemAmount(id, item, metadata) end)
    return (ok and tonumber(res)) or 0
end

local function ox_count(id, item, metadata)
    local ok, res = pcall(function()
        return exports.ox_inventory:GetItemCount(id, item, metadata)
    end)
    if ok and type(res) == 'number' then return res end
    -- Older ox_inventory builds: Search returns a count when mode == 'count'.
    local ok2, res2 = pcall(function()
        return exports.ox_inventory:Search(id, 'count', item, metadata)
    end)
    return (ok2 and tonumber(res2)) or 0
end

local function qb_count(id, item)
    local p = Bridge._getPlayerObject(id)
    if p and p.Functions and p.Functions.GetItemByName then
        local data = p.Functions.GetItemByName(item)
        return (data and data.amount) or 0
    end
    if GetResourceState('qb-inventory') == 'started' then
        local ok, res = pcall(function() return exports['qb-inventory']:GetItemCount(id, item) end)
        if ok and type(res) == 'number' then return res end
    end
    return 0
end

local function esx_count(id, item)
    local p = Bridge._getPlayerObject(id)
    if not p or not p.getInventoryItem then return 0 end
    local slot = p.getInventoryItem(item)
    return (slot and (slot.count or slot.amount)) or 0
end

function Bridge.GetItemCount(id, item, metadata)
    if INV == JAK then return jak_count(id, item, metadata) end
    if INV == 'ox_inventory' then return ox_count(id, item, metadata) end
    if INV == 'qb-inventory' or Bridge.IsQB then return qb_count(id, item) end
    if INV == 'esx' or Bridge.Framework == 'esx' then return esx_count(id, item) end
    return 0
end

function Bridge.HasItem(id, item, count)
    count = tonumber(count) or 1
    if INV == JAK then
        local ok, res = pcall(function() return exports[JAK]:hasItem(id, item, count) end)
        if ok and type(res) == 'boolean' then return res end
    end
    return Bridge.GetItemCount(id, item) >= count
end

function Bridge.AddItem(id, item, count, metadata, slot)
    count = tonumber(count) or 1

    if INV == JAK then
        local ok, success = pcall(function()
            return exports[JAK]:addItem(id, item, count, metadata, slot)
        end)
        return ok and success ~= false
    elseif INV == 'ox_inventory' then
        local ok, res = pcall(function()
            return exports.ox_inventory:AddItem(id, item, count, metadata, slot)
        end)
        return ok and res ~= false
    elseif INV == 'qb-inventory' or Bridge.IsQB then
        if GetResourceState('qb-inventory') == 'started' then
            local ok, res = pcall(function()
                return exports['qb-inventory']:AddItem(id, item, count, slot, metadata, 'bwnd_bridge')
            end)
            if ok and res ~= nil then return res ~= false end
        end
        local p = Bridge._getPlayerObject(id)
        return p ~= nil and p.Functions.AddItem(item, count, slot, metadata) ~= false
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        p.addInventoryItem(item, count)
        return true
    end
    return false
end

function Bridge.RemoveItem(id, item, count, metadata, slot)
    count = tonumber(count) or 1

    if INV == JAK then
        local ok, success = pcall(function()
            return exports[JAK]:removeItem(id, item, count, metadata, slot)
        end)
        return ok and success ~= false
    elseif INV == 'ox_inventory' then
        local ok, res = pcall(function()
            return exports.ox_inventory:RemoveItem(id, item, count, metadata, slot)
        end)
        return ok and res ~= false
    elseif INV == 'qb-inventory' or Bridge.IsQB then
        if GetResourceState('qb-inventory') == 'started' then
            local ok, res = pcall(function()
                return exports['qb-inventory']:RemoveItem(id, item, count, slot, 'bwnd_bridge')
            end)
            if ok and res ~= nil then return res ~= false end
        end
        local p = Bridge._getPlayerObject(id)
        return p ~= nil and p.Functions.RemoveItem(item, count, slot) ~= false
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        if esx_count(id, item) < count then return false end
        p.removeInventoryItem(item, count)
        return true
    end
    return false
end

function Bridge.CanCarryItem(id, item, count)
    count = tonumber(count) or 1
    if INV == JAK then
        local ok, res = pcall(function() return exports[JAK]:canCarryItem(id, item, count) end)
        return not ok or res ~= false
    elseif INV == 'ox_inventory' then
        local ok, res = pcall(function()
            return exports.ox_inventory:CanCarryItem(id, item, count)
        end)
        return not ok or res ~= false
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if p and p.canCarryItem then return p.canCarryItem(item, count) end
    end
    return true
end

function Bridge.GetSlotWithItem(id, item, metadata)
    if INV == JAK then
        local ok, res = pcall(function() return exports[JAK]:GetSlotWithItem(id, item, metadata) end)
        if ok then return res end
    elseif INV == 'ox_inventory' then
        local ok, res = pcall(function() return exports.ox_inventory:GetSlotWithItem(id, item, metadata) end)
        if ok then return res end
    elseif Bridge.IsQB then
        local p = Bridge._getPlayerObject(id)
        if p and p.Functions and p.Functions.GetItemByName then return p.Functions.GetItemByName(item) end
    end
    return nil
end

function Bridge.GetSlotsWithItem(id, item)
    if INV == JAK then
        local ok, res = pcall(function() return exports[JAK]:GetSlotsWithItem(id, item) end)
        if ok and res ~= nil then return res end
    elseif INV == 'ox_inventory' then
        local ok, res = pcall(function() return exports.ox_inventory:GetSlotsWithItem(id, item) end)
        if ok and res ~= nil then return res end
    end
    return {}
end

function Bridge.GetItem(id, item, metadata)
    if INV == JAK then
        local ok, res = pcall(function() return exports[JAK]:getItemByName(id, item, metadata) end)
        if ok then return res end
    elseif INV == 'ox_inventory' then
        local ok, res = pcall(function()
            return exports.ox_inventory:GetItem(id, item, metadata, false)
        end)
        if ok then return res end
    elseif Bridge.IsQB then
        local p = Bridge._getPlayerObject(id)
        if p and p.Functions and p.Functions.GetItemByName then
            return p.Functions.GetItemByName(item)
        end
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if p and p.getInventoryItem then return p.getInventoryItem(item) end
    end
    return nil
end

function Bridge.GetInventory(id)
    if INV == JAK then
        local ok, res = pcall(function() return exports[JAK]:getInventory(id) end)
        if ok then return res end
    elseif INV == 'ox_inventory' then
        local ok, res = pcall(function() return exports.ox_inventory:GetInventoryItems(id) end)
        if ok then return res end
    elseif Bridge.IsQB then
        local p = Bridge._getPlayerObject(id)
        return p and p.PlayerData and p.PlayerData.items or {}
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        return p and p.inventory or {}
    end
    return {}
end

function Bridge.GetItemLabel(item)
    if INV == JAK then
        local ok, data = pcall(function() return exports[JAK]:getItemLabel(item) end)
        if ok and type(data) == 'string' then return data end
        return item
    elseif INV == 'ox_inventory' then
        local ok, data = pcall(function() return exports.ox_inventory:Items(item) end)
        if ok and type(data) == 'table' then return data.label or item end
    elseif Bridge.IsQB and QBCore then
        local data = QBCore.Shared.Items[item]
        return data and data.label or item
    elseif Bridge.Framework == 'esx' and ESX then
        local items = ESX.GetItems and ESX.GetItems() or {}
        return (items[item] and items[item].label) or item
    end
    return item
end

function Bridge.SetItemMetadata(id, slot, metadata)
    if INV == JAK then
        local ok, res = pcall(function() return exports[JAK]:setItemMetadataInSlot(id, slot, metadata) end)
        return ok and res ~= false
    elseif INV == 'ox_inventory' then
        local ok, res = pcall(function() return exports.ox_inventory:SetMetadata(id, slot, metadata) end)
        return ok and res ~= false
    end
    return false
end

function Bridge.RegisterUsableItem(item, cb)
    if INV == JAK then
        local ok = pcall(function() return exports[JAK]:registerUsableItem(item, cb) end)
        if ok then
            Bridge.Debug(('RegisterUsableItem(%s) -> jaksam_inventory'):format(item))
            return
        end
    end

    if Bridge.Framework == 'qbx' then
        exports.qbx_core:CreateUseableItem(item, cb)
    elseif Bridge.Framework == 'qb' and QBCore then
        QBCore.Functions.CreateUseableItem(item, cb)
    elseif Bridge.Framework == 'esx' and ESX then
        ESX.RegisterUsableItem(item, cb)
    else
        Bridge.Warn(('RegisterUsableItem(%s): no inventory/framework to register with'):format(item))
    end
end

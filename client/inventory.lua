Bridge = Bridge or {}

function Bridge.GetItemCount(item)
    if Bridge.Inventory == 'jaksam_inventory' then
        local ok, n = pcall(function() return exports.jaksam_inventory:getTotalItemAmount(item) end)
        if ok and type(n) == 'number' then return n end
        ok, n = pcall(function() return exports.jaksam_inventory:GetItemCount(item) end)
        if ok and type(n) == 'number' then return n end
        ok, n = pcall(function() return exports.jaksam_inventory:Search('count', item) end)
        return (ok and tonumber(n)) or 0
    end

    if Bridge.Inventory == 'ox_inventory' then
        local ok, res = pcall(function() return exports.ox_inventory:Search('count', item) end)
        return (ok and tonumber(res)) or 0
    end

    local items = Bridge.GetPlayerData().items or Bridge.GetPlayerData().inventory or {}
    local total = 0
    for _, slot in pairs(items) do
        if type(slot) == 'table' and (slot.name == item or slot.item == item) then
            total = total + (slot.count or slot.amount or 0)
        end
    end
    return total
end

function Bridge.HasItem(item, count)
    return Bridge.GetItemCount(item) >= (tonumber(count) or 1)
end

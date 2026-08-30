Bridge = Bridge or {}

local function esxAccount(mtype)
    if mtype == 'cash' then return 'money' end
    if mtype == 'black' then return (Bridge.Config and Bridge.Config.BlackMoneyAccount) or 'black_money' end
    return mtype -- 'bank', or a custom account name
end

function Bridge.GetMoney(id, moneyType)
    local mtype = Bridge.MoneyType(moneyType)

    if Bridge.Framework == 'qbx' then
        if mtype == 'black' then return 0 end
        return (QBX and QBX:GetMoney(id, mtype)) or 0
    elseif Bridge.Framework == 'qb' then
        local p = Bridge._getPlayerObject(id)
        if not p then return 0 end
        if mtype == 'black' then return 0 end
        return (p.PlayerData.money and p.PlayerData.money[mtype]) or 0
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if not p then return 0 end
        local acc = p.getAccount and p.getAccount(esxAccount(mtype))
        return (acc and acc.money) or 0
    end
    return 0
end

function Bridge.AddMoney(id, moneyType, amount, reason)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end
    local mtype = Bridge.MoneyType(moneyType)
    reason = reason or 'bwnd_bridge'

    if Bridge.Framework == 'qbx' then
        if mtype == 'black' then Bridge.Warn("qbx has no 'black' money type") return false end
        return (QBX and QBX:AddMoney(id, mtype, amount, reason)) == true
    elseif Bridge.Framework == 'qb' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        if mtype == 'black' then Bridge.Warn("qb has no 'black' money type") return false end
        return p.Functions.AddMoney(mtype, amount, reason) ~= false
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        p.addAccountMoney(esxAccount(mtype), amount, reason)
        return true
    end
    return false
end

function Bridge.RemoveMoney(id, moneyType, amount, reason)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end
    local mtype = Bridge.MoneyType(moneyType)
    reason = reason or 'bwnd_bridge'

    if Bridge.Framework == 'qbx' then
        if mtype == 'black' then return false end
        return (QBX and QBX:RemoveMoney(id, mtype, amount, reason)) == true
    elseif Bridge.Framework == 'qb' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        if mtype == 'black' then return false end
        return p.Functions.RemoveMoney(mtype, amount, reason) ~= false
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        local acc = p.getAccount and p.getAccount(esxAccount(mtype))
        if not acc or acc.money < amount then return false end
        p.removeAccountMoney(esxAccount(mtype), amount, reason)
        return true
    end
    return false
end

function Bridge.SetMoney(id, moneyType, amount, reason)
    amount = tonumber(amount)
    if not amount or amount < 0 then return false end
    local mtype = Bridge.MoneyType(moneyType)
    reason = reason or 'bwnd_bridge'

    if Bridge.Framework == 'qbx' then
        return (QBX and QBX:SetMoney(id, mtype, amount, reason)) == true
    elseif Bridge.Framework == 'qb' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        return p.Functions.SetMoney(mtype, amount, reason) ~= false
    elseif Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(id)
        if not p then return false end
        p.setAccountMoney(esxAccount(mtype), amount, reason)
        return true
    end
    return false
end

function Bridge.CanAfford(id, moneyType, amount)
    amount = tonumber(amount) or 0
    return Bridge.GetMoney(id, moneyType) >= amount
end

function Bridge.ChargePlayer(id, amount, reason, order)
    order = order or { 'cash', 'bank' }
    for i = 1, #order do
        if Bridge.CanAfford(id, order[i], amount) and Bridge.RemoveMoney(id, order[i], amount, reason) then
            return true, order[i]
        end
    end
    return false, nil
end

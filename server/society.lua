Bridge = Bridge or {}

local SYS = Bridge.SocietySystem

function Bridge.GetSocietyMoney(society)
    if SYS == 'Renewed-Banking' then
        local ok, res = pcall(function() return exports['Renewed-Banking']:getAccountMoney(society) end)
        return (ok and tonumber(res)) or 0
    elseif SYS == 'qb-banking' then
        local ok, res = pcall(function() return exports['qb-banking']:GetAccountBalance(society) end)
        return (ok and tonumber(res)) or 0
    elseif SYS == 'qb-management' then
        local ok, res = pcall(function() return exports['qb-management']:GetAccount(society) end)
        return (ok and tonumber(res)) or 0
    elseif SYS == 'esx_society' then
        local balance = 0
        local done = false
        TriggerEvent('esx_society:getSociety', society, function(data)
            if data then
                TriggerEvent('esx_addonaccount:getSharedAccount', data.account, function(account)
                    balance = (account and account.money) or 0
                    done = true
                end)
            else
                done = true
            end
        end)
        local timeout = 0
        while not done and timeout < 50 do Wait(10) timeout = timeout + 1 end
        return balance
    end
    return 0
end

function Bridge.AddSocietyMoney(society, amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end

    if SYS == 'Renewed-Banking' then
        return pcall(function() exports['Renewed-Banking']:addAccountMoney(society, amount) end)
    elseif SYS == 'qb-banking' then
        return pcall(function() exports['qb-banking']:AddMoney(society, amount) end)
    elseif SYS == 'qb-management' then
        return pcall(function() exports['qb-management']:AddMoney(society, amount) end)
    elseif SYS == 'esx_society' then
        TriggerEvent('esx_society:getSociety', society, function(data)
            if data then
                TriggerEvent('esx_addonaccount:getSharedAccount', data.account, function(account)
                    if account then account.addMoney(amount) end
                end)
            end
        end)
        return true
    end
    return false
end

function Bridge.RemoveSocietyMoney(society, amount)
    amount = tonumber(amount)
    if not amount or amount <= 0 then return false end

    if SYS == 'Renewed-Banking' then
        return pcall(function() exports['Renewed-Banking']:removeAccountMoney(society, amount) end)
    elseif SYS == 'qb-banking' then
        return pcall(function() exports['qb-banking']:RemoveMoney(society, amount) end)
    elseif SYS == 'qb-management' then
        return pcall(function() exports['qb-management']:RemoveMoney(society, amount) end)
    elseif SYS == 'esx_society' then
        local ok = false
        TriggerEvent('esx_society:getSociety', society, function(data)
            if data then
                TriggerEvent('esx_addonaccount:getSharedAccount', data.account, function(account)
                    if account and account.money >= amount then
                        account.removeMoney(amount)
                        ok = true
                    end
                end)
            end
        end)
        return ok
    end
    return false
end

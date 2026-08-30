Bridge = Bridge or {}

function Bridge.HasPermission(src, permission)
    if not src or src == 0 then return false end

    if type(permission) == 'table' then
        for i = 1, #permission do
            if Bridge.HasPermission(src, permission[i]) then return true end
        end
        return false
    end

    if type(permission) ~= 'string' or permission == '' then return false end

    if IsPlayerAceAllowed(src, permission) then return true end
    if not permission:find('%.') and IsPlayerAceAllowed(src, ('group.%s'):format(permission)) then
        return true
    end

    if Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(src)
        if p and p.getGroup and p.getGroup() == permission then return true end
    end

    return false
end

function Bridge.GetPlayerGroup(src)
    if Bridge.Framework == 'esx' then
        local p = Bridge._getPlayerObject(src)
        return (p and p.getGroup and p.getGroup()) or 'user'
    end
    return nil
end

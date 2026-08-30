-- Framework-agnostic helpers used across the bridge.

Bridge = Bridge or {}

function Bridge.IsServer()
    return IsDuplicityVersion() == true
end

function Bridge.IsClient()
    return not Bridge.IsServer()
end

function Bridge.ResourceStarted(name)
    return GetResourceState(name) == 'started'
end

function Bridge.FirstStarted(list)
    for i = 1, #list do
        if GetResourceState(list[i]) == 'started' then
            return list[i]
        end
    end
    return nil
end

function Bridge.Trim(str)
    if type(str) ~= 'string' then return '' end
    return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end

function Bridge.NamesMatch(a, b)
    if type(a) ~= 'string' or type(b) ~= 'string' then return false end
    return a:lower() == b:lower()
end

function Bridge.MoneyType(t)
    t = tostring(t or 'cash'):lower()
    if t == 'cash' or t == 'money' then return 'cash' end
    if t == 'bank' then return 'bank' end
    if t == 'black' or t == 'blackmoney' or t == 'black_money' or t == 'dirty' or t == 'dirtymoney' then
        return 'black'
    end
    return t
end

function Bridge.AsSource(id)
    local n = tonumber(id)
    if n and n > 0 and n < 65536 and math.floor(n) == n then return n end
    return nil
end

function Bridge.Merge(target, source)
    if type(source) == 'table' then
        for k, v in pairs(source) do target[k] = v end
    end
    return target
end

function Bridge.SafeExport(resource, method, ...)
    if GetResourceState(resource) ~= 'started' then
        return false
    end
    return pcall(function(...)
        return exports[resource][method](...)
    end, ...)
end

Bridge = Bridge or {}

local useJg = Bridge.VehiclePropsSystem == 'jg-mechanic'

function Bridge.GetVehicleProperties(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end

    if useJg and GetResourceState('jg-mechanic') == 'started' then
        local ok, props = pcall(function()
            return exports['jg-mechanic']:getVehicleProperties(vehicle)
        end)
        if ok and props then return props end
    end

    if lib and lib.getVehicleProperties then
        return lib.getVehicleProperties(vehicle)
    end
    return nil
end

function Bridge.SetVehicleProperties(vehicle, props)
    if not vehicle or vehicle == 0 or type(props) ~= 'table' or not DoesEntityExist(vehicle) then
        return false
    end

    if useJg and GetResourceState('jg-mechanic') == 'started' then
        local ok = pcall(function()
            exports['jg-mechanic']:setVehicleProperties(vehicle, props)
        end)
        if ok then return true end
    end

    if lib and lib.setVehicleProperties then
        lib.setVehicleProperties(vehicle, props)
        return true
    end
    return false
end

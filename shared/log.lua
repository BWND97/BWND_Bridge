Bridge = Bridge or {}

local RESET = '^7'

function Bridge.Print(...)
    print(('^5[BWND_Bridge]%s'):format(RESET), ...)
end

function Bridge.Warn(...)
    print(('^3[BWND_Bridge] [warn]%s'):format(RESET), ...)
end

function Bridge.Error(...)
    print(('^1[BWND_Bridge] [error]%s'):format(RESET), ...)
end

function Bridge.Debug(...)
    local cfg = Bridge.Config
    if cfg and cfg.Debug then
        print(('^6[BWND_Bridge] [debug]%s'):format(RESET), ...)
    end
end

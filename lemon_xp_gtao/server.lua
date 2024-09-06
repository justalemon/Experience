local function ready()
    local src = tonumber(source)

    local xp = exports.lemon_xp:getXP(src)
    local level  = exports.lemon_xp:getLevel(src)
    local lower = exports.lemon_xp:getXPForLevel(level)
    local higher = exports.lemon_xp:getXPForLevel(level + 1)

    TriggerClientEvent("lemon_xp_gtao:update", src, lower, higher, xp, xp, level)
end
RegisterNetEvent("lemon_xp_gtao:ready", ready)

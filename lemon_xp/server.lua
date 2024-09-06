local storage = (function ()
    local method = GetConvar("lemon_xp_storage", "")

    if method ~= "" then
        return method
    end

    if GetResourceState("oxmysql") == "started" then
        return "oxmysql"
    end
    return "json"
end)()
local cache = {}

local function change(src, amount)
    src = tonumber(src)

    local identifier = GetPlayerIdentifierByType(src, "license")
    local total = (cache[src] or 0) + amount

    if total < 0 then
        total = 0
    end

    cache[src] = total

    if storage == "json" then
        error("not implemented")
    elseif storage == "oxmysql" then
        if GetResourceState("oxmysql") ~= "started" then
            error("Storage method set to oxmysql, but oxmysql is not running")
        end

        exports.oxmysql:prepare_async("INSERT INTO xp (id, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(XP)", {identifier, total})
    end
end

local function add(src, amount)
    src = tonumber(src)

    if amount <= 0 then
        error("Attempted to add experience equal or under zero: " .. tostring(amount))
    end

    change(src, math.abs(amount))
end
exports("add", add)

local function remove(src, amount)
    src = tonumber(src)

    if amount <= 0 then
        error("Attempted to add experience equal or under zero: " .. tostring(amount))
    end

    change(src, -amount)
end
exports("remove", remove)

local function clientReady()
    local src = tonumber(source)

    if cache[src] == nil then
        return
    end
end
RegisterNetEvent("lemon_xp:clientReady", clientReady)

local function init()
    if GetCurrentResourceName() ~= "lemon_xp" then
        print("ERROR! Experience script should be called lemon_xp, current name is " .. GetCurrentResourceName())
        StopResource(GetCurrentResourceName())
        return
    end
end
Citizen.CreateThread(init)

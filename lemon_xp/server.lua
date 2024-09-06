local storage = (function ()
    local method = GetConvar("lemon_xp_storage", "")

    if method ~= "" then
        return method
    end

    print("Guessing storage mode...")

    if GetResourceState("oxmysql") == "started" then
        return "oxmysql"
    end
    return "json"
end)()
local cache = {}

local function change(src, amount)
    local _src = src
    src = tonumber(src)

    if not src then
        error("Player Server ID is invalid: " .. tostring(_src))
    end

    local license = GetPlayerIdentifierByType(src, "license")

    if not license then
        error("Player " .. tostring(src) .. " does not has a license or is not valid")
    end

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

        exports.oxmysql:prepare_async("INSERT INTO xp (id, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(XP)", {license, total})
    end
end

local function add(src, amount)
    if amount <= 0 then
        error("Attempted to add experience equal or under zero: " .. tostring(amount))
    end

    change(src, math.abs(amount))
end
exports("add", add)

local function remove(src, amount)
    if amount <= 0 then
        error("Attempted to add experience equal or under zero: " .. tostring(amount))
    end

    change(src, -amount)
end
exports("remove", remove)

local function get(src)
    local _src = src
    src = tonumber(src)

    if not src then
        error("Player Server ID is not a number: " .. tostring(_src))
    end

    if GetNumPlayerIdentifiers(src) == 0 then
        error("Player Server ID is not valid:" .. tostring(src))
    end

    return cache[src] or 0
end
exports("get", get)

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

    print("Storage mode in use: " .. storage)

    if storage == "json" then
        print("Warning: Using JSON file for data storage")
        print("This should not be used for public servers")
        print("You should only use it for local testing")
        print("You have been warned!")
    end
end
Citizen.CreateThread(init)

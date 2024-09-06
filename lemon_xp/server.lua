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
local multipliers = {}
local multiplier = 1
local calculateLevelForXP = function(current)
    if not current or current <= 0 then
        return 1
    end

    return math.floor(current / 10000) + 1
end

-- INTERNAL TOOLS

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

-- EXPORTS

local function addXP(src, amount)
    if amount <= 0 then
        error("Attempted to add experience equal or under zero: " .. tostring(amount))
    end

    if multiplier[src] ~= nil and multiplier == 1 then
        change(src, math.abs(amount) * multiplier[src])
    else
        change(src, math.abs(amount) * multiplier)
    end
end
exports("addXP", addXP)

local function removeXP(src, amount)
    if amount <= 0 then
        error("Attempted to add experience equal or under zero: " .. tostring(amount))
    end

    change(src, -amount)
end
exports("removeXP", removeXP)

local function getXP(src)
    local _src = src
    src = tonumber(src)

    if not src then
        error("Player Server ID is not a number: " .. tostring(_src))
    end

    if GetNumPlayerIdentifiers(src) == 0 then
        error("Player Server ID is not valid:" .. tostring(src))
    end

    if cache[src] ~= nil then
        return cache[src]
    end

    local license = GetPlayerIdentifierByType(src, "license")
    local current = exports.oxmysql:prepare_async("SELECT xp FROM xp WHERE id = ?", {license})
    cache[src] = current
    return current
end
exports("getXP", getXP)

local function getLevel(src)
    return calculateLevelForXP(getXP(src))
end
exports("getLevel", getLevel)

local function setLevelCalculator(cb)
    if type(cb) ~= "function" then
        error("Expected function, got " .. type(cb))
    end

    calculateLevelForXP = cb
end
exports("setLevelCalculator", setLevelCalculator)

local function setMultiplier(mult)
    if type(mult) ~= "number" then
        error("Multiplier is not a number")
    end

    if mult < 1 then
        error("Multiplier can't be set under one")
    end

    multiplier = mult
end
exports("setMultiplier", setMultiplier)

local function getMultiplier()
    return multiplier
end
exports("getMultiplier", getMultiplier)

local function getPlayerMultiplier(src)
    return multipliers[src]
end
exports("getPlayerMultiplier", getPlayerMultiplier)

local function setPlayerMultiplier(src, mult)
    local _src = src
    src = tonumber(src)

    if not src or GetNumPlayerIdentifiers(src) == 0 then
        error("Invalid player id: " .. tostring(_src))
    end

    multipliers[src] = tonumber(mult)
end
exports("setPlayerMultiplier", setPlayerMultiplier)

-- EVENTS

local function playerJoining(src, _)
    getXP(src)
end
AddEventHandler("playerJoining", playerJoining)

local function playerDropped(_)
    local src = tonumber(source)

    if src == nil then
        print("Warning: ID of dropped player is nil, unable to perform cleanup")
        return
    end

    cache[src] = nil
    multipliers[src] = nil
end
AddEventHandler("playerDropped", playerDropped)

local function clientReady()
    local src = tonumber(source)

    if cache[src] == nil then
        return
    end
end
RegisterNetEvent("lemon_xp:clientReady", clientReady)

-- INITIALIZATION

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

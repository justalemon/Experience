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
local calculateLevelForXP = function(xp)
    if not xp or xp <= 0 then
        return 1
    end

    return math.floor(xp / 10000) + 1
end
local calculateXPForLevel = function(level)
    if not level or level <= 1 then
        return 0
    else
        return 10000 * (level - 1)
    end
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

    local old = cache[src] or 0
    local current = old + amount

    if current < 0 then
        current = 0
    end

    cache[src] = current

    if storage == "json" then
        local contents = LoadResourceFile(GetCurrentResourceName(), "xp.json")

        if contents == nil or contents == "" then
            local data = {
                [license] = current
            }
            SaveResourceFile(GetCurrentResourceName(), "xp.json", json.encode(data), -1)
        else
            local parsed = json.decode(contents)
            parsed[license] = current
            SaveResourceFile(GetCurrentResourceName(), "xp.json", json.encode(parsed), -1)
        end
    elseif storage == "oxmysql" then
        if GetResourceState("oxmysql") ~= "started" then
            error("Storage method set to oxmysql, but oxmysql is not running")
        end

        exports.oxmysql:prepare_async("INSERT INTO xp (id, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(XP)", { license, current })
    end

    TriggerEvent("lemon_xp:updated", src, old, calculateLevelForXP(old), current, calculateLevelForXP(current))
end

local function getXPFromLicense(license)
    if storage == "oxmysql" then
        local current = exports.oxmysql:prepare_async("SELECT xp FROM xp WHERE id = ?", {license})
        return current
    elseif storage == "json" then
        local contents = LoadResourceFile(GetCurrentResourceName(), "xp.json")

        if contents == nil or contents == "" then
            return 0
        end

        local parsed = json.decode(contents)
        return parsed[license] or 0
    else
        return 0
    end
end

-- EXPORTS

local function addXP(src, amount)
    if amount <= 0 then
        error("Attempted to add experience equal or under zero: " .. tostring(amount))
    end

    if multipliers[src] ~= nil and multiplier == 1 then
        change(src, math.abs(amount) * multipliers[src])
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
    local xp = getXPFromLicense(license)
    cache[src] = xp
    return xp
end
exports("getXP", getXP)

local function getLevel(src)
    return calculateLevelForXP(getXP(src))
end
exports("getLevel", getLevel)

local function setLevelCalculators(levelForXP, XPForLevel)
    if type(levelForXP) ~= "function" then
        error("Expected function, got " .. type(levelForXP))
    end
    if type(XPForLevel) ~= "function" then
        error("Expected function, got " .. type(XPForLevel))
    end

    calculateLevelForXP = levelForXP
    calculateXPForLevel = XPForLevel
end
exports("setLevelCalculators", setLevelCalculators)

local function getLevelForXP(xp)
    return calculateLevelForXP(xp)
end
exports("getLevelForXP", getLevelForXP)

local function getXPForLevel(level)
    return calculateXPForLevel(level)
end
exports("getXPForLevel", getXPForLevel)

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

    local _mult = mult
    mult = tonumber(mult)

    if mult == nil then
        error("Invalid multiplier value: " .. tostring(_mult))
    end

    if mult < 1 then
        error("Multiplier can't be set under 1")
    end

    multipliers[src] = mult
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

-- COMMANDS

local function xpAddCommand(_, args, _)
    if args[1] == nil then
        print("Player ID not specified")
        return
    elseif args[2] == nil then
        print("Experience amount not specified")
        return
    end
    addXP(args[1], tonumber(args[2]))
end
RegisterCommand("xpadd", xpAddCommand, true)

local function xpRemoveCommand(_, args, _)
    if args[1] == nil then
        print("Player ID not specified")
        return
    elseif args[2] == nil then
        print("Experience amount not specified")
        return
    end
    removeXP(args[1], tonumber(args[2]))
end
RegisterCommand("xpremove", xpRemoveCommand, true)

local function xpInfoCommand(_, args, _)
    if args[1] == nil then
        print("No player id or identifier specified")
        return
    end

    local src = tonumber(args[1])

    if not src or src == nil then
        local xp = getXPFromLicense(args[1])
        print("Player " .. args[1] .. " has " .. tostring(xp) .. "XP (level " .. tostring(calculateLevelForXP(xp)) .. ")")
    else
        local xp = getXP(src)
        print("Player " .. GetPlayerName(src) .. " has " .. tostring(xp) .. "XP (level " .. tostring(calculateLevelForXP(xp)) .. ")")
    end
end
RegisterCommand("xpinfo", xpInfoCommand, true)

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

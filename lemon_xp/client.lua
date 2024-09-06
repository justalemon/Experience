local xp = 0
local level = 1

-- EVENTS

local function ready(newXP, newLevel)
    xp = newXP
    level = newLevel
end
RegisterNetEvent("lemon_xp:ready", ready)

local function updated(_, _, newXP, newLevel)
    xp = newXP
    level = newLevel
    print(newXP, newLevel)
end
RegisterNetEvent("lemon_xp:updated", updated)

-- INITIALIZATION

local function init()
    TriggerServerEvent("lemon_xp:ready")
end
Citizen.CreateThread(init)

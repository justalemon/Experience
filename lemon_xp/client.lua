local xp = 0
local level = 1

-- EVENTS

local function ready(newXP, newLevel)
    xp = newXP
    level = newLevel
end
RegisterNetEvent("lemon_xp:ready", ready)

-- INITIALIZATION

local function init()
    TriggerServerEvent("lemon_xp:ready")
end
Citizen.CreateThread(init)

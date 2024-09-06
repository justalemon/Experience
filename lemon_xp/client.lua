local function init()
    TriggerServerEvent("lemon_xp:clientReady")
end
Citizen.CreateThread(init)

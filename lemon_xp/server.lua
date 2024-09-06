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

local function init()
    if GetCurrentResourceName() ~= "lemon_xp" then
        print("ERROR! Experience script should be called lemon_xp, current name is " .. GetCurrentResourceName())
        StopResource(GetCurrentResourceName())
        return
    end
end
Citizen.CreateThread(init)

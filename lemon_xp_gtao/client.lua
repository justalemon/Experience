-- EVENTS

local function update(lower, upper, previous, current, level)
    while not HasHudScaleformLoaded(19) do
        RequestHudScaleform(19)
        Citizen.Wait(0)
    end

    BeginScaleformMovieMethodHudComponent(19, "SET_COLOUR")
    PushScaleformMovieFunctionParameterInt(116)
    EndScaleformMovieMethodReturn()

    BeginScaleformMovieMethodHudComponent(19, "SET_RANK_SCORES")
    PushScaleformMovieMethodParameterInt(lower)
    PushScaleformMovieMethodParameterInt(upper)
    PushScaleformMovieMethodParameterInt(previous)
    PushScaleformMovieMethodParameterInt(current)
    PushScaleformMovieMethodParameterInt(level)
    PushScaleformMovieMethodParameterInt(100)
    EndScaleformMovieMethodReturn()
end
RegisterNetEvent("lemon_xp_gtao:update", update)

-- INITIALIZATION

local function init()
    TriggerServerEvent("lemon_xp_gtao:ready")
end
Citizen.CreateThread(init)

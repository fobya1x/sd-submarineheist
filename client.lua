local SubmarineHeist = {
    ['started'] = false,
    ['finished'] = false,
    ['robber'] = false,
    ['ride'] = false,

    -- tables
    ['finish_peds'] = {},
    ['start_peds'] = {},
    ['guards_peds'] = {}
}

local function LoadModel(model)
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(0)
    end
end

local function Teleport(coords)
    DoScreenFadeOut(500)
    Wait(2000)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z - 1.0)
    DoScreenFadeIn(500)
end

local function Notify(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(0, 1)
end
local function SubTitle(text, time)
    BeginTextCommandPrint('STRING')
    AddTextComponentString(text)
    EndTextCommandPrint(time, true)
end
local function HelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, 50)
end
local function AddBlip(coords, sprite, colour, text)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, colour)
    SetBlipAsShortRange(blip, true)
    SetBlipScale(blip, 0.8)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function SpawnSubmarine()
    LoadModel(GetHashKey('kosatka'))
    submarine = CreateVehicle(GetHashKey('kosatka'), Config['spawn'], 180.0,
                              true, false)
    FreezeEntityPosition(submarine, true)
    SetModelAsNoLongerNeeded(GetHashKey('kosatka'))
end

local function SpawnGuards()
    local Ped = PlayerPedId()
    SetPedRelationshipGroupHash(Ped, GetHashKey('PLAYER'))
    AddRelationshipGroup("guards_group")
    for k, v in pairs(Config.Guards) do
        LoadModel(v.model)
        SubmarineHeist['guards_peds'][k] =
            CreatePed(4, GetHashKey(v.model), v.coords, true, true)
        GiveWeaponToPed(SubmarineHeist['guards_peds'][k], GetHashKey(v.weapon),
                        -1, true, true)
        SetPedRelationshipGroupHash(SubmarineHeist['guards_peds'][k],
                                    GetHashKey("guards_group"))
        SetRelationshipBetweenGroups(0, GetHashKey("guards_group"),
                                     GetHashKey("guards_group"))
        SetRelationshipBetweenGroups(5, GetHashKey("guards_group"),
                                     GetHashKey("PLAYER"))
        SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"),
                                     GetHashKey("guards_group"))
        SetPedArmour(SubmarineHeist['guards_peds'][k], 50)
        SetPedSeeingRange(SubmarineHeist['guards_peds'][k], 20.0)
        SetPedHearingRange(SubmarineHeist['guards_peds'][k], 100.0)
        SetPedCombatMovement(SubmarineHeist['guards_peds'][k], 3)
        TaskGuardCurrentPosition(SubmarineHeist['guards_peds'][k], 3.0, 3.0, 1)
        SetEntityAsMissionEntity(SubmarineHeist['guards_peds'][k])
        NetworkRegisterEntityAsNetworked(SubmarineHeist['guards_peds'][k])
        local NET_ID = NetworkGetNetworkIdFromEntity(
                           SubmarineHeist['guards_peds'][k])
        SetNetworkIdCanMigrate(NET_ID, true)
        SetNetworkIdExistsOnAllMachines(NET_ID, true)
    end
end

local function CheckPeds()
    for k, v in pairs(Config.Guards) do
        if IsEntityDead(SubmarineHeist['guards_peds'][k]) then
            return true
        else
            return false
        end
    end
end

local function StartHeist()
    TriggerServerEvent('sd-submarineheist:server:StartSync')
    Notify('~r~Submarine Heist Started')
    Notify('Go To The ~y~Yellow~s~ Point On The GPS')
    SpawnSubmarine()
    blip = AddBlip(Config['enter'], 1, 5, 'Submarine')
    SpawnGuards()
    SubmarineHeist['robber'] = true
end

local function FinishHeist()
    if not IsPedInAnyVehicle(PlayerPedId(), false) then 
        return 
    end
    TriggerServerEvent('sd-submarineheist:server:FinishSync')
    DeleteVehicle(submarine)
    TriggerServerEvent('sd-submarineheist:server:AddMoney', Config['reward'])
    Notify('~g~Submarine Heist Done')
    Notify('You Got ~g~' .. Config['reward'] .. '$')
    RemoveBlip(blip2)
end

local function EnterSubmarine()
    local Ped = PlayerPedId()

    if IsVehicleSeatFree(submarine, -1) then
        TaskWarpPedIntoVehicle(Ped, submarine, -1)
        return
    end
    if IsVehicleSeatFree(submarine, 0) then print(1) end
    if IsVehicleSeatFree(submarine, 0) then
        TaskWarpPedIntoVehicle(Ped, submarine, 0)
        return
    end

    if IsVehicleSeatFree(submarine, 1) then
        TaskWarpPedIntoVehicle(Ped, submarine, 1)
        return
    end
    if IsVehicleSeatFree(submarine, 2) then
        TaskWarpPedIntoVehicle(Ped, submarine, 2)
        return
    end

end

AddEventHandler('onResourceStop', function(rn)
    if rn == GetCurrentResourceName() then
        DeleteVehicle(submarine)
        RemoveBlip(blip)
        for k, v in pairs(Config.Guards) do
            DeleteEntity(SubmarineHeist['guards_peds'][k])
        end
    end
end)

RegisterNetEvent('sd-submarineheist:client:StartSync')
AddEventHandler('sd-submarineheist:client:StartSync', function()
    SubmarineHeist['started'] = not SubmarineHeist['started']
end)

RegisterNetEvent('sd-submarineheist:client:FinishSync')
AddEventHandler('sd-submarineheist:client:FinishSync',
                function() SubmarineHeist['finished'] = false end)

RegisterNetEvent('sd-submarineheist:client:ResetHeist')
AddEventHandler('sd-submarineheist:client:ResetHeist', function()
    SubmarineHeist = {
        ['started'] = false,
        ['finished'] = false,
        ['ride'] = false,
        ['robber'] = false,
        ['guards_peds'] = {}
    }
    DeleteVehicle(submarine)
    RemoveBlip(blip)
    RemoveBlip(blip2)
    for k, v in pairs(Config.Guards) do
        DeleteEntity(SubmarineHeist['guards_peds'][k])
    end
end)

CreateThread(function()
    while true do
        local sleep = 1500
        local Ped = PlayerPedId()
        local PedCo = GetEntityCoords(Ped)
        local SubCo = GetEntityCoords(submarine)

        local enter = #(PedCo - Config['enter'])
        local exit = #(PedCo - Config['exit'])
        local start = #(PedCo - Config.StartPeds[1].coords)
        local finish = #(PedCo - Config['finish'])
        local dist = #(PedCo - SubCo)

        if SubmarineHeist['started'] then
            if enter <= 1.5 and not SubmarineHeist['finished'] then
                sleep = 50
                HelpText('Press ~INPUT_PICKUP~ To Enter')
                if IsControlPressed(0, 38) then
                    Teleport(Config['exit'])
                    RemoveBlip(blip)
                end
            end
            if exit <= 1.5 then
                sleep = 50
                HelpText('Press ~INPUT_PICKUP~ To Exit')
                if IsControlPressed(0, 38) then
                    Teleport(Config['enter'])
                    if SubmarineHeist['robber'] and CheckPeds() then
                        SubmarineHeist['ride'] = true
                        SubmarineHeist['robber'] = false
                        SubmarineHeist['finished'] = true
                        Notify(
                            'Take The Submarine To The ~y~Yellow~s~ On tHe GPS')
                        FreezeEntityPosition(submarine, false)
                        blip2 = AddBlip(Config['finish'], 1, 5,
                                        'Finish Location')
                        TriggerServerEvent('sd-submarineheist:server:LockState',
                                           NetworkGetNetworkIdFromEntity(
                                               submarine), 1)
                    end
                end
            end

            if dist <= 100.0 and SubmarineHeist['finished'] and
                not IsPedInAnyVehicle(Ped, false) then
                sleep = 50
                HelpText('Press ~INPUT_PICKUP~ To Ride Submarine')
                if IsControlPressed(0, 38) then EnterSubmarine() end
            end

            if finish <= 50.0 and SubmarineHeist['finished'] then
                sleep = 50
                HelpText('Press ~INPUT_PICKUP~ To Finish')
                if IsControlPressed(0, 38) then FinishHeist() end
            end

        end

        if start <= 1.5 and not SubmarineHeist['started'] then
            sleep = 50
            HelpText('Press ~INPUT_PICKUP~ To Start The Submarine Heist')
            if IsControlPressed(0, 38) then StartHeist() end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    for k, v in pairs(Config.StartPeds) do
        LoadModel(v.model)
        SubmarineHeist['start_peds'][k] =
            CreatePed(4, GetHashKey(v.model), v.coords, v.heading, false, true)
        FreezeEntityPosition(SubmarineHeist['start_peds'][k], true)
        SetEntityInvincible(SubmarineHeist['start_peds'][k], true)
        SetBlockingOfNonTemporaryEvents(SubmarineHeist['start_peds'][k], true)
    end
end)


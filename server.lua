local Core;
if Config['framework'] == 'qb' then
    Core = exports['qb-core']:GetCoreObject()
elseif Config['framework'] == 'esx' then
    Core = exports['es_extended']:getSharedObject()
end

RegisterServerEvent('sd-submarineheist:server:AddAlert')
AddEventHandler('sd-submarineheist:server:AddAlert', function()
    local Players;
    if Config['framework'] == 'qb' then
        Players = Core.Functions.GetQBPlayers()
        for _, Players in pairs(Players) do
            if Players and Players.PlayerData.job.name == 'police' and Players.PlayerData.job.onduty then
                TriggerClientEvent('sd-submarineheist:client:AddBlip', Players.PlayerData.source)
            end
        end
    elseif Config['framework'] == 'esx' then
        Players = Core.GetExtendedPlayers('job', 'police')
        for _, Players in pairs(Players) do
        TriggerClientEvent('sd-submarineheist:client:AddBlip', Players.source)
        end
    end
end)

RegisterServerEvent('sd-submarineheist:server:AddMoney')
AddEventHandler('sd-submarineheist:server:AddMoney', function(amount)
    local Players;
    if Config['framework'] == 'qb' then
        Players = Core.Functions.GetPlayer(source)
        Player.Functions.AddMoney('cash', amount)
    elseif Config['framework'] == 'esx' then
        Players = Core.GetPlayerFromId(source)
        Player.addAccountMoney('cash', amount)
    end
end)

RegisterNetEvent('sd-submarineheist:server:LockState', function(vehNetId, state)
    SetVehicleDoorsLocked(NetworkGetEntityFromNetworkId(vehNetId), state)
end)

RegisterServerEvent('sd-submarineheist:server:FinishSync')
AddEventHandler('sd-submarineheist:server:FinishSync', function()
    TriggerClientEvent('sd-submarineheist:client:FinishSync', -1)
end)


RegisterServerEvent('sd-submarineheist:server:StartSync')
AddEventHandler('sd-submarineheist:server:StartSync', function()
    TriggerClientEvent('sd-submarineheist:client:StartSync', -1)
    Wait(60000 * 30)
    TriggerClientEvent('sd-submarineheist:client:ResetHeist', -1)
end)



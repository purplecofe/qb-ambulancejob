local PlayerJob = {}
local onDuty = false
local currentGarage = 0
local currentHospital

-- Functions

local function GetClosestPlayer()
    local closestPlayers = QBCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())

    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

function TakeOutVehicle(vehicleInfo)
    local coords = Config.Locations["vehicle"][currentGarage]
    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
        local veh = NetToVeh(netId)
        SetVehicleNumberPlateText(veh, Lang:t('info.amb_plate') .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, coords.w)
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        if Config.VehicleSettings[vehicleInfo] ~= nil then
            QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
        end
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
    end, vehicleInfo, coords, true)
end

function MenuGarage()
    local vehicleMenu = {
        {
            header = Lang:t('menu.amb_vehicles'),
            isMenuHeader = true
        }
    }

    local authorizedVehicles = Config.AuthorizedVehicles[QBCore.Functions.GetPlayerData().job.grade.level]
    for veh, label in pairs(authorizedVehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            header = label,
            txt = "",
            params = {
                event = "ambulance:client:TakeOutVehicle",
                args = {
                    vehicle = veh
                }
            }
        }
    end
    vehicleMenu[#vehicleMenu + 1] = {
        header = Lang:t('menu.close'),
        txt = "",
        params = {
            event = "qb-menu:client:closeMenu"
        }

    }
    exports['qb-menu']:openMenu(vehicleMenu)
end

-- Events

RegisterNetEvent('ambulance:client:TakeOutVehicle', function(data)
    local vehicle = data.vehicle
    TakeOutVehicle(vehicle)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    if PlayerJob.name == 'ambulance' then
        onDuty = PlayerJob.onduty
        if PlayerJob.onduty then
            TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
        else
            TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
        end
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)
    local ped = PlayerPedId()
    local player = PlayerId()
    CreateThread(function()
        Wait(5000)
        SetEntityMaxHealth(ped, 200)
        SetEntityHealth(ped, 200)
        SetPlayerHealthRechargeMultiplier(player, 0.0)
        SetPlayerHealthRechargeLimit(player, 0.0)
    end)
    CreateThread(function()
        Wait(1000)
        QBCore.Functions.GetPlayerData(function(PlayerData)
            PlayerJob = PlayerData.job
            onDuty = PlayerData.job.onduty
            SetPedArmour(PlayerPedId(), PlayerData.metadata["armor"])
            if (not PlayerData.metadata["inlaststand"] and PlayerData.metadata["isdead"]) then
                deathTime = Laststand.ReviveInterval
                OnDeath()
                DeathTimer()
            elseif (PlayerData.metadata["inlaststand"] and not PlayerData.metadata["isdead"]) then
                SetLaststand(true)
            else
                TriggerServerEvent("hospital:server:SetDeathStatus", false)
                TriggerServerEvent("hospital:server:SetLaststandStatus", false)
            end
            if PlayerJob.name == 'ambulance' and onDuty then
                TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
            end
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if PlayerJob.name == 'ambulance' and onDuty then
        TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
    end
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    if PlayerJob.name == 'ambulance' and duty ~= onDuty then
        if duty then
            TriggerServerEvent("hospital:server:AddDoctor", PlayerJob.name)
        else
            TriggerServerEvent("hospital:server:RemoveDoctor", PlayerJob.name)
        end
    end

    onDuty = duty
end)

function Status()
    if isStatusChecking then
        local statusMenu = {
            {
                header = Lang:t('menu.status'),
                isMenuHeader = true
            }
        }
        for _, v in pairs(statusChecks) do
            statusMenu[#statusMenu + 1] = {
                header = v.label,
                txt = "",
                params = {
                    event = "hospital:client:TreatWounds",
                }
            }
        end
        statusMenu[#statusMenu + 1] = {
            header = Lang:t('menu.close'),
            txt = "",
            params = {
                event = "qb-menu:client:closeMenu"
            }
        }
        exports['qb-menu']:openMenu(statusMenu)
    end
end

RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()
    if player ~= -1 and distance < 5.0 then
        local playerId = GetPlayerServerId(player)
        QBCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(result)
            if result then
                for k, v in pairs(result) do
                    if k ~= "BLEED" and k ~= "WEAPONWOUNDS" then
                        statusChecks[#statusChecks + 1] = { bone = Config.BoneIndexes[k],
                            label = v.label .. " (" .. Config.WoundStates[v.severity] .. ")" }
                    elseif result["WEAPONWOUNDS"] then
                        for _, v2 in pairs(result["WEAPONWOUNDS"]) do
                            QBCore.Functions.Notify(QBCore.Shared.Weapons[v2].damagereason, 'success')
                        end
                    elseif result["BLEED"] > 0 then
                        QBCore.Functions.Notify(Config.BleedingStates[v].label, 'success')
                    else
                        QBCore.Functions.Notify(Lang:t('success.healthy_player'), 'success')
                    end
                end
                isStatusChecking = true
                Status()
            end
        end, playerId)
    else
        QBCore.Functions.Notify(Lang:t('error.no_player'), 'error')
    end
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
            local player, distance = GetClosestPlayer()
            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)
                QBCore.Functions.Progressbar("hospital_revive", Lang:t('progress.revive'), 5000, false, true, {
                    disableMovement = false,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = healAnimDict,
                    anim = healAnim,
                    flags = 16,
                }, {}, {}, function() -- Done
                    StopAnimTask(PlayerPedId(), healAnimDict, "exit", 1.0)
                    QBCore.Functions.Notify(Lang:t('success.revived'), 'success')
                    TriggerServerEvent("hospital:server:RevivePlayer", playerId)
                end, function() -- Cancel
                    StopAnimTask(PlayerPedId(), healAnimDict, "exit", 1.0)
                    QBCore.Functions.Notify(Lang:t('error.canceled'), "error")
                end)
            else
                QBCore.Functions.Notify(Lang:t('error.no_player'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('error.no_firstaid'), "error")
        end
    end, 'firstaid')
end)

RegisterNetEvent('hospital:client:TreatWounds', function()
    if QBCore.Functions.HasItem('bandage') then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 5.0 then
            local playerId = GetPlayerServerId(player)
            QBCore.Functions.Progressbar("hospital_healwounds", Lang:t('progress.healing'), 5000, false, true, {
                disableMovement = false,
                disableCarMovement = false,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = healAnimDict,
                anim = healAnim,
                flags = 16,
            }, {}, {}, function() -- Done
                StopAnimTask(PlayerPedId(), healAnimDict, "exit", 1.0)
                QBCore.Functions.Notify(Lang:t('success.helped_player'), 'success')
                TriggerServerEvent("hospital:server:TreatWounds", playerId)
            end, function() -- Cancel
                StopAnimTask(PlayerPedId(), healAnimDict, "exit", 1.0)
                QBCore.Functions.Notify(Lang:t('error.canceled'), "error")
            end)
        else
            QBCore.Functions.Notify(Lang:t('error.no_player'), "error")
        end
    else
        QBCore.Functions.Notify(Lang:t('error.no_bandage'), "error")
    end
end)

local check = false

RegisterNetEvent('qb-ambulancejob:stash', function()
    if onDuty then
        TriggerServerEvent("inventory:server:OpenInventory", "stash",
            "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
        TriggerEvent("inventory:client:SetCurrentStash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
    else
        QBCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
    end
end)

RegisterNetEvent('qb-ambulancejob:armory', function()
    if onDuty then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", Config.Items)
    else
        QBCore.Functions.Notify(Lang:t('error.not_ems'), 'error')
    end
end)

local CheckVehicle = false
local function EMSVehicle(k)
    CheckVehicle = true
    CreateThread(function()
        while CheckVehicle do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                CheckVehicle = false
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(ped))
                else
                    local currentVehicle = k
                    MenuGarage(currentVehicle)
                    currentGarage = currentVehicle
                end
            end
            Wait(1)
        end
    end)
end

local CheckHeli = false
local function EMSHelicopter(k)
    CheckHeli = true
    CreateThread(function()
        while CheckHeli do
            if IsControlJustPressed(0, 38) then
                exports['qb-core']:KeyPressed(38)
                CheckHeli = false
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(ped))
                else
                    local currentHelictoper = k
                    local coords = Config.Locations["helicopter"][currentHelictoper]
                    QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
                        local veh = NetToVeh(netId)
                        SetVehicleNumberPlateText(veh, Lang:t('info.heli_plate') .. tostring(math.random(1000, 9999)))
                        SetEntityHeading(veh, coords.w)
                        SetVehicleLivery(veh, 1) -- Ambulance Livery
                        exports['LegacyFuel']:SetFuel(veh, 100.0)
                        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
                        SetVehicleEngineOn(veh, true, true)
                    end, Config.Helicopter, coords, true)
                end
            end
            Wait(1)
        end
    end)
end

RegisterNetEvent('EMSToggle:Duty', function()
    onDuty = not onDuty
    TriggerServerEvent("QBCore:ToggleDuty")
    TriggerServerEvent("police:server:UpdateBlips")
end)
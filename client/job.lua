local statusCheckPed = nil
local PlayerJob = {}
local onDuty = false
local currentGarage = 1
local inDuty = false
local inStash = false
local inArmory = false
local inVehicle = false
local inHeli = false
local onRoof = false
local inMain = false
local WeaponDamageList = {}

-- Functions
local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

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
    local garage = Config.Locations["vehicle"][currentGarage]
    QBCore.Functions.SpawnVehicle(vehicleInfo, function(veh)
        SetVehicleNumberPlateText(veh, Lang:t('info.amb_plate') .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, garage.coords.w)
        exports['ps-fuel']:SetFuel(veh, 100.0)
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        if Config.VehicleSettings[vehicleInfo] ~= nil then
            QBCore.Shared.SetDefaultVehicleExtras(veh, Config.VehicleSettings[vehicleInfo].extras)
        end
        local props = {}
        props.modEngine = 4 --引擎
        props.modBrakes = 2 --剎車
        props.modTransmission = 3 --變速器
        props.modHorns = 1 --喇叭
        props.modSuspension = 3 --懸吊
        props.modArmor = 4 --板金
        props.modTurbo = 1 --Turbo
        QBCore.Functions.SetVehicleProperties(veh, props)
        TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
        SetVehicleEngineOn(veh, true, true)
    end)
end

function MenuGarage()
    local vehicleMenu = {
        {
            header = Lang:t('menu.amb_vehicles'),
            isMenuHeader = true
        }
    }
    
    for veh, label in pairs(Config.AuthorizedVehicles) do
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

function MenuHeliGarage()
    local vehicleMenu = {
        {
            header = Lang:t('menu.amb_vehicles'),
            isMenuHeader = true
        }
    }
    
    for veh, label in pairs(Config.Helicopter) do
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

local function CheckPlayers(vehicle)
    for i = -1, 5, 1 do
        local seat = GetPedInVehicleSeat(vehicle, i)
        if seat then
            TaskLeaveVehicle(seat, vehicle, 0)
        end
    end
    SetVehicleDoorsLocked(vehicle)
    Wait(1500)
    QBCore.Functions.DeleteVehicle(vehicle)
end

-- Events
RegisterNetEvent('ambulance:client:TakeOutVehicle', function(data)
    local vehicle = data.vehicle
    TakeOutVehicle(vehicle)
end)

RegisterNetEvent('ambulance:client:OpenVehicleMenu', function()
    if PlayerJob.name == "ambulance" and onDuty then
        if inHeli then
            MenuHeliGarage()
        else
            MenuGarage()
        end
    end
end)

RegisterNetEvent('ambulance:client:StoreVehicle', function()
    if PlayerJob.name == "ambulance" then
        exports['ps-ui']:HideText()
        local ped = PlayerPedId()
        CheckPlayers(GetVehiclePedIsIn(ped))
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
    TriggerServerEvent("hospital:server:SetDoctor")
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports.spawnmanager:setAutoSpawn(false)
    local ped = PlayerPedId()
    local player = PlayerId()
    TriggerServerEvent("hospital:server:SetDoctor")
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
                SetLaststand(true, true)
            else
                TriggerServerEvent("hospital:server:SetDeathStatus", false)
                TriggerServerEvent("hospital:server:SetLaststandStatus", false)
            end
        end)
    end)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    onDuty = duty
    TriggerServerEvent("hospital:server:SetDoctor")
    TriggerServerEvent("police:server:UpdateBlips")
end)

local function CheckStatus(source)
    local bones = table.concat(statusChecks, "/")
    local weaponWounds = table.concat(WeaponDamageList, "/")
    local message = "部位：" .. bones .. " | " .. "可能傷勢：" .. weaponWounds
    if bones ~= "" and weaponWounds ~= "" then
        exports['okokChatV2']:Message("#db3c30", '', "fas fa-user-md", "傷勢評估", "", message, source)
    end
    statusChecks = {}
    WeaponDamageList = {}
end

RegisterNetEvent('hospital:client:CheckStatus', function()
    local player, distance = GetClosestPlayer()
    local source = QBCore.Functions.GetPlayerData().source
    if player ~= -1 and distance < 3.0 then
        local playerId = GetPlayerServerId(player)
        statusCheckPed = GetPlayerPed(player)
        QBCore.Functions.Progressbar('CheckStatus', Lang:t("progress.status"), 5000, false, true, {-- Name | Label | Time | useWhileDead | canCancel
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = 'amb@medic@standing@kneel@base',
            anim = 'base',
            flags = 1,
        }, {}, {}, function()-- Play When Done
            ClearPedTasks(PlayerPedId())
            QBCore.Functions.TriggerCallback('hospital:GetPlayerStatus', function(result)
                if result then
                    for k, v in pairs(result) do
                        if k ~= "BLEED" and k ~= "WEAPONWOUNDS" then
                            statusChecks[#statusChecks + 1] = v.label
                        elseif result["WEAPONWOUNDS"] then
                            for k, v in pairs(result["WEAPONWOUNDS"]) do
                                local damagereason = QBCore.Shared.Weapons[v].damagereason
                                WeaponDamageList[#WeaponDamageList + 1] = damagereason
                            end
                        elseif result["BLEED"] > 0 then
                            -- TODO: 出血狀態
                            else
                            QBCore.Functions.Notify(Lang:t('success.healthy_player'), 'success')
                        end
                    end
                    CheckStatus(source)
                end
            end, playerId)
        end, function()-- Play When Cancel
        --Stuff goes here
        end)
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
                isHealingPerson = true
                QBCore.Functions.Progressbar("hospital_revive", Lang:t('progress.revive'), 5000, false, true, {
                    disableMovement = false,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = healAnimDict,
                    anim = healAnim,
                    flags = 16,
                }, {}, {}, function()-- Done
                    isHealingPerson = false
                    StopAnimTask(PlayerPedId(), healAnimDict, "exit", 1.0)
                    QBCore.Functions.Notify(Lang:t('success.revived'), 'success')
                    TriggerServerEvent("hospital:server:RevivePlayer", playerId)
                end, function()-- Cancel
                    isHealingPerson = false
                    StopAnimTask(PlayerPedId(), healAnimDict, "exit", 1.0)
                    QBCore.Functions.Notify(Lang:t('error.cancled'), "error")
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
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
            local player, distance = GetClosestPlayer()
            if player ~= -1 and distance < 5.0 then
                local playerId = GetPlayerServerId(player)
                isHealingPerson = true
                QBCore.Functions.Progressbar("hospital_healwounds", Lang:t('progress.healing'), 5000, false, true, {
                    disableMovement = false,
                    disableCarMovement = false,
                    disableMouse = false,
                    disableCombat = true,
                }, {
                    animDict = healAnimDict,
                    anim = healAnim,
                    flags = 16,
                }, {}, {}, function()-- Done
                    isHealingPerson = false
                    StopAnimTask(PlayerPedId(), healAnimDict, "exit", 1.0)
                    QBCore.Functions.Notify(Lang:t('success.helped_player'), 'success')
                    TriggerServerEvent("hospital:server:TreatWounds", playerId)
                end, function()-- Cancel
                    isHealingPerson = false
                    StopAnimTask(PlayerPedId(), healAnimDict, "exit", 1.0)
                    QBCore.Functions.Notify(Lang:t('error.canceled'), "error")
                end)
            else
                QBCore.Functions.Notify(Lang:t('error.no_player'), "error")
            end
        else
            QBCore.Functions.Notify(Lang:t('error.no_bandage'), "error")
        end
    end, 'bandage')
end)

RegisterNetEvent('qb-ambulancejob:stash', function()
    if onDuty then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
        TriggerEvent("inventory:client:SetCurrentStash", "ambulancestash_" .. QBCore.Functions.GetPlayerData().citizenid)
    end
end)

-- Threads
CreateThread(function()
    while true do
        Wait(10)
        if isHealingPerson then
            local ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, healAnimDict, healAnim, 3) then
                loadAnimDict(healAnimDict)
                TaskPlayAnim(ped, healAnimDict, healAnim, 3.0, 3.0, -1, 49, 0, 0, 0, 0)
            end
        end
    end
end)
-- 個人置物櫃
CreateThread(function()
    for k, v in pairs(Config.Locations["stash"]) do
        exports['qb-target']:AddBoxZone("stash" .. k, vector3(v.x, v.y, v.z), 3.4, 0.2, {
            name = "stash" .. k,
            debugPoly = false,
            heading = 339,
            minZ = v.z - 1.5,
            maxZ = v.z + 1,
        }, {
            options = {
                {
                    type = "client",
                    event = "qb-clothing:client:openClothStore",
                    icon = "fa fa-hand",
                    label = "衣櫃",
                    job = "ambulance"
                },
                {
                    type = "client",
                    event = "qb-ambulancejob:stash",
                    icon = "fa fa-hand",
                    label = "置物櫃",
                    job = "ambulance"
                }
            },
            distance = 1.5
        })
    end
end)
-- 藥櫃
CreateThread(function()
    local armoryPoly = {}
    for k, v in pairs(Config.Locations["armory"]) do
        armoryPoly[#armoryPoly + 1] = BoxZone:Create(vector3(vector3(v.x, v.y, v.z)), 2.0, 1, {
            name = "armory" .. k,
            debugPoly = false,
            heading = 70,
            minZ = v.z - 1.5,
            maxZ = v.z + 1,
        })
    end
    
    local armoryCombo = ComboZone:Create(armoryPoly, {name = "armoryCombo", debugPoly = false})
    armoryCombo:onPlayerInOut(function(isPointInside)
        if isPointInside then
            inArmory = true
            if onDuty and PlayerJob.name == "ambulance" then
                exports['ps-ui']:DisplayText(Lang:t('text.armory_button'), 'primary')
            end
        else
            inArmory = false
            exports['ps-ui']:HideText()
        end
    end)
end)
CreateThread(function()
    while true do
        local sleep = 1000
        if inArmory then
            sleep = 5
            if IsControlJustReleased(0, 38) then
                exports['qb-core']:KeyPressed(38)
                TriggerServerEvent("inventory:server:OpenInventory", "shop", "hospital", Config.Items)
            end
        end
        Wait(sleep)
    end
end)
-- 領車
-- exports('GetInGarage', function()
--     return inVehicle
-- end)
-- CreateThread(function()
--     local vehiclePoly = {}
--     for k, v in pairs(Config.Locations["vehicle"]) do
--         vehiclePoly[#vehiclePoly + 1] = BoxZone:Create(vector3(v.coords.x, v.coords.y, v.coords.z), v.width, v.height, {
--             name = "vehicle" .. k,
--             debugPoly = false,
--             heading = v.coords.w,
--             minZ = v.coords.z - 2,
--             maxZ = v.coords.z + 2,
--             data = {
--                 index = k
--             }
--         })
--     end
    
--     local ped = PlayerPedId()
--     local vehicleCombo = ComboZone:Create(vehiclePoly, {name = "vehicleCombo", debugPoly = false})
--     vehicleCombo:onPlayerInOut(function(isPointInside, _, zone)
--         if isPointInside then
--             inVehicle = true
--             currentGarage = zone.data.index
--             if onDuty and PlayerJob.name == "ambulance" then
--                 if IsPedInAnyVehicle(ped, false) then
--                     exports['ps-ui']:DisplayText(Lang:t('text.veh_parking'), 'left')
--                 else
--                     exports['ps-ui']:DisplayText(Lang:t('text.veh_button'), 'left')
--                 end
--             end
--         else
--             currentGarage = nil
--             inVehicle = false
--             exports['ps-ui']:HideText()
--         end
--     end)
-- end)
-- -- 領直升機
-- CreateThread(function()
--     local helicopterPoly = {}
--     for k, v in pairs(Config.Locations["helicopter"]) do
--         helicopterPoly[#helicopterPoly + 1] = BoxZone:Create(vector3(v.coords.x, v.coords.y, v.coords.z), v.width, v.height, {
--             name = "helicopter" .. k,
--             debugPoly = false,
--             minZ = v.coords.z - 1,
--             maxZ = v.coords.z + 1,
--             heading = v.coords.w,
--             data = {
--                 index = k
--             }
--         })
--     end
    
--     local ped = PlayerPedId()
--     local helicopterCombo = ComboZone:Create(helicopterPoly, {name = "helicopterCombo", debugPoly = false})
--     helicopterCombo:onPlayerInOut(function(isPointInside, _, zone)
--         if isPointInside then
--             inVehicle = true
--             inHeli = true
--             currentGarage = zone.data.index
--             if onDuty and IsPedInAnyVehicle(ped, false) and PlayerJob.name == "ambulance" then
--                 exports['ps-ui']:DisplayText(Lang:t('text.veh_parking'), 'left')
--             else
--                 exports['ps-ui']:DisplayText(Lang:t('text.veh_button'), 'left')
--             end
--         else
--             currentGarage = nil
--             inVehicle = false
--             inHeli = false
--             exports['ps-ui']:HideText()
--         end
--     end)
-- end)
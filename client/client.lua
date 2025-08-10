local RSGCore = exports['rsg-core']:GetCoreObject()
local SpawnedProps = {}
local isBusy = false
local campingZones = {}
local campingZone
local inCampingZone = false
lib.locale()

---------------------------------------------
-- check to see if prop can be place here
---------------------------------------------
local function CanPlacePropHere(pos)
    local canPlace = true
    local ZoneTypeId = 1
    local x,y,z =  table.unpack(GetEntityCoords(cache.ped))
    local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, ZoneTypeId)
    if town ~= false then
        canPlace = false
    end
    for i = 1, #Config.PlayerProps do
        local checkprops = vector3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z)
        local dist = #(pos - checkprops)
        if dist < 1.3 then
            canPlace = false
        end
    end
    return canPlace
end

---------------------------------------------
-- update props
---------------------------------------------
RegisterNetEvent('rex-camping:client:updatePropData')
AddEventHandler('rex-camping:client:updatePropData', function(data)
    Config.PlayerProps = data
end)

---------------------------------------------
-- spawn props
---------------------------------------------
Citizen.CreateThread(function()
    while true do
        Wait(150)
        local pos = GetEntityCoords(cache.ped)
        local InRange = false
        for i = 1, #Config.PlayerProps do
            local prop = vector3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z)
            local dist = #(pos - prop)
            if dist >= 50.0 then goto continue end
            local hasSpawned = false
            InRange = true
            for z = 1, #SpawnedProps do
                local p = SpawnedProps[z]
                if p.propid == Config.PlayerProps[i].propid then
                    hasSpawned = true
                end
            end
            if hasSpawned then goto continue end
            local modelHash = joaat(Config.PlayerProps[i].propmodel)
            local data = {}
            if not HasModelLoaded(modelHash) then
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do
                    Wait(1)
                end
            end
            data.campsiteid = Config.PlayerProps[i].campsiteid
            data.propid = Config.PlayerProps[i].propid
            data.citizenid = Config.PlayerProps[i].citizenid
            data.obj = CreateObject(modelHash, Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z, false, false, false)
            SetEntityHeading(data.obj, Config.PlayerProps[i].h)
            SetEntityAsMissionEntity(data.obj, true)
            PlaceObjectOnGroundProperly(data.obj)
            Wait(1000)
            FreezeEntityPosition(data.obj, true)
            SetModelAsNoLongerNeeded(data.obj)

            ---------------------------------------
            -- start veg modifiy
            ---------------------------------------
            local veg_modifier_sphere = 0
            if veg_modifier_sphere == nil or veg_modifier_sphere == 0 then
                local veg_radius = 3.0
                local veg_Flags =  1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256
                local veg_ModType = 1
                
                veg_modifier_sphere = Citizen.InvokeNative(0xFA50F79257745E74, Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z, veg_radius, veg_ModType, veg_Flags, 0)
                
            else
                Citizen.InvokeNative(0x9CF1836C03FB67A2, Citizen.PointerValueIntInitialized(veg_modifier_sphere), 0)
                veg_modifier_sphere = 0
            end
            ---------------------------------------

            ---------------------------------------
            -- setup campsite zone
            ---------------------------------------
            campingZone = lib.zones.sphere({
                coords = vec3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z),
                radius = Config.CampingZoneSize,
                debug = false,
                onEnter = function()
                    inCampingZone = true
                    if Config.PlayerProps[i].item == 'campflag' then
                        campsitename = tostring(Config.PlayerProps[i].campsitename)
                        lib.showTextUI(campsitename)
                    end
                end,
                onExit = function()
                    inCampingZone = false
                    lib.hideTextUI()
                end
            })
            campingZones[#campingZones+1] = campingZone
            ---------------------------------------

            ---------------------------------------
            -- setup campsite (campflag) target
            ---------------------------------------
            if Config.PlayerProps[i].item == 'campflag' then
                local blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, data.obj)
                Citizen.InvokeNative(0x74F74D3207ED525C, blip, joaat(Config.Blip.blipSprite), true)
                Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.Blip.blipName)
                Citizen.InvokeNative(0xD38744167B2FA257, blip, Config.Blip.blipScale)
                Citizen.InvokeNative(0x662D364ABF16DE2F, blip, joaat(Config.Blip.blipColour))
                exports.ox_target:addLocalEntity(data.obj, {
                    {
                        name = 'campsite',
                        icon = 'far fa-eye',
                        label = locale('cl_lang_1'),
                        onSelect = function()
                            TriggerEvent('rex-camping:client:campsitemainmenu', data.campsiteid, data.citizenid )
                        end,
                        distance = 1.5
                    }
                })
            end
            ---------------------------------------

            ---------------------------------------
            -- setup camp tent target
            ---------------------------------------    
            if Config.PlayerProps[i].item == 'camptent' then
                exports.ox_target:addLocalEntity(data.obj, {
                    {
                        name = 'camptent',
                        icon = 'far fa-eye',
                        label = locale('cl_lang_2'),
                        onSelect = function()
                            TriggerEvent('rex-camping:client:openinventory', data.campsiteid, data.citizenid)
                        end,
                        distance = 3.0
                    }
                })
            end
            ---------------------------------------

            ---------------------------------------
            -- setup campfire target
            ---------------------------------------    
            if Config.PlayerProps[i].item == 'campfire' then
                exports.ox_target:addLocalEntity(data.obj, {
                    {
                        name = 'campfire',
                        icon = 'far fa-eye',
                        label = locale('cl_lang_3'),
                        onSelect = function()
                            TriggerEvent('rex-camping:client:cookingmainmenu', data.citizenid)
                        end,
                        distance = 1.5
                    }
                })
            end
            ---------------------------------------

            ---------------------------------------
            -- setup hitchingpost target
            ---------------------------------------    
            if Config.PlayerProps[i].item == 'hitchingpost' then
                exports.ox_target:addLocalEntity(data.obj, {
                    {
                        name = 'hitchingpost',
                        icon = 'far fa-eye',
                        label = locale('cl_lang_4'),
                        onSelect = function()
                            local data = { campsiteid = data.campsiteid, propid = data.propid, citizenid = data.citizenid }
                            TriggerEvent('rex-camping:client:removesingleprop', data)
                        end,
                        distance = 1.5
                    }
                })
            end
            ---------------------------------------

            ---------------------------------------
            -- setup torch target
            ---------------------------------------    
            if Config.PlayerProps[i].item == 'torch' then
                exports.ox_target:addLocalEntity(data.obj, {
                    {
                        name = 'torch',
                        icon = 'far fa-eye',
                        label = locale('cl_lang_5'),
                        onSelect = function()
                            local data = { campsiteid = data.campsiteid, propid = data.propid, citizenid = data.citizenid }
                            TriggerEvent('rex-camping:client:removesingleprop', data)
                        end,
                        distance = 1.5
                    }
                })
            end
            ---------------------------------------

            ---------------------------------------
            -- setup crafttable target
            ---------------------------------------    
            if Config.PlayerProps[i].item == 'crafttable' then
                exports.ox_target:addLocalEntity(data.obj, {
                    {
                        name = 'crafttable',
                        icon = 'far fa-eye',
                        label = locale('cl_lang_45'),
                        onSelect = function()
                            TriggerEvent('rex-camping:client:craftingmenu', data.citizenid)
                        end,
                        distance = 1.5
                    }
                })
            end
            ---------------------------------------

            SpawnedProps[#SpawnedProps + 1] = data
            hasSpawned = false
            ::continue::
        end
        if not InRange then
            Wait(5000)
        end
    end
end)

---------------------------------------------
-- campsite main menu
---------------------------------------------
RegisterNetEvent('rex-camping:client:campsitemainmenu', function(campsiteid, ownercid)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local citizenid = PlayerData.citizenid
    if citizenid == ownercid then
        lib.registerContext({
            id = 'campsite_menu',
            title = locale('cl_lang_6'),
            options = {
                {
                    title = locale('cl_lang_7'),
                    icon = 'fa-solid fa-screwdriver-wrench',
                    event = 'rex-camping:client:equipmentmenu',
                    args = { campsiteid = campsiteid },
                    arrow = true
                },
                {
                    title = locale('cl_lang_8'),
                    icon = 'fa-solid fa-boxes-packing',
                    event = 'rex-camping:client:confirmpackup',
                    description = locale('cl_lang_34'),
                    args = { campsiteid = campsiteid },
                    arrow = true
                },
            }
        })
        lib.showContext('campsite_menu')
    else
        lib.registerContext({
            id = 'camp_robmenu',
            title = locale('cl_lang_37'),
            options = {
                {
                    title = locale('cl_lang_38'),
                    icon = 'fa-solid fa-mask',
                    event = 'rex-camping:client:robcampsite',
                    args = { campsiteid = campsiteid, ownercid = ownercid },
                    arrow = true
                },
            }
        })
        lib.showContext('camp_robmenu')
    end
end)

---------------------------------------------
-- campsite : deploy equipment
---------------------------------------------
RegisterNetEvent('rex-camping:client:equipmentmenu', function(data)
    lib.registerContext({
        id = 'equipment_menu',
        title = locale('cl_lang_9'),
        menu = 'campsite_menu',
        options = {
            {
                title = locale('cl_lang_10'),
                icon = 'fa-solid fa-map-pin',
                event = 'rex-camping:client:createprop',
                args = { propmodel = Config.TentProp, item = 'camptent', campsiteid = data.campsiteid },
                arrow = true
            },
            {
                title = locale('cl_lang_11'),
                icon = 'fa-solid fa-map-pin',
                event = 'rex-camping:client:createprop',
                args = { propmodel = Config.FireProp, item = 'campfire', campsiteid = data.campsiteid },
                arrow = true
            },
            {
                title = locale('cl_lang_12'),
                icon = 'fa-solid fa-map-pin',
                event = 'rex-camping:client:createprop',
                args = { propmodel = Config.HitchPostProp, item = 'hitchingpost', campsiteid = data.campsiteid },
                arrow = true
            },
            {
                title = locale('cl_lang_13'),
                icon = 'fa-solid fa-map-pin',
                event = 'rex-camping:client:createprop',
                args = { propmodel = Config.TorchProp, item = 'torch', campsiteid = data.campsiteid },
                arrow = true
            },
            {
                title = locale('cl_lang_46'),
                icon = 'fa-solid fa-map-pin',
                event = 'rex-camping:client:createprop',
                args = { propmodel = Config.CraftTableProp, item = 'crafttable', campsiteid = data.campsiteid },
                arrow = true
            },
        }
    })
    lib.showContext('equipment_menu')
end)

---------------------------------------------
-- camp tent menu
---------------------------------------------
RegisterNetEvent('rex-camping:client:camptentmenu', function(campsiteid, propid, citizenid)
    lib.registerContext({
        id = 'camptent',
        title = locale('cl_lang_14'),
        options = {
            {
                title = locale('cl_lang_15'),
                icon = 'fa-solid fa-box-open',
                event = 'rex-camping:client:openinventory',
                args = { campsiteid = campsiteid, citizenid = citizenid },
                arrow = true
            },
            {
                title = locale('cl_lang_16'),
                description = locale('cl_lang_34'),
                icon = 'fa-solid fa-circle-xmark',
                event = 'rex-camping:client:removesingleprop',
                args = { campsiteid = campsiteid, propid = propid, citizenid = citizenid },
                arrow = true
            },
        }
    })
    lib.showContext('camptent')
end)

---------------------------------------------
-- campfire menu
---------------------------------------------
RegisterNetEvent('rex-camping:client:campfiremenu', function(campsiteid, propid, citizenid)
    lib.registerContext({
        id = 'campfire',
        title = locale('cl_lang_17'),
        options = {
            {
                title = locale('cl_lang_18'),
                icon = 'fa-solid fa-fire',
                event = 'rex-camping:client:cookingmenu',
                arrow = true
            },
            {
                title = locale('cl_lang_19'),
                icon = 'fa-solid fa-circle-xmark',
                event = 'rex-camping:client:removesingleprop',
                args = { campsiteid = campsiteid, propid = propid, citizenid = citizenid },
                arrow = true
            },
        }
    })
    lib.showContext('campfire')
end)

---------------------------------------------
-- setup new campsite
---------------------------------------------
RegisterNetEvent('rex-camping:client:setupcampzone')
AddEventHandler('rex-camping:client:setupcampzone', function(propmodel, item, coords, heading)
    RSGCore.Functions.TriggerCallback('rex-camping:server:countprop', function(result)
        -- distance check
        local playercoords = GetEntityCoords(cache.ped)
        if #(playercoords - coords) > Config.PlaceDistance then
            lib.notify({ title = locale('cl_lang_20'), description = locale('cl_lang_21'), type = 'error', duration = 5000 })
            return
        end
        -- check campsites
        if result >= Config.MaxCampsites then
            lib.notify({ title = locale('cl_lang_22'), description = locale('cl_lang_23'), type = 'error', duration = 7000 })
            return
        end
        -- check camping zone
        if inCampingZone then
            lib.notify({ title = locale('cl_lang_24'), description = locale('cl_lang_25'), type = 'error', duration = 7000 })
            return
        end
        -- check not in town and other props
        if not CanPlacePropHere(coords) then
            lib.notify({ title = locale('cl_lang_26'), description = locale('cl_lang_27'), type = 'error', duration = 7000 })
            return
        end
        if not IsPedInAnyVehicle(cache.ped, false) and not isBusy then
            isBusy = true
            LocalPlayer.state:set("inv_busy", true, true) -- lock inventory
            local anim1 = `WORLD_HUMAN_CROUCH_INSPECT`
            FreezeEntityPosition(cache.ped, true)
            TaskStartScenarioInPlace(cache.ped, anim1, 0, true)
            Wait(10000)
            ClearPedTasks(cache.ped)
            FreezeEntityPosition(cache.ped, false)
            TriggerServerEvent('rex-camping:server:createnewprop', propmodel, item, coords, heading)
            LocalPlayer.state:set("inv_busy", false, true) -- unlock inventory
            isBusy = false
            return
        end
    end, item)
end)

---------------------------------------------
-- setup campsite equipment
---------------------------------------------
RegisterNetEvent('rex-camping:client:placecampsiteitem')
AddEventHandler('rex-camping:client:placecampsiteitem', function(propmodel, item, campsiteid, coords, heading)
    RSGCore.Functions.TriggerCallback('rex-camping:server:countcampitems', function(result)
        -- check not in town and other props
        if not CanPlacePropHere(coords) then
            lib.notify({ title = locale('cl_lang_28'), type = 'error', duration = 7000 })
            return
        end
        -- check campsite max items
        if item == 'camptent' and result >= Config.MaxTent then
            lib.notify({ title = locale('cl_lang_29'), type = 'error', duration = 7000 })
            return
        end
        if item == 'campfire' and result >= Config.MaxFire then
            lib.notify({ title = locale('cl_lang_29'), type = 'error', duration = 7000 })
            return
        end
        if item == 'hitchingpost' and result >= Config.MaxHitchPost then
            lib.notify({ title = locale('cl_lang_29'), type = 'error', duration = 7000 })
            return
        end
        if item == 'torch' and result >= Config.MaxTorch then
            lib.notify({ title = locale('cl_lang_29'), type = 'error', duration = 7000 })
            return
        end
        if item == 'crafttable' and result >= Config.MaxCraftTable then
            lib.notify({ title = locale('cl_lang_29'), type = 'error', duration = 7000 })
            return
        end
        -- check campsites
        if not inCampingZone then
            lib.notify({ title = locale('cl_lang_30'), type = 'error', duration = 7000 })
            return
        end
        if not IsPedInAnyVehicle(cache.ped, false) and not isBusy then
            isBusy = true
            local anim1 = `WORLD_HUMAN_CROUCH_INSPECT`
            FreezeEntityPosition(cache.ped, true)
            TaskStartScenarioInPlace(cache.ped, anim1, 0, true)
            Wait(10000)
            ClearPedTasks(cache.ped)
            FreezeEntityPosition(cache.ped, false)
            TriggerServerEvent('rex-camping:server:createnewitem', propmodel, item, campsiteid, coords, heading)
            isBusy = false
            return
        end
    end, campsiteid, item)
end)

-----------------------
-- remove campsite item
-----------------------
RegisterNetEvent('rex-camping:client:removesingleprop')
AddEventHandler('rex-camping:client:removesingleprop', function(data)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local citizenid = PlayerData.citizenid
    if citizenid == data.citizenid then
        TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
        Wait(5000)
        for i = 1, #SpawnedProps do
            local prop = SpawnedProps[i]
            if prop.propid == data.propid then
                SetEntityAsMissionEntity(prop.obj, false)
                FreezeEntityPosition(prop.obj, false)
                DeleteObject(prop.obj)
            end
        end
        ClearPedTasks(cache.ped)
        TriggerServerEvent('rex-camping:server:removesingleprop', data.campsiteid, data.propid, data.citizenid)
    end
end)

---------------------------------------------
-- confirm campsite packup
---------------------------------------------
RegisterNetEvent('rex-camping:client:confirmpackup', function(data)
    local input = lib.inputDialog(locale('cl_lang_39'), {
        {
            label = locale('cl_lang_40'),
            description = locale('cl_lang_41'),
            type = 'select',
            options = {
                { value = 'yes', label = locale('cl_lang_42') },
                { value = 'no',  label = locale('cl_lang_43') }
            },
            required = true
        },
    })
        
    if not input then
        return
    end
    
    if input[1] == 'no' then
        return
    end

    LocalPlayer.state:set('inv_busy', true, true)
    lib.progressBar({
        duration = 10000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disableControl = true,
        disable = {
            move = true,
            mouse = false,
        },
        label = locale('cl_lang_44'),
    })
    LocalPlayer.state:set('inv_busy', false, true)
    TriggerEvent('rex-camping:client:packupcampsite', data)
    TriggerServerEvent('rex-camping:server:additem', 'campflag', 1)
end)

-----------------------
-- packup campsite
-----------------------
RegisterNetEvent('rex-camping:client:packupcampsite', function(data)
    for i = 1, #SpawnedProps do
        if SpawnedProps[i].campsiteid == data.campsiteid then
            local props = SpawnedProps[i].obj
            SetEntityAsMissionEntity(props, false)
            FreezeEntityPosition(props, false)
            DeleteObject(props)
            TriggerServerEvent('rex-camping:server:removecampsiteprops', data.campsiteid)
            campingZone:remove()
            lib.hideTextUI()
            inCampingZone = false
        end
    end
end)

---------------------------------------------
-- rob campsite
---------------------------------------------
RegisterNetEvent('rex-camping:client:robcampsite')
AddEventHandler('rex-camping:client:robcampsite', function(data)
    local hasItem = RSGCore.Functions.HasItem('lockpick', 1)
    if hasItem then
        local success = lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'hard'}, {'e'})
        if success == true then
            TriggerServerEvent('rex-camping:server:robcampsite', data.campsiteid)
        else
            lib.notify({ title = locale('cl_lang_35'), type = 'error', duration = 7000 })
            TriggerServerEvent('rex-camping:server:removeitem', 'lockpick', 1)
        end
    else
        lib.notify({ title = locale('cl_lang_36'), type = 'error', duration = 7000 })
    end
end)

---------------------------------------------
-- clean up
---------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for i = 1, #SpawnedProps do
        local props = SpawnedProps[i].obj
        SetEntityAsMissionEntity(props, false)
        FreezeEntityPosition(props, false)
        DeleteObject(props)
    end
end)

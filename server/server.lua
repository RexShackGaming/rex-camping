local RSGCore = exports['rsg-core']:GetCoreObject()
local PropsLoaded = false
lib.locale()

---------------------------------------------
-- increase xp fuction
---------------------------------------------
local function IncreasePlayerXP(source, xpGain, xpType)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player then
        local currentXP = Player.Functions.GetRep(xpType)
        local newXP = currentXP + xpGain
        Player.Functions.AddRep(xpType, newXP)
        TriggerClientEvent('ox_lib:notify', source, { title = string.format(locale('sv_lang_8'), xpGain, xpType), type = 'inform', duration = 7000 })
    end
end

---------------------------------------------
-- check player xp
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-camping:server:checkxp', function(source, cb, xptype)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player then
        local currentXP = Player.Functions.GetRep(xptype)
        cb(currentXP)
    end
end)

----------------------------
-- create campsite id
----------------------------
local function CreateCampsiteId()
    local UniqueFound = false
    local CampsiteId = nil
    while not UniqueFound do
        CampsiteId = 'CSID' .. math.random(11111111, 99999999)
        local query = "%" .. CampsiteId .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_camping WHERE campsiteid LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return CampsiteId
end

----------------------------
-- create prop id
----------------------------
local function CreatePropId()
    local UniqueFound = false
    local PropId = nil
    while not UniqueFound do
        PropId = 'PID' .. math.random(11111111, 99999999)
        local query = "%" .. PropId .. "%"
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_camping WHERE propid LIKE ?", { query })
        if result == 0 then
            UniqueFound = true
        end
    end
    return PropId
end

---------------------------------------------
-- use campflag items
---------------------------------------------
RSGCore.Functions.CreateUseableItem('campflag', function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local data = { propmodel = Config.FlagProp, item = 'campflag' }
    TriggerClientEvent('rex-camping:client:createprop', src, data)
end)

---------------------------------------------
-- get all prop data
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-camping:server:getallpropdata', function(source, cb, propid)
    MySQL.query('SELECT * FROM rex_camping WHERE propid = ?', {propid}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- count props
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-camping:server:countprop', function(source, cb, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_camping WHERE citizenid = ? AND item = ?", { citizenid, item })
    if result then
        cb(result)
    else
        cb(nil)
    end
end)

---------------------------------------------
-- count props
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-camping:server:countcampitems', function(source, cb, campsiteid, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_camping WHERE campsiteid = ? AND item = ?", { campsiteid, item })
    if result then
        cb(result)
    else
        cb(nil)
    end
end)

---------------------------------------------
-- update prop data
---------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)
        if PropsLoaded then
            TriggerClientEvent('rex-camping:client:updatePropData', -1, Config.PlayerProps)
        end
    end
end)

---------------------------------------------
-- get props
---------------------------------------------
CreateThread(function()
    TriggerEvent('rex-camping:server:getProps')
    PropsLoaded = true
end)

---------------------------------------------
-- create new campsite in database
---------------------------------------------
RegisterServerEvent('rex-camping:server:createnewprop')
AddEventHandler('rex-camping:server:createnewprop', function(propmodel, item, coords, heading)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local campsiteid = CreateCampsiteId()
    local propid = CreatePropId()
    local citizenid = Player.PlayerData.citizenid

    local PropData =
    {
        campsitename = 'Player Campsite',
        campsiteid = campsiteid,
        propid = propid,
        item = item,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = heading,
        propmodel = propmodel,
        citizenid = citizenid,
        buildttime = os.time()
    }

    local newpropdata = json.encode(PropData)

    -- add campsite to database
    MySQL.Async.execute('INSERT INTO rex_camping (campsiteid, propid, citizenid, item, propdata) VALUES (@campsiteid, @propid, @citizenid, @item, @propdata)', { 
        ['@campsiteid'] = campsiteid,
        ['@propid'] = propid,
        ['@citizenid'] = citizenid,
        ['@item'] = item,
        ['@propdata'] = newpropdata
    })

    table.insert(Config.PlayerProps, PropData)
    Player.Functions.RemoveItem('campflag', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['campflag'], 'remove', 1)
    TriggerEvent('rex-camping:server:updateProps')

end)

---------------------------------------------
-- create new campsite in database
---------------------------------------------
RegisterServerEvent('rex-camping:server:createnewitem')
AddEventHandler('rex-camping:server:createnewitem', function(propmodel, item, campsiteid, coords, heading)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local propid = CreatePropId()
    local citizenid = Player.PlayerData.citizenid

    local PropData =
    {
        campsitename = 'Player Campsite',
        campsiteid = campsiteid,
        propid = propid,
        item = item,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = heading,
        propmodel = propmodel,
        citizenid = citizenid,
        buildttime = os.time()
    }

    local newpropdata = json.encode(PropData)

    -- add campsite to database
    MySQL.Async.execute('INSERT INTO rex_camping (campsiteid, propid, citizenid, item, propdata) VALUES (@campsiteid, @propid, @citizenid, @item, @propdata)', { 
        ['@campsiteid'] = campsiteid,
        ['@propid'] = propid,
        ['@citizenid'] = citizenid,
        ['@item'] = item,
        ['@propdata'] = newpropdata
    })

    table.insert(Config.PlayerProps, PropData)
    TriggerEvent('rex-camping:server:updateProps')

end)

---------------------------------------------
-- update props
---------------------------------------------
RegisterServerEvent('rex-camping:server:updateProps')
AddEventHandler('rex-camping:server:updateProps', function()
    local src = source
    TriggerClientEvent('rex-camping:client:updatePropData', src, Config.PlayerProps)
end)

---------------------------------------------
-- remove single prop
---------------------------------------------
RegisterServerEvent('rex-camping:server:removesingleprop')
AddEventHandler('rex-camping:server:removesingleprop', function(campsiteid, propid, owner)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if citizenid == owner then
        local result = MySQL.query.await('SELECT * FROM rex_camping')
        if not result then return end
        for i = 1, #result do
            local propData = json.decode(result[i].propdata)
            if propData.propid == propid then
                MySQL.Async.execute('DELETE FROM rex_camping WHERE propid = @propid', { ['@propid'] = result[i].propid })
                for k, v in pairs(Config.PlayerProps) do
                    if v.propid == propid then
                        table.remove(Config.PlayerProps, k)
                    end
                end
            end
        end
        TriggerEvent('rex-camping:server:updateProps')
        TriggerClientEvent('rex-camping:client:updatePropData', -1, Config.PlayerProps)
    end
end)

---------------------------------------------
-- remove campsite props
---------------------------------------------
RegisterServerEvent('rex-camping:server:removecampsiteprops')
AddEventHandler('rex-camping:server:removecampsiteprops', function(campsiteid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local result = MySQL.query.await('SELECT * FROM rex_camping')
    if not result then return end
    for i = 1, #result do
        local propData = json.decode(result[i].propdata)
        if propData.campsiteid == campsiteid then
            MySQL.Async.execute('DELETE FROM rex_camping WHERE campsiteid = @campsiteid', { ['@campsiteid'] = result[i].campsiteid })
            for k, v in pairs(Config.PlayerProps) do
                if v.campsiteid == campsiteid then
                    table.remove(Config.PlayerProps, k)
                end
            end
        end
    end
    MySQL.Async.execute('DELETE FROM inventories WHERE identifier = @identifier', { ['@identifier'] = campsiteid })
    TriggerEvent('rex-camping:server:updateProps')
    TriggerClientEvent('rex-camping:client:updatePropData', -1, Config.PlayerProps)
end)

---------------------------------------------
-- get props
---------------------------------------------
RegisterServerEvent('rex-camping:server:getProps')
AddEventHandler('rex-camping:server:getProps', function()
    local result = MySQL.query.await('SELECT * FROM rex_camping')
    if not result[1] then return end
    for i = 1, #result do
        local propData = json.decode(result[i].propdata)
        if Config.LoadNotification then
            print(locale('sv_lang_1')..propData.item..locale('sv_lang_2')..propData.propid)
        end
        table.insert(Config.PlayerProps, propData)
    end
end)

---------------------------------------------
-- check player has the ingredients (crafting)
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-camping:server:craftingcheck', function(source, cb, ingredients)
    local src = source
    local icheck = 0
    local Player = RSGCore.Functions.GetPlayer(src)
    for k, v in pairs(ingredients) do
        if exports['rsg-inventory']:GetItemCount(src, v.item) >= v.amount then
            icheck = icheck + 1
            if icheck == #ingredients then
                cb(true)
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_9'), type = 'error', duration = 7000 })
            cb(false)
            return
        end
    end
end)

---------------------------------------------
-- check player has the ingredients (cooking)
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-camping:server:cookingcheck', function(source, cb, ingredients, makeamount)
    local src = source
    local icheck = 0
    local Player = RSGCore.Functions.GetPlayer(src)
    for k, v in pairs(ingredients) do
        if exports['rsg-inventory']:GetItemCount(src, v.item) >= v.amount * makeamount then
            icheck = icheck + 1
            if icheck == #ingredients then
                cb(true)
            end
        else
            TriggerClientEvent('ox_lib:notify', src, {title = locale('sv_lang_9'), type = 'error', duration = 7000 })
            cb(false)
            return
        end
    end
end)

-----------------------------------------------
-- finish cooking
-----------------------------------------------
RegisterServerEvent('rex-camping:server:finishcooking')
AddEventHandler('rex-camping:server:finishcooking', function(ingredients, receive, giveamount, makeamount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    -- remove ingredients
    for k, v in pairs(ingredients) do
        local requiredAmount = v.amount * makeamount
        Player.Functions.RemoveItem(v.item, requiredAmount)
    end
    -- add item
    Player.Functions.AddItem(receive, giveamount * makeamount)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[receive], 'add')
    TriggerEvent('rsg-log:server:CreateLog', 'cooking', locale('sv_lang_3'), 'green', firstname..' '..lastname..' ('..citizenid..locale('sv_lang_4')..RSGCore.Shared.Items[receive].label)
end)

---------------------------------------------
-- finish crafting / give item
---------------------------------------------
RegisterNetEvent('rex-camping:server:finishcrafting', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local receive = data.receive
    local giveamount = data.giveamount
    for k, v in pairs(data.ingredients) do
        Player.Functions.RemoveItem(v.item, v.amount)
    end
    Player.Functions.AddItem(receive, giveamount)
    Player.Functions.RemoveItem(data.bpc, 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[data.bpc], 'remove', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[receive], 'add', giveamount)
    IncreasePlayerXP(src, 1, 'crafting')
end)

---------------------------------------------
-- remove item
---------------------------------------------
RegisterServerEvent('rex-camping:server:removeitem')
AddEventHandler('rex-camping:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove', amount)
end)

---------------------------------------------
-- add item
---------------------------------------------
RegisterServerEvent('rex-camping:server:additem')
AddEventHandler('rex-camping:server:additem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.AddItem(item, amount)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'add', amount)
end)

---------------------------------------------
-- camping storage
---------------------------------------------
RegisterServerEvent('rex-camping:server:campsitestorage', function(campsiteid, owner)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    if owner == citizenid then
        local data = { label = 'Camping Storage : '..campsiteid, maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots }
        local stashName = campsiteid
        exports['rsg-inventory']:OpenInventory(src, stashName, data)
    end
end)

---------------------------------------------
-- rob player campsite
---------------------------------------------
RegisterNetEvent('rex-camping:server:robcampsite', function(campsiteid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local data = { label = 'Camping Storage : '..campsiteid, maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots }
    local stashName = campsiteid
    exports['rsg-inventory']:OpenInventory(src, stashName, data)
end)

---------------------------------------------
-- campsite cronjob
---------------------------------------------
lib.cron.new(Config.CampingCronJob, function ()
    if Config.CronNotification then
        print(locale('sv_lang_5'))
    end
end)

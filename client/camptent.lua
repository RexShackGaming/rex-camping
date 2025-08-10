local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- campsite storage
---------------------------------------------
RegisterNetEvent('rex-camping:client:openinventory', function(campsiteid, citizenid)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    -- private use
    local pcitizenid = PlayerData.citizenid
    if not Config.StoragePublicUse then
        if pcitizenid == citizenid then
            TriggerServerEvent('rex-camping:server:campsitestorage', campsiteid, citizenid)
        else
            lib.notify({ title = 'No for public use!', type = 'error', duration = 7000 })
        end
    end
end)

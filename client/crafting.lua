local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- crafting menu
---------------------------------------------
local CategoryMenus = {}

CreateThread(function()
    for _, v in ipairs(Config.CampingCrafting) do
        local IngredientsMetadata = {}
        local setheader = RSGCore.Shared.Items[tostring(v.receive)].label
        local itemimg = "nui://"..Config.Image..RSGCore.Shared.Items[tostring(v.receive)].image

        for i, ingredient in ipairs(v.ingredients) do
            table.insert(IngredientsMetadata, { label = RSGCore.Shared.Items[ingredient.item].label, value = ingredient.amount })
        end

        local option = {
            title = setheader,
            icon = itemimg,
            event = 'rex-camping:client:checkingredients',
            metadata = IngredientsMetadata,
            args = {
                title = setheader,
                category = v.category,
                ingredients = v.ingredients,
                crafttime = v.crafttime,
                craftingxp = v.craftingxp,
                bpc = v.bpc,
                receive = v.receive,
                giveamount = v.giveamount
            }
        }

        if not CategoryMenus[v.category] then
            CategoryMenus[v.category] = {
                id = 'crafting_menu_' .. v.category,
                title = v.category,
                menu = 'crafting_menu',
                onBack = function() end,
                options = { option }
            }
        else
            table.insert(CategoryMenus[v.category].options, option)
        end
    end
end)

CreateThread(function()
    for category, MenuData in pairs(CategoryMenus) do
        RegisterNetEvent('rex-camping:client:' .. category)
        AddEventHandler('rex-camping:client:' .. category, function()
            lib.registerContext(MenuData)
            lib.showContext(MenuData.id)
        end)
    end
end)

RegisterNetEvent('rex-camping:client:craftingmenu', function(citizenid)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local pcitizenid = PlayerData.citizenid
    if not Config.CraftingPublicUse then
        if citizenid == pcitizenid then
            local Menu = {
                id = 'crafting_menu',
                title = locale('cl_lang_51'),
                options = {}
            }

            for category, MenuData in pairs(CategoryMenus) do
                table.insert(Menu.options, {
                    title = category,
                    description = locale('cl_lang_52') .. category,
                    event = 'rex-camping:client:' .. category,
                    arrow = true
                })
            end

            lib.registerContext(Menu)
            lib.showContext(Menu.id)
        else
            lib.notify({ title = locale('cl_lang_56'), type = 'error', duration = 7000 })
        end
    else
        local Menu = {
            id = 'crafting_menu',
            title = locale('cl_lang_51'),
            options = {}
        }

        for category, MenuData in pairs(CategoryMenus) do
            table.insert(Menu.options, {
                title = category,
                description = locale('cl_lang_52') .. category,
                event = 'rex-camping:client:' .. category,
                arrow = true
            })
        end

        lib.registerContext(Menu)
        lib.showContext(Menu.id)
    end
end)

---------------------------------------------
-- craft item
---------------------------------------------
RegisterNetEvent('rex-camping:client:checkingredients', function(data)
    local hasItem = RSGCore.Functions.HasItem(data.bpc, 1)
    if hasItem then
        -- check crafting rep
        RSGCore.Functions.TriggerCallback('rex-camping:server:checkxp', function(currentXP)
            if currentXP >= data.craftingxp then
                -- check crafting items
                RSGCore.Functions.TriggerCallback('rex-camping:server:craftingcheck', function(hasRequired)
                    if hasRequired == true then
                        LocalPlayer.state:set("inv_busy", true, true) -- lock inventory
                        lib.progressBar({
                            duration = tonumber(data.crafttime),
                            position = 'bottom',
                            useWhileDead = false,
                            canCancel = false,
                            disableControl = true,
                            disable = {
                                move = true,
                                mouse = true,
                            },
                            anim = {
                                dict = 'mech_inventory@crafting@fallbacks',
                                clip = 'full_craft_and_stow',
                                flag = 27,
                            },
                            label = locale('cl_lang_55').. RSGCore.Shared.Items[data.receive].label,
                        })
                        TriggerServerEvent('rex-camping:server:finishcrafting', data)
                        LocalPlayer.state:set("inv_busy", false, true) -- unlock inventory
                    else
                        lib.notify({ title = locale('cl_lang_57'), type = 'inform', duration = 7000 })
                    end
                end, data.ingredients)
            else
                lib.notify({ title = locale('cl_lang_58'), type = 'error', duration = 7000 })
            end
        end, 'crafting')
    else
        lib.notify({ title = RSGCore.Shared.Items[data.bpc].label..locale('cl_lang_59'), type = 'error', duration = 7000 })
    end
end)

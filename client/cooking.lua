local RSGCore = exports['rsg-core']:GetCoreObject()
local categoryMenus = {}
lib.locale()

---------------------------------------------
-- iterate through recipes and organize them by category
---------------------------------------------
for _, v in ipairs(Config.CookingRecipes) do
    local ingredientsMetadata = {}
    local setheader = RSGCore.Shared.Items[tostring(v.receive)].label
    local itemimg = "nui://"..Config.Image..RSGCore.Shared.Items[tostring(v.receive)].image
    for i, ingredient in ipairs(v.ingredients) do
        table.insert(ingredientsMetadata, { label = RSGCore.Shared.Items[ingredient.item].label, value = ingredient.amount })
    end
    local option = {
        title = setheader,
        icon = itemimg,
        event = 'rex-camping:client:cookingingredients',
        metadata = ingredientsMetadata,
        args = {
            title = setheader,
            ingredients = v.ingredients,
            maketime = v.maketime,
            receive = v.receive,
            giveamount = v.giveamount
        }
    }

    if not categoryMenus[v.category] then
        categoryMenus[v.category] = {
            id = 'cooking_menu_' .. v.category,
            title = v.category,
            menu = 'cooking_main_menu',
            onBack = function() end,
            options = { option }
        }
    else
        table.insert(categoryMenus[v.category].options, option)
    end
end

---------------------------------------------
-- log menu events by category
---------------------------------------------
for category, menuData in pairs(categoryMenus) do
    RegisterNetEvent('rex-camping:client:' .. category)
    AddEventHandler('rex-camping:client:' .. category, function()
        lib.registerContext(menuData)
        lib.showContext(menuData.id)
    end)
end

---------------------------------------------
-- main event to open main menu
---------------------------------------------
RegisterNetEvent('rex-camping:client:cookingmainmenu')
AddEventHandler('rex-camping:client:cookingmainmenu', function(citizenid)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    -- private use
    local pcitizenid = PlayerData.citizenid
    if not Config.CookingPublicUse then
        if pcitizenid == citizenid then
            local mainMenu = {
                id = 'cooking_main_menu',
                title = locale('cl_lang_18'),
                options = {}
            }

            for category, menuData in pairs(categoryMenus) do
                table.insert(mainMenu.options, {
                    title = category,
                    description = locale('cl_lang_47') .. category,
                    icon = 'fa-solid fa-kitchen-set',
                    event = 'rex-camping:client:' .. category,
                    arrow = true
                })
            end

            lib.registerContext(mainMenu)
            lib.showContext(mainMenu.id)
        else
            lib.notify({ title = 'No for public use!', type = 'error', duration = 7000 })
        end
    else
        -- public use
        local mainMenu = {
            id = 'cooking_main_menu',
            title = locale('cl_lang_18'),
            options = {}
        }

        for category, menuData in pairs(categoryMenus) do
            table.insert(mainMenu.options, {
                title = category,
                description = locale('cl_lang_47') .. category,
                icon = 'fa-solid fa-kitchen-set',
                event = 'rex-camping:client:' .. category,
                arrow = true
            })
        end

        lib.registerContext(mainMenu)
        lib.showContext(mainMenu.id)
    end
end)

---------------------------------------------
-- check player has the ingredients
---------------------------------------------
RegisterNetEvent('rex-camping:client:cookingingredients', function(data)
    local input = lib.inputDialog(locale('cl_lang_48'), {
        { 
            type = 'input',
            label = locale('cl_lang_49'),
            required = true,
            min = 1, max = 10 
        },
    })

    if not input then return end

    local makeamount = tonumber(input[1])

    if makeamount then
        RSGCore.Functions.TriggerCallback('rex-camping:server:cookingcheck', function(hasRequired)
            if (hasRequired) then
                TriggerEvent('rex-camping:client:docooking', data.title, data.ingredients, tonumber(data.maketime * makeamount), data.receive, data.giveamount,  makeamount)
            else
                return
            end
        end, data.ingredients, makeamount)
    end

end)

---------------------------------------------
-- do some cooking
---------------------------------------------
RegisterNetEvent('rex-camping:client:docooking', function(title, ingredients, maketime, receive, giveamount, makeamount)
    LocalPlayer.state:set("inv_busy", true, true) -- lock inventory
    lib.progressBar({
        duration = maketime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disableControl = true,
        disable = {
            move = true,
            mouse = false,
        },
        label = locale('cl_lang_50') .. title,
        anim = {
            dict = 'mech_inventory@crafting@fallbacks',
            clip = 'full_craft_and_stow',
            flag = 27,
        },
    })
    TriggerServerEvent('rex-camping:server:finishcooking', ingredients, receive, giveamount, makeamount)
    LocalPlayer.state:set("inv_busy", false, true) -- unlock inventory
end)

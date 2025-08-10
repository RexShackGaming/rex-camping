Config = Config or {}
Config.PlayerProps = {}

---------------------------------------------
-- settings
---------------------------------------------
Config.Image             = 'rsg-inventory/html/images/'
Config.CampingZoneSize   = 50.0
Config.StorageMaxWeight  = 2000000
Config.StorageMaxSlots   = 20
Config.CampingCronJob    = '0 * * * *' -- https://crontab.guru/#0_*_*_*_*
Config.CronNotification  = false
Config.LoadNotification  = false
Config.StoragePublicUse  = false -- allow others to use storage in campsites
Config.CraftingPublicUse = false -- allow others to use crafting in campsites
Config.CookingPublicUse  = false -- allow others to use cooking in campsites

---------------------------------
-- deploy settings
---------------------------------
Config.PromptGroupName   = 'Place Campsite'
Config.PromptCancelName  = 'Cancel'
Config.PromptPlaceName   = 'Set'
Config.PromptRotateLeft  = 'Rotate Left'
Config.PromptRotateRight = 'Rotate Right'
Config.PlaceDistance     = 5.0

---------------------------------------------
-- props / max props
---------------------------------------------
Config.FlagProp       = 'p_skullpost02x'
Config.TentProp       = 'mp005_s_posse_tent_bountyhunter07x'
Config.FireProp       = 'p_campfirecombined01x'
Config.HitchPostProp  = 'p_hitchingpost01x'
Config.TorchProp      = 'p_torchpost01x'
Config.CraftTableProp = 'mp005_s_posse_ammotable03x'
---------------------------------------------
Config.MaxCampsites  = 1
Config.MaxFire       = 1
Config.MaxTent       = 1
Config.MaxHitchPost  = 2
Config.MaxTorch      = 6
Config.MaxCraftTable = 1
---------------------------------------------

---------------------------------------------
-- blip settings
---------------------------------------------
Config.Blip = {
    blipName = 'Campsite',
    blipSprite = 'blip_camp_tent',
    blipScale = 0.2,
    blipColour = 'BLIP_MODIFIER_MP_COLOR_6'
}

---------------------------------
-- cooking crafting
---------------------------------
Config.CookingRecipes = {
    {
        category = 'Fish',
        maketime = 10000,
        ingredients = {
            [1] = { item = 'raw_fish', amount = 1 },
        },
        receive = 'cooked_fish',
        giveamount = 1
    },
    {
        category = 'Meat',
        maketime = 10000,
        ingredients = {
            [1] = { item = 'raw_meat', amount = 1 },
        },
        receive = 'cooked_meat',
        giveamount = 1
    },
    -- add more as required
}

---------------------------------
-- camping crafting
---------------------------------
Config.CampingCrafting = {

    {
        category = 'Tools',
        crafttime = 30000,
        craftingxp = 0,
        bpc = 'bpc_pickaxe',
        ingredients = { 
            [1] = { item = 'coal',      amount = 1 },
            [2] = { item = 'steel_bar', amount = 1 },
            [3] = { item = 'wood',      amount = 2 },
        },
        receive = 'pickaxe',
        giveamount = 1
    },

}

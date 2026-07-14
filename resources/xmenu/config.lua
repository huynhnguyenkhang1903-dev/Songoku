Config = {}

-- Menu Settings
Config.MenuKey = 57 -- F10 key
Config.Command = "xmenu"
Config.AnimationDuration = 300 -- ms

-- NPC Spawn Settings
Config.MaxNPCs = 100
Config.DefaultNPCCount = 5
Config.SpawnDistance = 1.0 -- meters between NPCs
Config.PushPlayerDistance = 2.0 -- meters to push player away
Config.SpawnDirection = "horizontal" -- "horizontal" (ngang) or "vertical" (doc)

-- NPC Default Settings
Config.DefaultHealth = 200
Config.DefaultArmor = 0
Config.DefaultInvincible = false

-- Scenarios (GTA V scenarios)
Config.Scenarios = {
    -- Standing
    "WORLD_HUMAN_STAND_IMPATIENT",
    "WORLD_HUMAN_STAND_MOBILE",
    "WORLD_HUMAN_STAND_FISHING",
    "WORLD_HUMAN_STAND_FIRE",
    -- Walking
    "WORLD_HUMAN_JOG_STANDING",
    "WORLD_HUMAN_WALK_FEMALE",
    "WORLD_HUMAN_WALK_MOBILE",
    -- Sitting
    "WORLD_HUMAN_SEAT_LEDGE",
    "WORLD_HUMAN_SEAT_STEPS",
    "WORLD_HUMAN_SEAT_WALL",
    -- World interactions
    "WORLD_HUMAN_SMOKING",
    "WORLD_HUMAN_DRINKING",
    "WORLD_HUMAN_BINOCULARS",
    "WORLD_HUMAN_CHEERING",
    "WORLD_HUMAN_PARTYING",
    "WORLD_HUMAN_MUSICIAN",
    "WORLD_HUMAN_HUGGING",
    "WORLD_HUMAN_LEANING",
    "WORLD_HUMAN_HANG_OUT_STREET",
    "WORLD_HUMAN_WINDOW_SHOP_BROWSE",
    "WORLD_HUMAN_PICNIC",
    "WORLD_HUMAN_STUPOR",
    "WORLD_HUMAN_BUM_FREEWAY",
    "WORLD_HUMAN_BUM_SLUMPED",
    "WORLD_HUMAN_BUM_STANDING",
    "WORLD_HUMAN_GARDENER_PLANT",
    "WORLD_HUMAN_GARDENER_LEAF_BLOWING",
    "WORLD_HUMAN_GARDENER_TRIMMING",
    "WORLD_HUMAN_SECURITY_SHOULDER",
    "WORLD_HUMAN_SECURITY_GUARD",
    "WORLD_HUMAN_CLIPBOARD",
    "WORLD_HUMAN_HUMAN_STATUE",
    "WORLD_HUMAN_YOGA",
    "WORLD_HUMAN_STRIP_WATCH_STAND",
    "PROP_HUMAN_BUM_SHOPPING_CART",
    "PROP_HUMAN_BBQ",
    "PROP_HUMAN_ABSEIL",
    "PROP_HUMAN_MUSCLE_FLEX",
    "PROP_HUMAN_MUSCLE_FREE_WEIGHTS",
    "PROP_HUMAN_MUSCLE_CHIN_UPS",
    "PROP_HUMAN_MUSCLE_PUSH_UPS",
    "PROP_HUMAN_STAND_IMPATIENT",
    "PROP_HUMAN_ATM",
    "PROP_HUMAN_SEAT_ARMCHAIR",
    "PROP_HUMAN_SEAT_BAR",
    "PROP_HUMAN_SEAT_BENCH",
    "PROP_HUMAN_SEAT_DECKCHAIR",
    "PROP_HUMAN_SEAT_MUSCLE_BENCH",
    "PROP_HUMAN_SEAT_MUSCLE_BENCH_PRESS",
    "PROP_HUMAN_SEAT_CHAIR",
    "PROP_HUMAN_SEAT_CHAIR_UPRIGHT",
    "PROP_HUMAN_SEAT_CHAIR_MP_PLAYER",
    "PROP_HUMAN_SEAT_DECKCHAIR_PLAYER",
    "PROP_HUMAN_SEAT_SOFA",
    "PROP_HUMAN_SEAT_STRIP_WATCH",
    "PROP_HUMAN_STAND_IMPATIENT_UPRIGHT",
    "PROP_HUMAN_STAND_IMPATIENT_FACILITY",
    "PROP_HUMAN_STAND_MOBILE_FACILITY",
    "PROP_HUMAN_STAND_MOBILE_UPRIGHT",
    "PROP_HUMAN_STAND_MOBILE_PHONE",
    "PROP_HUMAN_STAND_MOBILE_UPRIGHT_FACILITY",
}

-- Props (NPC can hold)
Config.Props = {
    {name = "Coffee Cup", model = "p_amb_coffeecup_01"},
    {name = "Phone", model = "prop_cs_phone_01"},
    {name = "Beer", model = "prop_beer_log_01"},
    {name = "Wine Glass", model = "prop_wine_glass_01"},
    {name = "Cigarette", model = "prop_cs_ciggy_01"},
    {name = "Briefcase", model = "prop_cs_briefcase_01"},
    {name = "Suitcase", model = "prop_suitcase_01"},
    {name = "Shopping Bag", model = "prop_shopping_bag_01"},
    {name = "Guitar", model = "prop_el_guitar_01"},
    {name = "Microphone", model = "p_ing_microphonel_01"},
}

-- Facial Expressions
Config.Expressions = {
    {name = "Normal", mood = "mood_normal"},
    {name = "Happy", mood = "mood_happy"},
    {name = "Angry", mood = "mood_angry"},
    {name = "Sad", mood = "mood_sad"},
    {name = "Stressed", mood = "mood_stressed"},
    {name = "Dead", mood = "mood_dead"},
    {name = "Injured", mood = "mood_injured"},
}

-- Weapons (All GTA V weapons)
Config.Weapons = {
    -- Melee
    "WEAPON_DAGGER",
    "WEAPON_BAT",
    "WEAPON_BOTTLE",
    "WEAPON_CROWBAR",
    "WEAPON_UNARMED",
    "WEAPON_FLASHLIGHT",
    "WEAPON_GOLFCLUB",
    "WEAPON_HAMMER",
    "WEAPON_HATCHET",
    "WEAPON_KNUCKLE",
    "WEAPON_KNIFE",
    "WEAPON_MACHETE",
    "WEAPON_SWITCHBLADE",
    "WEAPON_NIGHTSTICK",
    "WEAPON_WRENCH",
    "WEAPON_BATTLEAXE",
    "WEAPON_POOLCUE",
    "WEAPON_STONE_HATCHET",
    -- Pistols
    "WEAPON_PISTOL",
    "WEAPON_PISTOL_MK2",
    "WEAPON_COMBATPISTOL",
    "WEAPON_APPISTOL",
    "WEAPON_PISTOL50",
    "WEAPON_SNSPISTOL",
    "WEAPON_SNSPISTOL_MK2",
    "WEAPON_HEAVYPISTOL",
    "WEAPON_VINTAGEPISTOL",
    "WEAPON_FLAREGUN",
    "WEAPON_MARKSMANPISTOL",
    "WEAPON_REVOLVER",
    "WEAPON_REVOLVER_MK2",
    "WEAPON_DOUBLEACTION",
    "WEAPON_NAVYREVOLVER",
    "WEAPON_GADGETPISTOL",
    -- SMGs
    "WEAPON_MICROSMG",
    "WEAPON_SMG",
    "WEAPON_SMG_MK2",
    "WEAPON_ASSAULTSMG",
    "WEAPON_COMBATPDW",
    "WEAPON_MACHINEPISTOL",
    "WEAPON_MINISMG",
    -- Rifles
    "WEAPON_ASSAULTRIFLE",
    "WEAPON_ASSAULTRIFLE_MK2",
    "WEAPON_CARBINERIFLE",
    "WEAPON_CARBINERIFLE_MK2",
    "WEAPON_ADVANCEDRIFLE",
    "WEAPON_SPECIALCARBINE",
    "WEAPON_SPECIALCARBINE_MK2",
    "WEAPON_BULLPUPRIFLE",
    "WEAPON_BULLPUPRIFLE_MK2",
    "WEAPON_COMPACTRIFLE",
    -- Shotguns
    "WEAPON_PUMPSHOTGUN",
    "WEAPON_PUMPSHOTGUN_MK2",
    "WEAPON_SAWNOFFSHOTGUN",
    "WEAPON_ASSAULTSHOTGUN",
    "WEAPON_BULLPUPSHOTGUN",
    "WEAPON_MUSKET",
    "WEAPON_HEAVYSHOTGUN",
    "WEAPON_DBSHOTGUN",
    "WEAPON_AUTOSHOTGUN",
    "WEAPON_COMBATSHOTGUN",
    -- Snipers
    "WEAPON_SNIPERRIFLE",
    "WEAPON_HEAVYSNIPER",
    "WEAPON_MARKSMANRIFLE",
    "WEAPON_MARKSMANRIFLE_MK2",
    -- Heavy
    "WEAPON_GRENADELAUNCHER",
    "WEAPON_RPG",
    "WEAPON_MINIGUN",
    "WEAPON_FIREWORK",
    "WEAPON_RAILGUN",
    "WEAPON_HOMINGLAUNCHER",
    "WEAPON_COMPACTLAUNCHER",
    -- Throwables
    "WEAPON_GRENADE",
    "WEAPON_STICKYBOMB",
    "WEAPON_PROXIMITYMINE",
    "WEAPON_BZGAS",
    "WEAPON_SMOKEGRENADE",
    "WEAPON_MOLOTOV",
    "WEAPON_PIPEBOMB",
    "WEAPON_BALL",
    "WEAPON_FLARE",
    -- Misc
    "WEAPON_STUNGUN",
    "WEAPON_FIREEXTINGUISHER",
    "WEAPON_PETROLCAN",
    "WEAPON_HAZARDCAN",
    "WEAPON_SNIPER",
}

Config.WeaponSkins = {
    ["WEAPON_CARBINERIFLE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Trung Thu", component = "COMPONENT_CARBINERIFLE_TRUNGTHU" },
        { name = "Rồng Đỏ", component = "COMPONENT_CARBINERIFLE_DRAGONR" },
        { name = "Rồng Xanh", component = "COMPONENT_CARBINERIFLE_DRAGONG" },
        { name = "Rồng Bạc", component = "COMPONENT_CARBINERIFLE_DRAGONS" },
        { name = "Phượng Hoàng Băng", component = "COMPONENT_CARBINERIFLE_RPV_FZEB" },
        { name = "Griffin", component = "COMPONENT_CARBINERIFLE_RPV_GIFFIN" },
        { name = "Hỏa Long", component = "COMPONENT_CARBINERIFLE_RPV_HEFIRE" },
        { name = "Howl", component = "COMPONENT_CARBINERIFLE_RPV_HOWL" },
        { name = "Camo Hổ", component = "COMPONENT_CARBINERIFLE_RPV_TCAMO" },
        { name = "Monster Hunter", component = "COMPONENT_CARBINERIFLE_RPV_MHUNTE" },
        { name = "Raza", component = "COMPONENT_CARBINERIFLE_RPV_RHAZA" },
        { name = "Cali", component = "COMPONENT_CARBINERIFLE_RPV_TCALI" }
    },
    ["WEAPON_ASSAULTRIFLE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Rồng Lửa", component = "COMPONENT_ASSAULTRIFLE_RPV_DRAGON" },
        { name = "Bạc", component = "COMPONENT_ASSAULTRIFLE_RPV_SILVER" },
        { name = "Lan", component = "COMPONENT_ASSAULTRIFLE_RPV_LAN" },
        { name = "Lá Cây", component = "COMPONENT_ASSAULTRIFLE_RPV_GREEN" },
        { name = "Cá Mập", component = "COMPONENT_ASSAULTRIFLE_RPV_SHARK" },
        { name = "Pool Party", component = "COMPONENT_ASSAULTRIFLE_POOLPARTY" },
        { name = "FSER", component = "COMPONENT_ASSAULTRIFLE_RPV_FSER" },
        { name = "Misty", component = "COMPONENT_ASSAULTRIFLE_RPV_FMISTY" },
        { name = "Inject", component = "COMPONENT_ASSAULTRIFLE_RPV_FINJECT" },
        { name = "Hydnic", component = "COMPONENT_ASSAULTRIFLE_RPV_HYDNIC" },
        { name = "Jaguar", component = "COMPONENT_ASSAULTRIFLE_RPV_JAGUAR" },
        { name = "Neon Rider", component = "COMPONENT_ASSAULTRIFLE_RPV_NRIDER" },
        { name = "PDis", component = "COMPONENT_ASSAULTRIFLE_RPV_PDIS" },
        { name = "Vulcan", component = "COMPONENT_ASSAULTRIFLE_RPV_VULCAN" },
        { name = "Wlandr", component = "COMPONENT_ASSAULTRIFLE_RPV_WLANDR" },
        { name = "Supreme", component = "COMPONENT_ASSAULTRIFLE_RPV_SUPREME" },
        { name = "Orbit 1", component = "COMPONENT_ASSAULTRIFLE_RPV_ORBIT1" }
    },
    ["WEAPON_MICROSMG"] = {
        { name = "Mặc định", component = "default" },
        { name = "Neon Đỏ", component = "COMPONENT_MICROSMG_RPV_NEONR" }
    },
    ["WEAPON_SPECIALCARBINE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Họa Tiết", component = "COMPONENT_SPECIALCARBINE_RPV_PRINT" }
    },
    ["WEAPON_BULLPUPRIFLE_MK2"] = {
        { name = "Mặc định", component = "default" },
        { name = "Họa Tiết", component = "COMPONENT_BULLPUPRIFLE_MK2_PRINT" },
        { name = "Rồng Vàng", component = "COMPONENT_BULLPUPRIFLE_MK2_GDRAGON" },
        { name = "Rồng Đỏ", component = "COMPONENT_BULLPUPRIFLE_MK2_RDRAGON" },
        { name = "Rồng Bạc", component = "COMPONENT_BULLPUPRIFLE_MK2_SDRAGON" },
        { name = "Noel 2024", component = "COMPONENT_BULLPUPRIFLE_MK2_NOEL2024" },
        { name = "Tết 2025", component = "COMPONENT_BULLPUPRIFLE_MK2_TET2025" },
        { name = "Kỷ Niệm 6 Năm", component = "COMPONENT_BULLPUPRIFLE_MK2_6TH" },
        { name = "Trung Thu 2025", component = "COMPONENT_BULLPUPRIFLE_MK2_TRUNGTHU2025" },
        { name = "Kawai Động", component = "COMPONENT_BULLPUPRIFLE_MK2_KAWAI_ANIM" }
    },
    ["WEAPON_ASSAULTSMG"] = {
        { name = "Mặc định", component = "default" },
        { name = "Jujutsu Kaisen", component = "COMPONENT_ASSAULTSMG_JUJUTSU" }
    },
    ["WEAPON_ADVANCEDRIFLE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Ngộ Không", component = "COMPONENT_ADVANCEDRIFLE_WUKONG" }
    },
    ["WEAPON_CARBINERIFLE_MK2"] = {
        { name = "Mặc định", component = "default" },
        { name = "Ngộ Không", component = "COMPONENT_CARBINERIFLE_MK2_WUKONG" },
        { name = "Trung Thu", component = "COMPONENT_CARBINERIFLE_MK2_TRUNGTHU" },
        { name = "Rồng Hoàng Gia", component = "COMPONENT_CARBINERIFLE_MK2_RDRAGON" },
        { name = "Noel 2024", component = "COMPONENT_CARBINERIFLE_MK2_NOEL2024" },
        { name = "Tết 2025", component = "COMPONENT_CARBINERIFLE_MK2_TET2025" },
        { name = "Kỷ Niệm 6 Năm", component = "COMPONENT_CARBINERIFLE_MK2_6TH" },
        { name = "Trung Thu 2025", component = "COMPONENT_CARBINERIFLE_MK2_TRUNGTHU2025" },
        { name = "Kawai Động", component = "COMPONENT_CARBINERIFLE_MK2_KAWAI_ANIM" }
    },
    ["WEAPON_PUMPSHOTGUN"] = {
        { name = "Mặc định", component = "default" },
        { name = "Mắt Quỷ", component = "COMPONENT_PUMPSHOTGUN_EYE" }
    },
    ["WEAPON_MG"] = {
        { name = "Mặc định", component = "default" },
        { name = "Bộc Phá (Boom)", component = "COMPONENT_MG_BOOM" }
    },
    ["WEAPON_APPISTOL"] = {
        { name = "Mặc định", component = "default" },
        { name = "Mèo Con", component = "COMPONENT_APPISTOL_CAT" }
    },
    ["WEAPON_BULLPUPRIFLE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Tình Yêu Đen", component = "COMPONENT_BULLPUPRIFLE_BLACKLOVE" },
        { name = "Trung Thu", component = "COMPONENT_BULLPUPRIFLE_TRUNGTHU" },
        { name = "Tết 2025", component = "COMPONENT_BULLPUPRIFLE_TET2025" }
    },
    ["WEAPON_ASSAULTRIFLE_MK2"] = {
        { name = "Mặc định", component = "default" },
        { name = "Kỷ Niệm 6 Năm", component = "COMPONENT_ASSAULTRIFLE_MK2_6TH" },
        { name = "Trung Thu 2025", component = "COMPONENT_ASSAULTRIFLE_MK2_TRUNGTHU2025" },
        { name = "Kawai Động", component = "COMPONENT_ASSAULTRIFLEMK2_KAWAI_ANIM" }
    },
    ["WEAPON_SPECIALCARBINE_MK2"] = {
        { name = "Mặc định", component = "default" },
        { name = "Kawai Động", component = "COMPONENT_SPECIALCARBINE_MK2_KAWAI_ANIM" }
    },
    ["WEAPON_BAT"] = {
        { name = "Mặc định", component = "default" },
        { name = "Bat T12", component = "COMPONENT_BAT_T12" }
    },
    ["WEAPON_MACHETE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Machete Vàng", component = "COMPONENT_MACHETE_GOLD" },
        { name = "Skin 1", component = "COMPONENT_MACHETE_SKIN_01" },
        { name = "Skin 2", component = "COMPONENT_MACHETE_SKIN_02" }
    },
    ["WEAPON_POOLCUE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Skin 1", component = "COMPONENT_POOLCUE_SKIN_01" },
        { name = "Skin 2", component = "COMPONENT_POOLCUE_SKIN_02" },
        { name = "Skin 3", component = "COMPONENT_POOLCUE_SKIN_03" },
        { name = "Skin 4", component = "COMPONENT_POOLCUE_SKIN_04" },
        { name = "Skin 5", component = "COMPONENT_POOLCUE_SKIN_05" },
        { name = "Skin MK", component = "COMPONENT_POOLCUE_SKIN_MK" },
        { name = "Sói Độc", component = "COMPONENT_POOLCUE_WOLF_01" },
        { name = "Poker", component = "COMPONENT_POOLCUE_POKER_01" }
    },
    ["WEAPON_SWITCHBLADE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Skin 1", component = "COMPONENT_SWITCHBLADE_SKIN_01" },
        { name = "Sói Độc", component = "COMPONENT_SWITCHBLADE_WOLF_01" },
        { name = "Poker", component = "COMPONENT_SWITCHBLADE_POKER_01" }
    },
    ["WEAPON_KNUCKLE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Skin 1", component = "COMPONENT_KNUCKLE_SKIN_01" },
        { name = "Sói Độc", component = "COMPONENT_KNUCKLE_WOLF_01" },
        { name = "Poker", component = "COMPONENT_KNUCKLE_POKER_01" }
    },
    ["WEAPON_BOTTLE"] = {
        { name = "Mặc định", component = "default" },
        { name = "Sói Độc", component = "COMPONENT_BOTTLE_WOLF_01" },
        { name = "Poker", component = "COMPONENT_BOTTLE_POKER_01" }
    }
}

return Config

-- =========================================================================
-- 1. CORE RAGEUI LIGHTWEIGHT (INTEGRATED & FIX POSITION)
-- =========================================================================
local RageUI = {}
RageUI.Menus = {}
local CurrentMenu = nil

function RageUI.CreateMenu(Title, Subtitle, X, Y)
    local Menu = {
        Title = Title or "MENU",
        Subtitle = Subtitle or "LIST",
        Visible = false,
        X = X or 0.02,
        Y = Y or 0.05,
        Width = 0.235,
        Index = 1,
        FromIndex = 1, 
        ToIndex = 10 
    }
    return Menu
end

function RageUI.Visible(Menu, Value)
    if Value ~= nil then
        Menu.Visible = Value
        if Value then 
            CurrentMenu = Menu 
            CurrentMenu.Index = 1
            CurrentMenu.FromIndex = 1
            CurrentMenu.ToIndex = 10
        else 
            if CurrentMenu == Menu then CurrentMenu = nil end 
        end
    else
        return Menu.Visible
    end
end

local function DrawText2D(text, font, x, y, scale, r, g, b, a, center)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    if center then 
        SetTextWrap(0.0, 1.0) 
        SetTextCentre(true) 
    end
    BeginTextCommandDisplayText("STRING")
    AddTextComponentString(text)
    EndTextCommandDisplayText(x, y)
end

local function DrawHealthBar3D(entity, maxHealth)
    if not DoesEntityExist(entity) then return end
    
    local entityCoords = GetEntityCoords(entity)
    local headCoords = GetPedBoneCoords(entity, 0x796e8c9f, 0.0, 0.0, 0.0) or (entityCoords + vector3(0, 0, 1.0))
    
    local screenX, screenY = GetScreenCoordFromWorldCoord(headCoords.x, headCoords.y, headCoords.z)
    
    if not screenX or not screenY then return end
    
    local currentHealth = math.max(0, GetEntityHealth(entity) - 100)
    local healthPercent = math.min(1.0, currentHealth / maxHealth)
    
    local barWidth = 0.08
    local barHeight = 0.015
    local barX = screenX
    local barY = screenY - 0.04
    
    -- Thanh nền (đen)
    DrawRect(barX, barY, barWidth, barHeight, 0, 0, 0, 200)
    
    -- Thanh máu (xanh lá nếu khỏe, vàng nếu bị thương, đỏ nếu gần chết)
    local r, g, b = 0, 255, 0
    if healthPercent < 0.5 then
        r, g, b = 255, 255, 0
    end
    if healthPercent < 0.25 then
        r, g, b = 255, 0, 0
    end
    
    DrawRect(barX - (barWidth - barWidth * healthPercent) / 2, barY, barWidth * healthPercent, barHeight, r, g, b, 255)
    
    -- Text máu
    DrawText2D(math.floor(currentHealth) .. "/" .. maxHealth, 0, screenX, screenY - 0.055, 0.35, 255, 255, 255, 255, true)
end

local function Clamp(n, min, max)
    if n < min then return min end
    if n > max then return max end
    return n
end

local function SafeMenuXY(baseX, baseY)
    -- Safezone: 1.0 = default, smaller = tighter safe zone
    local sz = GetSafeZoneSize()
    local off = (1.0 - sz) * 0.5
    return Clamp(baseX, off + 0.002, 1.0 - off - 0.25), Clamp(baseY, off + 0.002, 1.0 - off - 0.15)
end

local function TrimForMenu(s, maxLen)
    s = tostring(s or "")
    s = s:gsub("~.", "") -- tránh control codes lạ
    if #s <= maxLen then return s end
    return s:sub(1, math.max(1, maxLen - 3)) .. "..."
end

local function NormalizeVehicleCode(name)
    local n = tostring(name or "")
    n = n:gsub("^%s+", ""):gsub("%s+$", "")
    n = n:gsub("%.[^%.]+$", "") -- bỏ .yft/.ytd/.ydd...
    n = n:gsub("_hi$", "")      -- bỏ hậu tố _hi
    n = n:gsub("^%s+", ""):gsub("%s+$", "")
    return n
end

local function NormalizeVehicleList(list)
    local out = {}
    local seen = {}
    for _, item in ipairs(list or {}) do
        local code = NormalizeVehicleCode(item)
        local lower = string.lower(code)
        if code ~= "" and not seen[lower] then
            seen[lower] = true
            table.insert(out, code)
        end
    end
    table.sort(out, function(a, b)
        return string.lower(a) < string.lower(b)
    end)
    return out
end

-- =========================================================================
-- 2. DISABLE GAME TRAFFIC & DISPATCH SERVICES
-- =========================================================================
Citizen.CreateThread(function()
    for i = 0, 15 do EnableDispatchService(i, false) end
    StartAudioScene("CHARACTER_CHANGE_IN_SKY_SCENE")
    SetAudioFlag("PolicesirenLangSound", false)
    SetWavesIntensity(0.0)
    SetGarbageTrucks(false)
    SetRandomBoats(false)
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
end)

-- =========================================================================
-- 3. VEHICLE SPAWNER LOGIC (SMART REPLACE & ANTI-SPAM LOCK)
-- =========================================================================
local isSpawning = false
local companions = {}
local companionSpawnCount = 1
local companionMode = "side"
local companionInvincible = true
local convoySirenOn = false
local convoyFollowDist = 12.0
local companionNamePrefix = "De Tu"
local companionNameCounter = 0
local showCompanionNames = true

local WEAPON_MELEE = {
    "WEAPON_KNIFE", "WEAPON_NIGHTSTICK", "WEAPON_HAMMER", "WEAPON_BAT", "WEAPON_CROWBAR",
    "WEAPON_GOLFCLUB", "WEAPON_BOTTLE", "WEAPON_DAGGER", "WEAPON_HATCHET", "WEAPON_KNUCKLE",
    "WEAPON_MACHETE", "WEAPON_SWITCHBLADE", "WEAPON_POOLCUE", "WEAPON_WRENCH",
    "WEAPON_BATTLEAXE", "WEAPON_STONE_HATCHET"
}

local WEAPON_GUNS = {
    "WEAPON_PISTOL", "WEAPON_COMBATPISTOL", "WEAPON_APPISTOL", "WEAPON_PISTOL50", "WEAPON_SNSPISTOL",
    "WEAPON_HEAVYPISTOL", "WEAPON_MICROSMG", "WEAPON_SMG", "WEAPON_ASSAULTSMG", "WEAPON_ASSAULTRIFLE",
    "WEAPON_CARBINERIFLE", "WEAPON_ADVANCEDRIFLE", "WEAPON_MG", "WEAPON_COMBATMG", "WEAPON_PUMPSHOTGUN",
    "WEAPON_SAWNOFFSHOTGUN", "WEAPON_ASSAULTSHOTGUN", "WEAPON_SNIPERRIFLE", "WEAPON_HEAVYSNIPER",
    "WEAPON_GRENADELAUNCHER", "WEAPON_RPG", "WEAPON_MINIGUN", "WEAPON_STUNGUN"
}

local CUSTOM_STREAM_WEAPON_COMPONENTS = {
    "COMPONENT_CARBINERIFLE_TRUNGTHU",
    "COMPONENT_CARBINERIFLE_DRAGONR",
    "COMPONENT_CARBINERIFLE_DRAGONG",
    "COMPONENT_CARBINERIFLE_DRAGONS",
    "COMPONENT_CARBINERIFLE_RPV_FZEB",
    "COMPONENT_CARBINERIFLE_RPV_GIFFIN",
    "COMPONENT_CARBINERIFLE_RPV_HEFIRE",
    "COMPONENT_CARBINERIFLE_RPV_HOWL",
    "COMPONENT_CARBINERIFLE_RPV_TCAMO",
    "COMPONENT_CARBINERIFLE_RPV_MHUNTE",
    "COMPONENT_CARBINERIFLE_RPV_RHAZA",
    "COMPONENT_CARBINERIFLE_RPV_TCALI",
    "COMPONENT_ASSAULTRIFLE_RPV_DRAGON",
    "COMPONENT_ASSAULTRIFLE_RPV_SILVER",
    "COMPONENT_ASSAULTRIFLE_RPV_LAN",
    "COMPONENT_ASSAULTRIFLE_RPV_GREEN",
    "COMPONENT_ASSAULTRIFLE_RPV_SHARK",
    "COMPONENT_ASSAULTRIFLE_POOLPARTY",
    "COMPONENT_ASSAULTRIFLE_RPV_FINJECT",
    "COMPONENT_ASSAULTRIFLE_RPV_FMISTY",
    "COMPONENT_ASSAULTRIFLE_RPV_FSER",
    "COMPONENT_ASSAULTRIFLE_RPV_HYDNIC",
    "COMPONENT_ASSAULTRIFLE_RPV_JAGUAR",
    "COMPONENT_ASSAULTRIFLE_RPV_NRIDER",
    "COMPONENT_ASSAULTRIFLE_RPV_PDIS",
    "COMPONENT_ASSAULTRIFLE_RPV_VULCAN",
    "COMPONENT_ASSAULTRIFLE_RPV_WLANDR",
    "COMPONENT_ASSAULTRIFLE_RPV_SUPREME",
    "COMPONENT_ASSAULTRIFLE_RPV_ORBIT1",
    "COMPONENT_MICROSMG_RPV_NEONR",
    "COMPONENT_SPECIALCARBINE_RPV_PRINT",
    "COMPONENT_BULLPUPRIFLE_MK2_PRINT",
    "COMPONENT_ASSAULTSMG_JUJUTSU",
    "COMPONENT_ADVANCEDRIFLE_WUKONG",
    "COMPONENT_CARBINERIFLE_MK2_WUKONG",
    "COMPONENT_PUMPSHOTGUN_EYE",
    "COMPONENT_MG_BOOM",
    "COMPONENT_APPISTOL_CAT",
    "COMPONENT_BULLPUPRIFLE_BLACKLOVE",
    "COMPONENT_BULLPUPRIFLE_TRUNGTHU",
    "COMPONENT_CARBINERIFLE_MK2_TRUNGTHU",
    "COMPONENT_CARBINERIFLE_MK2_RDRAGON",
    "COMPONENT_BULLPUPRIFLE_MK2_GDRAGON",
    "COMPONENT_BULLPUPRIFLE_MK2_RDRAGON",
    "COMPONENT_BULLPUPRIFLE_MK2_SDRAGON",
    "COMPONENT_BULLPUPRIFLE_MK2_NOEL2024",
    "COMPONENT_CARBINERIFLE_MK2_NOEL2024",
    "COMPONENT_BULLPUPRIFLE_MK2_TET2025",
    "COMPONENT_CARBINERIFLE_MK2_TET2025",
    "COMPONENT_BULLPUPRIFLE_MK2_6TH",
    "COMPONENT_CARBINERIFLE_MK2_6TH",
    "COMPONENT_ASSAULTRIFLE_MK2_TRUNGTHU2025",
    "COMPONENT_CARBINERIFLE_MK2_TRUNGTHU2025",
    "COMPONENT_BULLPUPRIFLE_MK2_TRUNGTHU2025",
    "COMPONENT_BAT_T12",
    "COMPONENT_MACHETE_GOLD",
    "COMPONENT_POOLCUE_SKIN_05",
    "COMPONENT_POOLCUE_SKIN_MK",
    "COMPONENT_POOLCUE_SKIN_04",
    "COMPONENT_MACHETE_SKIN_01",
    "COMPONENT_MACHETE_SKIN_02",
    "COMPONENT_SWITCHBLADE_SKIN_01",
    "COMPONENT_POOLCUE_SKIN_01",
    "COMPONENT_POOLCUE_SKIN_02",
    "COMPONENT_POOLCUE_SKIN_03",
    "COMPONENT_KNUCKLE_SKIN_01",
    "COMPONENT_BOTTLE_WOLF_01",
    "COMPONENT_SWITCHBLADE_WOLF_01",
    "COMPONENT_KNUCKLE_WOLF_01",
    "COMPONENT_POOLCUE_WOLF_01",
    "COMPONENT_ASSAULTRIFLEMK2_KAWAI_ANIM",
    "COMPONENT_CARBINERIFLE_MK2_KAWAI_ANIM",
    "COMPONENT_SPECIALCARBINE_MK2_KAWAI_ANIM",
    "COMPONENT_BULLPUPRIFLE_MK2_KAWAI_ANIM",
    "COMPONENT_BOTTLE_POKER_01",
    "COMPONENT_SWITCHBLADE_POKER_01",
    "COMPONENT_KNUCKLE_POKER_01",
    "COMPONENT_POOLCUE_POKER_01"
}

local function GetRandomStreamWeaponComponent(weaponHash)
    local valid = {}
    for _, compName in ipairs(CUSTOM_STREAM_WEAPON_COMPONENTS) do
        if IsComponentValidForWeapon then
            if IsComponentValidForWeapon(weaponHash, compName) then
                table.insert(valid, compName)
            end
        else
            local compHash = GetHashKey(compName)
            if type(IsWeaponComponentValid) == "function" and IsWeaponComponentValid(weaponHash, compHash) then
                table.insert(valid, compName)
            end
        end
    end
    if #valid == 0 then
        return nil
    end
    return valid[math.random(1, #valid)]
end

-- Compatibility helper: some runtimes may not expose IsWeaponComponentValid.
local COMPONENT_TOKEN_TO_WEAPONS = {
    CARBINERIFLE = { "WEAPON_CARBINERIFLE", "WEAPON_CARBINERIFLE_MK2" },
    ASSAULTRIFLE = { "WEAPON_ASSAULTRIFLE", "WEAPON_ASSAULTRIFLE_MK2" },
    ASSAULTSMG = { "WEAPON_ASSAULTSMG" },
    MICROSMG = { "WEAPON_MICROSMG" },
    SPECIALCARBINE = { "WEAPON_SPECIALCARBINE", "WEAPON_SPECIALCARBINE_MK2" },
    BULLPUPRIFLE = { "WEAPON_BULLPUPRIFLE", "WEAPON_BULLPUPRIFLE_MK2" },
    ADVANCEDRIFLE = { "WEAPON_ADVANCEDRIFLE" },
    PUMPSHOTGUN = { "WEAPON_PUMPSHOTGUN" },
    MG = { "WEAPON_MG" },
    APPISTOL = { "WEAPON_APPISTOL" },
    ASSAULTRIFLEMK2 = { "WEAPON_ASSAULTRIFLE_MK2" },
    CARBINERIFLEMK2 = { "WEAPON_CARBINERIFLE_MK2" },
    SPECIALCARBINEMK2 = { "WEAPON_SPECIALCARBINE_MK2" },
    BULLPUPRIFLEMK2 = { "WEAPON_BULLPUPRIFLE_MK2" },
    BAT = { "WEAPON_BAT" },
    MACHETE = { "WEAPON_MACHETE" },
    POOLCUE = { "WEAPON_POOLCUE" },
    SWITCHBLADE = { "WEAPON_SWITCHBLADE" },
    BOTTLE = { "WEAPON_BOTTLE" },
    KNUCKLE = { "WEAPON_KNUCKLE" },
}

function IsComponentValidForWeapon(weaponHash, comp)
    if type(IsWeaponComponentValid) == "function" then
        local compHash = type(comp) == "number" and comp or GetHashKey(comp)
        return IsWeaponComponentValid(weaponHash, compHash)
    end

    local compName = comp
    if type(compName) ~= "string" then
        -- try to resolve name from hash
        for _, cname in ipairs(CUSTOM_STREAM_WEAPON_COMPONENTS) do
            if GetHashKey(cname) == comp then
                compName = cname
                break
            end
        end
        if type(compName) ~= "string" then return false end
    end

    local token = compName:match('^COMPONENT_([A-Z0-9]+)')
    if not token then return false end
    token = token:upper()

    local list = COMPONENT_TOKEN_TO_WEAPONS[token]
    if list then
        for _, w in ipairs(list) do
            if GetHashKey(w) == weaponHash then return true end
        end
    end

    -- fallback: check common partial matches
    for _, wname in ipairs({"WEAPON_" .. token, "WEAPON_" .. token .. "_MK2"}) do
        if GetHashKey(wname) == weaponHash then return true end
    end

    return false
end

local COMBAT_NPC_HEALTH = 600
local combatNpcs = {}
local combatRelationshipHash = nil

local function EnsureCombatRelationship()
    if combatRelationshipHash then return combatRelationshipHash end
    local groupHash = GetHashKey("NPC_FIGHTER")
    AddRelationshipGroup("NPC_FIGHTER")
    combatRelationshipHash = groupHash
    local playerGroup = GetHashKey("PLAYER")
    SetRelationshipBetweenGroups(5, combatRelationshipHash, playerGroup)
    SetRelationshipBetweenGroups(5, playerGroup, combatRelationshipHash)
    return combatRelationshipHash
end

local function GetRandomMeleeWeapon()
    local valid = {
        "WEAPON_DAGGER",
        "WEAPON_BAT",
        "WEAPON_BOTTLE",
        "WEAPON_CROWBAR",
        "WEAPON_GOLFCLUB",
        "WEAPON_KNIFE",
        "WEAPON_MACHETE",
        "WEAPON_SWITCHBLADE",
        "WEAPON_POOLCUE"
    }
    
    return valid[math.random(1, #valid)]
end

local function SetRandomGangStyle(ped)
    local comps = {0, 1, 2, 3, 4, 6, 7, 8, 11}
    for _, comp in ipairs(comps) do
        local drawableCount = GetNumberOfPedDrawableVariations(ped, comp)
        if drawableCount and drawableCount > 0 then
            local drawable = math.random(0, drawableCount - 1)
            local textureCount = GetNumberOfPedTextureVariations(ped, comp, drawable)
            local texture = (textureCount and textureCount > 0) and math.random(0, textureCount - 1) or 0
            SetPedComponentVariation(ped, comp, drawable, texture, 0)
        end
    end
    if GetNumberOfPedPropDrawableVariations(ped, 0) > 0 then
        local propDrawable = math.random(0, GetNumberOfPedPropDrawableVariations(ped, 0) - 1)
        SetPedPropIndex(ped, 0, propDrawable, 0, true)
    end
    if GetNumberOfPedPropDrawableVariations(ped, 1) > 0 then
        local propDrawable = math.random(0, GetNumberOfPedPropDrawableVariations(ped, 1) - 1)
        SetPedPropIndex(ped, 1, propDrawable, 0, true)
    end
    SetPedHairColor(ped, math.random(0, 63), math.random(0, 63))
    SetPedEyeColor(ped, math.random(0, 31))
end

local function IsPedUsable(ped)
    return ped and ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped)
end

local function SetCombatPedDefaults(ped)
    if not IsPedUsable(ped) then return end
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedSuffersCriticalHits(ped, false)
    SetPedCanEvasiveDive(ped, true)
    SetPedAccuracy(ped, 80)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAttributes(ped, 2, true)
    SetPedCombatAttributes(ped, 0, true)
    SetPedCombatMovement(ped, 2)
    SetPedCombatAbility(ped, 85)
    SetPedCombatRange(ped, 1)
    SetPedSeeingRange(ped, 120.0)
    SetPedHearingRange(ped, 80.0)
    SetPedAlertness(ped, 3)
    SetPedFleeAttributes(ped, 0, false)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedConfigFlag(ped, 185, true)
    SetPedConfigFlag(ped, 208, true)
    SetPedConfigFlag(ped, 166, false)
    SetPedConfigFlag(ped, 167, false)
    SetPedConfigFlag(ped, 273, true)
    SetPedConfigFlag(ped, 281, true)
    SetPedConfigFlag(ped, 29, true)
    SetPedConfigFlag(ped, 130, true)
    SetPedConfigFlag(ped, 132, true)
    SetPedConfigFlag(ped, 268, true)
    SetPedConfigFlag(ped, 32, false)
    SetPedCanSwitchWeapon(ped, false)
    SetPedSuffersCriticalHits(ped, false)
end

local function LoadModel(hash)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 200 do
        Citizen.Wait(10)
        t = t + 1
    end
    return HasModelLoaded(hash)
end

local function SpawnCombatNPC()
    local playerPed = PlayerPedId()
    local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
    local modelHash = GetHashKey("mp_m_freemode_01")
    if not LoadModel(modelHash) then
        TriggerEvent('chat:addMessage', { color = {255, 80, 80}, args = {"[NPC CHIEN DAU]", "Khong load duoc model NPC!"} })
        return
    end
    local npc = CreatePed(4, modelHash, spawnPos.x, spawnPos.y, spawnPos.z, GetEntityHeading(playerPed), true, false)
    if not IsPedUsable(npc) then
        TriggerEvent('chat:addMessage', { color = {255, 80, 80}, args = {"[NPC CHIEN DAU]", "Loi tao NPC!"} })
        return
    end
    SetEntityAsMissionEntity(npc, true, true)
    SetEntityMaxHealth(npc, COMBAT_NPC_HEALTH)
    SetEntityHealth(npc, COMBAT_NPC_HEALTH)
    SetPedArmour(npc, 50)
    EnsureCombatRelationship()
    SetPedRelationshipGroupHash(npc, combatRelationshipHash)
    SetCombatPedDefaults(npc)
    SetRandomGangStyle(npc)

    local weapon = GetRandomMeleeWeapon()
    local weaponHash = GetHashKey(weapon)

    RemoveAllPedWeapons(npc, true)
    GiveWeaponToPed(npc, weaponHash, 9999, false, true)
    SetCurrentPedWeapon(npc, weaponHash, true)
    SetPedCanSwitchWeapon(npc, false)

    GiveWeaponToPed(playerPed, weaponHash, 9999, false, true)
    SetCurrentPedWeapon(playerPed, weaponHash, true)
    SetPedCanSwitchWeapon(playerPed, true)
    SetAmmoInClip(playerPed, weaponHash, 9999)
    AddAmmoToPed(playerPed, weaponHash, 9999)

    SetEntityMaxHealth(playerPed, 200)
    SetEntityHealth(playerPed, 200)
    SetPedArmour(playerPed, 50)

    TaskGoToEntity(npc, playerPed, -1, 5.0, 4.5, 1073741824.0, 0)
    Citizen.Wait(200)
    TaskCombatPed(npc, playerPed, 0, 16)
    table.insert(combatNpcs, { ped = npc, weapon = weapon })
    TriggerEvent('chat:addMessage', { color = {0, 255, 120}, args = {"[NPC CHIEN DAU]", "Da spawn NPC chien dau voi " .. weapon .. "."} })
end

local function RemoveAllCombatNPCs()
    for i = #combatNpcs, 1, -1 do
        local data = combatNpcs[i]
        if data and IsPedUsable(data.ped) then
            SetEntityAsMissionEntity(data.ped, true, true)
            DeletePed(data.ped)
        end
        table.remove(combatNpcs, i)
    end
end

local function RefreshCombatNPCHealth()
    for _, data in ipairs(combatNpcs) do
        if IsPedUsable(data.ped) then
            SetEntityHealth(data.ped, COMBAT_NPC_HEALTH)
            SetPedArmour(data.ped, 25)
            local newWeapon = GetRandomMeleeWeapon()
            RemoveAllPedWeapons(data.ped, true)
            GiveWeaponToPed(data.ped, GetHashKey(newWeapon), 9999, false, true)
            SetCurrentPedWeapon(data.ped, GetHashKey(newWeapon), true)
            data.weapon = newWeapon
        end
    end
end


local function RespawnPlayer()
    local playerPed = PlayerPedId()
    ResurrectPed(playerPed)
    SetEntityHealth(playerPed, 200)
    SetPedArmour(playerPed, 150)
    RefillAmmo(playerPed)
    RefreshCombatNPCHealth()
end

local function RefillAmmo(ped)
    for i = 0, 255 do
        local weapon = GetHashKey(GetPedWeapon(ped))
        if weapon ~= GetHashKey("WEAPON_UNARMED") then
            SetAmmoInClip(ped, weapon, 9999)
            AddAmmoToPed(ped, weapon, 9999)
        end
    end
end

local DRIVING_STYLE_SMART = 1074528293
local CONVOY_DRIVE_UPDATE_MS = 1200
local lastPlayerInVehicle = false
local playerLastHealth = 200

function SpawnVipVehicle(modelName)
    if isSpawning then return end 
    isSpawning = true

    local vehicleHash = GetHashKey(modelName)
    if not IsModelInCdimage(vehicleHash) or not IsModelAVehicle(vehicleHash) then
        TriggerEvent('chat:addMessage', { color = {255, 0, 0}, args = {"[SYSTEM]", "Vehicle model does not exist!"} })
        isSpawning = false
        return
    end

    Citizen.CreateThread(function()
        RequestModel(vehicleHash)
        
        local timeout = 0
        while not HasModelLoaded(vehicleHash) and timeout < 200 do 
            Citizen.Wait(10) 
            timeout = timeout + 1
        end

        if not HasModelLoaded(vehicleHash) then
            TriggerEvent('chat:addMessage', { color = {255, 0, 0}, args = {"[SYSTEM]", "Failed to load vehicle model timeout!"} })
            isSpawning = false
            return
        end

        local playerPed = PlayerPedId()
        local pCoords = GetEntityCoords(playerPed)
        local pHeading = GetEntityHeading(playerPed)
        
        if IsPedInAnyVehicle(playerPed, false) then
            local currentVehicle = GetVehiclePedIsIn(playerPed, false)
            pCoords = GetEntityCoords(currentVehicle)
            pHeading = GetEntityHeading(currentVehicle)
            
            SetEntityAsMissionEntity(currentVehicle, true, true)
            DeleteVehicle(currentVehicle)
        end

        local spawnedVehicle = CreateVehicle(vehicleHash, pCoords.x, pCoords.y, pCoords.z, pHeading, true, false)
        SetEntityAsMissionEntity(spawnedVehicle, true, true) 
        SetPedIntoVehicle(playerPed, spawnedVehicle, -1)     
        SetModelAsNoLongerNeeded(vehicleHash)

        TriggerEvent('chat:addMessage', { color = {0, 255, 0}, args = {"[SYSTEM]", "Successfully spawned " .. string.upper(modelName) .. "!"} })
        
        Citizen.Wait(100) 
        isSpawning = false 
    end)
end

RegisterCommand('car', function(source, args)
    if args[1] then 
        SpawnVipVehicle(args[1]) 
    else 
        TriggerEvent('chat:addMessage', { color = {255, 255, 0}, args = {"[SYSTEM]", "Press F3 to open Vehicle Spawner Menu!"} }) 
    end
end, false)

local function NormalizeWeaponCode(code)
    if not code then return nil end
    local normalized = tostring(code):gsub('%s+', ''):upper()
    if normalized == '' then return nil end
    if not normalized:find('^WEAPON_') then
        normalized = 'WEAPON_' .. normalized
    end
    return normalized
end

local function NormalizeComponentCode(name)
    if not name then return nil end
    local s = tostring(name):gsub('^%s+', ''):gsub('%s+$', '')
    local up = s:upper()
    if up == '' then return nil end
    if not up:find('^COMPONENT_') then up = 'COMPONENT_' .. up end
    for _, comp in ipairs(CUSTOM_STREAM_WEAPON_COMPONENTS) do
        if comp:upper() == up then
            return comp
        end
    end
    return nil
end

local function GiveWeaponToPlayer(weaponCode)
    local weaponName = NormalizeWeaponCode(weaponCode)
    if not weaponName then return false, 'Invalid weapon code' end

    local weaponHash = GetHashKey(weaponName)
    if not IsWeaponValid(weaponHash) then
        return false, weaponName
    end

    local playerPed = PlayerPedId()
    GiveWeaponToPed(playerPed, weaponHash, 9999, false, true)
    SetCurrentPedWeapon(playerPed, weaponHash, true)

    local weaponGroup = GetWeapontypeGroup(weaponHash)
    if weaponGroup ~= 2685387236 then
        SetAmmoInClip(playerPed, weaponHash, 9999)
        AddAmmoToPed(playerPed, weaponHash, 9999)
    end

    return true, weaponName
end

local function OpenKeyboardInput(title, defaultText, maxLen)
    AddTextEntry("FMMC_KEY_TIP8", title or "Nhap")
    DisplayOnscreenKeyboard(0, "FMMC_KEY_TIP8", "", defaultText or "", "", "", "", maxLen or 30)
    while UpdateOnscreenKeyboard() == 0 do
        Citizen.Wait(0)
    end
    if UpdateOnscreenKeyboard() == 2 then
        local result = GetOnscreenKeyboardResult()
        if result and result ~= "" then
            return result
        end
    end
    return nil
end

local function ChangeHeldWeaponSkin(skinArg)
    local playerPed = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    if not currentWeapon or currentWeapon == GetHashKey('WEAPON_UNARMED') then
        return false, 'Ban khong dang cam vu khi nao.'
    end

    if not skinArg or skinArg == '' or skinArg:lower() == 'random' then
        local componentName = GetRandomStreamWeaponComponent(currentWeapon)
        if not componentName then
            return false, 'Khong tim thay skin addon stream hop le cho vu khi hien tai.'
        end

        GiveWeaponComponentToPed(playerPed, currentWeapon, GetHashKey(componentName))
        return true, 'Random skin: ' .. componentName
    end

    local componentName = NormalizeComponentCode(skinArg)
    if componentName then
        local componentHash = GetHashKey(componentName)
        if IsComponentValidForWeapon(currentWeapon, componentName) then
            GiveWeaponComponentToPed(playerPed, currentWeapon, componentHash)
            return true, componentName
        end
    end

    local tintIndex = tonumber(skinArg)
    if tintIndex then
        if tintIndex < 0 or tintIndex > 7 then
            return false, 'Chi so tint tu 0 den 7.'
        end
        SetPedWeaponTintIndex(playerPed, currentWeapon, tintIndex)
        return true, 'Tint ' .. tintIndex
    end

    return false, 'Su dung /thayskin [component_name] hoac so tint 0-7.'
end

local function PromptWeaponSkinChange()
    local playerPed = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    if not currentWeapon or currentWeapon == GetHashKey('WEAPON_UNARMED') then
        TriggerEvent('chat:addMessage', { color = {255, 80, 80}, args = {'[SYSTEM]', 'Ban phai cam mot vu khi de thay skin.'} })
        return
    end

    local success, result = ChangeHeldWeaponSkin('random')
    if success then
        TriggerEvent('chat:addMessage', { color = {0, 255, 120}, args = {'[SYSTEM]', 'Da thay skin ngau nhien: ' .. result} })
    else
        TriggerEvent('chat:addMessage', { color = {255, 80, 80}, args = {'[SYSTEM]', result} })
    end
end

RegisterCommand('wp', function(_, args)
    if not args[1] or args[1] == '' then
        TriggerEvent('chat:addMessage', { color = {255, 255, 0}, args = {"[SYSTEM]", "Usage: /wp [weapon_code] e.g. /wp pistol or /wp WEAPON_PISTOL"} })
        return
    end

    local weaponArg = args[1]
    local success, result = GiveWeaponToPlayer(weaponArg)
    if success then
        TriggerEvent('chat:addMessage', { color = {0, 255, 120}, args = {"[SYSTEM]", "Da cap vu khi: " .. result} })
    else
        TriggerEvent('chat:addMessage', { color = {255, 80, 80}, args = {"[SYSTEM]", "Khong the cap vu khi: " .. tostring(result)} })
    end
end, false)

RegisterCommand('heal', function()
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
    ClearPedBloodDamage(playerPed)
    TriggerEvent('chat:addMessage', { color = {0, 255, 120}, args = {"[SYSTEM]", "Da hoi day mau!"} })
end, false)

RegisterCommand('thayskin', function(_, args)
    if not args[1] or args[1] == '' then
        PromptWeaponSkinChange()
        return
    end

    local skinArg = args[1]
    if skinArg:lower() == 'list' then
        TriggerEvent('chat:addMessage', { color = {255, 255, 0}, args = {"[SYSTEM]", "Su dung: /thayskin [component_name] hoac so tint 0-7. Vi du: /thayskin COMPONENT_CARBINERIFLE_DRAGONR"} })
        return
    end

    local success, result = ChangeHeldWeaponSkin(skinArg)
    if success then
        TriggerEvent('chat:addMessage', { color = {0, 255, 120}, args = {"[SYSTEM]", "Da thay skin: " .. result} })
    else
        TriggerEvent('chat:addMessage', { color = {255, 80, 80}, args = {"[SYSTEM]", tostring(result)} })
    end
end, false)

RegisterKeyMapping('thayskin', 'Thay skin vu khi dang cam', 'keyboard', 'k')

local function NextCompanionName(kind)
    companionNameCounter = companionNameCounter + 1
    if kind == "convoy" then
        return companionNamePrefix .. " #" .. companionNameCounter .. " (Tai Xe)"
    end
    return companionNamePrefix .. " #" .. companionNameCounter
end

local function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 230)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 180)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentString(text)
    EndTextCommandDisplayText(sx, sy)
end

local function SetupCompanionPed(clone, playerPed, isDriver)
    SetEntityAsMissionEntity(clone, true, true)
    SetBlockingOfNonTemporaryEvents(clone, true)
    SetPedCanRagdoll(clone, false)
    SetPedCanRagdollFromPlayerImpact(clone, false)
    SetPedFleeAttributes(clone, 0, false)
    SetPedCombatAttributes(clone, 46, true)
    SetPedCombatAbility(clone, 3)
    SetPedCombatMovement(clone, 3)
    SetPedCombatRange(clone, 2)
    SetEntityInvincible(clone, companionInvincible)
    SetPedRelationshipGroupHash(clone, GetPedRelationshipGroupHash(playerPed))
    if not isDriver then
        SetPedAsGroupMember(clone, GetPedGroupIndex(playerPed))
    end
    SetPedKeepTask(clone, true)
    SetPedCanBeDraggedOut(clone, false)
    SetCombatPedDefaults(clone)
    if isDriver then
        SetDriverAbility(clone, 1.0)
        SetDriverAggressiveness(clone, 0.2)
        SetPedStayInVehicleWhenJacked(clone, true)
        SetPedCanBeKnockedOffVehicle(clone, 0)
    end
end

local function ConvoyStopAndExit(data)
    local ped = data.ped
    local veh = data.veh
    if not IsPedUsable(ped) then return end
    ClearPedTasks(ped)
    if veh and DoesEntityExist(veh) then
        SetVehicleForwardSpeed(veh, 0.0)
        SetVehicleBrake(veh, true)
    end
    data.convoyDriving = false
end

local function ConvoyStartDriving(data, playerVeh)
    local ped = data.ped
    local veh = data.veh
    if not IsPedUsable(ped) or not DoesEntityExist(veh) or playerVeh == 0 then return end

    if not IsPedInVehicle(ped, veh, false) then
        SetPedIntoVehicle(ped, veh, -1)
    end
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleUndriveable(veh, false)
    SetVehicleBrake(veh, false)
    data.convoyDriving = true
    data.lastDriveTask = 0
end

local function ConvoyDriveBehindPlayer(data, playerVeh)
    local ped = data.ped
    local veh = data.veh
    if not data.convoyDriving or not IsPedUsable(ped) or not DoesEntityExist(veh) then return end
    if not IsPedInVehicle(ped, veh, false) then
        SetPedIntoVehicle(ped, veh, -1)
        return
    end

    local now = GetGameTimer()
    if data.lastDriveTask and (now - data.lastDriveTask) < CONVOY_DRIVE_UPDATE_MS then
        return
    end
    data.lastDriveTask = now

    local slot = data.slot or 1
    local backDist = convoyFollowDist + (slot * 5.0)
    local dest = GetOffsetFromEntityInWorldCoords(playerVeh, 0.0, -backDist, 0.0)
    local playerSpeed = GetEntitySpeed(playerVeh)
    local driveSpeed = math.max(18.0, math.min(42.0, playerSpeed * 3.2 + 14.0))

    TaskVehicleDriveToCoord(
        ped, veh,
        dest.x, dest.y, dest.z,
        driveSpeed, 0,
        GetEntityModel(veh),
        DRIVING_STYLE_SMART,
        3.0, true
    )
    SetDriveTaskMaxCruiseSpeed(ped, driveSpeed + 5.0)
end

local function OnPlayerEnteredVehicle(playerVeh)
    for _, data in ipairs(companions) do
        if data.kind == "convoy" and data.veh and DoesEntityExist(data.veh) then
            ConvoyStartDriving(data, playerVeh)
        end
    end
end

local function OnPlayerExitedVehicle()
    for _, data in ipairs(companions) do
        if data.kind == "convoy" then
            local ped = data.ped
            local veh = data.veh
            if IsPedUsable(ped) then
                ClearPedTasks(ped)
                if veh and DoesEntityExist(veh) then
                    SetVehicleForwardSpeed(veh, 0.0)
                    SetVehicleBrake(veh, true)
                end
                data.convoyDriving = false
            end
        end
    end
end

local function RemoveCompanionAt(index)
    local data = companions[index]
    if not data then return end
    if data.veh and DoesEntityExist(data.veh) then
        SetEntityAsMissionEntity(data.veh, true, true)
        DeleteVehicle(data.veh)
    end
    if IsPedUsable(data.ped) then
        SetEntityAsMissionEntity(data.ped, true, true)
        DeletePed(data.ped)
    end
    table.remove(companions, index)
end

local function RemoveAllCompanions()
    for i = #companions, 1, -1 do
        RemoveCompanionAt(i)
    end
end

local function GetFootOffset(index, total, mode)
    if mode == "follow" then
        return 0.0, -1.2 - (index * 1.1), 0.0
    elseif mode == "column" then
        return 0.0, -1.0 - (index * 1.3), 0.0
    elseif mode == "circle" then
        local angle = (index / math.max(1, total)) * 6.28318530718
        return math.cos(angle) * 1.8, math.sin(angle) * 1.8, 0.0
    elseif mode == "vformation" then
        local side = (index % 2 == 0) and 1 or -1
        local row = math.ceil(index / 2)
        return side * (0.8 + row * 0.5), -1.0 - (row * 1.0), 0.0
    elseif mode == "wedge" then
        local side = (index % 2 == 0) and 1 or -1
        local row = math.ceil(index / 2)
        return side * (1.2 + row * 0.4), -0.8 - (row * 0.9), 0.0
    elseif mode == "hold" then
        return 0.0, 0.0, 0.0
    else
        local lane = (index % 2 == 0) and math.floor(index / 2) or -math.floor((index + 1) / 2)
        return lane * 1.0, -0.8, 0.0
    end
end

local function ApplyFootTask(ped, playerPed, index, total)
    if companionMode == "hold" then
        TaskStandStill(ped, 1500)
        return
    end
    local xOff, yOff, zOff = GetFootOffset(index, total, companionMode)
    local speed = 2.6
    if IsPedRunning(playerPed) or IsPedSprinting(playerPed) then speed = 3.4 end
    TaskFollowToOffsetOfEntity(ped, playerPed, xOff, yOff, zOff, speed, 1200, 1.5, true)
end

local function SpawnCloneCompanion()
    local playerPed = PlayerPedId()
    local heading = GetEntityHeading(playerPed)
    local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -1.2, 0.0)
    local clone = ClonePed(playerPed, heading, true, true)
    if not IsPedUsable(clone) then return false end
    SetEntityCoordsNoOffset(clone, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
    SetEntityMaxHealth(clone, COMBAT_NPC_HEALTH)
    SetEntityHealth(clone, COMBAT_NPC_HEALTH)
    SetPedArmour(clone, 25)
    SetCombatPedDefaults(clone)
    local cloneWeapon = GetRandomMeleeWeapon()
    RemoveAllPedWeapons(clone, true)
    GiveWeaponToPed(clone, GetHashKey(cloneWeapon), 9999, false, true)
    SetCurrentPedWeapon(clone, GetHashKey(cloneWeapon), true)
    SetPedCanSwitchWeapon(clone, false)
    SetupCompanionPed(clone, playerPed, false)
    table.insert(companions, {
        ped = clone, veh = nil, kind = "foot", name = NextCompanionName("foot"),
        vehMode = "walking", lastDriveTask = 0
    })
    return true
end

local function GiveWeaponSetToCompanions(weaponList)
    for _, data in ipairs(companions) do
        local ped = data.ped
        if IsPedUsable(ped) then
            RemoveAllPedWeapons(ped, true)
            for _, weaponName in ipairs(weaponList) do
                local wHash = GetHashKey(weaponName)
                GiveWeaponToPed(ped, wHash, 9999, false, true)
            end
            SetCurrentPedWeapon(ped, GetHashKey(weaponList[1]), true)
        end
    end
end

local function GiveMyWeaponToCompanions()
    local playerPed = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    if not currentWeapon or currentWeapon == GetHashKey("WEAPON_UNARMED") then return end
    for _, data in ipairs(companions) do
        local ped = data.ped
        if IsPedUsable(ped) then
            RemoveAllPedWeapons(ped, true)
            GiveWeaponToPed(ped, currentWeapon, 9999, false, true)
        end
    end
end

local function TeleportCompanionsToMe()
    local playerPed = PlayerPedId()
    local footIndex = 0
    for _, data in ipairs(companions) do
        if data.kind == "convoy" and data.veh and DoesEntityExist(data.veh) then
            local pos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -8.0 - (data.slot or 1) * convoyFollowDist, 0.0)
            SetEntityCoordsNoOffset(data.veh, pos.x, pos.y, pos.z, false, false, false)
            if IsPedUsable(data.ped) and not IsPedInVehicle(data.ped, data.veh, false) then
                TaskWarpPedIntoVehicle(data.ped, data.veh, -1)
            end
        elseif IsPedUsable(data.ped) then
            footIndex = footIndex + 1
            local xOff, yOff = GetFootOffset(footIndex, #companions, companionMode)
            local pos = GetOffsetFromEntityInWorldCoords(playerPed, xOff, yOff, 0.0)
            SetEntityCoordsNoOffset(data.ped, pos.x, pos.y, pos.z, false, false, false)
        end
    end
end

local function SetConvoySirens(enabled)
    convoySirenOn = enabled
    for _, data in ipairs(companions) do
        if data.kind == "convoy" and data.veh and DoesEntityExist(data.veh) then
            SetVehicleHasMutedSirens(data.veh, false)
            SetVehicleSiren(data.veh, enabled)
            SetVehicleIsSirenOn(data.veh, enabled)
            if enabled then
                SetVehicleLights(data.veh, 2)
            end
        end
    end
end

local function SpawnConvoyMember(modelName, slot)
    local playerPed = PlayerPedId()
    local vehHash = GetHashKey(modelName)
    if not LoadModel(vehHash) or not IsModelAVehicle(vehHash) then
        return false
    end

    local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -6.0 - (slot * convoyFollowDist), 0.0)
    local heading = GetEntityHeading(playerPed)
    local veh = CreateVehicle(vehHash, spawnPos.x, spawnPos.y, spawnPos.z, heading, true, false)
    if not DoesEntityExist(veh) then return false end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    SetVehicleNeedsToBeHotwired(veh, false)
    SetVehRadioStation(veh, "OFF")

    local driver = ClonePed(playerPed, heading, true, true)
    if not IsPedUsable(driver) then
        DeleteVehicle(veh)
        return false
    end

    SetupCompanionPed(driver, playerPed, true)
    SetPedIntoVehicle(driver, veh, -1)

    if convoySirenOn then
        SetVehicleHasMutedSirens(veh, false)
        SetVehicleSiren(veh, true)
        SetVehicleIsSirenOn(veh, true)
        SetVehicleLights(veh, 2)
    end

    table.insert(companions, {
        ped = driver,
        veh = veh,
        kind = "convoy",
        slot = slot,
        model = modelName,
        name = NextCompanionName("convoy"),
        convoyDriving = false,
        lastDriveTask = 0
    })
    SetModelAsNoLongerNeeded(vehHash)
    return true
end

Citizen.CreateThread(function()
    while true do
        if showCompanionNames and #companions > 0 then
            for _, data in ipairs(companions) do
                if IsPedUsable(data.ped) and data.name and data.name ~= "" then
                    local head = GetPedBoneCoords(data.ped, 31086, 0.0, 0.0, 0.0)
                    DrawText3D(head.x, head.y, head.z + 0.45, data.name)
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(400)
        end
    end
end)

-- =========================================================================
-- 4. INITIALIZE MENUS & ARRAYS
-- =========================================================================
local MainMenu = RageUI.CreateMenu("VIP SPAWNER", "SERVER VEHICLE MANAGEMENT")
local SubMenuNoShop = RageUI.CreateMenu("NO SHOP", "VEHICLES NOT IN SHOP")
local SubMenuShop = RageUI.CreateMenu("SHOP", "VEHICLES IN SHOP")
local SubMenuNganh = RageUI.CreateMenu("XE NGANH", "AGENCY VEHICLES LIST")
local CompanionMenu = RageUI.CreateMenu("DE TU / BAN GAI", "NPC CLONE MANAGEMENT")
local CompanionModeMenu = RageUI.CreateMenu("FORMATION MODE", "HOW COMPANIONS MOVE")
local CompanionWeaponMenu = RageUI.CreateMenu("VU KHI DE TU", "CAP VU KHI CHO NPC")

local serverNoShopList = {}
local serverShopList = {}
local serverNganhList = {}
local CurrentTab = "main"
local SearchQuery = ""

local function ResetMenuCursor(menu)
    menu.Index = 1
    menu.FromIndex = 1
    menu.ToIndex = 10
end

local function ForceReleaseInput()
    SetNuiFocus(false, false)
end

local function CloseAllMenus()
    RageUI.Visible(MainMenu, false)
    RageUI.Visible(SubMenuNoShop, false)
    RageUI.Visible(SubMenuShop, false)
    RageUI.Visible(SubMenuNganh, false)
    RageUI.Visible(CompanionMenu, false)
    RageUI.Visible(CompanionModeMenu, false)
    RageUI.Visible(CompanionWeaponMenu, false)
    CurrentMenu = nil
end

RegisterCommand('fixchuot', function()
    ForceReleaseInput()
    CloseAllMenus()
    TriggerEvent('chat:addMessage', { color = {0, 255, 200}, args = {"[SYSTEM]", "Da mo khoa chuot + dieu khien."} })
end, false)

local function RunConvoySpawn(models)
    local spawned = 0
    local count = #models
    for i, model in ipairs(models) do
        if SpawnConvoyMember(model, i) then
            spawned = spawned + 1
        else
            TriggerEvent('chat:addMessage', {
                color = {255, 80, 80},
                args = {"[DOAN XE]", "Loi spawn xe #" .. i .. " model: " .. model}
            })
        end
    end
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 200},
        args = {"[DOAN XE]", "Da tao " .. spawned .. "/" .. count .. " xe trong doan."}
    })

    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then
        OnPlayerEnteredVehicle(GetVehiclePedIsIn(playerPed, false))
        lastPlayerInVehicle = true
    else
        lastPlayerInVehicle = false
    end
end

local function StartConvoySetup(sameModelForAll)
    ForceReleaseInput()
    CloseAllMenus()
    local count = companionSpawnCount
    if sameModelForAll then
        TriggerEvent('chat:addMessage', { color = {0, 255, 200}, args = {"[DOAN XE]", "Mo chat (T) go: /doanxe [ma xe]  -> tao " .. count .. " xe giong nhau"} })
        TriggerEvent('chat:addMessage', { color = {200, 200, 200}, args = {"[VD]", "/doanxe adder"} })
    else
        TriggerEvent('chat:addMessage', { color = {0, 255, 200}, args = {"[DOAN XE]", "Go: /doanxe ma1,ma2,ma3 (moi ma 1 xe)"} })
        TriggerEvent('chat:addMessage', { color = {200, 200, 200}, args = {"[VD]", "/doanxe adder,t20,zentorno"} })
    end
    TriggerEvent('chat:addMessage', { color = {255, 200, 0}, args = {"[DOAN XE]", "Bi ket chuot? Go /fixchuot"} })
end

RegisterCommand('detuprefix', function(_, args)
    if not args[1] then
        TriggerEvent('chat:addMessage', { color = {255, 255, 0}, args = {"[DE TU]", "/detuprefix [ten]  VD: /detuprefix De Tu"} })
        return
    end
    companionNamePrefix = table.concat(args, " ")
    TriggerEvent('chat:addMessage', { color = {0, 255, 200}, args = {"[DE TU]", "Tien to ten: " .. companionNamePrefix} })
end, false)

RegisterCommand('detuten', function(_, args)
    if not args[1] then
        TriggerEvent('chat:addMessage', { color = {255, 255, 0}, args = {"[DE TU]", "/detuten [ten rieng]"} })
        return
    end
    local last = companions[#companions]
    if not last then
        TriggerEvent('chat:addMessage', { color = {255, 80, 80}, args = {"[DE TU]", "Khong co NPC nao."} })
        return
    end
    last.name = table.concat(args, " ")
    TriggerEvent('chat:addMessage', { color = {0, 255, 200}, args = {"[DE TU]", "Da dat ten: " .. last.name} })
end, false)

RegisterCommand('doanxe', function(_, args)
    if not args[1] then
        TriggerEvent('chat:addMessage', { color = {255, 255, 0}, args = {"[DOAN XE]", "/doanxe [ma] = " .. companionSpawnCount .. " xe giong nhau"} })
        TriggerEvent('chat:addMessage', { color = {255, 255, 0}, args = {"[DOAN XE]", "/doanxe ma1,ma2,ma3 = nhieu xe khac nhau"} })
        TriggerEvent('chat:addMessage', { color = {255, 255, 0}, args = {"[DOAN XE]", "/fixchuot = mo khoa chuot"} })
        return
    end

    local raw = table.concat(args, " ")
    local models = {}

    if raw:find(",") then
        for part in raw:gmatch("[^,]+") do
            local m = NormalizeVehicleCode(part)
            if m ~= "" then
                table.insert(models, m)
            end
        end
    else
        local m = NormalizeVehicleCode(raw)
        if m == "" then return end
        for i = 1, companionSpawnCount do
            models[i] = m
        end
    end

    if #models == 0 then
        TriggerEvent('chat:addMessage', { color = {255, 80, 80}, args = {"[DOAN XE]", "Ma xe khong hop le."} })
        return
    end

    RunConvoySpawn(models)
end, false)

local function BuildVehicleItems(rawItems)
    if CurrentTab == "main" then
        return rawItems
    end

    local q = string.lower((SearchQuery or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    if q == "" then
        return rawItems
    end

    local filtered = {}
    for _, model in ipairs(rawItems) do
        local name = tostring(model or "")
        if string.find(string.lower(name), q, 1, true) then
            table.insert(filtered, name)
        end
    end
    return filtered
end

local function IsVehicleTab(tab)
    return tab == "main" or tab == "noshop" or tab == "shop" or tab == "nganh"
end

local function IsCompanionTab(tab)
    return tab == "comp_main" or tab == "comp_mode"
end

RegisterNetEvent('remove-npcs:receiveVehicles')
AddEventHandler('remove-npcs:receiveVehicles', function(noShop, shop, nganh)
    serverNoShopList = NormalizeVehicleList(noShop)
    serverShopList = NormalizeVehicleList(shop)
    serverNganhList = NormalizeVehicleList(nganh)
    CurrentTab = "main"
    SearchQuery = ""
    RageUI.Visible(MainMenu, true)
    ResetMenuCursor(MainMenu)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local hasVisibleMenu = MainMenu.Visible or SubMenuNoShop.Visible or SubMenuShop.Visible or SubMenuNganh.Visible
            or CompanionMenu.Visible or CompanionModeMenu.Visible or CompanionWeaponMenu.Visible

        if IsControlJustPressed(0, 170) or IsDisabledControlJustPressed(0, 170) then -- F3
            if not hasVisibleMenu then
                TriggerServerEvent('remove-npcs:requestVehicles')
            else
                RageUI.Visible(MainMenu, false)
                RageUI.Visible(SubMenuNoShop, false)
                RageUI.Visible(SubMenuShop, false)
                RageUI.Visible(SubMenuNganh, false)
                RageUI.Visible(CompanionMenu, false)
                RageUI.Visible(CompanionModeMenu, false)
                RageUI.Visible(CompanionWeaponMenu, false)
                CurrentMenu = nil
            end
        elseif IsControlJustPressed(0, 288) or IsDisabledControlJustPressed(0, 288) then -- F1
            if not hasVisibleMenu then
                CurrentTab = "comp_main"
                SearchQuery = ""
                RageUI.Visible(CompanionMenu, true)
                ResetMenuCursor(CompanionMenu)
            else
                RageUI.Visible(MainMenu, false)
                RageUI.Visible(SubMenuNoShop, false)
                RageUI.Visible(SubMenuShop, false)
                RageUI.Visible(SubMenuNganh, false)
                RageUI.Visible(CompanionMenu, false)
                RageUI.Visible(CompanionModeMenu, false)
                RageUI.Visible(CompanionWeaponMenu, false)
                CurrentMenu = nil
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if #companions > 0 then
            local playerPed = PlayerPedId()
            local inVehicle = IsPedInAnyVehicle(playerPed, false)
            local playerVeh = inVehicle and GetVehiclePedIsIn(playerPed, false) or 0

            if inVehicle and not lastPlayerInVehicle then
                OnPlayerEnteredVehicle(playerVeh)
            elseif not inVehicle and lastPlayerInVehicle then
                OnPlayerExitedVehicle()
            end
            lastPlayerInVehicle = inVehicle

            local footMembers = {}
            for _, data in ipairs(companions) do
                if data.kind ~= "convoy" then
                    table.insert(footMembers, data)
                end
            end
            local footTotal = #footMembers
            local footIndex = 0

            for i = #companions, 1, -1 do
                local data = companions[i]
                local ped = data.ped
                if not IsPedUsable(ped) then
                    if data.veh and DoesEntityExist(data.veh) then
                        DeleteVehicle(data.veh)
                    end
                    table.remove(companions, i)
                else
                    SetEntityInvincible(ped, companionInvincible)

                    if data.kind == "convoy" and data.veh and DoesEntityExist(data.veh) then
                        if inVehicle and playerVeh ~= 0 and data.convoyDriving then
                            ConvoyDriveBehindPlayer(data, playerVeh)
                        elseif not inVehicle and not IsPedInAnyVehicle(ped, false) then
                            footIndex = footIndex + 1
                            local now = GetGameTimer()
                            if not data.lastFootTask or (now - data.lastFootTask) > 2000 then
                                data.lastFootTask = now
                                ApplyFootTask(ped, playerPed, footIndex, math.max(1, footTotal + footIndex))
                            end
                        end
                    else
                        -- Automatic vehicle exit when player is on foot has been disabled to prevent automatic exits.
                        footIndex = footIndex + 1
                        local idx = 0
                        for fi, fm in ipairs(footMembers) do
                            if fm.ped == ped then idx = fi break end
                        end
                        if idx > 0 and not inVehicle then
                            local now = GetGameTimer()
                            if not data.lastFootTask or (now - data.lastFootTask) > 1500 then
                                data.lastFootTask = now
                                ApplyFootTask(ped, playerPed, idx, math.max(1, footTotal))
                            end
                        end
                    end
                end
            end
            Citizen.Wait(inVehicle and 0 or 400)
        else
            lastPlayerInVehicle = false
            Citizen.Wait(800)
        end
    end
end)

-- =========================================================================
-- 5. LUỒNG VẼ REALTIME CANVAS & THUẬT TOÁN SCROLL LIST THÔNG MINH
-- =========================================================================
Citizen.CreateThread(function()
    while true do
        local sleep = 250
        if CurrentMenu ~= nil then
            sleep = 0
            
            local startX, startY = SafeMenuXY(CurrentMenu.X, CurrentMenu.Y)
            local menuWidth = CurrentMenu.Width

            -- Header
            DrawRect(startX + (menuWidth/2), startY + 0.03, menuWidth, 0.06, 0, 120, 255, 235)
            DrawText2D(TrimForMenu(CurrentMenu.Title, 24), 1, startX + (menuWidth/2), startY + 0.01, 0.68, 255, 255, 255, 255, true)
            
            -- Subtitle bar
            DrawRect(startX + (menuWidth/2), startY + 0.075, menuWidth, 0.03, 14, 14, 14, 245)
            DrawText2D(TrimForMenu(CurrentMenu.Subtitle, 38), 0, startX + 0.008, startY + 0.062, 0.33, 205, 205, 205, 255, false)

            local rawItems = {}
            if CurrentTab == "main" then
                rawItems = {"1. VIEW NO SHOP VEHICLES", "2. VIEW SHOP VEHICLES", "3. VIEW XE NGANH VEHICLES"}
            elseif CurrentTab == "noshop" then
                rawItems = serverNoShopList
            elseif CurrentTab == "shop" then
                rawItems = serverShopList
            elseif CurrentTab == "nganh" then
                rawItems = serverNganhList
            elseif CurrentTab == "comp_main" then
                rawItems = {
                    "SPAWN NPC CHIEN DAU",
                    "SPAWN CLONE NPC (SL: " .. companionSpawnCount .. ")",
                    "TAO DOAN XE (CHAT: /doanxe a,b,c)",
                    "TAO DOAN XE (CHAT: /doanxe [ma])",
                    "GIAM SO LUONG",
                    "TANG SO LUONG",
                    "CHE DO DI BO / HANG NGU",
                    "MENU CAP VU KHI",
                    "TELEPORT VE TOI",
                    "CONG UU TIEN: " .. (convoySirenOn and "BAT" or "TAT"),
                    "TANG KHOANG CACH DOAN XE",
                    "GIAM KHOANG CACH DOAN XE",
                    "BAT/TAT BAT TU: " .. (companionInvincible and "ON" or "OFF"),
                    "XOA 1 NPC MOI NHAT",
                    "XOA TOAN BO",
                    "HIEN TEN TREN DAU: " .. (showCompanionNames and "BAT" or "TAT"),
                    "TIEN TO TEN: " .. TrimForMenu(companionNamePrefix, 14),
                    "DOI TEN NPC MOI NHAT",
                    "TONG: " .. #companions .. " | DOAN XE: " .. convoyFollowDist .. "m"
                }
            elseif CurrentTab == "comp_mode" then
                rawItems = {
                    "DI NGANG HANG (SIDE)",
                    "DI THEO SAU (FOLLOW)",
                    "HANG DOC 1 COT (COLUMN)",
                    "BAO QUANH (CIRCLE)",
                    "HINH CHU V (V-FORMATION)",
                    "HINH MUI TEN (WEDGE)",
                    "DUNG YEN TAI CHO (HOLD)"
                }
            elseif CurrentTab == "comp_weapons" then
                rawItems = {
                    "CAP TAT CA VU KHI (ALL)",
                    "CAP VU KHI CAN CHIEN",
                    "CAP VU KHI SUNG",
                    "CLONE SUNG DANG CAM",
                    "THU HET VU KHI"
                }
            end
            local items = IsVehicleTab(CurrentTab) and BuildVehicleItems(rawItems) or rawItems
            local hasSearch = (CurrentTab == "noshop" or CurrentTab == "shop" or CurrentTab == "nganh")

            if #items > 0 then
                DrawText2D(CurrentMenu.Index .. " / " .. #items, 0, startX + menuWidth - 0.008, startY + 0.062, 0.33, 0, 170, 255, 255, true)
            end

            if hasSearch then
                local searchInfo = "SEARCH [G]: " .. TrimForMenu(SearchQuery ~= "" and SearchQuery or "ALL", 26)
                DrawRect(startX + (menuWidth/2), startY + 0.395, menuWidth, 0.028, 14, 14, 14, 235)
                DrawText2D(searchInfo, 0, startX + 0.008, startY + 0.383, 0.31, 150, 220, 255, 255, false)
            end

            if CurrentMenu.Index < CurrentMenu.FromIndex then
                CurrentMenu.FromIndex = CurrentMenu.Index
                CurrentMenu.ToIndex = CurrentMenu.Index + 9
            elseif CurrentMenu.Index > CurrentMenu.ToIndex then
                CurrentMenu.ToIndex = CurrentMenu.Index
                CurrentMenu.FromIndex = CurrentMenu.Index - 9
            end

            local pageCount = math.max(1, math.ceil(#items / 10))
            local currentPage = math.max(1, math.ceil(CurrentMenu.Index / 10))
            DrawText2D("PAGE " .. currentPage .. "/" .. pageCount, 0, startX + menuWidth - 0.035, startY + 0.383, 0.30, 170, 170, 170, 255, false)

            if #items == 0 then
                DrawRect(startX + (menuWidth/2), startY + 0.105, menuWidth, 0.035, 25, 25, 25, 220)
                if hasSearch and SearchQuery ~= "" then
                    DrawText2D("NO RESULT FOR: " .. TrimForMenu(SearchQuery, 16), 0, startX + 0.008, startY + 0.092, 0.33, 255, 85, 85, 255, false)
                else
                    DrawText2D("EMPTY LIST...", 0, startX + 0.008, startY + 0.092, 0.35, 255, 50, 50, 255, false)
                end
            else
                local displayCount = 1
                for k, v in ipairs(items) do
                    if k >= CurrentMenu.FromIndex and k <= CurrentMenu.ToIndex then
                        local isSelected = (CurrentMenu.Index == k)
                        local bgR, bgG, bgB, bgA = 22, 22, 22, 220
                        local txtR, txtG, txtB = 240, 240, 240
                        
                        if isSelected then
                            -- Selected style: light background + blue accent line
                            bgR, bgG, bgB, bgA = 245, 245, 245, 255
                            txtR, txtG, txtB = 0, 0, 0
                        end
                        
                        local itemY = startY + 0.075 + (displayCount * 0.032)
                        DrawRect(startX + (menuWidth/2), itemY, menuWidth, 0.03, bgR, bgG, bgB, bgA)
                        if isSelected then
                            DrawRect(startX + 0.0022, itemY, 0.0038, 0.03, 0, 140, 255, 255)
                        end

                        local label = v
                        if CurrentTab ~= "main" then
                            -- xe: không uppercase toàn bộ để tránh tràn + dễ đọc mã xe
                            label = TrimForMenu(label, 32)
                        else
                            label = TrimForMenu(tostring(label), 38)
                        end

                        DrawText2D(label, 0, startX + 0.008, itemY - 0.013, 0.35, txtR, txtG, txtB, 255, false)
                        
                        displayCount = displayCount + 1
                    end
                end
            end

            -- =========================================================================
            -- 6. KEYBOARD CONTROLS LOGIC
            -- =========================================================================
            if IsControlJustPressed(0, 173) then -- ARROW DOWN
                CurrentMenu.Index = CurrentMenu.Index + 1
                if CurrentMenu.Index > #items then 
                    CurrentMenu.Index = 1 
                    CurrentMenu.FromIndex = 1
                    CurrentMenu.ToIndex = 10
                end
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

            elseif IsControlJustPressed(0, 172) then -- ARROW UP
                CurrentMenu.Index = CurrentMenu.Index - 1
                if CurrentMenu.Index < 1 then 
                    CurrentMenu.Index = #items 
                    CurrentMenu.ToIndex = #items
                    CurrentMenu.FromIndex = #items - 9
                    if CurrentMenu.FromIndex < 1 then CurrentMenu.FromIndex = 1 end
                end
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

            elseif IsControlJustPressed(0, 177) then -- BACKSPACE
                PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                if CurrentTab == "main" then
                    RageUI.Visible(MainMenu, false)
                    RageUI.Visible(SubMenuNoShop, false)
                    RageUI.Visible(SubMenuShop, false)
                    RageUI.Visible(SubMenuNganh, false)
                    RageUI.Visible(CompanionMenu, false)
                    RageUI.Visible(CompanionModeMenu, false)
                    RageUI.Visible(CompanionWeaponMenu, false)
                    CurrentMenu = nil
                elseif CurrentTab == "comp_main" then
                    RageUI.Visible(CompanionMenu, false)
                    RageUI.Visible(CompanionModeMenu, false)
                    RageUI.Visible(CompanionWeaponMenu, false)
                    CurrentMenu = nil
                elseif CurrentTab == "comp_mode" or CurrentTab == "comp_weapons" then
                    CurrentTab = "comp_main"
                    CurrentMenu = CompanionMenu
                    ResetMenuCursor(CurrentMenu)
                else
                    CurrentTab = "main"
                    CurrentMenu = MainMenu
                    SearchQuery = ""
                    ResetMenuCursor(CurrentMenu)
                end

            elseif IsControlJustPressed(0, 191) then -- ENTER
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
                if CurrentTab == "main" then
                    if CurrentMenu.Index == 1 then
                        CurrentTab = "noshop"
                        CurrentMenu = SubMenuNoShop
                    elseif CurrentMenu.Index == 2 then
                        CurrentTab = "shop"
                        CurrentMenu = SubMenuShop
                    elseif CurrentMenu.Index == 3 then 
                        CurrentTab = "nganh"
                        CurrentMenu = SubMenuNganh
                    end
                    SearchQuery = ""
                    ResetMenuCursor(CurrentMenu)
                elseif CurrentTab == "comp_main" then
                    if CurrentMenu.Index == 1 then
                        SpawnCombatNPC()
                    elseif CurrentMenu.Index == 2 then
                        local spawned = 0
                        for _ = 1, companionSpawnCount do
                            if SpawnCloneCompanion() then spawned = spawned + 1 end
                        end
                        TriggerEvent('chat:addMessage', { color = {0, 255, 200}, args = {"[DE TU]", "Da spawn " .. spawned .. " NPC."} })
                    elseif CurrentMenu.Index == 3 then
                        StartConvoySetup(false)
                    elseif CurrentMenu.Index == 4 then
                        StartConvoySetup(true)
                    elseif CurrentMenu.Index == 5 then
                        companionSpawnCount = math.max(1, companionSpawnCount - 1)
                    elseif CurrentMenu.Index == 6 then
                        companionSpawnCount = math.min(15, companionSpawnCount + 1)
                    elseif CurrentMenu.Index == 7 then
                        CurrentTab = "comp_mode"
                        CurrentMenu = CompanionModeMenu
                        ResetMenuCursor(CurrentMenu)
                    elseif CurrentMenu.Index == 8 then
                        CurrentTab = "comp_weapons"
                        CurrentMenu = CompanionWeaponMenu
                        ResetMenuCursor(CurrentMenu)
                    elseif CurrentMenu.Index == 9 then
                        TeleportCompanionsToMe()
                    elseif CurrentMenu.Index == 10 then
                        SetConvoySirens(not convoySirenOn)
                    elseif CurrentMenu.Index == 11 then
                        convoyFollowDist = math.min(30.0, convoyFollowDist + 2.0)
                    elseif CurrentMenu.Index == 12 then
                        convoyFollowDist = math.max(6.0, convoyFollowDist - 2.0)
                    elseif CurrentMenu.Index == 13 then
                        companionInvincible = not companionInvincible
                    elseif CurrentMenu.Index == 14 then
                        RemoveCompanionAt(#companions)
                    elseif CurrentMenu.Index == 15 then
                        RemoveAllCompanions()
                    elseif CurrentMenu.Index == 16 then
                        showCompanionNames = not showCompanionNames
                    elseif CurrentMenu.Index == 17 then
                        ForceReleaseInput()
                        CloseAllMenus()
                        TriggerEvent('chat:addMessage', { color = {0, 255, 200}, args = {"[DE TU]", "Go chat: /detuprefix [ten]  VD: /detuprefix Ban Gai"} })
                    elseif CurrentMenu.Index == 18 then
                        ForceReleaseInput()
                        CloseAllMenus()
                        TriggerEvent('chat:addMessage', { color = {0, 255, 200}, args = {"[DE TU]", "Go chat: /detuten [ten rieng]  (NPC moi nhat)"} })
                    end
                elseif CurrentTab == "comp_mode" then
                    local modes = {"side", "follow", "column", "circle", "vformation", "wedge", "hold"}
                    companionMode = modes[CurrentMenu.Index] or "side"
                    CurrentTab = "comp_main"
                    CurrentMenu = CompanionMenu
                    ResetMenuCursor(CurrentMenu)
                elseif CurrentTab == "comp_weapons" then
                    if CurrentMenu.Index == 1 then
                        local all = {}
                        for _, w in ipairs(WEAPON_MELEE) do table.insert(all, w) end
                        for _, w in ipairs(WEAPON_GUNS) do table.insert(all, w) end
                        GiveWeaponSetToCompanions(all)
                    elseif CurrentMenu.Index == 2 then
                        GiveWeaponSetToCompanions(WEAPON_MELEE)
                    elseif CurrentMenu.Index == 3 then
                        GiveWeaponSetToCompanions(WEAPON_GUNS)
                    elseif CurrentMenu.Index == 4 then
                        GiveMyWeaponToCompanions()
                    elseif CurrentMenu.Index == 5 then
                        for _, data in ipairs(companions) do
                            if IsPedUsable(data.ped) then RemoveAllPedWeapons(data.ped, true) end
                        end
                    end
                    CurrentTab = "comp_main"
                    CurrentMenu = CompanionMenu
                    ResetMenuCursor(CurrentMenu)
                else
                    local selectedVehicle = items[CurrentMenu.Index]
                    if selectedVehicle and selectedVehicle ~= "" then
                        SpawnVipVehicle(NormalizeVehicleCode(selectedVehicle))
                    end
                end
            elseif CurrentTab ~= "main" and IsControlJustPressed(0, 47) then -- G
                local typed = OpenKeyboardInput("SEARCH MODEL (LEAVE EMPTY = ALL)", SearchQuery, 30)
                if typed ~= nil then
                    SearchQuery = typed
                    ResetMenuCursor(CurrentMenu)
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ForceReleaseInput()
    RemoveAllCompanions()
    RemoveAllCombatNPCs()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ForceReleaseInput()
    local playerPed = PlayerPedId()
    SetEntityMaxHealth(playerPed, 200)
    SetEntityHealth(playerPed, 200)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        if #combatNpcs > 0 then
            SetEntityMaxHealth(playerPed, 200)
            if GetEntityHealth(playerPed) > 0 and not IsEntityDead(playerPed) then
                SetPedArmour(playerPed, 50)
                RefillAmmo(playerPed)
            end
        else
            SetEntityMaxHealth(playerPed, 200)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        for i = #combatNpcs, 1, -1 do
            local data = combatNpcs[i]
            if not data or not IsPedUsable(data.ped) or IsEntityDead(data.ped) then
                if data and DoesEntityExist(data.ped) then
                    SetEntityAsMissionEntity(data.ped, true, true)
                    DeletePed(data.ped)
                end
                table.remove(combatNpcs, i)
            else
                local npc = data.ped
                local npcCoords = GetEntityCoords(npc)
                local dist = #(playerCoords - npcCoords)
                if GetSelectedPedWeapon(npc) == GetHashKey("WEAPON_UNARMED") then
                    GiveWeaponToPed(npc, GetHashKey(data.weapon), 9999, false, true)
                    SetCurrentPedWeapon(npc, GetHashKey(data.weapon), true)
                end
                SetCombatPedDefaults(npc)
                if dist > 10.0 or not HasEntityClearLosToEntity(npc, playerPed, 17) then
                    TaskGoToEntity(npc, playerPed, -1, 4.0, 4.0, 1073741824.0, 0)
                else
                    TaskCombatPed(npc, playerPed, 0, 16)
                end
                SetPedKeepTask(npc, true)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local playerPed = PlayerPedId()
        local currentHealth = GetEntityHealth(playerPed)
        
        if #combatNpcs > 0 then
            if currentHealth <= 0 or IsEntityDead(playerPed) then
                RemoveAllCombatNPCs()
            else
                playerLastHealth = currentHealth
            end
        end
    end
end)

-- =========================================================================
-- HEALTH BAR DISPLAY FOR TARGETED NPC
-- =========================================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        
        if #combatNpcs > 0 then
            local targetEntity = GetPlayerTargetEntity(PlayerId())
            if targetEntity ~= 0 then
                for _, npc in ipairs(combatNpcs) do
                    if DoesEntityExist(npc) and npc == targetEntity then
                        DrawHealthBar3D(npc, COMBAT_NPC_HEALTH)
                        break
                    end
                end
            end
        end
    end
end)

-- =========================================================================
-- 7. VÒNG LẶP HÀNH QUYẾT TRAFFIC NPC MẶC ĐỊNH
-- =========================================================================
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        SetVehicleDensityMultiplierThisFrame(0.0)
        SetRandomVehicleDensityMultiplierThisFrame(0.0)
        SetParkedVehicleDensityMultiplierThisFrame(0.0)
        SetPedDensityMultiplierThisFrame(0.0)
        SetScenarioPedDensityMultiplierThisFrame(0.0)

        local handle, ped = FindFirstPed()
        local success
        repeat
            if DoesEntityExist(ped) then
                if not IsPedAPlayer(ped) and not IsEntityAMissionEntity(ped) then
                    SetEntityAsMissionEntity(ped, true, true)
                    DeletePed(ped)
                end
            end
            success, ped = FindNextPed(handle)
        until not success
        EndFindPed(handle)

        local vHandle, vehicle = FindFirstVehicle()
        local vSuccess
        repeat
            if DoesEntityExist(vehicle) then
                if not IsEntityAMissionEntity(vehicle) then
                    local hasPlayer = false
                    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                        if IsPedAPlayer(GetPedInVehicleSeat(vehicle, i)) then
                            hasPlayer = true
                            break
                        end
                    end
                    if not hasPlayer then
                        SetEntityAsMissionEntity(vehicle, true, true)
                        DeleteVehicle(vehicle)
                    end
                end
            end
            vSuccess, vehicle = FindNextVehicle(vHandle)
        until not vSuccess
        EndFindVehicle(vHandle)
    end
end)

-- Fix God Mode getting stuck when disabled in vMenu (M key)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerId = PlayerId()
        local playerPed = PlayerPedId()
        if not GetPlayerInvincible(playerId) then
            -- If player is not invincible in player container state, but ped is still invincible, clear it
            SetEntityInvincible(playerPed, false)
        end
    end
end)
Config = Config or {}

print("^2[XMenu] Client script loaded successfully!^7")

local MAX_GROUPS = 20
local spawnedNPCs = {}
local spawnedVehicles = {}
local npcOriginalPositions = {} -- Store original spawn positions
local npcGroups = {}            -- maps npc entity -> group name
local groupRelationships = {}   -- maps group name -> relationship behavior
for i = 1, MAX_GROUPS do
    groupRelationships["group" .. i] = "friendly"
end
local groupHashes = {}
local selectedGroup = "all"
local isMenuOpen = false
local menuAnimationProgress = 0

-- Helper Functions
-- Helper Functions

-- Menu Toggle Function
function ToggleMenu()
    isMenuOpen = not isMenuOpen
    print("[XMenu] ToggleMenu called. New state (isMenuOpen):", isMenuOpen)
    if isMenuOpen then
        UpdateNPCCounts()
    end
    SendNUIMessage({
        type = 'toggleMenu',
        visible = isMenuOpen
    })
    SetNuiFocus(isMenuOpen, isMenuOpen)
end

-- Update counts of NPCs in NUI
function UpdateNPCCounts()
    local total = 0
    local groupCounts = {}
    for i = 1, MAX_GROUPS do
        groupCounts["group" .. i] = 0
    end
    
    -- Clean up dead or deleted NPCs first
    for i = #spawnedNPCs, 1, -1 do
        local npc = spawnedNPCs[i]
        if not IsPedUsable(npc) then
            npcOriginalPositions[npc] = nil
            npcGroups[npc] = nil
            table.remove(spawnedNPCs, i)
        end
    end
    
    for _, npc in ipairs(spawnedNPCs) do
        local g = npcGroups[npc]
        if g and groupCounts[g] ~= nil then
            groupCounts[g] = groupCounts[g] + 1
            total = total + 1
        end
    end
    
    SendNUIMessage({
        type = 'updateNPCCounts',
        total = total,
        groupCounts = groupCounts
    })
end

-- Get targets filtered by group
function GetTargetNPCs(groupName)
    if not groupName or groupName == "all" then
        return spawnedNPCs
    end
    local targets = {}
    for _, npc in ipairs(spawnedNPCs) do
        if IsPedUsable(npc) and npcGroups[npc] == groupName then
            table.insert(targets, npc)
        end
    end
    return targets
end

-- Dynamic relationships update
function UpdateRelationships()
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return end
    local playerGroup = GetPedRelationshipGroupHash(playerPed)
    
    local groupKeys = {}
    for i = 1, MAX_GROUPS do
        table.insert(groupKeys, "group" .. i)
    end
    
    for i, g1 in ipairs(groupKeys) do
        local hash1 = groupHashes[g1]
        local rel1 = groupRelationships[g1]
        
        if hash1 then
            -- Relation to Player
            if rel1 == "friendly" or rel1 == "hostile_other" then
                SetRelationshipBetweenGroups(0, hash1, playerGroup) -- Companion
                SetRelationshipBetweenGroups(0, playerGroup, hash1)
            elseif rel1 == "neutral" then
                SetRelationshipBetweenGroups(3, hash1, playerGroup) -- Neutral
                SetRelationshipBetweenGroups(3, playerGroup, hash1)
            elseif rel1 == "hostile_player" then
                SetRelationshipBetweenGroups(5, hash1, playerGroup) -- Hate
                SetRelationshipBetweenGroups(5, playerGroup, hash1)
            end
            
            -- Relation to other groups
            for j, g2 in ipairs(groupKeys) do
                if i ~= j then
                    local hash2 = groupHashes[g2]
                    local rel2 = groupRelationships[g2]
                    
                    if hash2 then
                        if rel1 == "neutral" or rel2 == "neutral" then
                            SetRelationshipBetweenGroups(3, hash1, hash2)
                        elseif rel1 == "friendly" and rel2 == "friendly" then
                            SetRelationshipBetweenGroups(0, hash1, hash2)
                        elseif rel1 == "hostile_player" or rel2 == "hostile_player" then
                            SetRelationshipBetweenGroups(5, hash1, hash2)
                        elseif rel1 == "hostile_other" or rel2 == "hostile_other" then
                            SetRelationshipBetweenGroups(5, hash1, hash2)
                        else
                            SetRelationshipBetweenGroups(3, hash1, hash2)
                        end
                    end
                end
            end
        end
    end
end

-- Initialize custom relationship groups (up to MAX_GROUPS)
Citizen.CreateThread(function()
    for i = 1, MAX_GROUPS do
        local groupName = "XMENU_GROUP_" .. i
        local _, hash = AddRelationshipGroup(groupName)
        groupHashes["group" .. i] = hash
    end
end)

-- Draw 3D Markers above head of selected group
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isMenuOpen and selectedGroup ~= "all" then
            local targets = GetTargetNPCs(selectedGroup)
            for _, npc in ipairs(targets) do
                if IsPedUsable(npc) then
                    local coords = GetEntityCoords(npc)
                    DrawMarker(0, coords.x, coords.y, coords.z + 1.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 165, 0, 150, false, true, 2, nil, nil, false)
                end
            end
        end
    end
end)

-- Periodically clean up dead NPCs and update counts
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        UpdateNPCCounts()
    end
end)

function DrawText2D(text, font, x, y, scale, r, g, b, a, center)
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

function ShowNotification(text)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function IsPedUsable(ped)
    return ped and ped ~= 0 and DoesEntityExist(ped) and not IsEntityDead(ped)
end

function LoadModel(hash)
    if not IsModelInCdimage(hash) then return false end
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 500 do -- Tăng giới hạn timeout lên 5 giây
        Citizen.Wait(10)
        t = t + 1
    end
    return HasModelLoaded(hash)
end

function LoadAnimDict(dict)
    if not DoesAnimDictExist(dict) then return false end
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 500 do -- Tăng giới hạn timeout lên 5 giây
        Citizen.Wait(10)
        t = t + 1
    end
    return HasAnimDictLoaded(dict)
end

-- NPC Spawn Functions
function SpawnNPCs(count, direction, groupName, relationship)
    groupName = groupName or "group1"
    relationship = relationship or "friendly"
    direction = direction or Config.SpawnDirection
    local playerPed = PlayerPedId()
    
    if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then
        ShowNotification("~r~Loi: Player ped khong hop le!")
        return
    end
    
    groupRelationships[groupName] = relationship
    UpdateRelationships()
    
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    local playerModel = GetEntityModel(playerPed)
    
    if not LoadModel(playerModel) then
        ShowNotification("~r~Loi: Khong the load player model!")
        return
    end
    
    -- Clone player appearance 
    local playerDrawable = {}
    local playerTexture = {}
    local playerPalette = {}
    for i = 0, 11 do
        playerDrawable[i] = GetPedDrawableVariation(playerPed, i) or 0
        playerTexture[i] = GetPedTextureVariation(playerPed, i) or 0
        playerPalette[i] = GetPedPaletteVariation(playerPed, i) or 0
    end
    
    local playerProps = {}
    for i = 0, 9 do
        playerProps[i] = {
            drawable = GetPedPropIndex(playerPed, i),
            texture = GetPedPropTextureIndex(playerPed, i)
        }
    end
    
    local spawnCount = math.min(count, Config.MaxNPCs or 100)
    local spawned = 0
    
    for i = 0, spawnCount - 1 do
        local spawnHeading = playerHeading
        local spawnX, spawnY, spawnZ
        
        if direction == "horizontal" then
            local offset = (i + 1.0) * (Config.SpawnDistance or 1.5)
            local offsetCoords = GetOffsetFromEntityInWorldCoords(playerPed, offset, 0.0, 0.0)
            spawnX, spawnY, spawnZ = offsetCoords.x, offsetCoords.y, offsetCoords.z
            spawnHeading = playerHeading -- Cùng hướng với người chơi
        else
            local offset = (i + 1.0) * (Config.SpawnDistance or 1.5)
            local offsetCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, offset, 0.0)
            spawnX, spawnY, spawnZ = offsetCoords.x, offsetCoords.y, offsetCoords.z
            spawnHeading = (playerHeading - 180.0) % 360.0 -- Quay mặt đối diện người chơi
        end
        
        local npc = CreatePed(4, playerModel, spawnX, spawnY, spawnZ, spawnHeading, true, true)
        
        if IsPedUsable(npc) then
            SetEntityAsMissionEntity(npc, true, true)
            SetBlockingOfNonTemporaryEvents(npc, true)
            SetPedFleeAttributes(npc, 0, false)
            SetPedCombatAttributes(npc, 46, true)
            SetPedCombatAttributes(npc, 17, true)
            
            local groupHash = groupHashes[groupName]
            if groupHash then
                SetPedRelationshipGroupHash(npc, groupHash)
            end
            npcGroups[npc] = groupName
            
            SetEntityMaxHealth(npc, Config.DefaultHealth or 200)
            SetEntityHealth(npc, Config.DefaultHealth or 200)
            SetPedArmour(npc, Config.DefaultArmor or 0)
            
            -- Apply ngoại hình
            for j = 0, 11 do
                SetPedComponentVariation(npc, j, playerDrawable[j], playerTexture[j], playerPalette[j])
            end
            
            for j = 0, 9 do
                if playerProps[j].drawable ~= -1 then
                    SetPedPropIndex(npc, j, playerProps[j].drawable, playerProps[j].texture, true)
                end
            end
            
            -- FIX LỖI SAI HƯỚNG: Ép buộc cập nhật lại góc xoay chuẩn xác sau khi gán ngoại hình
            SetEntityHeading(npc, spawnHeading)
            SetGameplayPedHint(npc, 0.0, 0.0, 0.0, 1, 1, 1, 1) 
            
            npcOriginalPositions[npc] = {
                x = spawnX, y = spawnY, z = spawnZ, heading = spawnHeading
            }
            
            table.insert(spawnedNPCs, npc)
            spawned = spawned + 1
        else
            if npc and npc ~= 0 then DeletePed(npc) end
        end
    end
    
    local num = groupName:gsub("group", "")
    ShowNotification("~g~Da spawn " .. spawned .. " NPC cho Nhom " .. num .. "!")
    UpdateNPCCounts()
end

-- Apply Emoji Code to Selected NPCs
function ApplyEmojiCode(emojiCode, group)
    if not emojiCode or emojiCode == "" then
        ShowNotification("~r~Loi: Emoji code khong hop le!")
        return
    end
    
    local targets = GetTargetNPCs(group)
    if #targets == 0 then
        ShowNotification("~w~Khong co NPC nao de ap dung emoji!")
        return
    end
    
    local commonEmotes = {
        ["smoke"] = "WORLD_HUMAN_SMOKING",
        ["cop2"] = "WORLD_HUMAN_SECURITY_GUARD",
        ["sit"] = "WORLD_HUMAN_SEAT_STEPS",
        ["party"] = "WORLD_HUMAN_PARTYING",
        ["cheer"] = "WORLD_HUMAN_CHEERING",
        ["drink"] = "WORLD_HUMAN_DRINKING",
        ["yoga"] = "WORLD_HUMAN_YOGA",
        ["lean"] = "WORLD_HUMAN_LEANING"
    }
    
    if commonEmotes[string.lower(emojiCode)] then
        ApplyScenarioToAll(commonEmotes[string.lower(emojiCode)], group)
        return
    end
    
    -- Xóa các task cũ
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            ClearPedTasks(npc)
        end
    end
    
    local animDicts = {
        "anim@mp_player_intcelebrationmale@" .. emojiCode,
        "anim@mp_player_intcelebrationfemale@" .. emojiCode,
        "anim@mp_player_intupper@" .. emojiCode,
        "anim@mp_player_intupper@" .. emojiCode .. "@a",
        "anim@mp_player_intselfie@" .. emojiCode,
        "anim@mp_player_intincar@" .. emojiCode,
        emojiCode
    }
    
    local animName = emojiCode
    
    -- Xử lý định dạng "dict,anim"
    if string.find(emojiCode, ",") then
        local parts = {}
        for part in string.gmatch(emojiCode, "([^,]+)") do
            table.insert(parts, part)
        end
        if #parts == 2 then
            animDicts = { parts[1] }
            animName = parts[2]
        end
    end
    
    -- FIX LỖI EMOTE KHÔNG CHẠY: Tạo luồng xử lý bất đồng bộ để chờ tải dữ liệu Animation hoàn tất
    Citizen.CreateThread(function()
        local loadedDict = nil
        
        for _, dict in ipairs(animDicts) do
            if LoadAnimDict(dict) then
                loadedDict = dict
                break
            end
        end
        
        if loadedDict then
            for _, npc in ipairs(targets) do
                if IsPedUsable(npc) then
                    TaskPlayAnim(npc, loadedDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
                end
            end
            ShowNotification("~g~Da apply emoji code cho nhom!")
        else
            ApplyScenarioToAll(emojiCode, group)
        end
    end)
end

-- Apply Scenario to Selected NPCs
function ApplyScenarioToAll(scenario, group)
    if not scenario or scenario == "" then
        ShowNotification("~r~Loi: Scenario khong hop le!")
        return
    end
    
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            ClearPedTasks(npc)
            Citizen.Wait(10)
            TaskStartScenarioInPlace(npc, scenario, 0, true)
        end
    end
    ShowNotification("~g~Da apply scenario cho nhom!")
end

-- Clear Scenarios for Selected NPCs
function ClearAllScenarios(group)
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            ClearPedTasks(npc)
        end
    end
    ShowNotification("~g~Da xoa kịch bản cho nhom!")
end

-- Give Weapon to Selected NPCs
function GiveWeaponToAll(weapon, skin, group)
    if not weapon or weapon == "" then
        ShowNotification("~r~Loi: Vu khi khong hop le!")
        return
    end
    
    local weaponHash = GetHashKey(weapon)
    local targets = GetTargetNPCs(group)
    
    Citizen.CreateThread(function()
        for _, npc in ipairs(targets) do
            if IsPedUsable(npc) then
                RemoveWeaponFromPed(npc, weaponHash)
                Citizen.Wait(50)
                GiveWeaponToPed(npc, weaponHash, 9999, true, true)
                
                if skin and skin ~= "" and skin ~= "default" then
                    local componentHash = GetHashKey(skin)
                    GiveWeaponComponentToPed(npc, weaponHash, componentHash)
                end
                
                SetCurrentPedWeapon(npc, weaponHash, true)
            end
        end
        ShowNotification("~g~Da cap vu khi va skin cho nhom!")
    end)
end

-- Remove All Weapons from Selected NPCs
function RemoveAllWeapons(group)
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            RemoveAllPedWeapons(npc, true)
        end
    end
    ShowNotification("~g~Da xoa tat ca vu khi cua nhom!")
end

-- Give Prop to Selected NPCs
function GivePropToAll(propModel, group)
    if not propModel or propModel == "" then
        ShowNotification("~r~Loi: Prop model khong hop le!")
        return
    end
    
    local propHash = GetHashKey(propModel)
    if not LoadModel(propHash) then
        ShowNotification("~r~Khong the load model!")
        return
    end
    
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            local prop = CreateObject(propHash, 0.0, 0.0, 0.0, true, true, true)
            if prop and prop ~= 0 then
                local boneIndex = GetPedBoneIndex(npc, 28422) -- Right hand bone index
                AttachEntityToEntity(prop, npc, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
            end
        end
    end
    ShowNotification("~g~Da gan prop cho nhom!")
end

-- Remove All Props from Selected NPCs
function RemoveAllProps(group)
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            for i = 0, 9 do
                SetPedPropIndex(npc, i, -1, 0, true)
            end
            
            local npcCoords = GetEntityCoords(npc)
            local objects = GetGamePool('CObject')
            for _, obj in ipairs(objects) do
                if DoesEntityExist(obj) then
                    local objCoords = GetEntityCoords(obj)
                    if #(npcCoords - objCoords) < 2.0 then
                        DetachEntity(obj, true, true)
                        SetEntityAsMissionEntity(obj, true, true)
                        DeleteObject(obj)
                    end
                end
            end
        end
    end
    ShowNotification("~g~Da xoa tat ca props cua nhom!")
end

-- Set Expression to Selected NPCs
function SetExpressionToAll(mood, group)
    if not mood or mood == "" then
        ShowNotification("~r~Loi: Mood khong hop le!")
        return
    end
    
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            SetPedMood(npc, mood)
        end
    end
    ShowNotification("~g~Da set expression cho nhom!")
end

-- Delete Selected NPCs
function DeleteNPCs(groupName)
    local deleteCount = 0
    for i = #spawnedNPCs, 1, -1 do
        local npc = spawnedNPCs[i]
        if groupName == "all" or npcGroups[npc] == groupName then
            if DoesEntityExist(npc) then
                SetEntityAsMissionEntity(npc, true, true)
                DeletePed(npc)
            end
            npcOriginalPositions[npc] = nil
            npcGroups[npc] = nil
            table.remove(spawnedNPCs, i)
            deleteCount = deleteCount + 1
        end
    end
    
    if groupName == "all" then
        ShowNotification("~g~Da xoa tat ca NPC!")
    else
        local num = groupName:gsub("group", "")
        ShowNotification("~g~Da xoa NPC thuoc Nhom " .. num .. "! (" .. deleteCount .. ")")
    end
    UpdateNPCCounts()
end

-- Freeze/Unfreeze Selected NPCs
function FreezeAllNPCs(freeze, group)
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            FreezeEntityPosition(npc, freeze)
        end
    end
    local status = freeze and "dong bang" or "thao bang"
    ShowNotification("~g~Da " .. status .. " nhom!")
end

-- Set Invincible for Selected NPCs
function SetInvincibleAll(invincible, group)
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            SetEntityInvincible(npc, invincible)
        end
    end
    local status = invincible and "bat" or "tat"
    ShowNotification("~g~Da " .. status .. " bat kha xam pham cua nhom!")
end

-- Set Health for Selected NPCs
function SetHealthAll(health, group)
    if not health or health <= 0 then
        ShowNotification("~r~Loi: Gia tri mau khong hop le!")
        return
    end
    
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            SetEntityHealth(npc, health)
        end
    end
    ShowNotification("~g~Da set mau cho nhom: " .. health)
end

-- Follow Player Selected NPCs
function FollowPlayer(group)
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then
        ShowNotification("~r~Loi: Player ped khong hop le!")
        return
    end
    
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            ClearPedTasks(npc)
            TaskFollowToOffsetOfEntity(npc, playerPed, 0.0, 0.0, 0.0, 5.0, -1, 0.0, true)
        end
    end
    ShowNotification("~g~Nhom dang di theo ban!")
end

-- Stay Selected NPCs
function Stay(group)
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            ClearPedTasks(npc)
        end
    end
    ShowNotification("~g~Nhom dang dung yen!")
end

-- Follow Player with specific group (with configurable speed)
function FollowPlayerGroup(group, speed)
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then
        ShowNotification("~r~Loi: Player ped khong hop le!")
        return
    end
    
    speed = tonumber(speed) or 3.0
    local targets = GetTargetNPCs(group)
    if #targets == 0 then
        ShowNotification("~r~Khong co NPC nao trong nhom!")
        return
    end
    for i, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            ClearPedTasks(npc)
            -- Offset tung con NPC mot chut de khong chong len nhau
            local offsetX = (i % 3 - 1) * 1.0
            local offsetY = -math.floor((i - 1) / 3) * 1.5 - 1.5
            TaskFollowToOffsetOfEntity(npc, playerPed, offsetX, offsetY, 0.0, speed, -1, 1.0, true)
        end
    end
    local groupLabel = (group == "all") and "Tat ca" or ("Nhom " .. group:gsub("group", ""))
    ShowNotification("~g~" .. groupLabel .. " dang di theo ban! (toc do: " .. tostring(speed) .. ")")
end

-- Set Movement Clip (Dang di) for group
function SetMovementClipForGroup(group, clip)
    local targets = GetTargetNPCs(group)
    if #targets == 0 then
        ShowNotification("~r~Khong co NPC nao trong nhom!")
        return
    end
    
    local groupLabel = (group == "all") and "Tat ca" or ("Nhom " .. group:gsub("group", ""))
    
    -- Reset about default movement
    if clip == "reset" then
        for _, npc in ipairs(targets) do
            if IsPedUsable(npc) then
                ResetPedMovementClipset(npc, 0)
            end
        end
        ShowNotification("~g~Da reset dang di cho " .. groupLabel .. "!")
        return
    end
    
    -- Movement clip presets
    local clips = {
        ["walk_normal"]   = "move_m@generic",
        ["walk_casual"]   = "move_m@casual@f",
        ["walk_drunk"]    = "move_m@drunk@verydrunk",
        ["walk_swagger"]  = "move_m@swagger@",
        ["walk_gangster"] = "move_m@gangster@generic_2",
        ["walk_sexy"]     = "move_f@sexy@a",
        ["walk_injured"]  = "move_m@injured",
        ["walk_fat"]      = "move_m@fat@a",
        ["run_normal"]    = "move_m@hurrying@a",
        ["run_fast"]      = "move_m@sprint",
        ["walk_stealth"]  = "move_ped_crouched",
        ["walk_alien"]    = "move_m@alien",
    }
    
    local clipset = clips[clip] or clip
    
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            ResetPedMovementClipset(npc, 0)
            SetPedMovementClipset(npc, clipset, 0.25)
        end
    end
    ShowNotification("~g~Da doi dang di cho " .. groupLabel .. "!")
end

-- Helper function to apply driving style and task
function ApplyVehicleDriveTask(driver, vehicle, driveMode)
    if not DoesEntityExist(driver) or not DoesEntityExist(vehicle) then return end
    
    local playerPed = PlayerPedId()
    
    if driveMode == "follow" then
        local target = GetVehiclePedIsIn(playerPed, false)
        if target == 0 then target = playerPed end
        ClearPedTasks(driver)
        TaskVehicleFollow(driver, vehicle, target, 25.0, 786603, 10.0)
        
    elseif driveMode == "chaos" then
        ClearPedTasks(driver)
        TaskVehicleDriveWander(driver, vehicle, 40.0, 786469)
        
    elseif driveMode == "gps" then
        local blip = GetFirstBlipInfoId(8) -- 8 = Waypoint
        if DoesBlipExist(blip) then
            local coords = GetBlipInfoIdCoord(blip)
            ClearPedTasks(driver)
            TaskVehicleDriveToCoordLongrange(driver, vehicle, coords.x, coords.y, coords.z, 30.0, 786603, 10.0)
            ShowNotification("~g~Doan xe dang di chuyen theo GPS!")
        else
            ClearPedTasks(driver)
            TaskVehicleDriveWander(driver, vehicle, 20.0, 786603)
            ShowNotification("~y~Chua danh dau GPS, xe dang di lang thang!")
        end
        
    elseif driveMode == "race" then
        local blip = GetFirstBlipInfoId(8)
        ClearPedTasks(driver)
        if DoesBlipExist(blip) then
            local coords = GetBlipInfoIdCoord(blip)
            TaskVehicleDriveToCoordLongrange(driver, vehicle, coords.x, coords.y, coords.z, 60.0, 288, 5.0)
            ShowNotification("~g~Bat dau dua xe den diem GPS!")
        else
            local target = GetVehiclePedIsIn(playerPed, false)
            if target == 0 then target = playerPed end
            TaskVehicleFollow(driver, vehicle, target, 60.0, 288, 5.0)
            ShowNotification("~g~Bat dau dua theo xe ban!")
        end
    end
end

-- Spawn Vehicles
function SpawnVehicles(modelName, count, spacing, spawnNpc, driveMode, groupName)
    local vehicleHash = GetHashKey(modelName)
    if not IsModelInCdimage(vehicleHash) or not IsModelAVehicle(vehicleHash) then
        ShowNotification("~r~Loi: Model xe khong hop le!")
        return
    end
    
    if not LoadModel(vehicleHash) then
        ShowNotification("~r~Loi: Khong the load vehicle model!")
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    
    local spawnedCount = 0
    for i = 0, count - 1 do
        local offset = (i + 1.0) * spacing
        local offsetCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -offset, 0.0)
        
        local vehicle = CreateVehicle(vehicleHash, offsetCoords.x, offsetCoords.y, offsetCoords.z, playerHeading, true, true)
        if DoesEntityExist(vehicle) then
            SetEntityAsMissionEntity(vehicle, true, true)
            SetVehicleHasBeenOwnedByPlayer(vehicle, true)
            SetVehicleOnGroundProperly(vehicle)
            
            local driver = nil
            if spawnNpc then
                local pedModel = GetHashKey("s_m_m_security_01")
                if LoadModel(pedModel) then
                    driver = CreatePedInsideVehicle(vehicle, 26, pedModel, -1, true, true)
                    if DoesEntityExist(driver) then
                        SetEntityAsMissionEntity(driver, true, true)
                        SetBlockingOfNonTemporaryEvents(driver, true)
                        SetPedFleeAttributes(driver, 0, false)
                        SetPedCombatAttributes(driver, 46, true)
                        
                        local groupHash = groupHashes[groupName]
                        if groupHash then
                            SetPedRelationshipGroupHash(driver, groupHash)
                        end
                        
                        SetDriverAbility(driver, 1.0)
                        SetDriverAggressiveness(driver, 1.0)
                        
                        ApplyVehicleDriveTask(driver, vehicle, driveMode)
                    end
                end
            end
            
            table.insert(spawnedVehicles, {
                vehicle = vehicle,
                driver = driver,
                group = groupName
            })
            spawnedCount = spawnedCount + 1
        end
    end
    ShowNotification("~g~Da spawn " .. spawnedCount .. " xe cho Nhom " .. groupName:gsub("group", "") .. "!")
end

-- Delete Vehicles
function DeleteVehicles(groupName)
    local deleteCount = 0
    for i = #spawnedVehicles, 1, -1 do
        local entry = spawnedVehicles[i]
        if groupName == "all" or entry.group == groupName then
            if entry.driver and DoesEntityExist(entry.driver) then
                DeletePed(entry.driver)
            end
            if entry.vehicle and DoesEntityExist(entry.vehicle) then
                DeleteVehicle(entry.vehicle)
            end
            table.remove(spawnedVehicles, i)
            deleteCount = deleteCount + 1
        end
    end
    if groupName == "all" then
        ShowNotification("~g~Da xoa tat ca xe da spawn!")
    else
        local num = groupName:gsub("group", "")
        ShowNotification("~g~Da xoa " .. deleteCount .. " xe cua Nhom " .. num .. "!")
    end
end

-- Update Vehicle Driving Behavior
function UpdateVehicleBehavior(driveMode, groupName)
    local updateCount = 0
    for _, entry in ipairs(spawnedVehicles) do
        if groupName == "all" or entry.group == groupName then
            if entry.driver and DoesEntityExist(entry.driver) and entry.vehicle and DoesEntityExist(entry.vehicle) then
                ApplyVehicleDriveTask(entry.driver, entry.vehicle, driveMode)
                updateCount = updateCount + 1
            end
        end
    end
    ShowNotification("~g~Da cap nhat hanh vi cho " .. updateCount .. " xe!")
end

-- Quiet weapon giver for combat setup
function GiveWeaponToGroup(groupName, weapon, skin)
    if not weapon or weapon == "" or weapon == "default" then return end
    local weaponHash = GetHashKey(weapon)
    local targets = GetTargetNPCs(groupName)
    if #targets == 0 then return end
    
    Citizen.CreateThread(function()
        for _, npc in ipairs(targets) do
            if IsPedUsable(npc) then
                RemoveWeaponFromPed(npc, weaponHash)
                Citizen.Wait(10)
                -- Give weapon directly in hand (false = not hidden, true = force in hand)
                GiveWeaponToPed(npc, weaponHash, 9999, false, true)
                
                if skin and skin ~= "" and skin ~= "default" then
                    local componentHash = GetHashKey(skin)
                    GiveWeaponComponentToPed(npc, weaponHash, componentHash)
                end
                SetCurrentPedWeapon(npc, weaponHash, true)
            end
        end
    end)
end

-- Start Fight between two groups (moi nhom co weapon/skin rieng)
function StartFight(groupA, groupB, weaponA, skinA, weaponB, skinB)
    local playerPed = PlayerPedId()
    local hashA = (groupA == "player" and GetPedRelationshipGroupHash(playerPed) or groupHashes[groupA])
    local hashB = (groupB == "player" and GetPedRelationshipGroupHash(playerPed) or groupHashes[groupB])
    
    if not hashA or not hashB then
        ShowNotification("~r~Loi: Nhom khong hop le!")
        return
    end
    
    -- Equip weapons rieng cho tung nhom
    if groupA ~= "player" then
        GiveWeaponToGroup(groupA, weaponA, skinA)
    end
    if groupB ~= "player" then
        GiveWeaponToGroup(groupB, weaponB, skinB)
    end
    
    -- Set Hostile Relationship
    SetRelationshipBetweenGroups(5, hashA, hashB) -- Hate
    SetRelationshipBetweenGroups(5, hashB, hashA) -- Hate
    
    -- Also set hostile between NPC groups and player group if targeting player
    if groupA == "player" or groupB == "player" then
        local playerGroup = GetPedRelationshipGroupHash(playerPed)
        local npcGroup = groupA == "player" and groupHashes[groupB] or groupHashes[groupA]
        if npcGroup then
            SetRelationshipBetweenGroups(5, npcGroup, playerGroup)
            SetRelationshipBetweenGroups(5, playerGroup, npcGroup)
        end
    end
    
    -- Collect peds; for player group use actual player ped
    local pedsA = (groupA == "player") and {playerPed} or GetTargetNPCs(groupA)
    local pedsB = (groupB == "player") and {playerPed} or GetTargetNPCs(groupB)
    
    -- Apply aggressive combat attributes to NPC groups
    local function ApplyCombatAttribs(peds)
        for _, ped in ipairs(peds) do
            if IsPedUsable(ped) and ped ~= playerPed then
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetPedFleeAttributes(ped, 0, 0)
                SetPedCombatAttributes(ped, 46, true) -- BF_AlwaysFight
                SetPedCombatAttributes(ped, 5, true)  -- BF_CanUseCover
                SetPedCombatAttributes(ped, 16, true) -- BF_CanFightArmedPedsWhenNotArmed
                SetPedCombatAbility(ped, 2)           -- Professional
                SetPedCombatMovement(ped, 2)          -- Offensive
                SetPedCombatRange(ped, 2)             -- Far
                SetPedAlertness(ped, 3)               -- Alert
                SetPedAccuracy(ped, 80)               -- Good accuracy
            end
        end
    end
    
    if groupA ~= "player" then ApplyCombatAttribs(pedsA) end
    if groupB ~= "player" then ApplyCombatAttribs(pedsB) end
    
    Citizen.CreateThread(function()
        Citizen.Wait(300) -- Wait slightly for weapons to equip
        
        -- Group A attacks targets in Group B
        if groupA ~= "player" then
            for _, pedA in ipairs(pedsA) do
                if IsPedUsable(pedA) then
                    if groupB == "player" then
                        -- Attack player directly
                        ClearPedTasks(pedA)
                        TaskCombatPed(pedA, playerPed, 0, 16)
                    elseif #pedsB > 0 then
                        local target = pedsB[math.random(1, #pedsB)]
                        if IsPedUsable(target) then
                            ClearPedTasks(pedA)
                            TaskCombatPed(pedA, target, 0, 16)
                        end
                    end
                end
            end
        end
        
        -- Group B attacks targets in Group A
        if groupB ~= "player" then
            for _, pedB in ipairs(pedsB) do
                if IsPedUsable(pedB) then
                    if groupA == "player" then
                        -- Attack player directly
                        ClearPedTasks(pedB)
                        TaskCombatPed(pedB, playerPed, 0, 16)
                    elseif #pedsA > 0 then
                        local target = pedsA[math.random(1, #pedsA)]
                        if IsPedUsable(target) then
                            ClearPedTasks(pedB)
                            TaskCombatPed(pedB, target, 0, 16)
                        end
                    end
                end
            end
        end
    end)
    
    local nameA = groupA == "player" and "Player" or "Nhom " .. groupA:gsub("group", "")
    local nameB = groupB == "player" and "Player" or "Nhom " .. groupB:gsub("group", "")
    ShowNotification("~r~" .. nameA .. " va " .. nameB .. " dang tan cong nhau!")
end

-- Make Peace between two groups
function MakePeace(groupA, groupB)
    local hashA = (groupA == "player" and GetPedRelationshipGroupHash(PlayerPedId()) or groupHashes[groupA])
    local hashB = (groupB == "player" and GetPedRelationshipGroupHash(PlayerPedId()) or groupHashes[groupB])
    
    if not hashA or not hashB then
        ShowNotification("~r~Loi: Nhom khong hop le!")
        return
    end
    
    -- Reset relationship to neutral (3)
    SetRelationshipBetweenGroups(3, hashA, hashB)
    SetRelationshipBetweenGroups(3, hashB, hashA)
    
    -- Clear combat tasks
    local pedsA = GetTargetNPCs(groupA)
    local pedsB = GetTargetNPCs(groupB)
    
    for _, ped in ipairs(pedsA) do
        if IsPedUsable(ped) then
            ClearPedTasks(ped)
        end
    end
    for _, ped in ipairs(pedsB) do
        if IsPedUsable(ped) then
            ClearPedTasks(ped)
        end
    end
    
    local nameA = groupA == "player" and "Player" or "Nhom " .. groupA:gsub("group", "")
    local nameB = groupB == "player" and "Player" or "Nhom " .. groupB:gsub("group", "")
    ShowNotification("~g~Da giang hoa giua " .. nameA .. " va " .. nameB .. "!")
end

local CoupleAnims = {
    -- Lovers Pack (offset = 0.0, heading offset = 0.0)
    sit_on_lap = {
        dict = "lovers_couple_pack@anim",
        animA = "sit_on_lap_atc_full",
        animB = "sit_on_lap_vic_full"
    },
    sitseatedhug = {
        dict = "lovers_couple_pack@anim",
        animA = "sitseatedhug_m",
        animB = "sitseatedhug_f"
    },
    sitarmsaround = {
        dict = "lovers_couple_pack@anim",
        animA = "sitarmsaround_atc",
        animB = "sitarmsaround_vic"
    },
    navy_kiss = {
        dict = "lovers_couple_pack@anim",
        animA = "navy_kiss_atc",
        animB = "navy_kiss_vic"
    },
    hug_n_kiss = {
        dict = "lovers_couple_pack@anim",
        animA = "hug_n_kiss_atc",
        animB = "hug_n_kiss_vic"
    },
    hug = {
        dict = "lovers_couple_pack@anim",
        animA = "hug_atc",
        animB = "hug_vic"
    },
    back_rejection = {
        dict = "lovers_couple_pack@anim",
        animA = "back_rejection_atc",
        animB = "back_rejection_vic"
    },
    back_hug = {
        dict = "lovers_couple_pack@anim",
        animA = "back_hug_atc",
        animB = "back_hug_vic"
    },
    arms_around_shoulder = {
        dict = "lovers_couple_pack@anim",
        animA = "arms_around_shoulder_atc",
        animB = "arms_around_shoulder_vic"
    },
    
    -- Võ thuật & Đối kháng (Combat Emotes from rpemotes-reborn)
    heavyfinish = {
        dict = "melee@unarmed@streamed_core",
        animA = "heavy_punch_a",
        dictB = "melee@unarmed@streamed_variations",
        animB = "victim_takedown_front_cross_r",
        offset = 1.0
    },
    sidekick = {
        dict = "melee@unarmed@streamed_core",
        animA = "kick_close_a",
        dictB = "melee@unarmed@streamed_core",
        animB = "hit_counter_attack_r",
        offset = 1.1
    },
    counterattack = {
        dict = "melee@unarmed@streamed_core",
        animA = "hit_counter_attack_r",
        dictB = "melee@unarmed@streamed_core",
        animB = "melee_damage_left",
        offset = 1.0
    },
    backslap = {
        dict = "melee@unarmed@streamed_variations",
        animA = "plyr_takedown_front_backslap",
        dictB = "melee@unarmed@streamed_variations",
        animB = "victim_takedown_front_backslap",
        offset = 1.0
    },
    trainingspar = {
        dict = "melee@unarmed@streamed_core",
        animA = "idle",
        dictB = "melee@unarmed@streamed_core_fps",
        animB = "idle",
        offset = 1.2,
        loop = true
    },
    wingchun1 = {
        dict = "wing_chun@anim",
        animA = "paire_one_atc",
        dictB = "wing_chun@anim",
        animB = "paire_one_vic",
        offset = 0.95
    },
    wingchun2 = {
        dict = "wing_chun@anim",
        animA = "paire_two_atc",
        dictB = "wing_chun@anim",
        animB = "paire_two_vic",
        offset = 0.95
    },
    lowkick = {
        dict = "melee@unarmed@streamed_core",
        animA = "low_attack_0",
        dictB = "melee@unarmed@streamed_core",
        animB = "melee_damage_left",
        offset = 1.0
    },
    kickattack = {
        dict = "melee@unarmed@streamed_core",
        animA = "kick_close_a",
        dictB = "melee@unarmed@streamed_core",
        animB = "hit_counter_attack_l",
        offset = 1.05
    },
    hookpunch = {
        dict = "melee@unarmed@streamed_core",
        animA = "long_90_punch",
        dictB = "melee@unarmed@streamed_core",
        animB = "hit_counter_attack_r",
        offset = 1.0
    },
    spar = {
        dict = "melee@unarmed@streamed_core",
        animA = "heavy_punch_a",
        dictB = "melee@unarmed@streamed_core",
        animB = "hit_counter_attack_l",
        offset = 1.0
    },
    uppercutpunch = {
        dict = "melee@unarmed@streamed_core",
        animA = "long_0_punch",
        dictB = "melee@unarmed@streamed_core",
        animB = "melee_damage_left",
        offset = 1.0
    }
}

function PlayCoupleAnimation(pedA, pedB, animConfig)
    local dict = animConfig.dict
    local dictB = animConfig.dictB or dict
    
    Citizen.CreateThread(function()
        -- Load animation dictionaries
        RequestAnimDict(dict)
        if dictB ~= dict then
            RequestAnimDict(dictB)
        end
        
        local timeout = 0
        while (not HasAnimDictLoaded(dict) or not HasAnimDictLoaded(dictB)) and timeout < 200 do
            Citizen.Wait(10)
            timeout = timeout + 1
        end
        
        if not HasAnimDictLoaded(dict) or not HasAnimDictLoaded(dictB) then
            ShowNotification("~r~Loi: Khong the load animation dictionary!")
            return
        end
        
        -- Sync positions
        local coords = GetEntityCoords(pedA)
        local heading = GetEntityHeading(pedA)
        
        -- Clear tasks to prevent glitches
        ClearPedTasksImmediately(pedA)
        ClearPedTasksImmediately(pedB)
        
        -- Calculate target position for Ped B (the receiver/victim)
        local offset = animConfig.offset or 0.0
        local targetX = coords.x
        local targetY = coords.y
        local targetZ = coords.z
        
        if offset > 0.0 then
            local forward = GetEntityForwardVector(pedA)
            targetX = coords.x + forward.x * offset
            targetY = coords.y + forward.y * offset
        end
        
        -- Teleport Ped B and rotate to face Ped A (heading + 180 degrees)
        SetEntityCoords(pedB, targetX, targetY, targetZ, false, false, false, false)
        if offset > 0.0 then
            SetEntityHeading(pedB, heading + 180.0)
        else
            SetEntityHeading(pedB, heading)
        end
        
        -- Disable collision between the two peds so they don't push each other
        DisableEntityCollision(pedA, pedB, true)
        
        -- Wait a frame
        Citizen.Wait(50)
        
        -- Play animations looping
        TaskPlayAnim(pedA, dict, animConfig.animA, 8.0, -8.0, -1, 1, 0, false, false, false)
        TaskPlayAnim(pedB, dictB, animConfig.animB, 8.0, -8.0, -1, 1, 0, false, false, false)
    end)
end

-- Menu Toggle

-- Register Command and Key Mapping
RegisterCommand(Config.Command or "xmenu", function()
    ToggleMenu()
end, false)

RegisterKeyMapping(Config.Command or "xmenu", "Open NPC Spawn Menu", "keyboard", "o")

-- Key Handler (For closing menu or fallback)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isMenuOpen and (IsDisabledControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 200)) then
            isMenuOpen = false
            SendNUIMessage({ type = 'toggleMenu', visible = false })
            SetNuiFocus(false, false)
        end
    end
end)


-- NUI Callbacks
-- NUI Callbacks
RegisterNUICallback('toggleMenu', function(data, cb) ToggleMenu() cb({}) end)
RegisterNUICallback('spawnNPCs', function(data, cb) SpawnNPCs(tonumber(data.count), data.direction, data.group, data.relationship) cb({}) end)
RegisterNUICallback('applyEmojiCode', function(data, cb) ApplyEmojiCode(data.emojiCode, data.group) cb({}) end)
RegisterNUICallback('applyScenario', function(data, cb) ApplyScenarioToAll(data.scenario, data.group) cb({}) end)
RegisterNUICallback('clearScenarios', function(data, cb) ClearAllScenarios(data.group) cb({}) end)
RegisterNUICallback('giveWeapon', function(data, cb) GiveWeaponToAll(data.weapon, data.skin, data.group) cb({}) end)
RegisterNUICallback('removeWeapons', function(data, cb) RemoveAllWeapons(data.group) cb({}) end)
RegisterNUICallback('giveProp', function(data, cb) GivePropToAll(data.prop, data.group) cb({}) end)
RegisterNUICallback('removeProps', function(data, cb) RemoveAllProps(data.group) cb({}) end)
RegisterNUICallback('setExpression', function(data, cb) SetExpressionToAll(data.expression, data.group) cb({}) end)
RegisterNUICallback('deleteAllNPCs', function(data, cb) DeleteNPCs(data.group) cb({}) end)
RegisterNUICallback('freezeNPCs', function(data, cb) FreezeAllNPCs(data.freeze, data.group) cb({}) end)
RegisterNUICallback('setInvincible', function(data, cb) SetInvincibleAll(data.invincible, data.group) cb({}) end)
RegisterNUICallback('setHealth', function(data, cb) SetHealthAll(tonumber(data.health), data.group) cb({}) end)
RegisterNUICallback('followPlayer', function(data, cb) FollowPlayer(data.group) cb({}) end)
RegisterNUICallback('followPlayerGroup', function(data, cb) FollowPlayerGroup(data.group, data.speed) cb({}) end)
RegisterNUICallback('setMovementClip', function(data, cb) SetMovementClipForGroup(data.group, data.clip) cb({}) end)
RegisterNUICallback('stay', function(data, cb) Stay(data.group) cb({}) end)
RegisterNUICallback('closeMenu', function(data, cb) isMenuOpen = false SendNUIMessage({ type = 'toggleMenu', visible = false }) SetNuiFocus(false, false) cb({}) end)
RegisterNUICallback('changeActiveGroup', function(data, cb) selectedGroup = data.group cb({}) end)
RegisterNUICallback('spawnVehicles', function(data, cb) SpawnVehicles(data.model, tonumber(data.count), tonumber(data.distance), data.spawnNpc, data.driveMode, data.group) cb({}) end)
RegisterNUICallback('deleteVehicles', function(data, cb) DeleteVehicles(data.group) cb({}) end)
RegisterNUICallback('updateVehicleBehavior', function(data, cb) UpdateVehicleBehavior(data.driveMode, data.group) cb({}) end)
RegisterNUICallback('startFight', function(data, cb) StartFight(data.groupA, data.groupB, data.weaponA, data.skinA, data.weaponB, data.skinB) cb({}) end)
RegisterNUICallback('makePeace', function(data, cb) MakePeace(data.groupA, data.groupB) cb({}) end)

RegisterNUICallback('startCoupleAnim', function(data, cb)
    local groupA = data.groupA
    local groupB = data.groupB
    local animName = data.anim
    
    local animConfig = CoupleAnims[animName]
    if not animConfig then
        ShowNotification("~r~Loi: Dong tac khong ton tai!")
        cb({})
        return
    end
    
    local playerPed = PlayerPedId()
    local pedsA = (groupA == "player") and {playerPed} or GetTargetNPCs(groupA)
    local pedsB = (groupB == "player") and {playerPed} or GetTargetNPCs(groupB)
    
    if #pedsA == 0 or #pedsB == 0 then
        ShowNotification("~r~Khong tim thay Ped de thuc hien!")
        cb({})
        return
    end
    
    local count = math.min(#pedsA, #pedsB)
    for i = 1, count do
        local pedA = pedsA[i]
        local pedB = pedsB[i]
        if IsPedUsable(pedA) and IsPedUsable(pedB) then
            PlayCoupleAnimation(pedA, pedB, animConfig)
        end
    end
    
    ShowNotification("~g~Da bat dau dong tac cap doi!")
    cb({})
end)

RegisterNUICallback('stopCoupleAnim', function(data, cb)
    local groupA = data.groupA
    local groupB = data.groupB
    
    local playerPed = PlayerPedId()
    local pedsA = (groupA == "player") and {playerPed} or GetTargetNPCs(groupA)
    local pedsB = (groupB == "player") and {playerPed} or GetTargetNPCs(groupB)
    
    local count = math.min(#pedsA, #pedsB)
    for i = 1, count do
        local pedA = pedsA[i]
        local pedB = pedsB[i]
        if IsPedUsable(pedA) then 
            ClearPedTasks(pedA)
        end
        if IsPedUsable(pedB) then 
            ClearPedTasks(pedB)
            if IsPedUsable(pedA) then
                DisableEntityCollision(pedA, pedB, false)
            end
        end
    end
    
    ShowNotification("~w~Da dung dong tac cap doi!")
    cb({})
end)

-- Send config to NUI on resource start
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    if not Config then return end
    
    SendNUIMessage({
        type = 'initConfig',
        scenarios = Config.Scenarios or {},
        props = Config.Props or {},
        expressions = Config.Expressions or {},
        weapons = Config.Weapons or {},
        weaponSkins = Config.WeaponSkins or {},
        maxNPCs = Config.MaxNPCs or 100,
        defaultNPCCount = Config.DefaultNPCCount or 5
    })
    ShowNotification("~g~XMenu da san sang! Nhan F10 de mo menu")
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        DeleteNPCs("all")
        DeleteVehicles("all")
    end
end)
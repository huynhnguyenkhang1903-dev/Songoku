Config = Config or {}

print("^2[XMenu] Client script loaded successfully!^7")

local MAX_GROUPS = 20
local spawnedNPCs = {}
local spawnedVehicles = {}
local npcOriginalPositions = {} -- Store original spawn positions
local npcGroups = {}            -- maps npc entity -> group name
local npcFollowStates = {}      -- maps npc entity -> follow state
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
    
    -- Clean up deleted NPCs first (only if the entity no longer exists)
    for i = #spawnedNPCs, 1, -1 do
        local npc = spawnedNPCs[i]
        if not DoesEntityExist(npc) then
            npcOriginalPositions[npc] = nil
            npcGroups[npc] = nil
            table.remove(spawnedNPCs, i)
        end
    end
    
    for _, npc in ipairs(spawnedNPCs) do
        if IsPedUsable(npc) then
            local g = npcGroups[npc]
            if g and groupCounts[g] ~= nil then
                groupCounts[g] = groupCounts[g] + 1
                total = total + 1
            end
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
    local targets = {}
    for _, npc in ipairs(spawnedNPCs) do
        if IsPedUsable(npc) then
            if not groupName or groupName == "all" or npcGroups[npc] == groupName then
                table.insert(targets, npc)
            end
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
            SetPedCombatAttributes(npc, 5, true)   -- Always fight (CA_ALWAYS_FIGHT)
            SetPedCombatAttributes(npc, 17, false) -- Disable always flee (CA_ALWAYS_FLEE)
            
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
        ["cop"] = "WORLD_HUMAN_COP_IDLES",
        ["cop2"] = "WORLD_HUMAN_SECURITY_GUARD",
        ["guard"] = "WORLD_HUMAN_GUARD_STAND",
        ["guard2"] = "WORLD_HUMAN_SECURITY_GUARD",
        ["guard_patrol"] = "WORLD_HUMAN_GUARD_PATROL",
        ["torch"] = "WORLD_HUMAN_SECURITY_SHINE_TORCH",
        ["shoulder"] = "WORLD_HUMAN_SECURITY_SHOULDER",
        ["army"] = "WORLD_HUMAN_GUARD_STAND_ARMY",
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
                RemovePedFromGroup(npc)
                SetEntityAsMissionEntity(npc, true, true)
                DeletePed(npc)
                if DoesEntityExist(npc) then
                    DeleteEntity(npc)
                end
            end
            npcOriginalPositions[npc] = nil
            npcGroups[npc] = nil
            npcFollowStates[npc] = nil
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

local playerGroupId = nil

function GetOrCreatePlayerGroup()
    local playerPed = PlayerPedId()
    local grp = GetPedGroupIndex(playerPed)
    if grp == 0 or grp == -1 or not playerGroupId then
        playerGroupId = CreateGroup(0)
        SetPedAsGroupLeader(playerPed, playerGroupId)
        SetGroupFormation(playerGroupId, 3) -- Circle formation
        SetGroupFormationSpacing(playerGroupId, 1.5, 1.5, 3.0)
    end
    return playerGroupId
end

-- Follow Player Selected NPCs
function FollowPlayer(group)
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 or not DoesEntityExist(playerPed) then
        ShowNotification("~r~Loi: Player ped khong hop le!")
        return
    end
    
    local targets = GetTargetNPCs(group)
    local playerGroup = GetOrCreatePlayerGroup()
    
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            if IsPedInAnyVehicle(npc, false) then
                TaskLeaveAnyVehicle(npc, 0, 0)
            end
            npcFollowStates[npc] = { following = true, speed = 5.0 }
            
            local _, memberCount = GetGroupSize(playerGroup)
            if memberCount < 7 then
                SetPedAsGroupMember(npc, playerGroup)
                SetPedCombatAttributes(npc, 2, true)  -- Can fight armed peds when unarmed
                SetPedCombatAttributes(npc, 46, true) -- Always fight
                SetPedCombatRange(npc, 2)
                SetPedCombatAbility(npc, 2)
            else
                ClearPedTasksImmediately(npc)
                TaskFollowToOffsetOfEntity(npc, playerPed, 0.0, 0.0, 0.0, 5.0, -1, 3.0, true)
            end
        end
    end
    ShowNotification("~g~Nhom dang di theo ban!")
end

-- Stay Selected NPCs
function Stay(group)
    local targets = GetTargetNPCs(group)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            npcFollowStates[npc] = nil
            RemovePedFromGroup(npc)
            ClearPedTasksImmediately(npc)
        end
    end
    ShowNotification("~g~Nhom dang dung yen!")
end

-- NPC Auto-Board Nearest Vehicles
function NPCEnterNearestVehicles(group)
    local allNPCs = GetTargetNPCs(group)
    local targets = {}
    for _, npc in ipairs(allNPCs) do
        if not IsPedInAnyVehicle(npc, false) then
            table.insert(targets, npc)
        end
    end
    
    if #targets == 0 then
        ShowNotification("~r~Khong co NPC nao dang o ngoai xe!")
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    
    local nearbyVehicles = {}
    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) and not IsEntityDead(veh) then
            local coords = GetEntityCoords(veh)
            local dist = #(coords - playerCoords)
            if dist < 150.0 then
                table.insert(nearbyVehicles, { vehicle = veh, dist = dist })
            end
        end
    end

    if #nearbyVehicles == 0 then
        ShowNotification("~r~Khong tim thay xe nao trong ban kinh 150m!")
        return
    end

    table.sort(nearbyVehicles, function(a, b) return a.dist < b.dist end)

    local npcIndex = 1
    local numNpcs = #targets
    local boardedCount = 0

    -- Phase 1: Try to occupy all driver seats (-1) first
    for _, vehData in ipairs(nearbyVehicles) do
        if npcIndex > numNpcs then break end
        local veh = vehData.vehicle
        
        if IsVehicleSeatFree(veh, -1) then
            local npc = targets[npcIndex]
            ClearPedTasks(npc)
            TaskEnterVehicle(npc, veh, 20000, -1, 2.0, 1, 0)
            npcIndex = npcIndex + 1
            boardedCount = boardedCount + 1
        end
    end

    -- Phase 2: Occupy remaining empty passenger seats
    if npcIndex <= numNpcs then
        for _, vehData in ipairs(nearbyVehicles) do
            if npcIndex > numNpcs then break end
            local veh = vehData.vehicle
            local maxPassengers = GetVehicleMaxNumberOfPassengers(veh)
            
            for seat = 0, maxPassengers - 1 do
                if npcIndex > numNpcs then break end
                
                if IsVehicleSeatFree(veh, seat) then
                    local npc = targets[npcIndex]
                    ClearPedTasks(npc)
                    TaskEnterVehicle(npc, veh, 20000, seat, 2.0, 1, 0)
                    npcIndex = npcIndex + 1
                    boardedCount = boardedCount + 1
                end
            end
        end
    end

    if boardedCount > 0 then
        ShowNotification("~g~Da ra lenh cho " .. boardedCount .. " NPC di tim va len cac xe gan nhat!")
    else
        ShowNotification("~y~Tat ca cac xe gan day deu da day cho!")
    end
end

-- NPC Exit Vehicles & Equip Weapon
function NPCExitNearestVehicles(group, weaponName)
    local targets = GetTargetNPCs(group)
    if #targets == 0 then
        ShowNotification("~r~Khong co NPC nao trong nhom!")
        return
    end

    local weaponHash = GetHashKey(weaponName or "WEAPON_UNARMED")
    local exitedCount = 0

    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) and IsPedInAnyVehicle(npc, false) then
            ClearPedTasks(npc)
            TaskLeaveAnyVehicle(npc, 0, 0)
            
            -- Run a thread to wait until they exit, then give the weapon
            Citizen.CreateThread(function()
                local timeout = 0
                while IsPedInAnyVehicle(npc, false) and timeout < 100 do -- up to 10 seconds
                    Citizen.Wait(100)
                    timeout = timeout + 1
                end
                Citizen.Wait(500) -- Split second for safety
                if IsPedUsable(npc) then
                    if weaponHash ~= GetHashKey("WEAPON_UNARMED") then
                        GiveWeaponToPed(npc, weaponHash, 9999, false, true)
                        SetCurrentPedWeapon(npc, weaponHash, true)
                    else
                        RemoveAllPedWeapons(npc, true)
                    end
                end
            end)
            
            exitedCount = exitedCount + 1
        end
    end
    
    if exitedCount > 0 then
        ShowNotification("~g~Da ra lenh cho " .. exitedCount .. " NPC xuong xe!")
    else
        ShowNotification("~y~Khong co NPC nao trong nhom dang o trong xe!")
    end
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
    
    print(string.format("[XMenu] FollowPlayerGroup: group=%s, speed=%f, targets=%d", tostring(group), speed, #targets))
    
    if #targets == 0 then
        ShowNotification("~r~Khong co NPC nao trong nhom!")
        return
    end
    
    local playerGroup = GetOrCreatePlayerGroup()
    
    for i, npc in ipairs(targets) do
        if IsPedUsable(npc) then
            if IsPedInAnyVehicle(npc, false) then
                TaskLeaveAnyVehicle(npc, 0, 0)
            end
            
            npcFollowStates[npc] = { following = true, speed = speed }
            
            local _, memberCount = GetGroupSize(playerGroup)
            if memberCount < 7 then
                SetPedAsGroupMember(npc, playerGroup)
                SetPedCombatAttributes(npc, 2, true)  -- Can fight armed peds when unarmed
                SetPedCombatAttributes(npc, 46, true) -- Always fight
                SetPedCombatRange(npc, 2)
                SetPedCombatAbility(npc, 2)
            else
                Citizen.CreateThread(function()
                    if IsPedInAnyVehicle(npc, false) then
                        local timeout = 0
                        while IsPedInAnyVehicle(npc, false) and timeout < 100 do
                            Citizen.Wait(100)
                            timeout = timeout + 1
                        end
                        Citizen.Wait(500)
                    end
                    
                    if IsPedUsable(npc) and npcFollowStates[npc] and npcFollowStates[npc].following then
                        ClearPedTasksImmediately(npc)
                        -- Use 0.0 offset and 3.0m stopping range to prevent getting stuck on walls/trees
                        TaskFollowToOffsetOfEntity(npc, playerPed, 0.0, 0.0, 0.0, speed, -1, 3.0, true)
                    end
                end)
            end
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
    
    -- Ensure the vehicle is ready to drive (forces engine ON and releases handbrake)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleHandbrake(vehicle, false)
    
    -- Set driver attributes for boarded NPCs as well
    SetDriverAbility(driver, 1.0)
    SetDriverAggressiveness(driver, 1.0)
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedFleeAttributes(driver, 0, false)
    SetPedCombatAttributes(driver, 46, true)
    
    print(string.format("[XMenu] ApplyVehicleDriveTask: driver=%s, vehicle=%s, driveMode=%s", tostring(driver), tostring(vehicle), tostring(driveMode)))
    
    if driveMode == "follow" then
        ClearPedTasks(driver)
        TaskVehicleMissionPedTarget(driver, vehicle, playerPed, 7, 25.0, 786603, 6.0, 0.0, true)
        
    elseif driveMode == "follow_player" then
        ClearPedTasks(driver)
        TaskVehicleMissionPedTarget(driver, vehicle, playerPed, 7, 30.0, 786603, 6.0, 0.0, true)



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
function SpawnVehicles(modelName, count, spacing, spawnNpc, driveMode, groupName, color1, color2)
    local vehicleHash = GetHashKey(modelName)
    if not IsModelInCdimage(vehicleHash) or not IsModelAVehicle(vehicleHash) then
        ShowNotification("~r~Loi: Model xe khong hop le!")
        return
    end
    
    if not LoadModel(vehicleHash) then
        ShowNotification("~r~Loi: Khong the load vehicle model!")
        return
    end

    color1 = tonumber(color1) or 0
    color2 = tonumber(color2) or 0
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    local playerModel = GetEntityModel(playerPed)
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
    
    local spawnedCount = 0
    for i = 0, count - 1 do
        local offset = (i + 1.0) * spacing
        local offsetCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -offset, 0.0)
        
        local vehicle = CreateVehicle(vehicleHash, offsetCoords.x, offsetCoords.y, offsetCoords.z, playerHeading, true, true)
        if DoesEntityExist(vehicle) then
            SetEntityAsMissionEntity(vehicle, true, true)
            SetVehicleHasBeenOwnedByPlayer(vehicle, true)
            SetVehicleOnGroundProperly(vehicle)
            SetVehicleColours(vehicle, color1, color2)
            
            local driver = nil
            if spawnNpc then
                if LoadModel(playerModel) then
                    driver = CreatePed(26, playerModel, offsetCoords.x, offsetCoords.y, offsetCoords.z, playerHeading, true, true)
                    if DoesEntityExist(driver) then
                        SetEntityAsMissionEntity(driver, true, true)
                        SetBlockingOfNonTemporaryEvents(driver, true)
                        SetPedFleeAttributes(driver, 0, false)
                        SetPedCombatAttributes(driver, 46, true)
                        
                        for j = 0, 11 do
                            SetPedComponentVariation(driver, j, playerDrawable[j], playerTexture[j], playerPalette[j])
                        end
                        for j = 0, 9 do
                            if playerProps[j].drawable ~= -1 then
                                SetPedPropIndex(driver, j, playerProps[j].drawable, playerProps[j].texture, true)
                            end
                        end
                        
                        local groupHash = groupHashes[groupName]
                        if groupHash then
                            SetPedRelationshipGroupHash(driver, groupHash)
                        end
                        
                        SetDriverAbility(driver, 1.0)
                        SetDriverAggressiveness(driver, 1.0)
                        
                        npcGroups[driver] = groupName
                        table.insert(spawnedNPCs, driver)
                        
                        ApplyVehicleDriveTask(driver, vehicle, driveMode)
                        
                        -- Warp driver into vehicle after applying tasks to prevent task cancellation/ejection
                        SetPedIntoVehicle(driver, vehicle, -1)
                    end
                end
            end
            
            table.insert(spawnedVehicles, {
                vehicle = vehicle,
                driver = driver,
                lastDriver = driver,
                group = groupName,
                driveMode = driveMode,
                spacing = spacing
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
            local currentDriver = entry.vehicle and DoesEntityExist(entry.vehicle) and GetPedInVehicleSeat(entry.vehicle, -1) or entry.driver
            if currentDriver and DoesEntityExist(currentDriver) then
                DeletePed(currentDriver)
            end
            if entry.driver and DoesEntityExist(entry.driver) and entry.driver ~= currentDriver then
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
    
    -- 1. Update existing spawned vehicles
    for _, entry in ipairs(spawnedVehicles) do
        if groupName == "all" or entry.group == groupName then
            entry.driveMode = driveMode
            entry.aligned = false -- Reset aligned state when behavior is updated
            
            if entry.vehicle and DoesEntityExist(entry.vehicle) then
                local currentDriver = GetPedInVehicleSeat(entry.vehicle, -1)
                if currentDriver and currentDriver ~= 0 and currentDriver ~= PlayerPedId() and DoesEntityExist(currentDriver) then
                    ApplyVehicleDriveTask(currentDriver, entry.vehicle, driveMode)
                    entry.driver = currentDriver
                    entry.lastDriver = currentDriver
                end
                updateCount = updateCount + 1
            end
        end
    end
    
    -- 2. Dynamically find any NPCs of this group driving other vehicles and register them
    local targets = GetTargetNPCs(groupName)
    for _, npc in ipairs(targets) do
        if IsPedUsable(npc) and IsPedInAnyVehicle(npc, false) then
            local vehicle = GetVehiclePedIsIn(npc, false)
            if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == npc then
                -- Check if this vehicle is already in spawnedVehicles
                local alreadyTracked = false
                for _, entry in ipairs(spawnedVehicles) do
                    if entry.vehicle == vehicle then
                        alreadyTracked = true
                        break
                    end
                end
                
                if not alreadyTracked then
                    local npcGroup = npcGroups[npc] or groupName
                    if npcGroup == "all" then npcGroup = "group1" end -- Default fallback
                    
                    table.insert(spawnedVehicles, {
                        vehicle = vehicle,
                        driver = npc,
                        lastDriver = npc,
                        group = npcGroup,
                        driveMode = driveMode
                    })
                    ApplyVehicleDriveTask(npc, vehicle, driveMode)
                    updateCount = updateCount + 1
                end
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
function StartFight(groupA, groupB, weaponA, skinA, weaponB, skinB, behavior)
    local playerPed = PlayerPedId()
    local hashA = (groupA == "player" and GetPedRelationshipGroupHash(playerPed) or groupHashes[groupA])
    local hashB = (groupB == "player" and GetPedRelationshipGroupHash(playerPed) or groupHashes[groupB])
    
    if not hashA or not hashB then
        ShowNotification("~r~Loi: Nhom khong hop le!")
        return
    end
    
    behavior = behavior or "shoot"
    
    -- Force melee/unarmed weapons if behavior is melee
    if behavior == "melee" then
        local function getMeleeWeapon(w)
            if not w or w == "WEAPON_UNARMED" then return "WEAPON_UNARMED" end
            local meleeWeapons = {
                ["WEAPON_UNARMED"] = true, ["WEAPON_DAGGER"] = true, ["WEAPON_BAT"] = true,
                ["WEAPON_BOTTLE"] = true, ["WEAPON_CROWBAR"] = true, ["WEAPON_FLASHLIGHT"] = true,
                ["WEAPON_GOLFCLUB"] = true, ["WEAPON_HAMMER"] = true, ["WEAPON_HATCHET"] = true,
                ["WEAPON_KNUCKLE"] = true, ["WEAPON_KNIFE"] = true, ["WEAPON_MACHETE"] = true,
                ["WEAPON_SWITCHBLADE"] = true, ["WEAPON_NIGHTSTICK"] = true, ["WEAPON_WRENCH"] = true,
                ["WEAPON_BATTLEAXE"] = true, ["WEAPON_POOLCUE"] = true, ["WEAPON_STONE_HATCHET"] = true
            }
            if meleeWeapons[w] then return w end
            return "WEAPON_BAT"
        end
        weaponA = getMeleeWeapon(weaponA)
        weaponB = getMeleeWeapon(weaponB)
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
                
                if behavior == "melee" then
                    SetPedCombatAttributes(ped, 5, false)  -- BF_CanUseCover = false
                    SetPedCombatAttributes(ped, 16, true)  -- BF_CanFightArmedPedsWhenNotArmed
                    SetPedCombatMovement(ped, 2)           -- Offensive
                else
                    SetPedCombatAttributes(ped, 5, true)   -- BF_CanUseCover = true
                    SetPedCombatAttributes(ped, 16, true)
                    SetPedCombatMovement(ped, 2)           -- Offensive
                end
                
                SetPedCombatAbility(ped, 2)           -- Professional
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
        
        local function ApplyCombatBehavior(pedsSource, pedsTarget, targetGroup, isSourcePlayer)
            if isSourcePlayer then return end
            
            for _, ped in ipairs(pedsSource) do
                if IsPedUsable(ped) then
                    local targetPed = nil
                    if targetGroup == "player" then
                        targetPed = playerPed
                    elseif #pedsTarget > 0 then
                        targetPed = pedsTarget[math.random(1, #pedsTarget)]
                    end
                    
                    if targetPed and IsPedUsable(targetPed) then
                        ClearPedTasks(ped)
                        
                        -- Check if ped is in a vehicle and is the driver
                        local vehicle = GetVehiclePedIsIn(ped, false)
                        local isDriver = (vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped)
                        
                        if behavior == "chase" and isDriver then
                            TaskVehicleChase(ped, targetPed)
                            SetDriverAbility(ped, 1.0)
                            SetDriverAggressiveness(ped, 1.0)
                        else
                            TaskCombatPed(ped, targetPed, 0, 16)
                        end
                    end
                end
            end
        end
        
        -- Group A attacks targets in Group B
        ApplyCombatBehavior(pedsA, pedsB, groupB, groupA == "player")
        
        -- Group B attacks targets in Group A
        ApplyCombatBehavior(pedsB, pedsA, groupA, groupB == "player")
    end)
    
    local nameA = groupA == "player" and "Player" or "Nhom " .. groupA:gsub("group", "")
    local nameB = groupB == "player" and "Player" or "Nhom " .. groupB:gsub("group", "")
    local behaviorLabel = "giao tranh"
    if behavior == "shoot" then
        behaviorLabel = "ban nhau"
    elseif behavior == "melee" then
        behaviorLabel = "danh nhau"
    elseif behavior == "chase" then
        behaviorLabel = "truy duoi"
    end
    ShowNotification("~r~" .. nameA .. " va " .. nameB .. " dang " .. behaviorLabel .. "!")
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
RegisterNUICallback('spawnVehicles', function(data, cb) SpawnVehicles(data.model, tonumber(data.count), tonumber(data.distance), data.spawnNpc, data.driveMode, data.group, tonumber(data.color1), tonumber(data.color2)) cb({}) end)
RegisterNUICallback('deleteVehicles', function(data, cb) DeleteVehicles(data.group) cb({}) end)
RegisterNUICallback('updateVehicleBehavior', function(data, cb) UpdateVehicleBehavior(data.driveMode, data.group) cb({}) end)
RegisterNUICallback('npcEnterVehicles', function(data, cb) NPCEnterNearestVehicles(data.group) cb({}) end)
RegisterNUICallback('npcExitVehicles', function(data, cb) NPCExitNearestVehicles(data.group, data.weapon) cb({}) end)
RegisterNUICallback('startFight', function(data, cb) StartFight(data.groupA, data.groupB, data.weaponA, data.skinA, data.weaponB, data.skinB, data.behavior) cb({}) end)
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

-- Function to align vehicles neatly at the target GPS waypoint
function AlignGroupVehicles(groupName, gpsCoords)
    local vehiclesToAlign = {}
    for _, entry in ipairs(spawnedVehicles) do
        if entry.group == groupName and entry.vehicle and DoesEntityExist(entry.vehicle) then
            entry.aligned = true -- Mark as aligned
            table.insert(vehiclesToAlign, entry)
        end
    end
    
    if #vehiclesToAlign == 0 then return end
    
    -- Find the closest road node with its heading
    local success, roadCoords, roadHeading = GetClosestVehicleNodeWithHeading(gpsCoords.x, gpsCoords.y, gpsCoords.z, 1, 3.0, 0)
    local targetCoords = gpsCoords
    local targetHeading = 0.0
    
    if success then
        targetCoords = roadCoords
        targetHeading = roadHeading
    else
        -- Fallback to ground Z and player heading
        local retval, groundZ = GetGroundZFor_3dCoord(gpsCoords.x, gpsCoords.y, gpsCoords.z, 0)
        if retval then
            targetCoords = vector3(gpsCoords.x, gpsCoords.y, groundZ)
        else
            targetCoords = gpsCoords
        end
        targetHeading = GetEntityHeading(PlayerPedId())
    end
    
    -- Compute direction vector based on road heading (moving forward)
    local headingRad = math.rad(targetHeading)
    local dirVector = vector3(-math.sin(headingRad), math.cos(headingRad), 0.0)
    
    -- Spacing between vehicles (in meters)
    local spacing = 7.0
    
    -- Align vehicles one behind another along the road node
    for i, entry in ipairs(vehiclesToAlign) do
        local offsetDist = (i - 1) * spacing
        local spawnPos = targetCoords - (dirVector * offsetDist)
        
        -- Stop NPC driver tasks immediately
        local currentDriver = GetPedInVehicleSeat(entry.vehicle, -1)
        if currentDriver and currentDriver ~= 0 and DoesEntityExist(currentDriver) then
            ClearPedTasksImmediately(currentDriver)
            entry.driver = currentDriver
        end
        
        -- Position and stabilize the vehicle
        SetEntityCoordsNoOffset(entry.vehicle, spawnPos.x, spawnPos.y, spawnPos.z, true, false, false)
        SetEntityHeading(entry.vehicle, targetHeading)
        SetVehicleOnGroundProperly(entry.vehicle)
        SetVehicleForwardSpeed(entry.vehicle, 0.0)
        SetVehicleHandbrake(entry.vehicle, true)
        SetVehicleEngineOn(entry.vehicle, false, true, true)
    end
    
    local numStr = groupName:gsub("group", "")
    ShowNotification("~g~Nhom " .. numStr .. " da den diem den va tu dong xep hang ngay ngan!")
end

-- Thread to monitor GPS waypoint arrival
local lastGpsCoords = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local blip = GetFirstBlipInfoId(8) -- 8 = Waypoint
        if DoesBlipExist(blip) then
            local gpsCoords = GetBlipInfoIdCoord(blip)
            
            -- If GPS waypoint shifts by more than 5 meters, allow re-alignment
            if not lastGpsCoords or #(lastGpsCoords - gpsCoords) > 5.0 then
                lastGpsCoords = gpsCoords
                for _, entry in ipairs(spawnedVehicles) do
                    entry.aligned = false
                end
            end
            
            -- Identify vehicle groups driving to GPS that are close to the target
            local groupsToAlign = {}
            for _, entry in ipairs(spawnedVehicles) do
                if not entry.aligned and (entry.driveMode == "gps" or entry.driveMode == "race") then
                    if entry.vehicle and DoesEntityExist(entry.vehicle) then
                        local vehCoords = GetEntityCoords(entry.vehicle)
                        local dist = #(vehCoords - gpsCoords)
                        
                        -- If within 30 meters of target waypoint
                        if dist < 30.0 then
                            groupsToAlign[entry.group] = true
                        end
                    end
                end
            end
            
            -- Align vehicles in the groups that arrived
            for groupName, _ in pairs(groupsToAlign) do
                AlignGroupVehicles(groupName, gpsCoords)
            end
        else
            lastGpsCoords = nil
        end
    end
end)

local lastPlayerVeh = nil
local lastFollowCount = 0

-- Thread to monitor and keep follow vehicles close to the player, with auto line-up when stopped
Citizen.CreateThread(function()
    local wasPlayerStopped = false
    
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        
        if playerPed and playerPed ~= 0 then
            local playerVeh = GetVehiclePedIsIn(playerPed, false)
            if playerVeh ~= 0 then
                lastPlayerVeh = playerVeh
            end
            
            -- Determine anchorEntity for lining up
            local anchorEntity = playerPed
            if playerVeh ~= 0 then
                anchorEntity = playerVeh
            elseif lastPlayerVeh and DoesEntityExist(lastPlayerVeh) then
                local playerCoords = GetEntityCoords(playerPed)
                local vehCoords = GetEntityCoords(lastPlayerVeh)
                if #(playerCoords - vehCoords) < 25.0 then
                    anchorEntity = lastPlayerVeh
                end
            end
            
            -- Check if anchor entity is stopped (speed < 0.2 m/s)
            local speedOfAnchor = GetEntitySpeed(anchorEntity)
            local isAnchorStopped = (speedOfAnchor < 0.2)
            
            -- Find all active follow vehicles
            local followEntries = {}
            for _, entry in ipairs(spawnedVehicles) do
                if entry.vehicle and DoesEntityExist(entry.vehicle) then
                    if entry.driveMode == "follow" or entry.driveMode == "follow_player" then
                        local currentDriver = GetPedInVehicleSeat(entry.vehicle, -1)
                        if currentDriver and currentDriver ~= 0 and DoesEntityExist(currentDriver) then
                            entry.driver = currentDriver
                            table.insert(followEntries, entry)
                        end
                    end
                end
            end
            
            if #followEntries > 0 then
                if isAnchorStopped then
                    -- When player is stopped, we want to align them.
                    sleep = 0 -- Run fast for alignment checks
                    
                    -- Assign stable queue slots if count changed or not yet assigned
                    local countChanged = (#followEntries ~= lastFollowCount)
                    if not wasPlayerStopped or countChanged then
                        lastFollowCount = #followEntries
                        local baseCoords = GetEntityCoords(anchorEntity)
                        table.sort(followEntries, function(a, b)
                            local distA = #(GetEntityCoords(a.vehicle) - baseCoords)
                            local distB = #(GetEntityCoords(b.vehicle) - baseCoords)
                            return distA < distB
                        end)
                        for idx, entry in ipairs(followEntries) do
                            entry.slotIndex = idx
                        end
                    end
                    
                    local baseCoords = GetEntityCoords(anchorEntity)
                    local forward = GetEntityForwardVector(anchorEntity)
                    local dirVector = -forward
                    
                    for _, entry in ipairs(followEntries) do
                        local currentDriver = entry.driver
                        local vehicle = entry.vehicle
                        local vehCoords = GetEntityCoords(vehicle)
                        
                        local spacing = entry.spacing or 8.0
                        local slotIdx = entry.slotIndex or 1
                        
                        -- Calculate target slot position and heading
                        local targetPos = baseCoords + dirVector * (spacing * slotIdx)
                        local targetHeading = GetEntityHeading(anchorEntity)
                        
                        local finalTargetPos
                        if entry.targetZ then
                            finalTargetPos = vector3(targetPos.x, targetPos.y, entry.targetZ)
                        else
                            local retval, groundZ = GetGroundZFor_3dCoord(targetPos.x, targetPos.y, targetPos.z, 0)
                            local finalZ = retval and groundZ or baseCoords.z
                            entry.targetZ = finalZ
                            finalTargetPos = vector3(targetPos.x, targetPos.y, finalZ)
                        end
                        
                        local distToSlot = #(vehCoords - finalTargetPos)
                        
                        if distToSlot > 3.0 then
                            -- Far from slot, drive there!
                            if entry.alignState ~= "driving" then
                                entry.alignState = "driving"
                                ClearPedTasks(currentDriver)
                                TaskVehicleDriveToCoordLongrange(currentDriver, vehicle, finalTargetPos.x, finalTargetPos.y, finalTargetPos.z, 15.0, 786603, 1.5)
                            end
                            SetVehicleHandbrake(vehicle, false)
                        else
                            -- Close to slot, snap once and park!
                            if entry.alignState ~= "parked" then
                                entry.alignState = "parked"
                                ClearPedTasksImmediately(currentDriver)
                                
                                -- Only snap coordinates and heading if there is a noticeable offset (to prevent glitching on spawn)
                                local currentHeading = GetEntityHeading(vehicle)
                                local headingDiff = math.abs(currentHeading - targetHeading)
                                while headingDiff > 180.0 do headingDiff = 360.0 - headingDiff end
                                
                                if distToSlot > 0.5 or headingDiff > 5.0 then
                                    SetEntityCoordsNoOffset(vehicle, finalTargetPos.x, finalTargetPos.y, finalTargetPos.z, true, false, false)
                                    SetEntityHeading(vehicle, targetHeading)
                                end
                                
                                SetVehicleForwardSpeed(vehicle, 0.0)
                                SetVehicleHandbrake(vehicle, true)
                                SetVehicleEngineOn(vehicle, true, true, true)
                            end
                        end
                    end
                    wasPlayerStopped = true
                else
                    -- Player is moving!
                    if wasPlayerStopped then
                        -- Just started moving again, reset all alignment states
                        for _, entry in ipairs(followEntries) do
                            entry.alignState = nil
                            entry.slotIndex = nil
                            entry.targetZ = nil
                            SetVehicleHandbrake(entry.vehicle, false)
                            -- Force re-apply of follow task
                            entry.lastSpeed = nil
                            entry.lastStyle = nil
                        end
                        wasPlayerStopped = false
                        lastFollowCount = 0
                    end
                    
                    -- Normal follow behavior
                    local baseCoords = GetEntityCoords(playerPed)
                    local isPlayerInVeh = (playerVeh ~= 0)
                    
                    for _, entry in ipairs(followEntries) do
                        local currentDriver = entry.driver
                        local vehicle = entry.vehicle
                        local vehCoords = GetEntityCoords(vehicle)
                        local dist = #(vehCoords - baseCoords)
                        
                        -- Adjust speed and driving style dynamically based on distance
                        local speed = 30.0
                        local style = 786603
                        
                        if dist > 60.0 then
                            speed = 60.0
                            style = 288
                        elseif dist > 35.0 then
                            speed = 40.0
                            style = 786603
                        elseif dist < 12.0 then
                            speed = 8.0
                            style = 786603
                        elseif dist < 25.0 then
                            speed = 18.0
                            style = 786603
                        end
                        
                        if not isPlayerInVeh and dist < 8.0 then
                            speed = 3.0
                        end
                        
                        if not entry.lastSpeed or math.abs(entry.lastSpeed - speed) > 4.0 or entry.lastStyle ~= style then
                            entry.lastSpeed = speed
                            entry.lastStyle = style
                            ClearPedTasks(currentDriver)
                            TaskVehicleMissionPedTarget(currentDriver, vehicle, playerPed, 7, speed, style, 6.0, 0.0, true)
                        end
                    end
                end
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

-- Thread to monitor driver changes and apply tasks automatically
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        for _, entry in ipairs(spawnedVehicles) do
            if entry.vehicle and DoesEntityExist(entry.vehicle) then
                local currentDriver = GetPedInVehicleSeat(entry.vehicle, -1)
                if currentDriver == 0 then currentDriver = nil end
                
                -- If player is driving, we don't control them
                if currentDriver == PlayerPedId() then
                    currentDriver = nil
                end
                
                -- Continually ensure engine is ON and handbrake is OFF while driving
                if currentDriver and DoesEntityExist(currentDriver) and entry.driveMode then
                    if not GetIsVehicleEngineRunning(entry.vehicle) then
                        SetVehicleEngineOn(entry.vehicle, true, true, false)
                    end
                    if entry.alignState ~= "parked" and entry.alignState ~= "lerping" then
                        SetVehicleHandbrake(entry.vehicle, false)
                    end
                end
                
                -- Check if driver has changed
                if currentDriver ~= entry.lastDriver then
                    entry.lastDriver = currentDriver
                    entry.driver = currentDriver
                    
                    if currentDriver and DoesEntityExist(currentDriver) and entry.driveMode then
                        print(string.format("[XMenu] Driver changed for vehicle %s. Applying task %s", tostring(entry.vehicle), tostring(entry.driveMode)))
                        ApplyVehicleDriveTask(currentDriver, entry.vehicle, entry.driveMode)
                    end
                end
            end
        end
    end
end)

-- Periodically check if any spawned NPCs are driving a vehicle that is not yet tracked
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        for _, npc in ipairs(spawnedNPCs) do
            if IsPedUsable(npc) and IsPedInAnyVehicle(npc, false) then
                local vehicle = GetVehiclePedIsIn(npc, false)
                if DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == npc then
                    -- Check if already tracked
                    local alreadyTracked = false
                    for _, entry in ipairs(spawnedVehicles) do
                        if entry.vehicle == vehicle then
                            alreadyTracked = true
                            break
                        end
                    end
                    
                    if not alreadyTracked then
                        local npcGroup = npcGroups[npc] or "group1"
                        table.insert(spawnedVehicles, {
                            vehicle = vehicle,
                            driver = npc,
                            lastDriver = npc,
                            group = npcGroup,
                            driveMode = "follow" -- Default mode for newly boarded vehicles
                        })
                        ApplyVehicleDriveTask(npc, vehicle, "follow")
                        print("[XMenu] Dynamically tracked vehicle driven by NPC " .. tostring(npc))
                    end
                end
            end
        end
    end
end)

-- Thread to monitor and enforce NPC follow behavior
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Check/re-apply every 1 second
        local playerPed = PlayerPedId()
        if playerPed and playerPed ~= 0 then
            local playerCoords = GetEntityCoords(playerPed)
            
            for npc, state in pairs(npcFollowStates) do
                if IsPedUsable(npc) and state.following then
                    -- If they are in a vehicle, don't force follow task on foot
                    -- Also, if they are currently defending/attacking, do not interrupt combat
                    -- Also, if they are in the native group, do not interfere with native follow
                    local isGroupMember = IsPedInGroup(npc)
                    if not isGroupMember and not IsPedInAnyVehicle(npc, false) and not state.target then
                        local npcCoords = GetEntityCoords(npc)
                        local dist = #(npcCoords - playerCoords)
                        
                        -- If they are too far from their stopping range, ensure they are actively following
                        if dist > 4.0 then
                            -- Re-apply task to ensure they keep following even if task got cancelled
                            TaskFollowToOffsetOfEntity(npc, playerPed, 0.0, 0.0, 0.0, state.speed, -1, 3.0, true)
                        end
                    end
                else
                    npcFollowStates[npc] = nil -- Clean up invalid peds
                end
            end
        end
    end
end)

local lastPlayerHealth = nil
local lastPlayerArmor = nil

function FindPlayerAttacker(playerPed)
    local currentHealth = GetEntityHealth(playerPed)
    local currentArmor = GetPedArmour(playerPed)
    
    if not lastPlayerHealth then
        lastPlayerHealth = currentHealth
        lastPlayerArmor = currentArmor
    end
    
    local attacker = GetPedAttacker(playerPed)
    if attacker and attacker ~= 0 and DoesEntityExist(attacker) and not IsEntityDead(attacker) then
        lastPlayerHealth = currentHealth
        lastPlayerArmor = currentArmor
        return attacker
    end
    
    -- Check if player health or armor decreased
    local tookDamage = (currentHealth < lastPlayerHealth) or (currentArmor < lastPlayerArmor)
    lastPlayerHealth = currentHealth
    lastPlayerArmor = currentArmor
    
    -- Scan nearby peds using FindFirstPed/FindNextPed
    local handle, ped = FindFirstPed()
    local success
    if handle ~= -1 then
        repeat
            if ped ~= playerPed and DoesEntityExist(ped) and not IsEntityDead(ped) then
                -- Check 1: Did this ped damage the player recently?
                if HasEntityBeenDamagedByEntity(playerPed, ped, true) then
                    attacker = ped
                    break
                end
                
                -- Check 2: Is this ped aiming/shooting or in melee combat with the player?
                if GetMeleeTargetForPed(ped) == playerPed then
                    attacker = ped
                    break
                end
                
                -- Check 3: Is their combat target the player? (For NPCs)
                if GetPedCombatTarget(ped) == playerPed then
                    attacker = ped
                    break
                end
                
                -- Check 4: General combat fallback
                if IsPedInCombat(ped, playerPed) then
                    -- Check if not one of our own spawned NPCs
                    local isOurNPC = false
                    for _, spawnedNpc in ipairs(spawnedNPCs) do
                        if spawnedNpc == ped then
                            isOurNPC = true
                            break
                        end
                    end
                    if not isOurNPC then
                        attacker = ped
                        break
                    end
                end
            end
            success, ped = FindNextPed(handle)
        until not success
        EndFindPed(handle)
    end
    
    return attacker
end

-- Thread to monitor if player is attacked or targets someone, and command NPCs to defend
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500) -- Check every 500ms
        local playerPed = PlayerPedId()
        if playerPed and playerPed ~= 0 then
            local attacker = FindPlayerAttacker(playerPed)
            
            -- Fallback: Check if player is free-aiming at or targeting a Ped
            if not attacker or attacker == 0 or IsEntityDead(attacker) then
                local isAiming, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                if isAiming and DoesEntityExist(targetEntity) and IsEntityAPed(targetEntity) and not IsEntityDead(targetEntity) then
                    local isOurNPC = false
                    for _, spawnedNpc in ipairs(spawnedNPCs) do
                        if spawnedNpc == targetEntity then
                            isOurNPC = true
                            break
                        end
                    end
                    if not isOurNPC then
                        attacker = targetEntity
                    end
                else
                    local targetPed = GetPlayerTargetEntity(PlayerId())
                    if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) and IsEntityAPed(targetPed) and not IsEntityDead(targetPed) then
                        local isOurNPC = false
                        for _, spawnedNpc in ipairs(spawnedNPCs) do
                            if spawnedNpc == targetPed then
                                isOurNPC = true
                                break
                            end
                        end
                        if not isOurNPC then
                            attacker = targetPed
                        end
                    end
                end
            end
            
            if attacker and attacker ~= 0 and attacker ~= playerPed and not IsEntityDead(attacker) then
                -- Check if the attacker is not one of our own spawned NPCs
                local isOurNPC = false
                for _, npc in ipairs(spawnedNPCs) do
                    if npc == attacker then
                        isOurNPC = true
                        break
                    end
                end
                
                if not isOurNPC then
                    -- Command all friendly NPCs to attack the attacker!
                    for _, npc in ipairs(spawnedNPCs) do
                        if IsPedUsable(npc) then
                            local groupName = npcGroups[npc] or "group1"
                            local rel = groupRelationships[groupName] or "friendly"
                            
                            -- Only friendly groups defend the player
                            if rel == "friendly" then
                                local isGroupMember = IsPedInGroup(npc)
                                if not isGroupMember then
                                    if not npcFollowStates[npc] then
                                        npcFollowStates[npc] = { following = false, speed = 3.0 }
                                    end
                                    
                                    local state = npcFollowStates[npc]
                                    if state.target ~= attacker then
                                        state.target = attacker
                                        print(string.format("[XMenu] Friendly NPC %s attacking target %s", tostring(npc), tostring(attacker)))
                                        ClearPedTasksImmediately(npc)
                                        
                                        -- Force Hate relationship group settings so the game engine allows them to attack
                                        local npcGroup = GetPedRelationshipGroupHash(npc)
                                        local attackerGroup = GetPedRelationshipGroupHash(attacker)
                                        if npcGroup and attackerGroup then
                                            SetRelationshipBetweenGroups(5, npcGroup, attackerGroup) -- 5 = Hate
                                            SetRelationshipBetweenGroups(5, attackerGroup, npcGroup)
                                        end
                                        
                                        SetBlockingOfNonTemporaryEvents(npc, false) -- Disable non-temporary blocking during combat
                                        SetPedFleeAttributes(npc, 0, false)
                                        SetPedCombatAttributes(npc, 5, true)   -- Always fight (CA_ALWAYS_FIGHT)
                                        SetPedCombatAttributes(npc, 17, false) -- Disable flee (CA_ALWAYS_FLEE)
                                        SetPedCombatAttributes(npc, 16, true)  -- Can fight armed peds when unarmed
                                        SetPedCombatRange(npc, 2)             -- Far range
                                        SetPedCombatAbility(npc, 2)           -- Professional
                                        SetPedAlertness(npc, 3)               -- Alert
                                        TaskCombatPed(npc, attacker, 0, 16)
                                      end
                                end
                            end
                        end
                    end
                end
            else
                -- No active enemy attacker, check if any NPC needs to resume their previous task
                for npc, state in pairs(npcFollowStates) do
                    if IsPedUsable(npc) then
                        if state.target then
                            -- Target is dead or no longer exists
                            if not DoesEntityExist(state.target) or IsEntityDead(state.target) then
                                print(string.format("[XMenu] Target gone. NPC %s resuming state.", tostring(npc)))
                                state.target = nil
                                ClearPedTasksImmediately(npc)
                                SetBlockingOfNonTemporaryEvents(npc, true)
                                
                                if state.following then
                                    local isGroupMember = IsPedInGroup(npc)
                                    if not isGroupMember then
                                        TaskFollowToOffsetOfEntity(npc, playerPed, 0.0, 0.0, 0.0, state.speed, -1, 3.0, true)
                                    end
                                else
                                    -- If they were not following, they just stay put
                                    npcFollowStates[npc] = nil -- Clean up temp state
                                end
                            end
                        end
                    else
                        npcFollowStates[npc] = nil
                    end
                end
            end
        end
    end
end)
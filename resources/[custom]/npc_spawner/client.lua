-- ==========================================
-- HE THONG QUAN LY NPC - BY GTA5VN
-- Version: Restructured & Optimized 100%
-- Ngon ngu: Tieng Viet Khong Dau
-- ==========================================

local _menuPool = NativeUI.CreatePool()
local mainMenu = nil
local npcList = {}             -- Bang luu cac NPC da tao: [npcName] = npcPed
local selectedGroup = "A"      -- Nhom mac dinh
local npcGroups = {}           -- Luu cac nhom NPC: [groupId] = {npcName1, npcName2, ...}
local driveSpeed = 10.0
local maxDistance = 50.0       -- Khoang cach toi da NPC co the di chuyen tu vi tri goc
local npcGroupHeading = 0.0    -- Huong mac dinh cho NPC khi sap xep
local npcGroupOrigin = nil     -- Toa do goc cho sap xep nhom NPC
local playerAnimDict = nil     -- Emote duoc chon tuong tac
local playerAnimName = nil
local npcLipSyncActive = {}    -- Theo doi nhiep mieng cua NPC
local emoteData = {dict = nil, name = nil}

-- ==========================================
-- DANG SACH VU KHI (WEAPON OPTIONS)
-- ==========================================
local weaponOptions = {
    -- Melee Weapons
    {label = "Dao (Knife)", weapon = "weapon_knife"},
    {label = "Gay Bong Chay (Baseball Bat)", weapon = "weapon_bat"},
    {label = "Bua (Hammer)", weapon = "weapon_hammer"},
    {label = "Riu Nho (Hatchet)", weapon = "weapon_hatchet"},
    {label = "Dao Gam (Antique Cavalry Dagger)", weapon = "weapon_dagger"},
    {label = "Gay Golf (Golf Club)", weapon = "weapon_golfclub"},
    {label = "Den Pin (Flashlight)", weapon = "weapon_flashlight"},
    {label = "Dao Machete", weapon = "weapon_machete"},
    {label = "Mo Let (Pipe Wrench)", weapon = "weapon_wrench"},
    {label = "Gay Bida (Pool Cue)", weapon = "weapon_poolcue"},
    {label = "Dao Bam (Switchblade)", weapon = "weapon_switchblade"},
    {label = "Tay Dam Thep (Knuckledusters)", weapon = "weapon_knuckle"},
    {label = "Riu Chien Dau (Battle Axe)", weapon = "weapon_battleaxe"},
    {label = "Chai Vo (Broken Bottle)", weapon = "weapon_bottle"},
    {label = "Duich Cui (Nightstick)", weapon = "weapon_nightstick"},
    {label = "Riu Da (Stone Hatchet)", weapon = "weapon_stone_hatchet"},

    -- Pistols
    {label = "Pistol", weapon = "weapon_pistol"},
    {label = "Combat Pistol", weapon = "weapon_combatpistol"},
    {label = "AP Pistol", weapon = "weapon_appistol"},
    {label = "Pistol .50", weapon = "weapon_pistol50"},
    {label = "SNS Pistol", weapon = "weapon_snspistol"},
    {label = "Heavy Pistol", weapon = "weapon_heavypistol"},
    {label = "Vintage Pistol", weapon = "weapon_vintagepistol"},
    {label = "Marksman Pistol", weapon = "weapon_marksmanpistol"},
    {label = "Heavy Revolver", weapon = "weapon_revolver"},
    {label = "Double-Action Revolver", weapon = "weapon_doubleaction"},
    {label = "Ceramic Pistol", weapon = "weapon_ceramicpistol"},
    {label = "Navy Revolver", weapon = "weapon_navyrevolver"},
    {label = "Perico Pistol", weapon = "weapon_perico"},
    {label = "Sung Phao Sang (Flare Gun)", weapon = "weapon_flaregun"},

    -- Submachine Guns
    {label = "Micro SMG", weapon = "weapon_microsmg"},
    {label = "SMG", weapon = "weapon_smg"},
    {label = "Assault SMG", weapon = "weapon_assaultsmg"},
    {label = "Combat PDW", weapon = "weapon_combatpdw"},
    {label = "Machine Pistol", weapon = "weapon_machinepistol"},
    {label = "Mini SMG", weapon = "weapon_minismg"},
    {label = "Unholy Hellbringer", weapon = "weapon_raycarbine"},

    -- Rifles
    {label = "Assault Rifle", weapon = "weapon_assaultrifle"},
    {label = "Carbine Rifle", weapon = "weapon_carbinerifle"},
    {label = "Advanced Rifle", weapon = "weapon_advancedrifle"},
    {label = "Special Carbine", weapon = "weapon_specialcarbine"},
    {label = "Bullpup Rifle", weapon = "weapon_bullpuprifle"},
    {label = "Compact Rifle", weapon = "weapon_compactrifle"},
    {label = "Military Rifle", weapon = "weapon_militaryrifle"},
    {label = "Heavy Rifle", weapon = "weapon_heavyrifle"},
    {label = "Service Carbine", weapon = "weapon_tacticalrifle"},

    -- Shotguns
    {label = "Pump Shotgun", weapon = "weapon_pumpshotgun"},
    {label = "Sawn-Off Shotgun", weapon = "weapon_sawnoffshotgun"},
    {label = "Assault Shotgun", weapon = "weapon_assaultshotgun"},
    {label = "Bullpup Shotgun", weapon = "weapon_bullpupshotgun"},
    {label = "Musket", weapon = "weapon_musket"},
    {label = "Heavy Shotgun", weapon = "weapon_heavyshotgun"},
    {label = "Double Barrel Shotgun", weapon = "weapon_dbshotgun"},
    {label = "Sweeper Shotgun", weapon = "weapon_autoshotgun"},
    {label = "Combat Shotgun", weapon = "weapon_combatshotgun"},

    -- Heavy Weapons
    {label = "RPG", weapon = "weapon_rpg"},
    {label = "Grenade Launcher", weapon = "weapon_grenadelauncher"},
    {label = "Minigun", weapon = "weapon_minigun"},
    {label = "Firework Launcher", weapon = "weapon_firework"},
    {label = "Railgun", weapon = "weapon_railgun"},
    {label = "Homing Launcher", weapon = "weapon_hominglauncher"},
    {label = "Compact Grenade Launcher", weapon = "weapon_compactlauncher"},
    {label = "Widowmaker", weapon = "weapon_rayminigun"},
    {label = "Compact EMP Launcher", weapon = "weapon_emplauncher"},

    -- Sniper Rifles
    {label = "Sniper Rifle", weapon = "weapon_sniperrifle"},
    {label = "Heavy Sniper", weapon = "weapon_heavysniper"},
    {label = "Marksman Rifle", weapon = "weapon_marksmanrifle"},
    {label = "Precision Rifle", weapon = "weapon_precisionrifle"},

    -- Thrown Weapons
    {label = "Luu Dan (Grenade)", weapon = "weapon_grenade"},
    {label = "Bom Keo (Sticky Bomb)", weapon = "weapon_stickybomb"},
    {label = "Bom Xang (Molotov)", weapon = "weapon_molotov"},
    {label = "Bom Khoi (Tear Gas)", weapon = "weapon_teargas"},
    {label = "Min Cam Bien (Proximity Mine)", weapon = "weapon_proximitymine"},
    {label = "Bom Ong (Pipe Bomb)", weapon = "weapon_pipebomb"},
    {label = "BZ Gas", weapon = "weapon_bzgas"},
    {label = "Phao Sang (Flare)", weapon = "weapon_flare"},
    {label = "Bong Tuyet (Snowball)", weapon = "weapon_snowball"},

    -- Miscellaneous
    {label = "Binh Chua Chay (Fire Extinguisher)", weapon = "weapon_fireextinguisher"},
    {label = "Can Xang (Jerry Can)", weapon = "weapon_petrolcan"},
    {label = "Digiscanner", weapon = "weapon_digiscanner"},
    {label = "Acid Package", weapon = "weapon_acidpackage"}
}

local weaponCategories = {
    {
        label = "Sung Ngan (Pistols)",
        weapons = {
            {label = "Pistol", weapon = "weapon_pistol"},
            {label = "Combat Pistol", weapon = "weapon_combatpistol"},
            {label = "AP Pistol", weapon = "weapon_appistol"},
            {label = "Pistol .50", weapon = "weapon_pistol50"},
            {label = "SNS Pistol", weapon = "weapon_snspistol"},
            {label = "Heavy Pistol", weapon = "weapon_heavypistol"},
            {label = "Vintage Pistol", weapon = "weapon_vintagepistol"},
            {label = "Marksman Pistol", weapon = "weapon_marksmanpistol"},
            {label = "Heavy Revolver", weapon = "weapon_revolver"},
            {label = "Double-Action Revolver", weapon = "weapon_doubleaction"},
            {label = "Ceramic Pistol", weapon = "weapon_ceramicpistol"},
            {label = "Navy Revolver", weapon = "weapon_navyrevolver"},
            {label = "Perico Pistol", weapon = "weapon_perico"},
            {label = "Sung Phao Sang (Flare Gun)", weapon = "weapon_flaregun"}
        }
    },
    {
        label = "Sung Truong (Rifles)",
        weapons = {
            {label = "Assault Rifle", weapon = "weapon_assaultrifle"},
            {label = "Carbine Rifle", weapon = "weapon_carbinerifle"},
            {label = "Advanced Rifle", weapon = "weapon_advancedrifle"},
            {label = "Special Carbine", weapon = "weapon_specialcarbine"},
            {label = "Special Carbine MK 2", weapon = "weapon_carbinerifle_mk2"},
            {label = "Bullpup Rifle", weapon = "weapon_bullpuprifle"},
            {label = "Bullpup Rifle MK 2", weapon = "weapon_bullpuprifle_mk2"},
            {label = "Compact Rifle", weapon = "weapon_compactrifle"},
            {label = "Military Rifle", weapon = "weapon_militaryrifle"},
            {label = "Heavy Rifle", weapon = "weapon_heavyrifle"},
            {label = "Service Carbine", weapon = "weapon_tacticalrifle"}
        }
    },
    {
        label = "Can Chien (Melee)",
        weapons = {
            {label = "Dao (Knife)", weapon = "weapon_knife"},
            {label = "Gay Bong Chay (Baseball Bat)", weapon = "weapon_bat"},
            {label = "Bua (Hammer)", weapon = "weapon_hammer"},
            {label = "Riu Nho (Hatchet)", weapon = "weapon_hatchet"},
            {label = "Dao Gam (Antique Cavalry Dagger)", weapon = "weapon_dagger"},
            {label = "Gay Golf (Golf Club)", weapon = "weapon_golfclub"},
            {label = "Den Pin (Flashlight)", weapon = "weapon_flashlight"},
            {label = "Dao Machete", weapon = "weapon_machete"},
            {label = "Mo Let (Pipe Wrench)", weapon = "weapon_wrench"},
            {label = "Gay Bida (Pool Cue)", weapon = "weapon_poolcue"},
            {label = "Dao Bam (Switchblade)", weapon = "weapon_switchblade"},
            {label = "Tay Dam Thep (Knuckledusters)", weapon = "weapon_knuckle"},
            {label = "Riu Chien Dau (Battle Axe)", weapon = "weapon_battleaxe"},
            {label = "Chai Vo (Broken Bottle)", weapon = "weapon_bottle"},
            {label = "Duich Cui (Nightstick)", weapon = "weapon_nightstick"},
            {label = "Riu Da (Stone Hatchet)", weapon = "weapon_stone_hatchet"}
        }
    },
    {
        label = "Shotgun",
        weapons = {
            {label = "Pump Shotgun", weapon = "weapon_pumpshotgun"},
            {label = "Sawn-Off Shotgun", weapon = "weapon_sawnoffshotgun"},
            {label = "Assault Shotgun", weapon = "weapon_assaultshotgun"},
            {label = "Bullpup Shotgun", weapon = "weapon_bullpupshotgun"},
            {label = "Musket", weapon = "weapon_musket"},
            {label = "Heavy Shotgun", weapon = "weapon_heavyshotgun"},
            {label = "Double Barrel Shotgun", weapon = "weapon_dbshotgun"},
            {label = "Sweeper Shotgun", weapon = "weapon_autoshotgun"},
            {label = "Combat Shotgun", weapon = "weapon_combatshotgun"}
        }
    },
    {
        label = "SMG",
        weapons = {
            {label = "Micro SMG", weapon = "weapon_microsmg"},
            {label = "SMG", weapon = "weapon_smg"},
            {label = "Assault SMG", weapon = "weapon_assaultsmg"},
            {label = "Combat PDW", weapon = "weapon_combatpdw"},
            {label = "Machine Pistol", weapon = "weapon_machinepistol"},
            {label = "Mini SMG", weapon = "weapon_minismg"},
            {label = "Unholy Hellbringer", weapon = "weapon_raycarbine"}
        }
    },
    {
        label = "Sung Nham (Sniper)",
        weapons = {
            {label = "Sniper Rifle", weapon = "weapon_sniperrifle"},
            {label = "Heavy Sniper", weapon = "weapon_heavysniper"},
            {label = "Marksman Rifle", weapon = "weapon_marksmanrifle"},
            {label = "Precision Rifle", weapon = "weapon_precisionrifle"}
        }
    },
    {
        label = "Vu Khi Nang (Heavy)",
        weapons = {
            {label = "RPG", weapon = "weapon_rpg"},
            {label = "Grenade Launcher", weapon = "weapon_grenadelauncher"},
            {label = "Minigun", weapon = "weapon_minigun"},
            {label = "Firework Launcher", weapon = "weapon_firework"},
            {label = "Railgun", weapon = "weapon_railgun"},
            {label = "Homing Launcher", weapon = "weapon_hominglauncher"},
            {label = "Compact Grenade Launcher", weapon = "weapon_compactlauncher"},
            {label = "Widowmaker", weapon = "weapon_rayminigun"},
            {label = "Compact EMP Launcher", weapon = "weapon_emplauncher"}
        }
    }
}

-- ==========================================
-- KHOI TAO MENU CHINH (CREATE MAIN MENU)
-- ==========================================
function CreateMainMenu()
    mainMenu = NativeUI.CreateMenu("Quan ly NPC", "Tao, Xoa, Dieu chinh va Emote cho NPC")
    _menuPool:Add(mainMenu)

    -- 1. Tao NPC
    local createNpcItem = NativeUI.CreateItem("Tao NPC", "Nhap ten NPC de tao.")
    mainMenu:AddItem(createNpcItem)
    createNpcItem.Activated = function(sender, item)
        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 30)
        while (UpdateOnscreenKeyboard() == 0) do
            Citizen.Wait(0)
        end
        local npcNameInput = GetOnscreenKeyboardResult()
        if npcNameInput and npcNameInput ~= "" then
            CreateNPC(npcNameInput)
        end
    end

    -- 2. Tao NPC tu dong
    local createAutoNpcItem = NativeUI.CreateItem("Tao NPC Tu Dong", "Tao nhieu NPC tu dong.")
    mainMenu:AddItem(createAutoNpcItem)
    createAutoNpcItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowAutoNpcCreationMenu()
    end

    -- 3. Dieu huong tat ca NPC
    local adjustAllNpcPositionItem = NativeUI.CreateItem("Dieu huong tat ca NPC", "Dieu chinh vi tri/huong cua tat ca NPC cung luc bang ban phim.")
    mainMenu:AddItem(adjustAllNpcPositionItem)
    adjustAllNpcPositionItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        AdjustAllNpcPositions()
    end

    -- 4. Cap sung cho NPC (Tung NPC hoac Theo danh muc)
    local giveWeaponItem = NativeUI.CreateItem("Cap sung cho NPC", "Chon loai sung va NPC de cap sung.")
    mainMenu:AddItem(giveWeaponItem)
    giveWeaponItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowGiveWeaponMenu()
    end

    -- 5. Di chuyen tat ca NPC
    local moveAllNpcsItem = NativeUI.CreateItem("Di chuyen tat ca NPC", "Di chuyen tat ca NPC den vi tri danh dau tren ban do.")
    mainMenu:AddItem(moveAllNpcsItem)
    moveAllNpcsItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowMoveAllNpcsMenu()
    end

    -- 6. Nhep mieng cho NPC
    local autoLipSyncItem = NativeUI.CreateItem("Nhep mieng cho NPC", "Tu dong nhep mieng nhu dang noi.")
    mainMenu:AddItem(autoLipSyncItem)
    autoLipSyncItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowLipSyncMenu()
    end

    -- 7. Tat ca NPC danh lon
    local fightEachOtherItem = NativeUI.CreateItem("Tat ca NPC danh lon", "Kich hoat tat ca NPC danh lon voi nhau.")
    mainMenu:AddItem(fightEachOtherItem)
    fightEachOtherItem.Activated = function(sender, item)
        MakeAllNpcsFightEachOther()
    end

    -- 8. NPC len/xuong xe
    local npcEnterVehicleItem = NativeUI.CreateItem("NPC len/xuong xe", "Chon NPC de leo len xe gan nhat.")
    mainMenu:AddItem(npcEnterVehicleItem)
    npcEnterVehicleItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowNpcEnterVehicleMenu()
    end

    -- 9. NPC lai xe quanh khu vuc
    local npcDriveAroundItem = NativeUI.CreateItem("NPC lai xe quanh khu vuc", "NPC se lai xe quanh khu vuc ma khong dung vat the.")
    mainMenu:AddItem(npcDriveAroundItem)
    npcDriveAroundItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowNpcDriveAroundMenu()
    end

    -- 10. Tat ca NPC chay xe theo nhan vat chinh
    local allNpcsDriveToPlayerItem = NativeUI.CreateItem("Tat ca NPC chay xe theo nhan vat chinh", "Khien tat ca NPC lai xe theo nhan vat chinh.")
    mainMenu:AddItem(allNpcsDriveToPlayerItem)
    allNpcsDriveToPlayerItem.Activated = function(sender, item)
        AllNpcsDriveToPlayer()
    end

    -- 11. Tat ca NPC chay xe den diem dinh vi
    local allNpcsDriveToWaypointItem = NativeUI.CreateItem("Tat ca NPC chay xe den diem dinh vi", "Khien tat ca NPC lai xe den diem dinh vi tren ban do.")
    mainMenu:AddItem(allNpcsDriveToWaypointItem)
    allNpcsDriveToWaypointItem.Activated = function(sender, item)
        AllNpcsDriveToWaypoint()
    end

    -- 12. Sao chep Emote
    local copyEmoteMenuItem = NativeUI.CreateItem("Sao chep Emote", "Cho pheps NPC sao chep Emote tu nhan vat chinh.")
    mainMenu:AddItem(copyEmoteMenuItem)
    copyEmoteMenuItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowNpcCopyEmoteMenu()
    end

    -- 13. Xep NPC thanh vong tron
    local formCircleItem = NativeUI.CreateItem("Xep NPC thanh vong tron", "Di chuyen tat ca NPC de tao thanh vong tron.")
    mainMenu:AddItem(formCircleItem)
    formCircleItem.Activated = function(sender, item)
        FormCircleWithNpcs()
    end

    -- 14. Tat ca NPC xep hang ngang
    local formRowMenuItem = NativeUI.CreateItem("Tat ca NPC xep hang ngang", "Xep tat ca NPC thanh hang ngang tu 1 den 10 hang.")
    mainMenu:AddItem(formRowMenuItem)
    formRowMenuItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowRowFormationMenu()
    end

    -- 15. Xep Hang Doc Nhom
    local verticalFormationItem = NativeUI.CreateItem("Xep Hang Doc Nhom", "Xep nhom NPC thanh hang doc.")
    mainMenu:AddItem(verticalFormationItem)
    verticalFormationItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowGroupVerticalFormationMenu()
    end

    -- 16. Dieu huong nhom NPC
    local navigateGroupItem = NativeUI.CreateItem("Dieu Huong Nhom NPC", "Dieu huong cac nhom NPC da tao.")
    mainMenu:AddItem(navigateGroupItem)
    navigateGroupItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowGroupNavigationMenu()
    end

    -- 17. Xep Hang Ngang Nhom
    local groupFormationItem = NativeUI.CreateItem("Xep Hang Ngang Nhom", "Xep nhom NPC thanh hang ngang.")
    mainMenu:AddItem(groupFormationItem)
    groupFormationItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowGroupFormationMenu()
    end

    -- 18. Xep hinh tam giac
    local triangleFormationItem = NativeUI.CreateItem("Xep Hinh Tam Giac", "Xep nhom NPC thanh hinh tam giac.")
    mainMenu:AddItem(triangleFormationItem)
    triangleFormationItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowTriangleFormationMenu()
    end

    -- 19. Dieu chinh tung NPC
    local adjustNpcPositionItem = NativeUI.CreateItem("Dieu chinh vi tri/huong NPC", "Chon NPC de dieu chinh vi tri hoac huong.")
    mainMenu:AddItem(adjustNpcPositionItem)
    adjustNpcPositionItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowAdjustNpcMenu()
    end

    -- 20. Xoa NPC
    local deleteNpcItem = NativeUI.CreateItem("Xoa NPC", "Chon NPC tu danh sach de xoa.")
    mainMenu:AddItem(deleteNpcItem)
    deleteNpcItem.Activated = function(sender, item)
        mainMenu:Visible(false)
        ShowDeleteMenu()
    end

    _menuPool:RefreshIndex()
end

-- ==========================================
-- SUBMENUS
-- ==========================================

-- Submenu Xoa NPC
function ShowDeleteMenu()
    local deleteMenu = NativeUI.CreateMenu("Xoa NPC", "Chon NPC hoac nhom de xoa")
    _menuPool:Add(deleteMenu)

    local deleteAllItem = NativeUI.CreateItem("Xoa tat ca NPC", "Xoa toan bo NPC trong danh sach.")
    deleteMenu:AddItem(deleteAllItem)
    deleteAllItem.Activated = function(sender, item)
        DeleteAllNPCs()
        deleteMenu:Visible(false)
    end

    for groupId, group in pairs(npcGroups) do
        local groupDeleteItem = NativeUI.CreateItem("Xoa Nhom " .. groupId, "Xoa tat ca NPC trong nhom " .. groupId)
        deleteMenu:AddItem(groupDeleteItem)
        groupDeleteItem.Activated = function(sender, item)
            DeleteNpcGroup(groupId)
            deleteMenu:Visible(false)
        end
    end

    for npcName, npcPed in pairs(npcList) do
        local npcItem = NativeUI.CreateItem(npcName, "Xoa NPC co ten '" .. npcName .. "'")
        deleteMenu:AddItem(npcItem)
        npcItem.Activated = function(sender, item)
            DeleteNPC(npcName)
            deleteMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    deleteMenu:Visible(true)
end

-- Submenu Dieu Chinh NPC
function ShowAdjustNpcMenu()
    local adjustMenu = NativeUI.CreateMenu("Dieu chinh NPC", "Chon NPC de dieu chinh")
    _menuPool:Add(adjustMenu)

    for npcName, npcPed in pairs(npcList) do
        local npcItem = NativeUI.CreateItem(npcName, "Dieu chinh vi tri/huong cho NPC " .. npcName)
        adjustMenu:AddItem(npcItem)

        npcItem.Activated = function(sender, item)
            adjustMenu:Visible(false)
            AdjustNpcPosition(npcPed)
        end
    end

    _menuPool:RefreshIndex()
    adjustMenu:Visible(true)
end

-- Submenu Cap Sung Danh Muc
function ShowGiveWeaponMenu()
    local weaponCategoryMenu = NativeUI.CreateMenu("Cap Sung", "Chon danh muc vu khi")
    _menuPool:Add(weaponCategoryMenu)

    for _, category in ipairs(weaponCategories) do
        local categoryItem = NativeUI.CreateItem(category.label, "Chon de xem cac loai sung trong danh muc " .. category.label)
        weaponCategoryMenu:AddItem(categoryItem)

        categoryItem.Activated = function(sender, item)
            ShowWeaponMenu(category)
            weaponCategoryMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    weaponCategoryMenu:Visible(true)
end

function ShowWeaponMenu(category)
    local weaponMenu = NativeUI.CreateMenu(category.label, "Chon loai sung de cap cho NPC")
    _menuPool:Add(weaponMenu)

    for _, weapon in ipairs(category.weapons) do
        local weaponItem = NativeUI.CreateItem(weapon.label, "Cap " .. weapon.label .. " cho NPC")
        weaponMenu:AddItem(weaponItem)

        weaponItem.Activated = function(sender, item)
            ShowNpcWeaponSelectMenu(weapon.weapon)
            weaponMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    weaponMenu:Visible(true)
end

function ShowNpcWeaponSelectMenu(weaponHash)
    local npcWeaponMenu = NativeUI.CreateMenu("Chon NPC", "Cap sung cho NPC")
    _menuPool:Add(npcWeaponMenu)

    local giveAllItem = NativeUI.CreateItem("Cap cho Tat Ca NPC", "Cap vu khi nay cho tat ca NPC")
    npcWeaponMenu:AddItem(giveAllItem)
    giveAllItem.Activated = function(sender, item)
        for _, npcPed in pairs(npcList) do
            GiveWeaponToNpc(npcPed, weaponHash)
        end
        npcWeaponMenu:Visible(false)
    end

    for npcName, npcPed in pairs(npcList) do
        local npcItem = NativeUI.CreateItem(npcName, "Cap vu khi cho NPC " .. npcName)
        npcWeaponMenu:AddItem(npcItem)
        npcItem.Activated = function(sender, item)
            GiveWeaponToNpc(npcPed, weaponHash)
            npcWeaponMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    npcWeaponMenu:Visible(true)
end

-- Submenu Di Chuyen Tat Ca NPC
function ShowMoveAllNpcsMenu()
    local moveMenu = NativeUI.CreateMenu("Di chuyen NPC", "Chon kieu di chuyen cho NPC")
    _menuPool:Add(moveMenu)

    local walkItem = NativeUI.CreateItem("Di bo", "Di chuyen tat ca NPC den vi tri danh dau bang cach di bo.")
    moveMenu:AddItem(walkItem)
    walkItem.Activated = function(sender, item)
        MoveAllNpcsToLocation("walk")
        moveMenu:Visible(false)
    end

    local runItem = NativeUI.CreateItem("Chay", "Di chuyen tat ca NPC den vi tri danh dau bang cach chay.")
    moveMenu:AddItem(runItem)
    runItem.Activated = function(sender, item)
        MoveAllNpcsToLocation("run")
        moveMenu:Visible(false)
    end

    local followPlayerItem = NativeUI.CreateItem("Theo doi nhan vat chinh", "Khien tat ca NPC di theo nhan vat chinh.")
    moveMenu:AddItem(followPlayerItem)
    followPlayerItem.Activated = function(sender, item)
        FollowPlayerWithAllNpcs()
        moveMenu:Visible(false)
    end

    local stopItem = NativeUI.CreateItem("Dung tat ca NPC", "Khien tat ca NPC dung lai ngay lap tuc.")
    moveMenu:AddItem(stopItem)
    stopItem.Activated = function(sender, item)
        StopAllNpcs()
        moveMenu:Visible(false)
    end

    _menuPool:RefreshIndex()
    moveMenu:Visible(true)
end

-- Submenu Nhep Mieng NPC
function ShowLipSyncMenu()
    local lipSyncMenu = NativeUI.CreateMenu("Nhep mieng NPC", "Chon NPC de tu dong nhep mieng")
    _menuPool:Add(lipSyncMenu)

    for npcName, npcPed in pairs(npcList) do
        local npcItem = NativeUI.CreateItem(npcName, "Kich hoat nhep mieng cho NPC " .. npcName)
        lipSyncMenu:AddItem(npcItem)
        npcItem.Activated = function(sender, item)
            ToggleNpcLipSync(npcPed)
            lipSyncMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    lipSyncMenu:Visible(true)
end

-- Submenu NPC Len/Xuong Xe
function ShowNpcEnterVehicleMenu()
    local npcEnterVehicleMenu = NativeUI.CreateMenu("NPC len/xuong xe", "Chon hanh dong len hoac xuong xe")
    _menuPool:Add(npcEnterVehicleMenu)

    local allNpcsEnterItem = NativeUI.CreateItem("Tat ca NPC len xe", "Tat ca NPC se tu dong tim ghe lai hoac phu de len xe.")
    npcEnterVehicleMenu:AddItem(allNpcsEnterItem)
    allNpcsEnterItem.Activated = function(sender, item)
        AllNpcsEnterVehicle()
        npcEnterVehicleMenu:Visible(false)
    end

    local allNpcsExitItem = NativeUI.CreateItem("Tat ca NPC xuong xe", "Tat ca NPC se xuong xe.")
    npcEnterVehicleMenu:AddItem(allNpcsExitItem)
    allNpcsExitItem.Activated = function(sender, item)
        AllNpcsExitVehicle()
        npcEnterVehicleMenu:Visible(false)
    end

    for npcName, npcPed in pairs(npcList) do
        local npcItem = NativeUI.CreateItem(npcName, "Cho NPC '" .. npcName .. "' len xe")
        npcEnterVehicleMenu:AddItem(npcItem)
        npcItem.Activated = function(sender, item)
            local vehicle = GetClosestVehicleToNpc(npcPed)
            if vehicle then
                ShowSeatSelectionMenu(npcPed, vehicle)
            else
                print("[ERROR] Khong tim thay xe gan NPC '" .. npcName .. "'.")
            end
            npcEnterVehicleMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    npcEnterVehicleMenu:Visible(true)
end

-- Submenu Chon Ghe Xe
function ShowSeatSelectionMenu(npcPed, vehicle)
    local seatMenu = NativeUI.CreateMenu("Chon ghe", "Chon ghe de NPC ngoi")
    _menuPool:Add(seatMenu)

    local driverSeatItem = NativeUI.CreateItem("Ghe lai", "NPC se ngoi ghe lai.")
    seatMenu:AddItem(driverSeatItem)
    driverSeatItem.Activated = function(sender, item)
        TaskEnterVehicle(npcPed, vehicle, -1, -1, 1.0, 1, 0)
        print("[INFO] NPC da vao ghe lai.")
        seatMenu:Visible(false)
    end

    local passengerSeatItem = NativeUI.CreateItem("Ghe phu", "NPC se ngoi ghe phu.")
    seatMenu:AddItem(passengerSeatItem)
    passengerSeatItem.Activated = function(sender, item)
        TaskEnterVehicle(npcPed, vehicle, -1, 0, 1.0, 1, 0)
        print("[INFO] NPC da vao ghe phu.")
        seatMenu:Visible(false)
    end

    local backSeatItem = NativeUI.CreateItem("Ghe sau (tu dong)", "NPC se ngoi vao ghe sau neu co ghe trong.")
    seatMenu:AddItem(backSeatItem)
    backSeatItem.Activated = function(sender, item)
        local seatIndex = FindFreeSeat(vehicle)
        if seatIndex ~= -1 then
            TaskEnterVehicle(npcPed, vehicle, -1, seatIndex, 1.0, 1, 0)
            print("[INFO] NPC da vao ghe: " .. seatIndex)
        else
            print("[ERROR] Khong co ghe trong trong xe.")
        end
        seatMenu:Visible(false)
    end

    _menuPool:RefreshIndex()
    seatMenu:Visible(true)
end

-- Submenu NPC Lai Xe Quanh Khu Vuc
function ShowNpcDriveAroundMenu()
    local npcDriveAroundMenu = NativeUI.CreateMenu("NPC lai xe quanh khu vuc", "Chon NPC de lai xe quanh khu vuc")
    _menuPool:Add(npcDriveAroundMenu)

    for npcName, npcPed in pairs(npcList) do
        local npcItem = NativeUI.CreateItem(npcName, "Chon NPC " .. npcName .. " de lai xe quanh khu vuc")
        npcDriveAroundMenu:AddItem(npcItem)
        npcItem.Activated = function(sender, item)
            StartNpcDriveAroundNearby(npcPed)
            npcDriveAroundMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    npcDriveAroundMenu:Visible(true)
end

-- Submenu Sao Chep Emote
function ShowNpcCopyEmoteMenu()
    local npcCopyEmoteMenu = NativeUI.CreateMenu("Sao chep Emote", "Chon NPC hoac tat ca NPC de sao chep Emote")
    _menuPool:Add(npcCopyEmoteMenu)

    local allNpcsItem = NativeUI.CreateItem("Tat ca NPC", "Tat ca NPC se sao chep Emote da luu")
    npcCopyEmoteMenu:AddItem(allNpcsItem)
    allNpcsItem.Activated = function(sender, item)
        CopyEmoteToAllNpcs()
        npcCopyEmoteMenu:Visible(false)
    end

    for npcName, npcPed in pairs(npcList) do
        local npcItem = NativeUI.CreateItem(npcName, "Cho NPC " .. npcName .. " sao chep Emote")
        npcCopyEmoteMenu:AddItem(npcItem)
        npcItem.Activated = function(sender, item)
            CopyPlayerEmoteToNpc(npcPed)
            npcCopyEmoteMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    npcCopyEmoteMenu:Visible(true)
end

-- Submenu Xep Hang Ngang Tat Ca NPC
function ShowRowFormationMenu()
    local rowMenu = NativeUI.CreateMenu("Xep hang ngang", "Chon so hang de xep tat ca NPC")
    _menuPool:Add(rowMenu)

    for i = 1, 10 do
        local rowItem = NativeUI.CreateItem(i .. " Hang", "Xep tat ca NPC thanh " .. i .. " hang ngang.")
        rowMenu:AddItem(rowItem)
        rowItem.Activated = function(sender, item)
            FormRowsWithNpcs(i)
            rowMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    rowMenu:Visible(true)
end

-- Submenu Tao NPC Tu Dong
function ShowAutoNpcCreationMenu()
    local autoNpcMenu = NativeUI.CreateMenu("Tao NPC Tu Dong", "Nhap so luong NPC can tao")
    _menuPool:Add(autoNpcMenu)

    local enterNumberItem = NativeUI.CreateItem("Nhap so luong", "Nhap so luong NPC ban muon tao.")
    autoNpcMenu:AddItem(enterNumberItem)
    enterNumberItem.Activated = function(sender, item)
        DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP8", "", "", "", "", "", 5)
        while UpdateOnscreenKeyboard() == 0 do
            Citizen.Wait(0)
        end

        local result = tonumber(GetOnscreenKeyboardResult())
        if result and result > 0 then
            CreateAutoNpcGroup(result)
            autoNpcMenu:Visible(false)
        else
            print("[ERROR] So luong khong hop le.")
        end
    end

    local options = {10, 20, 30, 40, 50}
    for _, count in ipairs(options) do
        local item = NativeUI.CreateItem("Tao " .. count .. " NPC", "Tao tu dong " .. count .. " NPC.")
        autoNpcMenu:AddItem(item)
        item.Activated = function(sender, selected)
            CreateAutoNpcGroup(count)
            autoNpcMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    autoNpcMenu:Visible(true)
end

-- Submenu Xep Hang Ngang Nhom
function ShowGroupFormationMenu()
    local groupFormationMenu = NativeUI.CreateMenu("Xep Hang Nhom NPC", "Chon nhom de xep hang ngang")
    _menuPool:Add(groupFormationMenu)

    for groupId, group in pairs(npcGroups) do
        local groupItem = NativeUI.CreateItem("Nhom " .. groupId, "Xep hang ngang cho nhom " .. groupId)
        groupFormationMenu:AddItem(groupItem)
        groupItem.Activated = function(sender, item)
            ShowRowFormationForGroupMenu(groupId)
        end
    end

    _menuPool:RefreshIndex()
    groupFormationMenu:Visible(true)
end

function ShowRowFormationForGroupMenu(groupId)
    _menuPool:CloseAllMenus()
    local rowMenu = NativeUI.CreateMenu("Xep Hang Nhom " .. groupId, "Chon so hang de xep")
    _menuPool:Add(rowMenu)

    for i = 1, 10 do
        local rowItem = NativeUI.CreateItem(i .. " Hang", "Xep nhom thanh " .. i .. " hang ngang.")
        rowMenu:AddItem(rowItem)
        rowItem.Activated = function(sender, item)
            ArrangeNpcsInGroupRows(groupId, i)
            rowMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    rowMenu:Visible(true)
end

-- Submenu Dieu Huong Nhom NPC
function ShowGroupNavigationMenu()
    local groupNavMenu = NativeUI.CreateMenu("Dieu Huong Nhom NPC", "Chon nhom de dieu huong")
    _menuPool:Add(groupNavMenu)

    groupNavMenu.OnMenuClosed = function()
        mainMenu:Visible(true)
    end

    for groupId, group in pairs(npcGroups) do
        local groupItem = NativeUI.CreateItem("Nhom " .. groupId, "Chon nhom " .. groupId)
        groupNavMenu:AddItem(groupItem)
        groupItem.Activated = function(sender, selected)
            groupNavMenu:Visible(false)
            AdjustNpcGroupPositions(groupId)
        end
    end

    _menuPool:RefreshIndex()
    groupNavMenu:Visible(true)
end

-- Submenu Xep Hang Doc Nhom
function ShowGroupVerticalFormationMenu()
    local verticalFormationMenu = NativeUI.CreateMenu("Xep Hang Doc Nhom", "Chon nhom de xep hang doc")
    _menuPool:Add(verticalFormationMenu)

    for groupId, group in pairs(npcGroups) do
        local groupItem = NativeUI.CreateItem("Nhom " .. groupId, "Xep hang doc cho nhom " .. groupId)
        verticalFormationMenu:AddItem(groupItem)
        groupItem.Activated = function(sender, item)
            ShowVerticalRowFormationForGroupMenu(groupId)
        end
    end

    _menuPool:RefreshIndex()
    verticalFormationMenu:Visible(true)
end

function ShowVerticalRowFormationForGroupMenu(groupId)
    _menuPool:CloseAllMenus()
    local rowMenu = NativeUI.CreateMenu("Xep Hang Doc Nhom " .. groupId, "Chon so hang doc de xep")
    _menuPool:Add(rowMenu)

    for i = 1, 10 do
        local rowItem = NativeUI.CreateItem(i .. " Hang Doc", "Xep nhom thanh " .. i .. " hang doc.")
        rowMenu:AddItem(rowItem)
        rowItem.Activated = function(sender, item)
            ArrangeNpcsInGroupVerticalRows(groupId, i)
            rowMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    rowMenu:Visible(true)
end

-- Submenu Xep Hinh Tam Giac
function ShowTriangleFormationMenu()
    local triangleMenu = NativeUI.CreateMenu("Xep Hinh Tam Giac", "Chon nhom NPC de xep hinh tam giac")
    _menuPool:Add(triangleMenu)

    for groupId, group in pairs(npcGroups) do
        local groupItem = NativeUI.CreateItem("Nhom " .. groupId, "Xep hinh tam giac cho nhom " .. groupId)
        triangleMenu:AddItem(groupItem)
        groupItem.Activated = function(sender, item)
            ArrangeNpcsInTriangle(groupId, 5.0)
            triangleMenu:Visible(false)
        end
    end

    _menuPool:RefreshIndex()
    triangleMenu:Visible(true)
end

-- ==========================================
-- LOGIC & CORE FUNCTIONS FOR NPC
-- ==========================================

-- Tao NPC don le
function CreateNPC(npcName)
    if npcList[npcName] then
        DeleteEntity(npcList[npcName])
        npcList[npcName] = nil
    end

    local playerPed = PlayerPedId()
    local modelHash = GetEntityModel(playerPed)

    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(0)
    end

    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    local npcPed = CreatePed(4, modelHash, playerCoords.x + 1.0, playerCoords.y, playerCoords.z, playerHeading, true, true)
    SetEntityAsMissionEntity(npcPed, true, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    TaskStandStill(npcPed, -1)

    if not IsModelAnimal(modelHash) then
        CopyCharacterAttributes(playerPed, npcPed)
    else
        SetPedDefaultAttributesForAnimal(npcPed)
    end

    npcList[npcName] = npcPed
    print("[INFO] NPC da duoc tao voi ten: " .. npcName)
    SetModelAsNoLongerNeeded(modelHash)
end

-- Sao chep thuoc tinh cua nhan vat chinh sang NPC
function CopyCharacterAttributes(sourcePed, targetPed)
    if not DoesEntityExist(sourcePed) or not DoesEntityExist(targetPed) then
        print("[ERROR] SourcePed hoac TargetPed khong ton tai.")
        return
    end

    -- Sao chep face features
    for i = 0, 19 do
        local featureValue = GetPedFaceFeature(sourcePed, i)
        if featureValue then
            SetPedFaceFeature(targetPed, i, featureValue)
        end
    end

    -- Head blend data
    local isBlendDataValid, shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix = GetPedHeadBlendData(sourcePed)
    if isBlendDataValid then
        SetPedHeadBlendData(
            targetPed,
            shapeFirst, shapeSecond, shapeThird,
            skinFirst, skinSecond, skinThird,
            shapeMix or 0.5, skinMix or 0.5, thirdMix or 0.0,
            false
        )
    end

    -- Toc
    local hairDrawable = GetPedDrawableVariation(sourcePed, 2)
    local hairTexture = GetPedTextureVariation(sourcePed, 2)
    SetPedComponentVariation(targetPed, 2, hairDrawable, hairTexture, 0)

    -- Mau toc
    local hairColor = GetPedHairColor(sourcePed)
    local hairHighlightColor = GetPedHairHighlightColor(sourcePed)
    SetPedHairColor(targetPed, hairColor, hairHighlightColor)

    -- Overlays (Trang diem, rau, vet seo...)
    for overlayId = 0, 12 do
        local overlayValue = GetPedHeadOverlayValue(sourcePed, overlayId)
        if overlayValue and overlayValue ~= 255 then
            SetPedHeadOverlay(targetPed, overlayId, overlayValue, 1.0)
            SetPedHeadOverlayColor(targetPed, overlayId, 1, 1, 0)
        end
    end

    -- Mau mat
    local eyeColor = GetPedEyeColor(sourcePed)
    if eyeColor then
        SetPedEyeColor(targetPed, eyeColor)
    end

    -- Trang phuc
    for componentId = 0, 11 do
        local drawableIndex = GetPedDrawableVariation(sourcePed, componentId)
        local textureIndex = GetPedTextureVariation(sourcePed, componentId)
        SetPedComponentVariation(targetPed, componentId, drawableIndex, textureIndex, 0)
    end

    -- Phuk kien (Props)
    for propId = 0, 7 do
        local propDrawable = GetPedPropIndex(sourcePed, propId)
        local propTexture = GetPedPropTextureIndex(sourcePed, propId)
        if propDrawable ~= -1 then
            SetPedPropIndex(targetPed, propId, propDrawable, propTexture, true)
        else
            ClearPedProp(targetPed, propId)
        end
    end
end

-- Cai dat dac tinh dong vat
function SetPedDefaultAttributesForAnimal(npcPed)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    ClearPedTasksImmediately(npcPed)
    TaskStandStill(npcPed, -1)
    print("[INFO] NPC dong vat duoc giu yen.")
end

function IsModelAnimal(modelHash)
    local animalModels = {
        [GetHashKey("a_c_chop")] = true,
        [GetHashKey("a_c_husky")] = true,
        [GetHashKey("a_c_cat_01")] = true,
        [GetHashKey("a_c_retriever")] = true,
        [GetHashKey("a_c_shepherd")] = true,
        [GetHashKey("a_c_pug")] = true,
        [GetHashKey("a_c_westy")] = true,
        [GetHashKey("a_c_rabbit_01")] = true
    }
    return animalModels[modelHash] or false
end

-- Xoa mot NPC theo ten
function DeleteNPC(npcName)
    if npcList[npcName] then
        local npcPed = npcList[npcName]
        if DoesEntityExist(npcPed) then
            DeleteEntity(npcPed)
            print("[INFO] NPC '" .. npcName .. "' da duoc xoa.")
        end
        npcList[npcName] = nil
    else
        print("[ERROR] NPC '" .. npcName .. "' khong ton tai.")
    end
end

-- Xoa tat ca NPC
function DeleteAllNPCs()
    for npcName, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            DeleteEntity(npcPed)
            print("[INFO] NPC '" .. npcName .. "' da duoc xoa.")
        end
    end
    npcList = {}
    npcGroups = {}
    print("[INFO] Tat ca NPC da duoc xoa.")
end

-- Xoa mot nhom NPC
function DeleteNpcGroup(groupId)
    if not npcGroups[groupId] then
        print("[ERROR] Nhom " .. groupId .. " khong ton tai.")
        return
    end

    for _, npcName in ipairs(npcGroups[groupId]) do
        if npcList[npcName] then
            DeleteNPC(npcName)
        end
    end

    npcGroups[groupId] = nil
    print("[INFO] Nhom NPC " .. groupId .. " da duoc xoa.")
end

-- Tao nhom NPC tu dong
function CreateAutoNpcGroup(groupSize)
    local groupId = #npcGroups + 1
    npcGroups[groupId] = {}

    for i = 1, groupSize do
        local npcName = "NPC_" .. groupId .. "_" .. i
        CreateNPC(npcName)
        table.insert(npcGroups[groupId], npcName)
    end

    print("[INFO] Da tao " .. groupSize .. " NPC trong nhom " .. groupId)
end

-- Dieu chinh vi tri tung NPC bang ban phim
function AdjustNpcPosition(npcPed)
    Citizen.CreateThread(function()
        local adjusting = true
        while adjusting do
            Citizen.Wait(0)

            -- Di chuyen bang phim NUMPAD 4/6/8/2
            if IsControlPressed(0, 108) then -- NUMPAD 4 (trai)
                TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, -0.5, 0.0, 0.0), 1.0, 1000, GetEntityHeading(npcPed) - 90.0, 0)
            elseif IsControlPressed(0, 109) then -- NUMPAD 6 (phai)
                TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.5, 0.0, 0.0), 1.0, 1000, GetEntityHeading(npcPed) + 90.0, 0)
            elseif IsControlPressed(0, 111) then -- NUMPAD 8 (len)
                TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.0, 0.5, 0.0), 1.0, 1000, GetEntityHeading(npcPed), 0)
            elseif IsControlPressed(0, 110) then -- NUMPAD 2 (xuong)
                TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.0, -0.5, 0.0), 1.0, 1000, GetEntityHeading(npcPed) + 180.0, 0)
            end

            -- Xoay bang NUMPAD 7 (Q) va 9 (E)
            if IsControlPressed(0, 117) then -- NUMPAD 7
                local heading = GetEntityHeading(npcPed)
                SetEntityHeading(npcPed, heading + 1.0)
            elseif IsControlPressed(0, 118) then -- NUMPAD 9
                local heading = GetEntityHeading(npcPed)
                SetEntityHeading(npcPed, heading - 1.0)
            end

            -- Nhan pham Enter (Numpad Enter hoac thuong) de luu
            if IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201) then
                ClearPedTasks(npcPed)
                adjusting = false
                print("[INFO] Da luu vi tri/huong cua NPC.")
            end
        end
    end)
end

-- Dieu chinh vi tri cua tat ca NPC cung luc
function AdjustAllNpcPositions()
    Citizen.CreateThread(function()
        local adjusting = true
        while adjusting do
            Citizen.Wait(0)

            -- Di chuyen tat ca
            if IsControlPressed(0, 108) then -- NUMPAD 4
                for _, npcPed in pairs(npcList) do
                    TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, -0.5, 0.0, 0.0), 1.0, 1000, GetEntityHeading(npcPed) - 90.0, 0)
                end
            elseif IsControlPressed(0, 109) then -- NUMPAD 6
                for _, npcPed in pairs(npcList) do
                    TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.5, 0.0, 0.0), 1.0, 1000, GetEntityHeading(npcPed) + 90.0, 0)
                end
            elseif IsControlPressed(0, 111) then -- NUMPAD 8
                for _, npcPed in pairs(npcList) do
                    TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.0, 0.5, 0.0), 1.0, 1000, GetEntityHeading(npcPed), 0)
                end
            elseif IsControlPressed(0, 110) then -- NUMPAD 2
                for _, npcPed in pairs(npcList) do
                    TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.0, -0.5, 0.0), 1.0, 1000, GetEntityHeading(npcPed) + 180.0, 0)
                end
            end

            -- Xoay tat ca
            if IsControlPressed(0, 117) then -- NUMPAD 7
                for _, npcPed in pairs(npcList) do
                    local heading = GetEntityHeading(npcPed)
                    SetEntityHeading(npcPed, heading + 1.0)
                end
            elseif IsControlPressed(0, 118) then -- NUMPAD 9
                for _, npcPed in pairs(npcList) do
                    local heading = GetEntityHeading(npcPed)
                    SetEntityHeading(npcPed, heading - 1.0)
                end
            end

            -- Luu bang Enter
            if IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201) then
                for _, npcPed in pairs(npcList) do
                    ClearPedTasks(npcPed)
                end
                adjusting = false
                print("[INFO] Da luu vi tri/huong cua tat ca NPC.")
            end
        end
    end)
end

-- Dieu huong vi tri nhom NPC
function AdjustNpcGroupPositions(groupId)
    local npcs = GetValidNpcsInGroup(groupId)
    if #npcs == 0 then
        print("[ERROR] Nhom khong co NPC hop le.")
        return
    end

    Citizen.CreateThread(function()
        local adjusting = true
        while adjusting do
            Citizen.Wait(0)

            -- Dieu huong
            if IsControlPressed(0, 108) then -- NUMPAD 4
                for _, npcPed in ipairs(npcs) do
                    TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, -0.5, 0.0, 0.0), 1.0, 1000, GetEntityHeading(npcPed), 0)
                end
            elseif IsControlPressed(0, 109) then -- NUMPAD 6
                for _, npcPed in ipairs(npcs) do
                    TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.5, 0.0, 0.0), 1.0, 1000, GetEntityHeading(npcPed), 0)
                end
            elseif IsControlPressed(0, 111) then -- NUMPAD 8
                for _, npcPed in ipairs(npcs) do
                    TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.0, 0.5, 0.0), 1.0, 1000, GetEntityHeading(npcPed), 0)
                end
            elseif IsControlPressed(0, 110) then -- NUMPAD 2
                for _, npcPed in ipairs(npcs) do
                    TaskGoStraightToCoord(npcPed, GetOffsetFromEntityInWorldCoords(npcPed, 0.0, -0.5, 0.0), 1.0, 1000, GetEntityHeading(npcPed), 0)
                end
            end

            -- Xoay
            if IsControlPressed(0, 117) then -- NUMPAD 7
                for _, npcPed in ipairs(npcs) do
                    local heading = GetEntityHeading(npcPed)
                    SetEntityHeading(npcPed, heading + 1.0)
                end
            elseif IsControlPressed(0, 118) then -- NUMPAD 9
                for _, npcPed in ipairs(npcs) do
                    local heading = GetEntityHeading(npcPed)
                    SetEntityHeading(npcPed, heading - 1.0)
                end
            end

            -- Luu
            if IsControlJustPressed(0, 191) or IsControlJustPressed(0, 201) then
                for _, npcPed in ipairs(npcs) do
                    ClearPedTasks(npcPed)
                end
                print("[INFO] Vi tri va huong cua nhom da duoc luu.")
                adjusting = false
            end
        end
    end)
end

-- Cap sung cho mot NPC
function GiveWeaponToNpc(npcPed, weaponHash)
    if DoesEntityExist(npcPed) then
        GiveWeaponToPed(npcPed, GetHashKey(weaponHash), 250, false, true)
        SetCurrentPedWeapon(npcPed, GetHashKey(weaponHash), true)
    end
end

-- Khien tat ca NPC di theo nguoi choi
function FollowPlayerWithAllNpcs()
    local playerPed = PlayerPedId()
    for _, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            TaskFollowToOffsetOfEntity(npcPed, playerPed, 0.0, 0.0, 0.0, 1.0, -1, 1.0, true)
        end
    end
    print("[INFO] Tat ca NPC dang di theo nhan vat chinh.")
end

-- Dung tat ca NPC
function StopAllNpcs()
    for _, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            ClearPedTasks(npcPed)
        end
    end
    print("[INFO] Tat ca NPC da dung lai.")
end

-- Dung tat ca hanh dong cua NPC lap tuc
function StopAllNpcsActions()
    for _, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            ClearPedTasksImmediately(npcPed)
            print("[INFO] NPC da dung moi hanh dong: " .. tostring(npcPed))
        end
    end
    print("[INFO] Tat ca NPC da dung hanh dong.")
end

-- Di chuyen den waypoint
function MoveAllNpcsToLocation(moveType)
    local blip = GetFirstBlipInfoId(8) -- Blip 8 la waypoint
    if DoesBlipExist(blip) then
        local targetPos = GetBlipInfoIdCoord(blip)

        for _, npcPed in pairs(npcList) do
            if DoesEntityExist(npcPed) then
                if moveType == "walk" then
                    TaskGoStraightToCoord(npcPed, targetPos.x, targetPos.y, targetPos.z, 1.0, -1, 0.0, 0)
                elseif moveType == "run" then
                    TaskGoStraightToCoord(npcPed, targetPos.x, targetPos.y, targetPos.z, 3.0, -1, 0.0, 0)
                end
            end
        end
        print("[INFO] Da di chuyen tat ca NPC den vi tri danh dau.")
    else
        print("[ERROR] Khong tim thay vi tri danh dau tren ban do.")
    end
end

-- Nhiep mieng cho NPC
local lipSyncAnimations = {
    {dict = "mp_facial", anim = "mic_chatter"},
    {dict = "facials@gen_male@base", anim = "mood_talking"},
    {dict = "mp_facial", anim = "mic_chatter_small"},
    {dict = "mp_facial", anim = "mic_chatter_large"}
}

function ToggleNpcLipSync(npcPed)
    if npcLipSyncActive[npcPed] then
        npcLipSyncActive[npcPed] = false
        ClearPedTasks(npcPed)
        print("[INFO] Da tat nhep mieng cho NPC.")
    else
        npcLipSyncActive[npcPed] = true
        Citizen.CreateThread(function()
            while npcLipSyncActive[npcPed] do
                local anim = lipSyncAnimations[math.random(#lipSyncAnimations)]
                if not HasAnimDictLoaded(anim.dict) then
                    RequestAnimDict(anim.dict)
                    while not HasAnimDictLoaded(anim.dict) do
                        Citizen.Wait(0)
                    end
                end

                PlayFacialAnim(npcPed, anim.anim, anim.dict)
                Citizen.Wait(math.random(400, 700))
            end
        end)
        print("[INFO] Da kich hoat nhep mieng cho NPC.")
    end
end

-- Kich hoat NPC tu danh nhau
function MakeAllNpcsFightEachOther()
    local npcPeds = {}
    for _, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            table.insert(npcPeds, npcPed)
        end
    end

    if #npcPeds < 2 then
        print("[ERROR] Can it nhat 2 NPC de danh lon.")
        return
    end

    for i, npcPed in ipairs(npcPeds) do
        local targetIndex = math.random(1, #npcPeds)
        while targetIndex == i do
            targetIndex = math.random(1, #npcPeds)
        end
        local targetPed = npcPeds[targetIndex]

        TaskCombatPed(npcPed, targetPed, 0, 16)
        SetPedCombatAttributes(npcPed, 46, true) -- Chien dau khong bo chay
    end
    print("[INFO] Kich hoat tat ca NPC danh lon voi nhau.")
end

-- Lên/xuống xe
function AllNpcsEnterVehicle()
    for npcName, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            local vehicle = GetClosestVehicleToNpc(npcPed)
            if vehicle and DoesEntityExist(vehicle) then
                local seatIndex = FindFreeSeat(vehicle)
                if seatIndex ~= -1 then
                    TaskEnterVehicle(npcPed, vehicle, -1, seatIndex, 1.0, 1, 0)
                    print("[INFO] " .. npcName .. " da len xe tai ghe: " .. seatIndex)
                else
                    print("[ERROR] " .. npcName .. " khong the len xe: Khong con ghe trong.")
                end
            else
                print("[ERROR] " .. npcName .. " khong tim thay xe gan do.")
            end
        end
    end
end

function AllNpcsExitVehicle()
    for _, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) and IsPedInAnyVehicle(npcPed, false) then
            TaskLeaveVehicle(npcPed, GetVehiclePedIsIn(npcPed, false), 0)
            print("[INFO] NPC da xuong xe.")
        end
    end
end

-- NPC lai xe quanh khu vuc
function StartNpcDriveAroundNearby(npcPed)
    local vehicle = GetVehiclePedIsIn(npcPed, false)
    if vehicle and GetPedInVehicleSeat(vehicle, -1) == npcPed then
        local origin = GetEntityCoords(npcPed)
        MoveNpcWithinRadius(npcPed, vehicle, origin)
        print("[INFO] NPC dang lai xe quanh khu vuc voi toc do thap.")
    else
        print("[ERROR] NPC khong o trong xe hoac khong o ghe lai.")
    end
end

function MoveNpcWithinRadius(npcPed, vehicle, origin)
    Citizen.CreateThread(function()
        while DoesEntityExist(npcPed) and IsPedInAnyVehicle(npcPed, false) do
            Citizen.Wait(1000)
            local npcCoords = GetEntityCoords(npcPed)
            local distance = #(npcCoords - origin)

            if distance > maxDistance then
                TaskVehicleDriveToCoordLongrange(npcPed, vehicle, origin.x, origin.y, origin.z, driveSpeed, 786603, 10.0)
            else
                TaskVehicleDriveWander(npcPed, vehicle, driveSpeed, 786603)
            end
        end
    end)
end

-- Lai xe theo nguoi choi hoac waypoint
function AllNpcsDriveToPlayer()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for npcName, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            local vehicle = GetVehiclePedIsIn(npcPed, false)
            if vehicle and GetPedInVehicleSeat(vehicle, -1) == npcPed then
                Citizen.CreateThread(function()
                    while DoesEntityExist(npcPed) and IsPedInAnyVehicle(npcPed, false) do
                        Citizen.Wait(1000)
                        playerCoords = GetEntityCoords(playerPed)
                        TaskVehicleDriveToCoordLongrange(npcPed, vehicle, playerCoords.x, playerCoords.y, playerCoords.z, 15.0, 2883621, 5.0)

                        local distance = #(GetEntityCoords(npcPed) - playerCoords)
                        if distance < 6.0 then
                            ClearPedTasks(npcPed)
                            print("[INFO] " .. npcName .. " da den gan nhan vat chinh.")
                            break
                        end
                    end
                end)
                print("[INFO] " .. npcName .. " dang lai xe theo nhan vat chinh.")
            else
                print("[ERROR] " .. npcName .. " khong o trong xe hoac khong phai ghe lai.")
            end
        end
    end
end

function AllNpcsDriveToWaypoint()
    local blip = GetFirstBlipInfoId(8) -- Waypoint
    if DoesBlipExist(blip) then
        local targetCoords = GetBlipInfoIdCoord(blip)

        for npcName, npcPed in pairs(npcList) do
            if DoesEntityExist(npcPed) then
                local vehicle = GetVehiclePedIsIn(npcPed, false)
                if vehicle and GetPedInVehicleSeat(vehicle, -1) == npcPed then
                    TaskVehicleDriveToCoordLongrange(npcPed, vehicle, targetCoords.x, targetCoords.y, targetCoords.z, 20.0, 1074528293, 5.0)
                    print("[INFO] " .. npcName .. " dang lai xe den diem dinh vi.")
                else
                    print("[ERROR] " .. npcName .. " khong o trong xe hoac khong phai ghe lai.")
                end
            end
        end
    else
        print("[ERROR] Khong tim thay diem dinh vi tren ban do.")
    end
end

-- Sao chep Emote cua nguoi choi
function CopyPlayerEmoteToNpc(npcPed)
    if playerAnimDict and playerAnimName then
        RequestAnimDict(playerAnimDict)
        while not HasAnimDictLoaded(playerAnimDict) do
            Citizen.Wait(0)
        end
        TaskPlayAnim(npcPed, playerAnimDict, playerAnimName, 8.0, -8.0, -1, 1, 0, false, false, false)
        print("[INFO] NPC da sao chep Emote: " .. playerAnimDict .. " - " .. playerAnimName)
    else
        print("[ERROR] Khong co Emote nao duoc luu.")
    end
end

function CopyEmoteToAllNpcs()
    if playerAnimDict and playerAnimName then
        RequestAnimDict(playerAnimDict)
        while not HasAnimDictLoaded(playerAnimDict) do
            Citizen.Wait(0)
        end
        for _, npcPed in pairs(npcList) do
            if DoesEntityExist(npcPed) then
                TaskPlayAnim(npcPed, playerAnimDict, playerAnimName, 8.0, -8.0, -1, 1, 0, false, false, false)
            end
        end
        print("[INFO] Tat ca NPC da sao chep Emote: " .. playerAnimDict .. " - " .. playerAnimName)
    else
        print("[ERROR] Khong co Emote nao duoc luu.")
    end
end

function SetPlayerEmote(animDict, animName)
    emoteData.dict = animDict
    emoteData.name = animName
    playerAnimDict = animDict
    playerAnimName = animName

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(0)
    end
    print("[INFO] Da luu Emote: " .. animDict .. " - " .. animName)
end

function PerformEmoteOnAllNpcs()
    if not playerAnimDict or not playerAnimName then
        print("[ERROR] Khong co Emote nao duoc luu. Su dung lenh `/setnpc`.")
        return
    end

    RequestAnimDict(playerAnimDict)
    while not HasAnimDictLoaded(playerAnimDict) do
        Citizen.Wait(0)
    end

    for _, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            TaskPlayAnim(npcPed, playerAnimDict, playerAnimName, 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end
    print("[INFO] Tat ca NPC da thuc hien emote.")
end

-- ==========================================
-- SẮP XẾP ĐỘI HÌNH (NPC FORMATIONS)
-- ==========================================

-- Vong tron
function FormCircleWithNpcs()
    local validNpcs = {}
    for _, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            table.insert(validNpcs, npcPed)
        end
    end

    if #validNpcs == 0 then
        print("[ERROR] Khong co NPC de sap xep.")
        return
    end

    local centerCoords = GetEntityCoords(PlayerPedId())
    local radius = math.max(1.5, #validNpcs * 0.15)
    local angleStep = 360 / #validNpcs
    local currentAngle = 0.0

    for _, npcPed in ipairs(validNpcs) do
        local offsetX = math.cos(math.rad(currentAngle)) * radius
        local offsetY = math.sin(math.rad(currentAngle)) * radius
        local targetCoords = vector3(centerCoords.x + offsetX, centerCoords.y + offsetY, centerCoords.z)

        TaskGoStraightToCoord(npcPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, GetHeadingFromVector_2d(offsetX, offsetY), 0)
        currentAngle = currentAngle + angleStep
    end
    print("[INFO] Tat ca NPC da duoc sap xep thanh vong tron.")
end

-- Hang ngang chung
function FormRowsWithNpcs(rows)
    local validNpcs = {}
    for _, npcPed in pairs(npcList) do
        if DoesEntityExist(npcPed) then
            table.insert(validNpcs, npcPed)
        end
    end

    if #validNpcs == 0 then
        print("[ERROR] Khong co NPC de xep hang.")
        return
    end

    local centerCoords = GetEntityCoords(PlayerPedId())
    local rowSpacing = 1.0
    local colSpacing = 1.0
    local numPerRow = math.ceil(#validNpcs / rows)

    local currentRow = 0
    local currentCol = 0

    for _, npcPed in ipairs(validNpcs) do
        local offsetX = currentCol * colSpacing
        local offsetY = currentRow * rowSpacing
        local targetCoords = vector3(centerCoords.x + offsetX, centerCoords.y - offsetY, centerCoords.z)

        TaskGoStraightToCoord(npcPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, GetEntityHeading(PlayerPedId()), 0)

        currentCol = currentCol + 1
        if currentCol >= numPerRow then
            currentCol = 0
            currentRow = currentRow + 1
        end
    end
    print("[INFO] Tat ca NPC da xep thanh " .. rows .. " hang ngang.")
end

-- Hang ngang theo nhom
function ArrangeNpcsInGroupRows(groupId, rows)
    local groupNpcs = GetValidNpcsInGroup(groupId)
    if #groupNpcs == 0 then
        print("[ERROR] Nhom khong co NPC hop le.")
        return
    end

    local originCoords = npcGroupOrigin or GetEntityCoords(PlayerPedId())
    local heading = npcGroupHeading or GetEntityHeading(PlayerPedId())

    local rowSpacing = 2.0
    local colSpacing = 2.0
    local numPerRow = math.ceil(#groupNpcs / rows)

    local direction = vector3(math.cos(math.rad(heading)), math.sin(math.rad(heading)), 0)
    local perpendicular = vector3(-direction.y, direction.x, 0)

    local currentRow, currentCol = 0, 0
    for _, npcPed in ipairs(groupNpcs) do
        local offsetX = currentCol * colSpacing
        local offsetY = currentRow * rowSpacing
        local targetCoords = vector3(
            originCoords.x + offsetX * perpendicular.x + offsetY * direction.x,
            originCoords.y + offsetX * perpendicular.y + offsetY * direction.y,
            originCoords.z
        )

        TaskGoStraightToCoord(npcPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, heading, 0)

        currentCol = currentCol + 1
        if currentCol >= numPerRow then
            currentCol = 0
            currentRow = currentRow + 1
        end
    end
    print(string.format("[INFO] Nhom %d xep thanh %d hang ngang.", groupId, rows))
end

-- Hàng dọc theo nhóm
function ArrangeNpcsInGroupVerticalRows(groupId, rows)
    local groupNpcs = GetValidNpcsInGroup(groupId)
    if #groupNpcs == 0 then
        print("[ERROR] Nhom khong co NPC hop le.")
        return
    end

    local originCoords = npcGroupOrigin or GetEntityCoords(PlayerPedId())
    local heading = npcGroupHeading or GetEntityHeading(PlayerPedId())

    local rowSpacing = 2.0
    local colSpacing = 1.0
    local numPerRow = math.ceil(#groupNpcs / rows)

    local direction = vector3(math.cos(math.rad(heading)), math.sin(math.rad(heading)), 0)
    local perpendicular = vector3(-direction.y, direction.x, 0)

    local currentRow, currentCol = 0, 0
    for _, npcPed in ipairs(groupNpcs) do
        local offsetX = currentCol * perpendicular.x * colSpacing
        local offsetY = currentRow * direction.y * rowSpacing
        local targetCoords = vector3(
            originCoords.x + offsetX,
            originCoords.y + offsetY,
            originCoords.z
        )

        TaskGoStraightToCoord(npcPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, heading, 0)

        currentRow = currentRow + 1
        if currentRow >= numPerRow then
            currentRow = 0
            currentCol = currentCol + 1
        end
    end
    print(string.format("[INFO] Nhom %d xep thanh %d hang doc.", groupId, rows))
end

-- Hinh tam giac
function ArrangeNpcsInTriangle(groupId, baseDistance)
    local groupNpcs = GetValidNpcsInGroup(groupId)
    if #groupNpcs == 0 then
        print("[ERROR] Nhom khong co NPC hop le.")
        return
    end

    local originCoords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local direction = vector3(math.cos(math.rad(heading)), math.sin(math.rad(heading)), 0)
    local perpendicular = vector3(-direction.y, direction.x, 0)

    local currentRow = 0
    local npcsPlaced = 0
    local numNpcs = #groupNpcs

    while npcsPlaced < numNpcs do
        local rowCount = currentRow * 2 + 1
        local rowOffset = baseDistance + currentRow * 2.0

        for i = 1, rowCount do
            if npcsPlaced >= numNpcs then break end

            local rowWidth = (rowCount - 1) * 1.5
            local xOffset = (i - 1) * 1.5 - rowWidth / 2
            local yOffset = rowOffset

            local targetCoords = vector3(
                originCoords.x + direction.x * yOffset + perpendicular.x * xOffset,
                originCoords.y + direction.y * yOffset + perpendicular.y * xOffset,
                originCoords.z
            )

            local npcPed = groupNpcs[npcsPlaced + 1]
            TaskGoStraightToCoord(npcPed, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, heading, 0)
            npcsPlaced = npcsPlaced + 1
        end
        currentRow = currentRow + 1
    end
    print(string.format("[INFO] Nhom %d da xep thanh hinh tam giac.", groupId))
end

-- ==========================================
-- HELPERS
-- ==========================================
function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        local success
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end)
end

function GetClosestVehicleToNpc(npcPed)
    local npcCoords = GetEntityCoords(npcPed)
    local radius = 15.0
    local closestVehicle = nil
    local minDistance = math.huge

    for vehicle in EnumerateVehicles() do
        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(npcCoords - vehicleCoords)

            if distance < minDistance and distance <= radius then
                closestVehicle = vehicle
                minDistance = distance
            end
        end
    end
    return closestVehicle
end

function FindFreeSeat(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return -1
    end

    if IsVehicleSeatFree(vehicle, -1) then
        return -1
    end

    if IsVehicleSeatFree(vehicle, 0) then
        return 0
    end

    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    for seatIndex = 1, maxSeats do
        if IsVehicleSeatFree(vehicle, seatIndex) then
            return seatIndex
        end
    end
    return -1
end

function DebugVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        print("[DEBUG] Vehicle khong ton tai.")
        return
    end

    print("[DEBUG] Vehicle ton tai tai: " .. tostring(GetEntityCoords(vehicle)))
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    print("[DEBUG] Max Seats: " .. maxSeats)

    for seatIndex = -1, maxSeats do
        if IsVehicleSeatFree(vehicle, seatIndex) then
            print("[DEBUG] Seat " .. seatIndex .. " is free.")
        else
            print("[DEBUG] Seat " .. seatIndex .. " is occupied.")
        end
    end
end

function GetHeadingFromVector_2d(dx, dy)
    local heading = math.deg(math.atan2(dy, dx))
    return (heading >= 0) and heading or (360 + heading)
end

function GetValidNpcsInGroup(groupId)
    local validNpcs = {}
    if npcGroups[groupId] then
        for _, npcName in ipairs(npcGroups[groupId]) do
            if npcList[npcName] and DoesEntityExist(npcList[npcName]) then
                table.insert(validNpcs, npcList[npcName])
            end
        end
    end
    return validNpcs
end

-- ==========================================
-- REGISTERS COMMAND & THREADS
-- ==========================================

-- Lenh set huong va vi tri goc
RegisterCommand("setnpchuong", function(source, args, rawCommand)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    npcGroupHeading = playerHeading
    npcGroupOrigin = playerCoords

    print(string.format("[INFO] Dat huong %.2f do va vi tri goc (%.2f, %.2f, %.2f) cho Nhom NPC.", playerHeading, playerCoords.x, playerCoords.y, playerCoords.z))
end, false)

-- Lenh set khoang cach giua cac hang
RegisterCommand("setnpcvitri", function(source, args, rawCommand)
    local rowSpacing = tonumber(args[1]) or 1.0
    local colSpacing = tonumber(args[2]) or 1.0

    for groupId, _ in pairs(npcGroups) do
        npcGroups[groupId].rowSpacing = rowSpacing
        npcGroups[groupId].colSpacing = colSpacing
    end
    print(string.format("[INFO] Da dat khoang cach hang ngang %.2f va hang doc %.2f cho cac nhom NPC.", colSpacing, rowSpacing))
end, false)

-- Lenh set emote va thuc thi nhanh
RegisterCommand("setnpc", function(source, args, rawCommand)
    if #args < 2 then
        print("[ERROR] Cu phap sai. Dung: /setnpc [group/all] animDict animName")
        return
    end

    local target = args[1]
    local animDict = args[2]
    local animName = args[3]

    SetPlayerEmote(animDict, animName)

    if target == "all" then
        PerformEmoteOnAllNpcs()
    elseif tonumber(target) then
        local groupId = tonumber(target)
        local groupNpcs = GetValidNpcsInGroup(groupId)
        if #groupNpcs > 0 then
            for _, npcPed in ipairs(groupNpcs) do
                TaskPlayAnim(npcPed, playerAnimDict, playerAnimName, 8.0, -8.0, -1, 1, 0, false, false, false)
            end
            print("[INFO] Da thuc hien emote cho nhom " .. groupId)
        end
    else
        print("[ERROR] Khong tim thay nhom hoac muc tieu hop le.")
    end
end, false)

-- Khoi chay Menu bang F5
CreateMainMenu()

RegisterCommand("npcmenu", function()
    if mainMenu then
        mainMenu:Visible(not mainMenu:Visible())
        SetNuiFocus(false, false)
    end
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        _menuPool:ProcessMenus()

        -- if IsControlJustPressed(1, 166) then -- F5
        --     if mainMenu then
        --         mainMenu:Visible(not mainMenu:Visible())
        --         SetNuiFocus(false, false)
        --     end
        -- end
    end
end)

-- Vo hieu hoa chuot khi bat Menu de dieu huong bang phim
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if _menuPool:IsAnyMenuOpen() then
            DisableControlAction(0, 1, true)   -- Mouse X
            DisableControlAction(0, 2, true)   -- Mouse Y
            DisableControlAction(0, 142, true) -- Left Click
            DisableControlAction(0, 18, true)  -- Enter NUI
            DisableControlAction(0, 199, true) -- ESC
            DisableControlAction(0, 237, true) -- Right Click

            SetNuiFocus(false, false)
        else
            Citizen.Wait(250)
        end
    end
end)

-- Lang nghe phim bam NUM+ va NUM- de dong dong bo Emote nhanh
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        -- Phim NUM+ (Control 96) - Thuc hien emote da luu
        if IsControlJustPressed(1, 96) then
            print("[DEBUG] Da nhan phim NUM+.")
            playerAnimDict = emoteData.dict
            playerAnimName = emoteData.name

            if not playerAnimDict or not playerAnimName then
                print("[ERROR] Khong co emote nao duoc luu. Su dung /setnpc.")
            else
                PerformEmoteOnAllNpcs()
            end
        end

        -- Phim NUM- (Control 97) - Dung tat ca hanh dong
        if IsControlJustPressed(1, 97) then
            print("[DEBUG] Da nhan phim NUM-.")
            StopAllNpcsActions()
        end
    end
end)

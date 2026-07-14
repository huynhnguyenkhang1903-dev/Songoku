local lastApplied = {ped = 0, shirt = -1, torso = -1, hands = -1}

local function applyFix(ped)
    if not ped or ped == 0 then return end

    local model = GetEntityModel(ped)
    local isMale = model == GetHashKey('mp_m_freemode_01')
    local isFemale = model == GetHashKey('mp_f_freemode_01')
    if not (isMale or isFemale) then return end

    local shirt = GetPedDrawableVariation(ped, 11)
    local torso = GetPedDrawableVariation(ped, 3)
    local hands = GetPedDrawableVariation(ped, 7)

    if ped == lastApplied.ped and shirt == lastApplied.shirt and torso == lastApplied.torso then return end

    local expectedTorso = shirt
    local torsoMax = GetNumberOfPedDrawableVariations(ped, 3) - 1
    if expectedTorso > torsoMax then expectedTorso = torsoMax end

    local changed = false
    if torso ~= expectedTorso then
        SetPedComponentVariation(ped, 3, expectedTorso, 0, 2)
        changed = true
    end

    if expectedTorso >= 15 and hands ~= 0 then
        local handsMax = GetNumberOfPedDrawableVariations(ped, 7) - 1
        if 0 <= handsMax then
            SetPedComponentVariation(ped, 7, 0, 0, 2)
            changed = true
        end
    end

    if changed then
        lastApplied.ped = ped
        lastApplied.shirt = shirt
        lastApplied.torso = expectedTorso
        lastApplied.hands = (expectedTorso >= 15) and 0 or hands
    end
end

AddEventHandler('playerSpawned', function()
    Citizen.Wait(2000)
    applyFix(PlayerPedId())
end)

RegisterCommand('fixbody', function()
    local ped = PlayerPedId()
    applyFix(ped)
    lastApplied.ped = 0
    lastApplied.shirt = -1
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 128},
        multiline = true,
        args = {'Hệ thống', 'Đã sửa thân người/tay. Nếu vẫn ghosting hãy dùng vMenu đổi Torso/Hands.'}
    })
end, false)

print("^2[TorsoFix v3] Loaded - Event-driven fix (no 500ms loop)^7")

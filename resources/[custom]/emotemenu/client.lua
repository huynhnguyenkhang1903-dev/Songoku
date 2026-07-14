local isMenuOpen = false
local currentEmote = nil

-- Toggle Menu function
function ToggleMenu()
    isMenuOpen = not isMenuOpen
    print("[EmoteMenu] ToggleMenu: Open state is " .. tostring(isMenuOpen))
    if isMenuOpen then
        SendNUIMessage({
            action = "open",
            emotes = Config.Emotes
        })
        SetNuiFocus(true, true)
    else
        SendNUIMessage({
            action = "close"
        })
        SetNuiFocus(false, false)
    end
end

-- Register Command
RegisterCommand("emotemenu", function()
    ToggleMenu()
end, false)

-- Register Keymapping (binds command to Config.MenuKey, which is F5 by default)
RegisterKeyMapping("emotemenu", "Mở Menu Emote (F5)", "keyboard", Config.MenuKey)

-- Close NUI Callback
RegisterNUICallback("close", function(data, cb)
    print("[EmoteMenu] NUI Callback: close")
    isMenuOpen = false
    SetNuiFocus(false, false)
    cb("ok")
end)

-- Find closest ped (either player or NPC) in front of the player
function GetClosestPedInFront(maxDistance)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forwardVector = GetEntityForwardVector(playerPed)
    
    local peds = GetGamePool('CPed')
    local closestPed = nil
    local closestDistance = maxDistance

    print("[EmoteMenu] Searching closest ped in front among " .. #peds .. " peds...")

    for _, ped in ipairs(peds) do
        if ped and ped ~= 0 and ped ~= playerPed and not IsPedInAnyVehicle(ped, true) and not IsPedDeadOrDying(ped, true) then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(coords - pedCoords)
            if distance < closestDistance then
                local dir = pedCoords - coords
                local dirLen = #dir
                if dirLen > 0.1 then
                    local dirNormal = dir / dirLen
                    local dot = dirNormal.x * forwardVector.x + dirNormal.y * forwardVector.y + dirNormal.z * forwardVector.z
                    -- within 60 degrees cone in front
                    if dot > 0.5 then
                        closestPed = ped
                        closestDistance = distance
                    end
                end
            end
        end
    end

    print("[EmoteMenu] Closest ped found: " .. tostring(closestPed) .. " at distance " .. tostring(closestDistance))
    return closestPed
end

-- Play react animation event sent from another player
RegisterNetEvent("emotemenu:playReact", function(animDict, animName, flag, coords, heading)
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then return end
    if IsPedInAnyVehicle(playerPed, true) then return end
    
    print("[EmoteMenu] Received synced react: " .. tostring(animDict) .. " / " .. tostring(animName))

    -- Align target player to stand at the correct coordinates and face the attacker
    if coords and heading then
        local currentCoords = GetEntityCoords(playerPed)
        SetEntityCoords(playerPed, coords.x, coords.y, currentCoords.z, false, false, false, false)
        SetEntityHeading(playerPed, heading)
        print("[EmoteMenu] Aligned coordinates & heading for react player")
    end
    
    if animDict and animDict ~= "" and animName and animName ~= "" then
        ClearPedTasks(playerPed)
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(10)
        end
        TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, -1, flag or 0, 0, false, false, false)
        currentEmote = "react_" .. animName
    end
end)

-- Play Emote NUI Callback
RegisterNUICallback("playEmote", function(data, cb)
    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then cb("error") return end

    print("[EmoteMenu] NUI Callback: playEmote - " .. tostring(data.id))

    -- Check if in vehicle
    if IsPedInAnyVehicle(playerPed, true) then
        TriggerEvent("chat:addMessage", {
            color = {255, 50, 50},
            multiline = true,
            args = {"Hệ thống", "Bạn không thể dùng emote khi đang ở trên xe!"}
        })
        cb("vehicle")
        return
    end

    ClearPedTasks(playerPed)

    -- Play Choreographed sequence
    if data.type == "choreography" then
        local targetPed = GetClosestPedInFront(2.5) -- search within 2.5 meters
        if not targetPed or targetPed == 0 then
            TriggerEvent("chat:addMessage", {
                color = {255, 50, 50},
                multiline = true,
                args = {"Hệ thống", "Không tìm thấy người chơi hoặc NPC nào ở phía trước để đấu võ!"}
            })
            cb("error")
            return
        end

        local isTargetPlayer = false
        local targetServerId = -1
        local targetPlayerIndex = NetworkGetPlayerIndexFromPed(targetPed)
        if targetPlayerIndex ~= -1 and NetworkIsPlayerActive(targetPlayerIndex) then
            isTargetPlayer = true
            targetServerId = GetPlayerServerId(targetPlayerIndex)
        end

        print("[EmoteMenu] Starting fight choreography sequence: " .. data.id .. " with target " .. tostring(targetPed))

        Citizen.CreateThread(function()
            -- Step 0: Align position and heading once at the start of choreography
            local coords1 = GetEntityCoords(playerPed)
            local coords2 = GetEntityCoords(targetPed)
            local dir = coords2 - coords1
            local dirLen = #dir
            if dirLen > 0 then
                local dirNormal = dir / dirLen
                local heading1 = GetHeadingFromVector_2d(dirNormal.x, dirNormal.y)
                local heading2 = GetHeadingFromVector_2d(-dirNormal.x, -dirNormal.y)
                local targetCoords = coords1 + (dirNormal * 1.1)

                -- Align attacker
                SetEntityHeading(playerPed, heading1)

                -- Align victim
                if isTargetPlayer then
                    TriggerServerEvent("emotemenu:syncReact", targetServerId, "", "", 0, targetCoords, heading2)
                else
                    if NetworkGetEntityIsNetworked(targetPed) then
                        NetworkRequestControlOfEntity(targetPed)
                        local timeout = 0
                        while not NetworkHasControlOfEntity(targetPed) and timeout < 30 do
                            Citizen.Wait(10)
                            timeout = timeout + 1
                        end
                    end
                    SetEntityCoords(targetPed, targetCoords.x, targetCoords.y, coords2.z, false, false, false, false)
                    SetEntityHeading(targetPed, heading2)
                end
                
                Citizen.Wait(100)
            end

            -- Step through the choreography
            currentEmote = data.id
            for i, step in ipairs(data.steps) do
                if currentEmote ~= data.id then
                    print("[EmoteMenu] Choreography interrupted!")
                    break
                end

                print("[EmoteMenu] Playing step " .. i)

                -- Attacker plays animation
                ClearPedTasks(playerPed)
                RequestAnimDict(step.attacker.dict)
                while not HasAnimDictLoaded(step.attacker.dict) do
                    Citizen.Wait(10)
                end
                TaskPlayAnim(playerPed, step.attacker.dict, step.attacker.anim, 8.0, -8.0, -1, step.attacker.flag or 0, 0, false, false, false)

                -- Victim plays animation
                if isTargetPlayer then
                    TriggerServerEvent("emotemenu:syncReact", targetServerId, step.victim.dict, step.victim.anim, step.victim.flag)
                else
                    Citizen.CreateThread(function()
                        ClearPedTasks(targetPed)
                        RequestAnimDict(step.victim.dict)
                        while not HasAnimDictLoaded(step.victim.dict) do
                            Citizen.Wait(10)
                        end
                        TaskPlayAnim(targetPed, step.victim.dict, step.victim.anim, 8.0, -8.0, -1, step.victim.flag or 0, 0, false, false, false)
                    end)
                end

                -- Wait delay
                Citizen.Wait(step.delay or 1000)
            end

            -- Reset currentEmote if finished naturally
            if currentEmote == data.id then
                currentEmote = nil
            end
        end)
        cb("ok")
        return
    end

    -- Play animation on player
    if data.type == "animation" then
        Citizen.CreateThread(function()
            RequestAnimDict(data.dict)
            while not HasAnimDictLoaded(data.dict) do
                Citizen.Wait(10)
            end
            
            TaskPlayAnim(playerPed, data.dict, data.anim, 8.0, -8.0, -1, data.flag or 49, 0, false, false, false)
            currentEmote = data.id
        end)
    elseif data.type == "scenario" then
        TaskStartScenarioInPlace(playerPed, data.scenario, 0, true)
        currentEmote = data.id
    end

    -- Handle combat synched reactions
    if data.react then
        local targetPed = GetClosestPedInFront(2.5) -- search within 2.5 meters
        if targetPed and targetPed ~= 0 then
            local coords1 = GetEntityCoords(playerPed)
            local coords2 = GetEntityCoords(targetPed)
            local dir = coords2 - coords1
            local dirLen = #dir
            if dirLen > 0 then
                local dirNormal = dir / dirLen
                
                -- Face each other
                local heading1 = GetHeadingFromVector_2d(dirNormal.x, dirNormal.y)
                local heading2 = GetHeadingFromVector_2d(-dirNormal.x, -dirNormal.y)
                
                SetEntityHeading(playerPed, heading1)
                
                local targetCoords = coords1 + (dirNormal * 1.1) -- 1.1 meters distance
                
                local targetPlayerIndex = NetworkGetPlayerIndexFromPed(targetPed)
                if targetPlayerIndex ~= -1 and NetworkIsPlayerActive(targetPlayerIndex) then
                    -- Target is another player! Get their server ID and sync
                    local targetServerId = GetPlayerServerId(targetPlayerIndex)
                    print("[EmoteMenu] Syncing reaction to player: " .. tostring(targetServerId))
                    TriggerServerEvent("emotemenu:syncReact", targetServerId, data.react.dict, data.react.anim, data.react.flag, targetCoords, heading2)
                else
                    -- Target is an NPC! Align and make them react locally
                    print("[EmoteMenu] Playing reaction on NPC locally")
                    Citizen.CreateThread(function()
                        if NetworkGetEntityIsNetworked(targetPed) then
                            NetworkRequestControlOfEntity(targetPed)
                            local timeout = 0
                            while not NetworkHasControlOfEntity(targetPed) and timeout < 30 do
                                Citizen.Wait(10)
                                timeout = timeout + 1
                            end
                        end
                        -- Align NPC position and heading
                        SetEntityCoords(targetPed, targetCoords.x, targetCoords.y, coords2.z, false, false, false, false)
                        SetEntityHeading(targetPed, heading2)
                        
                        ClearPedTasks(targetPed)
                        RequestAnimDict(data.react.dict)
                        while not HasAnimDictLoaded(data.react.dict) do
                            Citizen.Wait(10)
                        end
                        TaskPlayAnim(targetPed, data.react.dict, data.react.anim, 8.0, -8.0, -1, data.react.flag or 0, 0, false, false, false)
                    end)
                end
            end
        end
    end

    cb("ok")
end)

-- Clear Emote NUI Callback
RegisterNUICallback("clearEmote", function(data, cb)
    print("[EmoteMenu] NUI Callback: clearEmote")
    local playerPed = PlayerPedId()
    if playerPed and playerPed ~= 0 then
        ClearPedTasks(playerPed)
        currentEmote = nil
    end
    cb("ok")
end)

-- Cancel full-body animation or scenario if the player moves
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        local playerPed = PlayerPedId()
        if currentEmote and playerPed and playerPed ~= 0 then
            local isMoving = GetEntitySpeed(playerPed) > 0.5
            if isMoving then
                local isScenarioOrFullBody = false
                for _, emote in ipairs(Config.Emotes) do
                    if emote.id == currentEmote then
                        if emote.type == "scenario" or (emote.flag and emote.flag == 1) then
                            isScenarioOrFullBody = true
                        end
                        break
                    end
                end

                if isScenarioOrFullBody then
                    print("[EmoteMenu] Player moved. Clearing full body/scenario emote.")
                    ClearPedTasks(playerPed)
                    currentEmote = nil
                end
            end
        end
    end
end)

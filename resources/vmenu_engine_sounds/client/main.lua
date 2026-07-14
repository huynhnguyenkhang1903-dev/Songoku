local menuPool = NativeUI.CreatePool()
local mainMenu = NativeUI.CreateMenu('Engine Sounds', '~b~Select an engine sound')
local sounds = EngineSounds

menuPool:Add(mainMenu)

for i, sound in ipairs(sounds) do
    local item = NativeUI.CreateItem(sound.name, 'Apply ' .. sound.name .. ' engine sound')
    mainMenu:AddItem(item)
end

mainMenu.OnItemSelect = function(sender, item, index)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle == 0 then
        SetNotificationTextEntry('STRING')
        AddTextComponentString('~r~You are not in a vehicle!')
        DrawNotification(false, false)
        return
    end
    local sound = sounds[index]
    SetVehicleAudioEngineName(vehicle, sound.audio)
    SetNotificationTextEntry('STRING')
    AddTextComponentString('~g~Engine sound: ~w~' .. sound.name)
    DrawNotification(false, false)
end

RegisterCommand('engine', function()
    if menuPool:IsAnyMenuOpen() then
        menuPool:CloseAllMenus()
        return
    end
    mainMenu:Visible(not mainMenu:Visible())
end, false)

RegisterKeyMapping('engine', 'Open Engine Sound Menu', 'keyboard', 'o')

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        menuPool:ProcessMenus()
        if mainMenu:Visible() then
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if vehicle == 0 then
                mainMenu:Visible(false)
                SetNotificationTextEntry('STRING')
                AddTextComponentString('~r~You left the vehicle!')
                DrawNotification(false, false)
            end
        end
    end
end)

Citizen.CreateThread(function()
    local hash = GetHashKey("sanchez")
    if not IsModelInCdimage(hash) then
        Citizen.Wait(5000)
    end
end)

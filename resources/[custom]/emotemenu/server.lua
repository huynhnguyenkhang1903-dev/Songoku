RegisterNetEvent("emotemenu:syncReact", function(targetServerId, animDict, animName, flag, coords, heading)
    TriggerClientEvent("emotemenu:playReact", targetServerId, animDict, animName, flag, coords, heading)
end)

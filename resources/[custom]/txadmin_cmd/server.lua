RegisterCommand('tx', function(source, args, rawCommand)
    local url = 'http://localhost:40120'
    if args[1] then
        url = url .. '/' .. table.concat(args, '/')
    end
    TriggerClientEvent('chat:addMessage', source, {
        args = { '[txAdmin]', url }
    })
end, false)

RegisterCommand('myids', function(source, args, rawCommand)
    local ids = GetPlayerIdentifiers(source)
    local msg = 'Identifiers: ' .. table.concat(ids, ', ')
    TriggerClientEvent('chat:addMessage', source, {
        args = { '[myids]', msg }
    })
end, false)

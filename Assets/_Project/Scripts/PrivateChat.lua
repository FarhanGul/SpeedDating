--!Type(Client)

function self:ClientAwake()
    Chat.TextMessageReceivedHandler:Connect(function(channel,from,message)
        -- Chat:DisplayTextMessage(channel, from, message)
        client.localPlayer.character:PlayEmote("sit-idle", true, function()end)
    end)
end
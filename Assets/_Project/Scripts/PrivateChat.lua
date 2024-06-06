--!Type(Client)

function self:ClientAwake()
    Chat.TextMessageReceivedHandler:Connect(function(channel,from,message)
        Chat:DisplayTextMessage(channel, from, message)
    end)
end
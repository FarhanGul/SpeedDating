--!Type(Client)
local common = require("Common")

--!SerializeField
local enableDevMode : boolean = false


-- Private
local chatHistory
local partner

function self:ClientAwake()
    common.SubscribeEvent(common.EBeginDate(),function(args)
        StartPrivateChat(args[2])
    end)
    Chat.TextMessageReceivedHandler:Connect(function(channel,_from,_message)
        if( enableDevMode and string.sub(_message,1,1) == "@") then
            if(_from == client.localPlayer) then
                HandleDevMode(string.sub(_message,2,-1))
            end
            return
        end
        if(partner ~= nil) then
            if(_from == client.localPlayer or _from == partner) then
                table.insert(chatHistory,{from = _from,message = _message})
                common.InvokeEvent(common.EPrivateMessageSent(),_from,_message)
            end
        else
            Chat:DisplayTextMessage(channel, _from, _message)
        end
    end)
end

function HandleDevMode(message)
    if(message == "sit") then
        common.InvokeEvent(common.ETryToOccupySeat(),1)
    elseif(message == "question") then
        common.InvokeEvent(common.ELocalPlayerSelectedQuestion(),"This is a debug question")
    end
end

function StartPrivateChat(_partner)
    chatHistory = {}
    partner = _partner
end
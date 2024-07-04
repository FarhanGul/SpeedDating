--!Type(Client)
local common = require("Common")

-- Private
local playersDatingStatus

function self:ClientAwake()
    common.SubscribeEvent(common.EUpdatePlayerDatingStatus(),HandleUpdatePlayerDatingStatus)
    Chat.TextMessageReceivedHandler:Connect(function(channel,_from,_message)
        if( common.CEnableDevCommands() and string.sub(_message,1,1) == "@") then
            if(_from == client.localPlayer) then
                HandleDevMode(string.sub(_message,2,-1))
            end
            return
        end
        if( playersDatingStatus[_from.name] == common.NDatingStatusDating() ) then
            common.InvokeEvent(common.EPrivateMessageSent(),_from,_message)
        else
            Chat:DisplayTextMessage(channel, _from, _message)
        end
    end)
    playersDatingStatus = {}
end

function HandleDevMode(message)
    if(message == "s1") then
        common.InvokeEvent(common.ETryToOccupySeat(),1)
    elseif(message == "s2") then
        common.InvokeEvent(common.ETryToOccupySeat(),2)
    elseif(message == "q") then
        common.InvokeEvent(common.EChooseCustomQuestion())
    elseif(message == "pa") then
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayAgain())
    elseif(message == "pl") then
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayLater())
    end
end

function HandleUpdatePlayerDatingStatus(args)
    playersDatingStatus[args[1]] = args[2]
end
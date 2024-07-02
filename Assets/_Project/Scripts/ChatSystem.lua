--!Type(Client)
local common = require("Common")

-- Private
local partner
local seatedPlayers = {}

function self:ClientAwake()
    common.SubscribeEvent(common.EBeginDate(),function(args)
        partner = args[2]
    end)
    common.SubscribeEvent(common.EEndDate(),function()
        partner = nil
    end)
    common.SubscribeEvent(common.EUpdateSeatOccupant(),HandleUpdateSeatOccupant)
    Chat.TextMessageReceivedHandler:Connect(function(channel,_from,_message)
        if( common.CEnableDevCommands() and string.sub(_message,1,1) == "@") then
            if(_from == client.localPlayer) then
                HandleDevMode(string.sub(_message,2,-1))
            end
            return
        end
        if(partner ~= nil) then
            if(_from == client.localPlayer or _from == partner) then
                common.InvokeEvent(common.EPrivateMessageSent(),_from,_message)
            end
        elseif(table.find(seatedPlayers,_from.name) == nil ) then
            Chat:DisplayTextMessage(channel, _from, _message)
        end
    end)
end

function HandleUpdateSeatOccupant(args)
    seatedPlayers = {}
    local data = args[1]:GetData()
    for k,v in pairs(data) do
        if(v.occupant ~= nil ) then
            table.insert(seatedPlayers,v.occupant.name) 
        end
    end
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
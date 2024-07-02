--!Type(ClientAndServer)

-- Import
local common = require("Common")

-- Events
local e_sendPlayerAskingPermissionToDateToServer = Event.new("sendPlayerAskingPermissionToDateToServer")

local character : Character
local characterUI : CharacterUI

function self:ClientAwake()
    character = self.gameObject:GetComponent(Character)
    characterUI = self.gameObject:GetComponentInChildren(CharacterUI)
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        if(character.player ~= client.localPlayer) then
            -- Send player a date request
            e_sendPlayerAskingPermissionToDateToServer:FireServer(character.player)
        end
    end)
    common.SubscribeEvent(common.EUpdatePlayerDatingStatus(),function(player,datingStatus)
        if(character.player == player) then
            characterUI.SetStatus(datingStatus)
        end
    end)
    characterUI.SetStatus(common.NDatingStatusFree())
end

function self:ServerAwake()
    e_sendPlayerAskingPermissionToDateToServer:Connect(function(player,partner)
        
    end)
end
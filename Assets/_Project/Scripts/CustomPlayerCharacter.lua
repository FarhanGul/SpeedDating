--!Type(ClientAndServer)

-- Import
local common = require("Common")

local character : Character
local characterUI : CharacterUI

function self:ClientAwake()
    character = self.gameObject:GetComponent(Character)
    characterUI = self.gameObject:GetComponentInChildren(CharacterUI)
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        print(character.player.name.." Tapped")
    end)
    common.SubscribeEvent(common.EUpdatePlayerDatingStatus(),function(player,datingStatus)
        if(character.player == player) then
            characterUI.SetStatus(datingStatus)
        end
    end)
    characterUI.SetStatus(common.NDatingStatusFree())
end
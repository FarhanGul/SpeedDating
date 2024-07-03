--!Type(ClientAndServer)

-- Import
local common = require("Common")
local character : Character
local characterUI : CharacterUI
local datingStatus = common.NDatingStatusFree()

function self:ClientAwake()
    character = self.gameObject:GetComponent(Character)
    characterUI = self.gameObject:GetComponentInChildren(CharacterUI)
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(HandleTapped)
    common.SubscribeEvent(common.EUpdatePlayerDatingStatus(),HandleUpdatePlayerDatingStatus)
end

function HandleTapped()
    if(character.player ~= client.localPlayer) then
        common.InvokeEvent(common.EPlayerTapped(),character.player)
    end
end

function HandleUpdatePlayerDatingStatus(args)
    local playerName = args[1]
    local datingStatus = args[2]
    if(character.player.name == playerName) then
        characterUI.SetStatus(datingStatus)
    end
end
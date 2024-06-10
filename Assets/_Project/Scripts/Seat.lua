--!Type(ClientAndServer)

-- Require
local common = require("Common")
local characterController = require("PlayerCharacterController")

-- Private
local contact
local id
local currentOccupant

-- Functions
function self:ClientAwake()
    currentOccupant = nil
    id = self.transform:GetSiblingIndex() + 1
    contact = self.transform:Find("Contact")
    common.SubscribeEvent(common.EUpdateSeatOccupant(),HandleUpdateSeatOccupant)
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        common.InvokeEvent(common.ETryToOccupySeat(),id)
    end)
end

function HandleUpdateSeatOccupant(args)
    local newData = args[1]:GetData()[id]
    if ( newData ~= nil and currentOccupant ~= newData.occupant) then
        if(currentOccupant == nil and newData.occupant ~= nil) then
            OccupySeat(newData.occupant)
        elseif(currentOccupant ~= nil and newData.occupant == nil ) then
            LeaveSeat(currentOccupant)
        end
    end
end

function OccupySeat(player)
    currentOccupant = player
    player.character.usePathfinding = false
    player.character:Teleport(contact.position, function()end)
    player.character:PlayEmote("sit-idle", true, function()end)
    player.character.transform.rotation = contact.rotation
    if(player == client.localPlayer) then
        common.InvokeEvent(common.ELocalPlayerOccupiedSeat())
        characterController.options.enabled = false
    end
end

function LeaveSeat(player)
    currentOccupant = nil
    player.character.usePathfinding = true
    player.character:SetIdle()
    if(player == client.localPlayer)then
        characterController.options.enabled = true
    end
    common.InvokeEvent(common.EPlayerLeftSeat(),player)
end
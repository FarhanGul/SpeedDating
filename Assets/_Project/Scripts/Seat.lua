--!Type(ClientAndServer)

-- Require
local common = require("Common")
local characterController = require("PlayerCharacterController")

-- Private
local contact
local id
local currentOccupant
local outline : GameObject
local canBeOccupied

-- Functions
function self:ClientAwake()
    currentOccupant = nil
    id = self.transform:GetSiblingIndex() + 1
    contact = self.transform:Find("Contact")
    outline = self.transform:Find("Outline").gameObject
    common.SubscribeEvent(common.EUpdateSeatOccupant(),HandleUpdateSeatOccupant)
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        if(canBeOccupied) then 
            common.InvokeEvent(common.ETryToOccupySeat(),id)
        end
    end)
    SetAvailability(true)
end

function HandleUpdateSeatOccupant(args)
    local newData = args[1]:GetData()[id]
    if(newData ~= nil) then
        if ( currentOccupant ~= newData.occupant) then
            if(currentOccupant == nil and newData.occupant ~= nil) then
                OccupySeat(newData.occupant)
            elseif(currentOccupant ~= nil and newData.occupant == nil ) then
                LeaveSeat(currentOccupant)
            end
        end
    end
end

function OccupySeat(player)
    SetAvailability(false)
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
    Timer.new(common.TSeatAvailabilityCooldown(), function()
        SetAvailability(true)
    end,false)
end

function SetAvailability(isAvailable)
    canBeOccupied = isAvailable
    outline:SetActive(isAvailable)
end
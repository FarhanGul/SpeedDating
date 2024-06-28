--!Type(ClientAndServer)

-- Require
local common = require("Common")
local characterController = require("PlayerCharacterController")

-- Private
local contact
local id
local currentOccupant
local outline : GameObject
local tapHandler : TapHandler
local collider : Collider

-- Functions
function self:ClientAwake()
    collider = self.gameObject:GetComponent(Collider)
    tapHandler = self.gameObject:GetComponent(TapHandler)
    currentOccupant = nil
    id = self.transform:GetSiblingIndex() + 1
    outline = self.transform:Find("Outline").gameObject
    common.SubscribeEvent(common.EUpdateSeatOccupant(),HandleUpdateSeatOccupant)
    common.SubscribeEvent(common.EPermissionToSitRefused(),HandlePermissionToSitRefused)
    tapHandler.Tapped:Connect(function()
        if(characterController.options.enabled)then
            common.InvokeEvent(common.ETryToOccupySeat(),id)
            characterController.options.enabled = false
        end
    end)
    SetAvailability(true)
end

function HandlePermissionToSitRefused(args)
    if(id == args[1]) then
        local rejectedPlayer = args[2]
        if(rejectedPlayer == client.localPlayer) then 
            characterController.options.enabled = true
            tapHandler.enabled = false
            Timer.new(common.TSeatNotInteractableAfterRefusalDuration(), function()
                tapHandler.enabled = true
            end, false)
        end
        rejectedPlayer.character:MoveTo(self.transform:Find("Exit").position)
        SetAvailability(true)
    end
end

function HandleUpdateSeatOccupant(args)
    local newData = args[1]:GetData()[id]
    if(newData ~= nil) then
        if(newData.occupant == nil and newData.waitingForPermission) then
            -- Handle waiting for permission
            SetAvailability(false)
        elseif ( currentOccupant ~= newData.occupant) then
            -- Update occupants
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
    if(player == client.localPlayer) then
        common.InvokeEvent(common.ELocalPlayerOccupiedSeat())
    end
end

function LeaveSeat(player)
    currentOccupant = nil
    player.character:MoveTo(self.transform:Find("Exit").position)
    if(player == client.localPlayer)then
        characterController.options.enabled = true
    end
    common.InvokeEvent(common.EPlayerLeftSeat(),player)
    Timer.new(common.TSeatAvailabilityCooldown(), function()
        SetAvailability(true)
    end,false)
end

function SetAvailability(isAvailable)
    collider.enabled = isAvailable
    outline:SetActive(not isAvailable)
end
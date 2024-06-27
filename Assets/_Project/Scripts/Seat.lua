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
local isSeatingFunctionalityEnabled = true
local isTryingToOccupySeat

-- Functions
function self:ClientAwake()
    currentOccupant = nil
    id = self.transform:GetSiblingIndex() + 1
    outline = self.transform:Find("Outline").gameObject
    common.SubscribeEvent(common.EUpdateSeatOccupant(),HandleUpdateSeatOccupant)
    common.SubscribeEvent(common.EPermissionToSitRefused(),HandlePermissionToSitRefused)
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        if(canBeOccupied and isSeatingFunctionalityEnabled) then 
            isTryingToOccupySeat = true
            common.InvokeEvent(common.ETryToOccupySeat(),id)
            characterController.options.enabled = false
        end
    end)
    SetAvailability(true)
end

function HandlePermissionToSitRefused(args)
    characterController.options.enabled = true
    isSeatingFunctionalityEnabled = false
    if(isTryingToOccupySeat) then client.localPlayer.character:MoveTo(self.transform:Find("Exit").position) end
    Timer.new(common.TSeatNotInteractableAfterRefusalDuration(), function()
        isSeatingFunctionalityEnabled = true
    end, false)
    isTryingToOccupySeat = false
end

function HandleUpdateSeatOccupant(args)
    local newData = args[1]:GetData()[id]
    if(newData ~= nil) then
        -- Handle waiting for permission
        if(newData.occupant == nil) then
            SetAvailability(not newData.waitingForPermission)
        end

        -- Update occupants
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
    if(player == client.localPlayer) then
        common.InvokeEvent(common.ELocalPlayerOccupiedSeat())
    end
    isTryingToOccupySeat = false
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
    canBeOccupied = isAvailable
    outline:SetActive(isAvailable)
end
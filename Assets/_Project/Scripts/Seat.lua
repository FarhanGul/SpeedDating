--!Type(ClientAndServer)

-- Require
local common = require("Common")
local characterController = require("PlayerCharacterController")

-- Private
local contact
local id
local currentOccupant
local outline : GameObject
local collider : Collider
local anchor : Anchor
local isAnchorTaken

-- Functions
function self:ClientAwake()
    collider = self.gameObject:GetComponent(Collider)
    anchor = self.transform:Find("Anchor"):GetComponent(Anchor)
    currentOccupant = nil
    id = self.transform:GetSiblingIndex() + 1
    outline = self.transform:Find("Outline").gameObject
    common.SubscribeEvent(common.EUpdateSeatOccupant(),HandleUpdateSeatOccupant)
    common.SubscribeEvent(common.EPermissionToSitRefused(),HandlePermissionToSitRefused)
    common.SubscribeEvent(common.ECanPlayerOccupySeatVerdictReceived(),HandleCanPlayerOccupySeatVerdict)
    anchor.Entered:Connect(function()
        isAnchorTaken = true
        if(characterController.options.enabled)then
            common.InvokeEvent(common.ETryToOccupySeat(),id)
        end
    end)
    anchor.Exited:Connect(function()
        isAnchorTaken = false
    end)
    SetAvailability(true)
end

function HandleCanPlayerOccupySeatVerdict(args)
    -- seatId ( number ) , canOccupy ( boolean ) , canSitWithoutPermission ( boolean )
    if(id == args[1])then
        if(args[2]) then characterController.options.enabled = false end
    end
end

function HandlePermissionToSitRefused(args)
    if(id == args[1]) then
        local rejectedPlayer = args[2]
        Timer.new(common.TSeatNotInteractableAfterRefusalDuration(), function()
            if(rejectedPlayer == client.localPlayer) then characterController.options.enabled = true end
            rejectedPlayer.character:MoveTo(self.transform:Find("Exit").position)
            SetAvailability(true)
        end, false)
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
        elseif(newData.occupant == nil and newData.waitingForPermission == nil) then
            SetAvailability(true)
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
    local enabled = isAvailable and not isAnchorTaken
    collider.enabled = enabled
    outline:SetActive(not enabled)
end
--!Type(ClientAndServer)

-- Require
local common = require("Common")

-- Events
local e_sendPlayerLeftSeatToServer = Event.new("sendPlayerLeftSeatToServer")
local e_sendPlayerAskingPermissionToSitToServer = Event.new("sendPlayerAskingPermissionToSitToServer")
local e_sendPlayerAskingPermissionToSitToClient = Event.new("sendPlayerAskingPermissionToSitToClient")
local e_sendPermissionToSitVerdictToServer = Event.new("sendPermissionToSitVerdictToServer")
local e_sendPermissionToSitRefusedToClient = Event.new("sendPermissionToSitRefusedToClient")
local e_requestSeatsFromServer = Event.new("requestSeatStatusFromServer")
local e_sendSeatsToClient = Event.new("sendSeatsStateToClient")
local e_sendBeginDateToClient = Event.new("sendBeginDateToClient")

-- Private
local seats

-- Classes
function Seat(_id,_occupant,_waitingForPermission)
    return{
        id = _id,
        occupant = _occupant,
        waitingForPermission = _waitingForPermission,
    }
end

function Seats()
    return{
        _table = {},
        InitializeWithData = function(self,data)
            self._table = data
        end,
        UpdateSeatAndNotifyAllClients = function(self,_id,_newOccupant,_waitingForPermission) 
            seats:UpdateSeat(_id,_newOccupant,_waitingForPermission)
            e_sendSeatsToClient:FireAllClients(seats:GetData())
        end,
        UpdateSeat = function(self,_id,_newOccupant,_waitingForPermission)
            self._table[_id] = Seat(_id, _newOccupant,_waitingForPermission)
            if(_newOccupant ~= nil and self:GetPartnerId(_id) ~= nil and self._table[self:GetPartnerId(_id)].occupant ~= nil ) then
                -- Both players are seated begin date
                local otherOccupant = self._table[self:GetPartnerId(_id)].occupant
                local firstTurn = math.random(1,2)
                e_sendBeginDateToClient:FireClient(_newOccupant,_newOccupant,otherOccupant,firstTurn == 1)
                e_sendBeginDateToClient:FireClient(otherOccupant,otherOccupant,_newOccupant,firstTurn == 2)
            end
        end,
        HandleServerPlayerLeft = function(self,playerWhoLeft)
            for k , v in pairs(self._table) do
                if ( v.occupant == playerWhoLeft ) then
                    self:UpdateSeat(v.id,nil,nil)
                    e_sendSeatsToClient:FireAllClients(seats:GetData())
                    return
                end
            end
        end,
        AreBothSeatsEmpty = function(self,id)
            local isFirstSeatEmpty = self._table[id] == nil or self._table[id].occupant == nil
            local partnerId = self:GetPartnerId(id)
            local isSecondSeatEmpty = self._table[partnerId] == nil or self._table[partnerId].occupant == nil
            return isFirstSeatEmpty and isSecondSeatEmpty
        end,
        GetPartnerPlayerFromSeatId = function(self,id)
            local partnerId = self:GetPartnerId(id)
            return self._table[partnerId] ~= nil and self._table[partnerId].occupant or nil
        end,
        GetPartnerSeat = function(self,player)
            local partnerId = self:GetPartnerId(self:GetSeat(player).id)
            return self._table[partnerId] ~= nil and self._table[partnerId] or nil
        end,
        GetSeat = function(self,player)
            for k , v in pairs(self._table) do
                if ( v.occupant == player ) then
                    return v
                end
            end
            return nil
        end,
        GetPartnerId = function(self,id)
            local otherId
            if ( id % 2 == 0 ) then otherId = id - 1
            else otherId = id + 1 end
            return self._table[otherId] ~= nil and otherId or nil
        end,
        GetData = function(self)
            return self._table
        end,
        HandleClientLeftSeat = function(self,id)
            e_sendPlayerLeftSeatToServer:FireServer(id)
        end,
        HandleClientWantsToOccupySeat = function(self,id)
            -- Check if seat is not already occupied
            if ( self._table[id] == nil or (self._table[id].occupant == nil and self._table[id].waitingForPermission == nil)) then
                e_sendPlayerAskingPermissionToSitToServer:FireServer(id)
            end
        end,
        GetLocalPlayerSeat = function(self,id)
            for k , v in pairs(self._table) do
                if ( v.occupant == client.localPlayer ) then
                    return v
                end
            end
            return nil
        end
    }
end

-- Functions
function self:ServerAwake()
    seats = Seats()

    server.PlayerDisconnected:Connect(function(player)
        seats:HandleServerPlayerLeft(player)
    end)

    e_requestSeatsFromServer:Connect(function(player)
        e_sendSeatsToClient:FireClient(player,seats:GetData())
    end)

    e_sendPlayerLeftSeatToServer:Connect(function(player,id)
        seats:UpdateSeatAndNotifyAllClients(id, nil, nil)
    end)

    e_sendPlayerAskingPermissionToSitToServer:Connect(function(player,id)
        if(seats:AreBothSeatsEmpty(id)) then
            -- if both seats are empty let the player sit
            seats:UpdateSeatAndNotifyAllClients(id, player, nil)
        else
            -- elseif other seat is occupied send the partner a permission request
            seats:UpdateSeatAndNotifyAllClients(id, nil, player)
            e_sendPlayerAskingPermissionToSitToClient:FireClient(seats:GetPartnerPlayerFromSeatId(id),player)
        end
    end)

    e_sendPermissionToSitVerdictToServer:Connect(function(player,verdict)
        local partnerSeat = seats:GetPartnerSeat(player)
        local playerWaitingToSit = partnerSeat.waitingForPermission
        local waitingPlayerSeatId = partnerSeat.id
        if(verdict == common.NVerdictAccept()) then
            seats:UpdateSeatAndNotifyAllClients(waitingPlayerSeatId, playerWaitingToSit, nil)
        else
            seats:UpdateSeatAndNotifyAllClients(waitingPlayerSeatId, nil, nil)
            e_sendPermissionToSitRefusedToClient:FireClient(playerWaitingToSit)
        end
    end)

end

function self:ClientAwake()

    e_sendSeatsToClient:Connect(function(newSeatsData)
        seats = Seats()
        seats:InitializeWithData(newSeatsData)
        common.InvokeEvent(common.EUpdateSeatOccupant(),seats)
    end)

    e_sendBeginDateToClient:Connect(function(you, partner,isYourTurnFirst)
        if(you == client.localPlayer) then
            common.InvokeEvent(common.EBeginDate(),you,partner,isYourTurnFirst)
        end
    end)

    e_sendPlayerAskingPermissionToSitToClient:Connect(function(requestingPlayer)
        common.InvokeEvent(common.EDateRequestReceived(),requestingPlayer)
    end)

    e_sendPermissionToSitRefusedToClient:Connect(function()
        common.InvokeEvent(common.EPermissionToSitRefused())
    end)
   
    common.SubscribeEvent(common.ELocalPlayerLeftSeat(),function()
        seats:HandleClientLeftSeat(seats:GetLocalPlayerSeat().id)
    end)

    common.SubscribeEvent(common.ETryToOccupySeat(),function(args)
        seats:HandleClientWantsToOccupySeat(args[1])
    end)

    common.SubscribeEvent(common.ESubmitPermissionToSitVerdict(),function(args)
        e_sendPermissionToSitVerdictToServer:FireServer(args[1])
    end)

    e_requestSeatsFromServer:FireServer()
end

function GetSeats()
    return seats
end
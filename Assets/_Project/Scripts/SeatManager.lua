--!Type(ClientAndServer)

-- Require
local common = require("Common")

-- Events
local e_sendPlayerLeftSeatToServer = Event.new("sendPlayerLeftSeatToServer")
local e_sendPlayerOccupiedSeatToServer = Event.new("sendPlayerOccupiedSeatToServer")
local e_requestSeatsFromServer = Event.new("requestSeatStatusFromServer")
local e_sendSeatsToClient = Event.new("sendSeatsStateToClient")
local e_sendBeginDateToClient = Event.new("sendBeginDateToClient")

-- Private
local seats

-- Classes
function Seat(_id,_occupant)
    return{
        id = _id,
        occupant = _occupant
    }
end

function Seats()
    return{
        _table = {},
        InitializeWithData = function(self,data)
            self._table = data
        end,
        UpdateSeat = function(self,_id,_newOccupant)
            self._table[_id] = Seat(_id, _newOccupant)
            if(_newOccupant ~= nil and self:GetPartnerId(_id) ~= nil and self._table[self:GetPartnerId(_id)].occupant ~= nil ) then
                -- Both players are seated begin date
                local otherOccupant = self._table[self:GetPartnerId(_id)].occupant
                e_sendBeginDateToClient:FireClient(_newOccupant,_newOccupant,otherOccupant)
                e_sendBeginDateToClient:FireClient(otherOccupant,otherOccupant,_newOccupant)
            end
        end,
        HandleServerPlayerLeft = function(self,playerWhoLeft)
            for k , v in pairs(self._table) do
                if ( v.occupant == playerWhoLeft ) then
                    self:UpdateSeat(v.id,nil)
                    e_sendSeatsToClient:FireAllClients(seats:GetData())
                end
            end
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
            if ( self._table[id] == nil or self._table[id].occupant == nil ) then
                e_sendPlayerOccupiedSeatToServer:FireServer(id)
            end
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
        seats:UpdateSeat(id,nil)
        e_sendSeatsToClient:FireAllClients(seats:GetData())
    end)

    e_sendPlayerOccupiedSeatToServer:Connect(function(player,id)
        seats:UpdateSeat(id, player)
        e_sendSeatsToClient:FireAllClients(seats:GetData())
    end)

end

function self:ClientAwake()
    e_sendSeatsToClient:Connect(function(newSeatsData)
        seats = Seats()
        seats:InitializeWithData(newSeatsData)
        common.InvokeEvent(common.ESeatsReceivedFromServer)
    end)

    e_sendBeginDateToClient:Connect(function(you, partner)
        if(you == client.localPlayer) then
            common.InvokeEvent(common.EBeginDate(),you,partner)
        end
    end)

    e_requestSeatsFromServer:FireServer()
end

function GetSeats()
    return seats
end
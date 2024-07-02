--!Type(ClientAndServer)

-- Require
local common = require("Common")
local ranking = require("Ranking")

-- Events
local e_sendPlayerWantsToOccupySeat = Event.new("sendPlayerWantsToOccupySeat")
local e_sendCanPlayerOccupySeatVerdictToClient = Event.new("sendCanPlayerOccupySeatVerdictToClient")
local e_sendPlayerLeftSeatToServer = Event.new("sendPlayerLeftSeatToServer")
local e_sendPlayerAskingPermissionToSitToClient = Event.new("sendPlayerAskingPermissionToSitToClient")
local e_sendPermissionToSitRequestCancelledToServer = Event.new("sendPermissionToSitRequestCancelledToServer")
local e_sendPermissionToSitRequestCancelledToClient = Event.new("sendPermissionToSitRequestCancelledToClient")
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
            if(_newOccupant ~= nil and self:GetPartnerSeatId(_id) ~= nil and self._table[self:GetPartnerSeatId(_id)].occupant ~= nil ) then
                -- Both players are seated begin date
                local otherOccupant = self._table[self:GetPartnerSeatId(_id)].occupant
                self:BeginDate(_newOccupant,otherOccupant)

            end
        end,
        BeginDate = function(self,p1,p2)
            local pairId = ranking.GetUniquePairIdentifier(p1.name,p2.name)
            local arePlayersPlayingForTheFirstTime = false
            -- Fetch Partner History
            ranking.FetchPartnerHistoryFromStorage(function(partnerHistory)
                if(not table.find(partnerHistory,pairId)) then
                    arePlayersPlayingForTheFirstTime = true
                end
                local firstTurn = math.random(1,2)
                e_sendBeginDateToClient:FireClient(p1,p1,p2,firstTurn == 1,arePlayersPlayingForTheFirstTime)
                e_sendBeginDateToClient:FireClient(p2,p2,p1,firstTurn == 2,arePlayersPlayingForTheFirstTime)
            end)
        end,
        HandleServerPlayerLeft = function(self,playerWhoLeft)
            -- Check if they were waiting for permission if so send a cancel request
            for k , v in pairs(self._table) do
                if ( v.waitingForPermission == playerWhoLeft ) then
                    local seatedPlayer = self._table[seats:GetPartnerSeatId(v.id)].occupant
                    e_sendPermissionToSitRequestCancelledToClient:FireClient(seatedPlayer)
                    self:UpdateSeatAndNotifyAllClients(v.id,nil,nil)
                end
            end
            local seat = self:GetOccupiedSeat(playerWhoLeft)
            if(seat ~= nil) then
                -- If player was seated
                local partnerSeat = self:GetPartnerSeat(playerWhoLeft)
                -- Check if they were supposed to respond to a permission request 
                if(partnerSeat.waitingForPermission ~= nil) then
                    e_sendPermissionToSitRefusedToClient:FireAllClients(partnerSeat.id,partnerSeat.waitingForPermission,common.NVerdictPlayerLeft())
                    seats:UpdateSeat(partnerSeat.id,nil,nil)
                end
                seats:UpdateSeat(seat.id,nil,nil)
                e_sendSeatsToClient:FireAllClients(seats:GetData())
            end
        end,
        AreBothSeatsEmpty = function(self,id)
            local isFirstSeatEmpty = self._table[id] == nil or self._table[id].occupant == nil
            local partnerId = self:GetPartnerSeatId(id)
            local isSecondSeatEmpty = self._table[partnerId] == nil or self._table[partnerId].occupant == nil
            return isFirstSeatEmpty and isSecondSeatEmpty
        end,
        GetPartnerPlayerFromSeatId = function(self,id)
            local partnerId = self:GetPartnerSeatId(id)
            return self._table[partnerId] ~= nil and self._table[partnerId].occupant or nil
        end,
        GetPartnerSeat = function(self,player)
            local seat = self:GetOccupiedSeat(player)
            if(seat ~= nil ) then
                local partnerId = self:GetPartnerSeatId(self:GetOccupiedSeat(player).id)
                return self._table[partnerId] ~= nil and self._table[partnerId] or nil
            end
            return nil
        end,
        GetOccupiedSeat = function(self,player)
            for k , v in pairs(self._table) do
                if ( v.occupant == player ) then
                    return v
                end
            end
            return nil
        end,
        GetSeat = function(self,player)
            for k , v in pairs(self._table) do
                if ( v.occupant == player or v.waitingForPermission == player ) then
                    return v
                end
            end
            return nil
        end,
        GetPartnerSeatId = function(self,id)
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
        HandleClientWantsToOccupySeat = function(self,player,id)
            -- Check if seat is not already occupied
            if ( self._table[id] == nil or (self._table[id].occupant == nil and self._table[id].waitingForPermission == nil)) then
                if(seats:AreBothSeatsEmpty(id)) then
                    -- if both seats are empty let the player sit
                    seats:UpdateSeatAndNotifyAllClients(id, player, nil)
                    e_sendCanPlayerOccupySeatVerdictToClient:FireClient(player,id,true,true)
                else
                    -- elseif other seat is occupied send the partner a permission request
                    seats:UpdateSeatAndNotifyAllClients(id, nil, player)
                    e_sendPlayerAskingPermissionToSitToClient:FireClient(seats:GetPartnerPlayerFromSeatId(id),player)
                    e_sendCanPlayerOccupySeatVerdictToClient:FireClient(player,id,true,false)
                end
            else
                e_sendCanPlayerOccupySeatVerdictToClient:FireClient(player,id,false,false)
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

    e_sendPermissionToSitRequestCancelledToServer:Connect(function(player)
        local playerWhoLeftSeat = seats:GetSeat(player)
        local seatedPlayer = seats:GetData()[seats:GetPartnerSeatId(playerWhoLeftSeat.id)].occupant
        e_sendPermissionToSitRequestCancelledToClient:FireClient(seatedPlayer)
        seats:UpdateSeatAndNotifyAllClients(playerWhoLeftSeat.id,nil,nil)
        e_sendPermissionToSitRefusedToClient:FireAllClients(playerWhoLeftSeat.id,playerWhoLeftSeat.waitingForPermission,common.NVerdictPlayLater())
    end)

    e_requestSeatsFromServer:Connect(function(player)
        e_sendSeatsToClient:FireClient(player,seats:GetData())
    end)

    e_sendPlayerLeftSeatToServer:Connect(function(player,id)
        seats:UpdateSeatAndNotifyAllClients(id, nil, nil)
    end)

    e_sendPlayerWantsToOccupySeat:Connect(function(player,seatId)
        seats:HandleClientWantsToOccupySeat(player,seatId)
    end)

    e_sendPermissionToSitVerdictToServer:Connect(function(player,verdict)
        local partnerSeat = seats:GetPartnerSeat(player)
        local playerWaitingToSit = partnerSeat.waitingForPermission
        local waitingPlayerSeatId = partnerSeat.id
        if(verdict == common.NVerdictAccept()) then
            seats:UpdateSeatAndNotifyAllClients(waitingPlayerSeatId, playerWaitingToSit, nil)
        else
            e_sendPermissionToSitRefusedToClient:FireAllClients(waitingPlayerSeatId,playerWaitingToSit,common.NVerdictReject())
            seats:UpdateSeatAndNotifyAllClients(waitingPlayerSeatId, nil, nil)
        end
    end)
end

function self:ClientAwake()

    scene.PlayerJoined:Connect(function(scene, player)
        player.CharacterChanged:Connect(function(player, character) 
            if(character.gameObject:GetComponent(TapHandler) == nil) then
                character.gameObject:AddComponent(TapHandler)
                local tapHandler : TapHandler = character.gameObject:GetComponent(TapHandler)
                -- print("Is TapHandler Nil : "..tostring(tapHandler == nil))
                -- print("Is TapHandler.Tapped Nil : "..tostring(tapHandler.Tapped == nil))
                tapHandler.Tapped:Connect(function()
                    print(player.name.." was tapped")
                end)
            end
        end)
    end)

    e_sendSeatsToClient:Connect(function(newSeatsData)
        seats = Seats()
        seats:InitializeWithData(newSeatsData)
        common.InvokeEvent(common.EUpdateSeatOccupant(),seats)
    end)

    e_sendBeginDateToClient:Connect(function(you, partner,isYourTurnFirst,isNewParter)
        if(you == client.localPlayer) then
            common.InvokeEvent(common.EBeginDate(),you,partner,isYourTurnFirst,isNewParter)
        end
    end)

    e_sendCanPlayerOccupySeatVerdictToClient:Connect(function(seatId, canOccupy,canSitWithoutPermission)
        common.InvokeEvent(common.ECanPlayerOccupySeatVerdictReceived(),seatId,canOccupy,canSitWithoutPermission)
    end)

    e_sendPlayerAskingPermissionToSitToClient:Connect(function(requestingPlayer)
        common.InvokeEvent(common.EDateRequestReceived(),requestingPlayer)
    end)

    e_sendPermissionToSitRefusedToClient:Connect(function(seatId,rejectedPlayer,verdict)
        common.InvokeEvent(common.EPermissionToSitRefused(),seatId,rejectedPlayer,verdict)
    end)

    e_sendPermissionToSitRequestCancelledToClient:Connect(function()
        common.InvokeEvent(common.EPermissionToSitRequestCancelled())
    end)
   
    common.SubscribeEvent(common.ELocalPlayerLeftSeat(),function()
        seats:HandleClientLeftSeat(seats:GetLocalPlayerSeat().id)
    end)

    common.SubscribeEvent(common.ETryToOccupySeat(),function(args)
        e_sendPlayerWantsToOccupySeat:FireServer(args[1])
    end)

    common.SubscribeEvent(common.ESubmitPermissionToSitVerdict(),function(args)
        e_sendPermissionToSitVerdictToServer:FireServer(args[1])
    end)

    common.SubscribeEvent(common.ECancelPermissionToSitRequest(),function(args)
        e_sendPermissionToSitRequestCancelledToServer:FireServer()
    end)

    e_requestSeatsFromServer:FireServer()
end

function GetSeats()
    return seats
end
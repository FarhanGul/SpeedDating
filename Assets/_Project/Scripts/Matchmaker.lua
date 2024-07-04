--!Type(Module)

-- Imports
local common = require("Common")
local ranking = require("Ranking")

-- Events
local e_sendFetchDatingStatusToServer = Event.new("sendFetchDatingStatusToServer")
local e_sendDatingStatusToClient = Event.new("sendDatingStatusToClient")
local e_sendAskPermissionToDateToServer = Event.new("sendAskPermissionToDateToServer")
local e_sendWaitForPermissionToServer = Event.new("sendWaitForPermissionToServer")
local e_sendIsDateRequestValidToClient = Event.new("sendIsDateRequestValidToClient")
local e_sendDateRequestReceivedToClient = Event.new("sendDateRequestReceivedToClient")
local e_sendDateRequestVerdictToServer = Event.new("sendDateRequestVerdictToServer")
local e_sendProposalVerdictToClient = Event.new("sendProposalVerdictToClient")
local e_sendBeginDateToClient = Event.new("sendBeginDateToClient")
local e_sendEndDateToServer = Event.new("sendEndDateToServer")
local e_sendCancelDateRequestToServer = Event.new("sendCancelDateRequestToServer")

-- Type (Map) , Key (Player.name) , Value (common.NDatingStatus)
local playersDatingStatus
-- Type (Map) , Key (PlayerWhoGotProposal) , Value(PlayerWhoSentProposal)
local playersProposals
-- Type (Map) , Key (Player1) , Value(Player2)
local currentlyDatingCouples

function self:ClientAwake()
    -- Game Events
    common.SubscribeEvent(common.EPlayerTapped(),ClientHandlesAskPermissionToDate)
    common.SubscribeEvent(common.ESubmitDateRequestVerdict(),ClientHandlesDateRequestVerdict)
    common.SubscribeEvent(common.EEndDate(),ClientHandlesEndDate)
    common.SubscribeEvent(common.ECancelDateRequest(),ClientHandlesCancelDateRequest)
    -- Networking Events
    e_sendDatingStatusToClient:Connect(ClientHandlesDateStatusReceived)
    e_sendIsDateRequestValidToClient:Connect(ClientHandlesIsDateRequestValid)
    e_sendProposalVerdictToClient:Connect(ClientHandlesProposalVerdict)
    e_sendDateRequestReceivedToClient:Connect(ClientHandlesDateRequestReceived)
    e_sendBeginDateToClient:Connect(ClientHandlesBeginDate)
    -- Initialize
    e_sendFetchDatingStatusToServer:FireServer()
end

function self:ServerAwake()
    -- Initialize
    playersDatingStatus = {}
    playersProposals = {}
    currentlyDatingCouples = {}
    --Networking Events
    e_sendAskPermissionToDateToServer:Connect(ServerHandlesAskPermission)
    e_sendFetchDatingStatusToServer:Connect(ServerHandlesFetchDatingStatus)
    server.PlayerConnected:Connect(ServerHandlesPlayerConnected)
    server.PlayerDisconnected:Connect(ServerHandlesPlayerDisconnected)
    e_sendDateRequestVerdictToServer:Connect(ServerHandlesDateRequestVerdict)
    e_sendEndDateToServer:Connect(ServerHandlesEndDate)
    e_sendCancelDateRequestToServer:Connect(ServerHandlesCancelDateRequest)
end

function ClientHandlesBeginDate(you, partner,isYourTurnFirst,isNewParter)
    common.InvokeEvent(common.EBeginDate(),you,partner,isYourTurnFirst,isNewParter)
end

function ClientHandlesCancelDateRequest(args)
    e_sendCancelDateRequestToServer:FireServer()
end

function ClientHandlesDateRequestReceived(partnerName)
    common.InvokeEvent(common.EDateRequestReceived(),partnerName)
end

function ClientHandlesDateRequestVerdict(args)
    e_sendDateRequestVerdictToServer:FireServer(args[1])
end

function ClientHandlesAskPermissionToDate(args)
    e_sendAskPermissionToDateToServer:FireServer(args[1])
end

function ClientHandlesDateStatusReceived(newPlayersDatingStatus)
    for k,v in pairs(newPlayersDatingStatus) do
        common.InvokeEvent(common.EUpdatePlayerDatingStatus(),k,v)
    end
end

function ClientHandlesIsDateRequestValid(targetPlayerName,verdict)
    common.InvokeEvent(common.EIsDateRequestValidReceived(),targetPlayerName,verdict)
end

function ClientHandlesProposalVerdict(verdict)
    common.InvokeEvent(common.EProposalVerdictReceived(),verdict)
end

function ClientHandlesEndDate(args)
    local partner = args[1]
    if(common.IsChosenFromUniquePair(partner)) then
        e_sendEndDateToServer:FireServer()
    end
end

function ServerHandlesPlayerConnected(player)
    playersDatingStatus[player.name] = common.NDatingStatusFree()
end

function ServerHandlesPlayerDisconnected(player)
    local isDataStatusSendPending = false
    for k,v in currentlyDatingCouples do
        if (k == player or v == player) then
            currentlyDatingCouples[k] = nil
            local other = k == player and v or k
            playersDatingStatus[other.name] = common.NDatingStatusFree()
            isDataStatusSendPending = true
        end
    end
    for k,v in playersProposals do
        if (k == player or v == player) then
            ServerHandlesDateRequestVerdict(k, common.NVerdictPlayerLeft())
            isDataStatusSendPending = false
        end
    end
    if(isDataStatusSendPending) then e_sendDatingStatusToClient:FireAllClients(playersDatingStatus) end
end

function ServerHandlesFetchDatingStatus(player)
    e_sendDatingStatusToClient:FireAllClients(playersDatingStatus)
end

function ServerHandlesAskPermission(askingPlayer,interestedIn)
    if(playersDatingStatus[interestedIn.name] == common.NDatingStatusFree() and playersDatingStatus[askingPlayer.name] == common.NDatingStatusFree())then
        -- send request to interestedIn
        e_sendDateRequestReceivedToClient:FireClient(interestedIn,askingPlayer.name)
        -- Tell askingPlayer to wait
        e_sendIsDateRequestValidToClient:FireClient(askingPlayer,askingPlayer.name,common.NVerdictAccept())
        -- Update server state
        playersDatingStatus[askingPlayer.name] = common.NDatingStatusMatchmaking()
        playersDatingStatus[interestedIn.name] = common.NDatingStatusMatchmaking()
        playersProposals[interestedIn] = askingPlayer
        e_sendDatingStatusToClient:FireAllClients(playersDatingStatus)
    else
        -- tell asking player interestedIn is busy
        e_sendIsDateRequestValidToClient:FireClient(askingPlayer,askingPlayer.name,common.NVerdictReject())
    end
end

function ServerHandlesDateRequestVerdict(playerWhoGotProposal,verdict)
    local playerWhoSentProposal = playersProposals[playerWhoGotProposal]
    playersDatingStatus[playerWhoGotProposal.name] = common.NDatingStatusFree()
    playersDatingStatus[playerWhoSentProposal.name] = common.NDatingStatusFree()
    if(verdict == common.NVerdictPlayerLeft() or verdict == common.NVerdictPlayLater() )then
        e_sendProposalVerdictToClient:FireClient(playerWhoGotProposal,verdict)
        e_sendProposalVerdictToClient:FireClient(playerWhoSentProposal,verdict)
    elseif(verdict == common.NVerdictAccept()) then
        playersDatingStatus[playerWhoGotProposal.name] = common.NDatingStatusDating()
        playersDatingStatus[playerWhoSentProposal.name] = common.NDatingStatusDating()
        -- Inform both players to start the date
        currentlyDatingCouples[playerWhoGotProposal] = playerWhoSentProposal
        ServerHandlesBeginDate(playerWhoGotProposal,playerWhoSentProposal)
        -- Start date
    elseif(verdict == common.NVerdictReject())then
        -- Send rejection to player who sent proposal
        e_sendProposalVerdictToClient:FireClient(playerWhoSentProposal,common.NVerdictReject()) 
    end
    playersProposals[playerWhoGotProposal] = nil
    e_sendDatingStatusToClient:FireAllClients(playersDatingStatus)
end

function ServerHandlesCancelDateRequest(player)
    for k,v in pairs(playersProposals) do
        if(v == player) then
            ServerHandlesDateRequestVerdict(k, common.NVerdictPlayLater())
            return
        end
    end
end

function ServerHandlesBeginDate(p1,p2)
    local pairId = common.GetUniquePairIdentifier(p1.name,p2.name)
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
end

function ServerHandlesEndDate(player)
    for k,v in currentlyDatingCouples do
        if (k == player or v == player) then
            playersDatingStatus[k.name] = common.NDatingStatusFree()
            playersDatingStatus[v.name] = common.NDatingStatusFree()
            currentlyDatingCouples[k] = nil
        end
    end
    e_sendDatingStatusToClient:FireAllClients(playersDatingStatus)
end
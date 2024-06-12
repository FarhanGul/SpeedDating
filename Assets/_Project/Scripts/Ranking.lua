--!Type(Module)

local common = require("Common")

-- Events
local e_getRelationshipLeaderboardFromServer = Event.new("getRelationshipLeaderboardFromServer") 
local e_sendRelationshipLeaderboardToClient = Event.new("sendRelationshipLeaderboardToClient")
local e_getDatingLeaderboardFromServer = Event.new("getDatingLeaderboardFromServer") 
local e_sendDatingLeaderboardToClient = Event.new("sendDatingLeaderboardToClient")
local e_getPartnerHistoryFromServer = Event.new("getPartnerHistoryFromServer") 
local e_sendPartnerHistoryToClient = Event.new("sendPartnerHistoryToClient")
local e_sendIncrementDatingScoreToServer = Event.new("sendIncrementDatingScoreToServer")
local e_sendIncrementRelationshipScoreToServer = Event.new("sendIncrementRelationshipScoreToServer")

-- Private
local datingLeaderboard = {}
local relationshipLeaderboard = {}
local partnerHistory = {}
local responseCallback

function self:ClientAwake()
    e_sendDatingLeaderboardToClient:Connect(function(newLeaderboard)
        datingLeaderboard = newLeaderboard
        responseCallback()
    end)
    e_sendRelationshipLeaderboardToClient:Connect(function(newLeaderboard)
        relationshipLeaderboard = newLeaderboard
        responseCallback()
    end)
    e_sendPartnerHistoryToClient:Connect(function(newPartnerHistory)
        partnerHistory = newPartnerHistory
    end)
    e_getPartnerHistoryFromServer:FireServer()
end

function self:ServerAwake()
    e_getDatingLeaderboardFromServer:Connect(function(player)
        FetchDatingLeaderboardFromStorage()
        e_sendDatingLeaderboardToClient:FireClient(player,datingLeaderboard)
    end)
    e_getRelationshipLeaderboardFromServer:Connect(function(player)
        FetchRelationshipLeaderboardFromStorage()
        e_sendRelationshipLeaderboardToClient:FireClient(player,relationshipLeaderboard)
    end)
    e_getPartnerHistoryFromServer:Connect(function(player)
        e_sendPartnerHistoryToClient:FireClient(player,FetchPartnerHistoryFromStorage(player))
    end)
    e_sendIncrementDatingScoreToServer:Connect(function(player,partner)
        FetchDatingLeaderboardFromStorage()
        local found = false
        for k,v in pairs(datingLeaderboard) do
            if(k == player.name)then
                v += 1
                found = true
            end
        end
        if ( not found ) then
            datingLeaderboard[player.name] = 1
        end
        local history = FetchPartnerHistoryFromStorage(player)
        table.insert(history,partner.name)
        Storage.SetValue(common.KDatingLeaderboard(),datingLeaderboard)
        Storage.SetPlayerValue(common.KPartnerHistory(),history)
    end)
    e_sendIncrementRelationshipScoreToServer:Connect(function(player,partner)
        FetchRelationshipLeaderboardFromStorage()
        local relationshipId = GetUniquePairIdentifier(player.name, partner.name)
        for k,v in pairs(relationshipLeaderboard) do
            if(k == relationshipId)then
                v += 1
                found = true
            end
        end
        if ( not found ) then
            relationshipLeaderboard[relationshipId] = 1
        end
        Storage.SetValue(common.KRelationshipLeaderboard(),relationshipLeaderboard)
    end)
end

function FetchPartnerHistoryFromStorage(player)
    local history
    Storage.GetPlayerValue(player,common.KPartnerHistory(), function(storedValue)
        if storedValue == nil then storedValue = {} end
        history = storedValue
    end)
    return history
end

function FetchDatingLeaderboardFromStorage()
    Storage.GetValue(common.KDatingLeaderboard(), function(storedValue)
        if storedValue == nil then storedValue = {} end
        datingLeaderboard = storedValue
    end)
    table.sort(datingLeaderboard, function(a, b) return a > b end)
end

function FetchRelationshipLeaderboardFromStorage()
    Storage.GetValue(common.KRelationshipLeaderboard(), function(storedValue)
        if storedValue == nil then storedValue = {} end
        relationshipLeaderboard = storedValue
    end)
    table.sort(relationshipLeaderboard, function(a, b) return a > b end)
end


function CompletedDate(partner)
    if(not table.find(partnerHistory, partner.name)) then
        table.insert(partnerHistory,partner.name)
        e_sendIncrementDatingScoreToServer:FireServer(partner)
    else
        e_sendIncrementRelationshipScoreToServer:FireServer(partner)
    end
end

function FetchDatingLeaderboard(successCallback)
    responseCallback = successCallback
    e_getDatingLeaderboardFromServer:FireServer()
end

function FetchRelationshipLeaderboard(successCallback)
    responseCallback = successCallback
    e_getRelationshipLeaderboardFromServer:FireServer()
end

function DatingLeaderboard()
    return datingLeaderboard
end

function RelationshipLeaderboard()
    return relationshipLeaderboard
end

function GetUniquePairIdentifier(str1, str2)
    if str1 > str2 then
        str1, str2 = str2, str1
    end
    return str1..str2
end
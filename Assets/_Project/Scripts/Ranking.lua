--!Type(Module)

local common = require("Common")

-- Events
local e_getRelationshipLeaderboardFromServer = Event.new("getRelationshipLeaderboardFromServer") 
local e_sendRelationshipLeaderboardToClient = Event.new("sendRelationshipLeaderboardToClient")
local e_getDatingLeaderboardFromServer = Event.new("getDatingLeaderboardFromServer") 
local e_sendDatingLeaderboardToClient = Event.new("sendDatingLeaderboardToClient")
local e_sendDateCompleteToServer = Event.new("sendDateCompleteToServer")
local e_sendDeleteStorageToServer = Event.new("sendDeleteStorageToServer")

-- Private
local datingLeaderboard = {}
local relationshipLeaderboard = {}
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
end

function self:ServerAwake()
    e_getDatingLeaderboardFromServer:Connect(function(player)
        FetchDatingLeaderboardFromStorage(function()
            e_sendDatingLeaderboardToClient:FireClient(player,GetFormattedLeaderboard(player,datingLeaderboard,false))
        end)
    end)
    e_getRelationshipLeaderboardFromServer:Connect(function(player)
        FetchRelationshipLeaderboardFromStorage(function()
            e_sendRelationshipLeaderboardToClient:FireClient(player,GetFormattedLeaderboard(player,relationshipLeaderboard,true))
        end)
    end)
    e_sendDateCompleteToServer:Connect(function(sender,player,partner)
        local pairId = GetUniquePairIdentifier(player.name,partner.name)
        -- Fetch Partner History
        FetchPartnerHistoryFromStorage(function(partnerHistory)
            if(not table.find(partnerHistory,pairId)) then
                -- Players playing each for the first time
                table.insert(partnerHistory,pairId)
                Storage.SetValue(common.KPartnerHistory(),partnerHistory)
                IncrementDatingScore(player, partner)
            else
                IncrementRelationshipScore(pairId)
            end
        end)
    end)
    e_sendDeleteStorageToServer:Connect(function(player)
        Storage.DeleteValue(common.KDatingLeaderboard())
        Storage.DeleteValue(common.KRelationshipLeaderboard())
        Storage.DeleteValue(common.KPartnerHistory())
    end)
end

function IncrementDatingScore(player,partner)
    FetchDatingLeaderboardFromStorage(function()
        for k,v in pairs(datingLeaderboard) do
            if(k == player.name or k == partner.name)then
                datingLeaderboard[k] += 1
            end
        end
        if(datingLeaderboard[player.name] == nil) then datingLeaderboard[player.name] = 1 end
        if(datingLeaderboard[partner.name] == nil) then datingLeaderboard[partner.name] = 1 end
        Storage.SetValue(common.KDatingLeaderboard(),datingLeaderboard)
    end)
end

function IncrementRelationshipScore(pairId)
    FetchRelationshipLeaderboardFromStorage(function()
        for k,v in pairs(relationshipLeaderboard) do
            if(k == pairId)then
                relationshipLeaderboard[k] += 1
            end
        end
        if(relationshipLeaderboard[pairId] == nil ) then relationshipLeaderboard[pairId] = 1 end
        Storage.SetValue(common.KRelationshipLeaderboard(),relationshipLeaderboard)
    end)
end

function FetchPartnerHistoryFromStorage(responseCallback)
    local history
    Storage.GetValue(common.KPartnerHistory(), function(storedValue,errorCode)
        if storedValue == nil then storedValue = {} end
        history = storedValue
        responseCallback(history)
    end)
end

function FetchDatingLeaderboardFromStorage(responseCallback)
    Storage.GetValue(common.KDatingLeaderboard(), function(storedValue)
        if storedValue == nil then storedValue = {} end
        datingLeaderboard = storedValue
        responseCallback()
    end)
end

function FetchRelationshipLeaderboardFromStorage(responseCallback)
    Storage.GetValue(common.KRelationshipLeaderboard(), function(storedValue)
        if storedValue == nil then storedValue = {} end
        relationshipLeaderboard = storedValue
        responseCallback()
    end)
end


function CompletedDate(partner)
    local pairId = GetUniquePairIdentifier(client.localPlayer.name,partner.name)
    local chosenPlayer = GetOriginalStrings(pairId)[1] 
    if(client.localPlayer.name == chosenPlayer) then
        e_sendDateCompleteToServer:FireServer(client.localPlayer,partner)
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
    return str1 .. common.CRelationshipIdDelimiter() .. str2
end

function GetOriginalStrings(identifier)
    local escapedDelimiter = common.CRelationshipIdDelimiter():gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    local str1,str2 = identifier:match("^(.-)" .. escapedDelimiter .. "(.-)$")
    return {str1,str2}
end

function GetFormattedLeaderboard(player,fullLeaderboard,isKeyUniquePairId)
    local kvPairs = {}
    for k, v in pairs(fullLeaderboard) do
        table.insert(kvPairs, {key = k, value = v})
    end
    table.sort(kvPairs, function(a, b) return a.value > b.value end)
    local formatted = {}
    currentCount = 0
    local isPlayerFound = false
    for _, pair in ipairs(kvPairs) do
        local k = pair.key
        local v = pair.value
        if(isKeyUniquePairId) then
            if(GetOriginalStrings(k)[1] == player.name or GetOriginalStrings(k)[2] == player.name)then isPlayerFound = true end
        else
            if(k == player.name) then isPlayerFound = true end
        end
        table.insert(formatted,{name=k,score=v,rank=currentCount+1,isKeyPairId=isKeyUniquePairId})
        currentCount += 1
        if(currentCount == common.CVisibleTopRanks()) then break end
    end
    if( not isPlayerFound )then
        currentCount = 0
        for _, pair in ipairs(kvPairs) do
            local k = pair.key
            local v = pair.value
            local condition = isKeyUniquePairId and (GetOriginalStrings(k)[1] == player.name or GetOriginalStrings(k)[2] == player.name) or (k == player.name)
            if(condition) then
                table.insert(formatted,{name=k,score=v,rank=currentCount+1,isKeyPairId=isKeyUniquePairId})
                break
            end 
            currentCount+=1
        end
    end
    return formatted
end

function DevelopmentOnlyDeleteStorage()
    if(not common.CUseProductionStorage()) then
        e_sendDeleteStorageToServer:FireServer()
        print("Deleted Storage")
    end
end

function DevelopmentOnlyPopulateLeaderboards()
    if(not common.CUseProductionStorage()) then
        local p1 = {}
        local p2 = {}
        local type = "IncrementRelationship"
        if(type == "TopDating") then
            for i = 1, 10 do
                p1.name = "Player "..tostring(i)
                p2.name = "Player "..tostring(i*3)
                e_sendDateCompleteToServer:FireServer(p1,p2)
                p1.name = "Player "..tostring(i)
                p2.name = "Player "..tostring(i*6)
                e_sendDateCompleteToServer:FireServer(p1,p2)
            end
        elseif(type == "IncrementDating") then
            p1.name = "FarhanGulDev"
            p2.name = "LowRankPlayer"..tostring(math.random(1,1000000))
            e_sendDateCompleteToServer:FireServer(p1,p2)
        elseif(type == "TopRelationship") then
            for i = 1, 10 do
                p1.name = "Player "..tostring(math.random(1,1000000))
                p2.name = "Player "..tostring(math.random(1,1000000))
                local randomCount = math.random(4,8)
                for j = 1,randomCount do
                    e_sendDateCompleteToServer:FireServer(p1,p2)
                end
            end
        elseif(type == "IncrementRelationship") then
            p1.name = "FarhanGulDev"
            p2.name = "MyPartner"
            e_sendDateCompleteToServer:FireServer(p1,p2)
        end
        print("Populated leaderboard with dummy data "..type)
    end
end
--!Type(Module)
local events = {}

-- Functions
function self:ClientAwake()
    if(client.localPlayer.name == "FarhanGulDev") then
        if( not CUseProductionStorage()) then print("Using Development Storage") end
        if( CEnableDevCommands()) then print("Development commands enabled") end
        if( CEnableUIDebugging()) then print("UI Debugging enabled") end
    end
end

-- Function accepts list of alternative wait and functions
function Coroutine(...)
    local args = {...}
    if(#args % 2 ~= 0) then print("Invalid paramters passed to coroutine, even number of parameters required. Interval followed by function") end
    _ExecuteCoroutineStep(args, 1)
end

function _ExecuteCoroutineStep(args,i)
    if(i < #args) then
        Timer.new(args[i], function()  
            args[i+1]()
            _ExecuteCoroutineStep(args,i+2)
        end, false)
    end
end

function InvokeEvent(eventName,...)
    if(events[eventName] ~= nil) then
        local args = {...}
        for i = 1 , #events[eventName] do
            events[eventName][i](args)
        end
    end
end

function SubscribeEvent(eventName,callback)
    if(events[eventName] == nil) then events[eventName] = {} end
    table.insert(events[eventName],callback)
end

function UnsubscribeEvent(eventName,callback)
    if(events[eventName] == nil) then events[eventName] = {} end
    table.remove(events[eventName],callback)
end

function ShuffleArray(arr)
    local n = #arr
    for i = n, 2, -1 do
        local j = math.random(i) -- Generate a random index
        arr[i], arr[j] = arr[j], arr[i] -- Swap elements
    end
end

function GetRandomExcluding(from, to, exclude)
    local rand = math.random(from , to)
    while( exclude[rand] ~= nil) do
        rand = math.random(from , to)
    end
    return rand
end

-- Events
function ELocalPlayerOccupiedSeat() return "LocalPlayerOccupiedSeat" end -- void
function ELocalPlayerLeftSeat() return "LocalPlayerLeftSeat" end -- void
function EBeginDate() return "BeginDate" end -- you(Player) , partner(Player) , isYourTurnFirst(Bool)
function EPrivateMessageSent() return "PrivateMessageSent" end -- from(Player) , message(string)
function ETurnStarted() return "TurnStarted" end -- isMyTurn(Bool)
function ELocalPlayerSelectedQuestion() return "LocalPlayerSelectedQuestion" end -- question(string),sendOnChat(bool)
function EPlayerReceivedQuestionFromServer() return "PlayerReceivedQuestion" end -- question(string),sendOnChat(bool)
function EPlayerLeftSeat() return "PlayerLeftSeat" end -- player(Player)
function EUpdateResultStatus() return "UpdateResultStatus" end -- resultStatus(Enum ResultStatus)
function EUpdateSeatOccupant() return "UpdateSeatOccupant" end -- seats(Seats)
function ETryToOccupySeat() return "TryToOccupySeat" end -- id(integer)
function ESubmitVerdict() return "SubmitVerdict" end -- verdict(Enum Verdict)

-- Enumerations
-- Result Status
function NResultStatusCancelled() return "ResultStatusCancelled" end
function NResultStatusAcceptancePending() return "ResultStatusAcceptancePending" end
function NResultStatusAvailabilityPending() return "ResultStatusAvailabilityPending" end
function NResultStatusRejected() return "ResultStatusRejected" end
function NResultStatusBothAccepted() return "ResultStatusBothAccepted" end
function NResultStatusUnrequited() return "ResultStatusUnrequited" end
function NResultStatusPlayAgain() return "ResultStatusPlayAgain" end
function NResultStatusIWillPlayLater() return "ResultStatusIWillPlayLater" end
function NResultStatusPartnerWillPlayLater() return "ResultStatusPartnerWillPlayLater" end
-- RankingType
function NRankingTypeDatingScore() return "RankingTypeDatingScore" end
function NRankingTypeRelationshipScore() return "RankingTypeRelationshipScore" end

-- Verdict
function NVerdictAccept() return "VerdictAccept" end
function NVerdictReject() return "VerdictReject" end
function NVerdictPlayAgain() return "VerdictPlayAgain" end
function NVerdictPlayLater() return "VerdictPlayLater" end

-- Verdict Type
function NVerdictTypeAcceptance() return "VerdictTypeAcceptance" end
function NVerdictTypeAvailability() return "VerdictTypeAvailability" end

-- Duration
function TSeatAvailabilityCooldown() return 4 end

-- Constants

function CRequiredProgress() return CEnableQuickGame() and 1 or 8 end
function CVisibleTopRanks() return 6 end
function CRelationshipIdDelimiter() return "," end 

-- Development Constants
function CUseProductionStorage() return false end
function CEnableDevCommands() return false end
function CEnableUIDebugging() return false end
function CEnableQuickGame() return false end

-- Storage Keys
function KDatingLeaderboard() return CUseProductionStorage() and "DatingLeaderboard" or "_DatingLeaderboard" end
function KRelationshipLeaderboard() return  CUseProductionStorage() and "RelationshipLeaderboard" or "_RelationshipLeaderboard" end
function KPartnerHistory() return  CUseProductionStorage() and "PartnerHistory" or "_PartnerHistory" end
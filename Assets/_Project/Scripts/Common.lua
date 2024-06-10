--!Type(Module)
local events = {}

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
function ELocalPlayerSelectedQuestion() return "LocalPlayerSelectedQuestion" end -- question(string)
function EPlayerReceivedQuestionFromServer() return "PlayerReceivedQuestion" end -- question(string)
function EPlayerLeftSeat() return "PlayerLeftSeat" end -- player(Player)
function EEndDate() return "EndDate" end -- resultStatus(Enum)
function EUpdateSeatOccupant() return "UpdateSeatOccupant" end -- seats(Seats)
function ETryToOccupySeat() return "TryToOccupySeat" end -- id(integer)

--Enumerations
function NResultStatusCancelled() return "ResultStatusCancelled" end
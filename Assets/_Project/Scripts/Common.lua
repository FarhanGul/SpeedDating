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

function ELocalPlayerOccupiedSeat() return "LocalPlayerOccupiedSeat" end -- void
function ELocalPlayerLeftSeat() return "LocalPlayerLeftSeat" end -- void
function ESeatsReceivedFromServer() return "SeatsReceivedFromServer" end -- void
function EBeginDate() return "BeginDate" end -- you(Player) , partner(Player)
function EPrivateMessageSent() return "PrivateMessageSent" end -- from(Player) , message(string)
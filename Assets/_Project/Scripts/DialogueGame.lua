--!Type(ClientAndServer)

local common = require("Common")
local partner
local isMyTurnToQuestion
local waitingForAnswer = false

-- Events
local e_sendPlayerQuestionToServer = Event.new("sendPlayerQuestionToServer")
local e_sendPlayerQuestionToClient = Event.new("sendPlayerQuestionToClient")
local e_sendTurnChangedToServer = Event.new("e_sendTurnChangedToServer")
local e_sendTurnChangedToClient = Event.new("e_sendTurnChangedToClient")

function self:ServerAwake()
    e_sendPlayerQuestionToServer:Connect(function(player,partner,question)
        e_sendPlayerQuestionToClient:FireClient(partner,question)
    end)
    e_sendTurnChangedToServer:Connect(function(player,partner)
        e_sendTurnChangedToClient:FireClient(partner)
    end)
end

function self:ClientAwake()
    common.SubscribeEvent(common.EBeginDate(),BeginGame)
    common.SubscribeEvent(common.ELocalPlayerSelectedQuestion(),HandlePlayerSelectedQuestion)
    common.SubscribeEvent(common.EPrivateMessageSent(),HandlePrivateMessageSent)
    e_sendPlayerQuestionToClient:Connect(function(question)
        waitingForAnswer = true
        common.InvokeEvent(common.EPlayerReceivedQuestionFromServer(),question)
    end)
    e_sendTurnChangedToClient:Connect(function()
        ChangeTurn()
    end)

end

function BeginGame(args)
    partner = args[2]
    isMyTurnToQuestion = args[3]
    Timer.new(4,function() StartTurn() end,false)
end

function StartTurn()
    local randomQuestions = nil
    if(isMyTurnToQuestion) then randomQuestions = GetRandomQuestions() end
    common.InvokeEvent(common.ETurnStarted(),isMyTurnToQuestion,randomQuestions)
end

function ChangeTurn()
    isMyTurnToQuestion = not isMyTurnToQuestion
    StartTurn()
end

function HandlePlayerSelectedQuestion(args)
    e_sendPlayerQuestionToServer:FireServer(partner,args[1])
end

function HandlePrivateMessageSent(args)
    if(waitingForAnswer and args[1] == client.localPlayer) then
        waitingForAnswer = false
        e_sendTurnChangedToServer:FireServer(partner)
        ChangeTurn()
    end
end

function GetRandomQuestions()
    local questions = {
        "What is your real name?",
        "What is your age?",
        "Where are you from?",
        "Would you rather go scuba diving or sky diving?",
        "What is your dream job?",
        "Where did you last travel?",
        "Where would you like to travel to?"
    }
    common.ShuffleArray(questions)
    local randomQuestions = {}
    for i=1,4 do randomQuestions[i] = questions[i] end
    return randomQuestions
end
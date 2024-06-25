--!Type(ClientAndServer)

local common = require("Common")
local ranking = require("Ranking")
local data = require("Data")

local partner
local isMyTurnToQuestion
local waitingForAnswer = false
local partnerVerdict
local myVerdict
local verdictType
local isOpeningQuestion

-- Events
local e_sendPlayerQuestionToServer = Event.new("sendPlayerQuestionToServer")
local e_sendPlayerQuestionToClient = Event.new("sendPlayerQuestionToClient")
local e_sendTurnChangedToServer = Event.new("sendTurnChangedToServer")
local e_sendTurnChangedToClient = Event.new("sendTurnChangedToClient")
local e_sendVerdictToServer = Event.new("sendVerdictToServer")
local e_sendVerdictToClient = Event.new("sendVerdictToClient")

function self:ServerAwake()
    e_sendPlayerQuestionToServer:Connect(function(player,partner,question,sendOnChat)
        e_sendPlayerQuestionToClient:FireClient(partner,question,sendOnChat)
    end)
    e_sendTurnChangedToServer:Connect(function(player,partner)
        e_sendTurnChangedToClient:FireClient(partner)
    end)
    e_sendVerdictToServer:Connect(function(player,partner,verdict)
        e_sendVerdictToClient:FireClient(partner,verdict)
    end)
end

function self:ClientAwake()
    common.SubscribeEvent(common.ESubmitVerdict(),HandlePlayerSubmittedVerdict)
    common.SubscribeEvent(common.EPlayerLeftSeat(),HandlePlayerLeftSeat)
    common.SubscribeEvent(common.EBeginDate(),BeginGame)
    common.SubscribeEvent(common.ELocalPlayerSelectedQuestion(),HandlePlayerSelectedQuestion)
    common.SubscribeEvent(common.EPrivateMessageSent(),HandlePrivateMessageSent)
    e_sendPlayerQuestionToClient:Connect(function(question,sendOnChat)
        waitingForAnswer = true
        common.InvokeEvent(common.EPlayerReceivedQuestionFromServer(),question,sendOnChat)
    end)
    e_sendTurnChangedToClient:Connect(function()
        ChangeTurn()
    end)
    e_sendVerdictToClient:Connect(function(verdict)
        partnerVerdict = verdict
        HandleVerdict()
    end)
end

function BeginGame(args)
    SetVerdictType(common.NVerdictTypeAvailability())
    partner = args[2]
    isOpeningQuestion = true
    isMyTurnToQuestion = args[3]
    Timer.new(2.5,function() 
        if(partner ~= nil) then StartTurn() end
    end,false)
end

function StartTurn()
    local randomQuestions = nil
    if(isMyTurnToQuestion) then
        randomQuestions = GetRandomQuestions(isOpeningQuestion and common.NQuestionTypeOpening() or common.NQuestionTypeDefault())
    end
    isOpeningQuestion = false
    common.InvokeEvent(common.ETurnStarted(),isMyTurnToQuestion,randomQuestions)
end

function ChangeTurn()
    isMyTurnToQuestion = not isMyTurnToQuestion
    StartTurn()
end

function HandleVerdict()
    if(verdictType == common.NVerdictTypeAvailability()) then
        if(myVerdict == common.NVerdictPlayAgain() and partnerVerdict == nil) then
            common.InvokeEvent(common.EUpdateResultStatus(),common.NResultStatusAvailabilityPending())
        elseif(myVerdict == common.NVerdictPlayAgain() and partnerVerdict == common.NVerdictPlayAgain()) then
            PlayAgain()
        elseif(myVerdict == common.NVerdictPlayLater()) then
            EndGame(common.NResultStatusIWillPlayLater())
        elseif(partnerVerdict == common.NVerdictPlayLater()) then
            EndGame(common.NResultStatusPartnerWillPlayLater())
        end
    end
end

function SetVerdictType(newType)
    myVerdict = nil
    partnerVerdict = nil
    verdictType = newType
end

function PlayAgain()
    common.InvokeEvent(common.EUpdateResultStatus(),common.NResultStatusPlayAgain())
    common.InvokeEvent(common.EBeginDate(),client.localPlayer,partner,not isMyTurnToQuestion)
end

function HandlePlayerSubmittedVerdict(args)
    local verdict = args[1]
    myVerdict = verdict
    e_sendVerdictToServer:FireServer(partner,verdict)
    HandleVerdict()
end

function HandlePlayerSelectedQuestion(args)
    e_sendPlayerQuestionToServer:FireServer(partner,args[1],args[2])
end

function HandlePrivateMessageSent(args)
    if(waitingForAnswer and args[1] == client.localPlayer) then
        waitingForAnswer = false
        e_sendTurnChangedToServer:FireServer(partner)
        ChangeTurn()
    end
end

function HandlePlayerLeftSeat(args)
    if(args[1] == partner) then
        EndGame(common.NResultStatusCancelled())
    end
end

function EndGame(resultStatus)
    partner = nil
    waitingForAnswer = nil
    common.InvokeEvent(common.EUpdateResultStatus(),resultStatus)
    common.InvokeEvent(common.EEndDate())
end

function GetRandomQuestions(questionType)
    local questions = questionType == common.NQuestionTypeDefault() and data.GetQuestions() or data.GetOpeningQuestions()
    common.ShuffleArray(questions)
    local randomQuestions = {}
    for i=1,4 do randomQuestions[i] = questions[i] end
    return randomQuestions
end


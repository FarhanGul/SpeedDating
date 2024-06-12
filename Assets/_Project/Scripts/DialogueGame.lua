--!Type(ClientAndServer)

local common = require("Common")
local ranking = require("Ranking")

local partner
local isMyTurnToQuestion
local waitingForAnswer = false
local partnerVerdict
local myVerdict
local verdictType

-- Events
local e_sendPlayerQuestionToServer = Event.new("sendPlayerQuestionToServer")
local e_sendPlayerQuestionToClient = Event.new("sendPlayerQuestionToClient")
local e_sendTurnChangedToServer = Event.new("sendTurnChangedToServer")
local e_sendTurnChangedToClient = Event.new("sendTurnChangedToClient")
local e_sendVerdictToServer = Event.new("sendVerdictToServer")
local e_sendVerdictToClient = Event.new("sendVerdictToClient")

function self:ServerAwake()
    e_sendPlayerQuestionToServer:Connect(function(player,partner,question)
        e_sendPlayerQuestionToClient:FireClient(partner,question)
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
    e_sendPlayerQuestionToClient:Connect(function(question)
        waitingForAnswer = true
        common.InvokeEvent(common.EPlayerReceivedQuestionFromServer(),question)
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
    SetVerdictType(common.NVerdictTypeAcceptance())
    partner = args[2]
    isMyTurnToQuestion = args[3]
    Timer.new(2.5,function() 
        if(partner ~= nil) then StartTurn() end
    end,false)
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

function HandleVerdict()
    -- print(client.localPlayer.name.."@ Handle Verdict - Type ("..verdictType..") - Mine ( "..(myVerdict == nil and "Nothing" or myVerdict).." ) - Partner ("..(partnerVerdict == nil and "Nothing" or partnerVerdict).." )")
    if(verdictType == common.NVerdictTypeAcceptance())then
        if(myVerdict == nil or partnerVerdict == nil) then
            if(partnerVerdict == nil) then
                common.InvokeEvent(common.EUpdateResultStatus(),common.NResultStatusAcceptancePending())
            end
        else
            if(myVerdict == common.NVerdictAccept() and partnerVerdict == common.NVerdictAccept()) then
                ranking.CompletedDate(partner)
                common.InvokeEvent(common.EUpdateResultStatus(),common.NResultStatusBothAccepted())
            elseif(partnerVerdict == common.NVerdictReject()) then
                EndGame(common.NResultStatusRejected())
            elseif(myVerdict == common.NVerdictReject() and partnerVerdict == common.NVerdictAccept()) then
                EndGame(common.NResultStatusUnrequited())
            end
            SetVerdictType(common.NVerdictTypeAvailability())
        end
    elseif(verdictType == common.NVerdictTypeAvailability()) then
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
    e_sendPlayerQuestionToServer:FireServer(partner,args[1])
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
end

function GetRandomQuestions()
    local questions = {
        "What is your real name?",
        "What is your age?",
        "Where are you from?",
        "Would you rather go scuba diving or skydiving?",
        "What is your dream job?",
        "Where did you last travel?",
        "Where would you like to travel to?",
        "What's the most adventurous thing you've ever done?",
        "What's your favorite type of cuisine?",
        "If you could live in any city in the world, where would you live?",
        "Do you prefer cats or dogs?",
        "What's something you've always wanted to learn or try?",
        "If you could have any superpower, what would it be?",
        "What's the weirdest food you've ever tried?",
        "What is your favourite TV Show?",
        "What do you do for fun?",
        "What's the most important lesson you've learned from a past relationship?",
        "If you could time travel, which period would you visit?",
        "If you were stranded on a deserted island and could only bring three things, what would they be?",
        "What book are you reading at the moment?",
        "If you had to be someone else for a day, who would you be and why?",
        "If you could invite anyone, dead or alive, to dinner, who would it be?",
        "What's the most reckless thing you've ever done?",
        "If you won the lottery how would you spend it?",
        "What time in history would you have liked to be born in and why?",
        "If a movie was made about your life, who would you want to play you?",
        "If you could be granted three wishes, what would they be?",
        "Do you like to call or text?",
        "Would you rather time travel to the past or to the future",
        "Have you ever met anyone famous?",
        "What are you passionate about?",
        "Are you an optimist or a pessimist?",
        "Do you play any musical instrument?",
        "How do you de-stress?",
        "Mountains or beaches?",
        "Do you follow politics?",
        "Do you believe in love at first sight?",
        "What is your favorite movie?",
        "Which is your favorite sport?",
        "If I come to your house, what would you cook for me?",
        "What is your favorite food?",
        "What is your favorite tabletop game?",
        "What is the most difficult task you have ever completed?",
        "What is your current favorite app on your phone?",
        "Would you go to space if you could?",
        "What is the strangest food you have ever tried?",
        "Do you enjoy listening to podcasts? If yes, which ones?",
        "Summers or winters?",
        "Coffee or tea?",
        "What habit would you most like to change?",
        "Do you prefer to drive or sit in the passenger seat?",
        "Which is the last Netflix series you watched?",
        "What do you do typically on a weekend?",
        "Do you prefer vanilla or chocolate?",
        "Do you believe in a long-term relationship or short-term flings?",
        "What interests you most in a person?",
        "If you could eliminate one thing from your daily routine forever, what would it be?",
        "Do you like to shop online or at the mall?",
        "What can easily make you angry?",
        "Do you forgive and forget things easily?",
        "Would you rather have a partner with a great sense of humor or a partner who is super attractive?",
        "What according to you is the best thing about being single?",
        "Who would you want to be stuck with on an island?",
        "What kind of music do you like?",
        "How many languages do you speak?",
        "What kind of movies do you like?"
    }
    common.ShuffleArray(questions)
    local randomQuestions = {}
    for i=1,4 do randomQuestions[i] = questions[i] end
    return randomQuestions
end

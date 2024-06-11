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

end

function BeginGame(args)
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
    common.InvokeEvent(common.EEndDate(),resultStatus)
end

function GetResultStatusCancelled() return "ResultStatusCancelled" end

function GetRandomQuestions()
    local questions = {
        "What is your real name?",
        "What is your age?",
        "Where are you from?",
        "Would you rather go scuba diving or skydiving?",
        "What is your dream job?",
        "Where did you last travel?",
        "Where would you like to travel to?",
        "What's a fun fact about yourself that not many people know?",
        "What's the most adventurous thing you've ever done?",
        "What's your favorite type of cuisine?",
        "If you could live in any city in the world, where would you live?",
        "Do you prefer cats or dogs?",
        "What's something you've always wanted to learn or try?",
        "If you could have any superpower, what would it be?",
        "What's the weirdest food you've ever tried?",
        "What is your favourite TV programme?",
        "What do you do for fun?",
        "What's the most important lesson you've learned from a past relationship?",
        "If you could time travel, which period would you visit?",
        "If you were stranded on a deserted island and could only bring three things, what would they be?",
        "Would you rather have the ability to fly or be invisible?",
        "What book are you reading at the moment?",
        "If you had to be someone else for a day, who would you be and why?",
        "If you could invite anyone, dead or alive, to dinner, who would it be?",
        "What's the most reckless thing you've ever done?",
        "If you won the lottery how would you spend it?",
        "What time in history would you have liked to be born in and why?",
        "If a movie was made about your life, who would you want to play you?",
        "If you could be granted three wishes, what would they be?",
        "Do you prefer indoors or outdoors?",
        "Do you like to call or text?",
        "If you were an animal, what would it be?",
        "Would you rather time travel to the past or to the future",
        "Would you rather lose the ability to taste food or lose the ability to hear music?",
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
        "What is the most significant lesson you have taken away from a previous relationship?",
        "What is your favorite food?",
        "What is your favorite tabletop game",
        "What is the most difficult task you have ever completed?",
        "What is your current favorite app on your phone?",
        "What type of holiday is your favorite and why?",
        "Would you go to space if you could?",
        "What is the strangest food you have ever tried?",
        "Do you enjoy listening to podcasts? If yes, which ones?",
        "What kind of weather do you prefer?",
        "Which language would you choose to speak fluently if you could speak any other one?",
        "Are you a coffee or tea person?",
        "Which movie can you watch again and again?",
        "What habit would you most like to change?",
        "Do you prefer to drive or sit in the passenger seat?",
        "Which is the last Netflix series you loved?",
        "What do you do on a typical Sunday?",
        "Do you prefer vanilla or chocolate?",
        "Do you believe in a long-term relationship or short-term flings?",
        "What interests you most in a person?",
        "If you could eliminate one thing from your daily routine forever, what would it be?",
        "Do you like to shop online or at the mall?",
        "What can easily make you angry?",
        "Do you forgive and forget things easily?",
        "Would you rather have a partner with a great sense of humor or a partner who is super attractive?",
        "What according to you is the best thing about being single?",
        "What superpowers would you like to have?",
        "Who would you want to be stuck with on an island?",
        "What kind of music do you like, pop or rock?",
        "How many languages do you speak?",
        "What kind of movies do you like?",
        "What kind of music do you like?"
    }
    common.ShuffleArray(questions)
    local randomQuestions = {}
    for i=1,4 do randomQuestions[i] = questions[i] end
    return randomQuestions
end

--!Type(UI)

local common = require("Common")
local ranking = require("Ranking")

--!Bind
local root : VisualElement = nil
local waitingForCustomQuestion = false

-- Configuration
local FontSize = {
    normal = 0.05,
    heading = 0.07
}

local Colors = {
    grey = Color.new(62/255, 67/255, 71/255),
    darkGrey = Color.new(45/255, 45/255, 45/255),
    lightGrey = Color.new(74/255,74/255,74/255),
    white = Color.white,
    black = Color.black,
    red = Color.new(1, 115/255, 141/255),
    blue = Color.new(115/255, 185/255, 1),
}

-- Private
local chatPanel : UIScrollView
local gamePanel : VisualElement
local progressBar : UIProgressBar
local leaderboardPanel : VisualElement
local partner
local progress

-- Functions
function self:ClientAwake()
    common.SubscribeEvent(common.ELocalPlayerOccupiedSeat(),ShowSittingAlone)
    common.SubscribeEvent(common.EBeginDate(),ShowDialgoueGameIntro)
    common.SubscribeEvent(common.EPrivateMessageSent(),HandlePrivateMessage)
    common.SubscribeEvent(common.ETurnStarted(),ShowGameTurn)
    common.SubscribeEvent(common.EPlayerReceivedQuestionFromServer(),ShowQuestionReceived)
    common.SubscribeEvent(common.ELocalPlayerSelectedQuestion(),ShowQuestionSubmitted)
    common.SubscribeEvent(common.EUpdateResultStatus(),HandleResultStatusUpdated)
    if(common.CEnableUIDebugging()) then ShowDebugUI() else ShowHome() end
end

function ShowVerdictPending(panel)
    panel:Add(CreateLabel("Please wait for your partners verdict",FontSize.heading,Colors.black))
end

function ShowResultStatusBothAccepted(panel)
    panel:Add(CreateLabel("Your date was a success!",FontSize.heading,Colors.black))
    panel:Add(CreateLabel("Keep dating to improve your relationship score",FontSize.normal,Colors.black))
    panel:Add(CreateButton("Date again", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayAgain())
    end))
    panel:Add(CreateLabel("OR",FontSize.heading,Colors.black))
    panel:Add(CreateButton("Catch you later", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayLater())
    end))
    panel:Add(CreateLabel("Speed date with different partners to improve your dating score",FontSize.normal,Colors.black))
end

function ShowResultStatusRejected(panel)
    panel:Add(CreateLabel("You were rejected",FontSize.heading,Colors.black))
    panel:Add(CreateLabel("\"Rejection is merely a redirection\"",FontSize.normal,Colors.grey))
    panel:Add(CreateLabel("You will not be able to play again with your partner until tomorrow",FontSize.normal,Colors.black))
end

function ShowResultStatusUnrequited(panel)
    panel:Add(CreateLabel("Unrequited love",FontSize.heading,Colors.black))
    panel:Add(CreateLabel("Your partner accepted you but you rejected them",FontSize.normal,Colors.grey))
    panel:Add(CreateLabel("You will not be able to play again with your partner until tomorrow",FontSize.normal,Colors.black))
end

function ShowResultStatusPartnerWillPlayLater(panel)
    panel:Add(CreateLabel("Your partner had to leave",FontSize.heading,Colors.black))
    panel:Add(CreateLabel("They will catch you later",FontSize.normal,Colors.grey))
end

function ShowResultStatusPartnerLeft(panel)
    panel:Add(CreateLabel("Partner left",FontSize.heading,Colors.black))
    panel:Add(CreateLabel("Looks like your partner left the world",FontSize.normal,Colors.black))
end

function UninitializeDialogueGame()
    partner = nil
    gamePanel = nil
    chatPanel = nil
    progressBar = nil
    waitingForCustomQuestion = false
end

function HandleResultStatusUpdated(args)
    local resultStatus = args[1]
    local panel = RenderFullScreenPanel()
    local unintialzie = true
    if ( resultStatus == common.NResultStatusAcceptancePending() or resultStatus == common.NResultStatusAvailabilityPending() ) then
        ShowVerdictPending(panel)
        unintialzie = false
    elseif ( resultStatus == common.NResultStatusBothAccepted()) then
        ShowResultStatusBothAccepted(panel)
        unintialzie = false
    elseif ( resultStatus == common.NResultStatusIWillPlayLater()) then
        common.InvokeEvent(common.ELocalPlayerLeftSeat())
        ShowHome()
    else
        if(resultStatus == common.NResultStatusCancelled()) then ShowResultStatusPartnerLeft(panel)
        elseif(resultStatus == common.NResultStatusRejected()) then ShowResultStatusRejected(panel)
        elseif(resultStatus == common.NResultStatusUnrequited()) then ShowResultStatusUnrequited(panel)
        elseif(resultStatus == common.NResultStatusPartnerWillPlayLater()) then ShowResultStatusPartnerWillPlayLater(panel)
        end
        if (resultStatus == common.NResultStatusRejected()) then
            common.InvokeEvent(common.ELocalPlayerLeftSeat())
        end
        if(resultStatus ~= common.NResultStatusPlayAgain()) then
            Timer.new(common.TSeatAvailabilityCooldown(), function()
                if(resultStatus == common.NResultStatusCancelled() or resultStatus == common.NResultStatusPartnerWillPlayLater() 
                    or resultStatus == common.NResultStatusUnrequited()  ) then
                    ShowSittingAlone()
                else
                    ShowHome()
                end
            end,false)
        end
    end
    if(unintialzie) then UninitializeDialogueGame() end
end

function ShowSittingAlone()
    if(partner ~= nil) then return end
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(CreateLabel("Please wait for a partner to join you at the table",FontSize.heading))
    panel:Add(CreateButton("Leave", function()
        ShowHome()
        common.InvokeEvent(common.ELocalPlayerLeftSeat())
    end))
    root:Add(panel)
end

function ShowDialgoueGame()
    progress = 0
    root:Clear()
    local mainPanel = VisualElement.new()
    SetRelativeSize(mainPanel, 100, 100)
    -- Game Panel
    gamePanel = VisualElement.new()
    SetRelativeSize(gamePanel, 100, 45)
    gamePanel.style.backgroundColor = StyleColor.new(Colors.white)
    gamePanel:Add(CreateLabel("Game View",FontSize.heading,Colors.black))
    -- Chat Panel
    chatPanel = UIScrollView.new()
    SetRelativeSize(chatPanel, 100, 45)
    chatPanel:AddToClassList("ScrollViewContent")
    chatPanel.style.backgroundColor = StyleColor.new(Colors.grey)
    local startingLabel = CreateLabel("This is your private chat, it is only visible to you and your partner. Start chatting and have fun! Ask questions in order to progress your date.",FontSize.normal,Colors.white)
    startingLabel:AddToClassList("StartingLabel")
    chatPanel:Add(startingLabel)    
    -- Footer
    local footerPanel = VisualElement.new()
    SetRelativeSize(footerPanel, 100, 10)
    progressBar = CreateDateProgressBar()
    SetBackgroundColor(footerPanel, Colors.darkGrey)
    footerPanel:Add(progressBar)
    -- Construct
    mainPanel:Add(gamePanel)
    mainPanel:Add(chatPanel)
    mainPanel:Add(footerPanel)
    root:Add(mainPanel)
end

function IncrementProgress()
    progress += 1
    progressBar.value = progress / common.CRequiredProgress()
    if(progressBar.value >= 1) then
        ShowAcceptOrReject()
    end
end

function CreateDateProgressBar()
    local bar = UIProgressBar.new()
    SetRelativeSize(bar, 80, 100)
    bar.value = 0
    return bar
end

function ShowAcceptOrReject()
    root:Clear()
    local panel = VisualElement.new()
    SetBackgroundColor(panel, Colors.white)
    SetRelativeSize(panel, 100, 100)
    panel:Add(CreateLabel("Your speed date has finished",FontSize.heading,Colors.black))
    panel:Add(CreateLabel("You can play again to increase your relationship score",FontSize.normal,Colors.black))
    panel:Add(CreateButton("Accept Partner", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictAccept())
    end))
    panel:Add(CreateLabel("OR",FontSize.heading,Colors.black))
    panel:Add(CreateButton("Reject Partner", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictReject())
    end))
    panel:Add(CreateLabel("You will not be able to play again with your partner until tomorrow",FontSize.normal,Colors.black))
    root:Add(panel)
end

function ShowQuestionReceived(args)
    if(args[2]) then HandlePrivateMessage({partner,args[1]}) end
    gamePanel:Clear()
    gamePanel:Add(CreateLabel("It is your turn to answer",FontSize.heading,Colors.black))
    gamePanel:Add(CreateLabel(args[1],FontSize.normal,Colors.lightGrey))
end

function ShowQuestionSubmitted(args)
    HandlePrivateMessage({client.localPlayer,args[1]})
    gamePanel:Clear()
    gamePanel:Add(CreateLabel("Your partner is thinking of an answer please wait",FontSize.heading,Colors.black))
end

function ShowGameTurn(args)
    if(gamePanel == nil) then
        ShowDialgoueGame() 
    else
        IncrementProgress()
    end
    gamePanel:Clear()
    if(args[1])then
        gamePanel:Add(CreateLabel("It is your turn to ask a question",FontSize.heading,Colors.black))
        local scrollView = UIScrollView.new()
        gamePanel:Add(scrollView)
        scrollView:AddToClassList("ScrollViewContent")
        for i = 1, #args[2] do
            scrollView:Add(CreateButton(args[2][i], function()
                common.InvokeEvent(common.ELocalPlayerSelectedQuestion(),args[2][i],true)
            end))
        end
        scrollView:Add(CreateButton("Custom Question", function()
            gamePanel:Clear()
            gamePanel:Add(CreateLabel("It is your turn to ask a question",FontSize.heading,Colors.black))
            gamePanel:Add(CreateLabel("Send in a custom question now using the in-game chat",FontSize.normal,Colors.black))
            waitingForCustomQuestion = true
        end))
    else
        gamePanel:Add(CreateLabel("It is your partner's turn to ask a question, please wait",FontSize.heading,Colors.black))
    end
end

function ShowDialgoueGameIntro(args)
    partner = args[2]
    root:Clear()
    local panel = VisualElement.new()
    SetBackgroundColor(panel, Colors.white)
    SetRelativeSize(panel, 100, 100)
    panel:Add(CreateLabel("You are dating "..args[2].name,FontSize.normal,Colors.black))
    root:Add(panel)
end

function HandlePrivateMessage(args)
    if(chatPanel ~= nil) then
        if(waitingForCustomQuestion and args[1] == client.localPlayer) then
            waitingForCustomQuestion = false
            common.InvokeEvent(common.ELocalPlayerSelectedQuestion(),args[2],false)
            return
        end
        chatPanel:Add(CreateChatMessage(args[1], args[2]))
        chatPanel:AdjustScrollOffsetForNewContent()
    end
end

function CreateChatMessage(player,message)
    local panel = VisualElement.new()
    panel:AddToClassList("ChatMessage")
    panel.style.backgroundColor = player == client.localPlayer and StyleColor.new(Colors.white) or StyleColor.new(Colors.black)
    panel:Add(CreateLabel(message, FontSize.normal,player == client.localPlayer and StyleColor.new(Colors.black) or StyleColor.new(Colors.white)))
    SetMargin(panel, 0.02)
    return panel
end

function ShowDebugUI()
    root:Clear()
    chatPanel = UIScrollView.new()
    chatPanel:AddToClassList("ScrollViewContent")
    chatPanel.style.backgroundColor = StyleColor.new(Colors.grey)
    SetRelativeSize(chatPanel, 100, 45)
    local emptyPanel = VisualElement.new()
    SetBackgroundColor(emptyPanel, Colors.white)
    SetRelativeSize(emptyPanel, 100, 45)
    local button = CreateButton("Send Chat",function()
        chatPanel:Add(CreateChatMessage(client.localPlayer,math.random(1,100000000)))
        chatPanel:AdjustScrollOffsetForNewContent()
    end)
    SetRelativeSize(button, 100, 10)
    root:Add(emptyPanel)
    root:Add(chatPanel)
    root:Add(button)
end

function ShowHome()
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(CreateLabel("Welcome to speed dating!",FontSize.heading))
    panel:Add(CreateLabel("Sit at a table to begin your date",FontSize.normal))
    panel:Add(CreateButton("Ranking",ShowRanking ))
    root:Add(panel)
end

function ShowRanking()
    root:Clear()
    ranking.FetchRelationshipLeaderboard(function()end)
    ranking.FetchDatingLeaderboard(function() 
        local panel = RenderFullScreenPanel()
        panel:Add(CreateLabel("Ranking",FontSize.heading))
        panel:Add(CreateButton("Dating", function() ShowRankingData(common.NRankingTypeDatingScore()) end))
        panel:Add(CreateButton("Relationship", function() ShowRankingData(common.NRankingTypeRelationshipScore()) end))
        leaderboardPanel = VisualElement.new()
        panel:Add(leaderboardPanel)
        panel:Add(CreateButton("Close", function()
            leaderboardPanel = nil
            ShowHome()
        end))
        ShowRankingData(common.NRankingTypeDatingScore())
    end)
end

function ShowRankingData(rankingType)
    leaderboardPanel:Clear()
    local ve = VisualElement.new()
    ve:AddToClassList("HorizontalLayout")
    local variableString = rankingType == common.NRankingTypeDatingScore() and "Name" or "Couple"
    ve:Add(CreateLabel(variableString,FontSize.heading,Colors.black))
    ve:Add(CreateLabel("Score",FontSize.heading,Colors.black))
    leaderboardPanel:Add(ve)
    local playerFound = false
    local data = rankingType == common.NRankingTypeDatingScore() and ranking.DatingLeaderboard() or ranking.RelationshipLeaderboard()
    if(#data == 0) then
        leaderboardPanel:Add(CreateLabel("Looks like no one has scored yet. Start dating!",FontSize.normal,Color.black))
    else
        for i =1 , #data do
            ve = VisualElement.new()
            ve:AddToClassList("HorizontalLayout")
            ve:Add(CreateLabel(tostring(i),FontSize.normal,Color.black))
            ve:Add(CreateLabel(data[i].name,FontSize.normal,Color.black))
            ve:Add(CreateLabel(data[i].score,FontSize.normal,Color.black))
            leaderboardPanel:Add(ve)
        end
    end
    variableString = rankingType == common.NRankingTypeDatingScore() and
    "You get 1 point for each successful date with a new partner" 
    or 
    "You get 1 point for each successful date with an existing partner"
    leaderboardPanel:Add(CreateLabel(variableString,FontSize.normal,Colors.black))
end

function ShowRelationshipScore()
    leaderboardPanel:Clear()
    leaderboardPanel:Add(CreateLabel("You get 1 point for each successful date with an existing partner",FontSize.normal,Colors.black))
end

function CreateLabel(...)
    local args = {...}
    local text = args[1]
    local fontSize = args[2] == nil and FontSize.normal or args[2]
    local color = args[3] == nil and Colors.white or args[3]
    local label = UILabel.new()
    label:SetPrelocalizedText(text, false)
    label.style.color = StyleColor.new(color)
    label.style.fontSize = StyleLength.new(Length.new(fontSize*Screen.dpi))
    return label
end

function CreateButton(text,onPressed)
    local button = UIButton.new()
    SetBackgroundColor(button, Colors.blue)
    button:Add(CreateLabel(text,FontSize.normal,Colors.white)) 
    button:RegisterPressCallback(onPressed)
    return button
end

function SetMargin(ve:VisualElement,amount)
    local scaledAmount = amount * Screen.dpi
    ve.style.marginTop = StyleLength.new(Length.new(scaledAmount))
    ve.style.marginRight = StyleLength.new(Length.new(scaledAmount))
    ve.style.marginBottom = StyleLength.new(Length.new(scaledAmount))
    ve.style.marginLeft = StyleLength.new(Length.new(scaledAmount))
end

function SetBackgroundColor(ve:VisualElement,color)
    ve.style.backgroundColor = StyleColor.new(color)
end

function SetRelativeSize(ve : VisualElement,w,h)
    if(w > -1) then ve.style.width = StyleLength.new(Length.Percent(w)) end
    if(h > -1) then ve.style.height = StyleLength.new(Length.Percent(h)) end
end

function SetSize(ve : VisualElement,w,h)
    if(w > -1) then ve.style.width = StyleLength.new(Length.new(w)) end
    if(h > -1) then ve.style.height = StyleLength.new(Length.new(h)) end
end

function RenderFullScreenPanel()
    root:Clear()
    local panel = VisualElement.new()
    SetBackgroundColor(panel, Colors.white)
    SetRelativeSize(panel, 100, 100)
    root:Add(panel)
    return panel
end
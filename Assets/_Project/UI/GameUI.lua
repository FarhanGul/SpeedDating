--!Type(UI)

local common = require("Common")
local ranking = require("Ranking")

--!Bind
local root : VisualElement = nil
local waitingForCustomQuestion = false

-- Configuration
local FontSize = {
    normal = 17,
    heading = 20
}

local Colors = {
    black = Color.new(20/255, 19/255, 23/255),
    darkGrey = Color.new(40/255, 39/255, 45/255),
    grey = Color.new(63/255, 62/255, 70/255),
    blue = Color.new(13/255, 166/255, 252/255),
    red = Color.new(251/255, 23/255, 105/255),
    white = Color.new(204/255, 202/255, 220/255),
    lightGrey = Color.new(125/255,124/255,136/255),
}

-- Private
local chatPanel : UIScrollView
local gamePanel : VisualElement
local progressBar : UIProgressBar
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
    common.SubscribeEvent(common.EChooseCustomQuestion(),ShowAcceptingCustomQuestion)
    if(common.CEnableUIDebugging()) then ShowDebugUI() else ShowHome() end
end

function ShowVerdictPending(panel)
    panel:Add(CreateLabel("Please wait for your partners verdict",FontSize.heading,Colors.white))
end

function ShowResultStatusBothAccepted(panel)
    panel:Add(CreateLabel("Date finished",FontSize.heading,Colors.white))
    panel:Add(CreateLabel("Keep dating to improve your relationship score",FontSize.normal,Colors.lightGrey))
    panel:Add(CreateButton("Date again", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayAgain())
    end,Colors.blue))
    panel:Add(CreateLabel("OR",FontSize.heading,Colors.white))
    panel:Add(CreateButton("Catch you later", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayLater())
    end,Colors.red))
    panel:Add(CreateLabel("Speed date with different partners to improve your dating score",FontSize.normal,Colors.lightGrey))
end

function ShowResultStatusRejected(panel)
    panel:Add(CreateLabel("You were rejected",FontSize.heading,Colors.white))
    panel:Add(CreateLabel("\"Rejection is merely a redirection\"",FontSize.normal,Colors.lightGrey))
    panel:Add(CreateLabel("You will not be able to play again with your partner until tomorrow",FontSize.normal,Colors.lightGrey))
end

function ShowResultStatusUnrequited(panel)
    panel:Add(CreateLabel("Unrequited love",FontSize.heading,Colors.white))
    panel:Add(CreateLabel("Your partner accepted you but you rejected them",FontSize.normal,Colors.lightGrey))
    panel:Add(CreateLabel("You will not be able to play again with your partner until tomorrow",FontSize.normal,Colors.lightGrey))
end

function ShowResultStatusPartnerWillPlayLater(panel)
    panel:Add(CreateLabel("Your partner had to leave",FontSize.heading,Colors.white))
    panel:Add(CreateLabel("They will catch you later",FontSize.normal,Colors.lightGrey))
end

function ShowResultStatusPartnerLeft(panel)
    panel:Add(CreateLabel("Partner left",FontSize.heading,Colors.white))
    panel:Add(CreateLabel("Looks like your partner left the world",FontSize.normal,Colors.lightGrey))
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
    gamePanel:Clear()
    local unintialzie = true
    if ( resultStatus == common.NResultStatusAcceptancePending() or resultStatus == common.NResultStatusAvailabilityPending() ) then
        ShowVerdictPending(gamePanel)
        unintialzie = false
    elseif ( resultStatus == common.NResultStatusBothAccepted()) then
        ShowResultStatusBothAccepted(gamePanel)
        unintialzie = false
    elseif ( resultStatus == common.NResultStatusIWillPlayLater()) then
        common.InvokeEvent(common.ELocalPlayerLeftSeat())
        ShowHome()
    else
        if(resultStatus == common.NResultStatusCancelled()) then ShowResultStatusPartnerLeft(gamePanel)
        elseif(resultStatus == common.NResultStatusRejected()) then ShowResultStatusRejected(gamePanel)
        elseif(resultStatus == common.NResultStatusUnrequited()) then ShowResultStatusUnrequited(gamePanel)
        elseif(resultStatus == common.NResultStatusPartnerWillPlayLater()) then ShowResultStatusPartnerWillPlayLater(gamePanel)
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
    end,Colors.red))
    root:Add(panel)
end

function ShowDialgoueGame()
    progress = 0
    root:Clear()
    local mainPanel = VisualElement.new()
    SetRelativeSize(mainPanel, 100, 100)
    mainPanel.style.backgroundColor = StyleColor.new(Colors.black)

    -- Game Panel
    gamePanel = VisualElement.new()
    gamePanel:AddToClassList("GamePanel")
    gamePanel.style.backgroundColor = StyleColor.new(Colors.darkGrey)
    -- Chat Panel
    chatPanel = UIScrollView.new()
    chatPanel:AddToClassList("Grow")
    -- SetRelativeSize(chatPanel, 100, -1)
    chatPanel:AddToClassList("ScrollViewContent")
    local startingLabel = CreateLabel("This is your private chat, it is only visible to you and your partner. Start chatting and have fun! Ask questions in order to progress your date.",FontSize.normal,Colors.white)
    startingLabel:AddToClassList("StartingLabel")
    chatPanel:Add(startingLabel)    
    progressBar = CreateDateProgressBar()
    -- Construct
    mainPanel:Add(gamePanel)
    mainPanel:Add(chatPanel)
    mainPanel:Add(progressBar)
    root:Add(mainPanel)
end

function IncrementProgress()
    progress += 1
    progressBar.value = progress / common.CRequiredProgress()
    if(progressBar.value >= 1) then
        ranking.CompletedDate(partner)
        common.InvokeEvent(common.EUpdateResultStatus(),common.NResultStatusBothAccepted())
    end
end

function CreateDateProgressBar()
    local bar = UIProgressBar.new()
    bar.value = 0
    return bar
end

function ShowQuestionReceived(args)
    if(args[2]) then HandlePrivateMessage({partner,args[1]}) end
    gamePanel:Clear()
    gamePanel:Add(CreateLabel("Your turn to answer!",FontSize.heading,Colors.blue))
    gamePanel:Add(CreateLabel(args[1],FontSize.normal,Colors.lightGrey))
end

function ShowQuestionSubmitted(args)
    HandlePrivateMessage({client.localPlayer,args[1]})
    gamePanel:Clear()
    gamePanel:Add(CreateLabel("Waiting for answer...",FontSize.heading,Colors.white))
end

function ShowAcceptingCustomQuestion()
    gamePanel:Clear()
    gamePanel:Add(CreateLabel("Your turn to ask!",FontSize.heading,Colors.blue))
    gamePanel:Add(CreateLabel("Send in a custom question now using the in-game chat",FontSize.normal,Colors.lightGrey))
    waitingForCustomQuestion = true
end

function ShowGameTurn(args)
    if(gamePanel == nil) then
        ShowDialgoueGame()
    else
        IncrementProgress()
    end
    if(progressBar.value >= 1) then return end
    gamePanel:Clear()
    if(args[1])then
        gamePanel:Add(CreateLabel("Your turn to ask!",FontSize.heading,Colors.blue))
        local scrollView = UIScrollView.new()
        gamePanel:Add(scrollView)
        scrollView:AddToClassList("ScrollViewContent")
        for i = 1, #args[2] do
            local button = CreateButton(args[2][i], function()
                common.InvokeEvent(common.ELocalPlayerSelectedQuestion(),args[2][i],true)
            end,Colors.grey,"QuestionButton")
            scrollView:Add(button)
        end
        local button = CreateButton("Custom Question", function()
            common.InvokeEvent(common.EChooseCustomQuestion())
        end,Colors.grey,"QuestionButton")
        scrollView:Add(button)
    else
        gamePanel:Add(CreateLabel("Waiting For Question...",FontSize.heading,Colors.white))
    end
end

function ShowDialgoueGameIntro(args)
    partner = args[2]
    local panel = RenderFullScreenPanel()
    local label = CreateLabel("You are dating "..args[2].name,FontSize.normal,Colors.white)
    SetRelativeSize(label, 100, 100)
    panel:Add(label)
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
    local accentColor = player == client.localPlayer and "#0DA6FC" or "#CCCADC"
    panel:AddToClassList("HorizontalLayout")
    local richText = "<color="..accentColor..">"..player.name..": <color=#7D7C88>"..message.."</color>"
    local label = CreateLabel(richText,FontSize.normal,Colors.white)
    label:AddToClassList("LeftTextAlign")
    panel:Add(label)
    SetMargin(panel, 6)
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
    end,Colors.blue)
    SetRelativeSize(button, 100, 10)
    root:Add(emptyPanel)
    root:Add(chatPanel)
    root:Add(button)
end

function ShowHome()
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(CreateLabel("Welcome to speed dating!",FontSize.heading,Colors.white))
    panel:Add(CreateLabel("Sit at a table to begin your date",FontSize.normal,Colors.lightGrey))
    panel:Add(CreateButton("Ranking",ShowRanking ,Colors.blue))
    root:Add(panel)
end

function ShowRanking()
    root:Clear()
    ranking.FetchRelationshipLeaderboard(function()end)
    ranking.FetchDatingLeaderboard(function() 
        local panel = RenderFullScreenPanel()
        local title = CreateLabel("Ranking",FontSize.heading,Colors.white)
        local leaderboardPanel = VisualElement.new()
        local guideLabel = CreateLabel("",FontSize.normal,Colors.lightGrey)
        local tabOptions = {{
            text = "Dating",
            pressed = function() ShowRankingData(common.NRankingTypeDatingScore(),leaderboardPanel,guideLabel) end
        },{
            text = "Relationship",
            pressed = function() ShowRankingData(common.NRankingTypeRelationshipScore(),leaderboardPanel,guideLabel) end
        }}
        local tabs = CreateTabs(tabOptions)
        local closeButton = CreateButton("Close", function()
            ShowHome()
        end,Colors.red)
        panel:Add(title)
        panel:Add(tabs)
        panel:Add(leaderboardPanel)
        panel:Add(guideLabel)
        panel:Add(closeButton)
        SetRelativeSize(title, 90, 5)
        SetRelativeSize(tabs, 90, 10)
        SetRelativeSize(leaderboardPanel, 90, 68)
        SetRelativeSize(guideLabel, 90, 10)
        ShowRankingData(common.NRankingTypeDatingScore(),leaderboardPanel,guideLabel)
    end)
end

function ShowRankingData(rankingType,leaderboardPanel,guideLabel)
    leaderboardPanel:Clear()
    local ve = VisualElement.new()
    ve:AddToClassList("HorizontalSpaceBetween")
    local variableString = rankingType == common.NRankingTypeDatingScore() and "Name" or "Couple"
    ve:Add(CreateLabel(variableString,FontSize.heading,Colors.white))
    ve:Add(CreateLabel("Score",FontSize.heading,Colors.white))
    leaderboardPanel:Add(ve)
    local playerFound = false
    local data = rankingType == common.NRankingTypeDatingScore() and ranking.DatingLeaderboard() or ranking.RelationshipLeaderboard()
    if(#data == 0) then
        leaderboardPanel:Add(CreateLabel("Looks like no one has scored yet. Start dating!",FontSize.normal,Colors.lightGrey))
    else
        local myEntryShown = false
        for i =1 , #data do
            ve = VisualElement.new()
            ve:AddToClassList("HorizontalSpaceBetween")
            local playerVe = VisualElement.new()
            playerVe:AddToClassList("HorizontalLayout")
            local rankLabel = CreateLabel(data[i].rank,FontSize.normal,Colors.white)
            rankLabel.style.width = StyleLength.new(Length.Percent(10))
            rankLabel:AddToClassList("DontOverflow")
            playerVe:Add(rankLabel)
            playerVe.style.width = StyleLength.new(Length.Percent(80))
            if(data[i].isKeyPairId) then
                local labels = {}
                local couple = ranking.GetOriginalStrings(data[i].name)
                labels[1] = CreateLabel(couple[1],FontSize.normal,Colors.white)
                labels[2] = CreateLabel("&",FontSize.normal,Colors.lightGrey)
                labels[3] = CreateLabel(couple[2],FontSize.normal,Colors.white)
                for i=1,#labels do
                    labels[i].style.marginLeft = StyleLength.new(Length.new( (i == 1 and 7 or 4)))
                    if(i~=2) then labels[i]:AddToClassList("DontOverflow") end
                    labels[i]:AddToClassList("LeftTextAlign")
                    playerVe:Add(labels[i])
                end
            else
                local nameLabel = CreateLabel(data[i].name,FontSize.normal,Colors.white)
                nameLabel.style.marginLeft = StyleLength.new(Length.new(7))
                nameLabel:AddToClassList("DontOverflow")
                nameLabel:AddToClassList("LeftTextAlign")
                playerVe:Add(nameLabel)
            end
            if( string.match(data[i].name, client.localPlayer.name)~= nil and not myEntryShown )then
                ve:AddToClassList("MyLeaderboardEntry")
                myEntryShown = true
            end
            ve:Add(playerVe)
            local scoreLabel = CreateLabel(data[i].score,FontSize.normal,Colors.white)
            scoreLabel.style.width = StyleLength.new(Length.Percent(10))
            scoreLabel:AddToClassList("DontOverflow")
            scoreLabel:AddToClassList("RightTextAlign")
            ve:Add(scoreLabel)
            leaderboardPanel:Add(ve)
        end
    end
    variableString = rankingType == common.NRankingTypeDatingScore() and
    "You get 1 point for each date with a new partner" 
    or 
    "You get 1 point for each date with an existing partner"
    guideLabel:SetPrelocalizedText(variableString,false)

end

function CreateTabs(options)
    local ve = VisualElement.new()
    ve:AddToClassList("HorizontalLayout")
    for i = 1 , #options do
        local button = UIButton.new()
        button.style.color = StyleColor.new(Color.clear)
        button:Add(CreateLabel(options[i].text,FontSize.normal,Color.white)) 
        button.style.borderBottomColor = StyleColor.new(Colors.blue)
        button:RegisterPressCallback(function()
            for j = 1 , ve.childCount do
                local child = ve:ElementAt(j-1)
                if(button == child) then
                    -- Select
                    child:ElementAt(0).style.color = StyleColor.new(Colors.blue)
                    child.style.borderBottomWidth = StyleFloat.new(3)
                else
                    -- Unselect
                    child:ElementAt(0).style.color = StyleColor.new(Colors.white)
                    child.style.borderBottomWidth =  StyleFloat.new(0)
                end
            end
            options[i].pressed()
        end)
        ve:Add(button)
        -- Select Default
        ve:ElementAt(0):ElementAt(0).style.color = StyleColor.new(Colors.blue)
        ve:ElementAt(0).style.borderBottomWidth = StyleFloat.new(3)
    end

    return ve
end

function CreateLabel(...)
    local args = {...}
    local text = args[1]
    local fontSize = args[2] == nil and FontSize.normal or args[2]
    local color = args[3] == nil and Colors.white or args[3]
    local label = UILabel.new()
    label:SetPrelocalizedText(text, false)
    label.style.color = StyleColor.new(color)
    label.style.fontSize = StyleLength.new(Length.new(fontSize))
    label:AddToClassList("DefaultLabel")
    return label
end

function CreateButton(text,onPressed,color,class)
    local button = UIButton.new()
    SetBackgroundColor(button, color)
    local label = CreateLabel(text,FontSize.normal,Colors.white)
    button:Add(label) 
    button:AddToClassList(class == nil and "DefaultButton" or class)
    button:RegisterPressCallback(onPressed)
    return button
end

function SetMargin(ve:VisualElement,amount)
    local scaledAmount = amount
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
    SetBackgroundColor(panel, Colors.black)
    SetRelativeSize(panel, 100, 100)
    root:Add(panel)
    return panel
end
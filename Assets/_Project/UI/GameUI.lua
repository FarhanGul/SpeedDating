--!Type(UI)

local common = require("Common")
local ranking = require("Ranking")
local musicManager = require("MusicManager")
local ui = require("UILibrary")

--!Bind
local root : VisualElement = nil
local waitingForCustomQuestion = false

-- Private
local chatPanel : UIScrollView
local gamePanel : VisualElement
local progressBar : UIProgressBar
local partner
local progress
local exitButton

-- Functions
function self:ClientAwake()
    common.SubscribeEvent(common.EBeginDate(),ShowDialgoueGameIntro)
    common.SubscribeEvent(common.EPrivateMessageSent(),HandlePrivateMessage)
    common.SubscribeEvent(common.ETurnStarted(),ShowGameTurn)
    common.SubscribeEvent(common.EPlayerReceivedQuestionFromServer(),ShowQuestionReceived)
    common.SubscribeEvent(common.ELocalPlayerSelectedQuestion(),ShowQuestionSubmitted)
    common.SubscribeEvent(common.EUpdateResultStatus(),HandleResultStatusUpdated)
    common.SubscribeEvent(common.EChooseCustomQuestion(),ShowAcceptingCustomQuestion)
    common.SubscribeEvent(common.EDateRequestReceived(),ShowDateRequestReceived)
    common.SubscribeEvent(common.EIsDateRequestValidReceived(),HandleIsDateRequestValidReceived)
    common.SubscribeEvent(common.EProposalVerdictReceived(),HandleProposalVerdictReceived)
    if(common.CEnableUIDebugging()) then ShowDebugUI() else ShowTutorial() end
end

function HandleIsDateRequestValidReceived(args)
    if(args[1] == client.localPlayer.name)then
        if(args[2] == common.NVerdictAccept())then
            ShowAskingForPermission()
        end
    end
end

function ShowAskingForPermission()
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(ui.CreateLabel("Please wait",ui.FontSize().heading))
    panel:Add(ui.CreateLabel("Asking for permission",ui.FontSize().normal,ui.Colors().lightGrey))
    panel:Add(ui.CreateButton("Cancel Request", function()
        common.InvokeEvent(common.ECancelDateRequest())
    end,ui.Colors().red))
    root:Add(panel)
end

function HandleProposalVerdictReceived(args)
    local verdict = args[1]
    root:Clear()
    local panel = VisualElement.new()
    if(verdict == common.NVerdictReject()) then
        panel:Add(ui.CreateLabel("Your partner is not interested",ui.FontSize().heading,ui.Colors().white))
        panel:Add(ui.CreateLabel("Please try another player",ui.FontSize().normal,ui.Colors().lightGrey))
    elseif(verdict == common.NVerdictPlayerLeft()) then
        panel:Add(ui.CreateLabel("Request cancelled",ui.FontSize().heading,ui.Colors().white))
        panel:Add(ui.CreateLabel("Your partner left the world",ui.FontSize().normal,ui.Colors().lightGrey))
    elseif(verdict == common.NVerdictPlayLater()) then
        ShowHome()
    end
    root:Add(panel)
    if(verdict == common.NVerdictReject() or verdict == common.NVerdictPlayerLeft() ) then
        Timer.new(common.TSelfDistructingNotificationDuration(), function()
            if(root:Contains(panel)) then ShowHome() end
        end, false)
    end
end

function ShowDateRequestReceived(args)
    local requestingPlayerName = args[1]
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(ui.CreateLabel(requestingPlayerName.." has sent you a date request",ui.FontSize().heading))
    panel:Add(ui.CreateButton("Accept", function()
        common.InvokeEvent(common.ESubmitDateRequestVerdict(),common.NVerdictAccept())
    end,ui.Colors().blue))
    panel:Add(ui.CreateButton("Refuse", function()
        common.InvokeEvent(common.ESubmitDateRequestVerdict(),common.NVerdictReject())
        ShowHome()
    end,ui.Colors().red))
    root:Add(panel)
end

function ShowVerdictPending(panel)
    panel:Add(ui.CreateLabel("Please wait for your partners verdict",ui.FontSize().heading,ui.Colors().white))
end

function ShowResultStatusBothAccepted(panel)
    panel:Add(ui.CreateLabel("Date finished",ui.FontSize().heading,ui.Colors().white))
    panel:Add(ui.CreateLabel("Keep dating to improve your relationship score",ui.FontSize().normal,ui.Colors().lightGrey))
    panel:Add(ui.CreateButton("Date again", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayAgain())
    end,ui.Colors().blue))
    panel:Add(ui.CreateLabel("OR",ui.FontSize().heading,ui.Colors().white))
    panel:Add(ui.CreateButton("Catch you later", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayLater())
    end,ui.Colors().red))
    panel:Add(ui.CreateLabel("Speed date with different partners to improve your dating score",ui.FontSize().normal,ui.Colors().lightGrey))
end

function ShowResultStatusRejected(panel)
    panel:Add(ui.CreateLabel("You were rejected",ui.FontSize().heading,ui.Colors().white))
    panel:Add(ui.CreateLabel("\"Rejection is merely a redirection\"",ui.FontSize().normal,ui.Colors().lightGrey))
    panel:Add(ui.CreateLabel("You will not be able to play again with your partner until tomorrow",ui.FontSize().normal,ui.Colors().lightGrey))
end

function ShowResultStatusUnrequited(panel)
    panel:Add(ui.CreateLabel("Unrequited love",ui.FontSize().heading,ui.Colors().white))
    panel:Add(ui.CreateLabel("Your partner accepted you but you rejected them",ui.FontSize().normal,ui.Colors().lightGrey))
    panel:Add(ui.CreateLabel("You will not be able to play again with your partner until tomorrow",ui.FontSize().normal,ui.Colors().lightGrey))
end

function ShowResultStatusPartnerWillPlayLater(panel)
    panel:Add(ui.CreateLabel("Partner left",ui.FontSize().heading,ui.Colors().white))
    panel:Add(ui.CreateLabel("Your partner left the date",ui.FontSize().normal,ui.Colors().lightGrey))
end

function ShowResultStatusPartnerLeft(panel)
    panel:Add(ui.CreateLabel("Partner left",ui.FontSize().heading,ui.Colors().white))
    panel:Add(ui.CreateLabel("Looks like your partner left the world",ui.FontSize().normal,ui.Colors().lightGrey))
end

function UninitializeDialogueGame()
    partner = nil
    gamePanel = nil
    chatPanel = nil
    progressBar = nil
    waitingForCustomQuestion = false
    exitButton:RemoveFromHierarchy()
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
        if(resultStatus ~= common.NResultStatusPlayAgain()) then
            root:Clear()
            local ve = VisualElement.new()
            ve:Add(ui.CreateLabel("Date Finished",ui.FontSize().heading,ui.Colors().white))
            ve:Add(ui.CreateLabel("Your partner left",ui.FontSize().normal,ui.Colors().lightGrey))
            root:Add(ve)
            Timer.new(common.TSelfDistructingNotificationDuration(), function()
                if(root:Contains(ve)) then ShowHome() end
            end, false)
        end
    end
    ScrollChatToEnd()
    if(unintialzie) then UninitializeDialogueGame() end
end

function ShowSittingAlone()
    if(partner ~= nil) then return end
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(ui.CreateLabel("Please wait for a partner to join you at the table",ui.FontSize().heading))
    panel:Add(ui.CreateButton("Leave", function()
        ShowHome()
        common.InvokeEvent(common.ELocalPlayerLeftSeat())
    end,ui.Colors().red))
    root:Add(panel)
end

function ShowDialgoueGame()
    progress = 0
    root:Clear()
    local mainPanel = VisualElement.new()
    ui.SetRelativeSize(mainPanel, 100, 100)
    mainPanel.style.backgroundColor = StyleColor.new(ui.Colors().black)

    -- Game Panel
    gamePanel = VisualElement.new()
    gamePanel:AddToClassList("GamePanel")
    -- Chat Panel
    chatPanel = UIScrollView.new()
    chatPanel:AddToClassList("ScrollViewContent")
    local startingLabel = ui.CreateLabel("This is your private chat, it is only visible to you and your partner. Start chatting and have fun! Ask questions in order to progress your date.",ui.FontSize().normal,ui.Colors().white)
    startingLabel:AddToClassList("StartingLabel")
    chatPanel:Add(startingLabel)   
    --Progress Bar
    progressBar = CreateDateProgressBar()
    --Exit Button
    exitButton = ui.CreateButton("Leave", function()
        ShowExitConfirmation()
    end, ui.Colors().red, nil)
    
    -- Construct
    mainPanel:Add(gamePanel)
    mainPanel:Add(chatPanel)
    mainPanel:Add(exitButton)
    mainPanel:Add(progressBar)
    root:Add(mainPanel)
end

function ShowExitConfirmation()
    local modalContainer = VisualElement.new()
    ui.SetRelativeSize(modalContainer, 100, 100)
    local modal = VisualElement.new()
    modal:Add(ui.CreateLabel("Are you sure you want to leave your date?",ui.FontSize().normal,ui.Colors().white))
    modal:Add(ui.CreateButton("Yes", function()
        common.InvokeEvent(common.ESubmitVerdict(),common.NVerdictPlayLater())
    end, ui.Colors().red, nil))
    modal:Add(ui.CreateButton("No", function()
        modalContainer:RemoveFromHierarchy()
    end, ui.Colors().blue, nil))
    modal:AddToClassList("Modal")
    modalContainer:AddToClassList("ModalContainer")
    modalContainer:Add(modal)
    root:Add(modalContainer)
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
    gamePanel:Add(ui.CreateLabel("Your turn to answer!",ui.FontSize().heading,ui.Colors().blue))
    gamePanel:Add(ui.CreateLabel(args[1],ui.FontSize().normal,ui.Colors().lightGrey))
    ScrollChatToEnd()
end

function ShowQuestionSubmitted(args)
    gamePanel:Clear()
    gamePanel:Add(ui.CreateLabel("Waiting for answer...",ui.FontSize().heading,ui.Colors().white))
    HandlePrivateMessage({client.localPlayer,args[1]})
end

function ShowAcceptingCustomQuestion()
    gamePanel:Clear()
    gamePanel:Add(ui.CreateLabel("Your turn to ask!",ui.FontSize().heading,ui.Colors().blue))
    gamePanel:Add(ui.CreateLabel("Send in a custom question now using the in-game chat",ui.FontSize().normal,ui.Colors().lightGrey))
    waitingForCustomQuestion = true
    ScrollChatToEnd()
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
        gamePanel:Add(ui.CreateLabel("Your turn to ask!",ui.FontSize().heading,ui.Colors().blue))
        local scrollView = UIScrollView.new()
        gamePanel:Add(scrollView)
        scrollView:AddToClassList("ScrollViewContent")
        for i = 1, #args[2] do
            local button = ui.CreateButton(args[2][i], function()
                common.InvokeEvent(common.ELocalPlayerSelectedQuestion(),args[2][i],true)
            end,ui.Colors().grey,"QuestionButton")
            scrollView:Add(button)
        end
        local button = ui.CreateButton("Custom Question", function()
            common.InvokeEvent(common.EChooseCustomQuestion())
        end,ui.Colors().grey,"QuestionButton")
        scrollView:Add(button)
    else
        gamePanel:Add(ui.CreateLabel("Waiting For Question...",ui.FontSize().heading,ui.Colors().white))
    end
    ScrollChatToEnd()
end

function ShowDialgoueGameIntro(args)
    partner = args[2]
    local panel = ui.RenderFullScreenPanel(root)
    local label = ui.CreateLabel("You are dating "..args[2].name,ui.FontSize().normal,ui.Colors().white)
    ui.SetRelativeSize(label, 100, 100)
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
        ScrollChatToEnd()
    end
end

function ScrollChatToEnd()
    if(chatPanel ~= nil) then
        chatPanel:AdjustScrollOffsetForNewContent()
        chatPanel:ScrollToEnd()
    end
end

function CreateChatMessage(player,message)
    local panel = VisualElement.new()
    local accentColor = player == client.localPlayer and "#0DA6FC" or "#CCCADC"
    panel:AddToClassList("HorizontalLayout")
    local richText = "<color="..accentColor..">"..player.name..":</color> <color=#7D7C88> "..common.ReplaceEmojiCodes(message).." </color>"
    local label = ui.CreateLabel(richText,ui.FontSize().normal,ui.Colors().white)
    label:AddToClassList("LeftTextAlign")
    panel:Add(label)
    ui.SetMargin(panel, 6)
    return panel
end

function ShowDebugUI()
    ShowDialgoueGame()
    ShowResultStatusBothAccepted(gamePanel)
    Timer.Every(3, function() 
        chatPanel:Add(CreateChatMessage(client.localPlayer,math.random(1,100000000)))
        chatPanel:AdjustScrollOffsetForNewContent()
        chatPanel:ScrollToEnd()
    end)
end

function ShowHome()
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(ui.CreateLabel("Tap on a player to send a date request",ui.FontSize().heading,ui.Colors().white))
    panel:Add(ui.CreateButton("Ranking",ShowRanking ,ui.Colors().blue))
    if(musicManager.GetIsMuted()) then
        panel:Add(ui.CreateButton("Enable Music",function()
            musicManager.SetIsMuted(false)
            ShowHome()
        end ,ui.Colors().blue))
    else
        panel:Add(ui.CreateButton("Disable Music",function()
            musicManager.SetIsMuted(true)
            ShowHome()
        end ,ui.Colors().red))
    end
    root:Add(panel)
end

function ShowTutorial()
    local panel = ui.RenderFullScreenPanel(root)
    panel:AddToClassList("VerticalLayout")
    panel:Add(ui.CreateLabel("Welcome to Find A Bae!",ui.FontSize().heading,ui.Colors().white))
    local categoryBlock = VisualElement.new()
    categoryBlock:Add(ui.CreateLabel("How to play",ui.FontSize().normal,ui.Colors().white))
    categoryBlock:Add(ui.CreateLabel("Tap on player to send a date request. If they accept, start chatting! Keep the conversation flowing, our curated list of questions are there to spark your creativity",ui.FontSize().normal,ui.Colors().lightGrey))
    panel:Add(categoryBlock)
    categoryBlock = VisualElement.new()
    categoryBlock:Add(ui.CreateLabel("Tips for a great date",ui.FontSize().normal,ui.Colors().white))
    categoryBlock:Add(ui.CreateLabel("Show genuine interest in your date by asking questions and listening to their answers. Authenticity is attractive, share your true thoughts and feelings",ui.FontSize().normal,ui.Colors().lightGrey))
    panel:Add(categoryBlock)
    categoryBlock = VisualElement.new()
    categoryBlock:Add(ui.CreateLabel("Safety & Respect",ui.FontSize().normal,ui.Colors().white))
    categoryBlock:Add(ui.CreateLabel("Always be respectful and considerate. Everyone deserves a safe and comfortable experience.",ui.FontSize().normal,ui.Colors().lightGrey))
    panel:Add(categoryBlock)
    categoryBlock = VisualElement.new()
    categoryBlock:Add(ui.CreateLabel("Ranking",ui.FontSize().normal,ui.Colors().white))
    categoryBlock:Add(ui.CreateLabel("Challenge yourself to reach the top of the dating and relationship leaderboards by meeting new partners or nurturing your existing relationships.",ui.FontSize().normal,ui.Colors().lightGrey))
    panel:Add(categoryBlock)
    panel:Add(ui.CreateButton("Continue",ShowHome,ui.Colors().blue))
end

function ShowRanking()
    root:Clear()
    ranking.FetchRelationshipLeaderboard(function()end)
    ranking.FetchDatingLeaderboard(function() 
        local panel = ui.RenderFullScreenPanel(root)
        local title = ui.CreateLabel("Ranking",ui.FontSize().heading,ui.Colors().white)
        local leaderboardPanel = VisualElement.new()
        local guideLabel = ui.CreateLabel("",ui.FontSize().normal,ui.Colors().lightGrey)
        local tabOptions = {{
            text = "Dating",
            pressed = function() ShowRankingData(common.NRankingTypeDatingScore(),leaderboardPanel,guideLabel) end
        },{
            text = "Relationship",
            pressed = function() ShowRankingData(common.NRankingTypeRelationshipScore(),leaderboardPanel,guideLabel) end
        }}
        local tabs = ui.CreateTabs(tabOptions)
        local closeButton = ui.CreateButton("Close", function()
            ShowHome()
        end,ui.Colors().red)
        panel:Add(title)
        panel:Add(tabs)
        panel:Add(leaderboardPanel)
        panel:Add(guideLabel)
        panel:Add(closeButton)
        ui.SetRelativeSize(title, 90, 5)
        ui.SetRelativeSize(tabs, 90, 10)
        ui.SetRelativeSize(leaderboardPanel, 90, 68)
        ui.SetRelativeSize(guideLabel, 90, 10)
        ShowRankingData(common.NRankingTypeDatingScore(),leaderboardPanel,guideLabel)
    end)
end

function ShowRankingData(rankingType,leaderboardPanel,guideLabel)
    leaderboardPanel:Clear()
    local ve = VisualElement.new()
    ve:AddToClassList("HorizontalSpaceBetween")
    local variableString = rankingType == common.NRankingTypeDatingScore() and "Name" or "Couple"
    ve:Add(ui.CreateLabel(variableString,ui.FontSize().heading,ui.Colors().white))
    ve:Add(ui.CreateLabel("Score",ui.FontSize().heading,ui.Colors().white))
    leaderboardPanel:Add(ve)
    local playerFound = false
    local data = rankingType == common.NRankingTypeDatingScore() and ranking.DatingLeaderboard() or ranking.RelationshipLeaderboard()
    if(#data == 0) then
        leaderboardPanel:Add(ui.CreateLabel("Looks like no one has scored yet. Start dating!",ui.FontSize().normal,ui.Colors().lightGrey))
    else
        local myEntryShown = false
        for i =1 , #data do
            ve = VisualElement.new()
            ve:AddToClassList("HorizontalSpaceBetween")
            local playerVe = VisualElement.new()
            playerVe:AddToClassList("HorizontalLayout")
            local rankLabel = ui.CreateLabel(data[i].rank,ui.FontSize().normal,ui.Colors().white)
            rankLabel.style.width = StyleLength.new(Length.Percent(10))
            rankLabel:AddToClassList("DontOverflow")
            playerVe:Add(rankLabel)
            playerVe.style.width = StyleLength.new(Length.Percent(80))
            if(data[i].isKeyPairId) then
                local labels = {}
                local couple = common.GetOriginalStrings(data[i].name)
                labels[1] = ui.CreateLabel(couple[1],ui.FontSize().normal,ui.Colors().white)
                labels[2] = ui.CreateLabel("&",ui.FontSize().normal,ui.Colors().lightGrey)
                labels[3] = ui.CreateLabel(couple[2],ui.FontSize().normal,ui.Colors().white)
                for i=1,#labels do
                    labels[i].style.marginLeft = StyleLength.new(Length.new( (i == 1 and 7 or 4)))
                    if(i~=2) then labels[i]:AddToClassList("DontOverflow") end
                    labels[i]:AddToClassList("LeftTextAlign")
                    playerVe:Add(labels[i])
                end
            else
                local nameLabel = ui.CreateLabel(data[i].name,ui.FontSize().normal,ui.Colors().white)
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
            local scoreLabel = ui.CreateLabel(data[i].score,ui.FontSize().normal,ui.Colors().white)
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
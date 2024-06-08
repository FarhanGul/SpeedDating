--!Type(UI)

local common = require("Common")

--!Bind
local root : VisualElement = nil

-- Configuration
local FontSize = {
    normal = 0.08,
    heading = 0.1
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
local chatPanel : VisualElement
local gamePanel : VisualElement

-- Functions
function self:ClientAwake()
    common.SubscribeEvent(common.ELocalPlayerOccupiedSeat(),ShowSittingAlone)
    common.SubscribeEvent(common.EBeginDate(),ShowDialgoueGameIntro)
    common.SubscribeEvent(common.EPrivateMessageSent(),HandlePrivateMessage)
    common.SubscribeEvent(common.ETurnStarted(),ShowGameTurn)
    common.SubscribeEvent(common.EPlayerReceivedQuestionFromServer(),ShowQuestionReceived)
    -- ShowHome()
    ShowScrollViewTest()
end

function ShowSittingAlone()
    if(chatPanel ~= nil) then return end
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
    root:Clear()
    local mainPanel = VisualElement.new()
    SetRelativeSize(mainPanel, 100, 100)
    gamePanel = VisualElement.new()
    SetRelativeSize(gamePanel, 100, 50)
    gamePanel.style.backgroundColor = StyleColor.new(Colors.white)
    gamePanel:Add(CreateLabel("Game View",FontSize.heading,Colors.black))
    chatPanel = VisualElement.new()
    SetRelativeSize(chatPanel, 100, 50)
    chatPanel.style.backgroundColor = StyleColor.new(Colors.grey)
    mainPanel:Add(gamePanel)
    mainPanel:Add(chatPanel)
    root:Add(mainPanel)
end

function ShowQuestionReceived(args)
    print("UI received question "..args[1])
    gamePanel:Clear()
    gamePanel:Add(CreateLabel("It is your turn to answer",FontSize.heading,Colors.black))
    gamePanel:Add(CreateLabel(args[1],FontSize.normal,Colors.lightGrey))
end

function ShowGameTurn(args)
    if(gamePanel == nil) then ShowDialgoueGame() end
    gamePanel:Clear()
    if(args[1])then
        gamePanel:Add(CreateLabel("It is your turn to ask a question",FontSize.heading,Colors.black))
        for i = 1, #args[2] do
            gamePanel:Add(CreateButton(args[2][i], function()
                common.InvokeEvent(common.ELocalPlayerSelectedQuestion(),args[2][i])
            end))
        end
    else
        gamePanel:Add(CreateLabel("Your partner is thinking of a question please wait",FontSize.heading,Colors.black))
    end
end

function ShowDialgoueGameIntro(args)
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(CreateLabel("You are dating "..args[2].name),FontSize.normal,Colors.black)
    SetRelativeSize(panel, 100, 100)
    root:Add(panel)
end

function HandlePrivateMessage(args)
    if(chatPanel ~= nil) then
        chatPanel:Add(CreateChatMessage(args[1], args[2]))
    end
end

function CreateChatMessage(player,message)
    local panel = VisualElement.new()
    panel.style.backgroundColor = player == client.localPlayer and StyleColor.new(Colors.white) or StyleColor.new(Colors.black)
    panel:Add(CreateLabel(message, FontSize.normal,player == client.localPlayer and StyleColor.new(Colors.black) or StyleColor.new(Colors.white)))
    SetMargin(panel, 0.02)
    return panel
end

function ShowScrollViewTest()
    root:Clear()
    local panel = VisualElement.new()
    local scrollView = UIScrollView.new()
    scrollView.style.height = StyleLength.new(Length.new(500))
    scrollView.style.width = StyleLength.new(Length.new(500))
    for i = 1, 100 do
        scrollView:Add(CreateLabel(i.." A quick brown fox jumped over a lazy dog", FontSize.normal,Colors.blue))
    end
    scrollView.contentContainer:AddToClassList("test")
    panel:Add(scrollView)
    root:Add(panel)
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
    local panel = VisualElement.new()
    panel:Add(CreateLabel("Ranking",FontSize.heading))
    panel:Add(CreateButton("Close", function()
        root:Clear()
        ShowHome()
    end))
    root:Add(panel)
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
    ve.style.width = StyleLength.new(Length.Percent(w))
    ve.style.height = StyleLength.new(Length.Percent(h))
end
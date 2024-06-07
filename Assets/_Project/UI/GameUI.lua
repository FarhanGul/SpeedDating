--!Type(UI)

local common = require("Common")

--!Bind
local root : VisualElement = nil

-- Configuration
local FontSize = {
    normal = 0.05,
    heading = 0.07
}

local Colors = {
    grey = Color.new(62/255, 67/255, 71/255),
    darkGrey = Color.new(45/255, 45/255, 45/255),
    white = Color.white,
    black = Color.black,
    red = Color.new(1, 115/255, 141/255),
    blue = Color.new(115/255, 185/255, 1),
}

-- Private
local chatPanel

-- Functions
function self:ClientAwake()
    common.SubscribeEvent(common.ELocalPlayerOccupiedSeat(),ShowSittingAlone)
    common.SubscribeEvent(common.EBeginDate(),ShowDate)
    common.SubscribeEvent(common.EPrivateMessageSent(),HandlePrivateMessage)
    ShowHome()
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

function ShowDate(args)
    root:Clear()
    local mainPanel = VisualElement.new()
    mainPanel.style.height = StyleLength.new(Length.Percent(100))
    mainPanel.style.width = StyleLength.new(Length.Percent(100))
    local gamePanel = VisualElement.new()
    gamePanel.style.height = StyleLength.new(Length.Percent(50))
    gamePanel.style.width = StyleLength.new(Length.Percent(100))
    gamePanel.style.backgroundColor = StyleColor.new(Colors.white)
    gamePanel:Add(CreateLabel("Game View",FontSize.heading,Colors.black))
    chatPanel = VisualElement.new()
    chatPanel.style.height = StyleLength.new(Length.Percent(50))
    chatPanel.style.width = StyleLength.new(Length.Percent(100))
    chatPanel.style.backgroundColor = StyleColor.new(Colors.grey)
    mainPanel:Add(gamePanel)
    mainPanel:Add(chatPanel)
    root:Add(mainPanel)
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
    scrollView.style.width = StyleLength.new(Length.Percent(500))
    for i = 1, 100 do
        scrollView.contentContainer:Add(CreateChatMessage(client.localPlayer,i.." - A quick brown fox jumped over a lazy dog"))
    end
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
    local fontSize = args[2]
    local color = args[3]
    local label = UILabel.new()
    label:SetPrelocalizedText(text, false)
    label.style.color = StyleColor.new(color == nil and Colors.white or color)
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
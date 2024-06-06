--!Type(UI)

local common = require("Common")

--!Bind
local root : VisualElement = nil

local FontSize = {
    normal = 0.05,
    heading = 0.07
}

function self:ClientAwake()
    common.SubscribeEvent(common.ELocalPlayerOccupiedSeat(),ShowSittingAlone)
    common.SubscribeEvent(common.EBeginDate(),function(args) print("Date Begin : "..args[1].name.." - "..args[2].name) end)
    ShowHome()
end

function ShowSittingAlone()
    root:Clear()
    local panel = VisualElement.new()
    panel:Add(CreateLabel("Please wait for a partner to join you at the table",FontSize.heading))
    panel:Add(CreateButton("Leave", function()
        ShowHome()
        common.InvokeEvent(common.ELocalPlayerLeftSeat())
    end))
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

function CreateLabel(text,fontSize)
    local label = UILabel.new()
    label:SetPrelocalizedText(text, false)
    label.style.color = StyleColor.new(Color.white)
    label.style.fontSize = StyleLength.new(Length.new(fontSize*Screen.dpi))
    return label
end

function CreateButton(text,onPressed)
    local button = UIButton.new()
    button:Add(CreateLabel(text,FontSize.normal)) 
    button:RegisterPressCallback(onPressed)
    return button
end
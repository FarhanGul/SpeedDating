--!Type(UI)

-- Imports
local common = require("Common")
local ui = require("UILibrary")

--!Bind
local root : VisualElement = nil

-- Functions
function self:Update()
    self.transform.parent:LookAt(Camera.main.transform.position)
end

function SetStatus(datingStatus)
    root:Clear()
    local text = ""
    if(datingStatus == common.NDatingStatusFree()) then text = "Single"
    elseif(datingStatus == common.NDatingStatusMatchmaking()) then text = "Matchmaking"
    elseif(datingStatus == common.NDatingStatusDating()) then text = "Dating"
    end
    root:Add(ui.CreateLabel(text,ui.FontSize().heading,ui.Colors().white))
end
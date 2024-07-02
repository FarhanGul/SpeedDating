--!Type(UI)

-- Imports
local common = require("Common")

--!Bind
local root : VisualElement = nil

-- Functions
function self:ClientAwake()
    common.SubscribeEvent(common.EUpdatePlayerDatingStatus(),function(datingStatus)
        root:Clear()
    end)
end
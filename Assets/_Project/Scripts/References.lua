--!Type(Module)

--!SerializeField
local gameUIGameObject : GameObject = nil
--!SerializeField
local seatManagerGameObject : GameObject = nil

local gameUI
local seatManager

function self:ClientAwake()
    gameUI = gameUIGameObject:GetComponent("GameUI")
    seatManager = seatManagerGameObject:GetComponent("SeatManager")
end

function GameUI()
    return gameUI
end

function SeatManager()
    return seatManager
end

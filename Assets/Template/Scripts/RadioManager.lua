--!SerializeField
local DanceFloor : GameObject = nil
local lowFrequency : number = 60
local highFrequency : number = 500
local amplitude : number = 10

function self:Start()
    Audio:PlayMusicURL("https://streamssl.chilltrax.com:80/", 1)
end
--[[
function self:Update()
    if not Audio.isPlaying then
        return
    end
    str = Audio:GetMusicIntensity(lowFrequency, highFrequency, false) * amplitude
    print(tostring(str))
    local DanceRend = DanceFloor:GetComponent(Renderer)
    DanceRend.material:SetFloat("_strength", str)
end
--]]
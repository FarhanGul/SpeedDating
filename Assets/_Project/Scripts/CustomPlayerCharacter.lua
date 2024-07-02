--!Type(ClientAndServer)

local character : Character

function self:ClientAwake()
    character = self.gameObject:GetComponent(Character)
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        print(character.player.name.." Tapped")
    end)
end
--!Type(Client)

local contact

function self:ClientAwake()
    contact = self.transform:Find("Contact")
    self.gameObject:GetComponent(TapHandler).Tapped:Connect(function()
        client.localPlayer.character.usePathfinding = false
        client.localPlayer.character:Teleport(contact.position, function()end)
        client.localPlayer.character:PlayEmote("sit-idle", true, function()end)
        client.localPlayer.character.transform.rotation = contact.rotation
    end)
end
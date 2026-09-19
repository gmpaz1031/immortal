local datastoreservice = game:GetService("DataStoreService")

game.Players.PlayerAdded:Connect(function(plr)
	local lb = Instance.new("Folder", plr)
	lb.Name = "leaderstats"
	local qi = Instance.new("IntValue")
end)
game.Players.PlayerRemoving:Connect(function(plr)
	
end)
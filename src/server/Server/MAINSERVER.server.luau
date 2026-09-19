local rp = game:GetService("ReplicatedStorage")
local rem = rp.Remotes.MAIN

local CDS = {}

rem.OnServerEvent:Connect(function(player, tableargs)
	if tableargs then
		if tableargs[1] == "Cultivate" then
			if CDS[player.UserId] == nil then
				CDS[player.UserId] = true
				delay(0.5, function()
					CDS[player.UserId] = false
				end)
				
				
			end
		end
	end
end)
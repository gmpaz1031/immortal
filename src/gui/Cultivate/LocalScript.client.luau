local uis = game:GetService("UserInputService")
local rp = game:GetService("ReplicatedStorage")
local rs = game:GetService("RunService")

local cd = false
local plr = game.Players.LocalPlayer
local cultivate = false

uis.InputBegan:Connect(function(Key, Processed)
	if Processed then return end
	
	if Key.KeyCode == Enum.KeyCode.C then
		if cultivate == true then
			cultivate = false
		else
			if cd == false then
				cd = true
				cultivate = true
				delay(0.5, function()
					cd = false
				end)
			end
		end
	end
end)

rs.RenderStepped:Connect(function()
	if cultivate == true then
		script.Parent.FireEffect.Visible = true
	else
		script.Parent.FireEffect.Visible = false
	end
	task.wait(0.1)
end)
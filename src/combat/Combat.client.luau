local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local tool = script.Parent
local remote = ReplicatedStorage:WaitForChild("CultivationRemote")
local cooldown = false

local function playPunchAnimation()
	local character = player.Character
	local shoulder = character and character:FindFirstChild("RightShoulder", true)
	if not shoulder or not shoulder:IsA("Motor6D") then
		return
	end

	local original = shoulder.Transform
	shoulder.Transform = CFrame.Angles(math.rad(-75), 0, math.rad(20))
	task.delay(0.1, function()
		if shoulder.Parent then
			shoulder.Transform = CFrame.Angles(math.rad(20), 0, math.rad(-8))
		end
	end)
	task.delay(0.2, function()
		if shoulder.Parent then
			shoulder.Transform = original
		end
	end)
end

tool.Activated:Connect(function()
	if cooldown or tool.Parent ~= player.Character or player:GetAttribute("Cultivating") then
		return
	end

	cooldown = true
	playPunchAnimation()
	remote:FireServer("Punch")
	task.delay(0.45, function()
		cooldown = false
	end)
end)

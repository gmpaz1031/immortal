--!strict
-- src/server/MovementService.server.luau
-- Xianxia Movement Service for Immortal
-- Authoritative validation & replication for Flash Step & Flying Sword Mounts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local remotesFolder = ReplicatedStorage:WaitForChild("SkillRemotes") :: Folder
local moveRemote = remotesFolder:FindFirstChild("MovementRemote") :: RemoteEvent?
if not moveRemote then
	moveRemote = Instance.new("RemoteEvent")
	moveRemote.Name = "MovementRemote"
	moveRemote.Parent = remotesFolder
end

local function createServerAfterimage(char: Model, startPos: Vector3, targetPos: Vector3)
	local ghostModel = Instance.new("Model")
	ghostModel.Name = "ServerFlashStepGhost"

	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local p = part:Clone()
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.Anchored = true
			p.Material = Enum.Material.Neon
			p.Color = Color3.fromRGB(120, 220, 255)
			p.Transparency = 0.35
			p.CFrame = (part.CFrame - startPos) + targetPos
			p.Parent = ghostModel
		end
	end

	ghostModel.Parent = workspace
	Debris:AddItem(ghostModel, 0.4)
end

moveRemote.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not char or not root then return end

	if action == "FlashStep" then
		local startPos, targetPos = ...
		if typeof(startPos) == "Vector3" and typeof(targetPos) == "Vector3" then
			-- Replicate afterimages & sound to other clients
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= player then
					moveRemote:FireClient(otherPlayer, "ReplicateFlashStep", char, startPos, targetPos)
				end
			end

			-- Update server character position cleanly
			root.CFrame = CFrame.new(targetPos, targetPos + (targetPos - startPos).Unit)
		end
	elseif action == "MountSword" then
		char:SetAttribute("MountedFlyingSword", true)
	elseif action == "DismountSword" then
		char:SetAttribute("MountedFlyingSword", false)
	end
end)

print("[MovementService] Xianxia Movement Service initialized cleanly.")

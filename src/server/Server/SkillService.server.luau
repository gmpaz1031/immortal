--!strict
-- src/server/SkillService.server.luau
-- Martial Arts & Spiritual Combat Service
-- Manages skill validation, Qi costs, spatial hitboxes, damage, and VFX replication.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SkillConfig = require(Shared:WaitForChild("SkillConfig"))

local damageServiceModule = script.Parent:FindFirstChild("DamageService")
local DamageService = if damageServiceModule and damageServiceModule:IsA("ModuleScript") then require(damageServiceModule) :: any else nil

local function dealDamage(hum: Humanoid, amount: number, player: Player?, skillName: string?)
	if DamageService then
		DamageService.applyDamage(hum, amount, player, skillName)
	else
		hum:TakeDamage(amount)
	end
end

local remotesFolder = ReplicatedStorage:WaitForChild("SkillRemotes") :: Folder
local skillRequestRemote = remotesFolder:WaitForChild("SkillRequest") :: RemoteEvent
local skillReplicateRemote = remotesFolder:WaitForChild("SkillReplicate") :: RemoteEvent
local skillEquipReqRemote = remotesFolder:WaitForChild("SkillEquipRequest") :: RemoteEvent
local skillDataUpdateRemote = remotesFolder:WaitForChild("SkillDataUpdate") :: RemoteEvent

local aiTestRemote = remotesFolder:FindFirstChild("AITestEvent") :: RemoteEvent?
if not aiTestRemote then
	aiTestRemote = Instance.new("RemoteEvent")
	aiTestRemote.Name = "AITestEvent"
	aiTestRemote.Parent = remotesFolder
end

-- Player Cooldowns map: userId -> { [skillName]: nextAllowedTime }
local playerCooldowns: { [number]: { [string]: number } } = {}
local playerSlots: { [number]: { [number]: string } } = {}

local function getHitTargetsInRadius(origin: Vector3, radius: number, excludeChar: Model?): { Humanoid }
	local hitHumanoids: { [Humanoid]: boolean } = {}
	local results: { Humanoid } = {}

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if excludeChar then
		params.FilterDescendantsInstances = { excludeChar }
	end

	local parts = Workspace:GetPartBoundsInRadius(origin, radius, params)
	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not hitHumanoids[hum] and model ~= excludeChar then
			hitHumanoids[hum] = true
			table.insert(results, hum)
		end
	end

	return results
end

local function applyStun(hum: Humanoid, duration: number)
	if not hum or not hum.Parent or hum.Health <= 0 then return end

	local origSpeed = hum:GetAttribute("OriginalWalkSpeed")
	if not origSpeed then
		local curSpeed = hum.WalkSpeed
		origSpeed = if curSpeed > 0 then curSpeed else 16
		hum:SetAttribute("OriginalWalkSpeed", origSpeed)
	end
	local origJump = hum:GetAttribute("OriginalJumpPower")
	if not origJump then
		local curJump = hum.JumpPower
		origJump = if curJump > 0 then curJump else 50
		hum:SetAttribute("OriginalJumpPower", origJump)
	end

	local stunCount = (hum:GetAttribute("StunCount") or 0) + 1
	hum:SetAttribute("StunCount", stunCount)
	hum.WalkSpeed = 0
	hum.JumpPower = 0

	local statusLabel = hum.Parent and hum.Parent:FindFirstChild("DummyStatusTag", true) :: TextLabel?
	if statusLabel then
		statusLabel.Text = string.format("STATUS: STUNNED (%.1fs)", duration)
		statusLabel.TextColor3 = Color3.fromRGB(220, 160, 255)
	end

	task.delay(duration, function()
		if hum and hum.Parent then
			local remaining = (hum:GetAttribute("StunCount") or 1) - 1
			hum:SetAttribute("StunCount", math.max(0, remaining))
			if remaining <= 0 then
				local restoreSpeed = hum:GetAttribute("OriginalWalkSpeed") or 16
				local restoreJump = hum:GetAttribute("OriginalJumpPower") or 50
				local player = Players:GetPlayerFromCharacter(hum.Parent)
				if not player or not player:GetAttribute("Cultivating") then
					hum.WalkSpeed = restoreSpeed
					hum.JumpPower = restoreJump
				end
				hum:SetAttribute("OriginalWalkSpeed", nil)
				hum:SetAttribute("OriginalJumpPower", nil)

				if statusLabel and statusLabel.Parent then
					statusLabel.Text = "STATUS: ACTIVE"
					statusLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
				end
			end
		end
	end)
end

skillRequestRemote.OnServerEvent:Connect(function(player: Player, skillName: string, targetData: any)
	local skillDef = SkillConfig.Skills[skillName]
	if not skillDef then return end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	-- Check Cooldown
	local userId = player.UserId
	if not playerCooldowns[userId] then
		playerCooldowns[userId] = {}
	end

	local now = os.clock()
	if playerCooldowns[userId][skillName] and now < playerCooldowns[userId][skillName] then
		return
	end

	-- Check Qi Cost
	local leaderstats = player:FindFirstChild("leaderstats")
	local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
	if not qiVal or qiVal.Value < skillDef.QiCost then
		return
	end

	-- Deduct Qi & Record Cooldown
	qiVal.Value = qiVal.Value - skillDef.QiCost
	playerCooldowns[userId][skillName] = now + skillDef.Cooldown

	-- Calculate total damage with player Damage attribute
	local bonusDmg = player:GetAttribute("Damage") or 15
	local totalDamage = skillDef.Damage + math.floor(bonusDmg * 0.5)

	local origin = root.Position
	local hitPos: Vector3
	if targetData and typeof(targetData) == "table" and typeof(targetData.HitPosition) == "Vector3" then
		hitPos = targetData.HitPosition
	else
		hitPos = origin + root.CFrame.LookVector * 30
	end
	local lookDir = (hitPos - origin)
	if lookDir.Magnitude < 0.01 then
		lookDir = root.CFrame.LookVector
	else
		lookDir = lookDir.Unit
	end

	print(string.format("[SkillService] %s fired %s at position (%.1f, %.1f, %.1f)", player.Name, skillName, hitPos.X, hitPos.Y, hitPos.Z))

	-- Execute Skill Action & Spatial Hitboxes
	if skillName == "Sword Slash" then
		skillReplicateRemote:FireAllClients("SwordSlash", char, origin + Vector3.new(0, 1.5, 0), lookDir, skillDef.Range, skillDef.Speed or 75)
		-- Check cone/line hitbox
		task.delay(0.15, function()
			local center = origin + (lookDir * (skillDef.Range * 0.5))
			local victims = getHitTargetsInRadius(center, 12, char)
			for _, hum in ipairs(victims) do
				dealDamage(hum, totalDamage, player, "Sword Slash")
			end
		end)

	elseif skillName == "Flame Ball" then
		skillReplicateRemote:FireAllClients("FlameBall", char, origin + Vector3.new(0, 2, 0), hitPos, skillDef.Speed or 65, skillDef.Radius or 12)
		local dist = (hitPos - origin).Magnitude
		local travelTime = dist / (skillDef.Speed or 65)
		task.delay(travelTime, function()
			local victims = getHitTargetsInRadius(hitPos, skillDef.Radius or 12, char)
			for _, hum in ipairs(victims) do
				dealDamage(hum, totalDamage, player, "Flame Ball")
			end
		end)

	elseif skillName == "Palm Art" then
		local speed = skillDef.Speed or 55
		local radius = skillDef.Radius or 14
		local maxDuration = 4.0

		skillReplicateRemote:FireAllClients("PalmArt", char, origin, lookDir, hitPos, speed, radius)

		-- Server-side authoritative projectile travel & contact detection
		task.spawn(function()
			local spawnPos = origin + (lookDir * 4) + Vector3.new(0, 1.5, 0)

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = { char }

			-- Y ground clearance check on cast
			local groundRay = workspace:Raycast(spawnPos + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0), rayParams)
			if groundRay then
				local minY = groundRay.Position.Y + 3.0
				if spawnPos.Y < minY then
					spawnPos = Vector3.new(spawnPos.X, minY, spawnPos.Z)
				end
			end

			local startTime = os.clock()
			local currentPos = spawnPos

			while (os.clock() - startTime) < maxDuration do
				local dt = task.wait(0.03)
				local stepDist = speed * dt
				local hitRay = workspace:Raycast(currentPos, lookDir * (stepDist + 0.6), rayParams)
				local impactPos: Vector3? = if hitRay then hitRay.Position else nil

				if not impactPos then
					local overlapParams = OverlapParams.new()
					overlapParams.FilterType = Enum.RaycastFilterType.Exclude
					overlapParams.FilterDescendantsInstances = { char }
					local parts = workspace:GetPartBoundsInRadius(currentPos, 3.0, overlapParams)
					for _, part in ipairs(parts) do
						if part.Name ~= "Terrain" then
							local model = part:FindFirstAncestorOfClass("Model")
							if model and model:FindFirstChildOfClass("Humanoid") then
								impactPos = part.Position
								break
							end
						end
					end
				end

				if impactPos then
					-- Trigger client-side explosion FX sync
					skillReplicateRemote:FireAllClients("PalmExplosion", impactPos, radius)

					local victims = getHitTargetsInRadius(impactPos, radius, char)
					for _, hum in ipairs(victims) do
						dealDamage(hum, totalDamage, player, "Palm Art")
						local hRoot = hum.Parent and hum.Parent:FindFirstChild("HumanoidRootPart") :: BasePart?
						if hRoot then
							local offset = hRoot.Position - impactPos
							local knockDir = if offset.Magnitude > 0.1 then offset.Unit else lookDir
							local horizontalDir = Vector3.new(knockDir.X, 0, knockDir.Z)
							if horizontalDir.Magnitude > 0.01 then
								horizontalDir = horizontalDir.Unit
							else
								local flatLook = Vector3.new(lookDir.X, 0, lookDir.Z)
								horizontalDir = if flatLook.Magnitude > 0.01 then flatLook.Unit else Vector3.new(0, 0, -1)
							end

							-- Ground check downward to keep impulse surface-clamped (Rule 5)
							local downRay = workspace:Raycast(hRoot.Position + Vector3.new(0, 2, 0), Vector3.new(0, -10, 0))
							local yImpulse = 0
							if downRay and (hRoot.Position.Y - downRay.Position.Y) < 3.5 then
								yImpulse = 40
							end
							hRoot:ApplyImpulse(horizontalDir * 1600 + Vector3.new(0, yImpulse, 0))
						end
					end
					return
				end
				currentPos = currentPos + (lookDir * stepDist)
			end
		end)

	elseif skillName == "Thunder Strike" then
		local warningTime = 0.6
		skillReplicateRemote:FireAllClients("ThunderStrike", hitPos, skillDef.Radius or 16, warningTime)
		task.delay(warningTime, function()
			local victims = getHitTargetsInRadius(hitPos, skillDef.Radius or 16, char)
			for _, hum in ipairs(victims) do
				dealDamage(hum, totalDamage, player, "Thunder Strike")
				local victimModel = hum.Parent
				if victimModel and victimModel:IsA("Model") then
					-- Initial strike stun (1.2s) and zap effect attachment
					applyStun(hum, 1.2)
					skillReplicateRemote:FireAllClients("ZapEffect", victimModel, 6.5)

					-- Periodic Zap Task: pulses every 2 seconds until the 3rd zap (3 ticks total)
					task.spawn(function()
						for zapIndex = 1, 3 do
							task.wait(2.0)
							if hum and hum.Parent and hum.Health > 0 then
								local statusLabel = hum.Parent:FindFirstChild("DummyStatusTag", true) :: TextLabel?
								if statusLabel then
									statusLabel.Text = string.format("STATUS: ZAP PULSE %d/3 (STUNNED)", zapIndex)
									statusLabel.TextColor3 = Color3.fromRGB(160, 210, 255)
								end
								local zapDamage = math.max(10, math.floor(totalDamage * 0.22))
								dealDamage(hum, zapDamage, player, "Thunder Strike (Zap)")
								applyStun(hum, 1.2)
								skillReplicateRemote:FireAllClients("ZapPulse", victimModel)
							else
								break
							end
						end
					end)
				end
			end
		end)

	elseif skillName == "Multiple Swords" then
		skillReplicateRemote:FireAllClients("MultipleSwords", char, origin, hitPos, skillDef.Count or 5, skillDef.Speed or 80)
		for i = 1, (skillDef.Count or 5) do
			task.delay(i * 0.15, function()
				local victims = getHitTargetsInRadius(hitPos, 8, char)
				for _, hum in ipairs(victims) do
					dealDamage(hum, math.floor(totalDamage / 4), player, "Multiple Swords")
				end
			end)
		end

	elseif skillName == "Flame Spear" then
		local targetModel = targetData and targetData.TargetModel
		skillReplicateRemote:FireAllClients("FlameSpear", char, origin, targetModel, hitPos, skillDef.Speed or 90)
		task.delay(0.2, function()
			local victims = getHitTargetsInRadius(hitPos, 10, char)
			for _, hum in ipairs(victims) do
				dealDamage(hum, totalDamage, player, "Flame Spear")
			end
		end)
	end
end)

local function initPlayerSlots(player: Player)
	local userId = player.UserId
	local slots = {}
	for i = 1, 4 do
		local attrName = "SkillSlot" .. i
		local savedSkill = player:GetAttribute(attrName)
		if typeof(savedSkill) == "string" and SkillConfig.Skills[savedSkill] then
			slots[i] = savedSkill
		else
			slots[i] = SkillConfig.DefaultSlots[i] or "Sword Slash"
			player:SetAttribute(attrName, slots[i])
		end
	end
	playerSlots[userId] = slots
	skillDataUpdateRemote:FireClient(player, "SyncSlots", slots)
end

Players.PlayerAdded:Connect(function(player)
	task.delay(0.2, function()
		if player.Parent then
			initPlayerSlots(player)
		end
	end)
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(initPlayerSlots, p)
end

skillEquipReqRemote.OnServerEvent:Connect(function(player: Player, action: string, slotIdx: number, skillName: string)
	if action == "EquipSlot" and slotIdx >= 1 and slotIdx <= 4 then
		if not SkillConfig.Skills[skillName] then return end
		local userId = player.UserId
		if not playerSlots[userId] then
			playerSlots[userId] = table.clone(SkillConfig.DefaultSlots)
		end
		playerSlots[userId][slotIdx] = skillName
		player:SetAttribute("SkillSlot" .. slotIdx, skillName)
		skillDataUpdateRemote:FireClient(player, "SyncSlots", playerSlots[userId])
		print(string.format("[SkillService] %s equipped %s into Slot %d", player.Name, skillName, slotIdx))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
	playerSlots[player.UserId] = nil
end)

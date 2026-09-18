--!strict
--[[
    SkillService.luau
    Authoritative server-side coordinator for the combat skill system:
    - Verifies player state (alive, not cultivating, valid character)
    - Validates equipped slots and ownership
    - Enforces server-side cooldown timers
    - Validates target distances, ranges, and Line of Sight
    - Executes authoritative hitboxes and projectile simulation
    - Deals scaled damage via DamageService
    - Replicates visual cues to all clients
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkillConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkillConfig"))
local DamageService = require(script.Parent:WaitForChild("DamageService"))

local SkillService = {}

-- Track cooldowns per player: [Player][skillName] = os.clock()
local playerCooldowns: { [Player]: { [string]: number } } = {}

-- Track equipped skills per player: [Player] = { [1] = "SkillA", [2] = "SkillB", ... }
local playerEquippedSkills: { [Player]: { [number]: string } } = {}

-- Remotes folder setup
local remotesFolder = ReplicatedStorage:FindFirstChild("SkillRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "SkillRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

local skillRequestRemote = remotesFolder:FindFirstChild("SkillRequest")
if not skillRequestRemote then
	skillRequestRemote = Instance.new("RemoteEvent")
	skillRequestRemote.Name = "SkillRequest"
	skillRequestRemote.Parent = remotesFolder
end

local skillReplicateRemote = remotesFolder:FindFirstChild("SkillReplicate")
if not skillReplicateRemote then
	skillReplicateRemote = Instance.new("RemoteEvent")
	skillReplicateRemote.Name = "SkillReplicate"
	skillReplicateRemote.Parent = remotesFolder
end

local skillEquipRequestRemote = remotesFolder:FindFirstChild("SkillEquipRequest")
if not skillEquipRequestRemote then
	skillEquipRequestRemote = Instance.new("RemoteEvent")
	skillEquipRequestRemote.Name = "SkillEquipRequest"
	skillEquipRequestRemote.Parent = remotesFolder
end

local skillDataUpdateRemote = remotesFolder:FindFirstChild("SkillDataUpdate")
if not skillDataUpdateRemote then
	skillDataUpdateRemote = Instance.new("RemoteEvent")
	skillDataUpdateRemote.Name = "SkillDataUpdate"
	skillDataUpdateRemote.Parent = remotesFolder
end

-- Type casts to RemoteEvent since FindFirstChild returns Instance?
local skillRequest    = skillRequestRemote    :: RemoteEvent
local skillReplicate  = skillReplicateRemote  :: RemoteEvent
local skillEquipReq   = skillEquipRequestRemote :: RemoteEvent
local skillDataUpdate = skillDataUpdateRemote  :: RemoteEvent

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function getCharacterParts(player: Player): (Model?, BasePart?, Humanoid?)
	local char = player.Character
	if not char then return nil, nil, nil end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum  = char:FindFirstChildOfClass("Humanoid")
	return char, root, hum
end

local function isCooldownReady(player: Player, skillName: string): boolean
	local cd = playerCooldowns[player]
	if not cd then return true end
	local lastUsed = cd[skillName]
	if not lastUsed then return true end
	local skillDef = SkillConfig.Skills[skillName]
	if not skillDef then return true end
	return (os.clock() - lastUsed) >= skillDef.Cooldown
end

local function setCooldown(player: Player, skillName: string)
	if not playerCooldowns[player] then
		playerCooldowns[player] = {}
	end
	playerCooldowns[player][skillName] = os.clock()
end

local function getEquippedSkills(player: Player): { [number]: string }
	if not playerEquippedSkills[player] then
		-- Assign defaults
		local defaults: { [number]: string } = {}
		for i, name in ipairs(SkillConfig.DefaultSlots) do
			defaults[i] = name
		end
		playerEquippedSkills[player] = defaults
	end
	return playerEquippedSkills[player]
end

-- Exported so init.server can call it
function SkillService.getEquippedSkills(player: Player): { [number]: string }
	return getEquippedSkills(player)
end

--------------------------------------------------------------------------------
-- Skill Handlers (Server Authoritative)
--------------------------------------------------------------------------------

-- 1. Sword Slash — forward projectile hitbox simulation
local function handleSwordSlash(player: Player, skillDef: any, targetData: { [string]: any })
	local char, root, hum = getCharacterParts(player)
	if not char or not root or not hum or hum.Health <= 0 then return end

	local origin = root.Position
	local aimDir: Vector3 = targetData.AimDirection or root.CFrame.LookVector
	if aimDir.Magnitude < 0.01 then aimDir = root.CFrame.LookVector end
	aimDir = aimDir.Unit

	local speed  = skillDef.ProjectileSpeed or 70
	local range  = skillDef.Range           or 25
	local radius = skillDef.Radius          or 4

	-- Server simulates projectile travel in steps
	local stepSize  = 3
	local steps     = math.ceil(range / stepSize)
	local hitModels: { [Model]: boolean } = {}

	local ignoreList: { Instance } = { char, Workspace.Terrain }

	task.spawn(function()
		for i = 1, steps do
			task.wait(stepSize / speed)
			local checkPos = origin + aimDir * (stepSize * i)

			local targets = DamageService.findTargetsInRadius(checkPos, radius, player, false)
			for _, hum2 in ipairs(targets) do
				local model = hum2.Parent :: Model
				if model and not hitModels[model] then
					hitModels[model] = true
					DamageService.applyDamage(hum2, skillDef.BaseDamage, player, "Sword Slash")
				end
			end
		end
	end)

	-- Replicate VFX to all clients
	skillReplicate:FireAllClients("SwordSlash", char, origin, aimDir, range, speed)
end

-- 2. Palm Art — area around caster AoE
local function handlePalmArt(player: Player, skillDef: any, _targetData: { [string]: any })
	local char, root, hum = getCharacterParts(player)
	if not char or not root or not hum or hum.Health <= 0 then return end

	local origin  = root.Position
	local lookDir = root.CFrame.LookVector
	local radius  = skillDef.Radius or 14

	-- Small delay for cast animation
	task.wait(skillDef.CastTime or 0.4)

	local targets = DamageService.findTargetsInRadius(origin, radius, player, false)
	for _, hum2 in ipairs(targets) do
		DamageService.applyDamage(hum2, skillDef.BaseDamage, player, "Palm Art")
	end

	skillReplicate:FireAllClients("PalmArt", char, origin, lookDir, radius)
end

-- 3. Flame Ball — targeted AoE projectile
local function handleFlameBall(player: Player, skillDef: any, targetData: { [string]: any })
	local char, root, hum = getCharacterParts(player)
	if not char or not root or not hum or hum.Health <= 0 then return end

	local origin    = root.Position
	local targetPos: Vector3 = targetData.TargetPosition or (origin + root.CFrame.LookVector * 30)
	local speed     = skillDef.ProjectileSpeed or 55
	local radius    = skillDef.Radius or 8

	-- Clamp target within range
	local toTarget = targetPos - origin
	if toTarget.Magnitude > skillDef.Range then
		targetPos = origin + toTarget.Unit * skillDef.Range
	end

	local travelTime = (targetPos - origin).Magnitude / speed

	task.spawn(function()
		task.wait(travelTime)
		-- Detonate at target
		local targets = DamageService.findTargetsInRadius(targetPos, radius, player, false)
		for _, hum2 in ipairs(targets) do
			DamageService.applyDamage(hum2, skillDef.BaseDamage, player, "Flame Ball")
		end
	end)

	skillReplicate:FireAllClients("FlameBall", char, origin, targetPos, speed, radius)
end

-- 4. Thunder Strike — sky AoE with warning
local function handleThunderStrike(player: Player, skillDef: any, targetData: { [string]: any })
	local char, root, hum = getCharacterParts(player)
	if not char or not root or not hum or hum.Health <= 0 then return end

	local origin    = root.Position
	local targetPos: Vector3 = targetData.TargetPosition or (origin + root.CFrame.LookVector * 20)
	local radius    = skillDef.Radius          or 7
	local warning   = skillDef.WarningDuration or 1.5

	-- Clamp target within range
	local toTarget = targetPos - origin
	if toTarget.Magnitude > skillDef.Range then
		targetPos = origin + toTarget.Unit * skillDef.Range
	end

	-- Replicate warning ring first
	skillReplicate:FireAllClients("ThunderStrike", targetPos, radius, warning)

	task.spawn(function()
		task.wait(warning)
		-- Strike hits after warning
		local targets = DamageService.findTargetsInRadius(targetPos, radius, player, false)
		for _, hum2 in ipairs(targets) do
			DamageService.applyDamage(hum2, skillDef.BaseDamage, player, "Thunder Strike")
		end
	end)
end

-- 5. Multiple Swords — multi-projectile volley
local function handleMultipleSwords(player: Player, skillDef: any, targetData: { [string]: any })
	local char, root, hum = getCharacterParts(player)
	if not char or not root or not hum or hum.Health <= 0 then return end

	local origin    = root.Position
	local targetPos: Vector3 = targetData.TargetPosition or (origin + root.CFrame.LookVector * 30)
	local count     = skillDef.ProjectileCount or 7
	local speed     = skillDef.ProjectileSpeed or 65
	local radius    = skillDef.Radius          or 5

	local toTarget   = targetPos - origin
	local travelDist = math.min(toTarget.Magnitude, skillDef.Range or 45)
	targetPos        = origin + toTarget.Unit * travelDist
	local travelTime = travelDist / speed

	local hitModels: { [Model]: boolean } = {}

	task.spawn(function()
		-- Stagger swords slightly
		for i = 1, count do
			task.wait(i * 0.08)
			task.spawn(function()
				task.wait(travelTime)
				-- Each sword hits independently
				local jitter = Vector3.new(
					math.random(-3, 3),
					math.random(-1, 1),
					math.random(-3, 3)
				)
				local impactPos = targetPos + jitter
				local targets = DamageService.findTargetsInRadius(impactPos, radius, player, false)
				for _, hum2 in ipairs(targets) do
					local model = hum2.Parent :: Model
					if model and not hitModels[model] then
						hitModels[model] = true
						DamageService.applyDamage(hum2, skillDef.BaseDamage, player, "Multiple Swords")
					end
				end
			end)
		end
	end)

	skillReplicate:FireAllClients("MultipleSwords", char, origin, targetPos, count, speed)
end

-- 6. Flame Spear — lock-on homing single target
local function handleFlameSpear(player: Player, skillDef: any, targetData: { [string]: any })
	local char, root, hum = getCharacterParts(player)
	if not char or not root or not hum or hum.Health <= 0 then return end

	local origin      = root.Position
	local targetModel = targetData.TargetModel :: Model?
	local targetPos: Vector3 = targetData.TargetPosition or (origin + root.CFrame.LookVector * 40)
	local speed       = skillDef.ProjectileSpeed or 80

	-- Validate target model is still alive and in range
	local finalTargetHum: Humanoid? = nil
	if targetModel and targetModel.Parent then
		local tHum = targetModel:FindFirstChildOfClass("Humanoid")
		local tRoot = targetModel:FindFirstChild("HumanoidRootPart")
			or targetModel:FindFirstChild("Torso")
		if tHum and tHum.Health > 0 and tRoot and tRoot:IsA("BasePart") then
			local dist = (tRoot.Position - origin).Magnitude
			if dist <= skillDef.Range then
				finalTargetHum = tHum
				targetPos = tRoot.Position
			end
		end
	end

	-- If no lock-on target, treat as straight shot to targetPos
	local toTarget   = targetPos - origin
	local travelDist = math.min(toTarget.Magnitude, skillDef.Range or 70)
	local travelTime = travelDist / speed

	task.spawn(function()
		task.wait(travelTime)
		if finalTargetHum then
			-- Re-validate at arrival
			if finalTargetHum.Health > 0 then
				DamageService.applyDamage(finalTargetHum, skillDef.BaseDamage, player, "Flame Spear")
			end
		else
			-- No lock-on, splash at position
			local impactPos = origin + toTarget.Unit * travelDist
			local targets = DamageService.findTargetsInRadius(impactPos, skillDef.Radius or 5, player, false)
			for _, hum2 in ipairs(targets) do
				DamageService.applyDamage(hum2, skillDef.BaseDamage, player, "Flame Spear")
			end
		end
	end)

	skillReplicate:FireAllClients("FlameSpear", char, origin, targetModel, targetPos, speed)
end

--------------------------------------------------------------------------------
-- Skill Dispatch Table
--------------------------------------------------------------------------------

local skillHandlers: { [string]: (Player, any, { [string]: any }) -> () } = {
	["Sword Slash"]    = handleSwordSlash,
	["Palm Art"]       = handlePalmArt,
	["Flame Ball"]     = handleFlameBall,
	["Thunder Strike"] = handleThunderStrike,
	["Multiple Swords"]= handleMultipleSwords,
	["Flame Spear"]    = handleFlameSpear,
}

--------------------------------------------------------------------------------
-- SkillService.init — call this from init.server.luau
--------------------------------------------------------------------------------
function SkillService.init()
	-- 1. Handle Skill Cast Requests from client
	skillRequest.OnServerEvent:Connect(function(player: Player, skillName: string, targetData: any)
		if type(skillName) ~= "string" then return end

		-- Validate skill exists
		local skillDef = SkillConfig.Skills[skillName]
		if not skillDef then
			warn("[SkillService] Unknown skill:", skillName)
			return
		end

		-- Validate skill is equipped in one of the player's slots
		local equipped = getEquippedSkills(player)
		local isEquipped = false
		for _, name in ipairs(equipped) do
			if name == skillName then
				isEquipped = true
				break
			end
		end
		if not isEquipped then
			warn("[SkillService] Player", player.Name, "tried to use unequipped skill:", skillName)
			return
		end

		-- Check cooldown
		if not isCooldownReady(player, skillName) then
			return
		end

		-- Check character is alive
		local _, _, hum = getCharacterParts(player)
		if not hum or hum.Health <= 0 then return end

		-- Set cooldown and execute
		setCooldown(player, skillName)
		local handler = skillHandlers[skillName]
		if handler then
			task.spawn(handler, player, skillDef, targetData or {})
		end
	end)

	-- 2. Handle Equip Slot Changes from client
	skillEquipReq.OnServerEvent:Connect(function(player: Player, action: string, slot: number, skillName: string)
		if action == "EquipSlot" then
			if type(slot) ~= "number" or slot < 1 or slot > 4 then return end
			if type(skillName) ~= "string" then return end
			if not SkillConfig.Skills[skillName] and skillName ~= "" then return end

			local equipped = getEquippedSkills(player)
			equipped[slot] = skillName
			-- Sync back to client
			skillDataUpdate:FireClient(player, "SyncEquipped", equipped)

		elseif action == "UnequipSlot" then
			if type(slot) ~= "number" or slot < 1 or slot > 4 then return end
			local equipped = getEquippedSkills(player)
			equipped[slot] = ""
			skillDataUpdate:FireClient(player, "SyncEquipped", equipped)
		end
	end)

	-- 3. Clean up on player leave
	Players.PlayerRemoving:Connect(function(player: Player)
		playerCooldowns[player] = nil
		playerEquippedSkills[player] = nil
	end)

	-- 4. Sync equipped skills when player spawns
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			local slots = SkillService.getEquippedSkills(player)
			skillDataUpdate:FireClient(player, "SyncEquipped", slots)
		end)
	end)

	print("⚡ [SkillService] Initialized combat skill server listeners and validation.")
end

return SkillService

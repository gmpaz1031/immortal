--!strict
-- src/server/PlantHarvestService.server.luau
-- Production Modular Plant Gathering & Harvesting Service for Immortal Cultivation RPG
-- Handles manual placement detection, ProximityPrompt interactions, anti-duplication,
-- inventory rewards into Inventory.Miscs, 3-second respawns, 9-stud permanent zero-drift anchoring.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlantConfig = require(Shared:WaitForChild("PlantConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local remote = ReplicatedStorage:WaitForChild("CultivationRemote") :: RemoteEvent

-- Hidden cache folder to hold harvested plants during their 3-second respawn timer
local harvestedCache = ServerStorage:FindFirstChild("HarvestedPlantsCache") :: Folder?
if not harvestedCache then
	harvestedCache = Instance.new("Folder")
	harvestedCache.Name = "HarvestedPlantsCache"
	harvestedCache.Parent = ServerStorage
end

local registeredPlants = {} :: { [Model]: boolean }

-- ============================================================================
-- HELPER: VALID RESPAWN POSITION DETECTION (WITHIN 9 STUDS OF ORIGINAL ANCHOR)
-- ============================================================================
local function findValidRespawnCFrame(plant: Model, origPos: Vector3, plantDef: PlantConfig.PlantDef): CFrame
	local maxRadius = plantDef.RespawnRadius or 9
	local maxAttempts = 10

	local rayParams = RaycastParams.new()
	rayParams.FilterType = RaycastFilterType.Exclude
	rayParams.IgnoreWater = not (plantDef.IsWaterPlant == true)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = RaycastFilterType.Exclude

	for attempt = 1, maxAttempts do
		-- Random position strictly inside a circle of radius maxRadius
		local angle = math.random() * math.pi * 2
		local dist = maxRadius * math.sqrt(math.random()) -- uniform circular distribution
		local candX = origPos.X + dist * math.cos(angle)
		local candZ = origPos.Z + dist * math.sin(angle)

		-- Downward raycast from 15 studs above origPos to 15 studs below
		local rayOrigin = Vector3.new(candX, origPos.Y + 15, candZ)
		local rayDir = Vector3.new(0, -30, 0)

		-- Ignore characters and harvested cache
		local ignoreList: { Instance } = { plant, harvestedCache :: Instance }
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(ignoreList, player.Character)
			end
		end
		rayParams.FilterDescendantsInstances = ignoreList

		local result = Workspace:Raycast(rayOrigin, rayDir, rayParams)
		if result and result.Position then
			local hitPos = result.Position
			local distFromOrig = (Vector3.new(hitPos.X, origPos.Y, hitPos.Z) - origPos).Magnitude

			-- 1. Strictly within the 9-stud radius of the ORIGINAL placement position
			if distFromOrig <= (maxRadius + 0.1) then
				-- 2. Check surface slope (walkable ground, not sheer cliff or ceiling)
				if result.Normal.Y >= 0.60 then
					-- 3. Check water constraint
					local isWater = (result.Material == Enum.Material.Water)
					local waterOk = (plantDef.IsWaterPlant == true) or (not isWater)

					if waterOk then
						-- 4. Clearance check: ensure we are not inside a rock, wall, or building
						overlapParams.FilterDescendantsInstances = ignoreList
						local checkCenter = hitPos + Vector3.new(0, 1.2, 0)
						local partsInside = Workspace:GetPartBoundsInBox(CFrame.new(checkCenter), Vector3.new(1.8, 2.4, 1.8), overlapParams)
						local hasObstacle = false
						for _, part in ipairs(partsInside) do
							if part.CanCollide and not part:IsDescendantOf(plant) then
								hasObstacle = true
								break
							end
						end

						if not hasObstacle then
							-- Valid location found! Preserve natural orientation with a slight random yaw rotation
							local randomYaw = math.random() * math.pi * 2
							return CFrame.new(hitPos) * CFrame.Angles(0, randomYaw, 0)
						end
					end
				end
			end
		end
	end

	-- Fallback: If no valid randomized location found after 10 attempts,
	-- safely return the original placement position (zero drift guaranteed)
	return CFrame.new(origPos) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
end

-- ============================================================================
-- PLANT COLLECTION & RESPAWN LIFECYCLE
-- ============================================================================
local function harvestPlant(plant: Model, player: Player, plantDef: PlantConfig.PlantDef)
	-- Anti-Duplication Check: once collected, immediately mark unavailable
	if plant:GetAttribute("Harvested") == true then
		return
	end
	plant:SetAttribute("Harvested", true)

	local primaryPart = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
	local prompt = primaryPart and primaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = false
	end

	-- 1. Award plant item directly to player's Inventory (flat structure for DataStore persistence)
	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		local itemVal = inventory:FindFirstChild(plantDef.Name) :: IntValue?
		if not itemVal then
			itemVal = Instance.new("IntValue")
			itemVal.Name = plantDef.Name
			itemVal.Value = 1
			itemVal.Parent = inventory
		else
			itemVal.Value = itemVal.Value + 1
		end

		-- Explicitly notify client to refresh inventory and show notification
		remote:FireClient(player, "InventoryUpdated")
		remote:FireClient(player, "Notification", string.format("Collected %s!", plantDef.Name), true)
	end

	-- 2. Remove plant from world during respawn period
	local originalParent = plant.Parent or Workspace
	plant.Parent = harvestedCache

	-- 3. Respawn timer: exactly 3 seconds
	local respawnDelay = plantDef.RespawnTime or 3
	task.delay(respawnDelay, function()
		if not plant or not plant:IsDescendantOf(game) then
			return
		end

		-- Respawns exactly where the developer placed it in the world
		local origCF = plant:GetAttribute("OriginalSpawnCFrame")
		if typeof(origCF) == "CFrame" then
			plant:PivotTo(origCF)
		else
			local origPos = plant:GetAttribute("OriginalSpawnPosition") :: Vector3?
			if origPos then
				plant:PivotTo(CFrame.new(origPos))
			end
		end

		-- Return plant to world
		plant.Parent = originalParent
		plant:SetAttribute("Harvested", false)

		-- Re-enable prompt for next collection
		if prompt then
			prompt.Enabled = true
		end
	end)
end

-- ============================================================================
-- REGISTER MANUALLY PLACED PLANT MODEL
-- ============================================================================
local function registerPlant(plant: Model)
	if registeredPlants[plant] then
		return
	end

	-- Determine plant definition from model name or attribute
	local plantName = plant:GetAttribute("PlantName") or plant.Name
	local plantDef = PlantConfig.GetPlant(tostring(plantName))
	if not plantDef then
		return
	end

	registeredPlants[plant] = true
	CollectionService:AddTag(plant, "HarvestablePlant")

	-- Ensure PrimaryPart exists
	local primary = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
	if not primary then
		primary = Instance.new("Part")
		primary.Name = "PlantRoot"
		primary.Size = Vector3.new(1, 1, 1)
		primary.Transparency = 1
		primary.CanCollide = false
		primary.Anchored = true
		primary.Position = plant:GetPivot().Position
		primary.Parent = plant
		plant.PrimaryPart = primary
	else
		plant.PrimaryPart = primary
		primary.Anchored = true
	end

	-- Record permanent OriginalSpawnCFrame and OriginalSpawnPosition (never replaced by later respawns)
	local existingCF = plant:GetAttribute("OriginalSpawnCFrame") :: CFrame?
	if not existingCF then
		local initialCF = plant:GetPivot()
		plant:SetAttribute("OriginalSpawnCFrame", initialCF)
		plant:SetAttribute("OriginalSpawnPosition", initialCF.Position)
		plant:SetAttribute("CurrentSpawnPosition", initialCF.Position)
	end
	plant:SetAttribute("Harvested", false)

	-- Anchor all parts in the plant model
	for _, part in ipairs(plant:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanTouch = false
		end
	end

	-- Setup ProximityPrompt for interaction
	local prompt = primary:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "HarvestPrompt"
		prompt.Parent = primary
	end

	prompt.ActionText = "Collect"
	prompt.ObjectText = plantDef.Name
	prompt.HoldDuration = plantDef.PromptHoldDuration or 0.4
	prompt.MaxActivationDistance = 7.5
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true

	prompt.Triggered:Connect(function(player: Player)
		harvestPlant(plant, player, plantDef)
	end)

	plant.AncestryChanged:Connect(function(_, newParent)
		if newParent == nil then
			registeredPlants[plant] = nil
		end
	end)
end

-- ============================================================================
-- INITIALIZE & LISTEN FOR MANUALLY PLACED PLANTS IN WORKSPACE
-- ============================================================================
-- Scan existing plants in Workspace at startup
local function scanWorkspace()
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("Model") and PlantConfig.IsPlant(desc.Name) then
			registerPlant(desc)
		end
	end
end

scanWorkspace()

-- Listen dynamically for newly duplicated/placed plants in Workspace
Workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("Model") then
		task.defer(function()
			if desc:IsDescendantOf(Workspace) and PlantConfig.IsPlant(desc.Name) then
				registerPlant(desc)
			end
		end)
	end
end)

print("[PlantHarvestService] Initialized. Monitoring manually placed harvestable plants in Workspace.")

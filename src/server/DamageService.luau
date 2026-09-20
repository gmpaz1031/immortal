--!strict
--[[
    DamageService.luau
    Central authority on the server for applying damage, verifying targets,
    checking Line of Sight, cultivating stat multipliers, and triggering drop rewards.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DamageService = {}

-- Checks if an instance is a valid living target for damage
function DamageService.isValidTarget(targetHumanoid: Humanoid, casterPlayer: Player?): boolean
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return false
	end

	local targetModel = targetHumanoid.Parent
	if not targetModel or not targetModel:IsA("Model") then
		return false
	end

	-- Do not damage self
	if casterPlayer and casterPlayer.Character and targetModel == casterPlayer.Character then
		return false
	end

	return true
end

-- Checks if line of sight is clear between origin and target position
function DamageService.hasLineOfSight(origin: Vector3, targetPos: Vector3, ignoreList: { Instance }): boolean
	local direction = targetPos - origin
	local distance = direction.Magnitude
	if distance < 1 then
		return true
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.IgnoreWater = true

	local result = Workspace:Raycast(origin, direction.Unit * distance, rayParams)
	if result and result.Instance then
		-- If it hit non-collidable or translucent cosmetic parts, consider clear
		if not result.Instance.CanCollide or result.Instance.Transparency > 0.85 then
			return true
		end
		return false
	end
	return true
end

-- Gets a realm-based damage multiplier from player data if available
local function getRealmMultiplier(player: Player?): number
	if not player then return 1.0 end
	local data = player:FindFirstChild("CultivationData")
	if not data then return 1.0 end
	local realmVal = data:FindFirstChild("RealmIndex")
	if not realmVal then return 1.0 end
	-- Each realm adds 12% bonus damage
	return 1.0 + (realmVal.Value * 0.12)
end

-- Applies damage to a humanoid with realm scaling and defense reduction
function DamageService.applyDamage(
	targetHumanoid: Humanoid,
	baseDamage: number,
	casterPlayer: Player?,
	skillName: string?
): number
	if not DamageService.isValidTarget(targetHumanoid, casterPlayer) then
		return 0
	end

	local realmMult = getRealmMultiplier(casterPlayer)
	local finalDamage = math.floor(baseDamage * realmMult)

	-- Check for a defense attribute on the target's model
	local targetModel = targetHumanoid.Parent :: Model?
	if targetModel then
		local defAttr = targetModel:GetAttribute("Defense")
		if type(defAttr) == "number" and defAttr > 0 then
			finalDamage = math.max(1, finalDamage - defAttr)
		end
	end

	targetHumanoid:TakeDamage(finalDamage)

	if skillName then
		print(string.format("[DamageService] %s dealt %d damage via %s (realm mult: %.2f)",
			casterPlayer and casterPlayer.Name or "NPC",
			finalDamage, skillName, realmMult))
	end

	return finalDamage
end

-- Finds all humanoid targets within a sphere radius from a center point
function DamageService.findTargetsInRadius(
	center: Vector3,
	radius: number,
	casterPlayer: Player?,
	requireLoS: boolean?
): { Humanoid }
	local found: { Humanoid } = {}
	local ignoreList: { Instance } = {}

	if casterPlayer and casterPlayer.Character then
		table.insert(ignoreList, casterPlayer.Character)
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Health > 0 then
			local model = obj.Parent
			if model and model:IsA("Model") then
				-- Skip the caster's own character
				if casterPlayer and model == casterPlayer.Character then
					continue
				end

				local root = model:FindFirstChild("HumanoidRootPart")
					or model:FindFirstChild("Torso")
					or model:FindFirstChild("UpperTorso")
				if root and root:IsA("BasePart") then
					local dist = (root.Position - center).Magnitude
					if dist <= radius then
						if requireLoS then
							if DamageService.hasLineOfSight(center, root.Position, ignoreList) then
								table.insert(found, obj)
							end
						else
							table.insert(found, obj)
						end
					end
				end
			end
		end
	end

	return found
end

return DamageService

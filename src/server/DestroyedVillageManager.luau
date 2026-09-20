--!strict
--[[
    DestroyedVillageManager.luau
    Spawns and manages enemies in the Destroyed Village:
    - 5 Distinct Swordsmen patrolling village ruins with walking, jumping, and sword slashing animations:
      * Swordsman_1: Shadow Blade Swordsman
      * Swordsman_2: Crimson Dao Vanguard
      * Swordsman_3: Iron Gale Swordsman
      * Swordsman_4: Azure Wind Swordsman
      * Swordsman_5: Ghost Flame Swordsman
    - 1 Swordmaster Boss standing majestically at the Central Shrine Platform in STANDBY mode
]]

local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local DestroyedVillageManager = {}

-- Recorded exact locations for the Destroyed Village combat zone
local DEFAULT_CFRAMES: { [string]: CFrame } = {
	Swordsman_1 = CFrame.new(-679, 6.89, 195, -0.53, 0, 0.85, 0, 1, 0, -0.85, 0, -0.53),
	Swordsman_2 = CFrame.new(-614, 6.89, 190, -0.60, 0, 0.80, 0, 1, 0, -0.80, 0, -0.60),
	Swordsman_3 = CFrame.new(-674, 6.89, 245, -1.00, 0, -0.03, 0, 1, 0, 0.03, 0, -1.00),
	Swordsman_4 = CFrame.new(-621, 6.89, 250, -0.75, 0, -0.66, 0, 1, 0, 0.66, 0, -0.75),
	Swordsman_5 = CFrame.new(-649, 6.89, 260, -0.75, 0, 0.66, 0, 1, 0, -0.66, 0, -0.75),
	Swordmaster_Boss = CFrame.new(-647.73, 14.18, 226.04, -1, 0, 0, 0, 1, 0, 0, 0, -1),
}

function DestroyedVillageManager.init()
	local enemiesFolder = Workspace:FindFirstChild("DestroyedVillage_Enemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "DestroyedVillage_Enemies"
		enemiesFolder.Parent = Workspace
	end

	local templates = ServerStorage:FindFirstChild("DestroyedVillage_EnemyTemplates")
	if not templates then
		warn("[DestroyedVillageManager] DestroyedVillage_EnemyTemplates not found in ServerStorage!")
		return
	end

	-- Check if enemies already exist
	for name, targetCF in pairs(DEFAULT_CFRAMES) do
		local existing = enemiesFolder:FindFirstChild(name)
		if not existing then
			local template = templates:FindFirstChild(name)
			if template then
				local enemy = template:Clone()
				enemy.Name = name
				local hrp = enemy:FindFirstChild("HumanoidRootPart")
				if hrp then
					enemy.PrimaryPart = hrp
					enemy:PivotTo(targetCF)
				end
				enemy.Parent = enemiesFolder
			end
		end
	end

	print("🗡️ [DestroyedVillageManager] Destroyed Village enemies verified and active!")
end

return DestroyedVillageManager

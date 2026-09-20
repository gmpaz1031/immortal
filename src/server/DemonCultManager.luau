--!strict
--[[
    DemonCultManager.luau
    Orchestrates all Heavenly Demon Cult content:

    VILLAGE:
      - Generates DemonCultVillage environment
      - Spawns 5 Demon Cultists, 2 Senior Cultists, 1 Demonic Elder
      - All active AI attached via DemonCultAI

    TOWER:
      - Generates DemonCultTower environment (6 floors)
      - Spawns Pillar bosses at their designated floors:
          Floor 1: FlameDemoness
          Floor 2: PoisonDemoness
          Floor 3: FistDemon
          Floor 4: SwordDemon
          Floor 5: BloodDemon    (STANDBY)
          Apex:    SupremeDemon  (STANDBY)

    TEMPLATES (ServerStorage.DemonCult_EnemyTemplates):
      Stores cloneable templates for all 9 enemy types.
      Cave enemies: NOT placed here — user places manually.
]]

local Workspace           = game:GetService("Workspace")
local ServerStorage       = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DemonCultManager = {}

local function requireSibling(name: string)
	local m = ServerScriptService:FindFirstChild(name, true)
	if m and m:IsA("ModuleScript") then return require(m) end
	error("[DemonCultManager] Cannot find module: " .. name)
end

-- Village enemy spawn offsets (relative to village center -50, 0, 350)
local VILLAGE_CENTER = Vector3.new(-50, 0, 350)

local VILLAGE_SPAWNS: { { type: string, offset: Vector3 } } = {
	-- 5 Demon Cultists patrolling
	{ type = "DemonCultist", offset = Vector3.new( 40, 0, -30) },
	{ type = "DemonCultist", offset = Vector3.new(-40, 0, -30) },
	{ type = "DemonCultist", offset = Vector3.new( 40, 0,  30) },
	{ type = "DemonCultist", offset = Vector3.new(-40, 0,  30) },
	{ type = "DemonCultist", offset = Vector3.new(  0, 0,  60) },
	-- 2 Senior Demon Cultists at lodge + east hall
	{ type = "SeniorDemonCultist", offset = Vector3.new( 55, 0, -55) },
	{ type = "SeniorDemonCultist", offset = Vector3.new(-55, 0, -55) },
	-- 1 Demonic Elder guarding central shrine
	{ type = "DemonicElder", offset = Vector3.new(0, 6, -18) },
}

-- Tower boss spawn positions (world absolute)
-- Matches DemonCultTowerGenerator.FloorPositions exactly
local TOWER_SPAWNS: { { type: string, pos: Vector3 } } = {
	{ type = "FlameDemoness",  pos = Vector3.new(-50, 8.5,  160) },
	{ type = "PoisonDemoness", pos = Vector3.new(-50, 22.5, 160) },
	{ type = "FistDemon",      pos = Vector3.new(-50, 36.5, 160) },
	{ type = "SwordDemon",     pos = Vector3.new(-50, 50.5, 160) },
	{ type = "BloodDemon",     pos = Vector3.new(-50, 66.5, 160) },
	{ type = "SupremeDemon",   pos = Vector3.new(-50, 82.5, 160) },
}

local function spawnEnemy(
	enemyType: string,
	spawnPos: Vector3,
	enemiesFolder: Instance,
	templates: { [string]: Model },
	ai: { attach: (Model, string, CFrame?) -> () }
)
	local template = templates[enemyType]
	if not template then
		warn("[DemonCultManager] No template for:", enemyType)
		return
	end
	local clone = template:Clone()
	local hrp = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		warn("[DemonCultManager] No HumanoidRootPart in template:", enemyType)
		return
	end
	clone.PrimaryPart = hrp
	clone:PivotTo(CFrame.new(spawnPos))
	clone.Parent = enemiesFolder
	local spawnCF = CFrame.new(spawnPos)
	ai.attach(clone, enemyType, spawnCF)
end

function DemonCultManager.init()
	-- --------------------------------------------------------
	-- 1. Wipe any leftovers from previous bad generations
	-- --------------------------------------------------------
	local oldBoss = ServerStorage:FindFirstChild("DemonCult_BossTemplates")
	if oldBoss then oldBoss:Destroy() end

	-- --------------------------------------------------------
	-- 2. Build enemy templates in ServerStorage
	-- --------------------------------------------------------
	local templateFolder = ServerStorage:FindFirstChild("DemonCult_EnemyTemplates")
	if templateFolder then templateFolder:Destroy() end
	templateFolder = Instance.new("Folder")
	templateFolder.Name = "DemonCult_EnemyTemplates"
	templateFolder.Parent = ServerStorage

	local factory = requireSibling("DemonCultFactory")
	local ai      = requireSibling("DemonCultAI")

	local enemyTypes = {
		"DemonCultist", "SeniorDemonCultist", "DemonicElder",
		"FlameDemoness", "PoisonDemoness", "FistDemon", "SwordDemon",
		"SupremeDemon", "BloodDemon",
	}

	local templates: { [string]: Model } = {}
	for _, typeName in ipairs(enemyTypes) do
		local model = factory.createEnemy(typeName)
		model.Parent = templateFolder
		templates[typeName] = model
		print("[DemonCultManager] Built template:", typeName)
	end

	-- --------------------------------------------------------
	-- 3. Create enemies folder
	-- --------------------------------------------------------
	local enemiesFolder = Workspace:FindFirstChild("DemonCult_Enemies")
	if enemiesFolder then enemiesFolder:Destroy() end
	enemiesFolder = Instance.new("Folder")
	enemiesFolder.Name = "DemonCult_Enemies"
	enemiesFolder.Parent = Workspace

	-- --------------------------------------------------------
	-- 4. Generate village map
	-- --------------------------------------------------------
	local villageGen = requireSibling("DemonCultVillageGenerator")
	villageGen.generate()

	-- --------------------------------------------------------
	-- 5. Spawn village enemies
	-- --------------------------------------------------------
	for _, cfg in ipairs(VILLAGE_SPAWNS) do
		spawnEnemy(cfg.type, VILLAGE_CENTER + cfg.offset, enemiesFolder, templates, ai)
	end
	print(string.format("[DemonCultManager] Spawned %d village enemies.", #VILLAGE_SPAWNS))

	-- --------------------------------------------------------
	-- 6. Generate tower map
	-- --------------------------------------------------------
	local towerGen = requireSibling("DemonCultTowerGenerator")
	towerGen.generate()

	-- --------------------------------------------------------
	-- 7. Spawn tower bosses
	-- --------------------------------------------------------
	for _, cfg in ipairs(TOWER_SPAWNS) do
		spawnEnemy(cfg.type, cfg.pos, enemiesFolder, templates, ai)
	end
	print(string.format("[DemonCultManager] Spawned %d tower bosses.", #TOWER_SPAWNS))

	print("[DemonCultManager] Demon Cult fully initialized!")
end

return DemonCultManager

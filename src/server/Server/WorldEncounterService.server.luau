--!strict
--[[
    WorldEncounterService.server.luau
    Initializes world encounters on server startup:
    - Destroyed Village (5 Swordsmen + 1 Swordmaster Boss)
    - Heavenly Demon Cult (Demon Cult Village + 6-Floor Demonic Pavilion Tower)
]]

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local function initDestroyedVillage()
	local genModule = script.Parent:FindFirstChild("DestroyedVillageGenerator")
	if genModule and genModule:IsA("ModuleScript") then
		if not Workspace:FindFirstChild("DestroyedVillage") then
			local gen = require(genModule) :: any
			pcall(function()
				gen.generate()
			end)
		end
	end

	local mgrModule = script.Parent:FindFirstChild("DestroyedVillageManager")
	if mgrModule and mgrModule:IsA("ModuleScript") then
		local mgr = require(mgrModule) :: any
		local ok, err = pcall(function()
			mgr.init()
		end)
		if ok then
			print("[WorldEncounterService] Destroyed Village initialized.")
		else
			warn("[WorldEncounterService] Failed to init Destroyed Village:", err)
		end
	end
end

local function initDemonCult()
	local mgrModule = script.Parent:FindFirstChild("DemonCultManager")
	if mgrModule and mgrModule:IsA("ModuleScript") then
		local mgr = require(mgrModule) :: any
		local ok, err = pcall(function()
			mgr.init()
		end)
		if ok then
			print("[WorldEncounterService] Heavenly Demon Cult initialized.")
		else
			warn("[WorldEncounterService] Failed to init Demon Cult:", err)
		end
	end
end

task.spawn(function()
	task.wait(1) -- Brief grace period for core services to establish
	initDestroyedVillage()
	initDemonCult()
end)

import sys
import os
import json
import urllib.request
from pathlib import Path

PORT = 34875
BASE_URL = f"http://127.0.0.1:{PORT}"

def exec_code(code: str, timeout: float = 20.0):
    url = f"{BASE_URL}/exec"
    payload = json.dumps({"code": code}).encode("utf-8")
    req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        cmd_id = data.get("id")
    
    import time
    start_time = time.time()
    while time.time() - start_time < timeout:
        res_url = f"{BASE_URL}/result?id={cmd_id}"
        try:
            with urllib.request.urlopen(res_url) as resp:
                res_data = json.loads(resp.read().decode("utf-8"))
                return res_data.get("success", False), res_data.get("output") or res_data.get("error")
        except urllib.error.HTTPError as e:
            if e.code == 404:
                time.sleep(0.1)
                continue
            return False, f"HTTP Error {e.code}"
        except Exception:
            time.sleep(0.1)
            continue
    return False, "Timeout"

# 1. Update DATA Script Source
DATA_SRC = r"""--!strict
-- src/server/DATA.server.luau
-- PlayerDataService: Leaderstats, Attributes, Inventory, Destiny & DataStore Persistence

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local DestinyConfig = require(Shared:WaitForChild("DestinyConfig"))

local DATA_STORE_NAME = "Immortal_PlayerData_v1"
local playerDataStore = nil

pcall(function()
	playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
end)

local sessionData: { [number]: any } = {}

local function applyCharacterStats(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if humanoid then
		local maxHp = player:GetAttribute("MaxHealth") or 100
		humanoid.MaxHealth = maxHp
		humanoid.Health = maxHp
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local goldVal = Instance.new("IntValue")
	goldVal.Name = "Gold"
	goldVal.Value = 50 -- Starting 50 Gold
	goldVal.Parent = leaderstats

	local qiVal = Instance.new("IntValue")
	qiVal.Name = "Qi"
	qiVal.Value = 100 -- Starting Qi
	qiVal.Parent = leaderstats

	local inventory = Instance.new("Folder")
	inventory.Name = "Inventory"
	inventory.Parent = player

	-- Default Attributes
	player:SetAttribute("Realm", "Qi Condensation")
	player:SetAttribute("RealmLevel", 0)
	player:SetAttribute("Qi", 100)
	player:SetAttribute("Cultivating", false)
	player:SetAttribute("Damage", 15)
	player:SetAttribute("Defense", 5)
	player:SetAttribute("MaxHealth", 100)
	player:SetAttribute("EquippedWeapon", "None")
	player:SetAttribute("EquippedArmor", "None")
	player:SetAttribute("QiMultiplier", 1.0)
	player:SetAttribute("PillBuffExpiry", 0)
	player:SetAttribute("Talent", "Mortal")
	player:SetAttribute("TalentMultiplier", 1.0)
	player:SetAttribute("SpiritualRoot", "None")
	player:SetAttribute("SpiritualRootMultiplier", 1.0)
	player:SetAttribute("SpinsUsed", 0)

	qiVal.Changed:Connect(function(newVal)
		player:SetAttribute("Qi", newVal)
	end)

	local userId = player.UserId
	local savedData = nil

	if playerDataStore and not RunService:IsStudio() then
		local success, result = pcall(function()
			return playerDataStore:GetAsync("User_" .. userId)
		end)
		if success and result then
			savedData = result
		end
	end

	if savedData and typeof(savedData) == "table" then
		goldVal.Value = savedData.Gold or 50
		qiVal.Value = savedData.Qi or 0
		player:SetAttribute("Realm", savedData.Realm or "Qi Condensation")
		player:SetAttribute("RealmLevel", savedData.RealmLevel or 0)
		player:SetAttribute("EquippedWeapon", savedData.EquippedWeapon or "None")
		player:SetAttribute("EquippedArmor", savedData.EquippedArmor or "None")
		player:SetAttribute("Talent", savedData.Talent or "Mortal")
		player:SetAttribute("SpiritualRoot", savedData.SpiritualRoot or "None")
		player:SetAttribute("SpinsUsed", savedData.SpinsUsed or 0)

		if savedData.Inventory and typeof(savedData.Inventory) == "table" then
			for itemName, qty in pairs(savedData.Inventory) do
				if qty > 0 then
					local itmVal = Instance.new("IntValue")
					itmVal.Name = itemName
					itmVal.Value = qty
					itmVal.Parent = inventory
				end
			end
		end
	else
		local starterPill = Instance.new("IntValue")
		starterPill.Name = "Lesser Qi Pill"
		starterPill.Value = 2
		starterPill.Parent = inventory
	end

	local realmName = player:GetAttribute("Realm") or "Qi Condensation"
	local realmDef = CultivationConfig.Realms[realmName]
	local baseDmg = realmDef and realmDef.BaseDamage or 15
	local baseDef = realmDef and realmDef.BaseDefense or 5
	local baseHp = realmDef and realmDef.BaseHealth or 100

	local eqW = player:GetAttribute("EquippedWeapon")
	local wItem = eqW and ItemConfig.getItem(eqW)
	if wItem and wItem.DamageBonus then
		baseDmg = baseDmg + wItem.DamageBonus
	end

	local eqA = player:GetAttribute("EquippedArmor")
	local aItem = eqA and ItemConfig.getItem(eqA)
	if aItem and aItem.DefenseBonus then
		baseDef = baseDef + aItem.DefenseBonus
	end
	if aItem and aItem.MaxHealthBonus then
		baseHp = baseHp + aItem.MaxHealthBonus
	end

	local talent = player:GetAttribute("Talent") or "Mortal"
	local root = player:GetAttribute("SpiritualRoot") or "None"
	local talentMult = DestinyConfig.GetTalentMultiplier(talent)
	local rootMult = DestinyConfig.GetRootMultiplier(root)

	player:SetAttribute("Damage", baseDmg)
	player:SetAttribute("Defense", baseDef)
	player:SetAttribute("MaxHealth", baseHp)
	player:SetAttribute("TalentMultiplier", talentMult)
	player:SetAttribute("SpiritualRootMultiplier", rootMult)

	if player.Character then
		applyCharacterStats(player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		applyCharacterStats(player, char)
	end)

	sessionData[userId] = true
	print(string.format("[PlayerData] Initialized profile for %s (Talent: %s, Root: %s)", player.Name, talent, root))
end

local function savePlayerData(player: Player)
	local userId = player.UserId
	if not sessionData[userId] or not playerDataStore then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") and (leaderstats:FindFirstChild("Gold") :: IntValue).Value or 0
	local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") and (leaderstats:FindFirstChild("Qi") :: IntValue).Value or 0

	local invTable = {}
	local inventory = player:FindFirstChild("Inventory")
	if inventory then
		for _, child in ipairs(inventory:GetChildren()) do
			if child:IsA("IntValue") and child.Value > 0 then
				invTable[child.Name] = child.Value
			end
		end
	end

	local dataToSave = {
		Gold = goldVal,
		Qi = qiVal,
		Realm = player:GetAttribute("Realm") or "Qi Condensation",
		RealmLevel = player:GetAttribute("RealmLevel") or 0,
		EquippedWeapon = player:GetAttribute("EquippedWeapon") or "None",
		EquippedArmor = player:GetAttribute("EquippedArmor") or "None",
		Talent = player:GetAttribute("Talent") or "Mortal",
		SpiritualRoot = player:GetAttribute("SpiritualRoot") or "None",
		SpinsUsed = player:GetAttribute("SpinsUsed") or 0,
		Inventory = invTable,
	}

	pcall(function()
		playerDataStore:SetAsync("User_" .. userId, dataToSave)
	end)
end

local function onPlayerRemoving(player: Player)
	savePlayerData(player)
	sessionData[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

task.spawn(function()
	while true do
		task.wait(180)
		for _, p in ipairs(Players:GetPlayers()) do
			savePlayerData(p)
		end
	end
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		savePlayerData(p)
	end
end)
"""

# 2. Update MAINSERVER Script Source
MAINSERVER_SRC = r"""--!strict
-- src/server/MAINSERVER.server.luau
-- CultivationService: Meditation Loop, Breakthroughs, Item Usage, Equipment Stats & Destiny Wheel

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local DestinyConfig = require(Shared:WaitForChild("DestinyConfig"))

local remote = ReplicatedStorage:WaitForChild("CultivationRemote") :: RemoteEvent

local ADMIN_USER_IDS = {
	[game.CreatorId] = true,
}

local function isPlayerAdmin(player: Player): boolean
	return RunService:IsStudio() or ADMIN_USER_IDS[player.UserId] == true
end

local function recalculateStats(player: Player)
	local realmName = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 0
	local realmDef = CultivationConfig.Realms[realmName]

	local baseDmg = (realmDef and realmDef.BaseDamage or 15) + (level * 3)
	local baseDef = (realmDef and realmDef.BaseDefense or 5) + (level * 2)
	local baseHp  = (realmDef and realmDef.BaseHealth or 100) + (level * 15)

	-- Weapon bonus
	local eqW = player:GetAttribute("EquippedWeapon")
	local wItem = eqW and ItemConfig.getItem(eqW)
	if wItem and wItem.DamageBonus then
		baseDmg = baseDmg + wItem.DamageBonus
	end

	-- Armor bonus
	local eqA = player:GetAttribute("EquippedArmor")
	local aItem = eqA and ItemConfig.getItem(eqA)
	if aItem and aItem.DefenseBonus then
		baseDef = baseDef + aItem.DefenseBonus
	end
	if aItem and aItem.MaxHealthBonus then
		baseHp = baseHp + aItem.MaxHealthBonus
	end

	-- Talent & Spiritual Root multipliers
	local talent = player:GetAttribute("Talent") or "Mortal"
	local root = player:GetAttribute("SpiritualRoot") or "None"
	local talentMult = DestinyConfig.GetTalentMultiplier(talent)
	local rootMult = DestinyConfig.GetRootMultiplier(root)

	player:SetAttribute("Damage", baseDmg)
	player:SetAttribute("Defense", baseDef)
	player:SetAttribute("MaxHealth", baseHp)
	player:SetAttribute("Talent", talent)
	player:SetAttribute("TalentMultiplier", talentMult)
	player:SetAttribute("SpiritualRoot", root)
	player:SetAttribute("SpiritualRootMultiplier", rootMult)

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.MaxHealth = baseHp
	end
end

-- ============================================================================
-- 1. REMOTE EVENT DISPATCHER
-- ============================================================================
remote.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local args = { ... }

	if action == "Cultivate" then
		local current = player:GetAttribute("Cultivating") or false
		local newState = not current
		player:SetAttribute("Cultivating", newState)

		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			if newState then
				hum.WalkSpeed = 0
				hum.JumpPower = 0
				remote:FireClient(player, "MeditationStart")
			else
				hum.WalkSpeed = 16
				hum.JumpPower = 50
				remote:FireClient(player, "MeditationStop")
			end
		end

	elseif action == "Breakthrough" then
		local realm = player:GetAttribute("Realm") or "Qi Condensation"
		local level = player:GetAttribute("RealmLevel") or 0
		local currentQi = player:GetAttribute("Qi") or 0
		local reqQi = CultivationConfig.getRequiredQi(realm, level)

		if currentQi >= reqQi then
			local leaderstats = player:FindFirstChild("leaderstats")
			local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
			if qiVal then
				qiVal.Value = math.max(0, qiVal.Value - reqQi)
			end

			local realmDef = CultivationConfig.Realms[realm]
			if realmDef and level < realmDef.MaxLevel then
				player:SetAttribute("RealmLevel", level + 1)
			else
				local nextRealm = CultivationConfig.getNextRealm(realm)
				if nextRealm then
					player:SetAttribute("Realm", nextRealm)
					player:SetAttribute("RealmLevel", 1)
				else
					player:SetAttribute("RealmLevel", level + 1)
				end
			end

			recalculateStats(player)
			remote:FireClient(player, "BreakthroughStart")
			remote:FireAllClients("BreakthroughBurst", player)
			print(string.format("[Breakthrough] %s broke through to %s · Level %d!", player.Name, player:GetAttribute("Realm"), player:GetAttribute("RealmLevel") or 0))
		end

	elseif action == "SpinWheel" then
		local wheelType = args[1]
		if wheelType ~= "Talent" and wheelType ~= "SpiritualRoot" then return end

		local leaderstats = player:FindFirstChild("leaderstats")
		local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
		local spinsUsed = player:GetAttribute("SpinsUsed") or 0
		local cost = (spinsUsed == 0) and 0 or DestinyConfig.SPIN_COST

		if cost > 0 and (not goldVal or goldVal.Value < cost) then
			return
		end

		if cost > 0 and goldVal then
			goldVal.Value = goldVal.Value - cost
		end

		player:SetAttribute("SpinsUsed", spinsUsed + 1)

		if wheelType == "Talent" then
			local talentEntry, resultIdx = DestinyConfig.RollTalent()
			player:SetAttribute("Talent", talentEntry.Name)
			recalculateStats(player)
			remote:FireClient(player, "SpinResult", "Talent", resultIdx, talentEntry.Name, talentEntry.Multiplier)
			print(string.format("[DestinyWheel] %s spun Talent: %s (x%.2f)", player.Name, talentEntry.Name, talentEntry.Multiplier))
		elseif wheelType == "SpiritualRoot" then
			local rootEntry, resultIdx = DestinyConfig.RollSpiritualRoot()
			player:SetAttribute("SpiritualRoot", rootEntry.Name)
			recalculateStats(player)
			remote:FireClient(player, "SpinResult", "SpiritualRoot", resultIdx, rootEntry.Name, rootEntry.Multiplier)
			print(string.format("[DestinyWheel] %s spun Spiritual Root: %s (x%.2f)", player.Name, rootEntry.Name, rootEntry.Multiplier))
		end

	elseif action == "BuyItem" then
		local itemName = args[1]
		local item = itemName and ItemConfig.getItem(itemName)
		if item then
			local leaderstats = player:FindFirstChild("leaderstats")
			local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
			local inventory = player:FindFirstChild("Inventory")

			if goldVal and inventory and goldVal.Value >= item.Price then
				goldVal.Value = goldVal.Value - item.Price

				local itmVal = inventory:FindFirstChild(itemName) :: IntValue?
				if not itmVal then
					itmVal = Instance.new("IntValue")
					itmVal.Name = itemName
					itmVal.Value = 0
					itmVal.Parent = inventory
				end
				itmVal.Value = itmVal.Value + 1
				print(string.format("[Shop] %s purchased %s for %d Gold", player.Name, itemName, item.Price))
			end
		end

	elseif action == "UseItem" then
		local itemName = args[1]
		local inventory = player:FindFirstChild("Inventory")
		local itmVal = inventory and inventory:FindFirstChild(itemName) :: IntValue?

		if itmVal and itmVal.Value > 0 then
			local item = ItemConfig.getItem(itemName)
			if item and item.Type == "Pill" then
				itmVal.Value = itmVal.Value - 1

				if item.InstantQi then
					local leaderstats = player:FindFirstChild("leaderstats")
					local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
					if qiVal then
						qiVal.Value = qiVal.Value + item.InstantQi
					end
				end

				if itemName == "Spirit Spring Elixir" then
					local char = player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = hum.MaxHealth
					end
				end

				if item.QiGatherMultiplier and item.BuffDurationSeconds then
					player:SetAttribute("QiMultiplier", item.QiGatherMultiplier)
					player:SetAttribute("PillBuffExpiry", os.time() + item.BuffDurationSeconds)
				end
			end
		end

	elseif action == "EquipItem" then
		local itemName = args[1]
		local item = itemName and ItemConfig.getItem(itemName)
		local inventory = player:FindFirstChild("Inventory")
		local itmVal = inventory and inventory:FindFirstChild(itemName) :: IntValue?

		if item and itmVal and itmVal.Value > 0 then
			if item.Type == "Weapon" then
				player:SetAttribute("EquippedWeapon", item.Name)
			elseif item.Type == "Armor" then
				player:SetAttribute("EquippedArmor", item.Name)
			end
			recalculateStats(player)
		end

	elseif action == "UnequipItem" then
		local itemName = args[1]
		local item = itemName and ItemConfig.getItem(itemName)
		if item then
			if item.Type == "Weapon" and player:GetAttribute("EquippedWeapon") == item.Name then
				player:SetAttribute("EquippedWeapon", "None")
			elseif item.Type == "Armor" and player:GetAttribute("EquippedArmor") == item.Name then
				player:SetAttribute("EquippedArmor", "None")
			end
			recalculateStats(player)
		end

	elseif action == "AdminAction" and isPlayerAdmin(player) then
		local subAction = args[1]
		local leaderstats = player:FindFirstChild("leaderstats")
		local inventory = player:FindFirstChild("Inventory")

		if subAction == "AddGold" and leaderstats then
			local g = leaderstats:FindFirstChild("Gold") :: IntValue?
			if g then g.Value = g.Value + (args[2] or 1000) end
		elseif subAction == "AddQi" and leaderstats then
			local q = leaderstats:FindFirstChild("Qi") :: IntValue?
			if q then q.Value = q.Value + (args[2] or 500) end
		elseif subAction == "SetRealmLevel" then
			player:SetAttribute("RealmLevel", args[2] or 1)
			recalculateStats(player)
		elseif subAction == "AddItem" and inventory then
			local itmName = args[2]
			local qty = args[3] or 1
			local itmVal = inventory:FindFirstChild(itmName) :: IntValue?
			if not itmVal then
				itmVal = Instance.new("IntValue")
				itmVal.Name = itmName
				itmVal.Value = 0
				itmVal.Parent = inventory
			end
			itmVal.Value = itmVal.Value + qty
		end
	end
end)

-- ============================================================================
-- 2. BACKGROUND MEDITATION & BUFF TICK LOOP (Every 1 Second)
-- ============================================================================
task.spawn(function()
	while true do
		task.wait(1.0)
		local now = os.time()

		for _, p in ipairs(Players:GetPlayers()) do
			local expiry = p:GetAttribute("PillBuffExpiry") or 0
			if expiry > 0 and now >= expiry then
				p:SetAttribute("QiMultiplier", 1.0)
				p:SetAttribute("PillBuffExpiry", 0)
			end

			local isCult = p:GetAttribute("Cultivating") == true
			local realm = p:GetAttribute("Realm") or "Qi Condensation"
			local realmDef = CultivationConfig.Realms[realm]
			local baseSpeed = realmDef and realmDef.BaseQiPerSecond or 5

			local talentMult = p:GetAttribute("TalentMultiplier") or 1.0
			local rootMult = p:GetAttribute("SpiritualRootMultiplier") or 1.0
			local pillMult = p:GetAttribute("QiMultiplier") or 1.0
			local mult = talentMult * rootMult * pillMult

			local leaderstats = p:FindFirstChild("leaderstats")
			local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
			local maxCap = (realmDef and realmDef.BreakthroughRequirement or 100) * 2
			if qiVal then
				local gain = isCult and math.floor(baseSpeed * mult * 2) or math.max(1, math.floor(baseSpeed * mult * 0.4))
				if qiVal.Value < maxCap or isCult then
					qiVal.Value = qiVal.Value + gain
					if isCult then
						remote:FireClient(p, "QiGainTick", gain)
					end
				end
			end
		end
	end
end)
"""

# 3. Update CultivationClient Script Source
CULTIVATION_CLIENT_SRC = r"""--!strict
-- src/gui/CultivationUI/CultivationClient.client.luau
-- Xianxia RPG UI Controller (Dark Jade, Imperial Gold Filigree & Luminous Cyan Qi)
-- Binds cleanly to the pre-built StarterGui hierarchy.
-- Zero Chinese text, pure English UI.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local ui = script.Parent :: ScreenGui

-- ============================================================================
-- 1. DISABLE STARTERGUI BACKPACK
-- ============================================================================
local function disableBackpack()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
end
disableBackpack()
player.CharacterAdded:Connect(function()
	task.wait(0.1)
	disableBackpack()
end)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CultivationConfig = require(Shared:WaitForChild("CultivationConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local GuofengTheme = require(Shared:WaitForChild("GuofengTheme"))
local IconAssets = require(Shared:WaitForChild("IconAssets"))
local DestinyConfig = require(Shared:WaitForChild("DestinyConfig"))

local remote = ReplicatedStorage:WaitForChild("CultivationRemote") :: RemoteEvent

-- ============================================================================
-- 2. WAIT FOR PRE-BUILT STARTERGUI HIERARCHY
-- ============================================================================
local hud = ui:WaitForChild("GuofengHUD") :: Frame
local roadmapModal = ui:WaitForChild("RoadmapModal") :: Frame
local cultModal = ui:WaitForChild("CultivationScrollModal") :: Frame
local invModal = ui:WaitForChild("InventoryScrollModal") :: Frame
local shopModal = ui:WaitForChild("ShopScrollModal") :: Frame
local wheelModal = ui:WaitForChild("DestinyWheelModal") :: Frame

-- Top HUD Elements
local portraitSlot = hud:WaitForChild("PortraitSlot") :: Frame
local avatarImg = portraitSlot:WaitForChild("Avatar") :: ImageLabel
local realmLabel = hud:WaitForChild("RealmBanner"):WaitForChild("RealmLabel") :: TextLabel
local goldLabel = hud:WaitForChild("GoldBanner"):WaitForChild("GoldLabel") :: TextLabel
local hpFill = hud:WaitForChild("HPBar"):WaitForChild("Fill") :: Frame
local hpText = hud:WaitForChild("HPBar"):WaitForChild("Text") :: TextLabel
local qiFill = hud:WaitForChild("QiBar"):WaitForChild("Fill") :: Frame
local qiText = hud:WaitForChild("QiBar"):WaitForChild("Text") :: TextLabel

local navRow = hud:WaitForChild("NavRow") :: Frame
local roadmapNavBtn = navRow:WaitForChild("RoadmapNavBtn") :: TextButton
local cultNavBtn = navRow:WaitForChild("CultNavBtn") :: TextButton
local invNavBtn = navRow:WaitForChild("InvNavBtn") :: TextButton
local shopNavBtn = navRow:WaitForChild("ShopNavBtn") :: TextButton

-- Safe avatar thumbnail loading
task.spawn(function()
	local ok, thumb = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
	end)
	if ok and thumb and avatarImg then
		avatarImg.Image = thumb
	end
end)

-- ============================================================================
-- 3. FLOATING XIANXIA NOTIFICATION
-- ============================================================================
local function showNotification(msg: string, isGold: boolean?)
	local notif = Instance.new("TextLabel")
	notif.Name = "XianxiaNotif"
	notif.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
	notif.AnchorPoint = Vector2.new(0.5, 0)
	notif.Position = UDim2.new(0.5, 0, 0.12, 0)
	notif.Size = UDim2.new(0, 380, 0, 36)
	notif.Font = GuofengTheme.Fonts.Header
	notif.Text = msg
	notif.TextColor3 = isGold and GuofengTheme.Colors.GoldLight or GuofengTheme.Colors.CyanBright
	notif.TextSize = 13
	notif.ZIndex = 60
	notif.Parent = ui

	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(0, 6)
	nc.Parent = notif

	local ns = Instance.new("UIStroke")
	ns.Color = isGold and GuofengTheme.Colors.GoldBorder or GuofengTheme.Colors.CyanGlow
	ns.Thickness = 1.5
	ns.Parent = notif

	task.spawn(function()
		TweenService:Create(notif, TweenInfo.new(0.25), { Position = UDim2.new(0.5, 0, 0.14, 0) }):Play()
		task.wait(2.2)
		local fade = TweenService:Create(notif, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		notif:Destroy()
	end)
end

-- ============================================================================
-- 3b. FLOATING QI GAIN POPUP
-- ============================================================================
local function showQiGainPopup(amount: number)
	local popup = Instance.new("TextLabel")
	popup.Name = "QiGainPopup"
	popup.BackgroundTransparency = 1
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	local xOffset = math.random(-40, 40)
	popup.Position = UDim2.new(0.5, xOffset, 0.42, 0)
	popup.Size = UDim2.new(0, 120, 0, 30)
	popup.Font = GuofengTheme.Fonts.Title
	popup.Text = string.format("+%d Qi", amount)
	popup.TextColor3 = GuofengTheme.Colors.CyanBright
	popup.TextSize = 18
	popup.TextStrokeColor3 = GuofengTheme.Colors.DarkJadeBg
	popup.TextStrokeTransparency = 0.3
	popup.ZIndex = 65
	popup.Parent = ui

	task.spawn(function()
		local floatTween = TweenService:Create(popup, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, xOffset, 0.34, 0),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		floatTween:Play()
		floatTween.Completed:Wait()
		popup:Destroy()
	end)
end

-- ============================================================================
-- 3c. MEDITATION ANIMATION
-- ============================================================================
local meditationAnim: AnimationTrack? = nil

local function startMeditationAnimation()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://2506281703"

	local ok, track = pcall(function()
		return hum:FindFirstChildOfClass("Animator") and hum:FindFirstChildOfClass("Animator"):LoadAnimation(anim)
			or hum:LoadAnimation(anim)
	end)

	if ok and track then
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Action
		track:Play(0.3)
		meditationAnim = track
	end
end

local function stopMeditationAnimation()
	if meditationAnim then
		meditationAnim:Stop(0.3)
		meditationAnim = nil
	end
end

-- ============================================================================
-- 4. MODAL CONTROLS & NAVIGATION
-- ============================================================================
local function closeAllModals()
	roadmapModal.Visible = false
	cultModal.Visible = false
	invModal.Visible = false
	shopModal.Visible = false
	wheelModal.Visible = false
end

local function toggleModal(modal: Frame)
	local target = not modal.Visible
	closeAllModals()
	modal.Visible = target
end

-- Wire close buttons
roadmapModal:WaitForChild("CloseBtn").InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		roadmapModal.Visible = false
	end
end)

cultModal:WaitForChild("CloseBtn").InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		cultModal.Visible = false
	end
end)

invModal:WaitForChild("CloseBtn").InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		invModal.Visible = false
	end
end)

shopModal:WaitForChild("CloseBtn").InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		shopModal.Visible = false
	end
end)

-- Wire HUD Navigation Buttons (Destiny Wheel is NOT here! Only in Cultivation Panel)
roadmapNavBtn.MouseButton1Click:Connect(function()
	toggleModal(roadmapModal)
end)

cultNavBtn.MouseButton1Click:Connect(function()
	toggleModal(cultModal)
end)

invNavBtn.MouseButton1Click:Connect(function()
	toggleModal(invModal)
end)

shopNavBtn.MouseButton1Click:Connect(function()
	toggleModal(shopModal)
end)

-- Keybinds: M = Roadmap, C = Cultivation, B = Inventory, N = Shop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then return end

	if input.KeyCode == Enum.KeyCode.M then
		toggleModal(roadmapModal)
	elseif input.KeyCode == Enum.KeyCode.C then
		toggleModal(cultModal)
	elseif input.KeyCode == Enum.KeyCode.B then
		toggleModal(invModal)
	elseif input.KeyCode == Enum.KeyCode.N then
		toggleModal(shopModal)
	end
end)

-- ============================================================================
-- 5. ROADMAP INTERACTION
-- ============================================================================
local centerCanvas = roadmapModal:WaitForChild("CenterCanvas") :: Frame
local lineBanner = centerCanvas:WaitForChild("LineBanner") :: TextLabel

local phaseDetails = {
	[1] = "PHASE 1: ENEMY ROSTER EXPANSION · Spirit Boars, Shadow Vipers, Cloud Stags & Bandit Scouts populated across the outer wild valleys.",
	[2] = "PHASE 2: TECHNIQUE EXPANSION · Iron Body (Defense), Wind Blade (Slash), Void Step (Dash) unlocked with rank 5 passive masteries.",
	[3] = "PHASE 3: FIRST DUNGEON · The Black-Thread Hollow (22 scenes). Three branching paths: Combat, Stealth, and Lore. Boss: Cultist Leader.",
	[4] = "PHASE 4: NEARBY TOWN · Iron Bridge Town hub active. Visit Marketplace, Blacksmith Luo Jiwei, Inn Keeper Shu Yilan, and Notice Board.",
	[5] = "PHASE 5: CRAFTING EXPANSION (ACTIVE FOCUS) · Alchemy Cauldron & Blacksmith Anvil. 13 recipes across Elixirs, Weapons & Medicine.",
	[6] = "PHASE 6: MORTAL PEAK ARC · Sunder-Heart Palm technique, Wall-Faced Remnant ghost encounter, Qi circulation pressure & impurity control.",
	[7] = "PHASE 7: INNER SECT PATH (FUTURE) · Celestial Mountain Pagoda ascent. Orthodoxy vs Corrupted sects, discipline hall politics.",
}

for i = 1, 7 do
	local pNode = centerCanvas:FindFirstChild("PhaseNode_" .. i) :: Frame?
	if pNode then
		local clickDetector = Instance.new("TextButton")
		clickDetector.Name = "ClickDetector"
		clickDetector.BackgroundTransparency = 1
		clickDetector.Size = UDim2.new(1, 0, 1, 0)
		clickDetector.Text = ""
		clickDetector.ZIndex = 28
		clickDetector.Parent = pNode

		clickDetector.MouseButton1Click:Connect(function()
			lineBanner.Text = phaseDetails[i] or "DEVELOPMENT PROGRESS LINE - SPIRITUAL QI PATHWAY"
			local stroke = pNode:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = GuofengTheme.Colors.CyanBright
				task.delay(1.5, function()
					if stroke and stroke.Parent then
						stroke.Color = (i == 5) and GuofengTheme.Colors.GoldAmber or GuofengTheme.Colors.GoldBorderDim
					end
				end)
			end
		end)
	end
end

-- ============================================================================
-- 6. CULTIVATION & STATS BINDING
-- ============================================================================
local statNodes = cultModal:WaitForChild("StatNodes") :: Frame
local breakProgText = cultModal:WaitForChild("BreakProgressText") :: TextLabel
local scrollQiBar = cultModal:WaitForChild("ScrollQiBar") :: Frame
local scrollQiFill = scrollQiBar:WaitForChild("Fill") :: Frame
local cinnabarBtn = cultModal:WaitForChild("CinnabarActionBtn") :: TextButton
local destinyWheelBtn = cultModal:WaitForChild("DestinyWheelBtn") :: TextButton

local talentCrest = cultModal:WaitForChild("TalentCrest") :: Frame
local rootCrest = cultModal:WaitForChild("RootCrest") :: Frame

-- Forward declare updateWheelUI
local updateWheelUI: () -> () = function() end

local function updateStatsDisplay()
	local realm = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 0
	local qi = player:GetAttribute("Qi") or 0
	local maxHealth = player:GetAttribute("MaxHealth") or 100
	local defense = player:GetAttribute("Defense") or 5
	local damage = player:GetAttribute("Damage") or 15
	local weapon = player:GetAttribute("EquippedWeapon") or "None"
	local armor = player:GetAttribute("EquippedArmor") or "None"
	local cultivating = player:GetAttribute("Cultivating") or false

	local talentName = player:GetAttribute("Talent") or "Mortal"
	local talentEntry = DestinyConfig.GetTalent(talentName)
	local rootName = player:GetAttribute("SpiritualRoot") or "None"
	local rootEntry = DestinyConfig.GetSpiritualRoot(rootName)

	local reqQi = CultivationConfig.getRequiredQi(realm, level)

	-- Update HUD banners
	realmLabel.Text = string.format("* %s - LEVEL %d *", string.upper(realm), level)
	
	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
	local gold = goldVal and goldVal.Value or 50
	goldLabel.Text = string.format("%d SPIRIT STONES", gold)

	-- Update HUD Bars
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hp = hum and hum.Health or maxHealth
	local hpRatio = math.clamp(hp / math.max(1, maxHealth), 0, 1)
	TweenService:Create(hpFill, TweenInfo.new(0.2), { Size = UDim2.new(hpRatio, 0, 1, 0) }):Play()
	hpText.Text = string.format("HP: %d / %d", math.floor(hp), math.floor(maxHealth))

	local qiRatio = math.clamp(qi / math.max(1, reqQi), 0, 1)
	TweenService:Create(qiFill, TweenInfo.new(0.2), { Size = UDim2.new(qiRatio, 0, 1, 0) }):Play()
	qiText.Text = string.format("QI: %d / %d", math.floor(qi), reqQi)

	-- Update Cultivation Modal Stats
	local qiGatherVal = statNodes:WaitForChild("QiGather"):WaitForChild("Val") :: TextLabel
	local healthVal = statNodes:WaitForChild("Health"):WaitForChild("Val") :: TextLabel
	local defenseVal = statNodes:WaitForChild("Defense"):WaitForChild("Val") :: TextLabel
	local damageVal = statNodes:WaitForChild("Damage"):WaitForChild("Val") :: TextLabel
	local weaponVal = statNodes:WaitForChild("Weapon"):WaitForChild("Val") :: TextLabel
	local armorVal = statNodes:WaitForChild("Armor"):WaitForChild("Val") :: TextLabel

	local baseRate = cultivating and 10.0 or 5.0
	local totalMult = talentEntry.Multiplier * (rootEntry and rootEntry.Multiplier or 1.0)
	qiGatherVal.Text = string.format("%.1f/s (%s)", baseRate * totalMult, cultivating and "MEDITATING" or "IDLE")

	healthVal.Text = tostring(math.floor(maxHealth))
	defenseVal.Text = tostring(defense)
	damageVal.Text = tostring(damage)
	weaponVal.Text = weapon
	armorVal.Text = armor

	-- Update Flanking Crest Cards
	local talentVal = talentCrest:WaitForChild("Val") :: TextLabel
	local talentMultLbl = talentCrest:WaitForChild("Mult") :: TextLabel
	talentVal.Text = talentEntry.Name
	talentVal.TextColor3 = talentEntry.Color
	talentMultLbl.Text = string.format("x%.2f Qi Speed", talentEntry.Multiplier)

	local rootVal = rootCrest:WaitForChild("Val") :: TextLabel
	local rootMultLbl = rootCrest:WaitForChild("Mult") :: TextLabel
	if rootEntry then
		rootVal.Text = rootEntry.Name
		rootVal.TextColor3 = rootEntry.Color
		rootMultLbl.Text = string.format("x%.2f Qi Speed", rootEntry.Multiplier)
	else
		rootVal.Text = "None"
		rootVal.TextColor3 = GuofengTheme.Colors.TextMuted
		rootMultLbl.Text = "Spin to Awaken"
	end

	-- Breakthrough Requirement
	breakProgText.Text = string.format("BREAKTHROUGH REQUIREMENT: %d / %d QI", math.floor(qi), reqQi)
	TweenService:Create(scrollQiFill, TweenInfo.new(0.2), { Size = UDim2.new(qiRatio, 0, 1, 0) }):Play()

	-- Cinnabar Button
	if qi >= reqQi then
		cinnabarBtn.Text = "BREAKTHROUGH REALM"
		cinnabarBtn.BackgroundColor3 = GuofengTheme.Colors.Cinnabar
	else
		cinnabarBtn.Text = cultivating and "STOP MEDITATION" or "BEGIN MEDITATION"
		cinnabarBtn.BackgroundColor3 = cultivating and GuofengTheme.Colors.CyanDark or GuofengTheme.Colors.DarkJadeElevated
	end

	updateWheelUI()
end

cinnabarBtn.MouseButton1Click:Connect(function()
	local realm = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 0
	local qi = player:GetAttribute("Qi") or 0
	local reqQi = CultivationConfig.getRequiredQi(realm, level)

	if qi >= reqQi then
		remote:FireServer("Breakthrough")
		showNotification("Attempting Realm Breakthrough...", true)
	else
		remote:FireServer("Cultivate")
		local nowCult = not (player:GetAttribute("Cultivating") or false)
		showNotification(nowCult and "Spiritual meditation began." or "Spiritual meditation stopped.")
	end
end)

-- Open Destiny Wheel ONLY from the Cultivation Panel
destinyWheelBtn.MouseButton1Click:Connect(function()
	cultModal.Visible = false
	wheelModal.Visible = true
	updateWheelUI()
end)

-- ============================================================================
-- 7. DESTINY WHEEL CONTROLLER & VISUAL ENGINE
-- ============================================================================
local wheelHeader = wheelModal:WaitForChild("HeaderBanner") :: Frame
local wheelCloseBtn = wheelHeader:WaitForChild("CloseBtn") :: TextButton
local tabRow = wheelModal:WaitForChild("TabRow") :: Frame
local talentTabBtn = tabRow:WaitForChild("TalentTab") :: TextButton
local rootTabBtn = tabRow:WaitForChild("RootTab") :: TextButton

local leftCol = wheelModal:WaitForChild("LeftColumn") :: Frame
local wheelRim = leftCol:WaitForChild("WheelRim") :: Frame
local wheelDisc = wheelRim:WaitForChild("WheelDisc") :: Frame
local currentStatusLabel = leftCol:WaitForChild("CurrentStatus") :: TextLabel
local costInfoLabel = leftCol:WaitForChild("CostInfo") :: TextLabel
local spinActionBtn = leftCol:WaitForChild("SpinActionBtn") :: TextButton

local rightCol = wheelModal:WaitForChild("RightColumn") :: Frame
local tierScroll = rightCol:WaitForChild("TierScroll") :: ScrollingFrame

local winnerOverlay = wheelModal:WaitForChild("WinnerOverlay") :: Frame
local winnerCard = winnerOverlay:WaitForChild("Card") :: Frame
local winTag = winnerCard:WaitForChild("Tag") :: TextLabel
local winName = winnerCard:WaitForChild("Name") :: TextLabel
local winMult = winnerCard:WaitForChild("Multiplier") :: TextLabel
local winDesc = winnerCard:WaitForChild("Desc") :: TextLabel
local winDismissBtn = winnerCard:WaitForChild("DismissBtn") :: TextButton

local currentWheelTab = "Talent"
local isWheelSpinning = false

wheelCloseBtn.MouseButton1Click:Connect(function()
	if isWheelSpinning then return end
	wheelModal.Visible = false
	cultModal.Visible = true
end)

winDismissBtn.MouseButton1Click:Connect(function()
	winnerOverlay.Visible = false
end)

local function renderWheelDisc()
	for _, child in ipairs(wheelDisc:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local entries = (currentWheelTab == "Talent") and DestinyConfig.TALENTS or DestinyConfig.SPIRITUAL_ROOTS
	local count = #entries
	local sliceAngle = 360 / count

	for i, entry in ipairs(entries) do
		local angle = (i - 1) * sliceAngle

		local spoke = Instance.new("Frame")
		spoke.Name = "Spoke_" .. tostring(i)
		spoke.BackgroundTransparency = 1
		spoke.AnchorPoint = Vector2.new(0.5, 0.5)
		spoke.Position = UDim2.new(0.5, 0, 0.5, 0)
		spoke.Size = UDim2.new(1, 0, 1, 0)
		spoke.Rotation = angle
		spoke.ZIndex = 33
		spoke.Parent = wheelDisc

		local pin = Instance.new("Frame")
		pin.Name = "Pin"
		pin.BackgroundColor3 = entry.Color
		pin.BorderSizePixel = 0
		pin.AnchorPoint = Vector2.new(0.5, 0)
		pin.Position = UDim2.new(0.5, 0, 0, 6)
		pin.Size = UDim2.new(0, 7, 0, 7)
		pin.ZIndex = 33
		pin.Parent = spoke

		local pinCorner = Instance.new("UICorner")
		pinCorner.CornerRadius = UDim.new(1, 0)
		pinCorner.Parent = pin

		local line = Instance.new("Frame")
		line.Name = "Line"
		line.BackgroundColor3 = entry.Color
		line.BackgroundTransparency = 0.4
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 0)
		line.Position = UDim2.new(0.5, 0, 0, 15)
		line.Size = UDim2.new(0, 1, 0, 22)
		line.ZIndex = 33
		line.Parent = spoke

		local sliceLabel = Instance.new("TextLabel")
		sliceLabel.Name = "Label"
		sliceLabel.BackgroundTransparency = 1
		sliceLabel.AnchorPoint = Vector2.new(0.5, 0)
		sliceLabel.Position = UDim2.new(0.5, 0, 0, 38)
		sliceLabel.Size = UDim2.new(0, 56, 0, 14)
		sliceLabel.Font = GuofengTheme.Fonts.Header
		if currentWheelTab == "Talent" then
			sliceLabel.Text = string.format("x%.1f", entry.Multiplier)
		else
			local shortName = entry.Name:gsub(" Root", "")
			sliceLabel.Text = shortName
		end
		sliceLabel.TextColor3 = entry.Color
		sliceLabel.TextSize = 9
		sliceLabel.ZIndex = 33
		sliceLabel.Parent = spoke
	end
end

local function renderTierReferenceList()
	for _, child in ipairs(tierScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local entries = (currentWheelTab == "Talent") and DestinyConfig.TALENTS or DestinyConfig.SPIRITUAL_ROOTS
	local currentEquipped = (currentWheelTab == "Talent") and (player:GetAttribute("Talent") or "Mortal") or (player:GetAttribute("SpiritualRoot") or "None")

	for idx, entry in ipairs(entries) do
		local isEquipped = (entry.Name == currentEquipped)

		local card = Instance.new("Frame")
		card.Name = entry.Name
		card.LayoutOrder = idx
		card.BackgroundColor3 = isEquipped and GuofengTheme.Colors.DarkJadeElevated or GuofengTheme.Colors.DarkJadeCard
		card.BorderSizePixel = 0
		card.Size = UDim2.new(1, -6, 0, 28)
		card.ZIndex = 33
		card.Parent = tierScroll

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 5)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = isEquipped and GuofengTheme.Colors.GoldBorder or GuofengTheme.Colors.GoldBorderDim
		cardStroke.Thickness = isEquipped and 1.5 or 1
		cardStroke.Parent = card

		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.BackgroundColor3 = entry.Color
		bar.BorderSizePixel = 0
		bar.Position = UDim2.new(0, 0, 0, 0)
		bar.Size = UDim2.new(0, 5, 1, 0)
		bar.ZIndex = 34
		bar.Parent = card

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(0, 3)
		barCorner.Parent = bar

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "Name"
		nameLbl.BackgroundTransparency = 1
		nameLbl.Position = UDim2.new(0, 12, 0, 0)
		nameLbl.Size = UDim2.new(0.48, -12, 1, 0)
		nameLbl.Font = GuofengTheme.Fonts.Header
		nameLbl.Text = entry.Name .. (isEquipped and " [ACTIVE]" or "")
		nameLbl.TextColor3 = entry.Color
		nameLbl.TextSize = 11
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.ZIndex = 34
		nameLbl.Parent = card

		local multLbl = Instance.new("TextLabel")
		multLbl.Name = "Multiplier"
		multLbl.BackgroundTransparency = 1
		multLbl.Position = UDim2.new(0.48, 0, 0, 0)
		multLbl.Size = UDim2.new(0.24, 0, 1, 0)
		multLbl.Font = GuofengTheme.Fonts.Body
		multLbl.Text = string.format("x%.2f Mult", entry.Multiplier)
		multLbl.TextColor3 = GuofengTheme.Colors.GoldLight
		multLbl.TextSize = 10
		multLbl.TextXAlignment = Enum.TextXAlignment.Center
		multLbl.ZIndex = 34
		multLbl.Parent = card

		local chanceLbl = Instance.new("TextLabel")
		chanceLbl.Name = "Chance"
		chanceLbl.BackgroundTransparency = 1
		chanceLbl.Position = UDim2.new(0.72, 0, 0, 0)
		chanceLbl.Size = UDim2.new(0.28, -6, 1, 0)
		chanceLbl.Font = GuofengTheme.Fonts.Header
		chanceLbl.Text = string.format("%.2f%%", entry.Chance)
		chanceLbl.TextColor3 = GuofengTheme.Colors.TextMuted
		chanceLbl.TextSize = 11
		chanceLbl.TextXAlignment = Enum.TextXAlignment.Right
		chanceLbl.ZIndex = 34
		chanceLbl.Parent = card
	end

	tierScroll.CanvasSize = UDim2.new(0, 0, 0, #entries * 32)
end

updateWheelUI = function()
	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") and (leaderstats:FindFirstChild("Gold") :: IntValue).Value or 0
	local spinsUsed = player:GetAttribute("SpinsUsed") or 0
	local isFree = (spinsUsed == 0)

	local tStroke = talentTabBtn:FindFirstChildOfClass("UIStroke")
	local rStroke = rootTabBtn:FindFirstChildOfClass("UIStroke")

	if currentWheelTab == "Talent" then
		talentTabBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
		if tStroke then
			tStroke.Color = GuofengTheme.Colors.GoldBorder
			tStroke.Thickness = 1.5
		end
		talentTabBtn.TextColor3 = GuofengTheme.Colors.GoldLight

		rootTabBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
		if rStroke then
			rStroke.Color = GuofengTheme.Colors.GoldBorderDim
			rStroke.Thickness = 1
		end
		rootTabBtn.TextColor3 = GuofengTheme.Colors.TextMuted

		local tName = player:GetAttribute("Talent") or "Mortal"
		local tEntry = DestinyConfig.GetTalent(tName)
		currentStatusLabel.Text = string.format("Current Talent: %s (x%.2f Qi Speed)", tEntry.Name, tEntry.Multiplier)
		currentStatusLabel.TextColor3 = tEntry.Color

		spinActionBtn.Text = isFree and "FREE INITIAL TALENT SPIN" or "SPIN TALENT (50 STONES)"
	else
		rootTabBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
		if rStroke then
			rStroke.Color = GuofengTheme.Colors.CyanBright
			rStroke.Thickness = 1.5
		end
		rootTabBtn.TextColor3 = GuofengTheme.Colors.CyanBright

		talentTabBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
		if tStroke then
			tStroke.Color = GuofengTheme.Colors.GoldBorderDim
			tStroke.Thickness = 1
		end
		talentTabBtn.TextColor3 = GuofengTheme.Colors.TextMuted

		local rName = player:GetAttribute("SpiritualRoot") or "None"
		local rEntry = DestinyConfig.GetSpiritualRoot(rName)
		if rEntry then
			currentStatusLabel.Text = string.format("Current Root: %s (x%.2f Qi Speed)", rEntry.Name, rEntry.Multiplier)
			currentStatusLabel.TextColor3 = rEntry.Color
		else
			currentStatusLabel.Text = "Current Root: None (Spin to awaken!)"
			currentStatusLabel.TextColor3 = GuofengTheme.Colors.TextMuted
		end

		spinActionBtn.Text = isFree and "FREE INITIAL ROOT SPIN" or "SPIN ROOT (50 STONES)"
	end

	costInfoLabel.Text = string.format("Cost: %s · Spirit Stones: %d", isFree and "FREE" or "50 Stones", goldVal)
	renderWheelDisc()
	renderTierReferenceList()
end

talentTabBtn.MouseButton1Click:Connect(function()
	if isWheelSpinning then return end
	currentWheelTab = "Talent"
	updateWheelUI()
end)

rootTabBtn.MouseButton1Click:Connect(function()
	if isWheelSpinning then return end
	currentWheelTab = "SpiritualRoot"
	updateWheelUI()
end)

spinActionBtn.MouseButton1Click:Connect(function()
	if isWheelSpinning then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") and (leaderstats:FindFirstChild("Gold") :: IntValue).Value or 0
	local spinsUsed = player:GetAttribute("SpinsUsed") or 0
	local isFree = (spinsUsed == 0)

	if not isFree and goldVal < DestinyConfig.SPIN_COST then
		showNotification("Not enough Spirit Stones! You need 50 Spirit Stones.", true)
		return
	end

	isWheelSpinning = true
	spinActionBtn.Text = "AWAKENING DESTINY..."
	spinActionBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated

	remote:FireServer("SpinWheel", currentWheelTab)
end)

-- ============================================================================
-- 8. INVENTORY MODAL BINDING
-- ============================================================================
local invItemList = invModal:WaitForChild("ItemList") :: ScrollingFrame

local function refreshInventoryUI()
	for _, ch in ipairs(invItemList:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	local inventory = player:FindFirstChild("Inventory")
	if not inventory then return end

	local items = inventory:GetChildren()
	for _, itmVal in ipairs(items) do
		if itmVal:IsA("IntValue") and itmVal.Value > 0 then
			local itemDef = ItemConfig.getItem(itmVal.Name)
			if itemDef then
				local card = GuofengTheme.createParchmentCard(invItemList, UDim2.new(1, 0, 0, 68), UDim2.new(0, 0, 0, 0))
				card.Name = itmVal.Name

				local nameLbl = card:WaitForChild("Name") :: TextLabel
				nameLbl.Text = string.format("%s  [x%d]", itemDef.Name, itmVal.Value)

				local descLbl = card:WaitForChild("Desc") :: TextLabel
				descLbl.Text = itemDef.Description or "Spiritual item."

				local useBtn = Instance.new("TextButton")
				useBtn.Name = "UseBtn"
				useBtn.Size = UDim2.new(0, 80, 0, 32)
				useBtn.Position = UDim2.new(1, -92, 0.5, -16)
				useBtn.BackgroundColor3 = GuofengTheme.Colors.CyanDark
				useBtn.Font = GuofengTheme.Fonts.Header
				useBtn.Text = (itemDef.Type == "Weapon" or itemDef.Type == "Armor") and "EQUIP" or "USE"
				useBtn.TextColor3 = GuofengTheme.Colors.TextWhite
				useBtn.TextSize = 12
				useBtn.ZIndex = 25
				useBtn.Parent = card

				local uCorner = Instance.new("UICorner")
				uCorner.CornerRadius = UDim.new(0, 4)
				uCorner.Parent = useBtn

				useBtn.MouseButton1Click:Connect(function()
					if itemDef.Type == "Weapon" or itemDef.Type == "Armor" then
						remote:FireServer("EquipItem", itemDef.Name)
					else
						remote:FireServer("UseItem", itemDef.Name)
					end
				end)
			end
		end
	end
end

-- ============================================================================
-- 9. SHOP MODAL BINDING
-- ============================================================================
local shopItemList = shopModal:WaitForChild("ShopList") :: ScrollingFrame

local function populateShop()
	for _, ch in ipairs(shopItemList:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	for _, item in ipairs(ItemConfig.Catalog) do
		local card = GuofengTheme.createParchmentCard(shopItemList, UDim2.new(1, 0, 0, 72), UDim2.new(0, 0, 0, 0))
		card.Name = item.Name

		local nameLbl = card:WaitForChild("Name") :: TextLabel
		nameLbl.Text = item.Name

		local descLbl = card:WaitForChild("Desc") :: TextLabel
		descLbl.Text = item.Description or "Spiritual item."

		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyBtn"
		buyBtn.Size = UDim2.new(0, 100, 0, 32)
		buyBtn.Position = UDim2.new(1, -112, 0.5, -16)
		buyBtn.BackgroundColor3 = GuofengTheme.Colors.GoldDark
		buyBtn.Font = GuofengTheme.Fonts.Header
		buyBtn.Text = string.format("%d STONES", item.Price)
		buyBtn.TextColor3 = GuofengTheme.Colors.GoldLight
		buyBtn.TextSize = 12
		buyBtn.ZIndex = 25
		buyBtn.Parent = card

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 4)
		bCorner.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			remote:FireServer("BuyItem", item.Name)
		end)
	end
end
populateShop()

-- ============================================================================
-- 10. REMOTE EVENTS & ATTRIBUTE LISTENERS
-- ============================================================================
remote.OnClientEvent:Connect(function(event: string, ...)
	local args = { ... }
	if event == "MeditationStart" then
		startMeditationAnimation()
	elseif event == "MeditationStop" then
		stopMeditationAnimation()
	elseif event == "QiGainTick" then
		local gain = args[1] or 10
		showQiGainPopup(gain)
	elseif event == "BreakthroughStart" then
		showNotification("Heavenly Tribulation Surpassed! Realm Breakthrough Complete!", true)
	elseif event == "SpinResult" then
		local wheelType = args[1]
		local resultIndex = args[2]
		local resultName = args[3]
		local resultMultiplier = args[4]

		local count = (wheelType == "Talent") and #DestinyConfig.TALENTS or #DestinyConfig.SPIRITUAL_ROOTS
		local sliceAngle = 360 / count
		local targetSliceAngle = (360 - ((resultIndex - 1) * sliceAngle)) % 360

		local curRot = wheelDisc.Rotation
		local spins = 5 * 360
		local currentNormalized = curRot % 360
		local deltaAngle = (targetSliceAngle - currentNormalized)
		if deltaAngle < 0 then
			deltaAngle = deltaAngle + 360
		end
		local finalRotation = curRot + spins + deltaAngle

		local spinTween = TweenService:Create(wheelDisc, TweenInfo.new(3.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Rotation = finalRotation
		})
		spinTween:Play()
		spinTween.Completed:Wait()

		isWheelSpinning = false
		updateWheelUI()
		updateStatsDisplay()

		winTag.Text = (wheelType == "Talent") and "DESTINY TALENT AWAKENED" or "SPIRITUAL ROOT AWAKENED"
		winName.Text = resultName

		local entry = (wheelType == "Talent") and DestinyConfig.GetTalent(resultName) or DestinyConfig.GetSpiritualRoot(resultName)
		if entry then
			winName.TextColor3 = entry.Color
			local wCardStroke = winnerCard:FindFirstChildOfClass("UIStroke")
			if wCardStroke then
				wCardStroke.Color = entry.Color
			end
			winDesc.Text = entry.Description
		end

		winMult.Text = string.format("Cultivation Qi Gather Speed: x%.2f Multiplier", resultMultiplier)
		winnerOverlay.Visible = true

		task.delay(4.5, function()
			if winnerOverlay.Visible then
				winnerOverlay.Visible = false
			end
		end)
	end
end)

for _, attr in ipairs({ "Qi", "Realm", "RealmLevel", "Cultivating", "Damage", "Defense", "MaxHealth", "EquippedWeapon", "EquippedArmor", "Talent", "SpiritualRoot", "SpinsUsed" }) do
	player:GetAttributeChangedSignal(attr):Connect(function()
		updateStatsDisplay()
	end)
end

local leaderstats = player:WaitForChild("leaderstats", 10)
if leaderstats then
	local goldVal = leaderstats:WaitForChild("Gold", 5) :: IntValue?
	if goldVal then
		goldVal.Changed:Connect(function()
			updateStatsDisplay()
		end)
	end
	local qiVal = leaderstats:WaitForChild("Qi", 5) :: IntValue?
	if qiVal then
		qiVal.Changed:Connect(function()
			updateStatsDisplay()
		end)
	end
end

local inventory = player:WaitForChild("Inventory", 10)
if inventory then
	inventory.ChildAdded:Connect(refreshInventoryUI)
	inventory.ChildRemoved:Connect(refreshInventoryUI)
	for _, child in ipairs(inventory:GetChildren()) do
		if child:IsA("IntValue") then
			child.Changed:Connect(refreshInventoryUI)
		end
	end
end

updateStatsDisplay()
refreshInventoryUI()
"""

# Save to local files
print("Saving scripts to local workspace...")
Path("src/server/DATA.server.luau").write_text(DATA_SRC, encoding="utf-8")
Path("src/server/MAINSERVER.server.luau").write_text(MAINSERVER_SRC, encoding="utf-8")
Path("src/gui/CultivationClient.client.luau").write_text(CULTIVATION_CLIENT_SRC, encoding="utf-8")
Path("src/ui/CultivationClient.client.luau").write_text(CULTIVATION_CLIENT_SRC, encoding="utf-8")

# Inject into Studio
print("Injecting DATA script into Studio...")
lua_data = f"""
local sss = game:GetService("ServerScriptService")
local server = sss:WaitForChild("Server")
local dataScript = server:WaitForChild("DATA")
dataScript.Source = [====[{DATA_SRC}]====]
return "Injected DATA script"
"""
ok, res = exec_code(lua_data)
print("  DATA inject:", ok, res)

print("Injecting MAINSERVER script into Studio...")
lua_mainserver = f"""
local sss = game:GetService("ServerScriptService")
local server = sss:WaitForChild("Server")
local mainScript = server:WaitForChild("MAINSERVER")
mainScript.Source = [====[{MAINSERVER_SRC}]====]
return "Injected MAINSERVER script"
"""
ok, res = exec_code(lua_mainserver)
print("  MAINSERVER inject:", ok, res)

print("Injecting CultivationClient script into Studio...")
lua_client = f"""
local sg = game:GetService("StarterGui")
local cultUI = sg:WaitForChild("CultivationUI")
local clientScript = cultUI:WaitForChild("CultivationClient")
clientScript.Source = [====[{CULTIVATION_CLIENT_SRC}]====]
return "Injected CultivationClient script"
"""
ok, res = exec_code(lua_client)
print("  CultivationClient inject:", ok, res)

print("Deployment finished successfully!")

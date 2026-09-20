--!strict
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

local remote = ReplicatedStorage:WaitForChild("CultivationRemote") :: RemoteEvent

-- ============================================================================
-- 2. WAIT FOR PRE-BUILT STARTERGUI HIERARCHY
-- ============================================================================
local hud = ui:WaitForChild("GuofengHUD") :: Frame
local roadmapModal = ui:WaitForChild("RoadmapModal") :: Frame
local cultModal = ui:WaitForChild("CultivationScrollModal") :: Frame
local invModal = ui:WaitForChild("InventoryScrollModal") :: Frame
local shopModal = ui:WaitForChild("ShopScrollModal") :: Frame

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

	-- Use Roblox sit animation as meditation pose
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://2506281703" -- Sitting idle animation

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

-- Wire HUD Navigation Buttons
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

	qiGatherVal.Text = cultivating and "10.0/s (MEDITATING)" or "5.0/s (IDLE)"
	healthVal.Text = tostring(math.floor(maxHealth))
	defenseVal.Text = tostring(defense)
	damageVal.Text = tostring(damage)
	weaponVal.Text = weapon
	armorVal.Text = armor

	-- Breakthrough Requirement
	breakProgText.Text = string.format("BREAKTHROUGH REQUIREMENT: %d / %d QI", math.floor(qi), reqQi)
	TweenService:Create(scrollQiFill, TweenInfo.new(0.2), { Size = UDim2.new(qiRatio, 0, 1, 0) }):Play()

	-- Cinnabar Button: Meditate vs Breakthrough
	if qi >= reqQi then
		cinnabarBtn.Text = "BREAKTHROUGH REALM"
		cinnabarBtn.BackgroundColor3 = GuofengTheme.Colors.Cinnabar
	else
		cinnabarBtn.Text = cultivating and "STOP MEDITATION" or "BEGIN MEDITATION"
		cinnabarBtn.BackgroundColor3 = cultivating and GuofengTheme.Colors.CyanDark or GuofengTheme.Colors.DarkJadeElevated
	end
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

-- ============================================================================
-- 7. INVENTORY MODAL BINDING
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

				-- Circular Emblem for Icon (High contrast framing)
				local emblem = Instance.new("Frame")
				emblem.Name = "Emblem"
				emblem.BackgroundColor3 = GuofengTheme.Colors.DarkJadeHeader
				emblem.Size = UDim2.new(0, 48, 0, 48)
				emblem.Position = UDim2.new(0, 8, 0, 10)
				emblem.BorderSizePixel = 0
				emblem.Parent = card

				local emc = Instance.new("UICorner")
				emc.CornerRadius = UDim.new(1, 0)
				emc.Parent = emblem

				local ems = Instance.new("UIStroke")
				ems.Color = GuofengTheme.Colors.GoldBorder
				ems.Thickness = 1.2
				ems.Parent = emblem

				local itemAssetId = IconAssets.getItemIcon(itmVal.Name)
				if IconAssets.isUploaded(itemAssetId) then
					local img = Instance.new("ImageLabel")
					img.BackgroundTransparency = 1
					img.Size = UDim2.new(1, 0, 1, 0)
					img.Image = itemAssetId
					img.ScaleType = Enum.ScaleType.Fit
					img.Parent = emblem
				else
					local iconLab = Instance.new("TextLabel")
					iconLab.BackgroundTransparency = 1
					iconLab.Size = UDim2.new(1, 0, 1, 0)
					iconLab.Font = GuofengTheme.Fonts.Title
					iconLab.Text = itemDef.Icon or "-"
					iconLab.TextSize = 24
					iconLab.TextColor3 = Color3.fromRGB(255, 255, 255)
					iconLab.Parent = emblem
				end

				-- Name & Quantity
				local nameLab = Instance.new("TextLabel")
				nameLab.BackgroundTransparency = 1
				nameLab.Size = UDim2.new(0, 240, 0, 22)
				nameLab.Position = UDim2.new(0, 64, 0, 10)
				nameLab.Font = GuofengTheme.Fonts.Header
				nameLab.Text = string.format("%s (x%d)", itemDef.Name, itmVal.Value)
				nameLab.TextColor3 = GuofengTheme.Colors.GoldLight
				nameLab.TextSize = 13
				nameLab.TextXAlignment = Enum.TextXAlignment.Left
				nameLab.Parent = card

				-- Description / Stats
				local descLab = Instance.new("TextLabel")
				descLab.BackgroundTransparency = 1
				descLab.Size = UDim2.new(0, 240, 0, 20)
				descLab.Position = UDim2.new(0, 64, 0, 32)
				descLab.Font = GuofengTheme.Fonts.Body
				descLab.Text = itemDef.Description or ""
				descLab.TextColor3 = GuofengTheme.Colors.TextMuted
				descLab.TextSize = 11
				descLab.TextXAlignment = Enum.TextXAlignment.Left
				descLab.Parent = card

				-- Action Button (Use or Equip)
				local actBtn = GuofengTheme.createXianxiaActionButton(
					card,
					itemDef.Type == "Pill" and "USE" or "EQUIP",
					UDim2.new(0, 92, 0, 34),
					UDim2.new(1, -100, 0, 17),
					itemDef.Type == "Pill"
				)
				actBtn.TextSize = 12

				actBtn.MouseButton1Click:Connect(function()
					if itemDef.Type == "Pill" then
						remote:FireServer("UseItem", itmVal.Name)
						showNotification("Consumed " .. itemDef.Name)
					else
						remote:FireServer("EquipItem", itmVal.Name)
						showNotification("Equipped " .. itemDef.Name)
					end
				end)
			end
		end
	end
end

-- ============================================================================
-- 8. SHOP MODAL BINDING
-- ============================================================================
local shopItemList = shopModal:WaitForChild("ShopItemList") :: ScrollingFrame

local function populateShopUI()
	for _, ch in ipairs(shopItemList:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	for _, itemDef in pairs(ItemConfig.Items) do
		local card = GuofengTheme.createParchmentCard(shopItemList, UDim2.new(1, 0, 0, 68), UDim2.new(0, 0, 0, 0))
		card.Name = itemDef.Id

		-- Circular Emblem for Icon (High contrast framing)
		local emblem = Instance.new("Frame")
		emblem.Name = "Emblem"
		emblem.BackgroundColor3 = GuofengTheme.Colors.DarkJadeHeader
		emblem.Size = UDim2.new(0, 48, 0, 48)
		emblem.Position = UDim2.new(0, 8, 0, 10)
		emblem.BorderSizePixel = 0
		emblem.Parent = card

		local emc = Instance.new("UICorner")
		emc.CornerRadius = UDim.new(1, 0)
		emc.Parent = emblem

		local ems = Instance.new("UIStroke")
		ems.Color = GuofengTheme.Colors.GoldBorder
		ems.Thickness = 1.2
		ems.Parent = emblem

		local itemAssetId = IconAssets.getItemIcon(itemDef.Name)
		if IconAssets.isUploaded(itemAssetId) then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.new(1, 0, 1, 0)
			img.Image = itemAssetId
			img.ScaleType = Enum.ScaleType.Fit
			img.Parent = emblem
		else
			local iconLab = Instance.new("TextLabel")
			iconLab.BackgroundTransparency = 1
			iconLab.Size = UDim2.new(1, 0, 1, 0)
			iconLab.Font = GuofengTheme.Fonts.Title
			iconLab.Text = itemDef.Icon or "-"
			iconLab.TextSize = 24
			iconLab.TextColor3 = Color3.fromRGB(255, 255, 255)
			iconLab.Parent = emblem
		end

		-- Name & Price
		local nameLab = Instance.new("TextLabel")
		nameLab.BackgroundTransparency = 1
		nameLab.Size = UDim2.new(0, 240, 0, 22)
		nameLab.Position = UDim2.new(0, 64, 0, 10)
		nameLab.Font = GuofengTheme.Fonts.Header
		nameLab.Text = string.format("%s - %d Gold", itemDef.Name, itemDef.Price)
		nameLab.TextColor3 = GuofengTheme.Colors.GoldLight
		nameLab.TextSize = 13
		nameLab.TextXAlignment = Enum.TextXAlignment.Left
		nameLab.Parent = card

		-- Description / Effect
		local descLab = Instance.new("TextLabel")
		descLab.BackgroundTransparency = 1
		descLab.Size = UDim2.new(0, 240, 0, 20)
		descLab.Position = UDim2.new(0, 64, 0, 32)
		descLab.Font = GuofengTheme.Fonts.Body
		descLab.Text = itemDef.Description or ""
		descLab.TextColor3 = GuofengTheme.Colors.TextMuted
		descLab.TextSize = 11
		descLab.TextXAlignment = Enum.TextXAlignment.Left
		descLab.Parent = card

		-- Purchase Button
		local buyBtn = GuofengTheme.createXianxiaActionButton(
			card,
			"PURCHASE",
			UDim2.new(0, 96, 0, 34),
			UDim2.new(1, -106, 0, 17),
			false
		)
		buyBtn.TextSize = 12

		buyBtn.MouseButton1Click:Connect(function()
			remote:FireServer("BuyItem", itemDef.Id)
		end)
	end
end

-- ============================================================================
-- 9. INITIALIZE & LISTENERS
-- ============================================================================
populateShopUI()

player:GetAttributeChangedSignal("Qi"):Connect(updateStatsDisplay)
player:GetAttributeChangedSignal("Realm"):Connect(updateStatsDisplay)
player:GetAttributeChangedSignal("RealmLevel"):Connect(updateStatsDisplay)
player:GetAttributeChangedSignal("MaxHealth"):Connect(updateStatsDisplay)
player:GetAttributeChangedSignal("Defense"):Connect(updateStatsDisplay)
player:GetAttributeChangedSignal("Damage"):Connect(updateStatsDisplay)
player:GetAttributeChangedSignal("Cultivating"):Connect(updateStatsDisplay)
player:GetAttributeChangedSignal("EquippedWeapon"):Connect(updateStatsDisplay)
player:GetAttributeChangedSignal("EquippedArmor"):Connect(updateStatsDisplay)

local leaderstats = player:WaitForChild("leaderstats", 10)
if leaderstats then
	local goldVal = leaderstats:WaitForChild("Gold", 5)
	if goldVal then
		goldVal.Changed:Connect(updateStatsDisplay)
	end
end

local inv = player:WaitForChild("Inventory", 10)
if inv then
	inv.ChildAdded:Connect(refreshInventoryUI)
	inv.ChildRemoved:Connect(refreshInventoryUI)
	for _, c in ipairs(inv:GetChildren()) do
		if c:IsA("IntValue") then
			c.Changed:Connect(refreshInventoryUI)
		end
	end
end

-- Health changes on Character
local function bindCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	if hum then
		hum.HealthChanged:Connect(updateStatsDisplay)
	end
	updateStatsDisplay()
end

if player.Character then
	bindCharacter(player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

-- Server remote listener for breakthroughs and notices
remote.OnClientEvent:Connect(function(action: string, ...)
	local args = { ... }
	if action == "BreakthroughStart" then
		showNotification("Realm Breakthrough Achieved!", true)
		updateStatsDisplay()
	elseif action == "Notification" then
		showNotification(args[1] or "")
	elseif action == "OpenShop" then
		toggleModal(shopModal)
	elseif action == "MeditationStart" then
		startMeditationAnimation()
	elseif action == "MeditationStop" then
		stopMeditationAnimation()
	elseif action == "QiGainTick" then
		local amount = args[1] or 0
		if amount > 0 then
			showQiGainPopup(amount)
		end
	end
end)

-- Initial stats paint
updateStatsDisplay()
refreshInventoryUI()

print("[CultivationClient] Xianxia RPG UI initialized cleanly with zero Chinese text.")

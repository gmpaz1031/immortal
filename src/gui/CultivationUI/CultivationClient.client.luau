--!strict
-- src/gui/CultivationUI/CultivationClient.client.luau
-- Xianxia RPG UI Controller (Dark Jade, Imperial Gold Filigree & Luminous Cyan Qi)
-- Binds cleanly to the pre-built StarterGui hierarchy.
-- Zero Chinese text, pure English UI.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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
-- 2. BIND TO USER'S STARTERGUI HIERARCHY
-- ============================================================================
local roadmapModal = ui:WaitForChild("RoadmapModal") :: Frame
local cultModal = ui:WaitForChild("CultivationScrollModal") :: Frame
local invModal = ui:WaitForChild("InventoryScrollModal") :: Frame
local shopModal = ui:WaitForChild("ShopScrollModal") :: Frame
local wheelModal = ui:WaitForChild("DestinyWheelModal") :: Frame

-- Direct Navigation Row
local navRow = ui:WaitForChild("NavRow") :: Frame
local roadmapNavBtn = navRow:WaitForChild("RoadmapNavBtn") :: TextButton
local cultNavBtn = navRow:WaitForChild("CultNavBtn") :: TextButton
local invNavBtn = navRow:WaitForChild("InvNavBtn") :: TextButton
local shopNavBtn = navRow:WaitForChild("ShopNavBtn") :: TextButton

-- User Custom Bottom Status Bar
local hpBar = ui:WaitForChild("HPBar") :: Frame
local hpFill = hpBar:WaitForChild("Fill") :: Frame
local hpText = hpBar:WaitForChild("Text") :: TextLabel

local qiBar = ui:WaitForChild("QiBar") :: Frame
local qiFill = qiBar:WaitForChild("Fill") :: Frame
local qiText = qiBar:WaitForChild("Text") :: TextLabel

local goldLabel = ui:WaitForChild("GoldLabel") :: TextLabel
local realmLabel = ui:WaitForChild("RealmLabel") :: TextLabel

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
-- 3b. FLOATING QI GAIN POPUP (Luminous Animated Screen Floater)
-- ============================================================================
local function showQiGainPopup(amount: number)
	local popup = Instance.new("TextLabel")
	popup.Name = "QiGainPopup"
	popup.BackgroundTransparency = 1
	popup.AnchorPoint = Vector2.new(0.5, 0.5)
	local xOffset = math.random(-80, 80)
	local startY = 0.50 + (math.random(-15, 15) / 1000)
	popup.Position = UDim2.new(0.5, xOffset, startY, 0)
	popup.Size = UDim2.new(0, 180, 0, 40)
	popup.Font = Enum.Font.GothamBlack
	popup.Text = string.format("+%d QI", amount)
	popup.TextColor3 = Color3.fromRGB(80, 255, 215) -- Luminous Celestial Cyan
	popup.TextSize = 22
	popup.ZIndex = 85
	popup.Parent = ui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(12, 45, 38)
	stroke.Thickness = 2.0
	stroke.Transparency = 0.1
	stroke.Parent = popup

	task.spawn(function()
		local endY = startY - 0.14
		local floatTween = TweenService:Create(popup, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, xOffset, endY, 0),
		})
		floatTween:Play()

		task.wait(0.5)
		local fadeText = TweenService:Create(popup, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {
			TextTransparency = 1,
		})
		local fadeStroke = TweenService:Create(stroke, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {
			Transparency = 1,
		})
		fadeText:Play()
		fadeStroke:Play()
		fadeText.Completed:Wait()
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

-- Forward declarations for modal refresh handlers
local refreshInventoryUI: () -> ()
local populateShop: () -> ()
local updateStatsDisplay: () -> ()

local function toggleModal(modal: Frame)
	local target = not modal.Visible
	closeAllModals()
	modal.Visible = target
	if target and modal == invModal and refreshInventoryUI then
		pcall(refreshInventoryUI)
	elseif target and modal == shopModal and populateShop then
		pcall(populateShop)
	elseif target and modal == cultModal and updateStatsDisplay then
		pcall(updateStatsDisplay)
	end
end

-- Wire close buttons safely without blocking threads
local function wireCloseBtn(modal: Frame)
	local btn = modal:FindFirstChild("CloseBtn", true) or modal:WaitForChild("CloseBtn", 3)
	if btn then
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				modal.Visible = false
			end
		end)
	end
end

wireCloseBtn(roadmapModal)
wireCloseBtn(cultModal)
wireCloseBtn(invModal)
wireCloseBtn(shopModal)

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

-- Keybinds: M = Roadmap, K = Cultivation Panel, C = Cultivate (Meditate), B = Inventory, N = Shop
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then return end

	if input.KeyCode == Enum.KeyCode.M then
		toggleModal(roadmapModal)
	elseif input.KeyCode == Enum.KeyCode.K then
		toggleModal(cultModal)
	elseif input.KeyCode == Enum.KeyCode.C then
		-- Cultivate (sitting meditation position & Qi gathering)
		remote:FireServer("Cultivate")
		local nowCult = not (player:GetAttribute("Cultivating") or false)
		showNotification(nowCult and "Spiritual meditation began." or "Spiritual meditation stopped.")
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
	[1] = "PHASE 1: ENEMY ROSTER EXPANSION - Spirit Boars, Shadow Vipers, Cloud Stags & Bandit Scouts populated across the outer wild valleys.",
	[2] = "PHASE 2: TECHNIQUE EXPANSION - Iron Body (Defense), Wind Blade (Slash), Void Step (Dash) unlocked with rank 5 passive masteries.",
	[3] = "PHASE 3: FIRST DUNGEON - The Black-Thread Hollow (22 scenes). Three branching paths: Combat, Stealth, and Lore. Boss: Cultist Leader.",
	[4] = "PHASE 4: NEARBY TOWN - Iron Bridge Town hub active. Visit Marketplace, Blacksmith Luo Jiwei, Inn Keeper Shu Yilan, and Notice Board.",
	[5] = "PHASE 5: CRAFTING EXPANSION (ACTIVE FOCUS) - Alchemy Cauldron & Blacksmith Anvil. 13 recipes across Elixirs, Weapons & Medicine.",
	[6] = "PHASE 6: MORTAL PEAK ARC - Sunder-Heart Palm technique, Wall-Faced Remnant ghost encounter, Qi circulation pressure & impurity control.",
	[7] = "PHASE 7: INNER SECT PATH (FUTURE) - Celestial Mountain Pagoda ascent. Orthodoxy vs Corrupted sects, discipline hall politics.",
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

-- Pre-cache child labels once so updateStatsDisplay never yields
local qiGatherVal = statNodes:WaitForChild("QiGather"):WaitForChild("Val") :: TextLabel
local healthVal = statNodes:WaitForChild("Health"):WaitForChild("Val") :: TextLabel
local defenseVal = statNodes:WaitForChild("Defense"):WaitForChild("Val") :: TextLabel
local damageVal = statNodes:WaitForChild("Damage"):WaitForChild("Val") :: TextLabel
local weaponVal = statNodes:WaitForChild("Weapon"):WaitForChild("Val") :: TextLabel
local armorVal = statNodes:WaitForChild("Armor"):WaitForChild("Val") :: TextLabel

local talentVal = talentCrest:WaitForChild("Val") :: TextLabel
local talentMultLbl = talentCrest:WaitForChild("Mult") :: TextLabel
local rootVal = rootCrest:WaitForChild("Val") :: TextLabel
local rootMultLbl = rootCrest:WaitForChild("Mult") :: TextLabel

-- Forward declare updateWheelUI
local updateWheelUI: () -> () = function() end

updateStatsDisplay = function()
	local realm = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 0

	local leaderstats = player:FindFirstChild("leaderstats")
	local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
	local qi = qiVal and qiVal.Value or (player:GetAttribute("Qi") or 0)

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
	realmLabel.Text = string.format("%s · LEVEL %d", string.upper(realm), level)
	
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") :: IntValue?
	local gold = goldVal and goldVal.Value or 50
	goldLabel.Text = string.format("%d SPIRIT STONES", gold)

	-- Update HUD Bars
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hp = hum and hum.Health or maxHealth
	local hpRatio = math.clamp(hp / math.max(1, maxHealth), 0, 1)
	TweenService:Create(hpFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(hpRatio, 0, 1, 0) }):Play()
	hpText.Text = string.format("HP: %d / %d", math.floor(hp), math.floor(maxHealth))

	local qiRatio = math.clamp(qi / math.max(1, reqQi), 0, 1)
	TweenService:Create(qiFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(qiRatio, 0, 1, 0) }):Play()
	qiText.Text = string.format("QI: %d / %d", math.floor(qi), reqQi)

	-- Update Cultivation Modal Stats
	local realmDef = CultivationConfig.Realms[realm]
	local baseSpeed = realmDef and realmDef.BaseQiPerSecond or 5
	local totalMult = talentEntry.Multiplier * (rootEntry and rootEntry.Multiplier or 1.0)
	local areaMult = player:GetAttribute("AreaQiMultiplier") or 1.0
	local activeRate = baseSpeed * totalMult * areaMult * 2

	if cultivating then
		qiGatherVal.Text = string.format("%.1f/s (MEDITATING)", activeRate)
	else
		qiGatherVal.Text = "0.0/s (IDLE)"
	end

	healthVal.Text = tostring(math.floor(maxHealth))
	defenseVal.Text = tostring(defense)
	damageVal.Text = tostring(damage)
	weaponVal.Text = weapon
	armorVal.Text = armor

	-- Update Flanking Crest Cards
	talentVal.Text = talentEntry.Name
	talentVal.TextColor3 = talentEntry.Color
	talentMultLbl.Text = string.format("x%.2f Qi Speed", talentEntry.Multiplier)

	if rootEntry then
		rootVal.Text = rootEntry.Name
		rootVal.TextColor3 = rootEntry.Color
		rootMultLbl.Text = string.format("x%.2f Qi Speed", rootEntry.Multiplier)
	else
		rootVal.Text = "None"
		rootVal.TextColor3 = GuofengTheme.Colors.TextMuted
		rootMultLbl.Text = "Spin to Awaken"
	end

	-- Breakthrough Requirement Text & Fill Bar
	breakProgText.Text = string.format("BREAKTHROUGH REQUIREMENT: %d / %d QI", math.floor(qi), reqQi)
	TweenService:Create(scrollQiFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(qiRatio, 0, 1, 0) }):Play()

	-- Cinnabar Button (Breakthrough vs Meditation Toggle)
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
	local leaderstats = player:FindFirstChild("leaderstats")
	local qiVal = leaderstats and leaderstats:FindFirstChild("Qi") :: IntValue?
	local qi = qiVal and qiVal.Value or (player:GetAttribute("Qi") or 0)
	local reqQi = CultivationConfig.getRequiredQi(realm, level)

	if qi >= reqQi then
		remote:FireServer("Breakthrough")
		showNotification("Attempting Realm Breakthrough...", true)
	else
		local nowCult = not (player:GetAttribute("Cultivating") or false)
		player:SetAttribute("Cultivating", nowCult)
		remote:FireServer("Cultivate")
		showNotification(nowCult and "Spiritual meditation began." or "Spiritual meditation stopped.")
		updateStatsDisplay()
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
local wheelPointer = wheelRim:WaitForChild("Pointer") :: Frame
local currentStatusLabel = leftCol:WaitForChild("CurrentStatus") :: TextLabel
local costInfoLabel = leftCol:WaitForChild("CostInfo") :: TextLabel
local spinActionBtn = leftCol:WaitForChild("SpinActionBtn") :: TextButton

local rightCol = wheelModal:WaitForChild("RightColumn") :: Frame
local tierScroll = rightCol:WaitForChild("TierScroll") :: ScrollingFrame

-- Destiny Award Pop-Up (Full-screen celebration modal)
local awardPopup = ui:WaitForChild("DestinyAwardPopup") :: Frame
local awardCard = awardPopup:WaitForChild("Card") :: Frame
local awardCloseBtn = awardCard:WaitForChild("CloseBtn") :: TextButton
local awardHeaderPill = awardCard:WaitForChild("HeaderPill") :: Frame
local awardHeaderLabel = awardHeaderPill:WaitForChild("HeaderLabel") :: TextLabel
local awardNameLabel = awardCard:WaitForChild("NameLabel") :: TextLabel
local awardMultBanner = awardCard:WaitForChild("MultBanner") :: Frame
local awardMultLabel = awardMultBanner:WaitForChild("MultLabel") :: TextLabel
local awardChanceLabel = awardCard:WaitForChild("ChanceLabel") :: TextLabel
local awardDescBox = awardCard:WaitForChild("DescBox") :: TextLabel
local awardClaimBtn = awardCard:WaitForChild("ClaimBtn") :: TextButton

local currentWheelTab = "Talent"
local isWheelSpinning = false
local isDecelerating = false
local currentSpinSession = 0
local pointerConn: RBXScriptConnection? = nil
local activeSpinTween: Tween? = nil

local function getWheelDisc(): CanvasGroup
	local disc = wheelRim:FindFirstChild("WheelDisc")
	if disc and disc:IsA("CanvasGroup") then
		return disc :: CanvasGroup
	end
	return (wheelRim:WaitForChild("WheelDisc")) :: any
end

local function dismissAwardPopup()
	awardPopup.Visible = false
end

awardCloseBtn.MouseButton1Click:Connect(dismissAwardPopup)
awardClaimBtn.MouseButton1Click:Connect(dismissAwardPopup)
awardClaimBtn.Activated:Connect(dismissAwardPopup)

awardPopup.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local mousePos = input.Position
		local cardPos = awardCard.AbsolutePosition
		local cardSize = awardCard.AbsoluteSize
		local inCard = (mousePos.X >= cardPos.X and mousePos.X <= cardPos.X + cardSize.X and
			mousePos.Y >= cardPos.Y and mousePos.Y <= cardPos.Y + cardSize.Y)
		if not inCard then
			dismissAwardPopup()
		end
	end
end)

wheelCloseBtn.MouseButton1Click:Connect(function()
	if isWheelSpinning then return end
	dismissAwardPopup()
	wheelModal.Visible = false
	cultModal.Visible = true
end)

local function renderWheelDisc()
	local disc = getWheelDisc()
	for _, child in ipairs(disc:GetChildren()) do
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
		spoke.Parent = disc

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
	if isWheelSpinning then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") and (leaderstats:FindFirstChild("Gold") :: IntValue).Value or 0
	local isTalent = (currentWheelTab == "Talent")
	local spinsDone = player:GetAttribute(isTalent and "TalentSpins" or "RootSpins") or 0
	local isFree = (spinsDone == 0)

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

	spinActionBtn.AutoButtonColor = true
	spinActionBtn.BackgroundColor3 = GuofengTheme.Colors.Cinnabar
	costInfoLabel.Text = string.format("Cost: %s | Spirit Stones: %d", isFree and "FREE" or "50 Stones", goldVal)
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
	local isTalent = (currentWheelTab == "Talent")
	local spinsDone = player:GetAttribute(isTalent and "TalentSpins" or "RootSpins") or 0
	local isFree = (spinsDone == 0)

	if not isFree and goldVal < DestinyConfig.SPIN_COST then
		showNotification("Not enough Spirit Stones! You need 50 Spirit Stones.", true)
		return
	end

	isWheelSpinning = true
	isDecelerating = false
	spinActionBtn.AutoButtonColor = false
	spinActionBtn.Text = "SPINNING..."
	spinActionBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated

	local session = tick()
	currentSpinSession = session

	local disc = getWheelDisc()
	if activeSpinTween then
		activeSpinTween:Cancel()
		activeSpinTween = nil
	end

	-- Continuous rapid spinning loop until server responds with SpinResult
	local function runContinuousSpin()
		if not isWheelSpinning or currentSpinSession ~= session or isDecelerating then return end
		local cur = disc.Rotation
		activeSpinTween = TweenService:Create(disc, TweenInfo.new(0.45, Enum.EasingStyle.Linear), {
			Rotation = cur + 360
		})
		activeSpinTween.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and isWheelSpinning and currentSpinSession == session and not isDecelerating then
				runContinuousSpin()
			end
		end)
		activeSpinTween:Play()
	end
	runContinuousSpin()

	-- Needle pointer tick-tick-tick bounce
	if pointerConn then
		pointerConn:Disconnect()
		pointerConn = nil
	end
	local count = (currentWheelTab == "Talent") and #DestinyConfig.TALENTS or #DestinyConfig.SPIRITUAL_ROOTS
	local sliceAngle = 360 / count
	local lastSector = -1
	pointerConn = RunService.RenderStepped:Connect(function()
		if not isWheelSpinning then return end
		local d = getWheelDisc()
		local r = d.Rotation
		local sec = math.floor((r % 360) / sliceAngle)
		if sec ~= lastSector then
			lastSector = sec
			wheelPointer.Rotation = 58
			TweenService:Create(wheelPointer, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Rotation = 45
			}):Play()
		end
	end)

	-- Safety watchdog: in case of dropped event or network delay, UI recovers cleanly after 10s
	task.delay(10.0, function()
		if isWheelSpinning and currentSpinSession == session then
			isWheelSpinning = false
			isDecelerating = false
			if activeSpinTween then
				activeSpinTween:Cancel()
				activeSpinTween = nil
			end
			if pointerConn then
				pointerConn:Disconnect()
				pointerConn = nil
			end
			wheelPointer.Rotation = 45
			spinActionBtn.AutoButtonColor = true
			updateWheelUI()
			updateStatsDisplay()
		end
	end)

	remote:FireServer("SpinWheel", currentWheelTab)
end)

-- ============================================================================
-- 8. PROFESSIONAL 5-CATEGORY GRID INVENTORY SYSTEM
-- ============================================================================
local headerBar = invModal:WaitForChild("HeaderBar") :: Frame
local searchBox = headerBar:WaitForChild("SearchFrame"):WaitForChild("SearchBox") :: TextBox
local capacityLabel = headerBar:WaitForChild("CapacityLabel") :: TextLabel
local categoryTabs = invModal:WaitForChild("CategoryTabs") :: Frame
local mainBody = invModal:WaitForChild("MainBody") :: Frame
local gridContainer = mainBody:WaitForChild("GridContainer") :: Frame
local invItemList = gridContainer:WaitForChild("ItemList") :: ScrollingFrame
local inspectPanel = mainBody:WaitForChild("InspectPanel") :: Frame

local iconBox = inspectPanel:WaitForChild("IconBox") :: Frame
local iconGlyph = iconBox:WaitForChild("IconGlyph") :: TextLabel
local rarityGlow = iconBox:WaitForChild("RarityGlow") :: UIStroke
local itemNameLabel = inspectPanel:WaitForChild("ItemName") :: TextLabel
local itemTierLabel = inspectPanel:WaitForChild("ItemTier") :: TextLabel
local descText = inspectPanel:WaitForChild("DescFrame"):WaitForChild("DescText") :: TextLabel
local statLabel = inspectPanel:WaitForChild("StatLabel") :: TextLabel
local valueLabel = inspectPanel:WaitForChild("ValueLabel") :: TextLabel
local actionBtn = inspectPanel:WaitForChild("ActionBtn") :: TextButton
local discardBtn = inspectPanel:WaitForChild("DiscardBtn") :: TextButton

local currentCategory = "MISC"
local selectedItemName: string? = nil
local selectedActionConn: RBXScriptConnection? = nil
local selectedDiscardConn: RBXScriptConnection? = nil
local activeCardStrokes: { [string]: UIStroke } = {}

local rarityColors = {
	Common = Color3.fromRGB(140, 148, 155),
	Uncommon = Color3.fromRGB(56, 183, 100),
	Rare = Color3.fromRGB(59, 130, 246),
	Epic = Color3.fromRGB(168, 85, 247),
	Legendary = Color3.fromRGB(234, 179, 8),
}

local function getRarityColor(rarity: string?): Color3
	return rarityColors[rarity or "Common"] or rarityColors.Common
end

local function selectItem(itmVal: IntValue?, itemDef: any)
	if not itmVal then
		itemNameLabel.Text = "Select an Item"
		itemNameLabel.TextColor3 = GuofengTheme.Colors.GoldLight
		itemTierLabel.Text = "EMPTY SLOT"
		itemTierLabel.TextColor3 = GuofengTheme.Colors.CyanGlow
		descText.Text = "Click any item slot on the left grid to view its properties, cultivation stats, and alchemical grade."
		statLabel.Text = ""
		valueLabel.Text = "SELL VALUE: --"
		iconGlyph.Text = "--"
		rarityGlow.Color = Color3.fromRGB(70, 90, 100)
		actionBtn.Visible = false
		discardBtn.Visible = false
		selectedItemName = nil
		return
	end

	selectedItemName = itmVal.Name
	local rCol = getRarityColor(itemDef and itemDef.Rarity)
	local displayName = itemDef and itemDef.Name or itmVal.Name
	local rarityName = itemDef and itemDef.Rarity or "Common"
	local categoryName = itemDef and (itemDef.Category or itemDef.Type) or "Misc"

	itemNameLabel.Text = displayName
	itemNameLabel.TextColor3 = rCol
	itemTierLabel.Text = string.upper(string.format("%s %s", rarityName, categoryName))
	itemTierLabel.TextColor3 = rCol
	descText.Text = itemDef and (itemDef.Description or "Spiritual cultivation item.") or "Material harvested in the cultivation world."

	local statLines = {}
	if itemDef then
		if itemDef.DamageBonus and itemDef.DamageBonus > 0 then
			table.insert(statLines, string.format("+%d Physical Attack", itemDef.DamageBonus))
		end
		if itemDef.DefenseBonus and itemDef.DefenseBonus > 0 then
			table.insert(statLines, string.format("+%d Physical Defense", itemDef.DefenseBonus))
		end
		if itemDef.MaxHealthBonus and itemDef.MaxHealthBonus > 0 then
			table.insert(statLines, string.format("+%d Max Vitality", itemDef.MaxHealthBonus))
		end
		if itemDef.QiGatherMultiplier and itemDef.QiGatherMultiplier > 1 then
			table.insert(statLines, string.format("x%.1f Qi Gathering Speed", itemDef.QiGatherMultiplier))
		end
		if itemDef.InstantQi and itemDef.InstantQi > 0 then
			table.insert(statLines, string.format("+%d Immediate Spiritual Qi", itemDef.InstantQi))
		end
		if itemDef.BuffDurationSeconds and itemDef.BuffDurationSeconds > 0 then
			table.insert(statLines, string.format("Duration: %ds", itemDef.BuffDurationSeconds))
		end
	end
	if #statLines == 0 then
		statLabel.Text = "Raw spiritual material. Suitable for alchemy, crafting, or trade."
		statLabel.TextColor3 = Color3.fromRGB(150, 175, 185)
	else
		statLabel.Text = table.concat(statLines, "\n")
		statLabel.TextColor3 = Color3.fromRGB(110, 230, 240)
	end

	local sellVal = itemDef and (itemDef.SellValue or math.floor((itemDef.Price or 20) / 2)) or 5
	valueLabel.Text = string.format("SELL VALUE: %d SPIRIT STONES", sellVal)
	iconGlyph.Text = itemDef and (itemDef.Icon or string.sub(displayName, 1, 2)) or "IT"
	rarityGlow.Color = rCol

	actionBtn.Visible = true
	discardBtn.Visible = true

	local isEquip = itemDef and (itemDef.Type == "Weapon" or itemDef.Type == "Armor" or itemDef.Type == "Tool" or itemDef.Category == "Equipment")
	local isUsable = itemDef and (itemDef.Type == "Pill" or itemDef.Type == "Manual" or itemDef.InstantQi or itemDef.BuffDurationSeconds)

	if isEquip then
		actionBtn.Text = "EQUIP"
		actionBtn.BackgroundColor3 = Color3.fromRGB(35, 95, 130)
		actionBtn.AutoButtonColor = true
	elseif isUsable then
		actionBtn.Text = "USE"
		actionBtn.BackgroundColor3 = Color3.fromRGB(24, 85, 62)
		actionBtn.AutoButtonColor = true
	else
		actionBtn.Text = "EXAMINE"
		actionBtn.BackgroundColor3 = Color3.fromRGB(36, 45, 52)
		actionBtn.AutoButtonColor = false
	end

	if selectedActionConn then
		selectedActionConn:Disconnect()
		selectedActionConn = nil
	end
	if selectedDiscardConn then
		selectedDiscardConn:Disconnect()
		selectedDiscardConn = nil
	end

	selectedActionConn = actionBtn.MouseButton1Click:Connect(function()
		if isEquip then
			remote:FireServer("EquipItem", displayName)
		elseif isUsable then
			remote:FireServer("UseItem", displayName)
		end
	end)

	selectedDiscardConn = discardBtn.MouseButton1Click:Connect(function()
		remote:FireServer("DiscardItem", displayName)
	end)
end

local function matchesTab(itemDef: any, tab: string): boolean
	if not itemDef then
		return tab == "MISC"
	end
	local cat = itemDef.Category or itemDef.Type or "MISC"
	if tab == "MISC" then
		return cat == "Miscs" or cat == "Misc" or itemDef.Type == "Miscs" or itemDef.Type == "Herb" or itemDef.Type == "Plant" or itemDef.Type == "Ore"
	elseif tab == "PILLS" then
		return cat == "Pills" or cat == "Pill" or itemDef.Type == "Pill"
	elseif tab == "MANUALS" then
		return cat == "Manuals" or cat == "Manual" or itemDef.Type == "Manual" or string.find(itemDef.Name, "Manual") ~= nil or string.find(itemDef.Name, "Scripture") ~= nil or string.find(itemDef.Name, "Sutra") ~= nil
	elseif tab == "SKILLS" then
		return cat == "Skills" or cat == "Skill" or itemDef.Type == "Skill"
	elseif tab == "EQUIPMENT" then
		return cat == "Equipment" or itemDef.Type == "Weapon" or itemDef.Type == "Armor" or itemDef.Type == "Tool"
	end
	return false
end

local function updateTabButtons()
	for _, tabName in ipairs({ "MISC", "PILLS", "MANUALS", "SKILLS", "EQUIPMENT" }) do
		local btn = categoryTabs:FindFirstChild("Tab_" .. tabName) :: TextButton?
		if btn then
			local stroke = btn:FindFirstChild("TabStroke") :: UIStroke?
			if tabName == currentCategory then
				btn.BackgroundColor3 = Color3.fromRGB(24, 75, 58)
				btn.TextColor3 = Color3.fromRGB(245, 220, 115)
				if stroke then
					stroke.Color = Color3.fromRGB(215, 180, 85)
					stroke.Thickness = 1.4
				end
			else
				btn.BackgroundColor3 = Color3.fromRGB(20, 26, 32)
				btn.TextColor3 = Color3.fromRGB(150, 170, 175)
				if stroke then
					stroke.Color = Color3.fromRGB(45, 60, 65)
					stroke.Thickness = 1.0
				end
			end
		end
	end
end

refreshInventoryUI = function()
	for _, ch in ipairs(invItemList:GetChildren()) do
		if ch:IsA("GuiObject") and not ch:IsA("UIGridLayout") then
			ch:Destroy()
		end
	end
	table.clear(activeCardStrokes)

	local inventory = player:FindFirstChild("Inventory")
	if not inventory then
		capacityLabel.Text = "Capacity: 0 / 100"
		selectItem(nil, nil)
		return
	end

	local allItems: { IntValue } = {}
	for _, itm in ipairs(inventory:GetDescendants()) do
		if (itm:IsA("IntValue") or itm:IsA("NumberValue")) and itm.Value > 0 then
			table.insert(allItems, itm)
		end
	end

	capacityLabel.Text = string.format("Capacity: %d / 100", #allItems)

	local searchQuery = string.lower(searchBox.Text or "")
	local filteredItems: { IntValue } = {}

	for _, itm in ipairs(allItems) do
		local itemDef = ItemConfig.getItem(itm.Name)
		local matchesSearch = (searchQuery == "") or (string.find(string.lower(itm.Name), searchQuery, 1, true) ~= nil)
		if matchesSearch and matchesTab(itemDef, currentCategory) then
			table.insert(filteredItems, itm)
		end
	end

	local firstItemToSelect: { val: IntValue, def: any }? = nil
	local selectedStillExists = false

	for _, itmVal in ipairs(filteredItems) do
		local itemDef = ItemConfig.getItem(itmVal.Name)
		local displayName = itemDef and itemDef.Name or itmVal.Name
		local rCol = getRarityColor(itemDef and itemDef.Rarity)

		local slotBtn = Instance.new("TextButton")
		slotBtn.Name = itmVal.Name
		slotBtn.Size = UDim2.new(0, 78, 0, 78)
		slotBtn.BackgroundColor3 = Color3.fromRGB(22, 28, 35)
		slotBtn.AutoButtonColor = true
		slotBtn.Text = ""
		slotBtn.ZIndex = 55
		slotBtn.Parent = invItemList

		local sCorner = Instance.new("UICorner")
		sCorner.CornerRadius = UDim.new(0, 6)
		sCorner.Parent = slotBtn

		local sStroke = Instance.new("UIStroke")
		sStroke.Name = "SlotStroke"
		sStroke.Color = rCol
		sStroke.Thickness = 1.2
		sStroke.Parent = slotBtn
		activeCardStrokes[itmVal.Name] = sStroke

		-- Item Icon / Glyph
		local glyphLbl = Instance.new("TextLabel")
		glyphLbl.Name = "Glyph"
		glyphLbl.Size = UDim2.new(1, 0, 0, 36)
		glyphLbl.Position = UDim2.new(0, 0, 0, 8)
		glyphLbl.BackgroundTransparency = 1
		glyphLbl.Font = Enum.Font.GothamBold
		glyphLbl.Text = itemDef and (itemDef.Icon or string.sub(displayName, 1, 2)) or "IT"
		glyphLbl.TextColor3 = rCol
		glyphLbl.TextSize = 18
		glyphLbl.ZIndex = 56
		glyphLbl.Parent = slotBtn

		-- Item Truncated Name
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "Name"
		nameLbl.Size = UDim2.new(1, -8, 0, 16)
		nameLbl.Position = UDim2.new(0, 4, 0, 44)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamMedium
		nameLbl.Text = displayName
		nameLbl.TextColor3 = Color3.fromRGB(225, 235, 240)
		nameLbl.TextSize = 9
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.ZIndex = 56
		nameLbl.Parent = slotBtn

		-- Quantity badge
		local qtyLbl = Instance.new("TextLabel")
		qtyLbl.Name = "Qty"
		qtyLbl.Size = UDim2.new(1, -6, 0, 14)
		qtyLbl.Position = UDim2.new(0, 0, 1, -16)
		qtyLbl.BackgroundTransparency = 1
		qtyLbl.Font = Enum.Font.GothamBold
		qtyLbl.Text = string.format("x%d", itmVal.Value)
		qtyLbl.TextColor3 = GuofengTheme.Colors.GoldLight
		qtyLbl.TextSize = 10
		qtyLbl.TextXAlignment = Enum.TextXAlignment.Right
		qtyLbl.ZIndex = 56
		qtyLbl.Parent = slotBtn

		if itmVal.Name == selectedItemName then
			selectedStillExists = true
			sStroke.Thickness = 2.4
			sStroke.Color = Color3.fromRGB(255, 255, 255)
		end

		if not firstItemToSelect then
			firstItemToSelect = { val = itmVal, def = itemDef }
		end

		slotBtn.MouseButton1Click:Connect(function()
			for _, stk in pairs(activeCardStrokes) do
				stk.Thickness = 1.2
			end
			sStroke.Thickness = 2.4
			sStroke.Color = Color3.fromRGB(255, 255, 255)
			selectItem(itmVal, itemDef)
		end)
	end

	if selectedStillExists and selectedItemName then
		local curVal = inventory:FindFirstChild(selectedItemName, true) :: IntValue?
		if curVal then
			selectItem(curVal, ItemConfig.getItem(selectedItemName))
		end
	elseif firstItemToSelect then
		selectItem(firstItemToSelect.val, firstItemToSelect.def)
	else
		selectItem(nil, nil)
	end
end

-- Wire Category Tab Clicks
for _, tabName in ipairs({ "MISC", "PILLS", "MANUALS", "SKILLS", "EQUIPMENT" }) do
	local btn = categoryTabs:FindFirstChild("Tab_" .. tabName) :: TextButton?
	if btn then
		btn.MouseButton1Click:Connect(function()
			currentCategory = tabName
			updateTabButtons()
			refreshInventoryUI()
		end)
	end
end
updateTabButtons()

-- Wire Real-time Search
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	refreshInventoryUI()
end)

-- ============================================================================
-- 9. SHOP MODAL BINDING
-- ============================================================================
local shopItemList = (shopModal:FindFirstChild("ShopItemList")
	or shopModal:FindFirstChild("ShopList")
	or shopModal:WaitForChild("ShopItemList", 5)
	or shopModal:FindFirstChildWhichIsA("ScrollingFrame")) :: ScrollingFrame

populateShop = function()
	for _, ch in ipairs(shopItemList:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	local shopItems = {}
	if ItemConfig.ShopInventory then
		for _, itemName in ipairs(ItemConfig.ShopInventory) do
			local itm = ItemConfig.getItem(itemName)
			if itm then table.insert(shopItems, itm) end
		end
	else
		for _, itm in pairs(ItemConfig.Catalog) do
			table.insert(shopItems, itm)
		end
	end

	shopItemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopItemList.CanvasSize = UDim2.new(0, 0, 0, #shopItems * 80 + 30)

	for _, item in ipairs(shopItems) do
		local card = GuofengTheme.createParchmentCard(shopItemList, UDim2.new(1, -8, 0, 70), UDim2.new(0, 0, 0, 0))
		card.Name = item.Name

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "Name"
		nameLbl.BackgroundTransparency = 1
		nameLbl.Position = UDim2.new(0, 14, 0, 8)
		nameLbl.Size = UDim2.new(1, -135, 0, 22)
		nameLbl.Font = GuofengTheme.Fonts.Header
		nameLbl.Text = item.Name
		nameLbl.TextColor3 = GuofengTheme.Colors.GoldLight
		nameLbl.TextSize = 13
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.ZIndex = 25
		nameLbl.Parent = card

		local descLbl = Instance.new("TextLabel")
		descLbl.Name = "Desc"
		descLbl.BackgroundTransparency = 1
		descLbl.Position = UDim2.new(0, 14, 0, 30)
		descLbl.Size = UDim2.new(1, -135, 0, 32)
		descLbl.Font = GuofengTheme.Fonts.Body
		descLbl.Text = item.Description or "Spiritual item."
		descLbl.TextColor3 = GuofengTheme.Colors.TextMuted
		descLbl.TextSize = 11
		descLbl.TextWrapped = true
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.TextYAlignment = Enum.TextYAlignment.Top
		descLbl.ZIndex = 25
		descLbl.Parent = card

		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyBtn"
		buyBtn.Size = UDim2.new(0, 105, 0, 32)
		buyBtn.Position = UDim2.new(1, -118, 0.5, -16)
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
pcall(populateShop)

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
		updateStatsDisplay()
	elseif event == "BreakthroughStart" then
		showNotification("Heavenly Tribulation Surpassed! Realm Breakthrough Complete!", true)
		updateStatsDisplay()
	elseif event == "Notification" then
		local msg = args[1] or ""
		local isGold = args[2] == true
		showNotification(msg, isGold)
	elseif event == "InventoryUpdated" then
		refreshInventoryUI()
	elseif event == "OpenShop" then
		toggleModal(shopModal)
		populateShop()
	elseif event == "SpinError" then
		local errMsg = args[1] or "Spin could not be completed."
		isWheelSpinning = false
		currentSpinSession = 0
		if activeSpinTween then
			activeSpinTween:Cancel()
			activeSpinTween = nil
		end
		if pointerConn then
			pointerConn:Disconnect()
			pointerConn = nil
		end
		wheelPointer.Rotation = 45
		spinActionBtn.AutoButtonColor = true
		updateWheelUI()
		showNotification(errMsg, true)

	elseif event == "SpinResult" then
		local wheelType = args[1]
		local resultIndex = args[2]
		local resultName = args[3]
		local resultMultiplier = args[4]

		local count = (wheelType == "Talent") and #DestinyConfig.TALENTS or #DestinyConfig.SPIRITUAL_ROOTS
		local sliceAngle = 360 / count
		local targetSliceAngle = (360 - ((resultIndex - 1) * sliceAngle)) % 360

		local disc = getWheelDisc()
		isDecelerating = true
		if activeSpinTween then
			activeSpinTween:Cancel()
			activeSpinTween = nil
		end

		local curRot = disc.Rotation
		local curNorm = curRot % 360
		local deltaAngle = (targetSliceAngle - curNorm) % 360
		local spins = 4 * 360
		local finalRotation = curRot + spins + deltaAngle

		-- Ensure pointer ticking continues during deceleration
		if not pointerConn then
			local lastSector = -1
			pointerConn = RunService.RenderStepped:Connect(function()
				if not isWheelSpinning then return end
				local d = getWheelDisc()
				local r = d.Rotation
				local sec = math.floor((r % 360) / sliceAngle)
				if sec ~= lastSector then
					lastSector = sec
					wheelPointer.Rotation = 58
					TweenService:Create(wheelPointer, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Rotation = 45
					}):Play()
				end
			end)
		end

		-- Smooth 3.0s deceleration animation to the target prize slice
		local spinTween = TweenService:Create(disc, TweenInfo.new(3.0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Rotation = finalRotation
		})
		spinTween:Play()
		spinTween.Completed:Wait()

		-- Finished cleanly after spinning
		if pointerConn then
			pointerConn:Disconnect()
			pointerConn = nil
		end
		wheelPointer.Rotation = 45
		disc.Rotation = finalRotation

		isWheelSpinning = false
		isDecelerating = false
		currentSpinSession = 0
		spinActionBtn.AutoButtonColor = true

		updateStatsDisplay()
		updateWheelUI()

		-- Pop up on screen what talent/spiritual root they got!
		local entry = (wheelType == "Talent") and DestinyConfig.GetTalent(resultName) or DestinyConfig.GetSpiritualRoot(resultName)

		awardHeaderLabel.Text = (wheelType == "Talent") and "DESTINY TALENT AWAKENED" or "SPIRITUAL ROOT AWAKENED"
		awardNameLabel.Text = resultName
		if entry then
			awardNameLabel.TextColor3 = entry.Color
			local stroke = awardCard:FindFirstChild("Stroke") :: UIStroke?
			if stroke then
				stroke.Color = entry.Color
			end
			awardChanceLabel.Text = string.format("Rarity: %s | Probability: %.2f%%", entry.TierName, entry.Chance)
			awardDescBox.Text = entry.Description
		end

		awardMultLabel.Text = string.format("Qi Gathering Speed: x%.2f Multiplier", resultMultiplier)

		-- Show the full-screen centered award popup with entrance bounce!
		awardCard.Size = UDim2.new(0, 360, 0, 240)
		awardPopup.Visible = true
		TweenService:Create(awardCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 480, 0, 320)
		}):Play()
	elseif event == "FloatingNotice" then
		local noticeMsg = ...
		if typeof(noticeMsg) == "string" then
			showNotification(noticeMsg, true)
		end
	end
end)

for _, attr in ipairs({ "Qi", "Realm", "RealmLevel", "Cultivating", "Damage", "Defense", "MaxHealth", "EquippedWeapon", "EquippedArmor", "Talent", "SpiritualRoot", "TalentSpins", "RootSpins", "AreaQiMultiplier" }) do
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
	local function hookValue(val: Instance)
		if val:IsA("IntValue") or val:IsA("NumberValue") then
			val.Changed:Connect(function()
				refreshInventoryUI()
			end)
		end
	end

	inventory.DescendantAdded:Connect(function(desc)
		hookValue(desc)
		refreshInventoryUI()
	end)
	inventory.DescendantRemoving:Connect(function()
		refreshInventoryUI()
	end)
	for _, desc in ipairs(inventory:GetDescendants()) do
		hookValue(desc)
	end
end

updateStatsDisplay()
refreshInventoryUI()

-- Periodic UI refresh to guarantee real-time fidelity during meditation or modal interaction
task.spawn(function()
	while true do
		task.wait(0.5)
		if player:GetAttribute("Cultivating") == true or cultModal.Visible or hpBar.Visible then
			updateStatsDisplay()
		end
	end
end)

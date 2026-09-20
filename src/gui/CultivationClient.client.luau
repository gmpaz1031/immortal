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
-- 3c. MEDITATION ANIMATION & ACTIVE CULTIVATING CARD
-- ============================================================================
local meditationAnim: AnimationTrack? = nil
local meditationSteppedConn: RBXScriptConnection? = nil
local auraFxFolder: Folder? = nil

-- Dedicated Active Cultivating HUD Card (Prompt Section 5)
local cultCard = Instance.new("Frame")
cultCard.Name = "ActiveCultivatingCard"
cultCard.Size = UDim2.new(0, 310, 0, 136)
cultCard.Position = UDim2.new(0.5, -155, 0.74, 0)
cultCard.BackgroundColor3 = GuofengTheme.Colors.DarkJade
cultCard.BackgroundTransparency = 0.08
cultCard.BorderSizePixel = 0
cultCard.Visible = false
cultCard.ZIndex = 50
cultCard.Parent = ui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 10)
cardCorner.Parent = cultCard

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = GuofengTheme.Colors.GoldBorderDim
cardStroke.Thickness = 1.5
cardStroke.Parent = cultCard

local cardHeader = Instance.new("TextLabel")
cardHeader.Name = "Header"
cardHeader.Size = UDim2.new(1, 0, 0, 26)
cardHeader.Position = UDim2.new(0, 0, 0, 8)
cardHeader.BackgroundTransparency = 1
cardHeader.Font = GuofengTheme.Fonts.Title
cardHeader.Text = "CULTIVATING"
cardHeader.TextColor3 = GuofengTheme.Colors.GoldAmber
cardHeader.TextSize = 15
cardHeader.ZIndex = 51
cardHeader.Parent = cultCard

local cardQiText = Instance.new("TextLabel")
cardQiText.Name = "QiText"
cardQiText.Size = UDim2.new(1, 0, 0, 20)
cardQiText.Position = UDim2.new(0, 0, 0, 34)
cardQiText.BackgroundTransparency = 1
cardQiText.Font = GuofengTheme.Fonts.Body
cardQiText.Text = "Qi: 0 / 5,000"
cardQiText.TextColor3 = GuofengTheme.Colors.CyanBright
cardQiText.TextSize = 13
cardQiText.ZIndex = 51
cardQiText.Parent = cultCard

local cardBarBg = Instance.new("Frame")
cardBarBg.Name = "BarBg"
cardBarBg.Size = UDim2.new(0.88, 0, 0, 16)
cardBarBg.Position = UDim2.new(0.06, 0, 0, 58)
cardBarBg.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
cardBarBg.BorderSizePixel = 0
cardBarBg.ZIndex = 51
cardBarBg.Parent = cultCard

local cardBarCorner = Instance.new("UICorner")
cardBarCorner.CornerRadius = UDim.new(0, 8)
cardBarCorner.Parent = cardBarBg

local cardBarFill = Instance.new("Frame")
cardBarFill.Name = "Fill"
cardBarFill.Size = UDim2.new(0, 0, 1, 0)
cardBarFill.BackgroundColor3 = GuofengTheme.Colors.CyanBright
cardBarFill.BorderSizePixel = 0
cardBarFill.ZIndex = 52
cardBarFill.Parent = cardBarBg

local cardBarFillCorner = Instance.new("UICorner")
cardBarFillCorner.CornerRadius = UDim.new(0, 8)
cardBarFillCorner.Parent = cardBarFill

local cardPercentText = Instance.new("TextLabel")
cardPercentText.Name = "PercentText"
cardPercentText.Size = UDim2.new(1, 0, 1, 0)
cardPercentText.BackgroundTransparency = 1
cardPercentText.Font = GuofengTheme.Fonts.Body
cardPercentText.Text = "0.0%"
cardPercentText.TextColor3 = Color3.fromRGB(255, 255, 255)
cardPercentText.TextSize = 11
cardPercentText.ZIndex = 53
cardPercentText.Parent = cardBarBg

local cardRateText = Instance.new("TextLabel")
cardRateText.Name = "RateText"
cardRateText.Size = UDim2.new(1, 0, 0, 20)
cardRateText.Position = UDim2.new(0, 0, 0, 80)
cardRateText.BackgroundTransparency = 1
cardRateText.Font = GuofengTheme.Fonts.Body
cardRateText.Text = "+10.0 Qi / second"
cardRateText.TextColor3 = GuofengTheme.Colors.GreenAccent
cardRateText.TextSize = 13
cardRateText.ZIndex = 51
cardRateText.Parent = cultCard

local cardHintText = Instance.new("TextLabel")
cardHintText.Name = "HintText"
cardHintText.Size = UDim2.new(1, 0, 0, 20)
cardHintText.Position = UDim2.new(0, 0, 0, 104)
cardHintText.BackgroundTransparency = 1
cardHintText.Font = GuofengTheme.Fonts.Body
cardHintText.Text = "[ C ] Stop Cultivating"
cardHintText.TextColor3 = GuofengTheme.Colors.TextMuted
cardHintText.TextSize = 12
cardHintText.ZIndex = 51
cardHintText.Parent = cultCard

local function updateActiveCultivatingCard(currentQi: number, maxQi: number, qiRate: number)
	local ratio = math.clamp(currentQi / math.max(1, maxQi), 0, 1)
	local percent = math.floor(ratio * 1000 + 0.5) / 10

	cardQiText.Text = string.format("Qi: %d / %d", math.floor(currentQi), math.floor(maxQi))
	cardPercentText.Text = string.format("%.1f%%", percent)
	TweenService:Create(cardBarFill, TweenInfo.new(0.25), { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
	cardRateText.Text = string.format("+%.1f Qi / second", qiRate)

	if currentQi >= maxQi then
		cardHeader.Text = "QI FULL - BREAKTHROUGH AVAILABLE"
		cardHeader.TextColor3 = GuofengTheme.Colors.GoldAmber
		cardHintText.Text = "[ K ] Cultivation Panel  |  [ C ] Stand Up"
		cardBarFill.BackgroundColor3 = GuofengTheme.Colors.GoldAmber
	else
		cardHeader.Text = "CULTIVATING"
		cardHeader.TextColor3 = GuofengTheme.Colors.CyanBright
		cardHintText.Text = "[ C ] Stop Cultivating"
		cardBarFill.BackgroundColor3 = GuofengTheme.Colors.CyanBright
	end
end

local function startMeditationAnimation()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not root then return end

	-- 1. Animation Track
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

	-- 2. Procedural Cross-Legged Sitting Pose Guarantee (R15 & R6)
	hum.Sit = true
	local isR15 = hum.RigType == Enum.HumanoidRigType.R15

	if meditationSteppedConn then
		meditationSteppedConn:Disconnect()
		meditationSteppedConn = nil
	end

	meditationSteppedConn = RunService.Stepped:Connect(function()
		if not player:GetAttribute("Cultivating") then return end
		if isR15 then
			local rootJoint = root:FindFirstChild("RootJoint") :: Motor6D?
			if rootJoint then
				rootJoint.Transform = rootJoint.Transform * CFrame.new(0, -0.65, 0)
			end

			local leftHip = char:FindFirstChild("LeftUpperLeg") and (char.LeftUpperLeg:FindFirstChild("LeftHip") :: Motor6D?)
			local rightHip = char:FindFirstChild("RightUpperLeg") and (char.RightUpperLeg:FindFirstChild("RightHip") :: Motor6D?)
			local leftKnee = char:FindFirstChild("LeftLowerLeg") and (char.LeftLowerLeg:FindFirstChild("LeftKnee") :: Motor6D?)
			local rightKnee = char:FindFirstChild("RightLowerLeg") and (char.RightLowerLeg:FindFirstChild("RightKnee") :: Motor6D?)

			if leftHip then leftHip.Transform = CFrame.Angles(math.rad(75), math.rad(-25), math.rad(-20)) end
			if rightHip then rightHip.Transform = CFrame.Angles(math.rad(75), math.rad(25), math.rad(20)) end
			if leftKnee then leftKnee.Transform = CFrame.Angles(math.rad(-115), 0, math.rad(15)) end
			if rightKnee then rightKnee.Transform = CFrame.Angles(math.rad(-115), 0, math.rad(-15)) end

			local leftShoulder = char:FindFirstChild("LeftUpperArm") and (char.LeftUpperArm:FindFirstChild("LeftShoulder") :: Motor6D?)
			local rightShoulder = char:FindFirstChild("RightUpperArm") and (char.RightUpperArm:FindFirstChild("RightShoulder") :: Motor6D?)
			local leftElbow = char:FindFirstChild("LeftLowerArm") and (char.LeftLowerArm:FindFirstChild("LeftElbow") :: Motor6D?)
			local rightElbow = char:FindFirstChild("RightLowerArm") and (char.RightLowerArm:FindFirstChild("RightElbow") :: Motor6D?)

			if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(30), math.rad(15), math.rad(-15)) end
			if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(30), math.rad(-15), math.rad(15)) end
			if leftElbow then leftElbow.Transform = CFrame.Angles(math.rad(45), 0, 0) end
			if rightElbow then rightElbow.Transform = CFrame.Angles(math.rad(45), 0, 0) end
		else
			local torso = char:FindFirstChild("Torso")
			if torso then
				local leftHip = torso:FindFirstChild("Left Hip") :: Motor6D?
				local rightHip = torso:FindFirstChild("Right Hip") :: Motor6D?
				local leftShoulder = torso:FindFirstChild("Left Shoulder") :: Motor6D?
				local rightShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?

				if leftHip then leftHip.Transform = CFrame.Angles(math.rad(75), math.rad(-20), 0) end
				if rightHip then rightHip.Transform = CFrame.Angles(math.rad(75), math.rad(20), 0) end
				if leftShoulder then leftShoulder.Transform = CFrame.Angles(math.rad(30), 0, math.rad(-15)) end
				if rightShoulder then rightShoulder.Transform = CFrame.Angles(math.rad(30), 0, math.rad(15)) end
			end
		end
	end)

	-- 3. Subtle Spiritual Qi Gathering Particles & Aura
	if not auraFxFolder then
		auraFxFolder = Instance.new("Folder")
		auraFxFolder.Name = "MeditationAuraFX"
		auraFxFolder.Parent = char

		local qiEmitter = Instance.new("ParticleEmitter")
		qiEmitter.Name = "QiGatherParticles"
		qiEmitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, GuofengTheme.Colors.CyanBright),
			ColorSequenceKeypoint.new(0.5, GuofengTheme.Colors.GoldAmber),
			ColorSequenceKeypoint.new(1, GuofengTheme.Colors.CyanDark),
		})
		qiEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(0.5, 0.4),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		qiEmitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		qiEmitter.Lifetime = NumberRange.new(1.0, 1.8)
		qiEmitter.Rate = 14
		qiEmitter.Speed = NumberRange.new(-2.5, -0.5)
		qiEmitter.SpreadAngle = Vector2.new(180, 180)
		qiEmitter.LightEmission = 0.8
		qiEmitter.Parent = root

		local auraRing = Instance.new("Part")
		auraRing.Name = "AuraRing"
		auraRing.Shape = Enum.PartType.Cylinder
		auraRing.Size = Vector3.new(0.1, 5, 5)
		auraRing.Color = GuofengTheme.Colors.CyanBright
		auraRing.Material = Enum.Material.Neon
		auraRing.Transparency = 0.75
		auraRing.CanCollide = false
		auraRing.Anchored = false
		auraRing.CFrame = root.CFrame * CFrame.new(0, -1.8, 0) * CFrame.Angles(0, 0, math.rad(90))
		auraRing.Parent = auraFxFolder

		local aw = Instance.new("WeldConstraint")
		aw.Part0 = root
		aw.Part1 = auraRing
		aw.Parent = auraRing
	end

	cultCard.Visible = true
	local q = player:GetAttribute("Qi") or 0
	local mq = player:GetAttribute("MaxQi") or 5000
	local rate = player:GetAttribute("QiRate") or 10.0
	updateActiveCultivatingCard(q, mq, rate)
end

local function stopMeditationAnimation()
	if meditationAnim then
		meditationAnim:Stop(0.3)
		meditationAnim = nil
	end

	if meditationSteppedConn then
		meditationSteppedConn:Disconnect()
		meditationSteppedConn = nil
	end

	if auraFxFolder then
		auraFxFolder:Destroy()
		auraFxFolder = nil
	end

	cultCard.Visible = false

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Sit = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
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

local function toggleModal(modal: Frame)
	local target = not modal.Visible
	closeAllModals()
	modal.Visible = target
	if target and modal == invModal and refreshInventoryUI then
		pcall(refreshInventoryUI)
	elseif target and modal == shopModal and populateShop then
		pcall(populateShop)
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

-- Cultivation Manual Synergy Banner (under Taiji vortex)
local manualBanner = cultModal:FindFirstChild("ManualSynergyBanner") :: Frame?
if not manualBanner then
	manualBanner = Instance.new("Frame")
	manualBanner.Name = "ManualSynergyBanner"
	manualBanner.Size = UDim2.new(1, -36, 0, 24)
	manualBanner.Position = UDim2.new(0, 18, 0, 188)
	manualBanner.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated
	manualBanner.BorderSizePixel = 0
	manualBanner.ZIndex = 25
	manualBanner.Parent = cultModal

	local mbCorner = Instance.new("UICorner")
	mbCorner.CornerRadius = UDim.new(0, 5)
	mbCorner.Parent = manualBanner

	local mbStroke = Instance.new("UIStroke")
	mbStroke.Color = GuofengTheme.Colors.GoldBorderDim
	mbStroke.Thickness = 1
	mbStroke.Parent = manualBanner

	local mbLabel = Instance.new("TextLabel")
	mbLabel.Name = "Label"
	mbLabel.Size = UDim2.new(1, 0, 1, 0)
	mbLabel.BackgroundTransparency = 1
	mbLabel.Font = GuofengTheme.Fonts.Body
	mbLabel.Text = "CULTIVATION MANUAL: None"
	mbLabel.TextColor3 = GuofengTheme.Colors.GoldAmber
	mbLabel.TextSize = 11
	mbLabel.ZIndex = 26
	mbLabel.Parent = manualBanner
end
local manualLabel = manualBanner:WaitForChild("Label") :: TextLabel

-- Forward declare updateWheelUI
local updateWheelUI: () -> () = function() end

local function updateStatsDisplay()
	local realm = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 1
	local qi = player:GetAttribute("Qi") or 0
	local maxHealth = player:GetAttribute("MaxHealth") or 100
	local defense = player:GetAttribute("Defense") or 5
	local damage = player:GetAttribute("Damage") or 15
	local weapon = player:GetAttribute("EquippedWeapon") or "None"
	local armor = player:GetAttribute("EquippedArmor") or "None"
	local manual = player:GetAttribute("EquippedManual") or "None"
	local cultivating = player:GetAttribute("Cultivating") or false

	local talentName = player:GetAttribute("Talent") or "Mortal"
	local talentEntry = DestinyConfig.GetTalent(talentName)
	local rootName = player:GetAttribute("SpiritualRoot") or "None"
	local rootEntry = DestinyConfig.GetSpiritualRoot(rootName)

	local reqQi = CultivationConfig.getRequiredQi(realm, level)
	local hasSynergy = player:GetAttribute("ManualSynergy") == true
	local baseRate = CultivationConfig.getBaseQiRate(realm)
	local totalRate = player:GetAttribute("QiRate") or CultivationConfig.calculateQiRate(baseRate, talentEntry.Multiplier, hasSynergy and (rootEntry and rootEntry.Multiplier or 1.0) or 1.0, true)

	-- Update HUD banners
	local stageNum = math.clamp(level <= 0 and 1 or level, 1, 9)
	realmLabel.Text = string.format("* %s - STAGE %d / 9 *", string.upper(realm), stageNum)

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

	qiGatherVal.Text = string.format("+%.1f/s (%s)", totalRate, cultivating and "MEDITATING" or "IDLE")
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

	-- Update Cultivation Manual Banner
	if manual ~= "None" then
		if hasSynergy then
			manualLabel.Text = string.format("MANUAL: %s  |  ELEMENT SYNERGY: ACTIVE (+%.1fx)", manual, rootEntry and rootEntry.Multiplier or 1.5)
			manualLabel.TextColor3 = GuofengTheme.Colors.CyanBright
		else
			manualLabel.Text = string.format("MANUAL: %s  |  NO ELEMENT SYNERGY", manual)
			manualLabel.TextColor3 = GuofengTheme.Colors.GoldAmber
		end
	else
		manualLabel.Text = "MANUAL: None  |  EQUIP AN ELEMENTAL SCRIPTURE FOR SYNERGY"
		manualLabel.TextColor3 = GuofengTheme.Colors.TextMuted
	end

	-- Breakthrough Requirement
	if qi >= reqQi then
		breakProgText.Text = string.format("QI FULL - BREAKTHROUGH AVAILABLE: %d / %d QI", math.floor(qi), reqQi)
		breakProgText.TextColor3 = GuofengTheme.Colors.GoldAmber
		cinnabarBtn.Text = "BREAKTHROUGH REALM"
		cinnabarBtn.BackgroundColor3 = GuofengTheme.Colors.Cinnabar
	else
		breakProgText.Text = string.format("BREAKTHROUGH REQUIREMENT: %d / %d QI (STAGE %d / 9)", math.floor(qi), reqQi, stageNum)
		breakProgText.TextColor3 = GuofengTheme.Colors.CyanBright
		cinnabarBtn.Text = cultivating and "STOP MEDITATION" or "BEGIN MEDITATION"
		cinnabarBtn.BackgroundColor3 = cultivating and GuofengTheme.Colors.CyanDark or GuofengTheme.Colors.DarkJadeElevated
	end

	TweenService:Create(scrollQiFill, TweenInfo.new(0.2), { Size = UDim2.new(qiRatio, 0, 1, 0) }):Play()

	updateWheelUI()
	updateActiveCultivatingCard(qi, reqQi, totalRate)
end

cinnabarBtn.MouseButton1Click:Connect(function()
	local realm = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 1
	local qi = player:GetAttribute("Qi") or 0
	local reqQi = CultivationConfig.getRequiredQi(realm, level)

	if qi >= reqQi then
		remote:FireServer("Breakthrough")
		showNotification("Heavenly Tribulation initiated! Prepare your spirit...", true)
	else
		remote:FireServer("Cultivate")
		local nowCult = not (player:GetAttribute("Cultivating") or false)
		showNotification(nowCult and "Spiritual meditation began." or "Spiritual meditation stopped.")
	end
end)

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
	spinActionBtn.AutoButtonColor = false
	spinActionBtn.Text = "SPINNING..."
	spinActionBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeElevated

	local session = tick()
	currentSpinSession = session

	local disc = getWheelDisc()
	local startRot = disc.Rotation
	if activeSpinTween then
		activeSpinTween:Cancel()
		activeSpinTween = nil
	end

	-- Immediate rapid spin-up acceleration: starts rotating right away!
	activeSpinTween = TweenService:Create(disc, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Rotation = startRot + 720
	})
	activeSpinTween:Play()

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

	-- Safety watchdog: in case of dropped event or network delay, UI recovers cleanly after 8s
	task.delay(8.0, function()
		if isWheelSpinning and currentSpinSession == session then
			isWheelSpinning = false
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
		return cat == "Miscs" or cat == "Misc" or itemDef.Type == "Miscs" or itemDef.Type == "Herb" or itemDef.Type == "Ore"
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
			sStroke.Thickness = 2.5
			sStroke.Color = GuofengTheme.Colors.GoldAmber

			-- Smooth slot pullout animation (Prompt Section 11)
			TweenService:Create(slotBtn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 84, 0, 84),
			}):Play()
			task.delay(0.15, function()
				if slotBtn and slotBtn.Parent then
					TweenService:Create(slotBtn, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(0, 78, 0, 78),
					}):Play()
				end
			end)

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
local shopItemList = shopModal:WaitForChild("ShopList") :: ScrollingFrame

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
		local rate = args[2] or 10
		local curQi = args[3] or (player:GetAttribute("Qi") or 0)
		local maxCap = args[4] or (player:GetAttribute("MaxQi") or 5000)
		showQiGainPopup(gain)
		updateActiveCultivatingCard(curQi, maxCap, rate)
		updateStatsDisplay()
	elseif event == "TribulationPhase" then
		local phase = args[2] or 1
		if phase == 1 then
			showNotification("Phase 1: Entering deep celestial meditation...", true)
			startMeditationAnimation()
		elseif phase == 2 then
			showNotification("Phase 2: Qi surges violently! Tribulation Thunder Cloud gathers above!", true)
		elseif phase == 3 then
			showNotification("Phase 3: Heavenly Lightning strikes from the storm cloud!", true)
			local cam = Workspace.CurrentCamera
			if cam then
				local orig = cam.CFrame
				task.spawn(function()
					for i = 1, 6 do
						cam.CFrame = orig * CFrame.new(math.random(-1, 1) * 0.18, math.random(-1, 1) * 0.18, 0)
						task.wait(0.03)
					end
					cam.CFrame = orig
				end)
			end
		end
	elseif event == "BreakthroughSuccess" then
		local newRealm = args[1] or "Qi Condensation"
		local newStage = args[2] or 1
		showNotification(string.format("TRIBULATION SURPASSED! Ascended to %s Stage %d!", tostring(newRealm), tostring(newStage)), true)
		updateStatsDisplay()
	elseif event == "BreakthroughFailed" then
		showNotification(args[1] or "Breakthrough failed.", true)
	elseif event == "BreakthroughStart" then
		showNotification("Heavenly Tribulation Surpassed! Realm Breakthrough Complete!", true)
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
		if activeSpinTween then
			activeSpinTween:Cancel()
			activeSpinTween = nil
		end

		local curRot = disc.Rotation
		local curNorm = curRot % 360
		local deltaAngle = (targetSliceAngle - curNorm) % 360
		local spins = 5 * 360
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

		-- Smooth 3.2s deceleration animation to the target prize slice
		local spinTween = TweenService:Create(disc, TweenInfo.new(3.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
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

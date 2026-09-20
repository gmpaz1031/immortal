import sys
import os
import re

def upgrade_client_script():
    file_path = 'src/gui/CultivationClient.client.luau'
    with open(file_path, 'r', encoding='utf-8') as f:
        code = f.read()

    # 1. Update Section 3c: Add Procedural Sitting Pose, Qi Particles & Active Cultivating Card
    old_3c_pattern = r'-- ============================================================================\s*-- 3c\. MEDITATION ANIMATION\s*-- ============================================================================\s*local meditationAnim: AnimationTrack\? = nil\s*local function startMeditationAnimation\(\)[\s\S]*?local function stopMeditationAnimation\(\)[\s\S]*?end\s*end'
    
    new_3c = """-- ============================================================================
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
end"""

    match = re.search(old_3c_pattern, code)
    if match:
        code = code[:match.start()] + new_3c + code[match.end():]
        print("Updated Section 3c successfully!")
    else:
        print("Warning: Could not match Section 3c pattern.")

    # 2. Update updateStatsDisplay & CinnabarBtn in Section 6
    # Let's inspect section 6 replacement
    old_section_6_start = '-- 6. CULTIVATION & STATS BINDING'
    old_section_7_start = '-- 7. DESTINY WHEEL CONTROLLER & VISUAL ENGINE'

    s6_idx = code.find(old_section_6_start)
    s7_idx = code.find(old_section_7_start)

    if s6_idx != -1 and s7_idx != -1:
        new_section_6 = """-- 6. CULTIVATION & STATS BINDING
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
"""
        code = code[:s6_idx] + new_section_6 + code[s7_idx:]
        print("Updated Section 6 successfully!")
    else:
        print("Warning: Could not find Section 6 boundaries.")

    # 3. Update Inventory slot click with smooth pullout pop animation
    old_slot_click = """		slotBtn.MouseButton1Click:Connect(function()
			for _, stk in pairs(activeCardStrokes) do
				stk.Thickness = 1.2
			end
			sStroke.Thickness = 2.4
			sStroke.Color = Color3.fromRGB(255, 255, 255)
			selectItem(itmVal, itemDef)
		end)"""

    new_slot_click = """		slotBtn.MouseButton1Click:Connect(function()
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
		end)"""

    if old_slot_click in code:
        code = code.replace(old_slot_click, new_slot_click)
        print("Updated inventory slot pullout animation successfully!")
    else:
        print("Warning: Could not find old_slot_click pattern.")

    # 4. Update Remote Event Handler in Section 10 for QiGainTick, TribulationPhase, BreakthroughSuccess
    old_remote_block = """	if event == "MeditationStart" then
		startMeditationAnimation()
	elseif event == "MeditationStop" then
		stopMeditationAnimation()
	elseif event == "QiGainTick" then
		local gain = args[1] or 10
		showQiGainPopup(gain)
	elseif event == "BreakthroughStart" then
		showNotification("Heavenly Tribulation Surpassed! Realm Breakthrough Complete!", true)"""

    new_remote_block = """	if event == "MeditationStart" then
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
		showNotification("Heavenly Tribulation Surpassed! Realm Breakthrough Complete!", true)"""

    if old_remote_block in code:
        code = code.replace(old_remote_block, new_remote_block)
        print("Updated Section 10 Remote Events successfully!")
    else:
        print("Warning: Could not find old_remote_block pattern.")

    with open('src/gui/CultivationClient.client.luau', 'w', encoding='utf-8') as f:
        f.write(code)

    with open('src/ui/CultivationClient.client.luau', 'w', encoding='utf-8') as f:
        f.write(code)

    print("Both client script files updated successfully!")

if __name__ == '__main__':
    upgrade_client_script()

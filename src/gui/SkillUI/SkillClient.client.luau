--!strict
-- src/gui/SkillUI/SkillClient.client.luau
-- Xianxia RPG Martial Arts Skill Hotbar & Technique Manual Controller
-- Features responsive keybinds, mouse aiming, prompt notifications, and synchronized VFX.
-- ZERO runtime ScreenGui creation — strictly binds to pre-existing edit-mode StarterGui elements.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local ui = script.Parent :: ScreenGui

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SkillConfig = require(Shared:WaitForChild("SkillConfig"))
local SkillFXHelper = require(Shared:WaitForChild("SkillFXHelper"))
local GuofengTheme = require(Shared:WaitForChild("GuofengTheme"))
local IconAssets = require(Shared:WaitForChild("IconAssets"))

-- Skill Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("SkillRemotes") :: Folder
local skillRequestRemote = remotesFolder:WaitForChild("SkillRequest") :: RemoteEvent
local skillReplicateRemote = remotesFolder:WaitForChild("SkillReplicate") :: RemoteEvent
local skillEquipReqRemote = remotesFolder:WaitForChild("SkillEquipRequest") :: RemoteEvent
local skillDataUpdateRemote = remotesFolder:WaitForChild("SkillDataUpdate") :: RemoteEvent

-- Pre-existing StarterGui elements in edit mode
local hotbar = ui:WaitForChild("GuofengSkillHotbar") :: Frame
local bookModal = ui:WaitForChild("MartialArtsBookModal") :: Frame
local closeBookBtn = bookModal:WaitForChild("CloseBtn") :: TextButton
local skillList = bookModal:WaitForChild("SkillList") :: ScrollingFrame

local slotSkills: { [number]: string } = {
	[1] = SkillConfig.DefaultSlots[1] or "Sword Slash",
	[2] = SkillConfig.DefaultSlots[2] or "Flame Ball",
	[3] = SkillConfig.DefaultSlots[3] or "Palm Art",
	[4] = SkillConfig.DefaultSlots[4] or "Thunder Strike",
}

local clientCooldowns: { [string]: number } = {}
local slotFrames: { [number]: Frame } = {}
local slotButtons: { [number]: TextButton } = {}
local slotIcons: { [number]: TextLabel } = {}
local slotIconImages: { [number]: ImageLabel } = {}
local slotNames: { [number]: TextLabel } = {}
local slotCdOverlays: { [number]: Frame } = {}
local slotCdTexts: { [number]: TextLabel } = {}

local lockedTargetModel: Model? = nil
local selectedBookSkill: string? = nil

-- ============================================================================
-- PROMPT NOTIFICATION BANNER
-- ============================================================================
local function showPromptNotification(message: string, color: Color3?)
	local oldBanner = ui:FindFirstChild("PromptBanner")
	if oldBanner then oldBanner:Destroy() end

	local banner = Instance.new("TextLabel")
	banner.Name = "PromptBanner"
	banner.BackgroundColor3 = Color3.fromRGB(12, 26, 22)
	banner.BackgroundTransparency = 0.1
	banner.Size = UDim2.new(0, 360, 0, 40)
	banner.Position = UDim2.new(0.5, -180, 0.72, 0)
	banner.Font = GuofengTheme.Fonts.Header
	banner.Text = message
	banner.TextColor3 = color or GuofengTheme.Colors.GoldLight
	banner.TextSize = 13
	banner.ZIndex = 50
	banner.Parent = ui

	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 8)
	cr.Parent = banner

	local st = Instance.new("UIStroke")
	st.Color = color or GuofengTheme.Colors.GoldBorder
	st.Thickness = 1.8
	st.Parent = banner

	task.spawn(function()
		for i = 1, 15 do
			banner.Position = banner.Position - UDim2.new(0, 0, 0, 1)
			task.wait(0.03)
		end
		task.wait(0.6)
		for i = 1, 15 do
			banner.TextTransparency = i / 15
			banner.BackgroundTransparency = 0.1 + (i / 15) * 0.9
			st.Transparency = i / 15
			task.wait(0.03)
		end
		banner:Destroy()
	end)
end

-- ============================================================================
-- LOCK-ON RETICLE HELPER
-- ============================================================================
local lockOnReticle: BillboardGui? = nil
local function getLockOnReticle(): BillboardGui
	if lockOnReticle and lockOnReticle.Parent then return lockOnReticle end

	local bg = Instance.new("BillboardGui")
	bg.Name = "SkillLockOnReticle"
	bg.Size = UDim2.new(0, 44, 0, 44)
	bg.AlwaysOnTop = true
	bg.ResetOnSpawn = false
	bg.Enabled = false
	bg.Parent = ui

	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.Size = UDim2.new(1, 0, 1, 0)
	ring.BackgroundTransparency = 1
	ring.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Color = GuofengTheme.Colors.RedCrimson
	stroke.Thickness = 2.5
	stroke.Parent = ring

	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(1, 0)
	cr.Parent = ring

	lockOnReticle = bg
	return bg
end

local function updateAimReticle(targetPos: Vector3?, visible: boolean)
	local reticle = getLockOnReticle()
	if visible and targetPos then
		reticle.Enabled = true
		reticle.Adornee = workspace.Terrain
		reticle.ExtentsOffsetWorldSpace = targetPos
	else
		reticle.Enabled = false
	end
end

-- ============================================================================
-- MARTIAL ANIMATIONS & CAMERA HELPERS
-- ============================================================================
local function playCastAnimation(skillName: string)
	local char = localPlayer.Character
	if not char then return end
	local torso = char:FindFirstChild("Torso") :: BasePart?
	local rightShoulder = torso and torso:FindFirstChild("Right Shoulder") :: Motor6D?
	if not rightShoulder then return end

	local origC0 = rightShoulder.C0
	local targetC0 = CFrame.new(1.0, 0.5, -0.5) * CFrame.Angles(math.rad(110), math.rad(-40), math.rad(50))
	if skillName == "Palm Art" then
		targetC0 = CFrame.new(1.0, 0.5, -0.7) * CFrame.Angles(math.rad(90), 0, math.rad(15))
	elseif skillName == "Thunder Strike" then
		targetC0 = CFrame.new(1.0, 1.2, 0) * CFrame.Angles(math.rad(175), math.rad(10), 0)
	end

	local t1 = TweenService:Create(rightShoulder, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = targetC0 })
	t1:Play()
	t1.Completed:Connect(function()
		task.wait(0.14)
		local t2 = TweenService:Create(rightShoulder, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { C0 = origC0 })
		t2:Play()
	end)
end

local function tweakCamera(mode: string, targetPos: Vector3?)
	local camera = workspace.CurrentCamera
	if not camera then return end

	if mode == "Shake" then
		task.spawn(function()
			local origCF = camera.CFrame
			for i = 1, 6 do
				local offset = Vector3.new(math.random(-25, 25) / 100, math.random(-25, 25) / 100, 0)
				camera.CFrame = origCF + offset
				task.wait(0.02)
			end
			camera.CFrame = origCF
		end)
	end
end

local function getMouseAim(): (Vector3, Vector3)
	local camera = workspace.CurrentCamera
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local origin = hrp and hrp.Position or (camera and camera.CFrame.Position or Vector3.zero)

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera and camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local dir = ray and ray.Direction or (camera and camera.CFrame.LookVector or Vector3.new(0, 0, -1))

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if char then params.FilterDescendantsInstances = { char } end

	local hit = workspace:Raycast(origin, dir * 300, params)
	local targetPos = hit and hit.Position or (origin + dir * 60)
	return origin, targetPos
end

local function findTargetUnderMouse(maxDist: number): Model?
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	if not ray then return nil end

	local char = localPlayer.Character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	if char then params.FilterDescendantsInstances = { char } end

	local hit = workspace:Raycast(ray.Origin, ray.Direction * maxDist, params)
	if hit and hit.Instance then
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and model ~= char then
			return model
		end
	end
	return nil
end

-- ============================================================================
-- SLOT VISUAL UPDATE FUNCTION
-- ============================================================================
local function updateSlotVisual(i: number, skillName: string)
	slotSkills[i] = skillName
	local slotOrb = slotFrames[i]
	if not slotOrb then return end

	local skillDef = SkillConfig.Skills[skillName]
	local icn = slotIcons[i]
	local icnImg = slotIconImages[i]
	local nl = slotNames[i]

	local assetId = IconAssets.getSkillIcon(skillName)
	if IconAssets.isUploaded(assetId) then
		if not icnImg then
			icnImg = Instance.new("ImageLabel")
			icnImg.Name = "IconImage"
			icnImg.BackgroundTransparency = 1
			icnImg.Size = UDim2.new(0.75, 0, 0.75, 0)
			icnImg.Position = UDim2.new(0.125, 0, 0.05, 0)
			icnImg.ScaleType = Enum.ScaleType.Fit
			icnImg.ZIndex = 4
			icnImg.Parent = slotOrb
			slotIconImages[i] = icnImg
		end
		icnImg.Image = assetId
		icnImg.Visible = true
		if icn then icn.Visible = false end
	else
		if icnImg then icnImg.Visible = false end
		if icn and skillDef then
			icn.Text = skillDef.Icon or "SS"
			icn.Visible = true
		end
	end
	if nl and skillDef then
		nl.Text = skillDef.DisplayName or skillName
	end
end

-- ============================================================================
-- SLOT ACTIVATION (Combat Casting)
-- ============================================================================
local function activateSlot(slotIdx: number, overrideTargetPos: Vector3?)
	local skillName = slotSkills[slotIdx]
	if not skillName then return end

	local skillDef = SkillConfig.Skills[skillName]
	if not skillDef then return end

	local now = os.clock()
	local nextAllowed = clientCooldowns[skillName] or 0
	if now < nextAllowed then
		showPromptNotification(string.format("%s is on cooldown! (%.1fs)", skillName, nextAllowed - now), GuofengTheme.Colors.RedCrimson)
		return
	end

	local curQi = localPlayer:GetAttribute("Qi") or 0
	if curQi < skillDef.QiCost then
		showPromptNotification(string.format("Insufficient Qi! Requires %d Qi.", skillDef.QiCost), GuofengTheme.Colors.RedCrimson)
		return
	end

	clientCooldowns[skillName] = now + skillDef.Cooldown

	local origin, targetPos = getMouseAim()
	if overrideTargetPos then targetPos = overrideTargetPos end

	local targetModel = nil
	if skillDef.TargetType == "Targeted" then
		targetModel = findTargetUnderMouse(skillDef.Range or 80)
	end

	playCastAnimation(skillName)
	skillRequestRemote:FireServer(skillName, {
		TargetPosition = targetPos,
		TargetModel = targetModel,
		Origin = origin,
	})

	-- Cooldown UI overlay sweep
	local cdOverlay = slotCdOverlays[slotIdx]
	local cdText = slotCdTexts[slotIdx]
	if cdOverlay and cdText then
		cdOverlay.Visible = true
		cdText.Visible = true
		task.spawn(function()
			local duration = skillDef.Cooldown
			local startTime = os.clock()
			while true do
				local elapsed = os.clock() - startTime
				local rem = duration - elapsed
				if rem <= 0 then break end
				cdText.Text = string.format("%.1f", rem)
				cdOverlay.Size = UDim2.new(1, 0, rem / duration, 0)
				task.wait(0.04)
			end
			cdOverlay.Visible = false
			cdText.Visible = false
		end)
	end

	-- Slot press visual bounce
	local slotOrb = slotFrames[slotIdx]
	if slotOrb then
		local origSize = slotOrb.Size
		local stroke = slotOrb:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = GuofengTheme.Colors.GoldLight end

		TweenService:Create(slotOrb, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = origSize + UDim2.new(0, 6, 0, 6),
		}):Play()

		task.delay(0.12, function()
			if slotOrb and slotOrb.Parent then
				TweenService:Create(slotOrb, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = origSize,
				}):Play()
				if stroke and stroke.Parent then
					stroke.Color = GuofengTheme.Colors.CyanGlow
				end
			end
		end)
	end
end

-- ============================================================================
-- 1. SETUP THE 4 EDIT-MODE HOTBAR SLOTS
-- ============================================================================
for i = 1, 4 do
	local slotOrb = hotbar:WaitForChild("SkillSlot_" .. i) :: Frame
	slotFrames[i] = slotOrb

	local skillName = slotSkills[i]
	local skillDef = SkillConfig.Skills[skillName]

	local icn = slotOrb:FindFirstChild("Icon") :: TextLabel?
	local icnImg = slotOrb:FindFirstChild("IconImage") :: ImageLabel?
	local nl = slotOrb:FindFirstChild("Name") :: TextLabel?
	local btn = slotOrb:FindFirstChild("Btn") :: TextButton?
	local cdOverlay = slotOrb:FindFirstChild("CDOverlay") :: Frame?
	local cdText = slotOrb:FindFirstChild("CDText") :: TextLabel?

	slotIcons[i] = icn
	slotIconImages[i] = icnImg
	slotNames[i] = nl
	slotButtons[i] = btn
	slotCdOverlays[i] = cdOverlay
	slotCdTexts[i] = cdText

	-- Initial visual setup
	updateSlotVisual(i, skillName)

	if btn then
		btn.ZIndex = 20
		btn.Active = true
		btn.Selectable = true
		btn.MouseButton1Click:Connect(function()
			if selectedBookSkill then
				-- If a technique is selected in the manual, equip it into this slot!
				skillEquipReqRemote:FireServer("EquipSlot", i, selectedBookSkill)
				showPromptNotification(string.format("Equipped %s into Slot %d!", selectedBookSkill, i), GuofengTheme.Colors.CyanGlow)
				selectedBookSkill = nil
			else
				activateSlot(i)
			end
		end)
	end

	slotOrb.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not selectedBookSkill then
				activateSlot(i)
			end
		end
	end)
end

-- ============================================================================
-- 2. KEYBIND ACTIVATION (1, 2, 3, 4, Keypad 1-4, Z, X, V, F, and K)
-- ============================================================================
local keyToSlot = {
	[Enum.KeyCode.One]         = 1,
	[Enum.KeyCode.Two]         = 2,
	[Enum.KeyCode.Three]       = 3,
	[Enum.KeyCode.Four]        = 4,
	[Enum.KeyCode.KeypadOne]   = 1,
	[Enum.KeyCode.KeypadTwo]   = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour]  = 4,
	[Enum.KeyCode.Z]           = 1,
	[Enum.KeyCode.X]           = 2,
	[Enum.KeyCode.V]           = 3,
	[Enum.KeyCode.F]           = 4,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then return end

	if input.KeyCode == Enum.KeyCode.K then
		bookModal.Visible = not bookModal.Visible
		selectedBookSkill = nil
		return
	end

	local slotIdx = keyToSlot[input.KeyCode]
	if slotIdx then
		if selectedBookSkill then
			skillEquipReqRemote:FireServer("EquipSlot", slotIdx, selectedBookSkill)
			showPromptNotification(string.format("Equipped %s into Slot %d!", selectedBookSkill, slotIdx), GuofengTheme.Colors.CyanGlow)
			selectedBookSkill = nil
		else
			activateSlot(slotIdx)
		end
	end
end)

-- ============================================================================
-- 3. MARTIAL ARTS BOOK MODAL (Technique Manual)
-- ============================================================================
closeBookBtn.MouseButton1Click:Connect(function()
	bookModal.Visible = false
	selectedBookSkill = nil
end)

local function populateBookUI()
	for _, ch in ipairs(skillList:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	for _, skillName in ipairs(SkillConfig.SkillList) do
		local skillDef = SkillConfig.Skills[skillName]
		if not skillDef then continue end

		local card = GuofengTheme.createParchmentCard(skillList, UDim2.new(1, -8, 0, 74), UDim2.new(0, 4, 0, 0))
		card.Name = skillName

		-- Emblem for Icon
		local emblem = Instance.new("Frame")
		emblem.Name = "Emblem"
		emblem.BackgroundColor3 = GuofengTheme.Colors.DarkJadeHeader
		emblem.Size = UDim2.new(0, 52, 0, 52)
		emblem.Position = UDim2.new(0, 10, 0, 11)
		emblem.BorderSizePixel = 0
		emblem.ClipsDescendants = true
		emblem.Parent = card

		local emc = Instance.new("UICorner")
		emc.CornerRadius = UDim.new(1, 0)
		emc.Parent = emblem

		local ems = Instance.new("UIStroke")
		ems.Color = GuofengTheme.Colors.GoldBorder
		ems.Thickness = 1.5
		ems.Parent = emblem

		local skillAssetId = IconAssets.getSkillIcon(skillName)
		if IconAssets.isUploaded(skillAssetId) then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.new(1, 0, 1, 0)
			img.Image = skillAssetId
			img.ScaleType = Enum.ScaleType.Fit
			img.Parent = emblem
		else
			local icn = Instance.new("TextLabel")
			icn.BackgroundTransparency = 1
			icn.Size = UDim2.new(1, 0, 1, 0)
			icn.Font = GuofengTheme.Fonts.Title
			icn.Text = skillDef.Icon or "SS"
			icn.TextSize = 24
			icn.TextColor3 = Color3.fromRGB(255, 255, 255)
			icn.Parent = emblem
		end

		-- Name
		local nameLab = Instance.new("TextLabel")
		nameLab.BackgroundTransparency = 1
		nameLab.Size = UDim2.new(0, 220, 0, 22)
		nameLab.Position = UDim2.new(0, 70, 0, 6)
		nameLab.Font = GuofengTheme.Fonts.Header
		nameLab.Text = skillDef.DisplayName or skillDef.Name
		nameLab.TextColor3 = GuofengTheme.Colors.GoldLight
		nameLab.TextSize = 13
		nameLab.TextXAlignment = Enum.TextXAlignment.Left
		nameLab.Parent = card

		-- Stats line
		local statLab = Instance.new("TextLabel")
		statLab.BackgroundTransparency = 1
		statLab.Size = UDim2.new(0, 240, 0, 18)
		statLab.Position = UDim2.new(0, 70, 0, 28)
		statLab.Font = GuofengTheme.Fonts.Header
		statLab.Text = string.format("QI: %d  |  CD: %.1fs  |  POWER: %d", skillDef.QiCost, skillDef.Cooldown, skillDef.Damage or 0)
		statLab.TextColor3 = GuofengTheme.Colors.CyanGlow
		statLab.TextSize = 10
		statLab.TextXAlignment = Enum.TextXAlignment.Left
		statLab.Parent = card

		-- Description
		local descLab = Instance.new("TextLabel")
		descLab.BackgroundTransparency = 1
		descLab.Size = UDim2.new(0, 240, 0, 20)
		descLab.Position = UDim2.new(0, 70, 0, 48)
		descLab.Font = GuofengTheme.Fonts.Body
		descLab.Text = skillDef.Description or ""
		descLab.TextColor3 = GuofengTheme.Colors.TextMuted
		descLab.TextSize = 10
		descLab.TextXAlignment = Enum.TextXAlignment.Left
		descLab.Parent = card

		-- Equip Button / Badge
		local equipBtn = Instance.new("TextButton")
		equipBtn.Name = "EquipBtn"
		equipBtn.BackgroundColor3 = GuofengTheme.Colors.DarkJadeCard
		equipBtn.Size = UDim2.new(0, 85, 0, 30)
		equipBtn.Position = UDim2.new(1, -95, 0, 22)
		equipBtn.Font = GuofengTheme.Fonts.Header
		equipBtn.Text = "EQUIP"
		equipBtn.TextColor3 = GuofengTheme.Colors.GoldLight
		equipBtn.TextSize = 11
		equipBtn.Parent = card

		local ebc = Instance.new("UICorner")
		ebc.CornerRadius = UDim.new(0, 5)
		ebc.Parent = equipBtn

		local ebs = Instance.new("UIStroke")
		ebs.Color = GuofengTheme.Colors.GoldBorderDim
		ebs.Thickness = 1.2
		ebs.Parent = equipBtn

		equipBtn.MouseButton1Click:Connect(function()
			selectedBookSkill = skillName
			showPromptNotification(string.format("Selected %s. Press 1-4, Z/X/V/F, or click a hotbar slot to equip!", skillName), GuofengTheme.Colors.GoldLight)
		end)
	end
end

populateBookUI()

-- ============================================================================
-- 4. REPLICATE AND PLAY SKILL VISUALS & SOUNDS
-- ============================================================================
skillReplicateRemote.OnClientEvent:Connect(function(actionName: string, ...)
	SkillFXHelper.playSkillFX(actionName, ...)
end)

-- ============================================================================
-- 5. SERVER EQUIPPED SLOTS SYNCHRONIZATION
-- ============================================================================
local function applyEquippedSlots(data: any)
	if typeof(data) == "table" then
		for slot = 1, 4 do
			local sName = data[slot] or data[tostring(slot)]
			if typeof(sName) == "string" and SkillConfig.Skills[sName] then
				updateSlotVisual(slot, sName)
			end
		end
	end
end

skillDataUpdateRemote.OnClientEvent:Connect(function(action: string, data: any)
	if (action == "SyncEquipped" or action == "SyncSlots") and typeof(data) == "table" then
		applyEquippedSlots(data)
	end
end)

-- Initial slot sync from player attributes and reactive updates
for slot = 1, 4 do
	local attr = localPlayer:GetAttribute("SkillSlot" .. slot)
	if typeof(attr) == "string" and SkillConfig.Skills[attr] then
		updateSlotVisual(slot, attr)
	end
	localPlayer:GetAttributeChangedSignal("SkillSlot" .. slot):Connect(function()
		local updated = localPlayer:GetAttribute("SkillSlot" .. slot)
		if typeof(updated) == "string" and SkillConfig.Skills[updated] then
			updateSlotVisual(slot, updated)
		end
	end)
end

print("[SkillClient] Martial Arts Hotbar initialized cleanly with zero runtime ScreenGui creation.")

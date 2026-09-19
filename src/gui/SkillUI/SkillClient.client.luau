--!strict
--[[
    SkillClient.client.luau
    Anime Combat Skill System — Client HUD Controller.
    Handles:
      • 4-slot hotbar at bottom-center (Z / X / V / F)
      • Skill Book modal toggled with K
      • Cooldown overlays + countdown text
      • Lock-on reticle for Flame Spear
      • Procedural cast animations
      • VFX replication via SkillFXHelper
      • Communicates with SkillService (server) via SkillRemotes
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

-- Shared modules
local Shared        = ReplicatedStorage:WaitForChild("Shared")
local SkillConfig   = require(Shared:WaitForChild("SkillConfig"))
local SkillFXHelper = require(Shared:WaitForChild("SkillFXHelper"))

-- Remotes (created by server SkillService / project.json)
local remotesFolder         = ReplicatedStorage:WaitForChild("SkillRemotes") :: Folder
local skillRequestRemote    = remotesFolder:WaitForChild("SkillRequest")    :: RemoteEvent
local skillReplicateRemote  = remotesFolder:WaitForChild("SkillReplicate")  :: RemoteEvent
local skillEquipReqRemote   = remotesFolder:WaitForChild("SkillEquipRequest") :: RemoteEvent
local skillDataUpdateRemote = remotesFolder:WaitForChild("SkillDataUpdate")  :: RemoteEvent

--------------------------------------------------------------------------------
-- ScreenGui Setup — robust fallback
--------------------------------------------------------------------------------
local screenGui: ScreenGui
do
	local existing = playerGui:FindFirstChild("SkillUI")
	if existing and existing:IsA("ScreenGui") then
		screenGui = existing :: ScreenGui
	elseif script.Parent:IsA("ScreenGui") then
		screenGui = script.Parent :: ScreenGui
	else
		-- Last resort: create our own ScreenGui
		local sg = Instance.new("ScreenGui")
		sg.Name           = "SkillUI"
		sg.ResetOnSpawn   = false
		sg.DisplayOrder   = 5
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent         = playerGui
		screenGui = sg
	end
	screenGui.Enabled = true
end

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
-- Slots: Z=1, X=2, V=3, F=4
local slotKeyCodes: { [number]: Enum.KeyCode } = {
	[1] = Enum.KeyCode.Z,
	[2] = Enum.KeyCode.X,
	[3] = Enum.KeyCode.V,
	[4] = Enum.KeyCode.F,
}
local slotKeyNames: { [number]: string } = {
	[1] = "Z", [2] = "X", [3] = "V", [4] = "F",
}

local equippedSlots: { [number]: string } = {
	[1] = SkillConfig.DefaultSlots[1] or "",
	[2] = SkillConfig.DefaultSlots[2] or "",
	[3] = SkillConfig.DefaultSlots[3] or "",
	[4] = SkillConfig.DefaultSlots[4] or "",
}

local clientCooldowns: { [string]: number } = {}
local lockedTargetModel: Model? = nil

-- UI References
local slotUIButtons:      { [number]: Frame }     = {}
local slotCooldownFrames: { [number]: Frame }     = {}
local slotCooldownTexts:  { [number]: TextLabel } = {}
local slotIconLabels:     { [number]: TextLabel } = {}
local slotNameLabels:     { [number]: TextLabel } = {}
local slotKeyLabels:      { [number]: TextLabel } = {}

--------------------------------------------------------------------------------
-- Color Palette
--------------------------------------------------------------------------------
local DARK_BG    = Color3.fromRGB(12,  14,  22)
local MID_BG     = Color3.fromRGB(20,  24,  36)
local BORDER_CLR = Color3.fromRGB(60,  80, 130)
local TEXT_WHITE = Color3.fromRGB(240, 245, 255)
local GOLD_CLR   = Color3.fromRGB(255, 200, 60)
local DIM_TEXT   = Color3.fromRGB(140, 150, 175)

--------------------------------------------------------------------------------
-- Helper: rounded corner
--------------------------------------------------------------------------------
local function addCorner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function addStroke(parent: Instance, color: Color3?, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color     = color or BORDER_CLR
	s.Thickness = thickness or 1.5
	s.Parent    = parent
	return s
end

--------------------------------------------------------------------------------
-- Build Hotbar
--------------------------------------------------------------------------------
local hotbarFrame: Frame

local function buildHotbar()
	if hotbarFrame then hotbarFrame:Destroy() end

	hotbarFrame = Instance.new("Frame")
	hotbarFrame.Name            = "SkillHotbar"
	hotbarFrame.Size            = UDim2.new(0, 340, 0, 88)
	hotbarFrame.Position        = UDim2.new(0.5, -170, 1, -106)
	hotbarFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	hotbarFrame.BackgroundTransparency = 0.55
	hotbarFrame.BorderSizePixel = 0
	hotbarFrame.Parent          = screenGui
	addCorner(hotbarFrame, 12)
	addStroke(hotbarFrame, BORDER_CLR, 1.5)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection  = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment   = Enum.VerticalAlignment.Center
	layout.Padding        = UDim.new(0, 7)
	layout.Parent         = hotbarFrame

	for slot = 1, 4 do
		local skillName = equippedSlots[slot] or ""
		local skillDef  = SkillConfig.Skills[skillName]

		-- Slot card
		local card = Instance.new("Frame")
		card.Name   = "Slot" .. slot
		card.Size   = UDim2.new(0, 76, 0, 76)
		card.BackgroundColor3 = MID_BG
		card.BorderSizePixel  = 0
		card.Parent = hotbarFrame
		addCorner(card, 10)
		addStroke(card, skillDef and skillDef.Color or BORDER_CLR, 2)

		-- Cooldown overlay (sweeps from top)
		local cdOverlay = Instance.new("Frame")
		cdOverlay.Name   = "CooldownOverlay"
		cdOverlay.Size   = UDim2.new(1, 0, 0, 0)
		cdOverlay.Position = UDim2.new(0, 0, 0, 0)
		cdOverlay.AnchorPoint = Vector2.new(0, 0)
		cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		cdOverlay.BackgroundTransparency = 0.35
		cdOverlay.BorderSizePixel = 0
		cdOverlay.ZIndex  = 3
		cdOverlay.Visible = false
		cdOverlay.Parent  = card
		addCorner(cdOverlay, 10)

		-- Cooldown countdown text
		local cdText = Instance.new("TextLabel")
		cdText.Name   = "CooldownText"
		cdText.Size   = UDim2.new(1, 0, 1, 0)
		cdText.BackgroundTransparency = 1
		cdText.Text       = ""
		cdText.TextColor3 = TEXT_WHITE
		cdText.TextSize   = 17
		cdText.Font       = Enum.Font.GothamBold
		cdText.ZIndex     = 4
		cdText.Visible    = false
		cdText.Parent     = card

		-- Skill icon symbol (large emoji/text)
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name  = "Icon"
		iconLabel.Size  = UDim2.new(1, 0, 0, 38)
		iconLabel.Position = UDim2.new(0, 0, 0, 8)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text       = skillDef and skillDef.IconSymbol or "?"
		iconLabel.TextColor3 = skillDef and skillDef.Color or DIM_TEXT
		iconLabel.TextSize   = 26
		iconLabel.Font       = Enum.Font.GothamBold
		iconLabel.ZIndex     = 2
		iconLabel.Parent     = card

		-- Short skill name (1 word)
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name  = "SkillName"
		nameLabel.Size  = UDim2.new(1, -4, 0, 14)
		nameLabel.Position = UDim2.new(0, 2, 0, 46)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text       = skillDef and skillDef.Name:match("^%S+") or "-"
		nameLabel.TextColor3 = DIM_TEXT
		nameLabel.TextSize   = 10
		nameLabel.Font       = Enum.Font.Gotham
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.ZIndex     = 2
		nameLabel.Parent     = card

		-- Keybind label at bottom
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name  = "KeyBind"
		keyLabel.Size  = UDim2.new(1, 0, 0, 14)
		keyLabel.Position = UDim2.new(0, 0, 1, -16)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Text       = "[" .. slotKeyNames[slot] .. "]"
		keyLabel.TextColor3 = GOLD_CLR
		keyLabel.TextSize   = 11
		keyLabel.Font       = Enum.Font.GothamBold
		keyLabel.ZIndex     = 2
		keyLabel.Parent     = card

		-- Hover effect
		card.MouseEnter:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.1), {
				BackgroundColor3 = Color3.fromRGB(30, 36, 54),
			}):Play()
		end)
		card.MouseLeave:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.1), {
				BackgroundColor3 = MID_BG,
			}):Play()
		end)

		slotUIButtons[slot]      = card
		slotCooldownFrames[slot] = cdOverlay
		slotCooldownTexts[slot]  = cdText
		slotIconLabels[slot]     = iconLabel
		slotNameLabels[slot]     = nameLabel
		slotKeyLabels[slot]      = keyLabel
	end
end

local function refreshHotbarUI()
	for slot = 1, 4 do
		local skillName = equippedSlots[slot] or ""
		local skillDef  = SkillConfig.Skills[skillName]
		local card      = slotUIButtons[slot]
		if not card then continue end

		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = skillDef and skillDef.Color or BORDER_CLR
		end

		if slotIconLabels[slot] then
			slotIconLabels[slot].Text       = skillDef and skillDef.IconSymbol or "?"
			slotIconLabels[slot].TextColor3 = skillDef and skillDef.Color or DIM_TEXT
		end
		if slotNameLabels[slot] then
			slotNameLabels[slot].Text = skillDef and skillDef.Name:match("^%S+") or "-"
		end
	end
end

--------------------------------------------------------------------------------
-- Skill Book Toggle Button (bottom-left)
--------------------------------------------------------------------------------
local bookToggleBtn: TextButton
local bookModal:     Frame
local skillListContainer: ScrollingFrame
local modalSlotBarSlots: { Frame } = {}
local toggleSkillBook: () -> ()

local function buildBookToggleButton()
	bookToggleBtn = Instance.new("TextButton")
	bookToggleBtn.Name            = "SkillBookToggle"
	bookToggleBtn.Size            = UDim2.new(0, 120, 0, 38)
	bookToggleBtn.Position        = UDim2.new(0, 14, 1, -56)
	bookToggleBtn.BackgroundColor3 = DARK_BG
	bookToggleBtn.BorderSizePixel  = 0
	bookToggleBtn.Text             = "⚡ Skills [K]"
	bookToggleBtn.TextColor3       = GOLD_CLR
	bookToggleBtn.TextSize         = 14
	bookToggleBtn.Font             = Enum.Font.GothamBold
	bookToggleBtn.Parent           = screenGui
	addCorner(bookToggleBtn, 8)
	addStroke(bookToggleBtn, GOLD_CLR, 1.5)

	bookToggleBtn.Activated:Connect(function()
		if toggleSkillBook then
			toggleSkillBook()
		end
	end)
end

local function buildSkillBookModal()
	bookModal = Instance.new("Frame")
	bookModal.Name            = "SkillBookModal"
	bookModal.Size            = UDim2.new(0, 480, 0, 520)
	bookModal.Position        = UDim2.new(0.5, -240, 0.5, -260)
	bookModal.BackgroundColor3 = DARK_BG
	bookModal.BackgroundTransparency = 0.08
	bookModal.BorderSizePixel  = 0
	bookModal.Visible          = false
	bookModal.ZIndex           = 10
	bookModal.Parent           = screenGui
	addCorner(bookModal, 14)
	addStroke(bookModal, GOLD_CLR, 2)

	-- Title bar
	local title = Instance.new("TextLabel")
	title.Size   = UDim2.new(1, -20, 0, 38)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text       = "⚔️  Skill Book"
	title.TextColor3 = GOLD_CLR
	title.TextSize   = 20
	title.Font       = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex     = 11
	title.Parent     = bookModal

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size   = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -40, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
	closeBtn.Text       = "✕"
	closeBtn.TextColor3 = TEXT_WHITE
	closeBtn.TextSize   = 16
	closeBtn.Font       = Enum.Font.GothamBold
	closeBtn.ZIndex     = 12
	closeBtn.Parent     = bookModal
	addCorner(closeBtn, 6)
	closeBtn.Activated:Connect(function()
		bookModal.Visible = false
	end)

	-- Divider line
	local div = Instance.new("Frame")
	div.Size   = UDim2.new(1, -20, 0, 1)
	div.Position = UDim2.new(0, 10, 0, 50)
	div.BackgroundColor3 = BORDER_CLR
	div.BorderSizePixel  = 0
	div.ZIndex = 11
	div.Parent = bookModal

	-- Equipped slot bar label
	local slotBarLabel = Instance.new("TextLabel")
	slotBarLabel.Size   = UDim2.new(1, -20, 0, 18)
	slotBarLabel.Position = UDim2.new(0, 10, 0, 58)
	slotBarLabel.BackgroundTransparency = 1
	slotBarLabel.Text       = "Equipped Slots  (click to clear)"
	slotBarLabel.TextColor3 = DIM_TEXT
	slotBarLabel.TextSize   = 12
	slotBarLabel.Font       = Enum.Font.Gotham
	slotBarLabel.TextXAlignment = Enum.TextXAlignment.Left
	slotBarLabel.ZIndex     = 11
	slotBarLabel.Parent     = bookModal

	-- Slot mini-bar (4 mini slots)
	local slotBar = Instance.new("Frame")
	slotBar.Size   = UDim2.new(1, -20, 0, 60)
	slotBar.Position = UDim2.new(0, 10, 0, 78)
	slotBar.BackgroundTransparency = 1
	slotBar.ZIndex = 11
	slotBar.Parent = bookModal

	local slotLayout = Instance.new("UIListLayout")
	slotLayout.FillDirection  = Enum.FillDirection.Horizontal
	slotLayout.Padding        = UDim.new(0, 6)
	slotLayout.Parent         = slotBar

	for s = 1, 4 do
		local miniSlot = Instance.new("TextButton")
		miniSlot.Size   = UDim2.new(0, 100, 0, 58)
		miniSlot.BackgroundColor3 = MID_BG
		miniSlot.BorderSizePixel  = 0
		miniSlot.Text       = slotKeyNames[s] .. "\n" .. (equippedSlots[s] or "-")
		miniSlot.TextColor3 = GOLD_CLR
		miniSlot.TextSize   = 11
		miniSlot.Font       = Enum.Font.GothamBold
		miniSlot.TextWrapped = true
		miniSlot.ZIndex     = 12
		miniSlot.Parent     = slotBar
		addCorner(miniSlot, 8)
		addStroke(miniSlot, BORDER_CLR, 1.5)

		local capturedSlot = s
		miniSlot.Activated:Connect(function()
			equippedSlots[capturedSlot] = ""
			skillEquipReqRemote:FireServer("UnequipSlot", capturedSlot, "")
			refreshHotbarUI()
		end)

		modalSlotBarSlots[s] = miniSlot
	end

	-- Divider
	local div2 = Instance.new("Frame")
	div2.Size   = UDim2.new(1, -20, 0, 1)
	div2.Position = UDim2.new(0, 10, 0, 144)
	div2.BackgroundColor3 = BORDER_CLR
	div2.BorderSizePixel  = 0
	div2.ZIndex = 11
	div2.Parent = bookModal

	-- Skill list label
	local listLabel = Instance.new("TextLabel")
	listLabel.Size   = UDim2.new(1, -20, 0, 18)
	listLabel.Position = UDim2.new(0, 10, 0, 150)
	listLabel.BackgroundTransparency = 1
	listLabel.Text       = "All Skills  (click to equip)"
	listLabel.TextColor3 = DIM_TEXT
	listLabel.TextSize   = 12
	listLabel.Font       = Enum.Font.Gotham
	listLabel.TextXAlignment = Enum.TextXAlignment.Left
	listLabel.ZIndex     = 11
	listLabel.Parent     = bookModal

	-- Scrollable skill list
	skillListContainer = Instance.new("ScrollingFrame")
	skillListContainer.Size   = UDim2.new(1, -20, 0, 310)
	skillListContainer.Position = UDim2.new(0, 10, 0, 172)
	skillListContainer.BackgroundColor3 = MID_BG
	skillListContainer.BackgroundTransparency = 0.3
	skillListContainer.BorderSizePixel  = 0
	skillListContainer.ScrollBarThickness = 4
	skillListContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	skillListContainer.ZIndex    = 11
	skillListContainer.Parent    = bookModal
	addCorner(skillListContainer, 8)

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.Padding       = UDim.new(0, 5)
	listLayout.Parent        = skillListContainer
end

local function renderModalSlotBar()
	for s = 1, 4 do
		local btn = modalSlotBarSlots[s]
		if btn then
			local skillName = equippedSlots[s] or ""
			local skillDef  = SkillConfig.Skills[skillName]
			btn.Text        = slotKeyNames[s] .. "\n" .. (skillName ~= "" and skillName or "-")
			btn.TextColor3  = skillDef and skillDef.Color or DIM_TEXT
			local stroke = btn:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = skillDef and skillDef.Color or BORDER_CLR end
		end
	end
end

local function renderSkillList()
	-- Clear old entries
	for _, child in ipairs(skillListContainer:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	local totalHeight = 0
	for _, skillName in ipairs(SkillConfig.SkillList) do
		local skillDef = SkillConfig.Skills[skillName]
		if not skillDef then continue end

		local row = Instance.new("TextButton")
		row.Size   = UDim2.new(1, -8, 0, 62)
		row.BackgroundColor3 = DARK_BG
		row.BorderSizePixel  = 0
		row.Text             = ""
		row.ZIndex           = 12
		row.Parent           = skillListContainer
		addCorner(row, 8)

		-- Icon
		local icon = Instance.new("TextLabel")
		icon.Size   = UDim2.new(0, 48, 0, 48)
		icon.Position = UDim2.new(0, 8, 0, 7)
		icon.BackgroundTransparency = 1
		icon.Text       = skillDef.IconSymbol
		icon.TextColor3 = skillDef.Color
		icon.TextSize   = 30
		icon.Font       = Enum.Font.GothamBold
		icon.ZIndex     = 13
		icon.Parent     = row

		-- Name
		local nameL = Instance.new("TextLabel")
		nameL.Size   = UDim2.new(1, -130, 0, 20)
		nameL.Position = UDim2.new(0, 62, 0, 8)
		nameL.BackgroundTransparency = 1
		nameL.Text       = skillDef.Name
		nameL.TextColor3 = TEXT_WHITE
		nameL.TextSize   = 14
		nameL.Font       = Enum.Font.GothamBold
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.ZIndex     = 13
		nameL.Parent     = row

		-- Stats line
		local stats = Instance.new("TextLabel")
		stats.Size   = UDim2.new(1, -130, 0, 16)
		stats.Position = UDim2.new(0, 62, 0, 26)
		stats.BackgroundTransparency = 1
		stats.Text       = string.format("DMG: %d   CD: %.1fs   Range: %d", skillDef.BaseDamage, skillDef.Cooldown, skillDef.Range)
		stats.TextColor3 = DIM_TEXT
		stats.TextSize   = 11
		stats.Font       = Enum.Font.Gotham
		stats.TextXAlignment = Enum.TextXAlignment.Left
		stats.ZIndex     = 13
		stats.Parent     = row

		-- Description
		local desc = Instance.new("TextLabel")
		desc.Size   = UDim2.new(1, -130, 0, 14)
		desc.Position = UDim2.new(0, 62, 0, 42)
		desc.BackgroundTransparency = 1
		desc.Text       = skillDef.Description
		desc.TextColor3 = DIM_TEXT
		desc.TextSize   = 10
		desc.Font       = Enum.Font.Gotham
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextTruncate   = Enum.TextTruncate.AtEnd
		desc.ZIndex     = 13
		desc.Parent     = row

		-- Equip buttons (slots 1-4)
		for s = 1, 4 do
			local slotBtn = Instance.new("TextButton")
			slotBtn.Size   = UDim2.new(0, 28, 0, 28)
			slotBtn.Position = UDim2.new(1, -136 + (s - 1) * 32, 0, 17)
			slotBtn.BackgroundColor3 = MID_BG
			slotBtn.BorderSizePixel  = 0
			slotBtn.Text       = slotKeyNames[s]
			slotBtn.TextColor3 = equippedSlots[s] == skillName and skillDef.Color or DIM_TEXT
			slotBtn.TextSize   = 12
			slotBtn.Font       = Enum.Font.GothamBold
			slotBtn.ZIndex     = 14
			slotBtn.Parent     = row
			addCorner(slotBtn, 5)

			local capturedSlot = s
			local capturedSkill = skillName
			slotBtn.Activated:Connect(function()
				equippedSlots[capturedSlot] = capturedSkill
				skillEquipReqRemote:FireServer("EquipSlot", capturedSlot, capturedSkill)
				refreshHotbarUI()
				renderModalSlotBar()
				renderSkillList()
			end)
		end

		totalHeight = totalHeight + 67
	end

	skillListContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

toggleSkillBook = function()
	if not bookModal then
		buildSkillBookModal()
	end
	if not bookModal then return end

	bookModal.Visible = not bookModal.Visible
	if bookModal.Visible then
		renderModalSlotBar()
		renderSkillList()

		-- Pop-in animation
		bookModal.Size = UDim2.new(0, 380, 0, 420)
		TweenService:Create(bookModal, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size     = UDim2.new(0, 480, 0, 520),
			Position = UDim2.new(0.5, -240, 0.5, -260),
		}):Play()
	end
end

-- Initialize UI immediately so HUD and toggle button appear with zero delay
buildHotbar()
buildBookToggleButton()
buildSkillBookModal()
refreshHotbarUI()

--------------------------------------------------------------------------------
-- Lock-On Reticle for Flame Spear
--------------------------------------------------------------------------------
local reticle: SelectionBox

local function ensureLockOnReticle(): SelectionBox
	if not reticle then
		reticle = Instance.new("SelectionBox")
		reticle.Color3       = Color3.fromRGB(255, 160, 20)
		reticle.LineThickness = 0.08
		reticle.SurfaceTransparency = 0.85
		reticle.SurfaceColor3 = Color3.fromRGB(255, 160, 20)
		reticle.Visible      = false
		reticle.Parent       = Workspace
	end
	return reticle
end

local function updateLockOnTarget(): Model?
	local character = localPlayer.Character
	if not character then return nil end

	local camera = workspace.CurrentCamera
	if not camera then return nil end

	local camPos = camera.CFrame.Position
	local camDir = camera.CFrame.LookVector

	local best: Model?     = nil
	local bestScore        = math.huge
	local maxRange         = SkillConfig.Skills["Flame Spear"] and SkillConfig.Skills["Flame Spear"].Range or 70

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Humanoid") and obj.Health > 0 then
			local model = obj.Parent :: Model?
			if model and model ~= character then
				local root = model:FindFirstChild("HumanoidRootPart")
					or model:FindFirstChild("Torso")
				if root and root:IsA("BasePart") then
					local toTarget = root.Position - camPos
					local dist     = toTarget.Magnitude
					if dist <= maxRange then
						local dot    = toTarget.Unit:Dot(camDir)
						local angle  = math.acos(math.clamp(dot, -1, 1))
						local score  = angle * 2 + dist * 0.01
						if angle < math.rad(35) and score < bestScore then
							bestScore = score
							best = model
						end
					end
				end
			end
		end
	end

	return best
end

--------------------------------------------------------------------------------
-- Procedural Cast Animation (arm swing via BodyGyro / Weld trick)
--------------------------------------------------------------------------------
local function playProceduralCastAnim(skillName: string)
	local character = localPlayer.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	-- We don't have custom animations — just do a quick camera punch
	local camera = workspace.CurrentCamera
	if not camera then return end

	local skillDef = SkillConfig.Skills[skillName]
	local castTime = (skillDef and skillDef.CastTime) or 0.25

	-- Brief upward punch with tween
	local punchCF = camera.CFrame * CFrame.Angles(-0.12, 0.06, 0)
	TweenService:Create(camera, TweenInfo.new(castTime * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = punchCF,
	}):Play()
	task.delay(castTime * 0.5, function()
		TweenService:Create(camera, TweenInfo.new(castTime * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			CFrame = camera.CFrame,
		}):Play()
	end)
end

--------------------------------------------------------------------------------
-- Aim / Target Helper
--------------------------------------------------------------------------------
local function getAimTarget(range: number): (Vector3, Vector3)
	local camera    = workspace.CurrentCamera
	local character = localPlayer.Character
	if not camera or not character then
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local origin = root and root.Position or Vector3.zero
		return origin + Vector3.new(0, 0, -range), -Vector3.zAxis
	end

	local camCF  = camera.CFrame
	local origin = camCF.Position
	local dir    = camCF.LookVector

	-- Raycast to find what the camera is pointed at
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(origin, dir * range, rayParams)
	local targetPos = result and result.Position or (origin + dir * range)

	return targetPos, dir
end

--------------------------------------------------------------------------------
-- Slot Activation
--------------------------------------------------------------------------------
local function activateSlot(slotIdx: number)
	local skillName = equippedSlots[slotIdx]
	if not skillName or skillName == "" then return end

	local skillDef = SkillConfig.Skills[skillName]
	if not skillDef then return end

	-- Client-side cooldown gate
	local now = tick()
	if clientCooldowns[skillName] and clientCooldowns[skillName] > now then
		-- Flash slot red to indicate on cooldown
		local card = slotUIButtons[slotIdx]
		if card then
			local origColor = card.BackgroundColor3
			TweenService:Create(card, TweenInfo.new(0.08), { BackgroundColor3 = Color3.fromRGB(120, 30, 30) }):Play()
			task.delay(0.15, function()
				TweenService:Create(card, TweenInfo.new(0.12), { BackgroundColor3 = origColor }):Play()
			end)
		end
		return
	end

	-- Set optimistic client-side cooldown
	clientCooldowns[skillName] = now + skillDef.Cooldown

	-- Visual Click Bounce
	local slotFrame = slotUIButtons[slotIdx]
	TweenService:Create(slotFrame, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 82, 0, 82),
	}):Play()
	task.delay(0.08, function()
		TweenService:Create(slotFrame, TweenInfo.new(0.12), { Size = UDim2.new(0, 76, 0, 76) }):Play()
	end)

	-- Procedural cast animation
	playProceduralCastAnim(skillName)

	-- Gather aim / target data
	local targetPos, aimDir = getAimTarget(skillDef.Range or 60)

	local targetData = {
		AimDirection  = aimDir,
		TargetPosition = targetPos,
		TargetModel    = (skillName == "Flame Spear") and lockedTargetModel or nil,
	}

	-- Send authoritative request to server
	skillRequestRemote:FireServer(skillName, targetData)
end

--------------------------------------------------------------------------------
-- Keybind Input Listener  (Z, X, V, F  +  K for Skill Book)
--------------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then
		return
	end

	if input.KeyCode == Enum.KeyCode.K then
		toggleSkillBook()
		return
	end

	for slotIdx = 1, 4 do
		if input.KeyCode == slotKeyCodes[slotIdx] then
			activateSlot(slotIdx)
			break
		end
	end
end)

--------------------------------------------------------------------------------
-- Cooldown & Lock-On Render Loop
--------------------------------------------------------------------------------
local _reticle = ensureLockOnReticle()

RunService.RenderStepped:Connect(function()
	local now = tick()

	-- 1. Update Hotbar Cooldown Sweeps & Numbers
	for slotIdx = 1, 4 do
		local skillName = equippedSlots[slotIdx]
		local skillDef  = SkillConfig.Skills[skillName]
		local cdOverlay = slotCooldownFrames[slotIdx]
		local cdText    = slotCooldownTexts[slotIdx]

		if skillDef and clientCooldowns[skillName] then
			local remaining = clientCooldowns[skillName] - now
			if remaining > 0 then
				cdOverlay.Visible = true
				cdText.Visible    = true

				local frac     = math.clamp(remaining / skillDef.Cooldown, 0, 1)
				cdOverlay.Size = UDim2.new(1, 0, frac, 0)
				cdText.Text    = string.format("%.1f", remaining)
			else
				cdOverlay.Visible = false
				cdText.Visible    = false
			end
		else
			if cdOverlay then cdOverlay.Visible = false end
			if cdText    then cdText.Visible    = false end
		end
	end

	-- 2. Update Lock-on Target for Flame Spear
	local hasFlameSpear = false
	for slot = 1, 4 do
		if equippedSlots[slot] == "Flame Spear" then
			hasFlameSpear = true
			break
		end
	end

	if hasFlameSpear then
		lockedTargetModel = updateLockOnTarget()
		if lockedTargetModel and lockedTargetModel.Parent then
			local tRoot = lockedTargetModel:FindFirstChild("HumanoidRootPart")
				or lockedTargetModel:FindFirstChild("Torso")
			if tRoot then
				reticle.Adornee = tRoot :: BasePart
				reticle.Visible = true
			else
				reticle.Visible = false
			end
		else
			reticle.Visible = false
		end
	else
		reticle.Visible = false
	end
end)

--------------------------------------------------------------------------------
-- Server Replication Listener (plays anime VFX for all clients)
--------------------------------------------------------------------------------
skillReplicateRemote.OnClientEvent:Connect(function(action: string, ...)
	local args = { ... }

	if action == "SwordSlash" then
		local casterChar, origin, dir, range, speed = args[1], args[2], args[3], args[4], args[5]
		if casterChar then
			SkillFXHelper.playSwordSlash(casterChar, origin, dir, range, speed)
		end
	elseif action == "PalmArt" then
		local casterChar, origin, lookDir, radius = args[1], args[2], args[3], args[4]
		if casterChar then
			SkillFXHelper.playPalmArt(casterChar, origin, lookDir, radius)
		end
	elseif action == "FlameBall" then
		local casterChar, origin, targetPos, speed, radius = args[1], args[2], args[3], args[4], args[5]
		if casterChar then
			SkillFXHelper.playFlameBall(casterChar, origin, targetPos, speed, radius)
		end
	elseif action == "ThunderStrike" then
		local targetPos, radius, warningDuration = args[1], args[2], args[3]
		SkillFXHelper.playThunderStrike(targetPos, radius, warningDuration)
	elseif action == "MultipleSwords" then
		local casterChar, origin, targetPos, count, speed = args[1], args[2], args[3], args[4], args[5]
		if casterChar then
			SkillFXHelper.playMultipleSwords(casterChar, origin, targetPos, count, speed)
		end
	elseif action == "FlameSpear" then
		local casterChar, origin, targetModel, targetPos, speed = args[1], args[2], args[3], args[4], args[5]
		if casterChar then
			SkillFXHelper.playFlameSpear(casterChar, origin, targetModel, targetPos, speed)
		end
	end
end)

-- Sync equipped slots from server
skillDataUpdateRemote.OnClientEvent:Connect(function(action: string, data: any)
	if action == "SyncEquipped" and type(data) == "table" then
		for slot = 1, 4 do
			equippedSlots[slot] = data[slot] or ""
		end
		refreshHotbarUI()
		if bookModal and bookModal.Visible then
			renderModalSlotBar()
			renderSkillList()
		end
	end
end)

print("⚡ [SkillClient] Anime Combat Skill System HUD & Keybinds initialized.")

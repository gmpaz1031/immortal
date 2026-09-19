local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("CultivationRemote")
local ui = script.Parent

-- Enable default backpack for tool slots
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
end)

local romanNumerals = {
	[0] = "0",
	[1] = "I",
	[2] = "II",
	[3] = "III",
	[4] = "IV",
	[5] = "V",
	[6] = "VI",
	[7] = "VII",
	[8] = "VIII",
	[9] = "IX",
	[10] = "X",
}

local function toRoman(level)
	return romanNumerals[level] or tostring(level)
end

local function isTyping()
	return UserInputService:GetFocusedTextBox() ~= nil
end

-- Hide existing static Panel from default.project.json if present
local staticPanel = ui:FindFirstChild("Panel")
if staticPanel then
	staticPanel.Visible = false
end

--------------------------------------------------------------------------------
-- Top Navigation & HUD (Health Bar, Cultivation, Inventory, Shop)
--------------------------------------------------------------------------------
local topContainer = Instance.new("Frame")
topContainer.Name = "TopNav"
topContainer.BackgroundTransparency = 1
topContainer.Position = UDim2.new(0, 18, 0, 16)
topContainer.Size = UDim2.new(0, 480, 0, 110)
topContainer.Parent = ui

-- Health Bar Container
local healthContainer = Instance.new("Frame")
healthContainer.Name = "HealthContainer"
healthContainer.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
healthContainer.BorderSizePixel = 0
healthContainer.Position = UDim2.new(0, 0, 0, 0)
healthContainer.Size = UDim2.new(0, 260, 0, 24)
healthContainer.Parent = topContainer

local healthCorner = Instance.new("UICorner")
healthCorner.CornerRadius = UDim.new(0, 6)
healthCorner.Parent = healthContainer

local healthStroke = Instance.new("UIStroke")
healthStroke.Color = Color3.fromRGB(50, 60, 80)
healthStroke.Thickness = 1.2
healthStroke.Parent = healthContainer

local healthFill = Instance.new("Frame")
healthFill.Name = "Fill"
healthFill.BackgroundColor3 = Color3.fromRGB(220, 50, 60)
healthFill.BorderSizePixel = 0
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.Parent = healthContainer

local healthFillCorner = Instance.new("UICorner")
healthFillCorner.CornerRadius = UDim.new(0, 6)
healthFillCorner.Parent = healthFill

local healthText = Instance.new("TextLabel")
healthText.Name = "Label"
healthText.BackgroundTransparency = 1
healthText.Size = UDim2.new(1, 0, 1, 0)
healthText.Font = Enum.Font.GothamBold
healthText.Text = "HP: 100 / 100"
healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
healthText.TextSize = 12
healthText.ZIndex = 2
healthText.Parent = healthContainer

-- Action Buttons row
local buttonRow = Instance.new("Frame")
buttonRow.Name = "ButtonRow"
buttonRow.BackgroundTransparency = 1
buttonRow.Position = UDim2.new(0, 0, 0, 32)
buttonRow.Size = UDim2.new(0, 480, 0, 36)
buttonRow.Parent = topContainer

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.Padding = UDim.new(0, 8)
buttonLayout.Parent = buttonRow

-- 1. Cultivation Menu Button
local cultNavBtn = Instance.new("TextButton")
cultNavBtn.Name = "CultivationButton"
cultNavBtn.LayoutOrder = 1
cultNavBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
cultNavBtn.Size = UDim2.new(0, 120, 0, 32)
cultNavBtn.Font = Enum.Font.GothamBold
cultNavBtn.Text = "☯ Cultivation"
cultNavBtn.TextColor3 = Color3.fromRGB(255, 215, 80)
cultNavBtn.TextSize = 13
cultNavBtn.AutoButtonColor = true
cultNavBtn.Parent = buttonRow

local cultBtnCorner = Instance.new("UICorner")
cultBtnCorner.CornerRadius = UDim.new(0, 6)
cultBtnCorner.Parent = cultNavBtn

local cultBtnStroke = Instance.new("UIStroke")
cultBtnStroke.Color = Color3.fromRGB(210, 170, 50)
cultBtnStroke.Thickness = 1.2
cultBtnStroke.Parent = cultNavBtn

-- 2. Inventory Button
local invNavBtn = Instance.new("TextButton")
invNavBtn.Name = "InventoryButton"
invNavBtn.LayoutOrder = 2
invNavBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
invNavBtn.Size = UDim2.new(0, 110, 0, 32)
invNavBtn.Font = Enum.Font.GothamBold
invNavBtn.Text = "🎒 Inventory"
invNavBtn.TextColor3 = Color3.fromRGB(190, 215, 255)
invNavBtn.TextSize = 13
invNavBtn.AutoButtonColor = true
invNavBtn.Parent = buttonRow

local invBtnCorner = Instance.new("UICorner")
invBtnCorner.CornerRadius = UDim.new(0, 6)
invBtnCorner.Parent = invNavBtn

local invBtnStroke = Instance.new("UIStroke")
invBtnStroke.Color = Color3.fromRGB(70, 90, 130)
invBtnStroke.Thickness = 1.2
invBtnStroke.Parent = invNavBtn

-- 3. Shop Button
local shopNavBtn = Instance.new("TextButton")
shopNavBtn.Name = "ShopButton"
shopNavBtn.LayoutOrder = 3
shopNavBtn.BackgroundColor3 = Color3.fromRGB(36, 26, 48)
shopNavBtn.Size = UDim2.new(0, 95, 0, 32)
shopNavBtn.Font = Enum.Font.GothamBold
shopNavBtn.Text = "🏪 Shop"
shopNavBtn.TextColor3 = Color3.fromRGB(240, 180, 255)
shopNavBtn.TextSize = 13
shopNavBtn.AutoButtonColor = true
shopNavBtn.Parent = buttonRow

local shopBtnCorner = Instance.new("UICorner")
shopBtnCorner.CornerRadius = UDim.new(0, 6)
shopBtnCorner.Parent = shopNavBtn

local shopBtnStroke = Instance.new("UIStroke")
shopBtnStroke.Color = Color3.fromRGB(180, 100, 220)
shopBtnStroke.Thickness = 1.2
shopBtnStroke.Parent = shopNavBtn

-- 4. Admin Panel Button (TEMPORARY - will be removed later)
local adminNavBtn = Instance.new("TextButton")
adminNavBtn.Name = "AdminButton"
adminNavBtn.LayoutOrder = 4
adminNavBtn.BackgroundColor3 = Color3.fromRGB(55, 15, 15)
adminNavBtn.Size = UDim2.new(0, 90, 0, 32)
adminNavBtn.Font = Enum.Font.GothamBold
adminNavBtn.Text = "⚙ Admin"
adminNavBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
adminNavBtn.TextSize = 13
adminNavBtn.AutoButtonColor = true
adminNavBtn.Parent = buttonRow

local adminBtnCorner = Instance.new("UICorner")
adminBtnCorner.CornerRadius = UDim.new(0, 6)
adminBtnCorner.Parent = adminNavBtn

local adminBtnStroke = Instance.new("UIStroke")
adminBtnStroke.Color = Color3.fromRGB(255, 60, 60)
adminBtnStroke.Thickness = 1.2
adminBtnStroke.Parent = adminNavBtn

-- Active Buff Badge in HUD
local buffBadge = Instance.new("Frame")
buffBadge.Name = "ActiveBuffBadge"
buffBadge.BackgroundColor3 = Color3.fromRGB(45, 35, 15)
buffBadge.Position = UDim2.new(0, 0, 0, 72)
buffBadge.Size = UDim2.new(0, 240, 0, 22)
buffBadge.Visible = false
buffBadge.Parent = topContainer

local buffBadgeCorner = Instance.new("UICorner")
buffBadgeCorner.CornerRadius = UDim.new(0, 4)
buffBadgeCorner.Parent = buffBadge

local buffBadgeStroke = Instance.new("UIStroke")
buffBadgeStroke.Color = Color3.fromRGB(255, 200, 50)
buffBadgeStroke.Thickness = 1
buffBadgeStroke.Parent = buffBadge

local buffBadgeText = Instance.new("TextLabel")
buffBadgeText.Name = "Label"
buffBadgeText.BackgroundTransparency = 1
buffBadgeText.Size = UDim2.new(1, 0, 1, 0)
buffBadgeText.Font = Enum.Font.GothamBold
buffBadgeText.Text = "💊 Qi Pill (2x): 5:00"
buffBadgeText.TextColor3 = Color3.fromRGB(255, 230, 120)
buffBadgeText.TextSize = 11
buffBadgeText.Parent = buffBadge

--------------------------------------------------------------------------------
-- Floating Notifications
--------------------------------------------------------------------------------
local function showNotification(msg)
	local notif = Instance.new("TextLabel")
	notif.Name = "Notif"
	notif.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	notif.AnchorPoint = Vector2.new(0.5, 0)
	notif.Position = UDim2.new(0.5, 0, 0.12, 0)
	notif.Size = UDim2.new(0, 360, 0, 34)
	notif.Font = Enum.Font.GothamBold
	notif.Text = msg
	notif.TextColor3 = Color3.fromRGB(255, 235, 120)
	notif.TextSize = 14
	notif.ZIndex = 50
	notif.Parent = ui

	local nc = Instance.new("UICorner")
	nc.CornerRadius = UDim.new(0, 6)
	nc.Parent = notif

	local ns = Instance.new("UIStroke")
	ns.Color = Color3.fromRGB(255, 200, 60)
	ns.Thickness = 1.2
	ns.Parent = notif

	task.spawn(function()
		TweenService:Create(notif, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0.14, 0) }):Play()
		task.wait(2.2)
		local fade = TweenService:Create(notif, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		notif:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Modal Window 1: Cultivation Stats Modal Panel
--------------------------------------------------------------------------------
local modalPanel = Instance.new("Frame")
modalPanel.Name = "StatsModalPanel"
modalPanel.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
modalPanel.BorderSizePixel = 0
modalPanel.AnchorPoint = Vector2.new(0.5, 0.5)
modalPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
modalPanel.Size = UDim2.new(0, 420, 0, 450)
modalPanel.Visible = false
modalPanel.ZIndex = 5
modalPanel.Parent = ui

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 10)
modalCorner.Parent = modalPanel

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(210, 175, 60)
modalStroke.Thickness = 1.8
modalStroke.Parent = modalPanel

local modalTitle = Instance.new("TextLabel")
modalTitle.Name = "Title"
modalTitle.BackgroundTransparency = 1
modalTitle.Position = UDim2.new(0, 18, 0, 12)
modalTitle.Size = UDim2.new(1, -36, 0, 28)
modalTitle.Font = Enum.Font.GothamBlack
modalTitle.Text = "CULTIVATION STATS"
modalTitle.TextColor3 = Color3.fromRGB(255, 215, 80)
modalTitle.TextSize = 20
modalTitle.ZIndex = 6
modalTitle.Parent = modalPanel

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
closeBtn.Position = UDim2.new(1, -36, 0, 10)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
closeBtn.TextSize = 14
closeBtn.ZIndex = 7
closeBtn.Parent = modalPanel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsList"
statsFrame.BackgroundTransparency = 1
statsFrame.Position = UDim2.new(0, 22, 0, 48)
statsFrame.Size = UDim2.new(1, -44, 0, 225)
statsFrame.ZIndex = 6
statsFrame.Parent = modalPanel

local statsLayout = Instance.new("UIListLayout")
statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
statsLayout.Padding = UDim.new(0, 6)
statsLayout.Parent = statsFrame

local function createStatRow(order, labelName, defaultVal)
	local row = Instance.new("Frame")
	row.Name = labelName
	row.LayoutOrder = order
	row.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 26)
	row.ZIndex = 6
	row.Parent = statsFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 4)
	rowCorner.Parent = row

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "Label"
	titleLbl.BackgroundTransparency = 1
	titleLbl.Position = UDim2.new(0, 10, 0, 0)
	titleLbl.Size = UDim2.new(0.45, -10, 1, 0)
	titleLbl.Font = Enum.Font.GothamMedium
	titleLbl.Text = labelName .. ":"
	titleLbl.TextColor3 = Color3.fromRGB(180, 195, 220)
	titleLbl.TextSize = 12
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 7
	titleLbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.Name = "Value"
	valLbl.BackgroundTransparency = 1
	valLbl.Position = UDim2.new(0.45, 0, 0, 0)
	valLbl.Size = UDim2.new(0.55, -10, 1, 0)
	valLbl.Font = Enum.Font.GothamBold
	valLbl.Text = defaultVal
	valLbl.TextColor3 = Color3.fromRGB(255, 235, 150)
	valLbl.TextSize = 12
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.ZIndex = 7
	valLbl.Parent = row

	return valLbl
end

local stageValLabel = createStatRow(1, "Cultivation Stage", "Qi Condensation Level 0")
local damageValLabel = createStatRow(2, "Damage", "10")
local defenseValLabel = createStatRow(3, "Defense", "0")
local healthValLabel = createStatRow(4, "Total Health", "100 / 100")
local goldValLabel = createStatRow(5, "Total Gold", "0")
local qiMultValLabel = createStatRow(6, "Qi Multiplier", "1.00x")
local luckValLabel = createStatRow(7, "Luck", "10")

local modalQiBar = Instance.new("Frame")
modalQiBar.Name = "ModalQiBar"
modalQiBar.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
modalQiBar.BorderSizePixel = 0
modalQiBar.Position = UDim2.new(0, 22, 0, 282)
modalQiBar.Size = UDim2.new(1, -44, 0, 26)
modalQiBar.ZIndex = 6
modalQiBar.Parent = modalPanel

local modalQiCorner = Instance.new("UICorner")
modalQiCorner.CornerRadius = UDim.new(0, 6)
modalQiCorner.Parent = modalQiBar

local modalQiFill = Instance.new("Frame")
modalQiFill.Name = "Fill"
modalQiFill.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
modalQiFill.BorderSizePixel = 0
modalQiFill.Size = UDim2.new(0, 0, 1, 0)
modalQiFill.ZIndex = 6
modalQiFill.Parent = modalQiBar

local modalQiFillCorner = Instance.new("UICorner")
modalQiFillCorner.CornerRadius = UDim.new(0, 6)
modalQiFillCorner.Parent = modalQiFill

local modalQiText = Instance.new("TextLabel")
modalQiText.Name = "Label"
modalQiText.BackgroundTransparency = 1
modalQiText.Size = UDim2.new(1, 0, 1, 0)
modalQiText.Font = Enum.Font.GothamBold
modalQiText.Text = "Qi: 0 / 100"
modalQiText.TextColor3 = Color3.fromRGB(255, 255, 255)
modalQiText.TextSize = 13
modalQiText.ZIndex = 7
modalQiText.Parent = modalQiBar

local cultivateActionBtn = Instance.new("TextButton")
cultivateActionBtn.Name = "CultivateActionBtn"
cultivateActionBtn.BackgroundColor3 = Color3.fromRGB(30, 48, 75)
cultivateActionBtn.BorderSizePixel = 0
cultivateActionBtn.Position = UDim2.new(0, 22, 0, 320)
cultivateActionBtn.Size = UDim2.new(1, -44, 0, 36)
cultivateActionBtn.Font = Enum.Font.GothamBold
cultivateActionBtn.Text = "Press C to Cultivate"
cultivateActionBtn.TextColor3 = Color3.fromRGB(220, 235, 255)
cultivateActionBtn.TextSize = 14
cultivateActionBtn.ZIndex = 6
cultivateActionBtn.Parent = modalPanel

local cultActCorner = Instance.new("UICorner")
cultActCorner.CornerRadius = UDim.new(0, 6)
cultActCorner.Parent = cultivateActionBtn

local breakthroughActionBtn = Instance.new("TextButton")
breakthroughActionBtn.Name = "BreakthroughActionBtn"
breakthroughActionBtn.BackgroundColor3 = Color3.fromRGB(180, 110, 20)
breakthroughActionBtn.BorderSizePixel = 0
breakthroughActionBtn.Position = UDim2.new(0, 22, 0, 366)
breakthroughActionBtn.Size = UDim2.new(1, -44, 0, 42)
breakthroughActionBtn.Font = Enum.Font.GothamBlack
breakthroughActionBtn.Text = "⚡ BREAKTHROUGH ⚡"
breakthroughActionBtn.TextColor3 = Color3.fromRGB(255, 245, 200)
breakthroughActionBtn.TextSize = 16
breakthroughActionBtn.Visible = false
breakthroughActionBtn.ZIndex = 6
breakthroughActionBtn.Parent = modalPanel

local brkCorner = Instance.new("UICorner")
brkCorner.CornerRadius = UDim.new(0, 6)
brkCorner.Parent = breakthroughActionBtn

local brkStroke = Instance.new("UIStroke")
brkStroke.Color = Color3.fromRGB(255, 215, 80)
brkStroke.Thickness = 1.5
brkStroke.Parent = breakthroughActionBtn

--------------------------------------------------------------------------------
-- Modal Window 2: Stored Items Inventory UI
--------------------------------------------------------------------------------
local inventoryModal = Instance.new("Frame")
inventoryModal.Name = "InventoryModalPanel"
inventoryModal.BackgroundColor3 = Color3.fromRGB(14, 17, 28)
inventoryModal.BorderSizePixel = 0
inventoryModal.AnchorPoint = Vector2.new(0.5, 0.5)
inventoryModal.Position = UDim2.new(0.5, 0, 0.5, 0)
inventoryModal.Size = UDim2.new(0, 440, 0, 420)
inventoryModal.Visible = false
inventoryModal.ZIndex = 10
inventoryModal.Parent = ui

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 10)
invCorner.Parent = inventoryModal

local invStroke = Instance.new("UIStroke")
invStroke.Color = Color3.fromRGB(90, 125, 190)
invStroke.Thickness = 1.8
invStroke.Parent = inventoryModal

local invTitle = Instance.new("TextLabel")
invTitle.Name = "Title"
invTitle.BackgroundTransparency = 1
invTitle.Position = UDim2.new(0, 18, 0, 14)
invTitle.Size = UDim2.new(1, -36, 0, 28)
invTitle.Font = Enum.Font.GothamBlack
invTitle.Text = "🎒 STORED ITEMS INVENTORY"
invTitle.TextColor3 = Color3.fromRGB(190, 220, 255)
invTitle.TextSize = 18
invTitle.ZIndex = 11
invTitle.Parent = inventoryModal

local invCloseBtn = Instance.new("TextButton")
invCloseBtn.Name = "CloseBtn"
invCloseBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
invCloseBtn.Position = UDim2.new(1, -36, 0, 12)
invCloseBtn.Size = UDim2.new(0, 26, 0, 26)
invCloseBtn.Font = Enum.Font.GothamBold
invCloseBtn.Text = "✕"
invCloseBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
invCloseBtn.TextSize = 14
invCloseBtn.ZIndex = 12
invCloseBtn.Parent = inventoryModal

local invCloseCorner = Instance.new("UICorner")
invCloseCorner.CornerRadius = UDim.new(0, 6)
invCloseCorner.Parent = invCloseBtn

local invScroll = Instance.new("ScrollingFrame")
invScroll.Name = "ItemList"
invScroll.BackgroundTransparency = 1
invScroll.BorderSizePixel = 0
invScroll.Position = UDim2.new(0, 18, 0, 52)
invScroll.Size = UDim2.new(1, -36, 1, -66)
invScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
invScroll.ScrollBarThickness = 5
invScroll.ZIndex = 11
invScroll.Parent = inventoryModal

local invScrollLayout = Instance.new("UIListLayout")
invScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
invScrollLayout.Padding = UDim.new(0, 8)
invScrollLayout.Parent = invScroll

local invEmptyText = Instance.new("TextLabel")
invEmptyText.Name = "EmptyText"
invEmptyText.BackgroundTransparency = 1
invEmptyText.Position = UDim2.new(0, 0, 0.4, 0)
invEmptyText.Size = UDim2.new(1, 0, 0, 40)
invEmptyText.Font = Enum.Font.GothamMedium
invEmptyText.Text = "Your inventory is empty.\nVisit the Pill Shop to acquire spiritual pills!"
invEmptyText.TextColor3 = Color3.fromRGB(130, 150, 180)
invEmptyText.TextSize = 14
invEmptyText.Visible = false
invEmptyText.ZIndex = 11
invEmptyText.Parent = invScroll

--------------------------------------------------------------------------------
-- Modal Window 3: Pill Shop UI
--------------------------------------------------------------------------------
local shopModal = Instance.new("Frame")
shopModal.Name = "ShopModalPanel"
shopModal.BackgroundColor3 = Color3.fromRGB(20, 15, 28)
shopModal.BorderSizePixel = 0
shopModal.AnchorPoint = Vector2.new(0.5, 0.5)
shopModal.Position = UDim2.new(0.5, 0, 0.5, 0)
shopModal.Size = UDim2.new(0, 460, 0, 440)
shopModal.Visible = false
shopModal.ZIndex = 15
shopModal.Parent = ui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shopModal

local shopStroke = Instance.new("UIStroke")
shopStroke.Color = Color3.fromRGB(190, 110, 240)
shopStroke.Thickness = 1.8
shopStroke.Parent = shopModal

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.BackgroundTransparency = 1
shopTitle.Position = UDim2.new(0, 18, 0, 12)
shopTitle.Size = UDim2.new(1, -36, 0, 26)
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.Text = "🏪 PILL PAVILION SHOP"
shopTitle.TextColor3 = Color3.fromRGB(240, 190, 255)
shopTitle.TextSize = 18
shopTitle.ZIndex = 16
shopTitle.Parent = shopModal

local shopGoldLabel = Instance.new("TextLabel")
shopGoldLabel.Name = "GoldBalance"
shopGoldLabel.BackgroundTransparency = 1
shopGoldLabel.Position = UDim2.new(0, 18, 0, 38)
shopGoldLabel.Size = UDim2.new(1, -36, 0, 18)
shopGoldLabel.Font = Enum.Font.GothamBold
shopGoldLabel.Text = "Your Gold: 🪙 0"
shopGoldLabel.TextColor3 = Color3.fromRGB(255, 215, 80)
shopGoldLabel.TextSize = 13
shopGoldLabel.TextXAlignment = Enum.TextXAlignment.Left
shopGoldLabel.ZIndex = 16
shopGoldLabel.Parent = shopModal

local shopCloseBtn = Instance.new("TextButton")
shopCloseBtn.Name = "CloseBtn"
shopCloseBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
shopCloseBtn.Position = UDim2.new(1, -36, 0, 12)
shopCloseBtn.Size = UDim2.new(0, 26, 0, 26)
shopCloseBtn.Font = Enum.Font.GothamBold
shopCloseBtn.Text = "✕"
shopCloseBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
shopCloseBtn.TextSize = 14
shopCloseBtn.ZIndex = 17
shopCloseBtn.Parent = shopModal

local shopCloseCorner = Instance.new("UICorner")
shopCloseCorner.CornerRadius = UDim.new(0, 6)
shopCloseCorner.Parent = shopCloseBtn

local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Name = "ShopList"
shopScroll.BackgroundTransparency = 1
shopScroll.BorderSizePixel = 0
shopScroll.Position = UDim2.new(0, 18, 0, 64)
shopScroll.Size = UDim2.new(1, -36, 1, -78)
shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
shopScroll.ScrollBarThickness = 5
shopScroll.ZIndex = 16
shopScroll.Parent = shopModal

local shopScrollLayout = Instance.new("UIListLayout")
shopScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopScrollLayout.Padding = UDim.new(0, 8)
shopScrollLayout.Parent = shopScroll

--------------------------------------------------------------------------------
-- Populate Shop Items
--------------------------------------------------------------------------------
local SHOP_CATALOG = {
	{
		Name = "Qi Condensation Pill",
		Price = 30,
		Icon = "💊",
		Rarity = "Rare",
		RarityColor = Color3.fromRGB(255, 215, 70),
		Desc = "Amplifies Qi gathering speed by 2x for 5 minutes."
	},
	{
		Name = "Lesser Qi Pill",
		Price = 15,
		Icon = "🔹",
		Rarity = "Common",
		RarityColor = Color3.fromRGB(100, 200, 255),
		Desc = "Instant spiritual surge. Restores +50 Qi immediately."
	},
	{
		Name = "Spirit Spring Elixir",
		Price = 20,
		Icon = "🧪",
		Rarity = "Uncommon",
		RarityColor = Color3.fromRGB(120, 230, 140),
		Desc = "Sacred mountain dew. Fully restores 100% of your Total Health."
	}
}

for idx, item in ipairs(SHOP_CATALOG) do
	local card = Instance.new("Frame")
	card.Name = item.Name
	card.LayoutOrder = idx
	card.BackgroundColor3 = Color3.fromRGB(30, 22, 42)
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, -8, 0, 72)
	card.ZIndex = 16
	card.Parent = shopScroll

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(75, 55, 100)
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "Name"
	nameLbl.BackgroundTransparency = 1
	nameLbl.Position = UDim2.new(0, 12, 0, 8)
	nameLbl.Size = UDim2.new(0.65, -12, 0, 20)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.Text = item.Icon .. " " .. item.Name
	nameLbl.TextColor3 = item.RarityColor
	nameLbl.TextSize = 14
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.ZIndex = 17
	nameLbl.Parent = card

	local descLbl = Instance.new("TextLabel")
	descLbl.Name = "Desc"
	descLbl.BackgroundTransparency = 1
	descLbl.Position = UDim2.new(0, 12, 0, 30)
	descLbl.Size = UDim2.new(0.65, -12, 0, 34)
	descLbl.Font = Enum.Font.GothamMedium
	descLbl.Text = item.Desc
	descLbl.TextColor3 = Color3.fromRGB(190, 180, 210)
	descLbl.TextSize = 11
	descLbl.TextWrapped = true
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.ZIndex = 17
	descLbl.Parent = card

	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyBtn"
	buyBtn.BackgroundColor3 = Color3.fromRGB(160, 90, 210)
	buyBtn.Position = UDim2.new(0.7, 0, 0.2, 0)
	buyBtn.Size = UDim2.new(0.27, 0, 0.6, 0)
	buyBtn.Font = Enum.Font.GothamBlack
	buyBtn.Text = "🪙 " .. tostring(item.Price) .. " G"
	buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.TextSize = 13
	buyBtn.AutoButtonColor = true
	buyBtn.ZIndex = 17
	buyBtn.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 6)
	buyCorner.Parent = buyBtn

	buyBtn.Activated:Connect(function()
		remote:FireServer("BuyItem", item.Name)
	end)
end

shopScroll.CanvasSize = UDim2.new(0, 0, 0, #SHOP_CATALOG * 82)

--------------------------------------------------------------------------------
-- Modal Window 4: Admin Panel (TEMPORARY)
--------------------------------------------------------------------------------
local adminModal = Instance.new("Frame")
adminModal.Name = "AdminModalPanel"
adminModal.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
adminModal.BorderSizePixel = 0
adminModal.AnchorPoint = Vector2.new(0.5, 0.5)
adminModal.Position = UDim2.new(0.5, 0, 0.5, 0)
adminModal.Size = UDim2.new(0, 440, 0, 500)
adminModal.Visible = false
adminModal.ZIndex = 20
adminModal.Parent = ui

local adminCorner = Instance.new("UICorner")
adminCorner.CornerRadius = UDim.new(0, 10)
adminCorner.Parent = adminModal

local adminStroke = Instance.new("UIStroke")
adminStroke.Color = Color3.fromRGB(255, 60, 60)
adminStroke.Thickness = 2
adminStroke.Parent = adminModal

local adminTitle = Instance.new("TextLabel")
adminTitle.Name = "Title"
adminTitle.BackgroundTransparency = 1
adminTitle.Position = UDim2.new(0, 18, 0, 12)
adminTitle.Size = UDim2.new(1, -36, 0, 28)
adminTitle.Font = Enum.Font.GothamBlack
adminTitle.Text = "⚙ ADMIN PANEL (DEV)"
adminTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
adminTitle.TextSize = 20
adminTitle.ZIndex = 21
adminTitle.Parent = adminModal

local adminCloseBtn = Instance.new("TextButton")
adminCloseBtn.Name = "CloseBtn"
adminCloseBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
adminCloseBtn.Position = UDim2.new(1, -36, 0, 10)
adminCloseBtn.Size = UDim2.new(0, 26, 0, 26)
adminCloseBtn.Font = Enum.Font.GothamBold
adminCloseBtn.Text = "✕"
adminCloseBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
adminCloseBtn.TextSize = 14
adminCloseBtn.ZIndex = 22
adminCloseBtn.Parent = adminModal

local adminCloseCorner = Instance.new("UICorner")
adminCloseCorner.CornerRadius = UDim.new(0, 6)
adminCloseCorner.Parent = adminCloseBtn

local adminScroll = Instance.new("ScrollingFrame")
adminScroll.Name = "AdminList"
adminScroll.BackgroundTransparency = 1
adminScroll.BorderSizePixel = 0
adminScroll.Position = UDim2.new(0, 18, 0, 50)
adminScroll.Size = UDim2.new(1, -36, 1, -64)
adminScroll.CanvasSize = UDim2.new(0, 0, 0, 600)
adminScroll.ScrollBarThickness = 5
adminScroll.ZIndex = 21
adminScroll.Parent = adminModal

local adminLayout = Instance.new("UIListLayout")
adminLayout.SortOrder = Enum.SortOrder.LayoutOrder
adminLayout.Padding = UDim.new(0, 8)
adminLayout.Parent = adminScroll

local function createAdminActionBtn(order, label, color, callback)
	local btn = Instance.new("TextButton")
	btn.Name = label
	btn.LayoutOrder = order
	btn.BackgroundColor3 = color
	btn.Size = UDim2.new(1, -8, 0, 42)
	btn.Font = Enum.Font.GothamBold
	btn.Text = label
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 14
	btn.AutoButtonColor = true
	btn.ZIndex = 22
	btn.Parent = adminScroll

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 6)
	bc.Parent = btn

	btn.Activated:Connect(callback)
	return btn
end

createAdminActionBtn(1, "🪙 Add 1,000 Gold", Color3.fromRGB(160, 120, 30), function()
	remote:FireServer("AdminAction", "AddGold", 1000)
end)

createAdminActionBtn(2, "🪙 Add 10,000 Gold", Color3.fromRGB(180, 135, 20), function()
	remote:FireServer("AdminAction", "AddGold", 10000)
end)

createAdminActionBtn(3, "🔵 Add 500 Qi", Color3.fromRGB(40, 100, 180), function()
	remote:FireServer("AdminAction", "AddQi", 500)
end)

createAdminActionBtn(4, "🔵 Add 5,000 Qi", Color3.fromRGB(30, 80, 200), function()
	remote:FireServer("AdminAction", "AddQi", 5000)
end)

createAdminActionBtn(5, "🔵 Add 50,000 Qi", Color3.fromRGB(20, 60, 220), function()
	remote:FireServer("AdminAction", "AddQi", 50000)
end)

createAdminActionBtn(6, "⬆ Set Realm Level 1", Color3.fromRGB(60, 120, 60), function()
	remote:FireServer("AdminAction", "SetRealmLevel", 1)
end)

createAdminActionBtn(7, "⬆ Set Realm Level 5", Color3.fromRGB(50, 140, 50), function()
	remote:FireServer("AdminAction", "SetRealmLevel", 5)
end)

createAdminActionBtn(8, "⬆ Set Realm Level 10", Color3.fromRGB(40, 160, 40), function()
	remote:FireServer("AdminAction", "SetRealmLevel", 10)
end)

createAdminActionBtn(9, "💊 Add 10x Qi Condensation Pill", Color3.fromRGB(150, 80, 30), function()
	remote:FireServer("AdminAction", "AddItem", "Qi Condensation Pill", 10)
end)

createAdminActionBtn(10, "🔹 Add 10x Lesser Qi Pill", Color3.fromRGB(50, 90, 160), function()
	remote:FireServer("AdminAction", "AddItem", "Lesser Qi Pill", 10)
end)

createAdminActionBtn(11, "🧪 Add 10x Spirit Spring Elixir", Color3.fromRGB(40, 130, 70), function()
	remote:FireServer("AdminAction", "AddItem", "Spirit Spring Elixir", 10)
end)

createAdminActionBtn(12, "❤️ Full Heal Character", Color3.fromRGB(180, 40, 40), function()
	remote:FireServer("AdminAction", "HealFull")
end)

createAdminActionBtn(13, "⚡ Apply 5x Qi Mega-Buff (1 hour)", Color3.fromRGB(180, 160, 20), function()
	remote:FireServer("AdminAction", "MaxBuff")
end)

createAdminActionBtn(14, "💾 Force Save Now", Color3.fromRGB(80, 80, 120), function()
	remote:FireServer("AdminAction", "SaveNow")
end)

createAdminActionBtn(15, "🪖 Add Helmet (+10 HP/Def)", Color3.fromRGB(80, 110, 150), function()
	remote:FireServer("AdminAction", "AddItem", "Helmet", 1)
end)

createAdminActionBtn(16, "🛡️ Add Armor (+10 HP/Def)", Color3.fromRGB(100, 80, 140), function()
	remote:FireServer("AdminAction", "AddItem", "Armor", 1)
end)

--------------------------------------------------------------------------------
-- Inventory Render Helper
--------------------------------------------------------------------------------
local function renderInventory()
	for _, child in ipairs(invScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local invFolder = player:FindFirstChild("Inventory")
	local items = {}
	if invFolder then
		for _, v in ipairs(invFolder:GetChildren()) do
			if v:IsA("IntValue") and v.Value > 0 then
				table.insert(items, { Name = v.Name, Count = v.Value })
			end
		end
	end

	invEmptyText.Visible = (#items == 0)

	for idx, itm in ipairs(items) do
		local card = Instance.new("Frame")
		card.Name = itm.Name
		card.LayoutOrder = idx
		card.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
		card.BorderSizePixel = 0
		card.Size = UDim2.new(1, -8, 0, 68)
		card.ZIndex = 12
		card.Parent = invScroll

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 8)
		cCorner.Parent = card

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Color3.fromRGB(60, 80, 120)
		cStroke.Thickness = 1
		cStroke.Parent = card

		local isHelmet = (itm.Name == "Helmet")
		local isArmor = (itm.Name == "Armor")
		local isEquippable = isHelmet or isArmor
		local isEquipped = (isHelmet and player:GetAttribute("EquippedHelmet") == true) or (isArmor and player:GetAttribute("EquippedArmor") == true)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "Name"
		nameLbl.BackgroundTransparency = 1
		nameLbl.Position = UDim2.new(0, 12, 0, 8)
		nameLbl.Size = UDim2.new(0.65, -12, 0, 20)
		nameLbl.Font = Enum.Font.GothamBold

		local icon = "💊"
		if isHelmet then
			icon = "🪖"
		elseif isArmor then
			icon = "🛡️"
		elseif itm.Name == "Lesser Qi Pill" then
			icon = "🔹"
		elseif itm.Name == "Spirit Spring Elixir" then
			icon = "🧪"
		end

		if isEquipped then
			nameLbl.Text = string.format("%s %s  [EQUIPPED]", icon, itm.Name)
			nameLbl.TextColor3 = Color3.fromRGB(100, 255, 150)
		else
			nameLbl.Text = string.format("%s %s  [x%d]", icon, itm.Name, itm.Count)
			nameLbl.TextColor3 = Color3.fromRGB(255, 230, 120)
		end
		nameLbl.TextSize = 14
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.ZIndex = 13
		nameLbl.Parent = card

		local descText = "Item."
		if itm.Name == "Qi Condensation Pill" then
			descText = "Amplifies Qi gathering speed by 2x for 5 minutes."
		elseif itm.Name == "Lesser Qi Pill" then
			descText = "Instantly restores +50 Qi."
		elseif itm.Name == "Spirit Spring Elixir" then
			descText = "Fully restores 100% of Total Health."
		elseif isHelmet then
			descText = "Bandit drop gear. Adds +10 Total Health and +10 Defense."
		elseif isArmor then
			descText = "Bandit drop gear. Adds +10 Total Health and +10 Defense."
		end

		local descLbl = Instance.new("TextLabel")
		descLbl.Name = "Desc"
		descLbl.BackgroundTransparency = 1
		descLbl.Position = UDim2.new(0, 12, 0, 30)
		descLbl.Size = UDim2.new(0.65, -12, 0, 30)
		descLbl.Font = Enum.Font.GothamMedium
		descLbl.Text = descText
		descLbl.TextColor3 = Color3.fromRGB(180, 200, 230)
		descLbl.TextSize = 11
		descLbl.TextWrapped = true
		descLbl.TextXAlignment = Enum.TextXAlignment.Left
		descLbl.ZIndex = 13
		descLbl.Parent = card

		local actionBtn = Instance.new("TextButton")
		actionBtn.Name = "ActionBtn"
		actionBtn.Position = UDim2.new(0.72, 0, 0.2, 0)
		actionBtn.Size = UDim2.new(0.24, 0, 0.6, 0)
		actionBtn.Font = Enum.Font.GothamBlack
		actionBtn.TextSize = 13
		actionBtn.AutoButtonColor = true
		actionBtn.ZIndex = 13
		actionBtn.Parent = card

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = actionBtn

		if isEquippable then
			if isEquipped then
				actionBtn.Text = "UNEQUIP"
				actionBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
				actionBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
				actionBtn.Activated:Connect(function()
					remote:FireServer("UnequipItem", itm.Name)
				end)
			else
				actionBtn.Text = "EQUIP"
				actionBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
				actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				actionBtn.Activated:Connect(function()
					remote:FireServer("EquipItem", itm.Name)
				end)
			end
		else
			actionBtn.Text = "USE"
			actionBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 220)
			actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			actionBtn.Activated:Connect(function()
				remote:FireServer("UseItem", itm.Name)
			end)
		end
	end

	invScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(260, #items * 78))
end

-- Modal navigation buttons
cultNavBtn.Activated:Connect(function()
	modalPanel.Visible = not modalPanel.Visible
	if modalPanel.Visible then
		inventoryModal.Visible = false
		shopModal.Visible = false
		adminModal.Visible = false
	end
end)

closeBtn.Activated:Connect(function()
	modalPanel.Visible = false
end)

invNavBtn.Activated:Connect(function()
	inventoryModal.Visible = not inventoryModal.Visible
	if inventoryModal.Visible then
		modalPanel.Visible = false
		shopModal.Visible = false
		adminModal.Visible = false
		renderInventory()
	end
end)

invCloseBtn.Activated:Connect(function()
	inventoryModal.Visible = false
end)

shopNavBtn.Activated:Connect(function()
	shopModal.Visible = not shopModal.Visible
	if shopModal.Visible then
		modalPanel.Visible = false
		inventoryModal.Visible = false
		adminModal.Visible = false
	end
end)

shopCloseBtn.Activated:Connect(function()
	shopModal.Visible = false
end)

adminNavBtn.Activated:Connect(function()
	adminModal.Visible = not adminModal.Visible
	if adminModal.Visible then
		modalPanel.Visible = false
		inventoryModal.Visible = false
		shopModal.Visible = false
	end
end)

adminCloseBtn.Activated:Connect(function()
	adminModal.Visible = false
end)

-- Remote notification and shop opener from in-world seller
remote.OnClientEvent:Connect(function(event, ...)
	local args = { ... }
	if event == "OpenShop" then
		shopModal.Visible = true
		modalPanel.Visible = false
		inventoryModal.Visible = false
		adminModal.Visible = false
	elseif event == "Notification" then
		local msg = args[1] or ""
		showNotification(msg)
		renderInventory()
	end
end)

--------------------------------------------------------------------------------
-- Joint helpers & Animation
--------------------------------------------------------------------------------
local originalC0s = {}
local activeTracks = {}

local function findJoint(character, ...)
	for _, name in { ... } do
		local joint = character:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			return joint
		end
	end
end

local function buildPose(name, cframe, children)
	local pose = Instance.new("Pose")
	pose.Name = name
	pose.CFrame = cframe or CFrame.identity
	pose.Weight = 1
	if children then
		for _, child in children do
			child.Parent = pose
		end
	end
	return pose
end

local function createLotusKeyframeSequence(isR15, sitOffset)
	local kfs = Instance.new("KeyframeSequence")
	kfs.Loop = true
	kfs.Priority = Enum.AnimationPriority.Action4

	if isR15 then
		local kf0 = Instance.new("Keyframe")
		kf0.Time = 0

		local leftLeg0 = buildPose("LeftUpperLeg", CFrame.Angles(math.rad(72), math.rad(-40), math.rad(-35)), {
			buildPose("LeftLowerLeg", CFrame.Angles(math.rad(118), 0, 0), {
				buildPose("LeftFoot", CFrame.Angles(math.rad(-24), math.rad(-10), math.rad(-15)))
			})
		})
		local rightLeg0 = buildPose("RightUpperLeg", CFrame.Angles(math.rad(72), math.rad(40), math.rad(35)), {
			buildPose("RightLowerLeg", CFrame.Angles(math.rad(118), 0, 0), {
				buildPose("RightFoot", CFrame.Angles(math.rad(-24), math.rad(10), math.rad(15)))
			})
		})
		local leftArm0 = buildPose("LeftUpperArm", CFrame.Angles(math.rad(28), math.rad(16), math.rad(-24)), {
			buildPose("LeftLowerArm", CFrame.Angles(math.rad(-48), math.rad(-18), math.rad(-10)), {
				buildPose("LeftHand", CFrame.Angles(0, 0, math.rad(-20)))
			})
		})
		local rightArm0 = buildPose("RightUpperArm", CFrame.Angles(math.rad(28), math.rad(-16), math.rad(24)), {
			buildPose("RightLowerArm", CFrame.Angles(math.rad(-48), math.rad(18), math.rad(10)), {
				buildPose("RightHand", CFrame.Angles(0, 0, math.rad(20)))
			})
		})
		local upperTorso0 = buildPose("UpperTorso", CFrame.Angles(math.rad(6), 0, 0), {
			buildPose("Head", CFrame.Angles(math.rad(-4), 0, 0)),
			leftArm0, rightArm0
		})
		local lowerTorso0 = buildPose("LowerTorso", CFrame.new(0, sitOffset, 0), {
			upperTorso0, leftLeg0, rightLeg0
		})
		buildPose("HumanoidRootPart", CFrame.identity, { lowerTorso0 }).Parent = kf0
		kf0.Parent = kfs

		local kf1 = Instance.new("Keyframe")
		kf1.Time = 1.5
		local leftLeg1 = buildPose("LeftUpperLeg", CFrame.Angles(math.rad(72), math.rad(-40), math.rad(-35)), {
			buildPose("LeftLowerLeg", CFrame.Angles(math.rad(118), 0, 0), {
				buildPose("LeftFoot", CFrame.Angles(math.rad(-24), math.rad(-10), math.rad(-15)))
			})
		})
		local rightLeg1 = buildPose("RightUpperLeg", CFrame.Angles(math.rad(72), math.rad(40), math.rad(35)), {
			buildPose("RightLowerLeg", CFrame.Angles(math.rad(118), 0, 0), {
				buildPose("RightFoot", CFrame.Angles(math.rad(-24), math.rad(10), math.rad(15)))
			})
		})
		local leftArm1 = buildPose("LeftUpperArm", CFrame.Angles(math.rad(30), math.rad(16), math.rad(-25)), {
			buildPose("LeftLowerArm", CFrame.Angles(math.rad(-48), math.rad(-18), math.rad(-10)), {
				buildPose("LeftHand", CFrame.Angles(0, 0, math.rad(-20)))
			})
		})
		local rightArm1 = buildPose("RightUpperArm", CFrame.Angles(math.rad(30), math.rad(-16), math.rad(25)), {
			buildPose("RightLowerArm", CFrame.Angles(math.rad(-48), math.rad(18), math.rad(10)), {
				buildPose("RightHand", CFrame.Angles(0, 0, math.rad(20)))
			})
		})
		local upperTorso1 = buildPose("UpperTorso", CFrame.new(0, 0.04, 0) * CFrame.Angles(math.rad(7.5), 0, 0), {
			buildPose("Head", CFrame.Angles(math.rad(-3), 0, 0)),
			leftArm1, rightArm1
		})
		local lowerTorso1 = buildPose("LowerTorso", CFrame.new(0, sitOffset + 0.02, 0), {
			upperTorso1, leftLeg1, rightLeg1
		})
		buildPose("HumanoidRootPart", CFrame.identity, { lowerTorso1 }).Parent = kf1
		kf1.Parent = kfs

		local kf2 = Instance.new("Keyframe")
		kf2.Time = 3.0
		local leftLeg2 = buildPose("LeftUpperLeg", CFrame.Angles(math.rad(72), math.rad(-40), math.rad(-35)), {
			buildPose("LeftLowerLeg", CFrame.Angles(math.rad(118), 0, 0), {
				buildPose("LeftFoot", CFrame.Angles(math.rad(-24), math.rad(-10), math.rad(-15)))
			})
		})
		local rightLeg2 = buildPose("RightUpperLeg", CFrame.Angles(math.rad(72), math.rad(40), math.rad(35)), {
			buildPose("RightLowerLeg", CFrame.Angles(math.rad(118), 0, 0), {
				buildPose("RightFoot", CFrame.Angles(math.rad(-24), math.rad(10), math.rad(15)))
			})
		})
		local leftArm2 = buildPose("LeftUpperArm", CFrame.Angles(math.rad(28), math.rad(16), math.rad(-24)), {
			buildPose("LeftLowerArm", CFrame.Angles(math.rad(-48), math.rad(-18), math.rad(-10)), {
				buildPose("LeftHand", CFrame.Angles(0, 0, math.rad(-20)))
			})
		})
		local rightArm2 = buildPose("RightUpperArm", CFrame.Angles(math.rad(28), math.rad(-16), math.rad(24)), {
			buildPose("RightLowerArm", CFrame.Angles(math.rad(-48), math.rad(18), math.rad(10)), {
				buildPose("RightHand", CFrame.Angles(0, 0, math.rad(20)))
			})
		})
		local upperTorso2 = buildPose("UpperTorso", CFrame.Angles(math.rad(6), 0, 0), {
			buildPose("Head", CFrame.Angles(math.rad(-4), 0, 0)),
			leftArm2, rightArm2
		})
		local lowerTorso2 = buildPose("LowerTorso", CFrame.new(0, sitOffset, 0), {
			upperTorso2, leftLeg2, rightLeg2
		})
		buildPose("HumanoidRootPart", CFrame.identity, { lowerTorso2 }).Parent = kf2
		kf2.Parent = kfs
	else
		-- R6
		local kf0 = Instance.new("Keyframe")
		kf0.Time = 0
		local torso0 = buildPose("Torso", CFrame.new(0, 0, -1.68), {
			buildPose("Head", CFrame.Angles(math.rad(-4), 0, 0)),
			buildPose("Left Arm", CFrame.new(0, -0.15, -0.15) * CFrame.Angles(math.rad(26), math.rad(14), math.rad(-18))),
			buildPose("Right Arm", CFrame.new(0, -0.15, -0.15) * CFrame.Angles(math.rad(26), math.rad(-14), math.rad(18))),
			buildPose("Left Leg", CFrame.new(-0.2, 0.15, -0.6) * CFrame.Angles(math.rad(78), math.rad(-20), math.rad(-55))),
			buildPose("Right Leg", CFrame.new(0.2, 0.15, -0.6) * CFrame.Angles(math.rad(78), math.rad(20), math.rad(55)))
		})
		buildPose("HumanoidRootPart", CFrame.identity, { torso0 }).Parent = kf0
		kf0.Parent = kfs

		local kf1 = Instance.new("Keyframe")
		kf1.Time = 1.5
		local torso1 = buildPose("Torso", CFrame.new(0, 0, -1.64) * CFrame.Angles(math.rad(2), 0, 0), {
			buildPose("Head", CFrame.Angles(math.rad(-3), 0, 0)),
			buildPose("Left Arm", CFrame.new(0, -0.14, -0.15) * CFrame.Angles(math.rad(27), math.rad(14), math.rad(-18))),
			buildPose("Right Arm", CFrame.new(0, -0.14, -0.15) * CFrame.Angles(math.rad(27), math.rad(-14), math.rad(18))),
			buildPose("Left Leg", CFrame.new(-0.2, 0.15, -0.6) * CFrame.Angles(math.rad(78), math.rad(-20), math.rad(-55))),
			buildPose("Right Leg", CFrame.new(0.2, 0.15, -0.6) * CFrame.Angles(math.rad(78), math.rad(20), math.rad(55)))
		})
		buildPose("HumanoidRootPart", CFrame.identity, { torso1 }).Parent = kf1
		kf1.Parent = kfs

		local kf2 = Instance.new("Keyframe")
		kf2.Time = 3.0
		local torso2 = buildPose("Torso", CFrame.new(0, 0, -1.68), {
			buildPose("Head", CFrame.Angles(math.rad(-4), 0, 0)),
			buildPose("Left Arm", CFrame.new(0, -0.15, -0.15) * CFrame.Angles(math.rad(26), math.rad(14), math.rad(-18))),
			buildPose("Right Arm", CFrame.new(0, -0.15, -0.15) * CFrame.Angles(math.rad(26), math.rad(-14), math.rad(18))),
			buildPose("Left Leg", CFrame.new(-0.2, 0.15, -0.6) * CFrame.Angles(math.rad(78), math.rad(-20), math.rad(-55))),
			buildPose("Right Leg", CFrame.new(0.2, 0.15, -0.6) * CFrame.Angles(math.rad(78), math.rad(20), math.rad(55)))
		})
		buildPose("HumanoidRootPart", CFrame.identity, { torso2 }).Parent = kf2
		kf2.Parent = kfs
	end

	return kfs
end

local function applyPoseToJoint(character, jointNames, offsetCFrame)
	local joint = findJoint(character, table.unpack(jointNames))
	if joint then
		if not originalC0s[joint] then
			originalC0s[joint] = joint.C0
		end
		joint.C0 = originalC0s[joint] * offsetCFrame
	end
end

local function applyLotusC0(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local isR15 = character:FindFirstChild("UpperTorso") ~= nil or character:FindFirstChild("LowerTorso") ~= nil
	local hipHeight = humanoid and humanoid.HipHeight
	local sitOffset = (hipHeight and hipHeight > 0.5) and -(hipHeight * 0.92) or -1.85

	if isR15 then
		applyPoseToJoint(character, { "Root", "RootJoint" }, CFrame.new(0, sitOffset, 0))
		applyPoseToJoint(character, { "Waist" }, CFrame.Angles(math.rad(6), 0, 0))
		applyPoseToJoint(character, { "Neck" }, CFrame.Angles(math.rad(-4), 0, 0))
		applyPoseToJoint(character, { "LeftHip", "Left Hip" }, CFrame.Angles(math.rad(72), math.rad(-40), math.rad(-35)))
		applyPoseToJoint(character, { "LeftKnee", "Left Knee" }, CFrame.Angles(math.rad(118), 0, 0))
		applyPoseToJoint(character, { "LeftAnkle", "Left Ankle" }, CFrame.Angles(math.rad(-24), math.rad(-10), math.rad(-15)))
		applyPoseToJoint(character, { "RightHip", "Right Hip" }, CFrame.Angles(math.rad(72), math.rad(40), math.rad(35)))
		applyPoseToJoint(character, { "RightKnee", "Right Knee" }, CFrame.Angles(math.rad(118), 0, 0))
		applyPoseToJoint(character, { "RightAnkle", "Right Ankle" }, CFrame.Angles(math.rad(-24), math.rad(10), math.rad(15)))
		applyPoseToJoint(character, { "LeftShoulder", "Left Shoulder" }, CFrame.Angles(math.rad(28), math.rad(16), math.rad(-24)))
		applyPoseToJoint(character, { "LeftElbow", "Left Elbow" }, CFrame.Angles(math.rad(-48), math.rad(-18), math.rad(-10)))
		applyPoseToJoint(character, { "LeftWrist", "Left Wrist" }, CFrame.Angles(0, 0, math.rad(-20)))
		applyPoseToJoint(character, { "RightShoulder", "Right Shoulder" }, CFrame.Angles(math.rad(28), math.rad(-16), math.rad(24)))
		applyPoseToJoint(character, { "RightElbow", "Right Elbow" }, CFrame.Angles(math.rad(-48), math.rad(18), math.rad(10)))
		applyPoseToJoint(character, { "RightWrist", "Right Wrist" }, CFrame.Angles(0, 0, math.rad(20)))
	else
		applyPoseToJoint(character, { "RootJoint", "Root" }, CFrame.new(0, 0, -1.68))
		applyPoseToJoint(character, { "Neck" }, CFrame.Angles(math.rad(-4), 0, 0))
		applyPoseToJoint(character, { "Left Hip", "LeftHip" }, CFrame.new(-0.2, 0.15, -0.6) * CFrame.Angles(math.rad(78), math.rad(-20), math.rad(-55)))
		applyPoseToJoint(character, { "Right Hip", "RightHip" }, CFrame.new(0.2, 0.15, -0.6) * CFrame.Angles(math.rad(78), math.rad(20), math.rad(55)))
		applyPoseToJoint(character, { "Left Shoulder", "LeftShoulder" }, CFrame.new(0, -0.15, -0.15) * CFrame.Angles(math.rad(26), math.rad(14), math.rad(-18)))
		applyPoseToJoint(character, { "Right Shoulder", "RightShoulder" }, CFrame.new(0, -0.15, -0.15) * CFrame.Angles(math.rad(26), math.rad(-14), math.rad(18)))
	end
end

local function restoreLotusC0(character)
	for _, joint in character:GetDescendants() do
		if joint:IsA("Motor6D") and originalC0s[joint] then
			joint.C0 = originalC0s[joint]
			originalC0s[joint] = nil
		end
	end
end

local function startLotusAnimation(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	for _, track in humanoid:GetPlayingAnimationTracks() do
		track:Stop(0.15)
	end

	local isR15 = character:FindFirstChild("UpperTorso") ~= nil or character:FindFirstChild("LowerTorso") ~= nil
	local hipHeight = humanoid.HipHeight
	local sitOffset = (hipHeight and hipHeight > 0.5) and -(hipHeight * 0.92) or -1.85

	local success, track = pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		local kfs = createLotusKeyframeSequence(isR15, sitOffset)
		local animId = KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		local loaded = animator:LoadAnimation(anim)
		loaded.Priority = Enum.AnimationPriority.Action4
		loaded.Looped = true
		return loaded
	end)

	if success and track then
		activeTracks[character] = track
		track:Play(0.3)
	else
		applyLotusC0(character)
	end
end

local function stopLotusAnimation(character)
	local track = activeTracks[character]
	if track then
		track:Stop(0.3)
		activeTracks[character] = nil
	end
	restoreLotusC0(character)
end

--------------------------------------------------------------------------------
-- Super Saiyan Breakthrough Animation & Aura
--------------------------------------------------------------------------------
local breakthroughEffects = {}

local function createSuperSaiyanKeyframeSequence(isR15)
	local kfs = Instance.new("KeyframeSequence")
	kfs.Loop = true
	kfs.Priority = Enum.AnimationPriority.Action4

	if isR15 then
		local kf0 = Instance.new("Keyframe")
		kf0.Time = 0

		local leftLeg0 = buildPose("LeftUpperLeg", CFrame.Angles(math.rad(22), math.rad(-22), math.rad(-10)), {
			buildPose("LeftLowerLeg", CFrame.Angles(math.rad(42), 0, 0), {
				buildPose("LeftFoot", CFrame.Angles(math.rad(-18), 0, 0))
			})
		})
		local rightLeg0 = buildPose("RightUpperLeg", CFrame.Angles(math.rad(22), math.rad(22), math.rad(10)), {
			buildPose("RightLowerLeg", CFrame.Angles(math.rad(42), 0, 0), {
				buildPose("RightFoot", CFrame.Angles(math.rad(-18), 0, 0))
			})
		})
		local leftArm0 = buildPose("LeftUpperArm", CFrame.Angles(math.rad(-18), math.rad(18), math.rad(-30)), {
			buildPose("LeftLowerArm", CFrame.Angles(math.rad(-90), math.rad(-20), 0), {
				buildPose("LeftHand", CFrame.Angles(0, 0, math.rad(-15)))
			})
		})
		local rightArm0 = buildPose("RightUpperArm", CFrame.Angles(math.rad(-18), math.rad(-18), math.rad(30)), {
			buildPose("RightLowerArm", CFrame.Angles(math.rad(-90), math.rad(20), 0), {
				buildPose("RightHand", CFrame.Angles(0, 0, math.rad(15)))
			})
		})
		local upperTorso0 = buildPose("UpperTorso", CFrame.Angles(math.rad(8), 0, 0), {
			buildPose("Head", CFrame.Angles(math.rad(-14), 0, 0)),
			leftArm0, rightArm0
		})
		local lowerTorso0 = buildPose("LowerTorso", CFrame.new(0, -0.4, 0), {
			upperTorso0, leftLeg0, rightLeg0
		})
		buildPose("HumanoidRootPart", CFrame.identity, { lowerTorso0 }).Parent = kf0
		kf0.Parent = kfs
	else
		local kf0 = Instance.new("Keyframe")
		kf0.Time = 0
		local torso0 = buildPose("Torso", CFrame.new(0, -0.3, 0), {
			buildPose("Head", CFrame.Angles(math.rad(-15), 0, 0)),
			buildPose("Left Arm", CFrame.Angles(math.rad(25), math.rad(15), math.rad(-25))),
			buildPose("Right Arm", CFrame.Angles(math.rad(25), math.rad(-15), math.rad(25))),
			buildPose("Left Leg", CFrame.Angles(math.rad(15), math.rad(-10), 0)),
			buildPose("Right Leg", CFrame.Angles(math.rad(15), math.rad(10), 0))
		})
		buildPose("HumanoidRootPart", CFrame.identity, { torso0 }).Parent = kf0
		kf0.Parent = kfs
	end

	return kfs
end

local function startSuperSaiyanAnimation(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local isR15 = character:FindFirstChild("UpperTorso") ~= nil or character:FindFirstChild("LowerTorso") ~= nil
	local success, track = pcall(function()
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		local kfs = createSuperSaiyanKeyframeSequence(isR15)
		local animId = KeyframeSequenceProvider:RegisterKeyframeSequence(kfs)
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		local loaded = animator:LoadAnimation(anim)
		loaded.Priority = Enum.AnimationPriority.Action4
		loaded.Looped = true
		return loaded
	end)

	if success and track then
		track:Play(0.2)
		return track
	end
	return nil
end

local function playSuperSaiyanAura(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local fx = {}
	breakthroughEffects[character] = fx

	local hl = Instance.new("Highlight")
	hl.Name = "SSAuraHighlight"
	hl.FillColor = Color3.fromRGB(255, 220, 50)
	hl.OutlineColor = Color3.fromRGB(255, 255, 200)
	hl.FillTransparency = 0.4
	hl.OutlineTransparency = 0
	hl.Adornee = character
	hl.Parent = character
	fx.Highlight = hl

	local pl = Instance.new("PointLight")
	pl.Name = "SSAuraLight"
	pl.Color = Color3.fromRGB(255, 215, 60)
	pl.Range = 28
	pl.Brightness = 6
	pl.Parent = root
	fx.Light = pl

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SSAuraParticles"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 120)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 200, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.4, 2.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.6, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Lifetime = NumberRange.new(0.4, 0.9)
	emitter.Rate = 90
	emitter.Speed = NumberRange.new(8, 18)
	emitter.SpreadAngle = Vector2.new(20, 180)
	emitter.Acceleration = Vector3.new(0, 24, 0)
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Parent = root
	fx.Emitter = emitter

	fx.Track = startSuperSaiyanAnimation(character)

	if character == player.Character then
		task.spawn(function()
			local cam = workspace.CurrentCamera
			local t0 = tick()
			while tick() - t0 < 2.5 and fx.Active ~= false do
				RunService.RenderStepped:Wait()
				if cam then
					local intensity = 0.18 + ((tick() - t0) * 0.1)
					cam.CFrame = cam.CFrame * CFrame.Angles(
						math.rad((math.random() - 0.5) * intensity * 2),
						math.rad((math.random() - 0.5) * intensity * 2),
						0
					)
				end
			end
		end)
	end
end

local function playSuperSaiyanExplosion(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local fx = breakthroughEffects[character]
	if fx then
		fx.Active = false
		if fx.Track then
			fx.Track:Stop(0.4)
		end
	end

	if character == player.Character then
		local flash = Instance.new("Frame")
		flash.Name = "SSExplosionFlash"
		flash.BackgroundColor3 = Color3.fromRGB(255, 245, 180)
		flash.Size = UDim2.fromScale(1, 1)
		flash.BorderSizePixel = 0
		flash.ZIndex = 100
		flash.Parent = ui

		TweenService:Create(flash, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		Debris:AddItem(flash, 0.6)

		task.spawn(function()
			local cam = workspace.CurrentCamera
			local t0 = tick()
			while tick() - t0 < 0.6 do
				RunService.RenderStepped:Wait()
				if cam then
					local fade = 1 - ((tick() - t0) / 0.6)
					cam.CFrame = cam.CFrame * CFrame.Angles(
						math.rad((math.random() - 0.5) * 1.6 * fade),
						math.rad((math.random() - 0.5) * 1.6 * fade),
						0
					)
				end
			end
		end)
	end

	local ring = Instance.new("Part")
	ring.Name = "SSShockwaveRing"
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 220, 60)
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.4, 2, 2)
	ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.15
	ring.Parent = workspace

	local ringTween = TweenService:Create(ring, TweenInfo.new(0.7, Enum.EasingStyle.Expo, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.4, 65, 65),
		Transparency = 1
	})
	ringTween:Play()
	Debris:AddItem(ring, 0.8)

	local burst = Instance.new("ParticleEmitter")
	burst.Name = "SSBurstEmitter"
	burst.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 220)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0))
	})
	burst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	burst.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	burst.Lifetime = NumberRange.new(0.5, 0.9)
	burst.Speed = NumberRange.new(25, 60)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.LightEmission = 1
	burst.LightInfluence = 0
	burst.Parent = root
	burst:Emit(150)
	Debris:AddItem(burst, 1.2)

	local head = character:FindFirstChild("Head")
	if head then
		local bbg = Instance.new("BillboardGui")
		bbg.Name = "BreakthroughBanner"
		bbg.AlwaysOnTop = true
		bbg.Size = UDim2.new(0, 280, 0, 50)
		bbg.StudsOffset = Vector3.new(0, 3.5, 0)
		bbg.Adornee = head
		bbg.Parent = character

		local bannerTxt = Instance.new("TextLabel")
		bannerTxt.BackgroundTransparency = 1
		bannerTxt.Size = UDim2.new(1, 0, 1, 0)
		bannerTxt.Font = Enum.Font.GothamBlack
		bannerTxt.Text = "⚡ BREAKTHROUGH SUCCESS! ⚡"
		bannerTxt.TextColor3 = Color3.fromRGB(255, 230, 80)
		bannerTxt.TextScaled = true
		bannerTxt.Parent = bbg

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(180, 80, 10)
		stroke.Thickness = 2
		stroke.Parent = bannerTxt

		task.spawn(function()
			TweenService:Create(bbg, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				StudsOffset = Vector3.new(0, 5.5, 0)
			}):Play()
			task.wait(1.4)
			TweenService:Create(bannerTxt, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			task.wait(0.5)
			bbg:Destroy()
		end)
	end

	task.delay(0.6, function()
		if fx then
			if fx.Emitter then
				fx.Emitter.Rate = 0
				Debris:AddItem(fx.Emitter, 1)
			end
			if fx.Highlight then
				TweenService:Create(fx.Highlight, TweenInfo.new(0.6), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
				Debris:AddItem(fx.Highlight, 0.7)
			end
			if fx.Light then
				TweenService:Create(fx.Light, TweenInfo.new(0.6), { Brightness = 0 }):Play()
				Debris:AddItem(fx.Light, 0.7)
			end
		end
		breakthroughEffects[character] = nil
	end)
end

remote.OnClientEvent:Connect(function(event, targetPlayer)
	local char = targetPlayer and targetPlayer.Character
	if not char then return end

	if event == "BreakthroughStart" then
		playSuperSaiyanAura(char)
	elseif event == "BreakthroughBurst" then
		playSuperSaiyanExplosion(char)
	end
end)

--------------------------------------------------------------------------------
-- Rendering HUD and Stats
--------------------------------------------------------------------------------
local function requirementFor(realm, level)
	if realm ~= "Qi Condensation" then
		return nil
	end
	return math.floor(100 * (2.5 ^ level) + 0.5)
end

local function updateHealthBar()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local hp = math.max(0, math.floor(humanoid.Health))
		local maxHp = math.floor(humanoid.MaxHealth)
		local frac = math.clamp(hp / math.max(1, maxHp), 0, 1)

		healthFill.Size = UDim2.new(frac, 0, 1, 0)
		healthText.Text = string.format("HP: %d / %d", hp, maxHp)
		healthValLabel.Text = string.format("%d / %d", hp, maxHp)
	end
end

local function render()
	local realm = player:GetAttribute("Realm") or "Qi Condensation"
	local level = player:GetAttribute("RealmLevel") or 0
	local qi = player:GetAttribute("Qi") or 0
	local required = requirementFor(realm, level)
	local isCultivating = player:GetAttribute("Cultivating") == true
	local isBreakingThrough = player:GetAttribute("BreakingThrough") == true

	local damage = player:GetAttribute("Damage") or (10 + level * 5)
	local qiMult = player:GetAttribute("QiMultiplier") or (1.0 + level * 0.25)
	local luck = player:GetAttribute("Luck") or (10 + level * 2)

	local leaderstats = player:FindFirstChild("leaderstats")
	local goldVal = leaderstats and leaderstats:FindFirstChild("Gold") and leaderstats.Gold.Value or 0

	local expiry = player:GetAttribute("PillBuffExpiry") or 0
	local now = os.time()
	local remainingPillSec = math.max(0, expiry - now)
	local isPillActive = remainingPillSec > 0

	-- Format Stats
	stageValLabel.Text = string.format("%s · Level %s", realm, toRoman(level))
	damageValLabel.Text = tostring(damage)
	local defense = player:GetAttribute("Defense") or 0
	defenseValLabel.Text = tostring(defense)
	goldValLabel.Text = tostring(goldVal)
	luckValLabel.Text = tostring(luck)
	shopGoldLabel.Text = "Your Gold: 🪙 " .. tostring(goldVal)

	if isPillActive then
		local mins = math.floor(remainingPillSec / 60)
		local secs = remainingPillSec % 60
		qiMultValLabel.Text = string.format("%.2fx (Pill: %dm %02ds)", qiMult, mins, secs)
		qiMultValLabel.TextColor3 = Color3.fromRGB(255, 215, 60)
		buffBadge.Visible = true
		buffBadgeText.Text = string.format("💊 Qi Pill (2x): %d:%02d", mins, secs)
	else
		qiMultValLabel.Text = string.format("%.2fx", qiMult)
		qiMultValLabel.TextColor3 = Color3.fromRGB(255, 235, 150)
		buffBadge.Visible = false
	end

	updateHealthBar()

	cultivateActionBtn.Text = isCultivating and "Cultivating — Press C to Stop" or "Press C to Cultivate"

	if required then
		modalQiText.Text = string.format("Qi: %d / %d", qi, required)
		modalQiFill.Size = UDim2.fromScale(math.clamp(qi / required, 0, 1), 1)
		breakthroughActionBtn.Visible = qi >= required and not isBreakingThrough
	else
		modalQiText.Text = string.format("Qi: %d", qi)
		modalQiFill.Size = UDim2.fromScale(1, 1)
		breakthroughActionBtn.Visible = false
	end
end

for _, attr in { "Qi", "Realm", "RealmLevel", "Cultivating", "Damage", "Defense", "EquippedHelmet", "EquippedArmor", "QiMultiplier", "Luck", "BreakingThrough", "PillBuffExpiry" } do
	player:GetAttributeChangedSignal(attr):Connect(function()
		render()
		renderInventory()
	end)
end

local function connectLeaderstats()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local gold = leaderstats:FindFirstChild("Gold")
		if gold then
			gold:GetPropertyChangedSignal("Value"):Connect(render)
		end
	end
end
player.ChildAdded:Connect(connectLeaderstats)
connectLeaderstats()
render()

-- Watch inventory folder for updates
local function connectInventoryWatch()
	local inv = player:WaitForChild("Inventory", 5)
	if inv then
		inv.ChildAdded:Connect(renderInventory)
		for _, child in ipairs(inv:GetChildren()) do
			child:GetPropertyChangedSignal("Value"):Connect(renderInventory)
		end
	end
end
task.spawn(connectInventoryWatch)

-- Heartbeat loop for countdown display
task.spawn(function()
	while true do
		task.wait(1)
		local expiry = player:GetAttribute("PillBuffExpiry") or 0
		if expiry > os.time() then
			render()
		end
	end
end)

--------------------------------------------------------------------------------
-- Cultivation Controls & Actions
--------------------------------------------------------------------------------
local Controls = nil
local function getControls()
	if Controls then
		return Controls
	end
	local playerScripts = player:FindFirstChild("PlayerScripts")
	if playerScripts then
		local playerModuleObj = playerScripts:FindFirstChild("PlayerModule")
		if playerModuleObj then
			local ok, module = pcall(require, playerModuleObj)
			if ok and module and module.GetControls then
				Controls = module:GetControls()
				return Controls
			end
		end
	end
	return nil
end

local function canStartCultivating()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		return false
	end
	return true
end

local function toggleCultivation()
	if player:GetAttribute("BreakingThrough") then return end
	local isCultivating = player:GetAttribute("Cultivating") == true
	if not isCultivating and not canStartCultivating() then
		return
	end
	if not isCultivating then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end
	remote:FireServer("Cultivate")
end

local function triggerBreakthrough()
	if player:GetAttribute("BreakingThrough") then return end
	local required = requirementFor(player:GetAttribute("Realm"), player:GetAttribute("RealmLevel") or 0)
	local qi = player:GetAttribute("Qi") or 0
	if not required or qi < required then
		return
	end
	remote:FireServer("Breakthrough")
end

cultivateActionBtn.Activated:Connect(toggleCultivation)
breakthroughActionBtn.Activated:Connect(triggerBreakthrough)

--------------------------------------------------------------------------------
-- 100% Reliable Combat Key "1" Toggle
--------------------------------------------------------------------------------
local function toggleEquipCombat()
	if player:GetAttribute("Cultivating") or player:GetAttribute("BreakingThrough") then
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Check if a tool is currently held in character
	local heldTool = character:FindFirstChildOfClass("Tool")
	if heldTool then
		-- Unequip back into backpack
		humanoid:UnequipTools()
	else
		-- Equip Combat tool or first available tool in backpack
		local backpack = player:FindFirstChildOfClass("Backpack")
		local tool = backpack and (backpack:FindFirstChild("Combat") or backpack:FindFirstChildOfClass("Tool"))
		if tool then
			humanoid:EquipTool(tool)
		end
	end
end

--------------------------------------------------------------------------------
-- Q-Key Dash (1.2s cooldown)
--------------------------------------------------------------------------------
local DASH_COOLDOWN = 1.2
local DASH_FORCE = 85   -- studs/s impulse
local DASH_DURATION = 0.18 -- how long the velocity lasts
local lastDashTime = 0

local function performDash()
	-- Can't dash while cultivating or breaking through
	if player:GetAttribute("Cultivating") or player:GetAttribute("BreakingThrough") then
		return
	end

	-- Cooldown check
	local now = tick()
	if now - lastDashTime < DASH_COOLDOWN then
		return
	end
	lastDashTime = now

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then return end

	-- Dash direction: prioritized by player's movement input (W/A/S/D), fallback to camera/look vector
	local moveDir = humanoid.MoveDirection
	local dashDir
	if moveDir.Magnitude > 0.1 then
		dashDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
	else
		local camera = workspace.CurrentCamera
		if camera then
			dashDir = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		else
			dashDir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
		end
		if dashDir.Magnitude < 0.01 then
			dashDir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
		end
		dashDir = dashDir.Unit
	end

	-- Quick VFX: brief trail effect using dust / chi particles
	local dashAttach = Instance.new("Attachment")
	dashAttach.Parent = hrp

	local dashParticles = Instance.new("ParticleEmitter")
	dashParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	dashParticles.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255), Color3.fromRGB(100, 160, 255))
	dashParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	dashParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	dashParticles.Lifetime = NumberRange.new(0.2, 0.4)
	dashParticles.Rate = 120
	dashParticles.Speed = NumberRange.new(2, 5)
	dashParticles.SpreadAngle = Vector2.new(30, 30)
	dashParticles.Parent = dashAttach

	-- Apply velocity via LinearVelocity
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = dashAttach
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce = 100000
	lv.VectorVelocity = dashDir * DASH_FORCE
	lv.Parent = hrp

	-- Lean animation
	local animTrack = nil
	local kfs = Instance.new("KeyframeSequence")
	kfs.Priority = Enum.AnimationPriority.Action4
	kfs.Loop = false

	local kf = Instance.new("Keyframe")
	kf.Time = 0

	local rootPose = Instance.new("Pose")
	rootPose.Name = "HumanoidRootPart"
	rootPose.CFrame = CFrame.Angles(math.rad(12), 0, 0)
	rootPose.Parent = kf
	kf.Parent = kfs

	local kf2 = Instance.new("Keyframe")
	kf2.Time = DASH_DURATION

	local rootPose2 = Instance.new("Pose")
	rootPose2.Name = "HumanoidRootPart"
	rootPose2.CFrame = CFrame.new()
	rootPose2.Parent = kf2
	kf2.Parent = kfs

	local ok, animId = pcall(function()
		return game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(kfs)
	end)
	if ok and animId then
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			animTrack = animator:LoadAnimation(anim)
			animTrack:Play(0.05)
		end
	end

	-- Clean up velocity after dash duration
	task.delay(DASH_DURATION, function()
		if lv and lv.Parent then
			lv:Destroy()
		end
		dashParticles.Rate = 0
	end)

	-- Remove attachment after particles fade
	task.delay(DASH_DURATION + 0.5, function()
		if dashAttach and dashAttach.Parent then
			dashAttach:Destroy()
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	-- Ignore if typing in a TextBox / Chat
	if isTyping() then
		return
	end

	if input.KeyCode == Enum.KeyCode.C then
		toggleCultivation()
	elseif input.KeyCode == Enum.KeyCode.One then
		-- Fire toggleEquipCombat directly regardless of backpack processed state!
		toggleEquipCombat()
	elseif input.KeyCode == Enum.KeyCode.Q then
		performDash()
	end
end)


--------------------------------------------------------------------------------
-- Cultivation State Handler (Movement Freeze, Lotus Pose)
--------------------------------------------------------------------------------
local function handleCultivationState()
	local isCultivating = player:GetAttribute("Cultivating") == true
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local controls = getControls()

	if isCultivating then
		if controls then
			controls:Disable()
		end
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
		end
		if character then
			startLotusAnimation(character)
		end
	else
		if controls then
			controls:Enable()
		end
		if humanoid then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			local savedSpeed = player:GetAttribute("CultivationWalkSpeed")
			humanoid.WalkSpeed = (savedSpeed and savedSpeed > 0) and savedSpeed or 16
			local savedJump = player:GetAttribute("CultivationJumpPower")
			humanoid.JumpPower = (savedJump and savedJump > 0) and savedJump or 50
			local savedHeight = player:GetAttribute("CultivationJumpHeight")
			humanoid.JumpHeight = (savedHeight and savedHeight > 0) and savedHeight or 7.2
		end
		if character then
			stopLotusAnimation(character)
		end
	end
end

local function setupPlayerCultivation(p)
	p:GetAttributeChangedSignal("Cultivating"):Connect(function()
		local isCult = p:GetAttribute("Cultivating") == true
		local char = p.Character
		if char then
			if isCult then
				startLotusAnimation(char)
			else
				stopLotusAnimation(char)
			end
		end
		if p == player then
			handleCultivationState()
		end
	end)
end

Players.PlayerAdded:Connect(setupPlayerCultivation)
for _, p in Players:GetPlayers() do
	setupPlayerCultivation(p)
end

local function onLocalCharacter(character)
	task.wait()
	handleCultivationState()
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.HealthChanged:Connect(updateHealthBar)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealthBar)
		updateHealthBar()
	end
end

player.CharacterAdded:Connect(onLocalCharacter)
if player.Character then
	task.spawn(onLocalCharacter, player.Character)
end

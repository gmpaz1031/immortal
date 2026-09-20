import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def build_pro_inventory_ui():
    print("=== Constructing Complete High-Budget Xianxia Inventory UI ===")

    lua_ui = """
    local StarterGui = game:GetService("StarterGui")
    local ui = StarterGui:WaitForChild("CultivationUI")
    local invModal = ui:WaitForChild("InventoryScrollModal")

    -- Clean old children inside InventoryScrollModal
    for _, ch in ipairs(invModal:GetChildren()) do
        ch:Destroy()
    end

    -- 1. BASE MODAL WINDOW (Large 820x520 dual-panel centered layout)
    invModal.Size = UDim2.new(0, 820, 0, 520)
    invModal.Position = UDim2.new(0.5, 0, 0.5, 0)
    invModal.AnchorPoint = Vector2.new(0.5, 0.5)
    invModal.BackgroundColor3 = Color3.fromRGB(15, 19, 24)
    invModal.BackgroundTransparency = 0.05
    invModal.BorderSizePixel = 0
    invModal.ZIndex = 50

    local baseCorner = Instance.new("UICorner")
    baseCorner.CornerRadius = UDim.new(0, 10)
    baseCorner.Parent = invModal

    local baseStroke = Instance.new("UIStroke")
    baseStroke.Color = Color3.fromRGB(215, 180, 85) -- Imperial Gold
    baseStroke.Thickness = 1.8
    baseStroke.Parent = invModal

    -- Subtle Inner Trim
    local innerTrim = Instance.new("Frame")
    innerTrim.Name = "InnerTrim"
    innerTrim.Size = UDim2.new(1, -8, 1, -8)
    innerTrim.Position = UDim2.new(0, 4, 0, 4)
    innerTrim.BackgroundTransparency = 1
    innerTrim.ZIndex = 51
    innerTrim.Parent = invModal

    local trimStroke = Instance.new("UIStroke")
    trimStroke.Color = Color3.fromRGB(45, 95, 80) -- Jade Accent
    trimStroke.Thickness = 1.0
    trimStroke.Transparency = 0.4
    trimStroke.Parent = innerTrim

    local trimCorner = Instance.new("UICorner")
    trimCorner.CornerRadius = UDim.new(0, 8)
    trimCorner.Parent = innerTrim

    -- 2. TOP HEADER BAR
    local header = Instance.new("Frame")
    header.Name = "HeaderBar"
    header.Size = UDim2.new(1, -24, 0, 44)
    header.Position = UDim2.new(0, 12, 0, 10)
    header.BackgroundTransparency = 1
    header.ZIndex = 52
    header.Parent = invModal

    -- Title Plaque
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 150, 1, 0)
    title.Position = UDim2.new(0, 6, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "INVENTORY"
    title.TextColor3 = Color3.fromRGB(245, 215, 110)
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 53
    title.Parent = header

    -- Search Box
    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchFrame"
    searchFrame.Size = UDim2.new(0, 200, 0, 30)
    searchFrame.Position = UDim2.new(0, 170, 0.5, -15)
    searchFrame.BackgroundColor3 = Color3.fromRGB(22, 28, 35)
    searchFrame.ZIndex = 53
    searchFrame.Parent = header

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 6)
    sCorner.Parent = searchFrame

    local sStroke = Instance.new("UIStroke")
    sStroke.Color = Color3.fromRGB(55, 75, 70)
    sStroke.Thickness = 1.0
    sStroke.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -16, 1, 0)
    searchBox.Position = UDim2.new(0, 10, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Font = Enum.Font.Gotham
    searchBox.PlaceholderText = "Search inventory..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(110, 130, 135)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.fromRGB(235, 245, 245)
    searchBox.TextSize = 12
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ZIndex = 54
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame

    -- Capacity Indicator
    local capacityLbl = Instance.new("TextLabel")
    capacityLbl.Name = "CapacityLabel"
    capacityLbl.Size = UDim2.new(0, 150, 1, 0)
    capacityLbl.Position = UDim2.new(1, -210, 0, 0)
    capacityLbl.BackgroundTransparency = 1
    capacityLbl.Font = Enum.Font.GothamMedium
    capacityLbl.Text = "Capacity: 0 / 100"
    capacityLbl.TextColor3 = Color3.fromRGB(140, 215, 195)
    capacityLbl.TextSize = 13
    capacityLbl.TextXAlignment = Enum.TextXAlignment.Right
    capacityLbl.ZIndex = 53
    capacityLbl.Parent = header

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -34, 0.5, -16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(28, 36, 44)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(215, 180, 85)
    closeBtn.TextSize = 14
    closeBtn.ZIndex = 54
    closeBtn.Parent = header

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 16)
    cCorner.Parent = closeBtn

    local cStroke = Instance.new("UIStroke")
    cStroke.Color = Color3.fromRGB(180, 140, 60)
    cStroke.Thickness = 1.2
    cStroke.Parent = closeBtn

    -- Also clone to direct child of invModal for universal compatibility
    local directClose = closeBtn:Clone()
    directClose.Position = UDim2.new(1, -44, 0, 12)
    directClose.Parent = invModal

    -- 3. CATEGORY TABS BAR (5 Distinct Tabs: MISC, PILLS, MANUALS, SKILLS, EQUIPMENT)
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "CategoryTabs"
    tabContainer.Size = UDim2.new(1, -24, 0, 36)
    tabContainer.Position = UDim2.new(0, 12, 0, 58)
    tabContainer.BackgroundTransparency = 1
    tabContainer.ZIndex = 52
    tabContainer.Parent = invModal

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabContainer

    local categories = { "MISC", "PILLS", "MANUALS", "SKILLS", "EQUIPMENT" }
    for _, catName in ipairs(categories) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. catName
        tabBtn.Size = UDim2.new(0, 120, 1, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(20, 26, 32)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.Text = catName
        tabBtn.TextColor3 = Color3.fromRGB(160, 180, 185)
        tabBtn.TextSize = 12
        tabBtn.ZIndex = 53
        tabBtn.Parent = tabContainer

        local tbCorner = Instance.new("UICorner")
        tbCorner.CornerRadius = UDim.new(0, 6)
        tbCorner.Parent = tabBtn

        local tbStroke = Instance.new("UIStroke")
        tbStroke.Name = "TabStroke"
        tbStroke.Color = Color3.fromRGB(45, 60, 65)
        tbStroke.Thickness = 1.0
        tbStroke.Parent = tabBtn
    end

    -- 4. MAIN DUAL-PANEL CONTENT CONTAINER
    local mainBody = Instance.new("Frame")
    mainBody.Name = "MainBody"
    mainBody.Size = UDim2.new(1, -24, 0, 410)
    mainBody.Position = UDim2.new(0, 12, 0, 100)
    mainBody.BackgroundTransparency = 1
    mainBody.ZIndex = 52
    mainBody.Parent = invModal

    -- LEFT PANEL: GRID INVENTORY
    local gridContainer = Instance.new("Frame")
    gridContainer.Name = "GridContainer"
    gridContainer.Size = UDim2.new(0, 490, 1, 0)
    gridContainer.Position = UDim2.new(0, 0, 0, 0)
    gridContainer.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    gridContainer.BackgroundTransparency = 0.2
    gridContainer.ZIndex = 53
    gridContainer.Parent = mainBody

    local gcCorner = Instance.new("UICorner")
    gcCorner.CornerRadius = UDim.new(0, 8)
    gcCorner.Parent = gridContainer

    local gcStroke = Instance.new("UIStroke")
    gcStroke.Color = Color3.fromRGB(40, 55, 60)
    gcStroke.Thickness = 1.0
    gcStroke.Parent = gridContainer

    -- ItemList ScrollingFrame (Maintains compatibility with CultivationClient)
    local itemList = Instance.new("ScrollingFrame")
    itemList.Name = "ItemList"
    itemList.Size = UDim2.new(1, -16, 1, -16)
    itemList.Position = UDim2.new(0, 8, 0, 8)
    itemList.BackgroundTransparency = 1
    itemList.BorderSizePixel = 0
    itemList.ScrollBarThickness = 5
    itemList.ScrollBarImageColor3 = Color3.fromRGB(180, 145, 75)
    itemList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemList.ZIndex = 54
    itemList.Parent = gridContainer

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Name = "GridLayout"
    gridLayout.CellSize = UDim2.new(0, 78, 0, 78)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = itemList

    -- RIGHT PANEL: DETAILED ITEM INSPECTION CARD
    local inspectPanel = Instance.new("Frame")
    inspectPanel.Name = "InspectPanel"
    inspectPanel.Size = UDim2.new(0, 286, 1, 0)
    inspectPanel.Position = UDim2.new(1, -286, 0, 0)
    inspectPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    inspectPanel.BackgroundTransparency = 0.15
    inspectPanel.ZIndex = 53
    inspectPanel.Parent = mainBody

    local ipCorner = Instance.new("UICorner")
    ipCorner.CornerRadius = UDim.new(0, 8)
    ipCorner.Parent = inspectPanel

    local ipStroke = Instance.new("UIStroke")
    ipStroke.Color = Color3.fromRGB(180, 145, 75)
    ipStroke.Thickness = 1.2
    ipStroke.Parent = inspectPanel

    -- Large Framed Icon Display
    local iconBox = Instance.new("Frame")
    iconBox.Name = "IconBox"
    iconBox.Size = UDim2.new(0, 80, 0, 80)
    iconBox.Position = UDim2.new(0.5, -40, 0, 12)
    iconBox.BackgroundColor3 = Color3.fromRGB(24, 32, 38)
    iconBox.ZIndex = 54
    iconBox.Parent = inspectPanel

    local ibCorner = Instance.new("UICorner")
    ibCorner.CornerRadius = UDim.new(0, 8)
    ibCorner.Parent = iconBox

    local ibStroke = Instance.new("UIStroke")
    ibStroke.Name = "RarityGlow"
    ibStroke.Color = Color3.fromRGB(140, 220, 210)
    ibStroke.Thickness = 1.5
    ibStroke.Parent = iconBox

    local iconGlyph = Instance.new("TextLabel")
    iconGlyph.Name = "IconGlyph"
    iconGlyph.Size = UDim2.new(1, 0, 1, 0)
    iconGlyph.BackgroundTransparency = 1
    iconGlyph.Font = Enum.Font.GothamBold
    iconGlyph.Text = "QI"
    iconGlyph.TextColor3 = Color3.fromRGB(245, 250, 255)
    iconGlyph.TextSize = 22
    iconGlyph.ZIndex = 55
    iconGlyph.Parent = iconBox

    -- Item Title
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "ItemName"
    nameLabel.Size = UDim2.new(1, -20, 0, 22)
    nameLabel.Position = UDim2.new(0, 10, 0, 98)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = "Select an Item"
    nameLabel.TextColor3 = Color3.fromRGB(245, 215, 110)
    nameLabel.TextSize = 14
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 54
    nameLabel.Parent = inspectPanel

    -- Item Tier & Category
    local tierLabel = Instance.new("TextLabel")
    tierLabel.Name = "ItemTier"
    tierLabel.Size = UDim2.new(1, -20, 0, 16)
    tierLabel.Position = UDim2.new(0, 10, 0, 120)
    tierLabel.BackgroundTransparency = 1
    tierLabel.Font = Enum.Font.GothamMedium
    tierLabel.Text = "COMMON MATERIAL"
    tierLabel.TextColor3 = Color3.fromRGB(90, 225, 195)
    tierLabel.TextSize = 11
    tierLabel.ZIndex = 54
    tierLabel.Parent = inspectPanel

    -- Lore & Description Parchment Frame
    local descFrame = Instance.new("Frame")
    descFrame.Name = "DescFrame"
    descFrame.Size = UDim2.new(1, -20, 0, 100)
    descFrame.Position = UDim2.new(0, 10, 0, 142)
    descFrame.BackgroundColor3 = Color3.fromRGB(24, 29, 36)
    descFrame.ZIndex = 54
    descFrame.Parent = inspectPanel

    local dfCorner = Instance.new("UICorner")
    dfCorner.CornerRadius = UDim.new(0, 6)
    dfCorner.Parent = descFrame

    local dfStroke = Instance.new("UIStroke")
    dfStroke.Color = Color3.fromRGB(45, 55, 62)
    dfStroke.Thickness = 1.0
    dfStroke.Parent = descFrame

    local descText = Instance.new("TextLabel")
    descText.Name = "DescText"
    descText.Size = UDim2.new(1, -16, 1, -12)
    descText.Position = UDim2.new(0, 8, 0, 6)
    descText.BackgroundTransparency = 1
    descText.Font = Enum.Font.Gotham
    descText.Text = "Click any item slot on the left grid to view its properties, cultivation stats, and alchemical grade."
    descText.TextColor3 = Color3.fromRGB(200, 210, 215)
    descText.TextSize = 11
    descText.TextWrapped = true
    descText.TextYAlignment = Enum.TextYAlignment.Top
    descText.ZIndex = 55
    descText.Parent = descFrame

    -- Stats & Modifiers
    local statLabel = Instance.new("TextLabel")
    statLabel.Name = "StatLabel"
    statLabel.Size = UDim2.new(1, -20, 0, 48)
    statLabel.Position = UDim2.new(0, 10, 0, 248)
    statLabel.BackgroundTransparency = 1
    statLabel.Font = Enum.Font.GothamMedium
    statLabel.Text = "+0 Qi Regeneration\\nIncreases Cultivation Speed"
    statLabel.TextColor3 = Color3.fromRGB(110, 230, 240)
    statLabel.TextSize = 11
    statLabel.TextWrapped = true
    statLabel.TextYAlignment = Enum.TextYAlignment.Top
    statLabel.ZIndex = 54
    statLabel.Parent = inspectPanel

    -- Economic Value Label
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueLabel"
    valueLabel.Size = UDim2.new(1, -20, 0, 20)
    valueLabel.Position = UDim2.new(0, 10, 0, 304)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = "SELL VALUE: 10 SPIRIT STONES"
    valueLabel.TextColor3 = Color3.fromRGB(245, 205, 95)
    valueLabel.TextSize = 12
    valueLabel.ZIndex = 54
    valueLabel.Parent = inspectPanel

    -- Action Buttons (USE/EQUIP & DISCARD)
    local actionBtn = Instance.new("TextButton")
    actionBtn.Name = "ActionBtn"
    actionBtn.Size = UDim2.new(0.55, -4, 0, 36)
    actionBtn.Position = UDim2.new(0, 10, 1, -46)
    actionBtn.BackgroundColor3 = Color3.fromRGB(24, 75, 58)
    actionBtn.Font = Enum.Font.GothamBold
    actionBtn.Text = "USE"
    actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    actionBtn.TextSize = 12
    actionBtn.ZIndex = 55
    actionBtn.Parent = inspectPanel

    local aCorner = Instance.new("UICorner")
    aCorner.CornerRadius = UDim.new(0, 6)
    aCorner.Parent = actionBtn

    local aStroke = Instance.new("UIStroke")
    aStroke.Color = Color3.fromRGB(180, 145, 75)
    aStroke.Thickness = 1.0
    aStroke.Parent = actionBtn

    local discardBtn = Instance.new("TextButton")
    discardBtn.Name = "DiscardBtn"
    discardBtn.Size = UDim2.new(0.45, -6, 0, 36)
    discardBtn.Position = UDim2.new(0.55, 2, 1, -46)
    discardBtn.BackgroundColor3 = Color3.fromRGB(36, 42, 48)
    discardBtn.Font = Enum.Font.GothamBold
    discardBtn.Text = "DISCARD"
    discardBtn.TextColor3 = Color3.fromRGB(175, 185, 195)
    discardBtn.TextSize = 11
    discardBtn.ZIndex = 55
    discardBtn.Parent = inspectPanel

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(0, 6)
    dCorner.Parent = discardBtn

    local dStroke = Instance.new("UIStroke")
    dStroke.Color = Color3.fromRGB(60, 70, 80)
    dStroke.Thickness = 1.0
    dStroke.Parent = discardBtn

    return "Successfully constructed Pro Xianxia Inventory UI hierarchy!"
    """

    ok, res = exec_code(lua_ui)
    print("Build UI Result:", ok, res)
    assert ok, f"Failed building UI: {res}"

if __name__ == '__main__':
    build_pro_inventory_ui()

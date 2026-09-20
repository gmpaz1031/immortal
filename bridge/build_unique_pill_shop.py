import sys
import os
from pathlib import Path
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy_unique_pill_shop():
    print("=== Building Unique Xianxia Pill Refining Pavilion & Alchemist NPC ===")

    lua_shop = """
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")

    local cultivationRemote = ReplicatedStorage:WaitForChild("CultivationRemote")

    -- Find or clean up existing ShopMerchant
    local existing = Workspace:FindFirstChild("ShopMerchant", true)
    local shopPosition = Vector3.new(24, 0, -11)
    local shopOrientation = CFrame.Angles(0, math.rad(-45), 0)

    if existing then
        shopPosition = existing:GetPivot().Position
        existing:Destroy()
    end

    local existingCircle = Workspace:FindFirstChild("ShopCircle", true)
    if existingCircle then
        existingCircle:Destroy()
    end

    -- Raycast down to find ground level
    local groundRay = Workspace:Raycast(Vector3.new(shopPosition.X, shopPosition.Y + 20, shopPosition.Z), Vector3.new(0, -50, 0))
    if groundRay and groundRay.Position then
        shopPosition = groundRay.Position
    end

    local shopModel = Instance.new("Model")
    shopModel.Name = "ShopMerchant"
    shopModel.Parent = Workspace

    local originCF = CFrame.new(shopPosition) * shopOrientation

    local function makePart(parent, name, size, cf, color, mat, shape)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.CFrame = cf
        p.Color = color
        p.Material = mat or Enum.Material.SmoothPlastic
        if shape then p.Shape = shape end
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Parent = parent
        return p
    end

    -- 1. ROOT & PLATFORM
    local hrp = makePart(shopModel, "HumanoidRootPart", Vector3.new(2, 2, 2), originCF * CFrame.new(0, 1.5, 0), Color3.fromRGB(0,0,0), Enum.Material.SmoothPlastic)
    hrp.Transparency = 1
    shopModel.PrimaryPart = hrp

    -- Elegant stone courtyard dais / stone tiles (replacing bare neon disc)
    local dais = makePart(shopModel, "ShopDais", Vector3.new(10, 0.25, 10), originCF * CFrame.new(0, 0.12, 0), Color3.fromRGB(55, 62, 58), Enum.Material.Slate, Enum.PartType.Cylinder)
    dais.CFrame = dais.CFrame * CFrame.Angles(0, 0, math.rad(90))

    -- Inner decorative jade mosaic ring
    local jadeRing = makePart(shopModel, "JadeMosaicRing", Vector3.new(8.5, 0.28, 8.5), originCF * CFrame.new(0, 0.14, 0), Color3.fromRGB(35, 95, 70), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
    jadeRing.CFrame = jadeRing.CFrame * CFrame.Angles(0, 0, math.rad(90))

    -- 2. APOTHECARY COUNTER & CABINET
    local counterCol = Color3.fromRGB(75, 45, 28) -- Deep lacquered redwood
    local goldTrim = Color3.fromRGB(215, 175, 75)

    -- Main front counter
    local counter = makePart(shopModel, "ApothecaryCounter", Vector3.new(4.8, 2.6, 1.2), originCF * CFrame.new(0, 1.3, -1.8), counterCol, Enum.Material.Wood)
    counter.CanCollide = true

    -- Countertop gold trim
    makePart(shopModel, "CounterTrim", Vector3.new(5.0, 0.15, 1.35), originCF * CFrame.new(0, 2.6, -1.8), goldTrim, Enum.Material.SmoothPlastic)

    -- Miniature medicine drawers on front of counter
    for r = 1, 2 do
        for c = 1, 4 do
            local dX = -1.6 + (c - 1) * 1.05
            local dY = 0.8 + (r - 1) * 0.95
            local drawer = makePart(shopModel, "Drawer_" .. r .. "_" .. c, Vector3.new(0.85, 0.75, 0.08), originCF * CFrame.new(dX, dY, -2.42), Color3.fromRGB(58, 32, 20), Enum.Material.Wood)
            -- Brass knob
            makePart(shopModel, "Knob_" .. r .. "_" .. c, Vector3.new(0.12, 0.12, 0.12), originCF * CFrame.new(dX, dY, -2.48), goldTrim, Enum.Material.Metal, Enum.PartType.Ball)
        end
    end

    -- 3. DISPLAYED SPIRITUAL ELIXIRS & PILL GOURDS ON COUNTER
    -- Golden Pill Gourd (Hu Lu)
    local gourdBase = originCF * CFrame.new(-1.4, 2.9, -1.8)
    makePart(shopModel, "GourdLower", Vector3.new(0.55, 0.55, 0.55), gourdBase, Color3.fromRGB(225, 180, 60), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makePart(shopModel, "GourdUpper", Vector3.new(0.40, 0.40, 0.40), gourdBase * CFrame.new(0, 0.4, 0), Color3.fromRGB(235, 195, 75), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    makePart(shopModel, "GourdCork", Vector3.new(0.14, 0.20, 0.14), gourdBase * CFrame.new(0, 0.65, 0), Color3.fromRGB(150, 45, 30), Enum.Material.Wood, Enum.PartType.Cylinder)

    -- Jade Medicine Flask
    local flaskBase = originCF * CFrame.new(1.4, 2.9, -1.8)
    makePart(shopModel, "JadeFlaskBody", Vector3.new(0.48, 0.65, 0.48), flaskBase, Color3.fromRGB(85, 215, 155), Enum.Material.Glass, Enum.PartType.Cylinder)
    makePart(shopModel, "JadeFlaskGlow", Vector3.new(0.35, 0.50, 0.35), flaskBase, Color3.fromRGB(120, 245, 185), Enum.Material.Neon, Enum.PartType.Cylinder)

    -- 4. ANCIENT BRONZE TRIPOD ALCHEMY CAULDRON (Dan Lu)
    local cauldronBase = originCF * CFrame.new(2.8, 1.2, 0.2)
    local bronzeCol = Color3.fromRGB(135, 105, 65)

    -- Cauldron bowl
    makePart(shopModel, "CauldronBelly", Vector3.new(1.6, 1.3, 1.6), cauldronBase * CFrame.new(0, 0.65, 0), bronzeCol, Enum.Material.Metal, Enum.PartType.Ball)
    local rim = makePart(shopModel, "CauldronRim", Vector3.new(1.7, 0.2, 1.7), cauldronBase * CFrame.new(0, 1.2, 0), bronzeCol, Enum.Material.Metal, Enum.PartType.Cylinder)
    rim.CFrame = rim.CFrame * CFrame.Angles(0, 0, math.rad(90))

    -- Glowing celestial embers inside cauldron
    local embers = makePart(shopModel, "CauldronEmbers", Vector3.new(1.2, 0.15, 1.2), cauldronBase * CFrame.new(0, 1.1, 0), Color3.fromRGB(75, 225, 205), Enum.Material.Neon, Enum.PartType.Cylinder)
    embers.CFrame = embers.CFrame * CFrame.Angles(0, 0, math.rad(90))

    -- 3 tripod legs
    for leg = 1, 3 do
        local legAngle = math.rad((leg - 1) * 120)
        local legCf = cauldronBase * CFrame.Angles(0, legAngle, 0) * CFrame.new(0.65, 0.15, 0) * CFrame.Angles(0, 0, math.rad(22))
        makePart(shopModel, "CauldronLeg_" .. leg, Vector3.new(0.24, 0.85, 0.24), legCf, bronzeCol, Enum.Material.Metal, Enum.PartType.Cylinder)
    end

    -- 5. ALCHEMIST NPC: ELDER YE (Daoist Master Alchemist)
    local npcBase = originCF * CFrame.new(0, 0, 0.2)

    -- Robed body
    local robesLower = makePart(shopModel, "AlchemistRobesLower", Vector3.new(1.8, 2.0, 1.3), npcBase * CFrame.new(0, 1.0, 0), Color3.fromRGB(30, 68, 55), Enum.Material.SmoothPlastic)
    local robesUpper = makePart(shopModel, "AlchemistTorso", Vector3.new(1.9, 1.8, 1.2), npcBase * CFrame.new(0, 2.4, 0), Color3.fromRGB(24, 56, 45), Enum.Material.SmoothPlastic)

    -- Imperial gold sash / belt
    makePart(shopModel, "GoldSash", Vector3.new(2.0, 0.28, 1.3), npcBase * CFrame.new(0, 1.9, 0), goldTrim, Enum.Material.SmoothPlastic)
    makePart(shopModel, "JadePendant", Vector3.new(0.35, 0.5, 0.1), npcBase * CFrame.new(0.45, 1.6, -0.65), Color3.fromRGB(90, 215, 150), Enum.Material.Glass)

    -- Head & serene Daoist expression
    local head = makePart(shopModel, "AlchemistHead", Vector3.new(1.15, 1.15, 1.15), npcBase * CFrame.new(0, 3.6, 0), Color3.fromRGB(245, 215, 180), Enum.Material.SmoothPlastic)

    -- Traditional Daoist Conical Bamboo Hat (Doupeng / Li Mao)
    local hatCf = npcBase * CFrame.new(0, 4.35, 0)
    local hatBrim = makePart(shopModel, "BambooHatBrim", Vector3.new(2.8, 0.12, 2.8), hatCf, Color3.fromRGB(195, 160, 110), Enum.Material.Wood, Enum.PartType.Cylinder)
    hatBrim.CFrame = hatBrim.CFrame * CFrame.Angles(0, 0, math.rad(90))
    local hatCone = makePart(shopModel, "BambooHatCone", Vector3.new(1.8, 0.5, 1.8), hatCf * CFrame.new(0, 0.22, 0), Color3.fromRGB(180, 145, 95), Enum.Material.Wood, Enum.PartType.Cylinder)
    hatCone.CFrame = hatCone.CFrame * CFrame.Angles(0, 0, math.rad(90))
    -- Jade medallion on top of hat
    makePart(shopModel, "HatJadeCrest", Vector3.new(0.3, 0.15, 0.3), hatCf * CFrame.new(0, 0.5, 0), Color3.fromRGB(90, 220, 160), Enum.Material.Glass, Enum.PartType.Cylinder)

    -- Herbalist backpack (Beilou) slung on back with rolled elixir scrolls and herbs
    local packCf = npcBase * CFrame.new(0, 2.4, 0.85)
    makePart(shopModel, "HerbBasket", Vector3.new(1.3, 1.6, 0.75), packCf, Color3.fromRGB(140, 105, 68), Enum.Material.Wood)
    makePart(shopModel, "BasketRim", Vector3.new(1.4, 0.15, 0.85), packCf * CFrame.new(0, 0.8, 0), Color3.fromRGB(115, 80, 48), Enum.Material.Wood)
    -- Peeking herbal leaves
    makePart(shopModel, "PeekingHerbs", Vector3.new(0.8, 0.4, 0.3), packCf * CFrame.new(0, 0.95, 0), Color3.fromRGB(70, 185, 100), Enum.Material.SmoothPlastic)

    -- Left arm resting naturally on counter
    makePart(shopModel, "LeftArm", Vector3.new(0.8, 1.6, 0.8), npcBase * CFrame.new(-1.3, 2.2, -0.4) * CFrame.Angles(math.rad(30), 0, math.rad(15)), Color3.fromRGB(24, 56, 45), Enum.Material.SmoothPlastic)
    -- Right arm holding alchemy ladle / gourd
    makePart(shopModel, "RightArm", Vector3.new(0.8, 1.6, 0.8), npcBase * CFrame.new(1.3, 2.2, -0.4) * CFrame.Angles(math.rad(30), 0, math.rad(-15)), Color3.fromRGB(24, 56, 45), Enum.Material.SmoothPlastic)

    -- 6. COMPACT, REFINED GUOFENG FLOATING NAMEPLATE (NOT GIANT! MAX DISTANCE 35)
    local bbg = Instance.new("BillboardGui")
    bbg.Name = "ShopLabel"
    bbg.AlwaysOnTop = false
    bbg.Size = UDim2.new(0, 160, 0, 44)
    bbg.StudsOffset = Vector3.new(0, 3.2, 0)
    bbg.MaxDistance = 35 -- disappears from far away so it NEVER clutters the map!
    bbg.Adornee = head
    bbg.Parent = shopModel

    local plaque = Instance.new("Frame")
    plaque.Name = "Plaque"
    plaque.Size = UDim2.new(1, 0, 1, 0)
    plaque.BackgroundColor3 = Color3.fromRGB(12, 22, 20)
    plaque.BackgroundTransparency = 0.15
    plaque.BorderSizePixel = 0
    plaque.Parent = bbg

    local pCorner = Instance.new("UICorner")
    pCorner.CornerRadius = UDim.new(0, 6)
    pCorner.Parent = plaque

    local pStroke = Instance.new("UIStroke")
    pStroke.Color = Color3.fromRGB(215, 180, 85)
    pStroke.Thickness = 1.2
    pStroke.Parent = plaque

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 0, 0, 3)
    titleLbl.Size = UDim2.new(1, 0, 0, 20)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = "PILL REFINING PAVILION"
    titleLbl.TextColor3 = Color3.fromRGB(255, 215, 95)
    titleLbl.TextSize = 11
    titleLbl.Parent = plaque

    local subLbl = Instance.new("TextLabel")
    subLbl.Name = "Subtitle"
    subLbl.BackgroundTransparency = 1
    subLbl.Position = UDim2.new(0, 0, 0, 22)
    subLbl.Size = UDim2.new(1, 0, 0, 18)
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.Text = "Elder Ye | Grand Alchemist"
    subLbl.TextColor3 = Color3.fromRGB(90, 225, 195)
    subLbl.TextSize = 9
    subLbl.Parent = plaque

    -- 7. CLEAN REFINED PROXIMITY PROMPT
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ShopPrompt"
    prompt.ActionText = "Trade Pills & Gear"
    prompt.ObjectText = "Pill Pavilion"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.Parent = hrp

    prompt.Triggered:Connect(function(player)
        cultivationRemote:FireClient(player, "OpenShop")
    end)

    -- Clickable counter/merchant
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = shopModel

    clickDetector.MouseClick:Connect(function(player)
        cultivationRemote:FireClient(player, "OpenShop")
    end)

    return "Successfully built unique Pill Refining Pavilion & Alchemist NPC!"
    """

    ok, res = exec_code(lua_shop)
    print("Unique Pill Shop Result:", ok, res)
    assert ok, f"Failed building unique shop: {res}"

if __name__ == '__main__':
    deploy_unique_pill_shop()

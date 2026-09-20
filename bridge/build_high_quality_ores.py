import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def build_ores():
    print("=== Constructing 5 High-Quality Xianxia Mineable Ore Models ===")

    lua_builder = """
    local ServerStorage = game:GetService("ServerStorage")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local CollectionService = game:GetService("CollectionService")

    local function getOrCreateFolder(parent, name)
        local f = parent:FindFirstChild(name)
        if not f then
            f = Instance.new("Folder")
            f.Name = name
            f.Parent = parent
        end
        return f
    end

    local ssTemplates = getOrCreateFolder(ServerStorage, "OreTemplates")
    local rsTemplates = getOrCreateFolder(ReplicatedStorage, "OreTemplates")
    local wsTemplates = getOrCreateFolder(Workspace, "OreTemplates")

    -- Clear old templates
    for _, ch in ipairs(ssTemplates:GetChildren()) do ch:Destroy() end
    for _, ch in ipairs(rsTemplates:GetChildren()) do ch:Destroy() end
    for _, ch in ipairs(wsTemplates:GetChildren()) do ch:Destroy() end

    local function makePart(parent, name, size, cf, color, mat, shape, transparency)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.CFrame = cf
        p.Color = color
        p.Material = mat or Enum.Material.Slate
        if shape then p.Shape = shape end
        if transparency then p.Transparency = transparency end
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Anchored = true
        p.CanCollide = true
        p.CastShadow = true
        p.Parent = parent
        return p
    end

    local function makeWedge(parent, name, size, cf, color, mat, transparency)
        local w = Instance.new("WedgePart")
        w.Name = name
        w.Size = size
        w.CFrame = cf
        w.Color = color
        w.Material = mat or Enum.Material.Slate
        if transparency then w.Transparency = transparency end
        w.TopSurface = Enum.SurfaceType.Smooth
        w.BottomSurface = Enum.SurfaceType.Smooth
        w.Anchored = true
        w.CanCollide = true
        w.CastShadow = true
        w.Parent = parent
        return w
    end

    local function setupOreAttributes(model, name, hits)
        model.Name = name
        model:SetAttribute("OreName", name)
        model:SetAttribute("MaxHits", hits)
        model:SetAttribute("CurrentHits", 0)
        model:SetAttribute("Mined", false)
        local cf = model:GetPivot()
        model:SetAttribute("OriginalSpawnCFrame", cf)
        model:SetAttribute("OriginalSpawnPosition", cf.Position)
        CollectionService:AddTag(model, "MineableOre")

        local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if primary then
            model.PrimaryPart = primary
            local prompt = primary:FindFirstChildOfClass("ProximityPrompt")
            if not prompt then
                prompt = Instance.new("ProximityPrompt")
                prompt.Name = "MinePrompt"
                prompt.Parent = primary
            end
            prompt.ActionText = "Mine"
            prompt.ObjectText = name
            prompt.HoldDuration = 0.5
            prompt.MaxActivationDistance = 8.5
            prompt.RequiresLineOfSight = false
            prompt.Enabled = true
        end
    end

    -- ========================================================================
    -- 1. IRON ORE (Rough dark-brown & gray boulder, raw iron veins, rust patches)
    -- ========================================================================
    local function createIronOre(rootCf)
        local model = Instance.new("Model")
        model.Name = "Iron Ore"

        local root = makePart(model, "OreRoot", Vector3.new(4.4, 0.4, 4.2), rootCf, Color3.fromRGB(65, 58, 52), Enum.Material.Slate)
        root.Transparency = 1
        root.CanCollide = false
        model.PrimaryPart = root

        -- Core boulder
        local rockDark = Color3.fromRGB(72, 66, 60)
        local rockMid = Color3.fromRGB(88, 80, 72)
        local rustCol = Color3.fromRGB(185, 95, 45)
        local ironCol = Color3.fromRGB(145, 142, 138)

        makePart(model, "CoreStone", Vector3.new(3.8, 4.6, 3.4), rootCf * CFrame.new(0, 2.3, 0), rockDark, Enum.Material.Slate)
        makePart(model, "BackPlate", Vector3.new(3.2, 4.0, 1.8), rootCf * CFrame.new(0, 2.0, 1.1) * CFrame.Angles(math.rad(10), 0, 0), rockMid, Enum.Material.Slate)
        makePart(model, "LeftFacet", Vector3.new(1.8, 3.8, 3.0), rootCf * CFrame.new(-1.3, 1.9, 0) * CFrame.Angles(0, 0, math.rad(12)), rockDark, Enum.Material.Slate)
        makePart(model, "RightFacet", Vector3.new(1.8, 3.6, 2.8), rootCf * CFrame.new(1.3, 1.8, -0.2) * CFrame.Angles(0, 0, math.rad(-14)), rockMid, Enum.Material.Slate)

        -- Angled fractures
        makeWedge(model, "TopCleft", Vector3.new(2.4, 1.6, 2.0), rootCf * CFrame.new(0.2, 4.2, -0.3) * CFrame.Angles(0, math.rad(25), 0), rockDark, Enum.Material.Slate)
        makeWedge(model, "FrontWedge", Vector3.new(2.8, 2.2, 1.5), rootCf * CFrame.new(-0.2, 1.1, -1.5) * CFrame.Angles(0, math.rad(180), 0), rockMid, Enum.Material.Slate)

        -- Raw Metallic Iron Veins cutting through front & sides
        makePart(model, "IronVein1", Vector3.new(1.6, 0.45, 0.6), rootCf * CFrame.new(-0.3, 2.8, -1.6) * CFrame.Angles(math.rad(15), math.rad(20), math.rad(-25)), ironCol, Enum.Material.Metal)
        makePart(model, "IronVein2", Vector3.new(1.4, 0.5, 0.5), rootCf * CFrame.new(0.6, 2.2, -1.5) * CFrame.Angles(math.rad(-10), math.rad(-15), math.rad(30)), ironCol, Enum.Material.Metal)
        makePart(model, "IronVein3", Vector3.new(1.8, 0.55, 0.6), rootCf * CFrame.new(-0.8, 1.5, -1.4) * CFrame.Angles(math.rad(5), 0, math.rad(-15)), ironCol, Enum.Material.Metal)
        makePart(model, "SideIron1", Vector3.new(0.6, 1.6, 0.5), rootCf * CFrame.new(1.8, 2.4, 0.2) * CFrame.Angles(math.rad(20), 0, math.rad(-10)), ironCol, Enum.Material.Metal)

        -- Oxidized Rust Patches
        makePart(model, "RustPatch1", Vector3.new(1.2, 1.1, 0.3), rootCf * CFrame.new(-0.1, 3.2, -1.65) * CFrame.Angles(math.rad(8), math.rad(5), 0), rustCol, Enum.Material.CorrodedMetal)
        makePart(model, "RustPatch2", Vector3.new(1.5, 0.9, 0.3), rootCf * CFrame.new(0.7, 1.7, -1.55) * CFrame.Angles(math.rad(-5), math.rad(-8), 0), rustCol, Enum.Material.CorrodedMetal)
        makePart(model, "RustPatch3", Vector3.new(0.9, 1.4, 0.3), rootCf * CFrame.new(-1.1, 2.2, -1.45) * CFrame.Angles(0, math.rad(12), math.rad(-10)), rustCol, Enum.Material.CorrodedMetal)
        makePart(model, "RustPatch4", Vector3.new(1.0, 0.8, 0.25), rootCf * CFrame.new(0.2, 4.0, -1.1) * CFrame.Angles(math.rad(15), 0, 0), rustCol, Enum.Material.CorrodedMetal)

        -- Base rock skirt
        makePart(model, "BaseRock1", Vector3.new(1.5, 0.7, 1.2), rootCf * CFrame.new(-1.8, 0.35, -1.1) * CFrame.Angles(0, math.rad(30), 0), rockDark, Enum.Material.Slate)
        makePart(model, "BaseRock2", Vector3.new(1.4, 0.6, 1.3), rootCf * CFrame.new(1.7, 0.3, -1.0) * CFrame.Angles(0, math.rad(-40), 0), rockMid, Enum.Material.Slate)

        setupOreAttributes(model, "Iron Ore", 3)
        return model
    end

    -- ========================================================================
    -- 2. STEEL ORE (Dense dark-gray basalt, bright silver metallic veins, sharp fracture)
    -- ========================================================================
    local function createSteelOre(rootCf)
        local model = Instance.new("Model")
        model.Name = "Steel Ore"

        local root = makePart(model, "OreRoot", Vector3.new(4.2, 0.4, 4.0), rootCf, Color3.fromRGB(42, 45, 50), Enum.Material.Basalt)
        root.Transparency = 1
        root.CanCollide = false
        model.PrimaryPart = root

        local basaltDark = Color3.fromRGB(40, 44, 48)
        local basaltMid = Color3.fromRGB(55, 60, 66)
        local silverCol = Color3.fromRGB(230, 235, 240)
        local chromeCol = Color3.fromRGB(200, 205, 215)

        -- Hard chiseled basalt core
        makePart(model, "BasaltCore", Vector3.new(3.6, 5.0, 3.2), rootCf * CFrame.new(0, 2.5, 0), basaltDark, Enum.Material.Basalt)
        makePart(model, "ShearBlock1", Vector3.new(2.8, 4.2, 1.6), rootCf * CFrame.new(0.6, 2.2, -0.9) * CFrame.Angles(math.rad(8), math.rad(15), math.rad(-5)), basaltMid, Enum.Material.Basalt)
        makePart(model, "ShearBlock2", Vector3.new(2.6, 3.8, 1.8), rootCf * CFrame.new(-0.8, 2.0, 0.8) * CFrame.Angles(math.rad(-10), math.rad(-12), math.rad(8)), basaltDark, Enum.Material.Basalt)

        -- Sharp angular fracture wedges
        makeWedge(model, "ApexWedge", Vector3.new(2.6, 1.8, 2.2), rootCf * CFrame.new(-0.2, 4.6, 0.2) * CFrame.Angles(0, math.rad(45), 0), basaltMid, Enum.Material.Basalt)
        makeWedge(model, "RightWedge", Vector3.new(1.8, 3.0, 1.8), rootCf * CFrame.new(1.5, 1.8, 0.3) * CFrame.Angles(0, math.rad(-75), math.rad(10)), basaltDark, Enum.Material.Basalt)
        makeWedge(model, "FrontCleft", Vector3.new(1.6, 2.4, 1.4), rootCf * CFrame.new(-1.1, 1.4, -1.2) * CFrame.Angles(0, math.rad(135), 0), basaltMid, Enum.Material.Basalt)

        -- Polished Bright Silver Metallic Veins cutting diagonally across fracture planes
        makePart(model, "SilverVein1", Vector3.new(2.4, 0.35, 0.5), rootCf * CFrame.new(0.2, 3.4, -1.35) * CFrame.Angles(math.rad(15), math.rad(25), math.rad(-35)), silverCol, Enum.Material.Metal)
        makePart(model, "SilverVein2", Vector3.new(2.2, 0.3, 0.45), rootCf * CFrame.new(-0.4, 2.2, -1.4) * CFrame.Angles(math.rad(10), math.rad(-20), math.rad(40)), chromeCol, Enum.Material.Metal)
        makePart(model, "SilverVein3", Vector3.new(2.8, 0.4, 0.5), rootCf * CFrame.new(0.4, 1.5, -1.25) * CFrame.Angles(math.rad(-5), math.rad(15), math.rad(-25)), silverCol, Enum.Material.Metal)
        makePart(model, "CrossVein", Vector3.new(0.4, 2.2, 0.4), rootCf * CFrame.new(0.8, 2.6, -1.3) * CFrame.Angles(math.rad(12), 0, math.rad(25)), chromeCol, Enum.Material.Metal)
        makePart(model, "SideSilver", Vector3.new(0.5, 1.8, 1.6), rootCf * CFrame.new(-1.7, 2.6, 0.1) * CFrame.Angles(0, 0, math.rad(15)), silverCol, Enum.Material.Metal)

        -- Dense rock skirt
        makePart(model, "BaseRock1", Vector3.new(1.6, 0.8, 1.4), rootCf * CFrame.new(-1.6, 0.4, -1.2), basaltDark, Enum.Material.Basalt)
        makePart(model, "BaseRock2", Vector3.new(1.8, 0.7, 1.3), rootCf * CFrame.new(1.5, 0.35, -1.1) * CFrame.Angles(0, math.rad(30), 0), basaltMid, Enum.Material.Basalt)

        setupOreAttributes(model, "Steel Ore", 5)
        return model
    end

    -- ========================================================================
    -- 3. SPIRIT STONE (Dark bedrock, glowing cyan crystalline cluster, spiritual Qi aura)
    -- ========================================================================
    local function createSpiritStone(rootCf)
        local model = Instance.new("Model")
        model.Name = "Spirit Stone"

        local root = makePart(model, "OreRoot", Vector3.new(4.4, 0.4, 4.2), rootCf, Color3.fromRGB(30, 36, 44), Enum.Material.Slate)
        root.Transparency = 1
        root.CanCollide = false
        model.PrimaryPart = root

        local rockDark = Color3.fromRGB(32, 38, 44)
        local rockRim = Color3.fromRGB(45, 52, 60)
        local crystalCyan = Color3.fromRGB(80, 235, 255)
        local crystalCore = Color3.fromRGB(150, 250, 255)
        local deepCyan = Color3.fromRGB(35, 175, 215)

        -- Cradle bedrock boulder
        makePart(model, "RockBack", Vector3.new(3.8, 5.2, 2.4), rootCf * CFrame.new(0, 2.5, 0.9), rockDark, Enum.Material.Slate)
        makePart(model, "RockLeftCradle", Vector3.new(1.8, 4.2, 2.6), rootCf * CFrame.new(-1.4, 2.1, -0.2) * CFrame.Angles(0, 0, math.rad(10)), rockRim, Enum.Material.Slate)
        makePart(model, "RockRightCradle", Vector3.new(1.8, 4.0, 2.6), rootCf * CFrame.new(1.4, 2.0, -0.2) * CFrame.Angles(0, 0, math.rad(-10)), rockDark, Enum.Material.Slate)
        makeWedge(model, "TopRockCap", Vector3.new(2.4, 1.5, 1.8), rootCf * CFrame.new(0, 4.6, 0.5) * CFrame.Angles(0, math.rad(180), 0), rockDark, Enum.Material.Slate)

        -- Central Giant Spiritual Crystal Spires (Hexagonal / faceted clusters jutting forward)
        -- Tall center spire
        local c1 = makePart(model, "SpireCenter", Vector3.new(1.1, 3.2, 1.1), rootCf * CFrame.new(0, 3.2, -0.8) * CFrame.Angles(math.rad(-12), 0, math.rad(5)), crystalCyan, Enum.Material.Glass, nil, 0.15)
        makeWedge(model, "TipCenter", Vector3.new(1.1, 0.9, 1.1), c1.CFrame * CFrame.new(0, 2.0, 0) * CFrame.Angles(0, math.rad(45), 0), crystalCyan, Enum.Material.Glass, 0.15)
        
        -- Left upper spire
        local c2 = makePart(model, "SpireLeftUp", Vector3.new(0.85, 2.4, 0.85), rootCf * CFrame.new(-0.85, 3.4, -0.6) * CFrame.Angles(math.rad(-18), math.rad(-25), math.rad(-20)), deepCyan, Enum.Material.Glass, nil, 0.2)
        makeWedge(model, "TipLeftUp", Vector3.new(0.85, 0.75, 0.85), c2.CFrame * CFrame.new(0, 1.55, 0) * CFrame.Angles(0, math.rad(30), 0), deepCyan, Enum.Material.Glass, 0.2)

        -- Right upper spire
        local c3 = makePart(model, "SpireRightUp", Vector3.new(0.9, 2.6, 0.9), rootCf * CFrame.new(0.9, 3.3, -0.6) * CFrame.Angles(math.rad(-15), math.rad(25), math.rad(22)), deepCyan, Enum.Material.Glass, nil, 0.2)
        makeWedge(model, "TipRightUp", Vector3.new(0.9, 0.8, 0.9), c3.CFrame * CFrame.new(0, 1.7, 0) * CFrame.Angles(0, math.rad(-30), 0), deepCyan, Enum.Material.Glass, 0.2)

        -- Lower forward clusters
        local c4 = makePart(model, "SpireLowFront", Vector3.new(1.0, 2.2, 1.0), rootCf * CFrame.new(0.1, 1.8, -1.3) * CFrame.Angles(math.rad(20), 0, math.rad(-8)), crystalCyan, Enum.Material.Glass, nil, 0.15)
        makeWedge(model, "TipLowFront", Vector3.new(1.0, 0.8, 1.0), c4.CFrame * CFrame.new(0, 1.45, 0) * CFrame.Angles(0, math.rad(45), 0), crystalCyan, Enum.Material.Glass, 0.15)

        local c5 = makePart(model, "SpireLowLeft", Vector3.new(0.75, 1.8, 0.75), rootCf * CFrame.new(-0.9, 1.6, -1.1) * CFrame.Angles(math.rad(15), math.rad(-20), math.rad(-25)), deepCyan, Enum.Material.Glass, nil, 0.2)
        local c6 = makePart(model, "SpireLowRight", Vector3.new(0.8, 1.9, 0.8), rootCf * CFrame.new(1.0, 1.5, -1.0) * CFrame.Angles(math.rad(10), math.rad(20), math.rad(28)), deepCyan, Enum.Material.Glass, nil, 0.2)

        -- Inner Luminous Core (Glowing Qi reservoir inside the cluster)
        local core = makePart(model, "LuminousCore", Vector3.new(0.7, 2.0, 0.7), rootCf * CFrame.new(0, 2.5, -0.6), crystalCore, Enum.Material.Neon, nil, 0.1)
        core.CanCollide = false

        -- Spiritual Light
        local light = Instance.new("PointLight")
        light.Name = "QiLight"
        light.Color = Color3.fromRGB(70, 235, 255)
        light.Range = 14
        light.Brightness = 1.6
        light.Parent = core

        -- Subtle Qi Particle Auras
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "QiSparkles"
        emitter.LightEmission = 1
        emitter.LightInfluence = 0
        emitter.Rate = 6
        emitter.Lifetime = NumberRange.new(1.2, 2.2)
        emitter.Speed = NumberRange.new(0.4, 1.2)
        emitter.SpreadAngle = Vector2.new(45, 45)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.5, 0.35),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 245, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 180, 220)),
        })
        emitter.Parent = core

        setupOreAttributes(model, "Spirit Stone", 6)
        return model
    end

    -- ========================================================================
    -- 4. JADE CRYSTAL (Moist cavern stone, emerald-green crystalline formations, oily luster)
    -- ========================================================================
    local function createJadeCrystal(rootCf)
        local model = Instance.new("Model")
        model.Name = "Jade Crystal"

        local root = makePart(model, "OreRoot", Vector3.new(4.2, 0.4, 4.0), rootCf, Color3.fromRGB(42, 46, 42), Enum.Material.Slate)
        root.Transparency = 1
        root.CanCollide = false
        model.PrimaryPart = root

        local rockDark = Color3.fromRGB(45, 49, 44)
        local rockMoss = Color3.fromRGB(52, 58, 50)
        local jadeVivid = Color3.fromRGB(40, 205, 115)
        local jadeDeep = Color3.fromRGB(24, 155, 80)
        local jadeLight = Color3.fromRGB(75, 235, 145)

        -- Cavern Rock matrix
        makePart(model, "MatrixCore", Vector3.new(3.8, 5.0, 3.2), rootCf * CFrame.new(0, 2.5, 0), rockDark, Enum.Material.Slate)
        makePart(model, "MossCollar", Vector3.new(3.4, 3.8, 1.8), rootCf * CFrame.new(0, 2.1, 0.9) * CFrame.Angles(math.rad(8), 0, 0), rockMoss, Enum.Material.Slate)
        makePart(model, "LeftShear", Vector3.new(1.8, 3.6, 2.8), rootCf * CFrame.new(-1.3, 1.9, -0.1) * CFrame.Angles(0, 0, math.rad(12)), rockDark, Enum.Material.Slate)
        makePart(model, "RightShear", Vector3.new(1.8, 3.4, 2.6), rootCf * CFrame.new(1.3, 1.8, -0.2) * CFrame.Angles(0, 0, math.rad(-14)), rockMoss, Enum.Material.Slate)

        -- Emerald-Green Crystalline Formations (Hexagonal / angled elongated jade prisms growing naturally)
        -- Upper Cluster
        local j1 = makePart(model, "JadePrism1", Vector3.new(0.85, 2.8, 0.85), rootCf * CFrame.new(0.7, 3.6, -0.9) * CFrame.Angles(math.rad(-15), math.rad(25), math.rad(18)), jadeVivid, Enum.Material.Glass, nil, 0.15)
        makeWedge(model, "JadeTip1", Vector3.new(0.85, 0.8, 0.85), j1.CFrame * CFrame.new(0, 1.8, 0) * CFrame.Angles(0, math.rad(45), 0), jadeLight, Enum.Material.Glass, 0.15)

        local j2 = makePart(model, "JadePrism2", Vector3.new(0.7, 2.2, 0.7), rootCf * CFrame.new(1.2, 3.2, -0.7) * CFrame.Angles(math.rad(-10), math.rad(40), math.rad(28)), jadeDeep, Enum.Material.Glass, nil, 0.2)
        local j3 = makePart(model, "JadePrism3", Vector3.new(0.65, 1.8, 0.65), rootCf * CFrame.new(0.3, 4.0, -0.6) * CFrame.Angles(math.rad(-22), math.rad(10), math.rad(5)), jadeLight, Enum.Material.Glass, nil, 0.15)

        -- Lower Primary Cluster
        local j4 = makePart(model, "JadeMain", Vector3.new(1.0, 3.0, 1.0), rootCf * CFrame.new(-0.6, 2.0, -1.2) * CFrame.Angles(math.rad(12), math.rad(-15), math.rad(-22)), jadeVivid, Enum.Material.Glass, nil, 0.15)
        makeWedge(model, "JadeMainTip", Vector3.new(1.0, 0.85, 1.0), j4.CFrame * CFrame.new(0, 1.9, 0) * CFrame.Angles(0, math.rad(45), 0), jadeLight, Enum.Material.Glass, 0.15)

        local j5 = makePart(model, "JadeSatellite1", Vector3.new(0.75, 2.0, 0.75), rootCf * CFrame.new(-1.1, 1.6, -1.0) * CFrame.Angles(math.rad(18), math.rad(-30), math.rad(-35)), jadeDeep, Enum.Material.Glass, nil, 0.2)
        local j6 = makePart(model, "JadeSatellite2", Vector3.new(0.7, 1.7, 0.7), rootCf * CFrame.new(-0.2, 1.5, -1.4) * CFrame.Angles(math.rad(25), math.rad(10), math.rad(-10)), jadeVivid, Enum.Material.Glass, nil, 0.15)
        local j7 = makePart(model, "JadeSatellite3", Vector3.new(0.6, 1.4, 0.6), rootCf * CFrame.new(-0.9, 2.6, -1.0) * CFrame.Angles(math.rad(8), math.rad(-10), math.rad(-15)), jadeLight, Enum.Material.Glass, nil, 0.15)

        -- Soft jade light
        local jLight = Instance.new("PointLight")
        jLight.Name = "JadeAura"
        jLight.Color = Color3.fromRGB(45, 225, 115)
        jLight.Range = 9
        jLight.Brightness = 0.9
        jLight.Parent = j4

        setupOreAttributes(model, "Jade Crystal", 7)
        return model
    end

    -- ========================================================================
    -- 5. BLACK IRON (Pitch-black monolithic obsidian boulder, reflective metallic seams)
    -- ========================================================================
    local function createBlackIron(rootCf)
        local model = Instance.new("Model")
        model.Name = "Black Iron"

        local root = makePart(model, "OreRoot", Vector3.new(4.4, 0.4, 4.2), rootCf, Color3.fromRGB(18, 19, 22), Enum.Material.Basalt)
        root.Transparency = 1
        root.CanCollide = false
        model.PrimaryPart = root

        local blackBasalt = Color3.fromRGB(18, 20, 24)
        local deepCharcoal = Color3.fromRGB(28, 30, 36)
        local gunmetalSpecular = Color3.fromRGB(90, 95, 105)
        local darkIronPlate = Color3.fromRGB(65, 70, 80)

        -- Heavy Monolithic Volcanic Rock Core
        makePart(model, "ObsidianMonolith", Vector3.new(4.0, 5.4, 3.6), rootCf * CFrame.new(0, 2.7, 0), blackBasalt, Enum.Material.Basalt)
        makePart(model, "RearWeight", Vector3.new(3.6, 4.6, 2.0), rootCf * CFrame.new(0, 2.3, 1.1) * CFrame.Angles(math.rad(8), 0, 0), deepCharcoal, Enum.Material.Basalt)
        makePart(model, "LeftBastion", Vector3.new(2.0, 4.4, 3.2), rootCf * CFrame.new(-1.4, 2.2, 0) * CFrame.Angles(0, 0, math.rad(10)), blackBasalt, Enum.Material.Basalt)
        makePart(model, "RightBastion", Vector3.new(2.0, 4.2, 3.0), rootCf * CFrame.new(1.4, 2.1, -0.1) * CFrame.Angles(0, 0, math.rad(-12)), deepCharcoal, Enum.Material.Basalt)

        -- Sharp angular cap
        makeWedge(model, "ObsidianCrown", Vector3.new(2.8, 1.8, 2.4), rootCf * CFrame.new(0.2, 4.8, -0.2) * CFrame.Angles(0, math.rad(30), 0), blackBasalt, Enum.Material.Basalt)

        -- Reflective Gunmetal Metallic Seams & Polished Ribbons
        makePart(model, "MirrorSeam1", Vector3.new(2.6, 0.45, 0.5), rootCf * CFrame.new(0.1, 3.6, -1.5) * CFrame.Angles(math.rad(12), math.rad(20), math.rad(-28)), gunmetalSpecular, Enum.Material.Metal)
        makePart(model, "MirrorSeam2", Vector3.new(2.4, 0.4, 0.45), rootCf * CFrame.new(-0.3, 2.4, -1.55) * CFrame.Angles(math.rad(15), math.rad(-15), math.rad(35)), darkIronPlate, Enum.Material.Metal)
        makePart(model, "MirrorSeam3", Vector3.new(2.8, 0.5, 0.55), rootCf * CFrame.new(0.3, 1.4, -1.45) * CFrame.Angles(math.rad(-8), math.rad(10), math.rad(-20)), gunmetalSpecular, Enum.Material.Metal)
        makePart(model, "VerticalCrevice", Vector3.new(0.5, 2.4, 0.45), rootCf * CFrame.new(-0.9, 2.8, -1.4) * CFrame.Angles(math.rad(10), 0, math.rad(-15)), darkIronPlate, Enum.Material.Metal)
        makePart(model, "SideSpecularSeam", Vector3.new(0.55, 2.2, 1.8), rootCf * CFrame.new(1.8, 2.5, 0.2) * CFrame.Angles(0, 0, math.rad(-15)), gunmetalSpecular, Enum.Material.Metal)

        -- Dense heavy footing
        makePart(model, "BaseCollar1", Vector3.new(1.8, 0.9, 1.5), rootCf * CFrame.new(-1.8, 0.45, -1.3) * CFrame.Angles(0, math.rad(25), 0), blackBasalt, Enum.Material.Basalt)
        makePart(model, "BaseCollar2", Vector3.new(1.9, 0.8, 1.4), rootCf * CFrame.new(1.7, 0.4, -1.2) * CFrame.Angles(0, math.rad(-35), 0), deepCharcoal, Enum.Material.Basalt)

        setupOreAttributes(model, "Black Iron", 8)
        return model
    end

    -- ========================================================================
    -- INSTANTIATE AND DEPLOY MASTER TEMPLATES
    -- ========================================================================
    local builders = {
        ["Iron Ore"] = createIronOre,
        ["Steel Ore"] = createSteelOre,
        ["Spirit Stone"] = createSpiritStone,
        ["Jade Crystal"] = createJadeCrystal,
        ["Black Iron"] = createBlackIron,
    }

    local order = { "Iron Ore", "Steel Ore", "Spirit Stone", "Jade Crystal", "Black Iron" }
    local spacing = 9.0
    local startX = -((#order - 1) * spacing) / 2
    local showcaseY = 2.0
    local showcaseZ = -14.0

    for i, name in ipairs(order) do
        local builder = builders[name]
        
        -- 1. ServerStorage template
        local ssModel = builder(CFrame.new(0, 0, 0))
        ssModel.Parent = ssTemplates

        -- 2. ReplicatedStorage template
        local rsModel = ssModel:Clone()
        rsModel.Parent = rsTemplates

        -- 3. Workspace showcase preview row (cleanly spaced for inspection/mining)
        local posX = startX + (i - 1) * spacing
        local wsModel = ssModel:Clone()
        wsModel:PivotTo(CFrame.new(posX, showcaseY, showcaseZ))
        wsModel:SetAttribute("OriginalSpawnCFrame", wsModel:GetPivot())
        wsModel:SetAttribute("OriginalSpawnPosition", wsModel:GetPivot().Position)
        wsModel.Parent = wsTemplates
    end

    return "Successfully constructed all 5 high-quality mineable ore models!"
    """

    ok, res = exec_code(lua_builder)
    print("Ore Builder Result:", ok, res)
    assert ok, f"Failed building ores: {res}"

if __name__ == '__main__':
    build_ores()

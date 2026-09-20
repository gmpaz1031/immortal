import sys
import os
from pathlib import Path
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy_all():
    print("=== Deploying Plant Gathering System ===")

    # 1. Read files
    plant_config = Path("src/shared/PlantConfig.luau").read_text(encoding="utf-8")
    item_config = Path("src/shared/ItemConfig.luau").read_text(encoding="utf-8")
    data_server = Path("src/server/DATA.server.luau").read_text(encoding="utf-8")
    client_src = Path("src/gui/CultivationClient.client.luau").read_text(encoding="utf-8")
    harvest_service = Path("src/server/PlantHarvestService.server.luau").read_text(encoding="utf-8")

    # 2. Inject PlantConfig & ItemConfig into ReplicatedStorage.Shared
    print("1. Injecting Shared modules...")
    lua_shared = f"""
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Shared = ReplicatedStorage:WaitForChild("Shared")

    local pc = Shared:FindFirstChild("PlantConfig")
    if not pc then
        pc = Instance.new("ModuleScript")
        pc.Name = "PlantConfig"
        pc.Parent = Shared
    end
    pc.Source = [====[{plant_config}]====]

    local ic = Shared:FindFirstChild("ItemConfig")
    if not ic then
        ic = Instance.new("ModuleScript")
        ic.Name = "ItemConfig"
        ic.Parent = Shared
    end
    ic.Source = [====[{item_config}]====]

    return "Injected PlantConfig & ItemConfig into ReplicatedStorage.Shared"
    """
    ok, res = exec_code(lua_shared)
    print("Shared modules:", ok, res)
    assert ok, f"Failed shared: {res}"

    # 3. Update DATA.server and CultivationClient
    print("2. Updating DATA and CultivationClient...")
    lua_scripts = f"""
    local SSS = game:GetService("ServerScriptService"):WaitForChild("Server")
    local dataScript = SSS:WaitForChild("DATA")
    dataScript.Source = [====[{data_server}]====]

    local StarterGui = game:GetService("StarterGui")
    local cultUI = StarterGui:WaitForChild("CultivationUI")
    local clientScript = cultUI:WaitForChild("CultivationClient")
    clientScript.Source = [====[{client_src}]====]

    local phs = SSS:FindFirstChild("PlantHarvestService")
    if not phs then
        phs = Instance.new("Script")
        phs.Name = "PlantHarvestService"
        phs.Parent = SSS
    end
    phs.Source = [====[{harvest_service}]====]

    return "Updated DATA, CultivationClient, and PlantHarvestService"
    """
    ok, res = exec_code(lua_scripts)
    print("Scripts update:", ok, res)
    assert ok, f"Failed scripts: {res}"

    # 4. Construct all 11 distinct 3D plant models
    print("3. Generating 11 distinct 3D plant models...")
    lua_models = """
    local ServerStorage = game:GetService("ServerStorage")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")

    local function getOrCreateFolder(parent, name)
        local f = parent:FindFirstChild(name)
        if not f then
            f = Instance.new("Folder")
            f.Name = name
            f.Parent = parent
        end
        return f
    end

    local ssTemplates = getOrCreateFolder(ServerStorage, "PlantTemplates")
    local rsTemplates = getOrCreateFolder(ReplicatedStorage, "PlantTemplates")
    local wsTemplates = getOrCreateFolder(Workspace, "PlantTemplates")

    -- Clean old templates
    for _, ch in ipairs(ssTemplates:GetChildren()) do ch:Destroy() end
    for _, ch in ipairs(rsTemplates:GetChildren()) do ch:Destroy() end
    for _, ch in ipairs(wsTemplates:GetChildren()) do ch:Destroy() end

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

    local function makeStemWedge(parent, name, size, cf, color, mat)
        local w = Instance.new("WedgePart")
        w.Name = name
        w.Size = size
        w.CFrame = cf
        w.Color = color
        w.Material = mat or Enum.Material.SmoothPlastic
        w.TopSurface = Enum.SurfaceType.Smooth
        w.BottomSurface = Enum.SurfaceType.Smooth
        w.Anchored = true
        w.CanCollide = false
        w.CastShadow = false
        w.Parent = parent
        return w
    end

    local builders = {}

    -- 1. Spirit Grass (Slender arching emerald grass blades with glowing jade tips)
    builders["Spirit Grass"] = function()
        local m = Instance.new("Model")
        m.Name = "Spirit Grass"
        local root = makePart(m, "PlantRoot", Vector3.new(1.2, 0.4, 1.2), CFrame.new(0, 0.2, 0), Color3.fromRGB(45, 90, 45), Enum.Material.Grass, Enum.PartType.Cylinder)
        root.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
        root.Transparency = 1
        m.PrimaryPart = root

        local base = makePart(m, "TuftBase", Vector3.new(0.6, 0.2, 0.6), CFrame.new(0, 0.1, 0), Color3.fromRGB(40, 85, 40), Enum.Material.Grass, Enum.PartType.Cylinder)
        base.CFrame = base.CFrame * CFrame.Angles(0, 0, math.rad(90))

        -- 5 blades of grass in radial pattern
        for i = 1, 5 do
            local angle = math.rad((i - 1) * 72)
            local tilt = math.rad(18)
            local cf = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.7, 0.2) * CFrame.Angles(tilt, 0, 0)
            makeStemWedge(m, "BladeLower", Vector3.new(0.25, 1.4, 0.08), cf, Color3.fromRGB(60, 185, 95), Enum.Material.SmoothPlastic)
            local tipCf = cf * CFrame.new(0, 0.8, 0.04) * CFrame.Angles(math.rad(15), 0, 0)
            local tip = makePart(m, "BladeTip", Vector3.new(0.18, 0.6, 0.06), tipCf, Color3.fromRGB(150, 255, 180), Enum.Material.Neon)
        end
        return m
    end

    -- 2. Ginseng Herb (Pale root, dark green leaves, cluster of red berries)
    builders["Ginseng Herb"] = function()
        local m = Instance.new("Model")
        m.Name = "Ginseng Herb"
        local root = makePart(m, "PlantRoot", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), Color3.fromRGB(180, 145, 95), Enum.Material.Wood)
        root.Transparency = 1
        m.PrimaryPart = root

        -- Visible taproot protruding
        makePart(m, "TapRootMain", Vector3.new(0.35, 0.7, 0.35), CFrame.new(0, 0.3, 0), Color3.fromRGB(205, 170, 115), Enum.Material.Wood, Enum.PartType.Cylinder)
        makePart(m, "TapRootForkL", Vector3.new(0.2, 0.5, 0.2), CFrame.new(-0.15, 0.18, 0) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(195, 160, 105), Enum.Material.Wood, Enum.PartType.Cylinder)
        makePart(m, "TapRootForkR", Vector3.new(0.18, 0.45, 0.18), CFrame.new(0.14, 0.15, 0.08) * CFrame.Angles(0, 0, math.rad(-20)), Color3.fromRGB(195, 160, 105), Enum.Material.Wood, Enum.PartType.Cylinder)

        -- Central stem
        makePart(m, "Stem", Vector3.new(0.1, 0.9, 0.1), CFrame.new(0, 0.9, 0), Color3.fromRGB(55, 120, 55), Enum.Material.SmoothPlastic)

        -- 3 leaf branches
        for i = 1, 3 do
            local angle = math.rad((i - 1) * 120)
            local lCf = CFrame.new(0, 1.1, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.1, 0.35) * CFrame.Angles(math.rad(15), 0, 0)
            makePart(m, "Leaf", Vector3.new(0.4, 0.06, 0.6), lCf, Color3.fromRGB(45, 140, 55), Enum.Material.SmoothPlastic)
        end

        -- Red ginseng berry cluster on top
        local berryCenter = CFrame.new(0, 1.4, 0)
        makePart(m, "BerryCore", Vector3.new(0.18, 0.18, 0.18), berryCenter, Color3.fromRGB(225, 30, 30), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
        for b = 1, 4 do
            local bCf = berryCenter * CFrame.Angles(0, math.rad(b * 90), 0) * CFrame.new(0.1, 0.05, 0)
            makePart(m, "Berry", Vector3.new(0.14, 0.14, 0.14), bCf, Color3.fromRGB(235, 45, 45), Enum.Material.Neon, Enum.PartType.Ball)
        end
        return m
    end

    -- 3. Ironleaf Herb (Rigid metallic-sheen lanceolate blade rosette)
    builders["Ironleaf Herb"] = function()
        local m = Instance.new("Model")
        m.Name = "Ironleaf Herb"
        local root = makePart(m, "PlantRoot", Vector3.new(1.2, 0.5, 1.2), CFrame.new(0, 0.25, 0), Color3.fromRGB(70, 80, 90), Enum.Material.Metal)
        root.Transparency = 1
        m.PrimaryPart = root

        makePart(m, "MetalCenter", Vector3.new(0.4, 0.25, 0.4), CFrame.new(0, 0.12, 0), Color3.fromRGB(50, 60, 70), Enum.Material.Metal, Enum.PartType.Cylinder)

        -- 6 sharp metallic blades
        for i = 1, 6 do
            local angle = math.rad((i - 1) * 60)
            local cf = CFrame.new(0, 0.15, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.4, 0.4) * CFrame.Angles(math.rad(30), 0, 0)
            makePart(m, "Blade", Vector3.new(0.28, 0.9, 0.06), cf, Color3.fromRGB(120, 135, 150), Enum.Material.Metal)
            local edge = makePart(m, "BladeEdge", Vector3.new(0.06, 0.9, 0.08), cf * CFrame.new(0, 0, 0.02), Color3.fromRGB(190, 210, 225), Enum.Material.Neon)
        end
        return m
    end

    -- 4. Moonlight Grass (Pale silver curved blades with soft lunar blue glow)
    builders["Moonlight Grass"] = function()
        local m = Instance.new("Model")
        m.Name = "Moonlight Grass"
        local root = makePart(m, "PlantRoot", Vector3.new(1.2, 0.4, 1.2), CFrame.new(0, 0.2, 0), Color3.fromRGB(180, 205, 230), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        for i = 1, 6 do
            local angle = math.rad((i - 1) * 60 + 15)
            local tilt = math.rad(22)
            local cf = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.75, 0.25) * CFrame.Angles(tilt, 0, 0)
            makeStemWedge(m, "MoonBlade", Vector3.new(0.24, 1.5, 0.06), cf, Color3.fromRGB(210, 225, 245), Enum.Material.SmoothPlastic)
            local tipCf = cf * CFrame.new(0, 0.85, 0.04) * CFrame.Angles(math.rad(20), 0, 0)
            local tip = makePart(m, "MoonGlow", Vector3.new(0.16, 0.6, 0.06), tipCf, Color3.fromRGB(165, 205, 255), Enum.Material.Neon)
        end
        return m
    end

    -- 5. Clearheart Flower (Pure white 5-petal flower with golden stamen core)
    builders["Clearheart Flower"] = function()
        local m = Instance.new("Model")
        m.Name = "Clearheart Flower"
        local root = makePart(m, "PlantRoot", Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        -- Slender stem
        makePart(m, "Stem", Vector3.new(0.1, 0.9, 0.1), CFrame.new(0, 0.45, 0), Color3.fromRGB(60, 150, 75), Enum.Material.SmoothPlastic)

        -- 2 small stem leaves
        makePart(m, "StemLeaf1", Vector3.new(0.25, 0.05, 0.4), CFrame.new(0.18, 0.4, 0) * CFrame.Angles(0, 0, math.rad(-25)), Color3.fromRGB(50, 135, 65), Enum.Material.SmoothPlastic)
        makePart(m, "StemLeaf2", Vector3.new(0.25, 0.05, 0.4), CFrame.new(-0.18, 0.55, 0) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(50, 135, 65), Enum.Material.SmoothPlastic)

        -- 5 white blossom petals
        local headCf = CFrame.new(0, 0.95, 0)
        for i = 1, 5 do
            local angle = math.rad((i - 1) * 72)
            local pCf = headCf * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.08, 0.32) * CFrame.Angles(math.rad(18), 0, 0)
            makePart(m, "Petal", Vector3.new(0.32, 0.06, 0.5), pCf, Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic)
        end

        -- Golden central stamen
        makePart(m, "Stamen", Vector3.new(0.26, 0.16, 0.26), headCf * CFrame.new(0, 0.1, 0), Color3.fromRGB(255, 215, 65), Enum.Material.Neon, Enum.PartType.Cylinder)
        return m
    end

    -- 6. Bloodroot (Crimson root nodules with dark wine-red spade foliage)
    builders["Bloodroot"] = function()
        local m = Instance.new("Model")
        m.Name = "Bloodroot"
        local root = makePart(m, "PlantRoot", Vector3.new(1.2, 0.6, 1.2), CFrame.new(0, 0.3, 0), Color3.fromRGB(140, 20, 30), Enum.Material.Slate)
        root.Transparency = 1
        m.PrimaryPart = root

        -- Gnarled crimson root nodules
        makePart(m, "RootNodule1", Vector3.new(0.5, 0.4, 0.5), CFrame.new(0, 0.2, 0), Color3.fromRGB(160, 25, 35), Enum.Material.Slate, Enum.PartType.Ball)
        makePart(m, "RootNodule2", Vector3.new(0.35, 0.3, 0.35), CFrame.new(0.2, 0.15, -0.1), Color3.fromRGB(135, 18, 25), Enum.Material.Slate, Enum.PartType.Ball)
        makePart(m, "RootNodule3", Vector3.new(0.38, 0.32, 0.38), CFrame.new(-0.18, 0.16, 0.15), Color3.fromRGB(145, 20, 30), Enum.Material.Slate, Enum.PartType.Ball)

        -- 4 wine-red spade leaves
        for i = 1, 4 do
            local angle = math.rad((i - 1) * 90 + 20)
            local cf = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.35, 0.38) * CFrame.Angles(math.rad(28), 0, 0)
            makePart(m, "BloodLeaf", Vector3.new(0.36, 0.08, 0.65), cf, Color3.fromRGB(125, 15, 25), Enum.Material.SmoothPlastic)
            local rib = makePart(m, "BloodRib", Vector3.new(0.08, 0.1, 0.6), cf * CFrame.new(0, 0.02, 0), Color3.fromRGB(220, 35, 50), Enum.Material.Neon)
        end
        return m
    end

    -- 7. Jade Lotus (Translucent jade open lotus bowl with lilypad base)
    builders["Jade Lotus"] = function()
        local m = Instance.new("Model")
        m.Name = "Jade Lotus"
        local root = makePart(m, "PlantRoot", Vector3.new(1.8, 0.4, 1.8), CFrame.new(0, 0.1, 0), Color3.fromRGB(50, 170, 110), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        -- Lily pad base
        local pad = makePart(m, "LilyPad", Vector3.new(1.8, 0.08, 1.8), CFrame.new(0, 0.04, 0), Color3.fromRGB(40, 135, 75), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
        pad.CFrame = pad.CFrame * CFrame.Angles(0, 0, math.rad(90))

        -- Outer 6 jade petals
        local centerCf = CFrame.new(0, 0.15, 0)
        for i = 1, 6 do
            local angle = math.rad((i - 1) * 60)
            local pCf = centerCf * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.16, 0.42) * CFrame.Angles(math.rad(32), 0, 0)
            makePart(m, "OuterPetal", Vector3.new(0.38, 0.08, 0.55), pCf, Color3.fromRGB(95, 215, 160), Enum.Material.Glass)
        end

        -- Inner 6 jade petals (more upright)
        for i = 1, 6 do
            local angle = math.rad((i - 1) * 60 + 30)
            local pCf = centerCf * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.22, 0.25) * CFrame.Angles(math.rad(45), 0, 0)
            makePart(m, "InnerPetal", Vector3.new(0.3, 0.07, 0.45), pCf, Color3.fromRGB(120, 235, 185), Enum.Material.Glass)
        end

        -- Golden seed pod core
        local pod = makePart(m, "SeedPod", Vector3.new(0.35, 0.2, 0.35), centerCf * CFrame.new(0, 0.15, 0), Color3.fromRGB(245, 215, 80), Enum.Material.Neon, Enum.PartType.Cylinder)
        return m
    end

    -- 8. Hundred-Year Ginseng (Grand ancient ginseng with complex roots and red pearls)
    builders["Hundred-Year Ginseng"] = function()
        local m = Instance.new("Model")
        m.Name = "Hundred-Year Ginseng"
        local root = makePart(m, "PlantRoot", Vector3.new(1.6, 1.4, 1.6), CFrame.new(0, 0.7, 0), Color3.fromRGB(210, 165, 95), Enum.Material.Wood)
        root.Transparency = 1
        m.PrimaryPart = root

        -- Gnarled ancient torso root
        makePart(m, "AncientRootBody", Vector3.new(0.55, 1.0, 0.5), CFrame.new(0, 0.5, 0), Color3.fromRGB(225, 180, 105), Enum.Material.Wood, Enum.PartType.Cylinder)
        makePart(m, "LegRootL", Vector3.new(0.28, 0.7, 0.28), CFrame.new(-0.25, 0.25, 0.08) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(210, 165, 95), Enum.Material.Wood, Enum.PartType.Cylinder)
        makePart(m, "LegRootR", Vector3.new(0.26, 0.65, 0.26), CFrame.new(0.24, 0.22, -0.06) * CFrame.Angles(0, 0, math.rad(-22)), Color3.fromRGB(210, 165, 95), Enum.Material.Wood, Enum.PartType.Cylinder)
        makePart(m, "ArmRootF", Vector3.new(0.2, 0.5, 0.2), CFrame.new(0, 0.55, 0.22) * CFrame.Angles(math.rad(30), 0, 0), Color3.fromRGB(200, 155, 90), Enum.Material.Wood, Enum.PartType.Cylinder)

        -- Central stalk
        makePart(m, "Stalk", Vector3.new(0.14, 1.1, 0.14), CFrame.new(0, 1.25, 0), Color3.fromRGB(60, 135, 60), Enum.Material.SmoothPlastic)

        -- Dual foliage tiers
        for tier = 1, 2 do
            local yOff = 1.2 + (tier * 0.3)
            local count = 4
            for i = 1, count do
                local angle = math.rad((i - 1) * (360 / count) + (tier * 45))
                local lCf = CFrame.new(0, yOff, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.1, 0.45) * CFrame.Angles(math.rad(20), 0, 0)
                makePart(m, "CrownLeaf", Vector3.new(0.42, 0.08, 0.68), lCf, Color3.fromRGB(40, 145, 55), Enum.Material.SmoothPlastic)
            end
        end

        -- Crimson spiritual pearls
        local crownTop = CFrame.new(0, 1.9, 0)
        for p = 1, 6 do
            local pCf = crownTop * CFrame.Angles(0, math.rad(p * 60), 0) * CFrame.new(0.14, 0.08, 0)
            makePart(m, "Pearl", Vector3.new(0.18, 0.18, 0.18), pCf, Color3.fromRGB(245, 45, 45), Enum.Material.Neon, Enum.PartType.Ball)
        end
        return m
    end

    -- 9. Dragon Vein Grass (Arching blades with golden meridian vein patterns)
    builders["Dragon Vein Grass"] = function()
        local m = Instance.new("Model")
        m.Name = "Dragon Vein Grass"
        local root = makePart(m, "PlantRoot", Vector3.new(1.4, 0.5, 1.4), CFrame.new(0, 0.25, 0), Color3.fromRGB(50, 120, 60), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        for i = 1, 5 do
            local angle = math.rad((i - 1) * 72 + 10)
            local cf = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.9, 0.3) * CFrame.Angles(math.rad(20), 0, 0)
            makeStemWedge(m, "DragonBlade", Vector3.new(0.3, 1.8, 0.08), cf, Color3.fromRGB(55, 160, 80), Enum.Material.SmoothPlastic)
            -- Golden meridian vein running down the blade
            local vein = makePart(m, "DragonVein", Vector3.new(0.08, 1.6, 0.1), cf * CFrame.new(0, 0, 0.02), Color3.fromRGB(255, 205, 40), Enum.Material.Neon)
        end
        return m
    end

    -- 10. Ghost Orchid (Translucent white/lilac drooping petals, eerie silhouette)
    builders["Ghost Orchid"] = function()
        local m = Instance.new("Model")
        m.Name = "Ghost Orchid"
        local root = makePart(m, "PlantRoot", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 0.6, 0), Color3.fromRGB(220, 215, 240), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        -- Slender curving stem
        makePart(m, "StemLower", Vector3.new(0.08, 0.7, 0.08), CFrame.new(0, 0.35, 0), Color3.fromRGB(110, 135, 110), Enum.Material.SmoothPlastic)
        makePart(m, "StemUpper", Vector3.new(0.08, 0.6, 0.08), CFrame.new(0.12, 0.9, 0.1) * CFrame.Angles(math.rad(22), 0, math.rad(-18)), Color3.fromRGB(120, 145, 120), Enum.Material.SmoothPlastic)

        local blossomCf = CFrame.new(0.24, 1.2, 0.2)
        -- Pale ghostly dorsal sepal
        makePart(m, "DorsalSepal", Vector3.new(0.28, 0.6, 0.06), blossomCf * CFrame.new(0, 0.25, -0.1) * CFrame.Angles(math.rad(-25), 0, 0), Color3.fromRGB(245, 240, 255), Enum.Material.Glass)

        -- 2 serpentine lateral petals
        makePart(m, "PetalL", Vector3.new(0.18, 0.5, 0.05), blossomCf * CFrame.new(-0.2, 0.05, 0) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(225, 215, 245), Enum.Material.Glass)
        makePart(m, "PetalR", Vector3.new(0.18, 0.5, 0.05), blossomCf * CFrame.new(0.2, 0.05, 0) * CFrame.Angles(0, 0, math.rad(-45)), Color3.fromRGB(225, 215, 245), Enum.Material.Glass)

        -- Ghostly drooping double-tail tendrils
        makePart(m, "TendrilL", Vector3.new(0.06, 0.8, 0.06), blossomCf * CFrame.new(-0.12, -0.4, 0.1) * CFrame.Angles(math.rad(18), 0, math.rad(10)), Color3.fromRGB(195, 175, 235), Enum.Material.Neon)
        makePart(m, "TendrilR", Vector3.new(0.06, 0.8, 0.06), blossomCf * CFrame.new(0.12, -0.4, 0.1) * CFrame.Angles(math.rad(18), 0, math.rad(-10)), Color3.fromRGB(195, 175, 235), Enum.Material.Neon)

        -- Ethereal core
        makePart(m, "PhantomCore", Vector3.new(0.16, 0.16, 0.16), blossomCf, Color3.fromRGB(180, 140, 240), Enum.Material.Neon, Enum.PartType.Ball)
        return m
    end

    -- 11. Spirit Bamboo (Segmented bamboo stalks with golden nodes and leaf branchlets)
    builders["Spirit Bamboo"] = function()
        local m = Instance.new("Model")
        m.Name = "Spirit Bamboo"
        local root = makePart(m, "PlantRoot", Vector3.new(1.2, 1.8, 1.2), CFrame.new(0, 0.9, 0), Color3.fromRGB(60, 170, 90), Enum.Material.Wood)
        root.Transparency = 1
        m.PrimaryPart = root

        -- 3 bamboo stalks of varying heights
        local culmSpecs = {
            { x = 0, z = 0, height = 3.2, thick = 0.26 },
            { x = -0.32, z = 0.18, height = 2.4, thick = 0.22 },
            { x = 0.28, z = -0.22, height = 2.7, thick = 0.20 },
        }

        for cIdx, spec in ipairs(culmSpecs) do
            local numSegments = math.floor(spec.height / 0.8)
            for seg = 1, numSegments do
                local segY = (seg - 0.5) * 0.8
                local cf = CFrame.new(spec.x, segY, spec.z)
                makePart(m, "CulmSegment", Vector3.new(spec.thick, 0.74, spec.thick), cf, Color3.fromRGB(75, 195, 110), Enum.Material.Wood, Enum.PartType.Cylinder)
                -- Bamboo node ring
                local ringY = seg * 0.8
                local node = makePart(m, "NodeRing", Vector3.new(spec.thick + 0.06, 0.08, spec.thick + 0.06), CFrame.new(spec.x, ringY, spec.z), Color3.fromRGB(220, 245, 160), Enum.Material.Neon, Enum.PartType.Cylinder)

                -- Leaf spray branching off every alternate node
                if seg % 2 == 1 and seg > 1 then
                    local leafAngle = math.rad((seg * 90) + (cIdx * 60))
                    local leafCf = CFrame.new(spec.x, ringY, spec.z) * CFrame.Angles(0, leafAngle, 0) * CFrame.new(0, 0.1, 0.35) * CFrame.Angles(math.rad(15), 0, 0)
                    makePart(m, "BambooLeaf", Vector3.new(0.24, 0.04, 0.55), leafCf, Color3.fromRGB(90, 215, 125), Enum.Material.SmoothPlastic)
                end
            end
        end
        return m
    end

    -- Build and place all 11 plant templates
    local plantNames = {
        "Spirit Grass", "Ginseng Herb", "Ironleaf Herb", "Moonlight Grass",
        "Clearheart Flower", "Bloodroot", "Jade Lotus", "Hundred-Year Ginseng",
        "Dragon Vein Grass", "Ghost Orchid", "Spirit Bamboo"
    }

    local spacing = 4.5
    local startX = -((#plantNames - 1) * spacing) / 2
    local sampleY = 0

    -- Find ground level around 0,0,0
    local ray = Workspace:Raycast(Vector3.new(0, 50, 0), Vector3.new(0, -100, 0))
    if ray and ray.Position then
        sampleY = ray.Position.Y
    end

    local createdCount = 0
    for idx, name in ipairs(plantNames) do
        local builder = builders[name]
        if builder then
            -- 1. Create template for ServerStorage
            local modelSS = builder()
            local CollectionService = game:GetService("CollectionService")
            CollectionService:AddTag(modelSS, "HarvestablePlant")
            modelSS:SetAttribute("PlantName", name)

            local primary = modelSS.PrimaryPart
            if primary then
                local prompt = Instance.new("ProximityPrompt")
                prompt.Name = "HarvestPrompt"
                prompt.ActionText = "Harvest"
                prompt.ObjectText = name
                prompt.HoldDuration = 0.4
                prompt.MaxActivationDistance = 7.5
                prompt.RequiresLineOfSight = false
                prompt.Enabled = true
                prompt.Parent = primary
            end

            modelSS.Parent = ssTemplates

            -- 2. Create template for ReplicatedStorage
            local modelRS = modelSS:Clone()
            modelRS.Parent = rsTemplates

            -- 3. Create interactive sample row in Workspace.PlantTemplates for developer inspection
            local modelWS = modelSS:Clone()
            local posX = startX + (idx - 1) * spacing
            local samplePos = Vector3.new(posX, sampleY, 0)

            -- Raycast down at specific position to plant it firmly on the terrain
            local groundRay = Workspace:Raycast(Vector3.new(posX, sampleY + 20, 0), Vector3.new(0, -50, 0))
            if groundRay and groundRay.Position then
                samplePos = groundRay.Position
            end

            modelWS:PivotTo(CFrame.new(samplePos))
            modelWS:SetAttribute("OriginalSpawnPosition", samplePos)
            modelWS:SetAttribute("CurrentSpawnPosition", samplePos)
            modelWS:SetAttribute("Harvested", false)
            modelWS.Parent = wsTemplates

            createdCount = createdCount + 1
        end
    end

    return string.format("Successfully built and deployed all %d plant models to ServerStorage, ReplicatedStorage, and Workspace.PlantTemplates!", createdCount)
    """

    ok, res = exec_code(lua_models)
    print("Plant models deployment:", ok, res)
    assert ok, f"Failed models: {res}"
    print("=== Plant Gathering System deployment complete! ===")

if __name__ == '__main__':
    deploy_all()

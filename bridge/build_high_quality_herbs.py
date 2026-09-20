import sys
import os
from pathlib import Path
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def build_herbs():
    print("=== Constructing High-Quality Cultivation Herb Models ===")

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

    local ssTemplates = getOrCreateFolder(ServerStorage, "PlantTemplates")
    local rsTemplates = getOrCreateFolder(ReplicatedStorage, "PlantTemplates")
    local wsTemplates = getOrCreateFolder(Workspace, "PlantTemplates")

    -- Clear old templates
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

    local function makeWedge(parent, name, size, cf, color, mat)
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

    local function addMound(parent, radius, color)
        local m = makePart(parent, "SoilMound", Vector3.new(radius * 2, 0.25, radius * 2), CFrame.new(0, 0.1, 0), color or Color3.fromRGB(65, 52, 40), Enum.Material.Slate, Enum.PartType.Cylinder)
        m.CFrame = m.CFrame * CFrame.Angles(0, 0, math.rad(90))
        return m
    end

    local builders = {}

    -- ========================================================================
    -- 1. SPIRIT GRASS (Small: ~2.6 studs)
    -- Slender arching blades, pale emerald base, cyan/teal tips, luminous veins, central crystal seed
    -- ========================================================================
    builders["Spirit Grass"] = function()
        local m = Instance.new("Model")
        m.Name = "Spirit Grass"

        local root = makePart(m, "PlantRoot", Vector3.new(1.4, 0.6, 1.4), CFrame.new(0, 0.3, 0), Color3.fromRGB(50, 160, 85), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 0.7, Color3.fromRGB(55, 48, 38))

        -- Small spiritual crystal-like seed structure near the center
        local crystalCore = makePart(m, "SpiritSeedCrystal", Vector3.new(0.24, 0.45, 0.24), CFrame.new(0, 0.28, 0), Color3.fromRGB(130, 245, 220), Enum.Material.Glass, Enum.PartType.Ball)
        local seedGlow = makePart(m, "SeedFacet", Vector3.new(0.14, 0.25, 0.14), CFrame.new(0, 0.32, 0), Color3.fromRGB(160, 255, 240), Enum.Material.Neon, Enum.PartType.Cylinder)
        seedGlow.CFrame = seedGlow.CFrame * CFrame.Angles(0, 0, math.rad(45))

        -- 7 distinct arching spiritual blades in organic spiral
        local bladeConfigs = {
            { angle = 0,   len = 2.6, tilt = 12, bend = 16 },
            { angle = 52,  len = 2.4, tilt = 18, bend = 22 },
            { angle = 105, len = 2.7, tilt = 14, bend = 18 },
            { angle = 160, len = 2.3, tilt = 22, bend = 26 },
            { angle = 210, len = 2.8, tilt = 10, bend = 15 },
            { angle = 265, len = 2.2, tilt = 25, bend = 30 },
            { angle = 315, len = 2.5, tilt = 16, bend = 20 },
        }

        for i, cfg in ipairs(bladeConfigs) do
            local baseCf = CFrame.new(0, 0.15, 0) * CFrame.Angles(0, math.rad(cfg.angle), 0)
            local lowerLen = cfg.len * 0.55
            local upperLen = cfg.len * 0.45

            -- Lower blade (pale emerald base)
            local lowerCf = baseCf * CFrame.new(0, lowerLen * 0.45, 0.12) * CFrame.Angles(math.rad(cfg.tilt), 0, 0)
            makePart(m, "BladeLower_" .. i, Vector3.new(0.18, lowerLen, 0.05), lowerCf, Color3.fromRGB(65, 175, 95), Enum.Material.SmoothPlastic)

            -- Embedded fine luminous vein
            local veinCf = lowerCf * CFrame.new(0, 0, 0.02)
            makePart(m, "BladeVein_" .. i, Vector3.new(0.04, lowerLen * 0.9, 0.06), veinCf, Color3.fromRGB(140, 255, 225), Enum.Material.Neon)

            -- Upper blade & tip (cyan / teal transition)
            local upperCf = lowerCf * CFrame.new(0, lowerLen * 0.5, 0) * CFrame.Angles(math.rad(cfg.bend), 0, 0) * CFrame.new(0, upperLen * 0.45, 0)
            makePart(m, "BladeMid_" .. i, Vector3.new(0.14, upperLen * 0.6, 0.04), upperCf, Color3.fromRGB(75, 205, 160), Enum.Material.SmoothPlastic)

            local tipCf = upperCf * CFrame.new(0, upperLen * 0.4, 0) * CFrame.Angles(math.rad(cfg.bend * 0.5), 0, 0)
            makeWedge(m, "BladeTip_" .. i, Vector3.new(0.10, upperLen * 0.45, 0.03), tipCf, Color3.fromRGB(110, 245, 220), Enum.Material.Neon)
        end
        return m
    end

    -- ========================================================================
    -- 2. GINSENG HERB (Medium: ~3.0 studs)
    -- Partially exposed twisted pale tan root with rootlets, thick stalk, 4 compound leaf clusters, red berries
    -- ========================================================================
    builders["Ginseng Herb"] = function()
        local m = Instance.new("Model")
        m.Name = "Ginseng Herb"

        local root = makePart(m, "PlantRoot", Vector3.new(1.6, 1.4, 1.6), CFrame.new(0, 0.7, 0), Color3.fromRGB(205, 170, 115), Enum.Material.Wood)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 0.9, Color3.fromRGB(60, 48, 35))

        -- 1. EXPOSED GINSENG ROOT (Distinctive medicinal humanoid/forked root emerging from soil)
        local rootCol = Color3.fromRGB(215, 175, 120)
        local rootColDark = Color3.fromRGB(195, 155, 105)

        local mainTap = makePart(m, "MainTaproot", Vector3.new(0.42, 0.85, 0.40), CFrame.new(0, 0.42, 0) * CFrame.Angles(math.rad(10), math.rad(15), 0), rootCol, Enum.Material.Wood, Enum.PartType.Cylinder)
        mainTap.CFrame = mainTap.CFrame * CFrame.Angles(0, 0, math.rad(90))

        -- Forked primary root branches
        local rootForkL = makePart(m, "RootForkL", Vector3.new(0.24, 0.65, 0.24), CFrame.new(-0.20, 0.25, 0.08) * CFrame.Angles(math.rad(-15), 0, math.rad(35)), rootCol, Enum.Material.Wood, Enum.PartType.Cylinder)
        local rootForkR = makePart(m, "RootForkR", Vector3.new(0.22, 0.60, 0.22), CFrame.new(0.18, 0.22, -0.06) * CFrame.Angles(math.rad(12), 0, math.rad(-30)), rootCol, Enum.Material.Wood, Enum.PartType.Cylinder)

        -- 4 small lateral curling rootlets
        makePart(m, "Rootlet1", Vector3.new(0.10, 0.40, 0.10), CFrame.new(-0.32, 0.12, 0.18) * CFrame.Angles(0, math.rad(45), math.rad(45)), rootColDark, Enum.Material.Wood)
        makePart(m, "Rootlet2", Vector3.new(0.09, 0.35, 0.09), CFrame.new(0.28, 0.10, 0.15) * CFrame.Angles(0, math.rad(-30), math.rad(-40)), rootColDark, Enum.Material.Wood)
        makePart(m, "Rootlet3", Vector3.new(0.08, 0.32, 0.08), CFrame.new(0.05, 0.14, -0.25) * CFrame.Angles(math.rad(-45), 0, 0), rootColDark, Enum.Material.Wood)

        -- 2. CENTRAL MEDICINAL STALK
        makePart(m, "StalkLower", Vector3.new(0.16, 0.8, 0.16), CFrame.new(0, 0.95, 0), Color3.fromRGB(65, 130, 60), Enum.Material.SmoothPlastic)
        makePart(m, "StalkUpper", Vector3.new(0.13, 0.8, 0.13), CFrame.new(0, 1.55, 0), Color3.fromRGB(75, 145, 65), Enum.Material.SmoothPlastic)

        -- 3. 4 COMPOUND LEAF CLUSTERS (Each cluster has 3 serrated palmate leaflets)
        for i = 1, 4 do
            local angle = math.rad((i - 1) * 90 + 22)
            local petioleCf = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.1, 0.45) * CFrame.Angles(math.rad(22), 0, 0)

            -- Petiole stem
            makePart(m, "Petiole_" .. i, Vector3.new(0.07, 0.07, 0.5), petioleCf, Color3.fromRGB(60, 130, 55), Enum.Material.SmoothPlastic)

            -- Central large leaflet
            local centerLeafCf = petioleCf * CFrame.new(0, 0.05, 0.42) * CFrame.Angles(math.rad(10), 0, 0)
            makePart(m, "LeafCenter_" .. i, Vector3.new(0.42, 0.05, 0.65), centerLeafCf, Color3.fromRGB(45, 145, 55), Enum.Material.SmoothPlastic)
            makePart(m, "LeafRib_" .. i, Vector3.new(0.06, 0.06, 0.62), centerLeafCf * CFrame.new(0, 0.02, 0), Color3.fromRGB(90, 195, 80), Enum.Material.SmoothPlastic)

            -- Left leaflet
            local leftLeafCf = petioleCf * CFrame.new(-0.25, 0.03, 0.28) * CFrame.Angles(0, math.rad(30), math.rad(-15))
            makePart(m, "LeafLeft_" .. i, Vector3.new(0.32, 0.04, 0.48), leftLeafCf, Color3.fromRGB(40, 135, 50), Enum.Material.SmoothPlastic)

            -- Right leaflet
            local rightLeafCf = petioleCf * CFrame.new(0.25, 0.03, 0.28) * CFrame.Angles(0, math.rad(-30), math.rad(15))
            makePart(m, "LeafRight_" .. i, Vector3.new(0.32, 0.04, 0.48), rightLeafCf, Color3.fromRGB(40, 135, 50), Enum.Material.SmoothPlastic)
        end

        -- 4. SCARLET GINSENG BERRY UMBEL (Tight crown cluster of red medicinal berries on a pedicel)
        local umbelBase = CFrame.new(0, 2.1, 0)
        makePart(m, "BerryPedicel", Vector3.new(0.06, 0.35, 0.06), umbelBase * CFrame.new(0, -0.1, 0), Color3.fromRGB(90, 150, 80), Enum.Material.SmoothPlastic)
        makePart(m, "BerryUmbelCenter", Vector3.new(0.22, 0.22, 0.22), umbelBase * CFrame.new(0, 0.1, 0), Color3.fromRGB(215, 25, 25), Enum.Material.SmoothPlastic, Enum.PartType.Ball)

        for b = 1, 6 do
            local bAngle = math.rad((b - 1) * 60)
            local bCf = umbelBase * CFrame.new(0, 0.12, 0) * CFrame.Angles(0, bAngle, 0) * CFrame.new(0.14, 0.04, 0)
            makePart(m, "GinsengBerry_" .. b, Vector3.new(0.16, 0.16, 0.16), bCf, Color3.fromRGB(235, 35, 35), Enum.Material.Neon, Enum.PartType.Ball)
        end
        return m
    end

    -- ========================================================================
    -- 3. IRONLEAF HERB (Small: ~2.2 studs, width ~3.2 studs)
    -- Rigid, heavy layered dagger leaves, dark blue-green with metallic gray beveled edges & forged ribs, metal nodes
    -- ========================================================================
    builders["Ironleaf Herb"] = function()
        local m = Instance.new("Model")
        m.Name = "Ironleaf Herb"

        local root = makePart(m, "PlantRoot", Vector3.new(1.8, 0.6, 1.8), CFrame.new(0, 0.3, 0), Color3.fromRGB(70, 85, 95), Enum.Material.Metal)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 0.85, Color3.fromRGB(50, 48, 45))

        -- Metallic basal root collar & 4 forged iron nodes
        local collar = makePart(m, "IronCollar", Vector3.new(0.55, 0.35, 0.55), CFrame.new(0, 0.18, 0), Color3.fromRGB(55, 65, 75), Enum.Material.Metal, Enum.PartType.Cylinder)
        collar.CFrame = collar.CFrame * CFrame.Angles(0, 0, math.rad(90))

        for n = 1, 4 do
            local nAngle = math.rad((n - 1) * 90)
            local nCf = CFrame.new(0, 0.18, 0) * CFrame.Angles(0, nAngle, 0) * CFrame.new(0.32, 0, 0)
            makePart(m, "IronNode_" .. n, Vector3.new(0.16, 0.16, 0.16), nCf, Color3.fromRGB(90, 105, 115), Enum.Material.Metal, Enum.PartType.Ball)
        end

        -- Heavy central stalk
        makePart(m, "IronStalk", Vector3.new(0.24, 0.75, 0.24), CFrame.new(0, 0.55, 0), Color3.fromRGB(45, 60, 65), Enum.Material.Metal)

        -- 8 rigid lanceolate iron blade leaves (2 tiered rosettes of 4)
        local leafLayers = {
            { count = 4, yOff = 0.35, reach = 1.35, width = 0.38, tilt = 38, rotOff = 0,   col = Color3.fromRGB(35, 75, 70) },
            { count = 4, yOff = 0.65, reach = 1.15, width = 0.32, tilt = 25, rotOff = 45,  col = Color3.fromRGB(45, 90, 85) },
        }

        for tierIdx, tier in ipairs(leafLayers) do
            for i = 1, tier.count do
                local angle = math.rad((i - 1) * 90 + tier.rotOff)
                local cf = CFrame.new(0, tier.yOff, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.25, tier.reach * 0.45) * CFrame.Angles(math.rad(tier.tilt), 0, 0)

                -- Main heavy leaf plate (dark green / blue-green)
                makePart(m, "IronBlade_" .. tierIdx .. "_" .. i, Vector3.new(tier.width, 0.08, tier.reach), cf, tier.col, Enum.Material.Slate)

                -- Forged metallic bevel edges (left & right)
                local edgeL = cf * CFrame.new(-tier.width * 0.45, 0.02, 0)
                makePart(m, "BladeBevelL_" .. tierIdx .. "_" .. i, Vector3.new(0.06, 0.09, tier.reach * 0.95), edgeL, Color3.fromRGB(165, 180, 195), Enum.Material.Metal)

                local edgeR = cf * CFrame.new(tier.width * 0.45, 0.02, 0)
                makePart(m, "BladeBevelR_" .. tierIdx .. "_" .. i, Vector3.new(0.06, 0.09, tier.reach * 0.95), edgeR, Color3.fromRGB(165, 180, 195), Enum.Material.Metal)

                -- Central forged spine / rib
                local spine = cf * CFrame.new(0, 0.04, 0)
                makePart(m, "IronSpine_" .. tierIdx .. "_" .. i, Vector3.new(0.08, 0.10, tier.reach * 0.98), spine, Color3.fromRGB(110, 125, 135), Enum.Material.Metal)

                -- Sharp piercing dagger tip
                local tipCf = cf * CFrame.new(0, 0, tier.reach * 0.5) * CFrame.Angles(math.rad(15), 0, 0)
                makeWedge(m, "DaggerTip_" .. tierIdx .. "_" .. i, Vector3.new(tier.width * 0.7, tier.reach * 0.25, 0.06), tipCf, Color3.fromRGB(180, 195, 205), Enum.Material.Metal)
            end
        end

        -- Armored central crown spike
        makePart(m, "CrownSpike", Vector3.new(0.18, 0.5, 0.18), CFrame.new(0, 1.1, 0), Color3.fromRGB(140, 155, 165), Enum.Material.Metal, Enum.PartType.Cylinder)
        return m
    end

    -- ========================================================================
    -- 4. MOONLIGHT GRASS (Small: ~2.5 studs)
    -- Sweeping downward-curving crescent moon blades, pale silver-green, white/silver tips, hanging lunar seed pods
    -- ========================================================================
    builders["Moonlight Grass"] = function()
        local m = Instance.new("Model")
        m.Name = "Moonlight Grass"

        local root = makePart(m, "PlantRoot", Vector3.new(1.6, 0.6, 1.6), CFrame.new(0, 0.3, 0), Color3.fromRGB(200, 225, 240), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 0.75, Color3.fromRGB(48, 52, 58))

        -- 6 sweeping weeping crescent blades curving downward toward the ground like crescent moons
        local crescentBlades = {
            { angle = 15,  arc = 1.9, sweep = 42 },
            { angle = 75,  arc = 2.2, sweep = 48 },
            { angle = 135, arc = 1.8, sweep = 40 },
            { angle = 195, arc = 2.3, sweep = 50 },
            { angle = 255, arc = 2.0, sweep = 45 },
            { angle = 315, arc = 2.1, sweep = 46 },
        }

        for i, b in ipairs(crescentBlades) do
            local baseCf = CFrame.new(0, 0.18, 0) * CFrame.Angles(0, math.rad(b.angle), 0)

            -- Segment 1: Rising upward
            local s1Len = b.arc * 0.45
            local s1Cf = baseCf * CFrame.new(0, s1Len * 0.5, 0.15) * CFrame.Angles(math.rad(22), 0, 0)
            makePart(m, "MoonRise_" .. i, Vector3.new(0.18, s1Len, 0.04), s1Cf, Color3.fromRGB(195, 220, 235), Enum.Material.SmoothPlastic)

            -- Segment 2: Arching crest (paler silver)
            local s2Len = b.arc * 0.40
            local s2Cf = s1Cf * CFrame.new(0, s1Len * 0.5, 0) * CFrame.Angles(math.rad(b.sweep * 0.6), 0, 0) * CFrame.new(0, s2Len * 0.5, 0)
            makePart(m, "MoonArch_" .. i, Vector3.new(0.15, s2Len, 0.04), s2Cf, Color3.fromRGB(225, 238, 248), Enum.Material.SmoothPlastic)

            -- Segment 3: Weeping crescent tip pointing down (moon-white with blue-violet neon luster)
            local s3Len = b.arc * 0.35
            local s3Cf = s2Cf * CFrame.new(0, s2Len * 0.5, 0) * CFrame.Angles(math.rad(b.sweep * 0.8), 0, 0) * CFrame.new(0, s3Len * 0.5, 0)
            makePart(m, "MoonTip_" .. i, Vector3.new(0.11, s3Len, 0.03), s3Cf, Color3.fromRGB(245, 250, 255), Enum.Material.Neon)

            -- Tiny hanging crescent lunar seed capsule dangling beneath the arch
            if i % 2 == 1 then
                local podStemCf = s2Cf * CFrame.new(0, 0, -0.12) * CFrame.Angles(math.rad(-30), 0, 0)
                makePart(m, "PodStem_" .. i, Vector3.new(0.03, 0.25, 0.03), podStemCf, Color3.fromRGB(160, 185, 215), Enum.Material.SmoothPlastic)
                local podCf = podStemCf * CFrame.new(0, -0.15, 0) * CFrame.Angles(0, 0, math.rad(35))
                makePart(m, "LunarPod_" .. i, Vector3.new(0.16, 0.12, 0.06), podCf, Color3.fromRGB(205, 220, 255), Enum.Material.Neon, Enum.PartType.Ball)
            end
        end

        -- Luminous silver-violet center bud
        makePart(m, "MoonHeart", Vector3.new(0.22, 0.35, 0.22), CFrame.new(0, 0.35, 0), Color3.fromRGB(210, 220, 255), Enum.Material.Glass, Enum.PartType.Ball)
        return m
    end

    -- ========================================================================
    -- 5. CLEARHEART FLOWER (Small: ~2.4 studs)
    -- Symmetrical 8-petal white flower, crystalline center, cyan veins, heart-shaped base leaves
    -- ========================================================================
    builders["Clearheart Flower"] = function()
        local m = Instance.new("Model")
        m.Name = "Clearheart Flower"

        local root = makePart(m, "PlantRoot", Vector3.new(1.4, 1.2, 1.4), CFrame.new(0, 0.6, 0), Color3.fromRGB(245, 245, 250), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 0.7, Color3.fromRGB(58, 48, 38))

        -- 1. 4 DISTINCT BOTANICAL HEART-SHAPED BASE LEAVES
        for h = 1, 4 do
            local hAngle = math.rad((h - 1) * 90 + 15)
            local hBaseCf = CFrame.new(0, 0.15, 0) * CFrame.Angles(0, hAngle, 0) * CFrame.new(0, 0.05, 0.55) * CFrame.Angles(math.rad(12), 0, 0)

            -- Heart leaf main blade
            makePart(m, "HeartLeaf_" .. h, Vector3.new(0.55, 0.05, 0.60), hBaseCf, Color3.fromRGB(55, 150, 75), Enum.Material.SmoothPlastic)
            -- Heart cleft notch lobes (two rounded lobes forming classic heart shape)
            local lobeL = hBaseCf * CFrame.new(-0.16, 0.02, 0.25)
            makePart(m, "HeartLobeL_" .. h, Vector3.new(0.26, 0.06, 0.26), lobeL, Color3.fromRGB(60, 155, 80), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
            local lobeR = hBaseCf * CFrame.new(0.16, 0.02, 0.25)
            makePart(m, "HeartLobeR_" .. h, Vector3.new(0.26, 0.06, 0.26), lobeR, Color3.fromRGB(60, 155, 80), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
        end

        -- 2. LONG CLEAN GREEN STEM
        makePart(m, "FlowerStem", Vector3.new(0.12, 1.2, 0.12), CFrame.new(0, 0.75, 0), Color3.fromRGB(65, 155, 75), Enum.Material.SmoothPlastic)

        -- 3. 8-PETAL SYMMETRICAL PURE WHITE BLOSSOM
        local flowerCenter = CFrame.new(0, 1.45, 0)
        local petalCol = Color3.fromRGB(250, 252, 255)

        for p = 1, 8 do
            local pAngle = math.rad((p - 1) * 45)
            local petalCf = flowerCenter * CFrame.Angles(0, pAngle, 0) * CFrame.new(0, 0.08, 0.42) * CFrame.Angles(math.rad(18), 0, 0)

            -- Petal body
            makePart(m, "Petal_" .. p, Vector3.new(0.32, 0.05, 0.55), petalCf, petalCol, Enum.Material.SmoothPlastic)

            -- Pale cyan delicate vein on petal
            local vein = petalCf * CFrame.new(0, 0.02, 0)
            makePart(m, "PetalVein_" .. p, Vector3.new(0.04, 0.06, 0.50), vein, Color3.fromRGB(175, 240, 255), Enum.Material.Neon)
        end

        -- 4. CRYSTALLINE CENTER WITH SUBTLE HEART-SHAPED RECEPTACLE
        local coreCf = flowerCenter * CFrame.new(0, 0.12, 0)
        local crystalCore = makePart(m, "CrystallineCenter", Vector3.new(0.36, 0.20, 0.36), coreCf, Color3.fromRGB(195, 245, 255), Enum.Material.Glass, Enum.PartType.Cylinder)
        crystalCore.CFrame = crystalCore.CFrame * CFrame.Angles(0, 0, math.rad(90))

        -- Pure golden heart stamen
        makePart(m, "HeartStamenL", Vector3.new(0.15, 0.16, 0.15), coreCf * CFrame.new(-0.06, 0.06, 0.04), Color3.fromRGB(255, 220, 75), Enum.Material.Neon, Enum.PartType.Ball)
        makePart(m, "HeartStamenR", Vector3.new(0.15, 0.16, 0.15), coreCf * CFrame.new(0.06, 0.06, 0.04), Color3.fromRGB(255, 220, 75), Enum.Material.Neon, Enum.PartType.Ball)
        return m
    end

    -- ========================================================================
    -- 6. BLOODROOT (Small: ~2.3 studs, width ~3.0 studs)
    -- Gnarled crimson root twisting through soil, dark red stems, broad serrated crimson leaves, blood-red veins
    -- ========================================================================
    builders["Bloodroot"] = function()
        local m = Instance.new("Model")
        m.Name = "Bloodroot"

        local root = makePart(m, "PlantRoot", Vector3.new(1.8, 0.8, 1.8), CFrame.new(0, 0.4, 0), Color3.fromRGB(165, 25, 35), Enum.Material.Slate)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 0.9, Color3.fromRGB(48, 38, 35))

        -- 1. PROMINENT TWISTING BLOOD ROOT (The primary visual feature!)
        local rootEarth = Color3.fromRGB(105, 30, 30)
        local rootCrimson = Color3.fromRGB(175, 25, 35)

        -- Primary winding root torso
        local mainRoot = makePart(m, "BloodRootMain", Vector3.new(0.48, 0.95, 0.45), CFrame.new(0, 0.35, 0) * CFrame.Angles(math.rad(15), math.rad(25), math.rad(-10)), rootCrimson, Enum.Material.Slate, Enum.PartType.Cylinder)
        mainTap = mainRoot.CFrame * CFrame.Angles(0, 0, math.rad(90))

        -- Gnarled secondary knuckles curving over the soil surface
        makePart(m, "RootKnuckle1", Vector3.new(0.38, 0.38, 0.38), CFrame.new(0.32, 0.22, 0.15), rootCrimson, Enum.Material.Slate, Enum.PartType.Ball)
        makePart(m, "RootKnuckle2", Vector3.new(0.35, 0.35, 0.35), CFrame.new(-0.28, 0.20, -0.18), rootEarth, Enum.Material.Slate, Enum.PartType.Ball)
        makePart(m, "RootBranchS", Vector3.new(0.18, 0.65, 0.18), CFrame.new(0.48, 0.14, 0.28) * CFrame.Angles(0, 0, math.rad(45)), rootEarth, Enum.Material.Slate, Enum.PartType.Cylinder)

        -- 2. DARK RED STALKS
        makePart(m, "BloodStalkMain", Vector3.new(0.18, 0.85, 0.18), CFrame.new(0.05, 0.85, 0.05), Color3.fromRGB(120, 15, 25), Enum.Material.SmoothPlastic)

        -- 3. 5 BROAD DEEPLY LOBED CRIMSON LEAVES WITH ARTERIAL BLOOD VEINS
        for l = 1, 5 do
            local lAngle = math.rad((l - 1) * 72 + 10)
            local petioleCf = CFrame.new(0.05, 0.8, 0.05) * CFrame.Angles(0, lAngle, 0) * CFrame.new(0, 0.15, 0.45) * CFrame.Angles(math.rad(25), 0, 0)

            -- Leaf blade (broad spade)
            makePart(m, "BloodBlade_" .. l, Vector3.new(0.55, 0.06, 0.80), petioleCf, Color3.fromRGB(145, 20, 30), Enum.Material.SmoothPlastic)

            -- Blood-red arterial branching veins
            local centralVein = petioleCf * CFrame.new(0, 0.03, 0)
            makePart(m, "ArteryVein_" .. l, Vector3.new(0.08, 0.08, 0.76), centralVein, Color3.fromRGB(235, 35, 45), Enum.Material.Neon)

            local branchVeinL = petioleCf * CFrame.new(-0.15, 0.03, 0.08) * CFrame.Angles(0, math.rad(35), 0)
            makePart(m, "BranchVeinL_" .. l, Vector3.new(0.05, 0.06, 0.35), branchVeinL, Color3.fromRGB(215, 30, 40), Enum.Material.Neon)

            local branchVeinR = petioleCf * CFrame.new(0.15, 0.03, 0.08) * CFrame.Angles(0, math.rad(-35), 0)
            makePart(m, "BranchVeinR_" .. l, Vector3.new(0.05, 0.06, 0.35), branchVeinR, Color3.fromRGB(215, 30, 40), Enum.Material.Neon)
        end
        return m
    end

    -- ========================================================================
    -- 7. JADE LOTUS (Large: diameter ~4.6 studs, height ~2.2 studs)
    -- Premium gemstone-like lotus, broad notched circular lotus pad, layered translucent jade petals, golden seed pod
    -- ========================================================================
    builders["Jade Lotus"] = function()
        local m = Instance.new("Model")
        m.Name = "Jade Lotus"

        local root = makePart(m, "PlantRoot", Vector3.new(2.4, 0.6, 2.4), CFrame.new(0, 0.3, 0), Color3.fromRGB(90, 215, 160), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        -- 1. LARGE CIRCULAR LOTUS PAD WITH NATURAL TRIANGULAR CLEFT (Diameter ~4.4 studs)
        local padBase = makePart(m, "LotusPad", Vector3.new(4.2, 0.08, 4.2), CFrame.new(0, 0.04, 0), Color3.fromRGB(38, 120, 68), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
        padBase.CFrame = padBase.CFrame * CFrame.Angles(0, 0, math.rad(90))

        -- Subtle radial veins on lotus pad
        for r = 1, 6 do
            local rAngle = math.rad((r - 1) * 60)
            local rCf = CFrame.new(0, 0.08, 0) * CFrame.Angles(0, rAngle, 0) * CFrame.new(0, 0, 1.1)
            makePart(m, "PadVein_" .. r, Vector3.new(0.06, 0.03, 2.0), rCf, Color3.fromRGB(55, 150, 90), Enum.Material.SmoothPlastic)
        end

        -- 2. LAYERED TRANSLUCENT POLISHED JADE PETALS (Concentric bowl)
        local centerCf = CFrame.new(0, 0.16, 0)

        -- Outer layer: 8 broad flared jade petals
        for o = 1, 8 do
            local oAngle = math.rad((o - 1) * 45)
            local oCf = centerCf * CFrame.Angles(0, oAngle, 0) * CFrame.new(0, 0.18, 0.85) * CFrame.Angles(math.rad(32), 0, 0)
            makePart(m, "JadePetalOuter_" .. o, Vector3.new(0.52, 0.08, 0.95), oCf, Color3.fromRGB(85, 205, 155), Enum.Material.Glass)
        end

        -- Middle layer: 8 upright cup-shaped jade petals (interlocking)
        for mid = 1, 8 do
            local mAngle = math.rad((mid - 1) * 45 + 22.5)
            local mCf = centerCf * CFrame.Angles(0, mAngle, 0) * CFrame.new(0, 0.28, 0.55) * CFrame.Angles(math.rad(50), 0, 0)
            makePart(m, "JadePetalMid_" .. mid, Vector3.new(0.42, 0.07, 0.80), mCf, Color3.fromRGB(115, 230, 180), Enum.Material.Glass)
        end

        -- Inner layer: 6 delicate upright petals embracing core
        for inn = 1, 6 do
            local iAngle = math.rad((inn - 1) * 60)
            local iCf = centerCf * CFrame.Angles(0, iAngle, 0) * CFrame.new(0, 0.35, 0.32) * CFrame.Angles(math.rad(65), 0, 0)
            makePart(m, "JadePetalInner_" .. inn, Vector3.new(0.32, 0.06, 0.60), iCf, Color3.fromRGB(145, 245, 200), Enum.Material.Glass)
        end

        -- 3. PROMINENT GOLDEN-JADE SEED POD CORE
        local pod = makePart(m, "LotusSeedPod", Vector3.new(0.65, 0.30, 0.65), centerCf * CFrame.new(0, 0.32, 0), Color3.fromRGB(240, 215, 75), Enum.Material.Neon, Enum.PartType.Cylinder)
        pod.CFrame = pod.CFrame * CFrame.Angles(0, 0, math.rad(90))

        -- 6 seed pits on top of pod
        for s = 1, 6 do
            local sAngle = math.rad((s - 1) * 60)
            local sCf = centerCf * CFrame.new(0, 0.48, 0) * CFrame.Angles(0, sAngle, 0) * CFrame.new(0.20, 0, 0)
            makePart(m, "SeedPit_" .. s, Vector3.new(0.08, 0.05, 0.08), sCf, Color3.fromRGB(80, 140, 60), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
        end
        return m
    end

    -- ========================================================================
    -- 8. HUNDRED-YEAR GINSENG (Large: height ~4.2 studs, width ~3.4 studs)
    -- Massive ancient humanoid root, bark-like texture, dual foliage tiers, crown of 12 luminous crimson pearls
    -- ========================================================================
    builders["Hundred-Year Ginseng"] = function()
        local m = Instance.new("Model")
        m.Name = "Hundred-Year Ginseng"

        local root = makePart(m, "PlantRoot", Vector3.new(2.2, 2.0, 2.2), CFrame.new(0, 1.0, 0), Color3.fromRGB(225, 185, 125), Enum.Material.Wood)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 1.4, Color3.fromRGB(60, 48, 32))

        -- 1. MASSIVE ANCIENT HUMANOID ROOT (Surpassed a century of cultivation)
        local ancientCol = Color3.fromRGB(225, 185, 125)
        local darkBark = Color3.fromRGB(180, 140, 85)

        -- Central heavy torso root
        local torso = makePart(m, "AncientTorsoRoot", Vector3.new(0.75, 1.35, 0.70), CFrame.new(0, 0.70, 0) * CFrame.Angles(math.rad(8), math.rad(15), 0), ancientCol, Enum.Material.Wood, Enum.PartType.Cylinder)
        torso.CFrame = torso.CFrame * CFrame.Angles(0, 0, math.rad(90))

        -- Articulated ancient leg roots
        makePart(m, "AncientLegL", Vector3.new(0.38, 0.95, 0.38), CFrame.new(-0.35, 0.35, 0.12) * CFrame.Angles(math.rad(-15), 0, math.rad(30)), ancientCol, Enum.Material.Wood, Enum.PartType.Cylinder)
        makePart(m, "AncientLegR", Vector3.new(0.35, 0.90, 0.35), CFrame.new(0.32, 0.32, -0.10) * CFrame.Angles(math.rad(12), 0, math.rad(-28)), ancientCol, Enum.Material.Wood, Enum.PartType.Cylinder)

        -- Ancient arm roots branching sideways
        makePart(m, "AncientArmL", Vector3.new(0.28, 0.75, 0.28), CFrame.new(-0.42, 0.85, 0.20) * CFrame.Angles(0, math.rad(45), math.rad(40)), ancientCol, Enum.Material.Wood, Enum.PartType.Cylinder)
        makePart(m, "AncientArmR", Vector3.new(0.26, 0.70, 0.26), CFrame.new(0.40, 0.80, -0.18) * CFrame.Angles(0, math.rad(-35), math.rad(-38)), ancientCol, Enum.Material.Wood, Enum.PartType.Cylinder)

        -- 8 fibrous bearded rootlets trailing into earth
        for f = 1, 8 do
            local fAngle = math.rad((f - 1) * 45)
            local fCf = CFrame.new(0, 0.18, 0) * CFrame.Angles(0, fAngle, 0) * CFrame.new(0.55, 0, 0) * CFrame.Angles(0, 0, math.rad(45))
            makePart(m, "BeardRoot_" .. f, Vector3.new(0.08, 0.50, 0.08), fCf, darkBark, Enum.Material.Wood)
        end

        -- 2. MULTI-STEM CROWN
        makePart(m, "AncientStalkMain", Vector3.new(0.20, 1.4, 0.20), CFrame.new(0, 1.85, 0), Color3.fromRGB(65, 135, 65), Enum.Material.SmoothPlastic)
        makePart(m, "AncientStalkSubL", Vector3.new(0.14, 1.0, 0.14), CFrame.new(-0.25, 1.70, 0.1) * CFrame.Angles(0, 0, math.rad(18)), Color3.fromRGB(60, 130, 60), Enum.Material.SmoothPlastic)
        makePart(m, "AncientStalkSubR", Vector3.new(0.14, 1.0, 0.14), CFrame.new(0.25, 1.70, -0.1) * CFrame.Angles(0, 0, math.rad(-18)), Color3.fromRGB(60, 130, 60), Enum.Material.SmoothPlastic)

        -- 3. DUAL-TIER MATURE COMPOUND FOLIAGE CROWN (10 large palmate leaf clusters)
        for tier = 1, 2 do
            local yOff = 2.1 + (tier * 0.5)
            local count = 5
            for i = 1, count do
                local angle = math.rad((i - 1) * (360 / count) + (tier * 36))
                local cf = CFrame.new(0, yOff, 0) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.15, 0.75) * CFrame.Angles(math.rad(20), 0, 0)
                makePart(m, "MatureLeaf_" .. tier .. "_" .. i, Vector3.new(0.58, 0.07, 0.95), cf, Color3.fromRGB(38, 140, 55), Enum.Material.SmoothPlastic)
                makePart(m, "LeafRibM_" .. tier .. "_" .. i, Vector3.new(0.08, 0.08, 0.90), cf * CFrame.new(0, 0.03, 0), Color3.fromRGB(80, 190, 75), Enum.Material.SmoothPlastic)
            end
        end

        -- 4. RADIANT CROWN OF 12 CRIMSON GINSENG PEARLS
        local pearlDomeCf = CFrame.new(0, 3.25, 0)
        makePart(m, "PearlCore", Vector3.new(0.35, 0.35, 0.35), pearlDomeCf, Color3.fromRGB(220, 30, 30), Enum.Material.SmoothPlastic, Enum.PartType.Ball)

        for p = 1, 12 do
            local pAngle = math.rad((p - 1) * 30)
            local pCf = pearlDomeCf * CFrame.Angles(0, pAngle, 0) * CFrame.new(0.24, 0.08, 0)
            makePart(m, "GinsengPearl_" .. p, Vector3.new(0.20, 0.20, 0.20), pCf, Color3.fromRGB(255, 45, 45), Enum.Material.Neon, Enum.PartType.Ball)
        end
        return m
    end

    -- ========================================================================
    -- 9. DRAGON VEIN GRASS (Medium: height ~3.5 studs)
    -- Arching blades, branching golden/amber vein patterns, outward-curling dragon horns, scaled stalk
    -- ========================================================================
    builders["Dragon Vein Grass"] = function()
        local m = Instance.new("Model")
        m.Name = "Dragon Vein Grass"

        local root = makePart(m, "PlantRoot", Vector3.new(1.8, 1.0, 1.8), CFrame.new(0, 0.5, 0), Color3.fromRGB(55, 145, 75), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 0.9, Color3.fromRGB(52, 45, 36))

        -- 1. SCALED CENTRAL DRAGON STALK
        makePart(m, "DragonStalk", Vector3.new(0.28, 1.3, 0.28), CFrame.new(0, 0.75, 0), Color3.fromRGB(45, 95, 55), Enum.Material.SmoothPlastic)
        -- Small scale-like segments along stem
        for sc = 1, 4 do
            local scCf = CFrame.new(0, 0.35 + (sc * 0.25), 0) * CFrame.Angles(0, math.rad(sc * 45), 0)
            makePart(m, "ScaleRidge_" .. sc, Vector3.new(0.32, 0.08, 0.32), scCf, Color3.fromRGB(65, 125, 75), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
        end

        -- 2. 6 TALL ARCHING BLADES WITH INTRICATE GOLDEN MERIDIAN VEINS
        for b = 1, 6 do
            local bAngle = math.rad((b - 1) * 60 + 10)
            local isHorn = (b == 1 or b == 4) -- Two blades curl outward dramatically like miniature dragon horns

            local baseCf = CFrame.new(0, 0.35, 0) * CFrame.Angles(0, bAngle, 0)
            local tilt = isHorn and 38 or 18
            local bend = isHorn and 55 or 25
            local bladeLen = isHorn and 2.4 or 2.8

            -- Lower blade
            local lowerCf = baseCf * CFrame.new(0, bladeLen * 0.4, 0.2) * CFrame.Angles(math.rad(tilt), 0, 0)
            makePart(m, "DragonBladeL_" .. b, Vector3.new(0.26, bladeLen * 0.55, 0.06), lowerCf, Color3.fromRGB(50, 150, 75), Enum.Material.SmoothPlastic)

            -- Golden primary meridian vein running through leaf
            local veinM = lowerCf * CFrame.new(0, 0, 0.03)
            makePart(m, "MainVein_" .. b, Vector3.new(0.07, bladeLen * 0.52, 0.07), veinM, Color3.fromRGB(255, 205, 45), Enum.Material.Neon)

            -- Branching tributary veins
            local veinL = lowerCf * CFrame.new(-0.08, 0.1, 0.03) * CFrame.Angles(0, 0, math.rad(30))
            makePart(m, "SubVeinL_" .. b, Vector3.new(0.04, 0.35, 0.05), veinL, Color3.fromRGB(245, 185, 35), Enum.Material.Neon)
            local veinR = lowerCf * CFrame.new(0.08, -0.1, 0.03) * CFrame.Angles(0, 0, math.rad(-30))
            makePart(m, "SubVeinR_" .. b, Vector3.new(0.04, 0.35, 0.05), veinR, Color3.fromRGB(245, 185, 35), Enum.Material.Neon)

            -- Upper blade (curling outward like horn)
            local upperCf = lowerCf * CFrame.new(0, bladeLen * 0.35, 0) * CFrame.Angles(math.rad(bend), 0, 0) * CFrame.new(0, bladeLen * 0.35, 0)
            makePart(m, "DragonBladeU_" .. b, Vector3.new(0.18, bladeLen * 0.45, 0.05), upperCf, Color3.fromRGB(65, 175, 90), Enum.Material.SmoothPlastic)

            local tipCf = upperCf * CFrame.new(0, bladeLen * 0.3, 0) * CFrame.Angles(math.rad(bend * 0.5), 0, 0)
            makeWedge(m, "HornTip_" .. b, Vector3.new(0.12, 0.5, 0.04), tipCf, Color3.fromRGB(255, 215, 60), Enum.Material.Neon)
        end
        return m
    end

    -- ========================================================================
    -- 10. GHOST ORCHID (Medium: height ~3.4 studs)
    -- Dark black-green foliage, pale spectral orchid flowers, drooping serpentine petals & hanging tendrils
    -- ========================================================================
    builders["Ghost Orchid"] = function()
        local m = Instance.new("Model")
        m.Name = "Ghost Orchid"

        local root = makePart(m, "PlantRoot", Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, 0.7, 0), Color3.fromRGB(235, 230, 248), Enum.Material.SmoothPlastic)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 0.75, Color3.fromRGB(42, 40, 45))

        -- 1. DARK NEAR-BLACK BASAL FOLIAGE (Stark contrast to ghostly white flowers)
        for d = 1, 4 do
            local dAngle = math.rad((d - 1) * 90 + 25)
            local dCf = CFrame.new(0, 0.15, 0) * CFrame.Angles(0, dAngle, 0) * CFrame.new(0, 0.08, 0.45) * CFrame.Angles(math.rad(18), 0, 0)
            makePart(m, "DarkLeaf_" .. d, Vector3.new(0.38, 0.05, 0.65), dCf, Color3.fromRGB(28, 38, 30), Enum.Material.Slate)
        end

        -- 2. THIN WIRY GRAYISH-GREEN SERPENTINE STEM
        makePart(m, "GhostStem1", Vector3.new(0.09, 0.9, 0.09), CFrame.new(0, 0.55, 0), Color3.fromRGB(90, 115, 95), Enum.Material.SmoothPlastic)
        local stem2Cf = CFrame.new(0.12, 1.35, 0.10) * CFrame.Angles(math.rad(22), 0, math.rad(-15))
        makePart(m, "GhostStem2", Vector3.new(0.08, 0.8, 0.08), stem2Cf, Color3.fromRGB(105, 130, 110), Enum.Material.SmoothPlastic)

        -- 3. SPECTRAL ORCHID BLOSSOM (Ghostly silhouette with serpentine drooping tendrils)
        local blossomCenter = CFrame.new(0.26, 1.75, 0.22)

        -- Dorsal sepal (hooding over flower)
        local sepalCf = blossomCenter * CFrame.new(0, 0.32, -0.08) * CFrame.Angles(math.rad(-22), 0, 0)
        makePart(m, "DorsalSepal", Vector3.new(0.35, 0.65, 0.06), sepalCf, Color3.fromRGB(248, 246, 255), Enum.Material.Glass)

        -- 2 twisted lateral petals spreading like phantom wings
        local petalL = blossomCenter * CFrame.new(-0.28, 0.10, 0) * CFrame.Angles(0, math.rad(25), math.rad(40))
        makePart(m, "PhantomWingL", Vector3.new(0.24, 0.65, 0.05), petalL, Color3.fromRGB(235, 228, 252), Enum.Material.Glass)

        local petalR = blossomCenter * CFrame.new(0.28, 0.10, 0) * CFrame.Angles(0, math.rad(-25), math.rad(-40))
        makePart(m, "PhantomWingR", Vector3.new(0.24, 0.65, 0.05), petalR, Color3.fromRGB(235, 228, 252), Enum.Material.Glass)

        -- Eerie serpentine double-tail tendrils hanging straight downward
        local tendrilL = blossomCenter * CFrame.new(-0.16, -0.45, 0.08) * CFrame.Angles(math.rad(15), 0, math.rad(8))
        makePart(m, "GhostTendrilL", Vector3.new(0.06, 0.95, 0.06), tendrilL, Color3.fromRGB(215, 195, 245), Enum.Material.Neon)

        local tendrilR = blossomCenter * CFrame.new(0.16, -0.45, 0.08) * CFrame.Angles(math.rad(15), 0, math.rad(-8))
        makePart(m, "GhostTendrilR", Vector3.new(0.06, 0.95, 0.06), tendrilR, Color3.fromRGB(215, 195, 245), Enum.Material.Neon)

        -- Spectral violet central column / core
        makePart(m, "SpectralColumn", Vector3.new(0.18, 0.22, 0.18), blossomCenter * CFrame.new(0, 0.02, 0), Color3.fromRGB(180, 140, 235), Enum.Material.Neon, Enum.PartType.Ball)
        return m
    end

    -- ========================================================================
    -- 11. SPIRIT BAMBOO (Tall: height ~7.5 studs, width ~3.2 studs)
    -- Miniature grove of 4 segmented stalks with visible nodes, glowing spiritual rings, and horizontal leaf sprays
    -- ========================================================================
    builders["Spirit Bamboo"] = function()
        local m = Instance.new("Model")
        m.Name = "Spirit Bamboo"

        local root = makePart(m, "PlantRoot", Vector3.new(2.4, 3.5, 2.4), CFrame.new(0, 1.75, 0), Color3.fromRGB(60, 175, 95), Enum.Material.Wood)
        root.Transparency = 1
        m.PrimaryPart = root

        addMound(m, 1.3, Color3.fromRGB(55, 48, 36))

        -- Visible gnarled bamboo rhizome roots near soil
        for rh = 1, 5 do
            local rhAngle = math.rad((rh - 1) * 72 + 18)
            local rhCf = CFrame.new(0, 0.16, 0) * CFrame.Angles(0, rhAngle, 0) * CFrame.new(0.55, 0, 0) * CFrame.Angles(0, 0, math.rad(35))
            makePart(m, "Rhizome_" .. rh, Vector3.new(0.14, 0.65, 0.14), rhCf, Color3.fromRGB(65, 140, 80), Enum.Material.Wood, Enum.PartType.Cylinder)
        end

        -- 4 bamboo stalks of varying heights (creating an authentic miniature grove!)
        local culms = {
            { x = 0.0,   z = 0.0,   height = 7.2, diam = 0.36 },
            { x = -0.55, z = 0.35,  height = 5.6, diam = 0.30 },
            { x = 0.50,  z = -0.40, height = 6.2, diam = 0.32 },
            { x = 0.45,  z = 0.45,  height = 3.8, diam = 0.24 }, -- young bamboo shoot
        }

        for cIdx, c in ipairs(culms) do
            local numSegments = math.floor(c.height / 0.85)
            for seg = 1, numSegments do
                local segCenterY = (seg - 0.5) * 0.85
                local culmCf = CFrame.new(c.x, segCenterY, c.z)

                -- Bamboo internode culm segment (deep emerald)
                makePart(m, "Internode_" .. cIdx .. "_" .. seg, Vector3.new(c.diam, 0.78, c.diam), culmCf, Color3.fromRGB(55, 170, 90), Enum.Material.Wood, Enum.PartType.Cylinder)

                -- Luminous spiritual bamboo node ring
                local nodeY = seg * 0.85
                local nodeCf = CFrame.new(c.x, nodeY, c.z)
                makePart(m, "NodeRing_" .. cIdx .. "_" .. seg, Vector3.new(c.diam + 0.07, 0.09, c.diam + 0.07), nodeCf, Color3.fromRGB(195, 245, 165), Enum.Material.Neon, Enum.PartType.Cylinder)

                -- Horizontal branching bamboo leaf sprays at alternate nodes
                if seg > 1 and seg % 2 == 0 then
                    local branchAngle = math.rad((seg * 80) + (cIdx * 75))
                    local branchBaseCf = CFrame.new(c.x, nodeY, c.z) * CFrame.Angles(0, branchAngle, 0)

                    -- Delicate branchlet
                    local branchCf = branchBaseCf * CFrame.new(0, 0.08, 0.35) * CFrame.Angles(math.rad(12), 0, 0)
                    makePart(m, "Branch_" .. cIdx .. "_" .. seg, Vector3.new(0.06, 0.06, 0.45), branchCf, Color3.fromRGB(50, 145, 75), Enum.Material.SmoothPlastic)

                    -- 3 radiating slender lanceolate bamboo leaves
                    local leafCfC = branchCf * CFrame.new(0, 0.02, 0.38)
                    makePart(m, "BLeafC_" .. cIdx .. "_" .. seg, Vector3.new(0.24, 0.03, 0.75), leafCfC, Color3.fromRGB(80, 205, 115), Enum.Material.SmoothPlastic)

                    local leafCfL = branchCf * CFrame.new(-0.18, 0.02, 0.28) * CFrame.Angles(0, math.rad(28), 0)
                    makePart(m, "BLeafL_" .. cIdx .. "_" .. seg, Vector3.new(0.20, 0.03, 0.65), leafCfL, Color3.fromRGB(70, 190, 105), Enum.Material.SmoothPlastic)

                    local leafCfR = branchCf * CFrame.new(0.18, 0.02, 0.28) * CFrame.Angles(0, math.rad(-28), 0)
                    makePart(m, "BLeafR_" .. cIdx .. "_" .. seg, Vector3.new(0.20, 0.03, 0.65), leafCfR, Color3.fromRGB(70, 190, 105), Enum.Material.SmoothPlastic)
                end
            end
        end
        return m
    end

    -- ========================================================================
    -- ASSEMBLE ALL 11 TEMPLATES & DEPLOY
    -- ========================================================================
    local plantNames = {
        "Spirit Grass", "Ginseng Herb", "Ironleaf Herb", "Moonlight Grass",
        "Clearheart Flower", "Bloodroot", "Jade Lotus", "Hundred-Year Ginseng",
        "Dragon Vein Grass", "Ghost Orchid", "Spirit Bamboo"
    }

    local spacing = 5.5
    local startX = -((#plantNames - 1) * spacing) / 2
    local sampleY = 0

    local ray = Workspace:Raycast(Vector3.new(0, 50, 0), Vector3.new(0, -100, 0))
    if ray and ray.Position then
        sampleY = ray.Position.Y
    end

    local createdCount = 0
    for idx, name in ipairs(plantNames) do
        local builder = builders[name]
        if builder then
            local modelSS = builder()
            CollectionService:AddTag(modelSS, "HarvestablePlant")
            modelSS:SetAttribute("PlantName", name)

            -- Configure ProximityPrompt
            local primary = modelSS.PrimaryPart
            if primary then
                local prompt = Instance.new("ProximityPrompt")
                prompt.Name = "HarvestPrompt"
                prompt.ActionText = "Collect"
                prompt.ObjectText = name
                prompt.HoldDuration = 0.4
                prompt.MaxActivationDistance = 8.0
                prompt.RequiresLineOfSight = false
                prompt.Enabled = true
                prompt.Parent = primary
            end

            modelSS.Parent = ssTemplates

            local modelRS = modelSS:Clone()
            modelRS.Parent = rsTemplates

            -- Interactive sample row in Workspace.PlantTemplates
            local modelWS = modelSS:Clone()
            local posX = startX + (idx - 1) * spacing
            local samplePos = Vector3.new(posX, sampleY, 0)

            local groundRay = Workspace:Raycast(Vector3.new(posX, sampleY + 20, 0), Vector3.new(0, -50, 0))
            if groundRay and groundRay.Position then
                samplePos = groundRay.Position
            end

            local pivotCF = CFrame.new(samplePos)
            modelWS:PivotTo(pivotCF)
            modelWS:SetAttribute("OriginalSpawnCFrame", pivotCF)
            modelWS:SetAttribute("OriginalSpawnPosition", samplePos)
            modelWS:SetAttribute("CurrentSpawnPosition", samplePos)
            modelWS:SetAttribute("Harvested", false)
            modelWS.Parent = wsTemplates

            createdCount = createdCount + 1
        end
    end

    return string.format("Successfully built and deployed %d high-quality cultivation herb models!", createdCount)
    """

    ok, res = exec_code(lua_builder)
    print("Build herbs result:", ok, res)
    assert ok, f"Failed building herbs: {res}"

if __name__ == '__main__':
    build_herbs()

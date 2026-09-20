--!strict
-- generationId: fb3b3bcc-0f4a-446c-83e3-3376cc606a74
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local HeavenlyPagoda = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		WallColor: Color3?,
		RoofColor: Color3?,
		GoldColor: Color3?,
		StoneColor: Color3?,
		WoodColor: Color3?,
		BannerColor: Color3?,
	},
}
local startTime = 0
local timerThread : thread = task.spawn(function()
while true do
	if not script:IsDescendantOf(game) then
		startTime = 0
		return
	end
	if startTime > 0 then
		local elapsed = tick() - startTime
		print("[ProceduralModel] " .. script:GetFullName() .. " rendering... " .. string.format("%.0f", elapsed) .. " seconds")
	end
	task.wait(3)
end
end)
script.Destroying:Connect(function()
	task.cancel(timerThread)
end)

HeavenlyPagoda.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	-- local GP = require(script.Parent.GeometryPrimitives)
	-- local CSG = require(script.Parent.ConstructiveSolidGeometry)
	-- local SO = require(script.Parent.SmartObject)
	-- local MU = require(script.Parent.MathUtils)
	
	local model = GP.model("HeavenlyPagoda", nil)-- Fix orientation of the model
	model.WorldPivot = CFrame.identity
	
	
	-- == ATTRIBUTES ==
	local smartWidth = parameters.Size.X
	local smartHeight = parameters.Size.Y
	local smartDepth = parameters.Size.Z
	
	local colorWall = parameters.Attributes.WallColor or Color3.fromRGB(240, 245, 250)
	local colorRoof = parameters.Attributes.RoofColor or Color3.fromRGB(35, 50, 75)
	local colorGold = parameters.Attributes.GoldColor or Color3.fromRGB(255, 215, 0)
	local colorStone = parameters.Attributes.StoneColor or Color3.fromRGB(200, 205, 210)
	local colorWood = parameters.Attributes.WoodColor or Color3.fromRGB(60, 40, 30)
	local colorBanner = parameters.Attributes.BannerColor or Color3.fromRGB(40, 80, 160)
	
	local matWall = "SmoothPlastic"
	local matRoof = "Slate"
	local matGold = "Metal"
	local matStone = "Concrete"
	local matWood = "Wood"
	local matBanner = "Fabric"
	
	-- Procedural logic
	local storyHeight = 12
	local storyCount = math.max(2, math.floor(smartHeight / storyHeight))
	-- Distribute the height among the stories, reserving some for base and spire
	local actualStoryHeight = (smartHeight - 20 - 15) / storyCount
	if actualStoryHeight < 8 then actualStoryHeight = 8 end
	
	local coreWidth = smartWidth * 0.4
	local coreDepth = smartDepth * 0.4
	
	-- == HELPER FUNCTIONS ==
	
	-- Build a fence segment
	local function buildFence(name, parent, p1, p2, height)
	    local fenceGroup = GP.model(name, parent)
	    local length = (p2 - p1).Magnitude
	    if length < 0.1 then return end
	    
	    local dir = (p2 - p1).Unit
	    local count = math.floor(length / 2)
	    
	    -- Bottom and top rails
	    local right = dir:Cross(Vector3.yAxis)
	    local w = 0.4
	    
	    local p1Offset = p1 + Vector3.new(0, 0.5, 0)
	    local p2Offset = p2 + Vector3.new(0, 0.5, 0)
	    
	    GP.cylinder("RailBottom", p1Offset, p2Offset, 0.2, colorStone, matStone, fenceGroup)
	    GP.cylinder("RailTop", p1Offset + Vector3.new(0, height - 1, 0), p2Offset + Vector3.new(0, height - 1, 0), 0.25, colorWood, matWood, fenceGroup)
	    
	    -- Posts
	    MU.linearArray(p1, p2, count + 1, function(pos, i)
	        GP.axisAlignedBlockFromCorners("Post_"..i,
	            pos - Vector3.new((w/2) - 2e-3, 0, w/2),
	            pos + Vector3.new((w/2) + 2e-3, height, w/2),
	            colorStone, matStone, fenceGroup) -- zf-prevention: vector3_component
	    end)
	    
	    return fenceGroup
	end
	
	-- Build a sweeping roof (approximated with a pyramid and corner spikes)
	local function buildRoof(name, parent, center, width, depth, height, overhang)
	    local roofGroup = GP.model(name, parent)
	    
	    local rw = width + overhang * 2
	    local rd = depth + overhang * 2
	    
	    local c1 = center + Vector3.new(-rw/2, 0, -rd/2)
	    local c2 = center + Vector3.new(rw/2, 0, rd/2)
	    local apex = center + Vector3.new(0, height, 0)
	    
	    -- Main pyramid
	    GP.pyramid("MainRoof", c1, c2, apex, colorRoof, matRoof, roofGroup)
	    
	    -- Corner sweeps (cones angling upwards)
	    local corners = {
	        center + Vector3.new(-rw/2, 0, -rd/2),
	        center + Vector3.new(rw/2, 0, -rd/2),
	        center + Vector3.new(-rw/2, 0, rd/2),
	        center + Vector3.new(rw/2, 0, rd/2)
	    }
	    
	    for i, corner in ipairs(corners) do
	        local dirOut = (corner - center).Unit
	        dirOut = Vector3.new(dirOut.X, 0, dirOut.Z).Unit
	        
	        -- Start slightly inside, point outward and upward
	        local startP = corner - dirOut * 2
	        local endP = corner + dirOut * 3 + Vector3.new(0, 2, 0)
	        
	        GP.cone("Sweep_"..i, startP, endP, 0.8, colorGold, matGold, roofGroup)
	        
	        -- Hanging banner from the sweep tip
	        local bW = 1.0
	        local bH = 4.0
	        local bThick = 0.1
	        
	        local bModel = GP.model("Banner_"..i, roofGroup)
	        local topCenter = endP - Vector3.new(0, 0.5, 0)
	        
	        -- Align banner facing outward
	        local right = dirOut:Cross(Vector3.yAxis).Unit
	        
	        local p1 = topCenter - right * (bW/2)
	        local p2 = topCenter + right * (bW/2)
	        local p3 = p2 - Vector3.new(0, bH, 0)
	        local p4 = p1 - Vector3.new(0, bH, 0)
	        
	        GP.quadFromFourPoints("Fabric", p1, p2, p3, p4, bThick, dirOut, colorBanner, matBanner, bModel)
	        
	        -- Gold trim
	        GP.cylinder("TrimTop", p1, p2, 0.15, colorGold, matGold, bModel)
	        GP.cylinder("TrimBot", p4, p3, 0.15, colorGold, matGold, bModel)
	    end
	    
	    return roofGroup
	end
	
	-- Build a single pagoda story
	local function buildStory(name, parent, center, width, depth, height, isBase)
	    local storyGroup = GP.model(name, parent)
	    
	    -- Shell (walls)
	    local wallThick = 1.0
	    local w1 = center + Vector3.new(-width/2, 0, -depth/2)
	    local w2 = center + Vector3.new(width/2, height, depth/2)
	    
	    local outerBox = GP.axisAlignedBlockFromCorners("OuterWall", w1, w2, colorWall, matWall, workspace)
	    local i1 = w1 + Vector3.new(wallThick, -0.1, wallThick)
	    local i2 = w2 - Vector3.new(wallThick, 0.1, wallThick)
	    local innerBox = GP.axisAlignedBlockFromCorners("InnerWall", i1, i2, colorWall, matWall, workspace)
	    
	    local shell = CSG.subtract(name.."Shell", outerBox, {innerBox})
	    if shell then shell.Parent = storyGroup end
	    innerBox:Destroy()
	    
	    -- Floor
	    if not isBase then
	        GP.axisAlignedBlockFromCorners("Floor",
	            center + Vector3.new(-width/2, 0, -depth/2),
	            center + Vector3.new((width/2) + 2e-3, 1.0 + 2e-3, (depth/2) + 2e-3),
	            colorWood, matWood, storyGroup) -- zf-prevention: vector3_component
	            
	        -- Balcony around
	        local balcW = width + 6
	        local balcD = depth + 6
	        GP.axisAlignedBlockFromCorners("BalconyBase",
	            center + Vector3.new(-balcW/2, 0 - 4e-3, -balcD/2),
	            center + Vector3.new(balcW/2, 1.0, balcD/2),
	            colorStone, matStone, storyGroup) -- zf-prevention: vector3_component
	            
	        -- Balcony Fences
	        local bY = center.Y + 1.0
	        local fH = 2.5
	        local cFL = Vector3.new(balcW/2, bY, -balcD/2)
	        local cFR = Vector3.new(-balcW/2, bY, -balcD/2)
	        local cBL = Vector3.new(balcW/2, bY, balcD/2)
	        local cBR = Vector3.new(-balcW/2, bY, balcD/2)
	        
	        buildFence("FenceF", storyGroup, cFL, cFR, fH)
	        buildFence("FenceB", storyGroup, cBR, cBL, fH)
	        buildFence("FenceL", storyGroup, cBL, cFL, fH)
	        buildFence("FenceR", storyGroup, cFR, cBR, fH)
	    end
	    
	    -- Corner Pillars
	    local pRad = 1.2
	    local corners = {
	        center + Vector3.new(-width/2 - pRad*0.3, 0, -depth/2 - pRad*0.3),
	        center + Vector3.new(width/2 + pRad*0.3, 0, -depth/2 - pRad*0.3),
	        center + Vector3.new(-width/2 - pRad*0.3, 0, depth/2 + pRad*0.3),
	        center + Vector3.new(width/2 + pRad*0.3, 0, depth/2 + pRad*0.3)
	    }
	    
	    for i, c in ipairs(corners) do
	        GP.cylinder("Pillar_"..i, c, c + Vector3.new(0, height + 2e-3, 0), pRad, colorWood, matWood, storyGroup) -- zf-prevention: vector3_component
	        -- Gold bands
	        GP.cylinder("BandB_"..i, c + Vector3.new(0, 1, 0), c + Vector3.new(0, 2, 0), pRad + 0.1, colorGold, matGold, storyGroup)
	        GP.cylinder("BandT_"..i, c + Vector3.new(0, height-2, 0), c + Vector3.new(0, height-1, 0), pRad + 0.1, colorGold, matGold, storyGroup)
	    end
	    
	    -- Doors / Entrances (Front and Back)
	    -- Instead of full CSG cuts for simplicity, add a dark doorway frame
	    local doorW = 8
	    local doorH = 10
	    local dZ = depth/2 + 0.1
	    
	    -- Front (-Z)
	    local doorGroupF = GP.model("DoorFront", storyGroup)
	    GP.axisAlignedBlockFromCorners("DoorF",
	        center + Vector3.new(-doorW/2, 0 - 2e-3, -dZ),
	        center + Vector3.new(doorW/2, doorH, -dZ + 0.2),
	        colorWood, matWood, doorGroupF) -- zf-prevention: vector3_component
	    -- Frame F
	    GP.axisAlignedBlockFromCorners("FrameF",
	        center + Vector3.new(-doorW/2 - 1, 0, -dZ - 0.2),
	        center + Vector3.new(doorW/2 + 1, doorH + 1, -dZ + 0.1),
	        colorGold, matGold, doorGroupF)
	        
	    return storyGroup
	end
	
	-- == CONSTRUCTION ==
	
	-- 1. Foundation Base
	local foundation = GP.model("Foundation", model)
	local baseY = 0
	local baseH1 = 6
	local baseH2 = 8
	
	-- Lower terrace
	GP.axisAlignedBlockFromCorners("TerraceLower",
	    Vector3.new(-smartWidth/2, baseY, -smartDepth/2),
	    Vector3.new(smartWidth/2, baseY + baseH1, smartDepth/2),
	    colorStone, matStone, foundation)
	baseY = baseY + baseH1
	
	-- Upper terrace
	local t2W = coreWidth + 40
	local t2D = coreDepth + 40
	GP.axisAlignedBlockFromCorners("TerraceUpper",
	    Vector3.new(-t2W/2, baseY, -t2D/2),
	    Vector3.new(t2W/2, baseY + baseH2, t2D/2),
	    colorStone, matStone, foundation)
	baseY = baseY + baseH2
	
	-- Grand Stairs Front
	local stairW = 20
	local stairD = 30
	local stairZStart = -t2D/2
	local stairZEnd = stairZStart - stairD
	
	local stairs = GP.model("Stairs", foundation)
	GP.ramp("MainStair",
	    Vector3.new(0, baseY, stairZStart), -- Top middle
	    Vector3.new(0, 0, stairZEnd),     -- Bottom middle
	    stairW, colorStone, matStone, stairs)
	    
	-- Stair side walls
	GP.axisAlignedBlockFromCorners("StairWallL",
	    Vector3.new(stairW/2, 0, stairZEnd),
	    Vector3.new(stairW/2 + 2, baseY, stairZStart),
	    colorStone, matStone, stairs)
	GP.axisAlignedBlockFromCorners("StairWallR",
	    Vector3.new(-stairW/2 - 2, 0, stairZEnd),
	    Vector3.new(-stairW/2, baseY, stairZStart),
	    colorStone, matStone, stairs)
	
	-- 2. Main Pagoda
	local mainPagoda = GP.model("MainPagoda", model)
	local currentY = baseY
	local currentW = coreWidth
	local currentD = coreDepth
	
	for i = 1, storyCount do
	    local isBase = (i == 1)
	    local sH = isBase and (actualStoryHeight + 4) or actualStoryHeight
	    
	    -- Story Body
	    buildStory("Story_"..i, mainPagoda, Vector3.new(0, currentY, 0), currentW, currentD, sH, isBase)
	    currentY = currentY + sH
	    
	    -- Roof
	    local rH = 8
	    local overhang = 6
	    buildRoof("Roof_"..i, mainPagoda, Vector3.new(0, currentY, 0), currentW, currentD, rH, overhang)
	    currentY = currentY + 1.0 -- Slight embed
	    
	    -- Shrink next story
	    currentW = currentW * 0.85
	    currentD = currentD * 0.85
	end
	
	-- 3. Top Spire & Halo
	local spireGroup = GP.model("Spire", mainPagoda)
	local spY = currentY + 7 -- Start slightly inside last roof
	local spRad = 2.0
	local spH = 25
	
	GP.cylinder("SpireBase", Vector3.new(0, spY, 0), Vector3.new(0, spY + spH*0.3, 0), spRad, colorGold, matGold, spireGroup)
	GP.cone("SpireTip", Vector3.new(0, spY + spH*0.3, 0), Vector3.new(0, spY + spH, 0), spRad, colorGold, matGold, spireGroup)
	
	-- Halo ring
	local haloY = spY + spH * 0.5
	local haloRad = 15
	local haloThick = 0.8
	GP.hollowCylinder("Halo",
	    Vector3.new(0, haloY - haloThick/2, 0),
	    Vector3.new(0, haloY + haloThick/2, 0),
	    haloRad, 2.0, colorGold, matGold, spireGroup)
	
	-- 4. Side Pavilions
	local function buildPavilion(name, parent, center)
	    local pav = GP.model(name, parent)
	    local pW = 20
	    local pD = 20
	    local pY = baseY
	    local pH = 15
	    
	    -- Base block
	    GP.axisAlignedBlockFromCorners("Base",
	        center + Vector3.new(-pW/2 - 2, 0, -pD/2 - 2),
	        center + Vector3.new(pW/2 + 2, pY, pD/2 + 2),
	        colorStone, matStone, pav)
	        
	    -- Story
	    buildStory("Body", pav, center + Vector3.new(0, pY, 0), pW, pD, pH, true)
	    
	    -- Roof
	    buildRoof("Roof", pav, center + Vector3.new(0, pY + pH, 0), pW, pD, 6, 4)
	    
	    -- Mini Spire
	    local mY = pY + pH + 5
	    GP.cone("Spire", Vector3.new(center.X, mY, center.Z), Vector3.new(center.X, mY + 10, center.Z), 1.0, colorGold, matGold, pav)
	end
	
	-- Place pavilions on the sides (Left is +X, Right is -X)
	local pavDistX = smartWidth/2 - 15
	local pavDistZ = 0
	buildPavilion("PavilionLeft", model, Vector3.new(pavDistX, 0, pavDistZ))
	buildPavilion("PavilionRight", model, Vector3.new(-pavDistX, 0, pavDistZ))
	
	-- Connect pavilions with bridges to the upper terrace
	local function buildBridge(name, parent, startP, endP, width)
	    local bridge = GP.model(name, parent)
	    local thick = 2.0
	    
	    -- Main deck
	    GP.strutFromTwoPoints("Deck", startP, endP + Vector3.new(2e-3, 0, 0), width, thick, colorStone, matStone, bridge) -- zf-prevention: vector3_component
	    
	    -- Railings
	    local dir = (endP - startP).Unit
	    local right = dir:Cross(Vector3.yAxis).Unit
	    
	    local r1S = startP + right * (width/2 - 0.5) + Vector3.new(0, thick/2, 0)
	    local r1E = endP + right * (width/2 - 0.5) + Vector3.new(0, thick/2, 0)
	    buildFence("FenceR", bridge, r1S, r1E, 3)
	    
	    local r2S = startP - right * (width/2 - 0.5) + Vector3.new(0, thick/2, 0)
	    local r2E = endP - right * (width/2 - 0.5) + Vector3.new(0, thick/2, 0)
	    buildFence("FenceL", bridge, r2S, r2E, 3)
	end
	
	local bStartL = Vector3.new(t2W/2, baseY, 0)
	local bEndL = Vector3.new(pavDistX - 12, baseY, 0)
	buildBridge("BridgeLeft", model, bStartL, bEndL, 10)
	
	local bStartR = Vector3.new(-t2W/2, baseY, 0)
	local bEndR = Vector3.new(-pavDistX + 12, baseY, 0)
	buildBridge("BridgeRight", model, bStartR, bEndR, 10)
	
	-- 5. Floating Accents (Islands/Rocks around the base)
	local islands = GP.model("FloatingIslands", model)
	local islandData = {
	    {pos = Vector3.new(smartWidth/2 + 20, -10, -30), r = 8, h = 15},
	    {pos = Vector3.new(-smartWidth/2 - 25, -5, -40), r = 12, h = 20},
	    {pos = Vector3.new(smartWidth/2 + 10, -15, 40), r = 10, h = 18},
	    {pos = Vector3.new(-smartWidth/2 - 15, -20, 30), r = 9, h = 16}
	}
	
	for i, data in ipairs(islandData) do
	    local ig = GP.model("Island_"..i, islands)
	    -- Top flat grassy area
	    GP.cylinder("Top", data.pos, data.pos + Vector3.new(0, 2, 0), data.r, Color3.fromRGB(80, 120, 60), "Grass", ig)
	    -- Rocky bottom taper (cone downwards)
	    GP.cone("Bottom", data.pos, data.pos - Vector3.new(0, data.h, 0), data.r, colorStone, matStone, ig)
	end
	
	
	model.Parent = targetContainer
	-- reposition
	for _, part in targetContainer:GetDescendants() do
		if part:IsA("BasePart") then
			part.CFrame -= Vector3.yAxis * parameters.Size.Y / 2
		end
	end
	for _, model in targetContainer:GetDescendants() do
		if model:IsA("Model") then
			model.WorldPivot -= Vector3.yAxis * parameters.Size.Y / 2
		end
	end

	-- Stop timer when generation completes
	local timeElapsed = tick() - startTime
	startTime = 0
	if timeElapsed > 3 and script:IsDescendantOf(game) then
		print("[ProceduralModel] " .. script:GetFullName() .. " rendering completed")
	end

end

return HeavenlyPagoda

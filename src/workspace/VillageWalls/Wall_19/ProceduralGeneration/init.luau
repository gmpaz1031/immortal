--!strict
-- generationId: 068e9aa1-ddee-4f8e-a306-3ffcc28d0dd2
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local ChineseCultivationWall = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		StoneColor: Color3?,
		RoofColor: Color3?,
		GoldColor: Color3?,
		RuneColor: Color3?,
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

ChineseCultivationWall.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	local model = GP.model("ChineseCultivationWall", nil)-- Fix orientation of the model
	model.WorldPivot = CFrame.identity
	
	
	-- == ATTRIBUTES ==
	local totalWidth = parameters.Size.X
	local totalHeight = parameters.Size.Y
	local totalDepth = parameters.Size.Z
	
	local stoneColor = parameters.Attributes.StoneColor or Color3.fromRGB(220, 225, 230)
	local roofColor = parameters.Attributes.RoofColor or Color3.fromRGB(45, 140, 75)
	local goldColor = parameters.Attributes.GoldColor or Color3.fromRGB(235, 195, 50)
	local runeColor = parameters.Attributes.RuneColor or Color3.fromRGB(255, 215, 0)
	
	local stoneMat = "Concrete"
	local roofMat = "SmoothPlastic"
	local goldMat = "Metal"
	
	-- == TOP-LEVEL MODELS (Required exactly as named) ==
	local base = GP.model("base", model)
	local pillars = GP.model("pillars", model)
	local crenellations = GP.model("crenellations", model)
	
	-- == DERIVED METRICS ==
	local halfW = totalWidth / 2
	local halfD = totalDepth / 2
	
	local plinthHeight = totalHeight * 0.1
	local pillarWidth = totalWidth * 0.08
	local pillarDepth = totalDepth * 1.2
	local halfPillarW = pillarWidth / 2
	
	-- Define Pillar X positions (Viewer's Right to Left: -X to +X)
	-- 4 pillars creating 3 bays.
	local innerPillarOffset = totalWidth * 0.18
	local outerPillarOffset = halfW - halfPillarW
	
	local pX_FarRight = -outerPillarOffset
	local pX_MidRight = -innerPillarOffset
	local pX_MidLeft  = innerPillarOffset
	local pX_FarLeft  = outerPillarOffset
	
	local pillarXs = {pX_FarRight, pX_MidRight, pX_MidLeft, pX_FarLeft}
	
	local wallHeightSide = totalHeight * 0.65
	local wallHeightCenter = totalHeight * 0.75
	
	-- == 1. BASE (Plinth & Wall Panels) ==
	
	-- Continuous Bottom Plinth
	local plinthBaseHeight = plinthHeight * 0.5
	GP.axisAlignedBlockFromCorners("PlinthBase",
	    Vector3.new(halfW, 0, halfD * 1.1),
	    Vector3.new(-halfW, plinthBaseHeight, -halfD * 1.1),
	    stoneColor, stoneMat, base)
	
	GP.axisAlignedBlockFromCorners("PlinthTop",
	    Vector3.new(halfW - 0.2, plinthBaseHeight, halfD * 1.05),
	    Vector3.new(-halfW + 0.2, plinthHeight, -halfD * 1.05),
	    stoneColor, stoneMat, base)
	
	-- Helper function to build a wall panel between two x-coordinates
	local function buildWallPanel(name, xRight, xLeft, height)
	    local panelW = (xLeft - xRight) - pillarWidth
	    local centerX = (xLeft + xRight) / 2
	    local panelSub = GP.model(name, base)
	    
	    -- Main solid wall
	    GP.axisAlignedBlockFromCorners("MainWall",
	        Vector3.new(centerX + panelW/2, plinthHeight, halfD * 0.8),
	        Vector3.new(centerX - panelW/2, height, -halfD * 0.8),
	        stoneColor, "Marble", panelSub)
	        
	    -- Upper Decorative Recessed Frame Section
	    local frameHeight = totalHeight * 0.15
	    local frameBottom = height - frameHeight - 0.5
	    local frameTop = height - 0.5
	    
	    local innerFrameW = panelW * 0.85
	    
	    -- Inset background for the frame (slightly protruding from main wall for depth)
	    GP.axisAlignedBlockFromCorners("FrameBg_Front",
	        Vector3.new(centerX + innerFrameW/2, frameBottom, -halfD * 0.8),
	        Vector3.new(centerX - innerFrameW/2, frameTop, -halfD * 0.8 - 0.1),
	        stoneColor, stoneMat, panelSub)
	        
	    GP.axisAlignedBlockFromCorners("FrameBg_Back",
	        Vector3.new(centerX + innerFrameW/2, frameBottom, halfD * 0.8),
	        Vector3.new(centerX - innerFrameW/2, frameTop, halfD * 0.8 + 0.1),
	        stoneColor, stoneMat, panelSub)
	        
	    -- Gold Rune/Decoration in the center of the frame
	    local runeW = innerFrameW * 0.6
	    local runeH = frameHeight * 0.4
	    local runeCenterY = (frameBottom + frameTop) / 2
	    
	    -- Front Rune
	    GP.axisAlignedBlockFromCorners("RuneMain_Front",
	        Vector3.new(centerX + runeW/2, runeCenterY - runeH/2, -halfD * 0.8 - 0.1),
	        Vector3.new(centerX - runeW/2, runeCenterY + runeH/2, -halfD * 0.8 - 0.15),
	        runeColor, goldMat, panelSub)
	    GP.sphere("RuneDot1_Front", Vector3.new(centerX + runeW/2 + 0.5, runeCenterY, -halfD * 0.8 - 0.15), 0.3, runeColor, goldMat, panelSub)
	    GP.sphere("RuneDot2_Front", Vector3.new(centerX - runeW/2 - 0.5, runeCenterY, -halfD * 0.8 - 0.15), 0.3, runeColor, goldMat, panelSub)
	
	    -- Back Rune
	    GP.axisAlignedBlockFromCorners("RuneMain_Back",
	        Vector3.new(centerX + runeW/2, runeCenterY - runeH/2, halfD * 0.8 + 0.1),
	        Vector3.new(centerX - runeW/2, runeCenterY + runeH/2, halfD * 0.8 + 0.15),
	        runeColor, goldMat, panelSub)
	    GP.sphere("RuneDot1_Back", Vector3.new(centerX + runeW/2 + 0.5, runeCenterY, halfD * 0.8 + 0.15), 0.3, runeColor, goldMat, panelSub)
	    GP.sphere("RuneDot2_Back", Vector3.new(centerX - runeW/2 - 0.5, runeCenterY, halfD * 0.8 + 0.15), 0.3, runeColor, goldMat, panelSub)
	end
	
	-- Build the three panels
	buildWallPanel("RightPanel", pX_FarRight, pX_MidRight, wallHeightSide)
	buildWallPanel("CenterPanel", pX_MidRight, pX_MidLeft, wallHeightCenter)
	buildWallPanel("LeftPanel", pX_MidLeft, pX_FarLeft, wallHeightSide)
	
	
	-- == 2. PILLARS ==
	
	local function buildPillar(name, x, height, hasOuterScroll, isLeftSide)
	    local pillarSub = GP.model(name, pillars)
	    
	    -- Pillar Base Block
	    local pBaseHeight = totalHeight * 0.15
	    GP.axisAlignedBlockFromCorners("BaseBlock",
	        Vector3.new(x + halfPillarW * 1.2, plinthHeight, pillarDepth/2 * 1.1),
	        Vector3.new(x - halfPillarW * 1.2, plinthHeight + pBaseHeight, -pillarDepth/2 * 1.1),
	        stoneColor, stoneMat, pillarSub)
	        
	    -- Main Shaft
	    GP.axisAlignedBlockFromCorners("Shaft",
	        Vector3.new(x + halfPillarW, plinthHeight + pBaseHeight, pillarDepth/2),
	        Vector3.new(x - halfPillarW, height, -pillarDepth/2),
	        stoneColor, stoneMat, pillarSub)
	        
	    -- Top Cap
	    GP.axisAlignedBlockFromCorners("TopCap",
	        Vector3.new(x + halfPillarW * 1.3, height, pillarDepth/2 * 1.2),
	        Vector3.new(x - halfPillarW * 1.3, height + 0.8, -pillarDepth/2 * 1.2),
	        stoneColor, stoneMat, pillarSub)
	        
	    -- Front and Back Decorative Medallions
	    local medY = height - 2.5
	    GP.cylinder("MedallionFront", 
	        Vector3.new(x, medY, -pillarDepth/2), 
	        Vector3.new(x, medY, -pillarDepth/2 - 0.2), 
	        halfPillarW * 0.7, goldColor, goldMat, pillarSub)
	    GP.cylinder("MedallionBack", 
	        Vector3.new(x, medY, pillarDepth/2), 
	        Vector3.new(x, medY, pillarDepth/2 + 0.2), 
	        halfPillarW * 0.7, goldColor, goldMat, pillarSub)
	
	    -- Decorative Side Scroll (Buttress)
	    if hasOuterScroll then
	        local scrollDir = isLeftSide and 1 or -1 -- 1 for +X, -1 for -X
	        local sWidth = pillarWidth * 1.2
	        local sHeight = totalHeight * 0.25
	        local sX = x + (halfPillarW + sWidth/2) * scrollDir
	        
	        -- The flat backing of the scroll
	        GP.axisAlignedBlockFromCorners("ScrollBacking",
	            Vector3.new(sX + (sWidth/2)*scrollDir, plinthHeight, pillarDepth/2 * 0.6),
	            Vector3.new(sX - (sWidth/2)*scrollDir, plinthHeight + sHeight * 0.5, -pillarDepth/2 * 0.6),
	            stoneColor, stoneMat, pillarSub)
	            
	        -- The curved part using a tube along a bezier
	        local p0 = Vector3.new(x + halfPillarW * scrollDir, plinthHeight + sHeight, 0)
	        local p1 = Vector3.new(sX + (sWidth*0.5) * scrollDir, plinthHeight + sHeight * 0.8, 0)
	        local p2 = Vector3.new(sX + (sWidth*0.8) * scrollDir, plinthHeight + sHeight * 0.2, 0)
	        local p3 = Vector3.new(sX + (sWidth*0.2) * scrollDir, plinthHeight + sHeight * 0.1, 0)
	        
	        -- Front Scroll
	        local frontPts = {}
	        local backPts = {}
	        local segments = 8
	        for i = 0, segments do
	            local t = i / segments
	            local pt = MU.bezier(t, p0, p1, p2, p3)
	            table.insert(frontPts, pt + Vector3.new(0, 0, -pillarDepth/2 * 0.7))
	            table.insert(backPts, pt + Vector3.new(0, 0, pillarDepth/2 * 0.7))
	        end
	        
	        GP.tube("ScrollFront", frontPts, 0.4, stoneColor, stoneMat, pillarSub)
	        GP.tube("ScrollBack", backPts, 0.4, stoneColor, stoneMat, pillarSub)
	    end
	end
	
	-- Create the 4 pillars
	buildPillar("PillarFarRight", pX_FarRight, wallHeightSide + 1, true, false)
	buildPillar("PillarMidRight", pX_MidRight, wallHeightCenter + 1, false, false)
	buildPillar("PillarMidLeft", pX_MidLeft, wallHeightCenter + 1, false, true)
	buildPillar("PillarFarLeft", pX_FarLeft, wallHeightSide + 1, true, true)
	
	
	-- == 3. CRENELLATIONS (Roofs & Corbels) ==
	
	local function buildRoofSection(name, xCenter, roofW, baseY, isCenter)
	    local roofSub = GP.model(name, crenellations)
	    
	    local rDepth = isCenter and (totalDepth * 2.2) or (totalDepth * 1.8)
	    local rHeight = isCenter and (totalHeight * 0.25) or (totalHeight * 0.2)
	    local halfRW = roofW / 2
	    local halfRD = rDepth / 2
	    
	    -- 1. Corbel Brackets (Dougong)
	    local corbelZoneY = baseY
	    local corbelH = 1.2
	    local roofBaseY = baseY + corbelH
	    
	    -- Horizontal tie beam
	    GP.axisAlignedBlockFromCorners("TieBeam",
	        Vector3.new(xCenter + halfRW, corbelZoneY, halfD * 0.9),
	        Vector3.new(xCenter - halfRW, corbelZoneY + 0.6, -halfD * 0.9),
	        stoneColor, stoneMat, roofSub)
	        
	    -- Array of small corbel blocks
	    local numCorbels = math.floor(roofW / 2)
	    local corbelSpacing = roofW / (numCorbels + 1)
	    for i = 1, numCorbels do
	        local cx = (xCenter - halfRW) + i * corbelSpacing
	        -- Lower bracket
	        GP.axisAlignedBlockFromCorners("CorbelLow_"..i,
	            Vector3.new(cx + 0.3, corbelZoneY + 0.6, halfD * 1.2),
	            Vector3.new(cx - 0.3, corbelZoneY + 0.9, -halfD * 1.2),
	            stoneColor, stoneMat, roofSub)
	        -- Upper bracket (wider)
	        GP.axisAlignedBlockFromCorners("CorbelUp_"..i,
	            Vector3.new(cx + 0.4, corbelZoneY + 0.9, halfD * 1.5),
	            Vector3.new(cx - 0.4, corbelZoneY + 1.2, -halfD * 1.5),
	            stoneColor, stoneMat, roofSub)
	    end
	    
	    -- 2. Main Roof Mass
	    local roofTopY = roofBaseY + rHeight
	    
	    -- Lower roof tier (eaves base)
	    GP.axisAlignedBlockFromCorners("RoofTier1",
	        Vector3.new(xCenter + halfRW * 1.05, roofBaseY, halfRD * 0.9),
	        Vector3.new(xCenter - halfRW * 1.05, roofBaseY + 0.5, -halfRD * 0.9),
	        roofColor, roofMat, roofSub)
	        
	    -- Main angled roof (using a wedge-like shape, approximated with a block and top ridge)
	    -- To simulate the slope, we use a central block and side angles.
	    GP.axisAlignedBlockFromCorners("RoofCore",
	        Vector3.new(xCenter + halfRW * 0.8, roofBaseY + 0.5, halfRD * 0.7),
	        Vector3.new(xCenter - halfRW * 0.8, roofTopY - 0.5, -halfRD * 0.7),
	        roofColor, roofMat, roofSub)
	        
	    -- Ridge beam
	    GP.cylinder("RidgeBeam",
	        Vector3.new(xCenter + halfRW * 0.9, roofTopY, 0),
	        Vector3.new(xCenter - halfRW * 0.9, roofTopY, 0),
	        0.6, roofColor, roofMat, roofSub)
	        
	    -- Ridge Ends (ornaments)
	    GP.sphere("RidgeEndRight", Vector3.new(xCenter - halfRW * 0.9, roofTopY, 0), 1.0, roofColor, roofMat, roofSub)
	    GP.sphere("RidgeEndLeft", Vector3.new(xCenter + halfRW * 0.9, roofTopY, 0), 1.0, roofColor, roofMat, roofSub)
	
	    -- 3. Sweeping Curved Eaves (Corners)
	    local eaveOut = 2.0
	    local eaveUp = 1.5
	    
	    local function drawEave(eName, startX, startZ, dirX, dirZ)
	        local e0 = Vector3.new(startX, roofBaseY + 0.2, startZ)
	        local e3 = Vector3.new(startX + eaveOut * dirX, roofBaseY + eaveUp, startZ + eaveOut * dirZ)
	        local e1 = e0 + Vector3.new(dirX * eaveOut * 0.5, 0, dirZ * eaveOut * 0.5)
	        local e2 = e3 + Vector3.new(-dirX * eaveOut * 0.2, -eaveUp * 0.5, -dirZ * eaveOut * 0.2)
	        
	        local pts = MU.sampleBezierPoints(e0, e1, e2, e3, 6)
	        GP.tube(eName, pts, 0.4, roofColor, roofMat, roofSub)
	        -- Tip ornament
	        GP.cone(eName.."_Tip", e3, e3 + Vector3.new(dirX*0.5, 0.5, dirZ*0.5), 0.5, roofColor, roofMat, roofSub)
	    end
	    
	    -- Four corners of the roof
	    drawEave("Eave_FR", xCenter - halfRW * 1.05, -halfRD * 0.9, -1, -1)
	    drawEave("Eave_FL", xCenter + halfRW * 1.05, -halfRD * 0.9, 1, -1)
	    drawEave("Eave_BR", xCenter - halfRW * 1.05, halfRD * 0.9, -1, 1)
	    drawEave("Eave_BL", xCenter + halfRW * 1.05, halfRD * 0.9, 1, 1)
	end
	
	-- Calculate widths for roofs to span across pillars
	local centerRoofW = (pX_MidLeft - pX_MidRight) + pillarWidth * 1.5
	local sideRoofW = (pX_FarLeft - pX_MidLeft) + pillarWidth * 1.2
	
	-- Right Roof (Viewer's right, -X)
	local rightRoofCenterX = (pX_FarRight + pX_MidRight) / 2
	buildRoofSection("RightRoof", rightRoofCenterX, sideRoofW, wallHeightSide + 1.8, false)
	
	-- Left Roof (Viewer's left, +X)
	local leftRoofCenterX = (pX_FarLeft + pX_MidLeft) / 2
	buildRoofSection("LeftRoof", leftRoofCenterX, sideRoofW, wallHeightSide + 1.8, false)
	
	-- Center Roof (Highest and widest)
	local centerRoofCenterX = 0
	buildRoofSection("CenterRoof", centerRoofCenterX, centerRoofW, wallHeightCenter + 1.8, true)
	
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

return ChineseCultivationWall

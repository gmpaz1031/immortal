--!strict
-- generationId: 005cc6e5-4dee-453b-ad73-4a45a74ed368
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local RuinedHouse = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		DestructionLevel: number?,
		DebrisAmount: number?,
		ColorStucco: Color3?,
		ColorStone: Color3?,
		ColorStoneDark: Color3?,
		ColorWood: Color3?,
		ColorWoodDark: Color3?,
		ColorRoof: Color3?,
		ColorGlass: Color3?,
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

RuinedHouse.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	local house = GP.model("RuinedHouse", nil)-- Fix orientation of the model
	house.WorldPivot = CFrame.identity
	
	
	-- REQUIRED Smart Dimensions
	local smartWidth = parameters.Size.X
	local smartHeight = parameters.Size.Y
	local smartDepth = parameters.Size.Z
	
	-- Semantic Parameters
	local destructionLevel = parameters.Attributes.DestructionLevel or 0.7 -- Used to size the CSG cut
	local debrisAmount = parameters.Attributes.DebrisAmount or 5
	
	local colStucco = parameters.Attributes.ColorStucco or Color3.fromRGB(225, 215, 195)
	local colStone = parameters.Attributes.ColorStone or Color3.fromRGB(140, 145, 150)
	local colStoneDark = parameters.Attributes.ColorStoneDark or Color3.fromRGB(110, 115, 120)
	local colWood = parameters.Attributes.ColorWood or Color3.fromRGB(160, 120, 80)
	local colWoodDark = parameters.Attributes.ColorWoodDark or Color3.fromRGB(110, 80, 50)
	local colRoof = parameters.Attributes.ColorRoof or Color3.fromRGB(180, 85, 65)
	local colGlass = parameters.Attributes.ColorGlass or Color3.fromRGB(40, 30, 25)
	
	local matStucco = "Concrete"
	local matStone = "Slate"
	local matWood = "WoodPlanks"
	local matBeam = "Wood"
	local matRoof = "Brick"
	
	-- Scaling factors
	local scaleX = smartWidth / 10
	local scaleY = smartHeight / 10
	local scaleZ = smartDepth / 10
	
	-- Base layout dimensions
	local hw = 9 * scaleX
	local hd = 7 * scaleZ
	local groundY = 0
	local foundY = 2 * scaleY
	local floor2Y = 10 * scaleY
	local wallTopY = 18 * scaleY
	local peakY = 25 * scaleY
	local wallT = 0.8 * scaleX
	
	local frontZ = -hd
	local backZ = hd
	local leftX = hw    -- Viewer Left (+X)
	local rightX = -hw  -- Viewer Right (-X)
	
	-- TOP-LEVEL MODELS (Strict requirement)
	local wallsGroup = GP.model("walls", house)
	local windowsGroup = GP.model("windows", house)
	local doorGroup = GP.model("door", house)
	local roofGroup = GP.model("roof", house)
	
	-- ==========================================
	-- 1. WALLS & FOUNDATION
	-- ==========================================
	
	-- Foundation Slab
	GP.axisAlignedBlockFromCorners("Foundation", 
	    Vector3.new(leftX + 0.5*scaleX, groundY - 2e-3, frontZ - 0.5*scaleZ), 
	    Vector3.new(rightX - 0.5*scaleX, foundY, backZ + 0.5*scaleZ), 
	    colStone, matStone, wallsGroup) -- zf-prevention: vector3_component
	
	-- Foundation Stones Details
	for x = rightX, leftX, 2.5 * scaleX do
	    GP.roundedBox("FoundStoneF_"..x, Vector3.new(x, foundY*0.5, frontZ - 0.6*scaleZ), Vector3.new(2.2*scaleX, 1.8*scaleY, 1.5*scaleZ), 0.4*scaleX, colStoneDark, matStone, wallsGroup)
	    GP.roundedBox("FoundStoneB_"..x, Vector3.new(x, foundY*0.5, backZ + 0.6*scaleZ), Vector3.new(2.2*scaleX, 1.8*scaleY, 1.5*scaleZ), 0.4*scaleX, colStoneDark, matStone, wallsGroup)
	end
	
	-- Raw Stucco Walls
	local rawFront = GP.axisAlignedBlockFromCorners("RawFront", Vector3.new(leftX, foundY, frontZ), Vector3.new(rightX, wallTopY, frontZ + wallT), colStucco, matStucco, workspace, 0)
	local rawBack = GP.axisAlignedBlockFromCorners("RawBack", Vector3.new(leftX, foundY, backZ - wallT), Vector3.new(rightX, wallTopY, backZ), colStucco, matStucco, workspace, 0)
	local rawLeft = GP.axisAlignedBlockFromCorners("RawLeft", Vector3.new(leftX, foundY, frontZ), Vector3.new(leftX - wallT, wallTopY, backZ), colStucco, matStucco, workspace, 0)
	local rawRight = GP.axisAlignedBlockFromCorners("RawRight", Vector3.new(rightX + wallT, foundY, frontZ), Vector3.new(rightX, wallTopY, backZ), colStucco, matStucco, workspace, 0)
	
	-- Raw Gables
	local gableFront = GP.triangularPrismFromThreePoints("GableF", Vector3.new(leftX, wallTopY, frontZ), Vector3.new(rightX, wallTopY, frontZ), Vector3.new(0, peakY, frontZ), wallT, Vector3.zAxis, colStucco, matStucco, workspace, 0)
	local gableBack = GP.triangularPrismFromThreePoints("GableB", Vector3.new(rightX, wallTopY, backZ), Vector3.new(leftX, wallTopY, backZ), Vector3.new(0, peakY, backZ), wallT, Vector3.new(0,0,-1), colStucco, matStucco, workspace, 0)
	
	-- Destruction Cutters
	local cutSize = 12 * destructionLevel * math.max(scaleX, scaleY)
	local cutters = {}
	-- Main corner chunk missing (+X, +Y, -Z)
	table.insert(cutters, GP.sphere("Cut1", Vector3.new(leftX - 2*scaleX, floor2Y + 4*scaleY, frontZ + 1*scaleZ), cutSize, Color3.new(1,0,0), "Neon", workspace, 0))
	table.insert(cutters, GP.axisAlignedBlockFromCorners("Cut2", Vector3.new(leftX + 2*scaleX, floor2Y, frontZ - 2*scaleZ), Vector3.new(leftX - 6*scaleX, peakY + 2*scaleY, frontZ + 4*scaleZ), Color3.new(1,0,0), "Neon", workspace, 0))
	
	-- Window/Door Cutters
	local doorX = -2 * scaleX
	local doorW = 3.5 * scaleX
	local doorH = 6 * scaleY
	table.insert(cutters, GP.axisAlignedBlockFromCorners("DoorCut", Vector3.new(doorX + doorW/2, foundY, frontZ - 2), Vector3.new(doorX - doorW/2, foundY + doorH, frontZ + 2), Color3.new(1,0,0), "Neon", workspace, 0))
	
	local winX = -6.5 * scaleX
	local winW = 2.5 * scaleX
	local winH = 3.5 * scaleY
	local win1Y = foundY + 1.5 * scaleY
	local win2Y = floor2Y + 1.5 * scaleY
	table.insert(cutters, GP.axisAlignedBlockFromCorners("Win1Cut", Vector3.new(winX + winW/2, win1Y, frontZ - 2), Vector3.new(winX - winW/2, win1Y + winH, frontZ + 2), Color3.new(1,0,0), "Neon", workspace, 0))
	table.insert(cutters, GP.axisAlignedBlockFromCorners("Win2Cut", Vector3.new(winX + winW/2, win2Y, frontZ - 2), Vector3.new(winX - winW/2, win2Y + winH, frontZ + 2), Color3.new(1,0,0), "Neon", workspace, 0))
	
	-- Apply CSG
	local wF = CSG.subtract("WallFront", rawFront, cutters)
	wF.Parent = wallsGroup
	local wB = CSG.subtract("WallBack", rawBack, cutters)
	wB.Parent = wallsGroup
	local wL = CSG.subtract("WallLeft", rawLeft, cutters)
	wL.Parent = wallsGroup
	local wR = CSG.subtract("WallRight", rawRight, cutters)
	wR.Parent = wallsGroup
	local gF = CSG.subtract("GableFront", gableFront, cutters)
	gF.Parent = wallsGroup
	local gB = CSG.subtract("GableBack", gableBack, cutters)
	gB.Parent = wallsGroup
	
	for _, c in ipairs(cutters) do c:Destroy() end
	
	-- Chimney (On the left / +X)
	local chimX = leftX + 1.5 * scaleX
	local chimZ = 0
	local chimW = 3.5 * scaleX
	local chimD = 3.5 * scaleZ
	local chimTop = peakY + 4 * scaleY
	
	GP.axisAlignedBlockFromCorners("ChimneyCore", Vector3.new(chimX + chimW/2, groundY, chimZ - chimD/2), Vector3.new(chimX - chimW/2, chimTop, chimZ + chimD/2), colStucco, matStucco, wallsGroup)
	-- Chimney Stones
	for y = groundY, chimTop - 1, 2*scaleY do
	    GP.roundedBox("CStone_"..math.floor(y), Vector3.new(chimX + (math.random()-0.5)*0.5, y + 1, chimZ + (math.random()-0.5)*0.5), Vector3.new(chimW + 0.6, 1.8*scaleY, chimD + 0.6), 0.3, colStone, matStone, wallsGroup)
	end
	GP.axisAlignedBlockFromCorners("ChimneyCap", Vector3.new(chimX + chimW/2 + 0.5, chimTop, chimZ - chimD/2 - 0.5), Vector3.new(chimX - chimW/2 - 0.5, chimTop + 1*scaleY, chimZ + chimD/2 + 0.5), colStoneDark, matStone, wallsGroup)
	
	-- Interior Floor & Beams
	GP.axisAlignedBlockFromCorners("Floor2", Vector3.new(leftX - wallT, floor2Y, frontZ + wallT), Vector3.new(rightX + wallT, floor2Y + 0.5*scaleY, backZ - wallT), colWoodDark, matWood, wallsGroup)
	
	-- Floor Divider Beam (Front)
	GP.axisAlignedBlockFromCorners("FrontDividerBeam", Vector3.new(leftX + 0.5, floor2Y - 0.2*scaleY, frontZ - 0.2*scaleZ), Vector3.new(rightX - 0.5, floor2Y + 0.5*scaleY, frontZ + 0.5*scaleZ), colWood, matBeam, wallsGroup)
	
	-- Balcony
	local balcX = leftX - 1.5 * scaleX
	local balcW = 6 * scaleX
	local balcD = 2.5 * scaleZ
	GP.axisAlignedBlockFromCorners("BalconyFloor", Vector3.new(balcX, floor2Y - 2e-3, frontZ - balcD), Vector3.new(balcX - balcW, floor2Y + 0.4*scaleY, frontZ + 0.1), colWood, matWood, wallsGroup) -- zf-prevention: vector3_component
	GP.strutFromTwoPoints("BalcBracket1", Vector3.new(balcX - 0.5*scaleX, floor2Y - 3*scaleY, frontZ + 0.2), Vector3.new(balcX - 0.5*scaleX, floor2Y, frontZ - balcD + 0.2), 0.4*scaleX, 0.4*scaleY, colWoodDark, matBeam, wallsGroup)
	GP.strutFromTwoPoints("BalcBracket2", Vector3.new(balcX - balcW + 0.5*scaleX, floor2Y - 3*scaleY, frontZ + 0.2), Vector3.new(balcX - balcW + 0.5*scaleX, floor2Y, frontZ - balcD + 0.2), 0.4*scaleX, 0.4*scaleY, colWoodDark, matBeam, wallsGroup)
	
	-- Balcony Railing
	local rTopY = floor2Y + 2.5*scaleY
	GP.axisAlignedBlockFromCorners("RailTopFront", Vector3.new(balcX + 0.2, rTopY, frontZ - balcD - 0.2), Vector3.new(balcX - balcW - 0.2, rTopY + 0.4*scaleY, frontZ - balcD + 0.2), colWood, matBeam, wallsGroup)
	GP.axisAlignedBlockFromCorners("RailTopSide", Vector3.new(balcX - balcW - 0.2, rTopY, frontZ - balcD - 0.2), Vector3.new(balcX - balcW + 0.2, rTopY + 0.4*scaleY, frontZ + 0.2), colWood, matBeam, wallsGroup)
	local balcPosts = {balcX - 0.2, balcX - balcW/2, balcX - balcW + 0.2}
	for i, px in ipairs(balcPosts) do
	    GP.axisAlignedBlockFromCorners("RailPost_"..i, Vector3.new(px + 0.3*scaleX, floor2Y, frontZ - balcD - 0.2), Vector3.new(px - 0.3*scaleX, rTopY + 0.8*scaleY, frontZ - balcD + 0.3), colWood, matBeam, wallsGroup)
	end
	
	-- Debris
	for i = 1, debrisAmount do
	    local dx = leftX - math.random() * (hw * 1.5)
	    local dz = frontZ - math.random() * (4 * scaleZ)
	    GP.axisAlignedBlockFromCorners("Debris_"..i, Vector3.new(dx + 0.6, groundY - 2e-3, dz - 0.6), Vector3.new(dx - 0.6, groundY + 0.3, dz + 0.6), colRoof, matRoof, wallsGroup) -- zf-prevention: vector3_component
	end
	
	-- ==========================================
	-- 2. DOOR
	-- ==========================================
	local dFrameT = 0.4 * scaleX
	local dZ = frontZ
	-- Stone Door Frame
	GP.axisAlignedBlockFromCorners("DFrameT", Vector3.new(doorX + doorW/2 + dFrameT, foundY + doorH, dZ - dFrameT), Vector3.new(doorX - doorW/2 - dFrameT, foundY + doorH + dFrameT, (dZ + wallT) + 2e-3), colStoneDark, matStone, doorGroup) -- zf-prevention: vector3_component
	GP.axisAlignedBlockFromCorners("DFrameL", Vector3.new(doorX + doorW/2 + dFrameT, foundY, dZ - dFrameT), Vector3.new(doorX + doorW/2, foundY + doorH, (dZ + wallT) + 2e-3), colStoneDark, matStone, doorGroup) -- zf-prevention: vector3_component
	GP.axisAlignedBlockFromCorners("DFrameR", Vector3.new(doorX - doorW/2, foundY, dZ - dFrameT), Vector3.new(doorX - doorW/2 - dFrameT, foundY + doorH, (dZ + wallT) + 2e-3), colStoneDark, matStone, doorGroup) -- zf-prevention: vector3_component
	-- Door Panel
	GP.axisAlignedBlockFromCorners("DPanel", Vector3.new(doorX + doorW/2 - 0.1, foundY, dZ + 0.2), Vector3.new(doorX - doorW/2 + 0.1, foundY + doorH - 0.1, dZ + 0.5), colWood, matWood, doorGroup)
	GP.sphere("DKnob", Vector3.new(doorX + doorW/2 - 0.6*scaleX, foundY + doorH/2, dZ + 0.1), 0.2*scaleX, Color3.new(0.8,0.7,0.2), "Metal", doorGroup)
	-- Step
	GP.axisAlignedBlockFromCorners("DStep", Vector3.new(doorX + doorW/2, groundY, dZ - 1.5*scaleZ), Vector3.new(doorX - doorW/2, foundY, dZ), colStone, matStone, doorGroup)
	
	-- ==========================================
	-- 3. WINDOWS
	-- ==========================================
	local function buildWindow(name, x, y, w, h)
	    local wGrp = GP.model(name, windowsGroup)
	    local fT = 0.3 * scaleX
	    local z = frontZ
	    -- Stone Frame
	    GP.axisAlignedBlockFromCorners("WF_T", Vector3.new(x + w/2 + fT, y + h, z - fT), Vector3.new(x - w/2 - fT, y + h + fT, (z + wallT) + 2e-3), colStoneDark, matStone, wGrp) -- zf-prevention: vector3_component
	    GP.axisAlignedBlockFromCorners("WF_B", Vector3.new(x + w/2 + fT, y - fT, z - fT), Vector3.new(x - w/2 - fT, y, (z + wallT) + 2e-3), colStoneDark, matStone, wGrp) -- zf-prevention: vector3_component
	    GP.axisAlignedBlockFromCorners("WF_L", Vector3.new(x + w/2 + fT, y, z - fT), Vector3.new(x + w/2, y + h, (z + wallT) + 2e-3), colStoneDark, matStone, wGrp) -- zf-prevention: vector3_component
	    GP.axisAlignedBlockFromCorners("WF_R", Vector3.new(x - w/2, y, z - fT), Vector3.new(x - w/2 - fT, y + h, (z + wallT) + 2e-3), colStoneDark, matStone, wGrp) -- zf-prevention: vector3_component
	    -- Sill
	    GP.axisAlignedBlockFromCorners("WSill", Vector3.new(x + w/2 + fT + 0.2, y - fT - 0.2, z - fT - 0.3), Vector3.new(x - w/2 - fT - 0.2, y - fT, z + 0.2), colStone, matStone, wGrp)
	    -- Mullions
	    GP.axisAlignedBlockFromCorners("WMullV", Vector3.new(x + 0.1, y, z + 0.1), Vector3.new(x - 0.1, y + h, z + 0.3), colWoodDark, matBeam, wGrp)
	    GP.axisAlignedBlockFromCorners("WMullH", Vector3.new(x + w/2, y + h/2 - 0.1, z + 0.1), Vector3.new(x - w/2, y + h/2 + 0.1, z + 0.3), colWoodDark, matBeam, wGrp)
	    -- Glass (Dark)
	    GP.axisAlignedBlockFromCorners("WGlass", Vector3.new(x + w/2, y, z + 0.2), Vector3.new(x - w/2, y + h, z + 0.25), colGlass, "SmoothPlastic", wGrp, 0.2)
	end
	
	buildWindow("WinGround", winX, win1Y, winW, winH)
	buildWindow("WinUpper", winX, win2Y, winW, winH)
	
	
	-- ==========================================
	-- 4. ROOF
	-- ==========================================
	local roofT = 0.6 * scaleY
	local overhang = 1.2 * scaleZ
	local roofFront = frontZ - overhang
	local roofBack = backZ + overhang
	local eaveY = wallTopY - 0.5*scaleY
	
	-- Ridge Beam
	GP.axisAlignedBlockFromCorners("RidgeBeam", Vector3.new(leftX + overhang, peakY - roofT, -0.4*scaleZ), Vector3.new(rightX - overhang, peakY, 0.4*scaleZ), colWoodDark, matBeam, roofGroup)
	
	-- Exposed Rafters on Left side (+X)
	for x = leftX, 0, -2.5 * scaleX do
	    -- Front Rafter
	    GP.strutFromTwoPoints("RafterF_"..x, Vector3.new(x, peakY - roofT/2, 0), Vector3.new(x, eaveY, roofFront), 0.3*scaleX, 0.5*scaleY, colWoodDark, matBeam, roofGroup)
	    -- Back Rafter
	    GP.strutFromTwoPoints("RafterB_"..x, Vector3.new(x, peakY - roofT/2, 0), Vector3.new(x, eaveY, roofBack), 0.3*scaleX, 0.5*scaleY, colWoodDark, matBeam, roofGroup)
	end
	
	-- Horizontal Purlins (broken on left)
	GP.axisAlignedBlockFromCorners("PurlinF1", Vector3.new(leftX - 1*scaleX, peakY - 3*scaleY, frontZ/2), Vector3.new(0, peakY - 2.6*scaleY, frontZ/2 + 0.4*scaleZ), colWood, matBeam, roofGroup)
	GP.axisAlignedBlockFromCorners("PurlinF2", Vector3.new(leftX - 3*scaleX, peakY - 6*scaleY, frontZ - 2e-3), Vector3.new(0 + 2e-3, peakY - 5.6*scaleY, frontZ + 0.4*scaleZ), colWood, matBeam, roofGroup) -- zf-prevention: vector3_component
	
	-- Intact Roof Slabs on Right side (-X)
	-- Front Slope
	GP.quadFromFourPoints("RoofSlabRightFront", 
	    Vector3.new(0, eaveY, roofFront), 
	    Vector3.new(rightX - overhang, eaveY, roofFront), 
	    Vector3.new(rightX - overhang, peakY, 0), 
	    Vector3.new(0, peakY, 0), 
	    roofT, Vector3.yAxis, colRoof, matRoof, roofGroup)
	
	-- Back Slope (Mostly intact across the whole back, but let's break the left part a bit)
	GP.quadFromFourPoints("RoofSlabBack", 
	    Vector3.new(leftX - 2*scaleX, eaveY, roofBack), 
	    Vector3.new(rightX - overhang, eaveY, roofBack), 
	    Vector3.new(rightX - overhang, peakY, 0), 
	    Vector3.new(leftX - 2*scaleX, peakY, 0), 
	    roofT, Vector3.yAxis, colRoof, matRoof, roofGroup)
	
	-- Add some scattered roof tiles on the surviving beams
	GP.quadFromFourPoints("Tile1", Vector3.new(leftX - 1.5*scaleX, peakY - 2*scaleY, -1.5*scaleZ), Vector3.new(leftX - 3.5*scaleX, peakY - 2*scaleY, -1.5*scaleZ), Vector3.new(leftX - 3.5*scaleX, peakY, 0), Vector3.new(leftX - 1.5*scaleX, peakY, 0), roofT*0.5, Vector3.yAxis, colRoof, matRoof, roofGroup)
	
	-- Roof Edge Trim (Fascia) Right side
	GP.strutFromTwoPoints("FasciaRightFront", Vector3.new(rightX - overhang, peakY + 0.1, 0), Vector3.new(rightX - overhang, eaveY - 0.2, roofFront - 0.1), 0.4*scaleX, 0.8*scaleY, colWoodDark, matBeam, roofGroup)
	GP.strutFromTwoPoints("FasciaRightBack", Vector3.new(rightX - overhang, peakY + 0.1, 0), Vector3.new(rightX - overhang, eaveY - 0.2, roofBack + 0.1), 0.4*scaleX, 0.8*scaleY, colWoodDark, matBeam, roofGroup)
	
	house.Parent = targetContainer
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

return RuinedHouse

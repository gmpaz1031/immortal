--!strict
-- generationId: 7150c475-ea2a-48b0-92d8-1f5b60bbd1fa
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local RuinedInn = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		ColorPlaster: Color3?,
		ColorTimber: Color3?,
		ColorDarkTimber: Color3?,
		ColorBurnt: Color3?,
		ColorFoundation: Color3?,
		ColorRoof: Color3?,
		ColorInterior: Color3?,
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

RuinedInn.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	local myModel = GP.model("RuinedInn", nil)-- Fix orientation of the model
	myModel.WorldPivot = CFrame.identity
	
	
	-- REQUIRED SMART DIMENSIONS
	local sw = parameters.Size.X
	local sh = parameters.Size.Y
	local sd = parameters.Size.Z
	
	-- SEMANTIC PARAMETERS
	local colPlaster = parameters.Attributes.ColorPlaster or Color3.fromRGB(235, 225, 195)
	local colTimber = parameters.Attributes.ColorTimber or Color3.fromRGB(120, 85, 60)
	local colDarkTimber = parameters.Attributes.ColorDarkTimber or Color3.fromRGB(80, 55, 40)
	local colBurnt = parameters.Attributes.ColorBurnt or Color3.fromRGB(45, 40, 40)
	local colFoundation = parameters.Attributes.ColorFoundation or Color3.fromRGB(110, 115, 120)
	local colRoof = parameters.Attributes.ColorRoof or Color3.fromRGB(70, 65, 75)
	local colInterior = parameters.Attributes.ColorInterior or Color3.fromRGB(50, 45, 40)
	
	-- REQUIRED TOP-LEVEL GROUPS
	local wallsGrp = GP.model("walls", myModel)
	local windowsGrp = GP.model("windows", myModel)
	local doorGrp = GP.model("door", myModel)
	local roofGrp = GP.model("roof", myModel)
	
	-- LAYOUT VARS
	local halfW = sw / 2
	local halfD = sd / 2
	local leftX = halfW   -- Viewer's Left (+X)
	local rightX = -halfW -- Viewer's Right (-X)
	local frontZ = -halfD
	local backZ = halfD
	
	local foundH = sh * 0.08
	local storyH = (sh * 0.65 - foundH) / 2
	local wallTopY = foundH + storyH * 2
	local peakY = sh
	local wallT = 0.8
	
	-- ==========================================
	-- 1. WALLS & FOUNDATION
	-- ==========================================
	
	-- Foundation Base
	GP.axisAlignedBlockFromCorners("Foundation", 
	    Vector3.new(rightX - 0.2, 0, frontZ - 0.2), 
	    Vector3.new(leftX + 0.2, foundH, backZ + 0.2), 
	    colFoundation, "Slate", wallsGrp)
	
	-- Base Wall CSG
	local csgTemp = GP.model("CSGTemp", nil)
	
	local rawWall = GP.axisAlignedBlockFromCorners("RawWall",
	    Vector3.new(rightX, foundH, frontZ),
	    Vector3.new(leftX, wallTopY, backZ),
	    colPlaster, "Concrete", csgTemp)
	
	-- Cutters
	local cutters = {}
	
	-- Hollow Interior
	local innerCut = GP.axisAlignedBlockFromCorners("InnerCut",
	    Vector3.new(rightX + wallT, foundH, frontZ + wallT),
	    Vector3.new(leftX - wallT, wallTopY + 1, backZ - wallT),
	    Color3.new(1,0,0), "Neon", csgTemp)
	table.insert(cutters, innerCut)
	
	-- Door Cutout
	local doorW, doorH = sw * 0.25, storyH * 0.7
	local doorX = 0
	local doorCut = GP.axisAlignedBlockFromCorners("DoorCut",
	    Vector3.new(doorX - doorW/2, foundH, frontZ - 1),
	    Vector3.new(doorX + doorW/2, foundH + doorH, frontZ + wallT + 1),
	    Color3.new(1,0,0), "Neon", csgTemp)
	table.insert(cutters, doorCut)
	
	-- Window Cutout
	local winW, winH = sw * 0.2, storyH * 0.5
	local winY = foundH + storyH + storyH * 0.2
	local winCut = GP.axisAlignedBlockFromCorners("WinCut",
	    Vector3.new(doorX - winW/2, winY, frontZ - 1),
	    Vector3.new(doorX + winW/2, winY + winH, frontZ + wallT + 1),
	    Color3.new(1,0,0), "Neon", csgTemp)
	table.insert(cutters, winCut)
	
	-- Ruin Cutouts (Massive collapse on -X side)
	local ruin1 = GP.sphere("Ruin1", Vector3.new(rightX + 1, wallTopY + 1, frontZ + 2), sw * 0.45, Color3.new(1,0,0), "Neon", csgTemp)
	local ruin2 = GP.sphere("Ruin2", Vector3.new(rightX - 1, wallTopY - storyH*0.4, frontZ + halfD), sw * 0.35, Color3.new(1,0,0), "Neon", csgTemp)
	local ruin3 = GP.sphere("Ruin3", Vector3.new(rightX + 3, wallTopY, backZ), sw * 0.4, Color3.new(1,0,0), "Neon", csgTemp)
	-- Additional random holes
	local hole1 = GP.sphere("Hole1", Vector3.new(leftX - 1.5, foundH + storyH*1.2, frontZ), 1.2, Color3.new(1,0,0), "Neon", csgTemp)
	local hole2 = GP.sphere("Hole2", Vector3.new(rightX + 2.5, foundH + storyH*0.5, frontZ), 1.8, Color3.new(1,0,0), "Neon", csgTemp)
	
	table.insert(cutters, ruin1)
	table.insert(cutters, ruin2)
	table.insert(cutters, ruin3)
	table.insert(cutters, hole1)
	table.insert(cutters, hole2)
	
	local finalWalls = CSG.subtract("MainWalls", rawWall, cutters)
	finalWalls.Parent = wallsGrp
	
	-- Interior Backing (Darkened interior box)
	GP.axisAlignedBlockFromCorners("InteriorBacking",
	    Vector3.new(rightX + wallT + 0.1, foundH, frontZ + wallT + 0.1),
	    Vector3.new(leftX - wallT - 0.1, wallTopY - storyH*0.2, backZ - wallT - 0.1),
	    colInterior, "Wood", wallsGrp)
	
	for _, c in ipairs(cutters) do c:Destroy() end
	rawWall:Destroy()
	csgTemp:Destroy()
	
	-- Timber Framing (Intact on +X, broken on -X)
	local tT = 0.4 -- Timber thickness
	-- Vertical Corners
	GP.axisAlignedBlockFromCorners("TimberFL", Vector3.new(leftX, foundH, frontZ), Vector3.new(leftX + tT, wallTopY, frontZ - tT), colTimber, "Wood", wallsGrp)
	GP.axisAlignedBlockFromCorners("TimberBL", Vector3.new(leftX, foundH, backZ), Vector3.new(leftX + tT, wallTopY, backZ + tT), colTimber, "Wood", wallsGrp)
	-- Broken Right Corners
	GP.axisAlignedBlockFromCorners("TimberFR_Broken", Vector3.new(rightX - tT, foundH, frontZ), Vector3.new(rightX, foundH + storyH*0.8, frontZ - tT), colTimber, "Wood", wallsGrp)
	GP.axisAlignedBlockFromCorners("TimberBR_Broken", Vector3.new(rightX - tT, foundH, backZ), Vector3.new(rightX, foundH + storyH*1.2, backZ + tT), colTimber, "Wood", wallsGrp)
	
	-- Horizontal Bands
	local band1Y = foundH + storyH
	GP.axisAlignedBlockFromCorners("Band1_Front", Vector3.new(rightX + 1.5, band1Y, frontZ), Vector3.new(leftX + tT, band1Y + tT, frontZ - tT), colTimber, "Wood", wallsGrp)
	GP.axisAlignedBlockFromCorners("Band1_SideL", Vector3.new(leftX, band1Y, frontZ), Vector3.new(leftX + tT, band1Y + tT, backZ), colTimber, "Wood", wallsGrp)
	
	local band2Y = wallTopY
	GP.axisAlignedBlockFromCorners("Band2_Front_Broken", Vector3.new(0, band2Y, frontZ), Vector3.new(leftX + tT, band2Y + tT, frontZ - tT), colTimber, "Wood", wallsGrp)
	GP.axisAlignedBlockFromCorners("Band2_SideL", Vector3.new(leftX, band2Y, frontZ), Vector3.new(leftX + tT, band2Y + tT, backZ), colTimber, "Wood", wallsGrp)
	
	-- Chimney on Left (+X)
	local chimW = 2.5
	local chimX = leftX + 0.2
	local chimZ = backZ - chimW - 1
	local chimTopY = peakY + 2
	GP.axisAlignedBlockFromCorners("ChimneyBase", Vector3.new(chimX, foundH, chimZ), Vector3.new(chimX + chimW, wallTopY, chimZ + chimW), colPlaster, "Concrete", wallsGrp)
	GP.axisAlignedBlockFromCorners("ChimneyStack", Vector3.new(chimX + 0.2, wallTopY, chimZ + 0.2), Vector3.new(chimX + chimW - 0.2, chimTopY, chimZ + chimW - 0.2), colPlaster, "Concrete", wallsGrp)
	GP.axisAlignedBlockFromCorners("ChimneyCap", Vector3.new(chimX, chimTopY, chimZ), Vector3.new(chimX + chimW, chimTopY + 0.5, chimZ + chimW), colTimber, "Wood", wallsGrp)
	GP.axisAlignedBlockFromCorners("ChimneyBurnt", Vector3.new(chimX + 0.4, chimTopY + 0.5, chimZ + 0.4), Vector3.new(chimX + chimW - 0.4, chimTopY + 1.5, chimZ + chimW - 0.4), colBurnt, "Wood", wallsGrp)
	
	-- Signpost on Left (+X)
	local signX = leftX + 1.5
	local signZ = frontZ - 1.5
	GP.cylinder("SignPost", Vector3.new(signX, 0, signZ), Vector3.new(signX, foundH + storyH*0.8, signZ), 0.3, colTimber, "Wood", wallsGrp)
	GP.axisAlignedBlockFromCorners("SignArm", Vector3.new(signX - 0.2, foundH + storyH*0.6, signZ - 0.2), Vector3.new(signX + 3.5, foundH + storyH*0.6 + 0.4, signZ + 0.2), colTimber, "Wood", wallsGrp)
	-- Sign Boards
	GP.axisAlignedBlockFromCorners("SignBoard1", Vector3.new(signX + 0.5, foundH + storyH*0.3, signZ - 0.25), Vector3.new(signX + 3.2, foundH + storyH*0.55, signZ + 0.25), colTimber, "Wood", wallsGrp)
	GP.axisAlignedBlockFromCorners("SignBoard2_Broken", Vector3.new(signX + 0.7, foundH + storyH*0.1, signZ - 0.25), Vector3.new(signX + 2.8, foundH + storyH*0.28, signZ + 0.25), colTimber, "Wood", wallsGrp)
	
	-- Rubble at Base
	GP.axisAlignedBlockFromCorners("Rubble1", Vector3.new(rightX - 2, 0, frontZ - 1), Vector3.new(rightX + 1, 1.5, frontZ + 2), colFoundation, "Slate", wallsGrp)
	GP.axisAlignedBlockFromCorners("Rubble2", Vector3.new(rightX - 0.5, 0 - 2e-3, frontZ - 2), Vector3.new(rightX + 2.5, 0.8, frontZ + 0), colTimber, "Wood", wallsGrp) -- zf-prevention: vector3_component
	GP.axisAlignedBlockFromCorners("Rubble3", Vector3.new(rightX + 3, 0, frontZ - 1.5), Vector3.new(rightX + 4.5, 0.5, frontZ - 0.5), colBurnt, "Wood", wallsGrp)
	GP.cylinder("Barrel", Vector3.new(leftX + 2.5, 0.5, frontZ - 0.5), Vector3.new(leftX + 2.5, 2.5, frontZ - 0.5), 0.8, colDarkTimber, "WoodPlanks", wallsGrp)
	
	-- ==========================================
	-- 2. DOOR
	-- ==========================================
	local dFrameT = 0.3
	-- Frame
	GP.axisAlignedBlockFromCorners("DoorFrameL", Vector3.new(doorX + doorW/2, foundH, frontZ - 0.2), Vector3.new(doorX + doorW/2 + dFrameT, foundH + doorH, frontZ + wallT + 0.2), colTimber, "Wood", doorGrp)
	GP.axisAlignedBlockFromCorners("DoorFrameR", Vector3.new(doorX - doorW/2 - dFrameT, foundH, frontZ - 0.2), Vector3.new(doorX - doorW/2, foundH + doorH, frontZ + wallT + 0.2), colTimber, "Wood", doorGrp)
	GP.axisAlignedBlockFromCorners("DoorFrameT", Vector3.new(doorX - doorW/2 - dFrameT, foundH + doorH, frontZ - 0.2), Vector3.new(doorX + doorW/2 + dFrameT, foundH + doorH + dFrameT, frontZ + wallT + 0.2), colTimber, "Wood", doorGrp)
	-- Door Panel
	GP.axisAlignedBlockFromCorners("DoorPanel", Vector3.new(doorX - doorW/2 + 0.1, foundH, frontZ + 0.2), Vector3.new(doorX + doorW/2 - 0.1, foundH + doorH - 0.1, frontZ + 0.6), colDarkTimber, "WoodPlanks", doorGrp)
	-- Details
	GP.sphere("DoorKnob", Vector3.new(doorX - doorW/2 + 0.4, foundH + doorH/2, frontZ + 0.1), 0.15, Color3.new(0.2,0.2,0.2), "Metal", doorGrp)
	GP.axisAlignedBlockFromCorners("DoorStep", Vector3.new(doorX - doorW/2, 0, frontZ - 1.2), Vector3.new(doorX + doorW/2, foundH, frontZ), colFoundation, "Slate", doorGrp)
	
	-- ==========================================
	-- 3. WINDOWS
	-- ==========================================
	local wFrameT = 0.3
	GP.axisAlignedBlockFromCorners("WinFrameL", Vector3.new(doorX + winW/2, winY, frontZ - 0.3), Vector3.new(doorX + winW/2 + wFrameT, winY + winH, frontZ + wallT + 0.3), colTimber, "Wood", windowsGrp)
	GP.axisAlignedBlockFromCorners("WinFrameR", Vector3.new(doorX - winW/2 - wFrameT, winY, frontZ - 0.3), Vector3.new(doorX - winW/2, winY + winH, frontZ + wallT + 0.3), colTimber, "Wood", windowsGrp)
	GP.axisAlignedBlockFromCorners("WinFrameB", Vector3.new(doorX - winW/2 - wFrameT - 0.2, winY - wFrameT, frontZ - 0.4), Vector3.new(doorX + winW/2 + wFrameT + 0.2, winY, frontZ + wallT + 0.4), colTimber, "Wood", windowsGrp)
	GP.axisAlignedBlockFromCorners("WinFrameT", Vector3.new(doorX - winW/2 - wFrameT, winY + winH, frontZ - 0.3), Vector3.new(doorX + winW/2 + wFrameT, winY + winH + wFrameT, frontZ + wallT + 0.3), colTimber, "Wood", windowsGrp)
	-- Awning over window
	GP.axisAlignedBlockFromCorners("WinAwning", Vector3.new(doorX - winW/2 - wFrameT - 0.3, winY + winH + wFrameT, frontZ - 0.6), Vector3.new(doorX + winW/2 + wFrameT + 0.3, winY + winH + wFrameT + 0.3, frontZ + wallT), colRoof, "Wood", windowsGrp)
	
	-- ==========================================
	-- 4. ROOF & RAFTERS
	-- ==========================================
	local roofTemp = GP.model("RoofTemp", nil)
	
	-- Raw Gables
	local rawFrontGable = GP.triangularPrismFromThreePoints("RawFrontGable",
	    Vector3.new(rightX, wallTopY, frontZ),
	    Vector3.new(leftX, wallTopY, frontZ),
	    Vector3.new(0, peakY, frontZ),
	    wallT, Vector3.zAxis, colPlaster, "Concrete", roofTemp)
	
	local rawBackGable = GP.triangularPrismFromThreePoints("RawBackGable",
	    Vector3.new(leftX, wallTopY, backZ),
	    Vector3.new(rightX, wallTopY, backZ),
	    Vector3.new(0, peakY, backZ),
	    wallT, Vector3.new(0,0,-1), colPlaster, "Concrete", roofTemp)
	
	-- Ruin Cutters for Roof
	local rCut1 = GP.sphere("RCut1", Vector3.new(rightX + 2, wallTopY + 2, frontZ + halfD), sw * 0.4, Color3.new(1,0,0), "Neon", roofTemp)
	local rCut2 = GP.sphere("RCut2", Vector3.new(rightX + 1, peakY - 1, frontZ + 1), sw * 0.3, Color3.new(1,0,0), "Neon", roofTemp)
	local rCut3 = GP.sphere("RCut3", Vector3.new(0, peakY - 0.5, backZ - 1), sw * 0.25, Color3.new(1,0,0), "Neon", roofTemp)
	
	local finalFrontGable = CSG.subtract("FrontGable", rawFrontGable, {rCut1, rCut2, rCut3})
	finalFrontGable.Parent = roofGrp
	local finalBackGable = CSG.subtract("BackGable", rawBackGable, {rCut1, rCut2, rCut3})
	finalBackGable.Parent = roofGrp
	
	rCut1:Destroy()
	rCut2:Destroy()
	rCut3:Destroy()
	rawFrontGable:Destroy()
	rawBackGable:Destroy()
	roofTemp:Destroy()
	
	-- Intact Roof Panel (Left Side +X)
	local roofOverhang = 1.0
	local roofT = 0.5
	GP.quadFromFourPoints("RoofPanelLeft",
	    Vector3.new(0, peakY + 0.2, backZ + roofOverhang),
	    Vector3.new(0, peakY + 0.2, frontZ - roofOverhang),
	    Vector3.new(leftX + roofOverhang, wallTopY - 0.2, frontZ - roofOverhang),
	    Vector3.new(leftX + roofOverhang, wallTopY - 0.2, backZ + roofOverhang),
	    roofT, Vector3.new(-1, 1, 0), colRoof, "WoodPlanks", roofGrp)
	
	-- Ridge Beam (Burnt)
	GP.axisAlignedBlockFromCorners("RidgeBeam",
	    Vector3.new(-0.3, peakY - 0.4, frontZ - 2e-3),
	    Vector3.new(0.3, peakY + 2e-3, backZ),
	    colBurnt, "Wood", roofGrp) -- zf-prevention: vector3_component
	
	-- Collapsed/Burnt Rafters spanning the gap on the Right Side (-X)
	local r1Start = Vector3.new(1, peakY - 1.5, frontZ + 1)
	local r1End = Vector3.new(rightX + 2, wallTopY + 1, frontZ + 4)
	GP.strutFromTwoPoints("BurntRafter1", r1Start, r1End, 0.4, 0.4, colBurnt, "Wood", roofGrp)
	
	local r2Start = Vector3.new(0, peakY - 0.5, backZ - 2)
	local r2End = Vector3.new(rightX + 1, wallTopY - 1, backZ - 4)
	GP.strutFromTwoPoints("BurntRafter2", r2Start, r2End, 0.5, 0.5, colBurnt, "Wood", roofGrp)
	
	local r3Start = Vector3.new(leftX - 3, wallTopY + 3, frontZ + 2)
	local r3End = Vector3.new(rightX + 3, wallTopY - 0.5, frontZ + 1)
	GP.strutFromTwoPoints("BurntRafter3", r3Start, r3End, 0.4, 0.6, colBurnt, "Wood", roofGrp)
	
	local r4Start = Vector3.new(-1, peakY - 2, frontZ + 2)
	local r4End = Vector3.new(-2, peakY - 4, frontZ + 3)
	GP.strutFromTwoPoints("BurntRafter4", r4Start, r4End, 0.3, 0.3, colDarkTimber, "Wood", roofGrp)
	
	myModel.Parent = targetContainer
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

return RuinedInn

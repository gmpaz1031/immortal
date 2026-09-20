--!strict
-- generationId: 93e1e6ac-c8eb-4687-8537-a05d56501031
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local RuinedBarn = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		ColorWood: Color3?,
		ColorBeam: Color3?,
		ColorCharred: Color3?,
		ColorHay: Color3?,
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

RuinedBarn.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	local myModel = GP.model("RuinedBarn", nil)-- Fix orientation of the model
	myModel.WorldPivot = CFrame.identity
	
	
	-- REQUIRED TOP-LEVEL MODELS (Strictly named)
	local wallsGrp = GP.model("walls", myModel)
	local windowsGrp = GP.model("windows", myModel)
	local doorGrp = GP.model("door", myModel)
	local roofGrp = GP.model("roof", myModel)
	
	-- SMART SCALING & PARAMETERS
	local smartWidth  = parameters.Size.X
	local smartHeight = parameters.Size.Y
	local smartDepth  = parameters.Size.Z
	
	local scaleX = smartWidth / 10
	local scaleY = smartHeight / 10
	local scaleZ = smartDepth / 10
	
	local bW = 20 * scaleX
	local bD = 18 * scaleZ
	local l1H = 8 * scaleY -- Ground floor height
	local l2H = 8 * scaleY -- Second floor height
	local baseH = l1H + l2H
	
	-- Roof heights (Gambrel style)
	local roofMidH = baseH + 6 * scaleY
	local roofTopH = roofMidH + 5 * scaleY
	local roofMidX = (bW / 2) * 0.6 -- Pinch point of gambrel roof
	
	local wallT = 0.5 * scaleX
	local beamT = 0.6 * scaleX
	local doorW = 8 * scaleX
	
	local halfW = bW / 2
	local halfD = bD / 2
	local frontZ = -halfD
	local backZ = halfD
	
	-- COLORS & MATERIALS
	local colWood = parameters.Attributes.ColorWood or Color3.fromRGB(140, 140, 145)
	local colBeam = parameters.Attributes.ColorBeam or Color3.fromRGB(100, 95, 90)
	local colCharred = parameters.Attributes.ColorCharred or Color3.fromRGB(50, 45, 45)
	local colHay = parameters.Attributes.ColorHay or Color3.fromRGB(190, 175, 100)
	
	local matWood = "WoodPlanks"
	local matBeam = "Wood"
	local matHay = "Grass"
	
	-- ==========================================
	-- 1. WALLS & FLOORS (wallsGrp)
	-- ==========================================
	
	-- Corner Posts
	GP.axisAlignedBlockFromCorners("Post_FR", Vector3.new(-halfW, 0, frontZ), Vector3.new(-halfW + beamT, baseH, frontZ + beamT), colBeam, matBeam, wallsGrp)
	GP.axisAlignedBlockFromCorners("Post_BR", Vector3.new(-halfW, 0, backZ - beamT), Vector3.new(-halfW + beamT, baseH, backZ), colBeam, matBeam, wallsGrp)
	GP.axisAlignedBlockFromCorners("Post_BL", Vector3.new(halfW - beamT, 0, backZ - beamT), Vector3.new(halfW, baseH, backZ), colBeam, matBeam, wallsGrp)
	-- Front door framing posts
	GP.axisAlignedBlockFromCorners("Post_DoorR", Vector3.new(-doorW/2 - beamT, 0, frontZ), Vector3.new(-doorW/2, baseH, frontZ + beamT), colBeam, matBeam, wallsGrp)
	GP.axisAlignedBlockFromCorners("Post_DoorL", Vector3.new(doorW/2, 0, frontZ), Vector3.new(doorW/2 + beamT, baseH, frontZ + beamT), colBeam, matBeam, wallsGrp)
	
	-- Floor Planes (Slatted look)
	local floorT = 0.3 * scaleY
	local floorPlankW = 1.0 * scaleZ
	local numPlanks = math.floor((bD - beamT*2) / floorPlankW)
	for i = 0, numPlanks do
	    local zStart = frontZ + beamT + i * floorPlankW
	    -- Skip some planks to look broken
	    if i % 7 ~= 0 then
	        -- Floor 1
	        GP.axisAlignedBlockFromCorners("Floor1_Plank_"..i, 
	            Vector3.new(-halfW + beamT, l1H - 2e-3, zStart + 0.1), 
	            Vector3.new(halfW - beamT, l1H + floorT, (zStart + floorPlankW - 0.1) + 2e-3), 
	            colBeam, matBeam, wallsGrp) -- zf-prevention: vector3_component
	        -- Floor 2 (Hayloft base)
	        if i % 4 ~= 0 then
	            GP.axisAlignedBlockFromCorners("Floor2_Plank_"..i, 
	                Vector3.new(-halfW + beamT, baseH - 2e-3, zStart + 0.1), 
	                Vector3.new(halfW - beamT, baseH + floorT, (zStart + floorPlankW - 0.1) + 2e-3), 
	                colBeam, matBeam, wallsGrp) -- zf-prevention: vector3_component
	        end
	    end
	end
	
	-- Horizontal Beams separating stories
	GP.axisAlignedBlockFromCorners("Beam_FrontMid", Vector3.new(halfW, l1H, frontZ - 0.1), Vector3.new((-halfW) + 2e-3, l1H + beamT, frontZ + beamT), colBeam, matBeam, wallsGrp) -- zf-prevention: vector3_component
	GP.axisAlignedBlockFromCorners("Beam_FrontTop", Vector3.new(halfW, baseH - 2e-3, frontZ - 0.1), Vector3.new(-halfW, baseH + beamT, frontZ + beamT), colBeam, matBeam, wallsGrp) -- zf-prevention: vector3_component
	
	-- Right Wall (-X) - Mostly Intact
	GP.axisAlignedBlockFromCorners("Wall_Right", Vector3.new(-halfW, 0, frontZ + beamT), Vector3.new(-halfW + wallT, baseH, backZ - beamT), colWood, matWood, wallsGrp)
	-- Back Wall (+Z) - Mostly Intact
	GP.axisAlignedBlockFromCorners("Wall_Back", Vector3.new(halfW - beamT, 0, backZ - wallT), Vector3.new(-halfW + beamT, baseH, backZ), colWood, matWood, wallsGrp)
	
	-- Front Wall segments (Left and Right of door)
	GP.axisAlignedBlockFromCorners("Wall_FrontR", Vector3.new(-halfW + beamT, 0, frontZ), Vector3.new(-doorW/2 - beamT, baseH, frontZ + wallT), colWood, matWood, wallsGrp)
	
	-- Left Wall (+X) & Front-Left - SEVERELY BROKEN (CSG)
	local leftWallBase = GP.axisAlignedBlockFromCorners("LeftWallBase", Vector3.new(halfW - wallT, 0, frontZ), Vector3.new(halfW, baseH, backZ - beamT), colWood, matWood, workspace, 0)
	local frontLeftBase = GP.axisAlignedBlockFromCorners("FrontLeftBase", Vector3.new(halfW, 0, frontZ), Vector3.new(doorW/2 + beamT, baseH, frontZ + wallT), colWood, matWood, workspace, 0)
	
	-- Create destruction cutters
	local cutters = {}
	local function addCutter(pos, size)
	    local cut = GP.axisAlignedBlockFromCorners("Cut", pos - size/2, pos + size/2, Color3.new(1,0,0), "Neon", workspace, 0)
	    table.insert(cutters, cut)
	end
	
	-- Massive hole in the front-left corner spanning both stories
	addCutter(Vector3.new(halfW, l1H, frontZ + 2*scaleZ), Vector3.new(8*scaleX, 10*scaleY, 8*scaleZ))
	addCutter(Vector3.new(halfW, l1H + 3*scaleY, frontZ), Vector3.new(6*scaleX, 6*scaleY, 4*scaleZ))
	addCutter(Vector3.new(halfW - 2*scaleX, l2H + 4*scaleY, frontZ + 4*scaleZ), Vector3.new(5*scaleX, 8*scaleY, 5*scaleZ))
	addCutter(Vector3.new(halfW, 2*scaleY, frontZ + 3*scaleZ), Vector3.new(3*scaleX, 4*scaleY, 3*scaleZ))
	
	local leftWallBroken = CSG.subtract("Wall_Left_Broken", leftWallBase, cutters)
	leftWallBroken.Parent = wallsGrp
	local frontLeftBroken = CSG.subtract("Wall_FrontL_Broken", frontLeftBase, cutters)
	frontLeftBroken.Parent = wallsGrp
	
	leftWallBase:Destroy()
	frontLeftBase:Destroy()
	for _, c in ipairs(cutters) do c:Destroy() end
	
	-- Charred/Dark patches on the broken edge
	GP.axisAlignedBlockFromCorners("Charred1", Vector3.new(halfW + 0.1, l1H - 1, frontZ + 1), Vector3.new(halfW - wallT - 0.1, l1H + 2, frontZ + 3), colCharred, matWood, wallsGrp)
	
	-- Hay Bales (Inside)
	GP.roundedBox("Hay1", Vector3.new(0, baseH + 1*scaleY, 0), Vector3.new(4*scaleX, 2*scaleY, 5*scaleZ), 0.5, colHay, matHay, wallsGrp)
	GP.roundedBox("Hay2", Vector3.new(-2*scaleX, baseH + 1.2*scaleY, 2*scaleZ), Vector3.new(3*scaleX, 2*scaleY, 4*scaleZ), 0.5, colHay, matHay, wallsGrp)
	GP.roundedBox("Hay3", Vector3.new(2*scaleX, l1H + 1*scaleY, 0), Vector3.new(4*scaleX, 2*scaleY, 5*scaleZ), 0.5, colHay, matHay, wallsGrp)
	
	-- Debris Pile (Fallen beams and planks on the viewer's left -> World +X)
	local debrisCount = math.floor(12 * (scaleX + scaleZ)/2)
	for i = 1, debrisCount do
	    local xOffset = math.random() * 5 * scaleX
	    local zOffset = math.random() * 8 * scaleZ
	    local isLeaning = math.random() > 0.5
	    
	    local startP, endP
	    if isLeaning then
	        startP = Vector3.new(halfW + 0.5 + xOffset, math.random() * 5 * scaleY, frontZ + zOffset)
	        endP = Vector3.new(halfW + 2 + xOffset + math.random()*3, 0.2, frontZ + zOffset + math.random()*2)
	    else
	        startP = Vector3.new(halfW + 1 + xOffset, 0.2, frontZ + zOffset)
	        endP = Vector3.new(halfW + 1 + xOffset + math.random()*4, 0.2, frontZ + zOffset + math.random()*4)
	    end
	    
	    GP.strutFromTwoPoints("Debris_"..i, startP, endP, 0.4*scaleX, 0.8*scaleY, colBeam, matWood, wallsGrp)
	end
	
	
	-- ==========================================
	-- 2. DOOR (doorGrp)
	-- ==========================================
	-- Sliding barn doors
	local dThick = 0.4 * scaleZ
	local halfDoorW = (doorW / 2) + 0.5*scaleX
	local doorH = l1H - 0.5*scaleY
	
	local function createBarnDoor(name, centerPos, isOpen, isCrooked)
	    local door = GP.model(name, doorGrp)
	    local dY = centerPos.Y
	    local dZ = centerPos.Z
	    local dX = centerPos.X
	    
	    local p1 = Vector3.new(dX - halfDoorW/2, dY - doorH/2, dZ - dThick/2)
	    local p2 = Vector3.new(dX + halfDoorW/2, dY + doorH/2, dZ + dThick/2)
	    
	    -- Main Panel
	    GP.axisAlignedBlockFromCorners("Panel", p1, p2, colWood, matWood, door)
	    
	    -- X Frame Trim
	    local fT = 0.2 * scaleX
	    local tZ = dZ - dThick/2 - 0.1
	    -- Border
	    GP.axisAlignedBlockFromCorners("TrimL", Vector3.new(dX + halfDoorW/2, dY - doorH/2, tZ), Vector3.new((dX + halfDoorW/2 - fT) + 2e-3, (dY + doorH/2) + 2e-3, tZ + 0.15), colBeam, matWood, door) -- zf-prevention: vector3_component
	    GP.axisAlignedBlockFromCorners("TrimR", Vector3.new((dX - halfDoorW/2) - 2e-3, dY - doorH/2, tZ), Vector3.new(dX - halfDoorW/2 + fT, (dY + doorH/2) + 2e-3, tZ + 0.15), colBeam, matWood, door) -- zf-prevention: vector3_component
	    GP.axisAlignedBlockFromCorners("TrimT", Vector3.new(dX + halfDoorW/2, dY + doorH/2 - fT, tZ), Vector3.new((dX - halfDoorW/2) + 2e-3, (dY + doorH/2) + 2e-3, tZ + 0.15), colBeam, matWood, door) -- zf-prevention: vector3_component
	    GP.axisAlignedBlockFromCorners("TrimB", Vector3.new(dX + halfDoorW/2, (dY - doorH/2) - 2e-3, tZ), Vector3.new((dX - halfDoorW/2) + 2e-3, dY - doorH/2 + fT, tZ + 0.15), colBeam, matWood, door) -- zf-prevention: vector3_component
	    
	    -- X Braces
	    local cornerTL = Vector3.new(dX + halfDoorW/2 - fT, dY + doorH/2 - fT, tZ + 0.05)
	    local cornerBR = Vector3.new(dX - halfDoorW/2 + fT, dY - doorH/2 + fT, tZ + 0.05)
	    local cornerTR = Vector3.new(dX - halfDoorW/2 + fT, dY + doorH/2 - fT, tZ + 0.05)
	    local cornerBL = Vector3.new(dX + halfDoorW/2 - fT, dY - doorH/2 + fT, tZ + 0.05)
	    
	    GP.strutFromTwoPoints("X1", cornerTL, cornerBR, fT, 0.1, colBeam, matWood, door)
	    GP.strutFromTwoPoints("X2", cornerTR, cornerBL, fT, 0.1, colBeam, matWood, door)
	end
	
	-- Ground Floor Doors (pushed to sides)
	createBarnDoor("Door_L1_Left", Vector3.new(doorW/2 + halfDoorW/2 - 1*scaleX, l1H/2, frontZ - 0.5*scaleZ), true, false)
	createBarnDoor("Door_L1_Right", Vector3.new(-doorW/2 - halfDoorW/2 + 0.5*scaleX, l1H/2, frontZ - 0.5*scaleZ), true, false)
	
	-- Second Floor Doors (Partially closed)
	createBarnDoor("Door_L2_Left", Vector3.new(doorW/4, l1H + l2H/2, frontZ - 0.5*scaleZ), true, false)
	createBarnDoor("Door_L2_Right", Vector3.new(-doorW/2 + 1*scaleX, l1H + l2H/2, frontZ - 0.5*scaleZ), true, false)
	
	
	-- ==========================================
	-- 3. WINDOWS (windowsGrp)
	-- ==========================================
	-- Added to satisfy the strict top-level naming requirement.
	-- A small broken window on the back wall.
	local winW = 3 * scaleX
	local winH = 3 * scaleY
	local winY = l1H + l2H/2
	
	-- Window Hole Cutter
	local wHole = GP.axisAlignedBlockFromCorners("WinHole", Vector3.new(winW/2, winY - winH/2, backZ - 2), Vector3.new(-winW/2, winY + winH/2, backZ + 2), Color3.new(), "Neon", workspace, 0)
	-- Re-cut the back wall
	local oldBack = wallsGrp:FindFirstChild("Wall_Back")
	if oldBack then
	    local newBack = CSG.subtract("Wall_Back", oldBack, {wHole})
	    newBack.Parent = wallsGrp
	    oldBack:Destroy()
	end
	wHole:Destroy()
	
	-- Broken Window Frame
	local fT = 0.2 * scaleX
	local wZ = backZ - wallT/2
	GP.axisAlignedBlockFromCorners("WFrame_Top", Vector3.new(winW/2, winY + winH/2, wZ - 0.2), Vector3.new(-winW/2, winY + winH/2 - fT, wZ + 0.2), colBeam, matWood, windowsGrp)
	GP.axisAlignedBlockFromCorners("WFrame_Left", Vector3.new(winW/2, winY - winH/2, wZ - 0.2), Vector3.new(winW/2 - fT, winY + winH/2, wZ + 0.2), colBeam, matWood, windowsGrp)
	-- Bottom frame is broken
	GP.axisAlignedBlockFromCorners("WFrame_BotL", Vector3.new(winW/2, winY - winH/2, wZ - 0.2), Vector3.new(winW/4, winY - winH/2 + fT, wZ + 0.2), colBeam, matWood, windowsGrp)
	-- Hanging broken mullion
	GP.strutFromTwoPoints("WFrame_Mullion", Vector3.new(0, winY + winH/2, wZ), Vector3.new(0.5*scaleX, winY - 0.5*scaleY, wZ - 0.5*scaleZ), fT, fT, colBeam, matWood, windowsGrp)
	
	
	-- ==========================================
	-- 4. ROOF (roofGrp)
	-- ==========================================
	local rOverhang = 1.5 * scaleZ
	local rEave = 1.0 * scaleX
	local rThick = 0.4 * scaleY
	local rFrontZ = frontZ - rOverhang
	local rBackZ = backZ + rOverhang
	local rLeftX = halfW + rEave
	local rRightX = -halfW - rEave
	local rMidLeftX = roofMidX + rEave/2
	local rMidRightX = -roofMidX - rEave/2
	
	local upDir = Vector3.yAxis
	
	-- Create solid roof panels to subtract from
	local roofBaseL_Low = GP.quadFromFourPoints("R_L_Low_Base", 
	    Vector3.new(roofMidX, roofMidH, rBackZ), Vector3.new(rLeftX, baseH, rBackZ),
	    Vector3.new(rLeftX, baseH, rFrontZ), Vector3.new(roofMidX, roofMidH, rFrontZ),
	    rThick, upDir, colWood, matWood, workspace, 0)
	    
	local roofBaseL_Up = GP.quadFromFourPoints("R_L_Up_Base", 
	    Vector3.new(0, roofTopH, rBackZ), Vector3.new(roofMidX, roofMidH, rBackZ),
	    Vector3.new(roofMidX, roofMidH, rFrontZ), Vector3.new(0, roofTopH, rFrontZ),
	    rThick, upDir, colWood, matWood, workspace, 0)
	
	-- Roof Cutters (Holes in the left side of the roof)
	local rCutters = {}
	local function addRCut(pos, size)
	    local cut = GP.axisAlignedBlockFromCorners("RCut", pos - size/2, pos + size/2, Color3.new(1,0,0), "Neon", workspace, 0)
	    table.insert(rCutters, cut)
	end
	
	addRCut(Vector3.new(roofMidX + 2*scaleX, roofMidH - 2*scaleY, frontZ + 4*scaleZ), Vector3.new(6*scaleX, 6*scaleY, 6*scaleZ))
	addRCut(Vector3.new(roofMidX - 1*scaleX, roofMidH + 2*scaleY, frontZ + 2*scaleZ), Vector3.new(4*scaleX, 5*scaleY, 4*scaleZ))
	
	local roofLLow = CSG.subtract("Roof_Left_Low", roofBaseL_Low, rCutters)
	roofLLow.Parent = roofGrp
	local roofLUp = CSG.subtract("Roof_Left_Up", roofBaseL_Up, rCutters)
	roofLUp.Parent = roofGrp
	
	roofBaseL_Low:Destroy()
	roofBaseL_Up:Destroy()
	for _, c in ipairs(rCutters) do c:Destroy() end
	
	-- Right Roof (Intact)
	GP.quadFromFourPoints("Roof_Right_Low", 
	    Vector3.new(rRightX, baseH, rBackZ), Vector3.new(-roofMidX, roofMidH, rBackZ),
	    Vector3.new(-roofMidX, roofMidH, rFrontZ), Vector3.new(rRightX, baseH, rFrontZ),
	    rThick, upDir, colWood, matWood, roofGrp)
	
	GP.quadFromFourPoints("Roof_Right_Up", 
	    Vector3.new(-roofMidX, roofMidH, rBackZ), Vector3.new(0, roofTopH, rBackZ),
	    Vector3.new(0, roofTopH, rFrontZ), Vector3.new(-roofMidX, roofMidH, rFrontZ),
	    rThick, upDir, colWood, matWood, roofGrp)
	
	-- Gables (Front and Back Triangles)
	local gT = wallT
	-- Front Gable Left
	GP.triangularPrismFromThreePoints("Gable_FL", 
	    Vector3.new(halfW, baseH, frontZ), Vector3.new(doorW/2, baseH, frontZ), Vector3.new(doorW/2, roofMidH, frontZ),
	    gT, Vector3.new(0,0,1), colWood, matWood, roofGrp)
	GP.triangularPrismFromThreePoints("Gable_FL_Top", 
	    Vector3.new(doorW/2, roofMidH, frontZ), Vector3.new(roofMidX, roofMidH, frontZ), Vector3.new(0, roofTopH, frontZ),
	    gT, Vector3.new(0,0,1), colWood, matWood, roofGrp)
	-- Front Gable Right
	GP.triangularPrismFromThreePoints("Gable_FR", 
	    Vector3.new(-doorW/2, baseH, frontZ), Vector3.new(-halfW, baseH, frontZ), Vector3.new(-doorW/2, roofMidH, frontZ),
	    gT, Vector3.new(0,0,1), colWood, matWood, roofGrp)
	GP.triangularPrismFromThreePoints("Gable_FR_Top", 
	    Vector3.new(-roofMidX, roofMidH, frontZ), Vector3.new(-doorW/2, roofMidH, frontZ), Vector3.new(0, roofTopH, frontZ),
	    gT, Vector3.new(0,0,1), colWood, matWood, roofGrp)
	
	-- Back Gable (Solid)
	GP.axisAlignedBlockFromCorners("Gable_Back_Base", Vector3.new(halfW, baseH, backZ - gT), Vector3.new(-halfW, roofMidH, backZ), colWood, matWood, roofGrp)
	GP.triangularPrismFromThreePoints("Gable_Back_Top1", Vector3.new(halfW, roofMidH, backZ - gT), Vector3.new(0, roofMidH, backZ - gT), Vector3.new(0, roofTopH, backZ - gT), gT, Vector3.new(0,0,-1), colWood, matWood, roofGrp)
	GP.triangularPrismFromThreePoints("Gable_Back_Top2", Vector3.new(0, roofMidH, backZ - gT), Vector3.new(-halfW, roofMidH, backZ - gT), Vector3.new(0, roofTopH, backZ - gT), gT, Vector3.new(0,0,-1), colWood, matWood, roofGrp)
	
	-- Roof Ridge Cap
	GP.axisAlignedBlockFromCorners("RidgeCap", Vector3.new(0.5*scaleX, roofTopH, rFrontZ), Vector3.new(-0.5*scaleX, roofTopH + 0.3*scaleY, rBackZ + 2e-3), colBeam, matWood, roofGrp) -- zf-prevention: vector3_component
	
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

return RuinedBarn

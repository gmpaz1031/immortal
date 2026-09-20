--!strict
-- generationId: 0e66965c-719e-4c97-a648-75fdf11cfeb0
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local RuinedMedievalHouse = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		ColorStone: Color3?,
		ColorPlaster: Color3?,
		ColorWood: Color3?,
		ColorDarkWood: Color3?,
		ColorRoof: Color3?,
		ColorTile: Color3?,
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

RuinedMedievalHouse.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	local model = GP.model("RuinedMedievalHouse", nil)-- Fix orientation of the model
	model.WorldPivot = CFrame.identity
	
	
	-- REQUIRED SMART DIMENSIONS
	local smartWidth = parameters.Size.X
	local smartHeight = parameters.Size.Y
	local smartDepth = parameters.Size.Z
	
	local sX = smartWidth / 24
	local sY = smartHeight / 34
	local sZ = smartDepth / 20
	
	-- COLORS & MATERIALS
	local colStone = parameters.Attributes.ColorStone or Color3.fromRGB(120, 125, 130)
	local colPlaster = parameters.Attributes.ColorPlaster or Color3.fromRGB(225, 210, 180)
	local colWood = parameters.Attributes.ColorWood or Color3.fromRGB(110, 75, 50)
	local colDarkWood = parameters.Attributes.ColorDarkWood or Color3.fromRGB(80, 50, 35)
	local colRoof = parameters.Attributes.ColorRoof or Color3.fromRGB(80, 85, 95)
	local colTile = parameters.Attributes.ColorTile or Color3.fromRGB(180, 90, 60)
	
	local matStone = "Slate"
	local matPlaster = "Concrete"
	local matWood = "WoodPlanks"
	
	-- TOP LEVEL GROUPS (Strictly enforced)
	local grpWalls = GP.model("walls", model)
	local grpWindows = GP.model("windows", model)
	local grpDoor = GP.model("door", model)
	local grpRoof = GP.model("roof", model)
	
	-- LAYOUT VARIABLES
	local halfW = (24 / 2) * sX
	local halfD = (20 / 2) * sZ
	local frontZ = -halfD
	local backZ = halfD
	
	local hLower = 12 * sY
	local hUpper = 12 * sY
	local hRoof = 10 * sY
	
	local yGround = 0
	local yMid = hLower
	local yTop = hLower + hUpper
	local yPeak = yTop + hRoof
	
	local wallT = 1.5 * math.min(sX, sZ)
	local overhang = 1.0 * sX
	
	-- ==========================================
	-- 1. CUTTERS (For Windows, Doors, and Ruins)
	-- ==========================================
	local tempCSG = GP.model("TempCSG", nil)
	local cuttersWalls = {}
	local cuttersRoof = {}
	local cutCol = Color3.new(1, 0, 0)
	
	-- Door Cutter (Center Front)
	local doorW = 5 * sX
	local doorH = 8 * sY
	local doorCut = GP.axisAlignedBlockFromCorners("CutDoor", 
	    Vector3.new(-doorW/2, yGround - 1, frontZ - 2), 
	    Vector3.new(doorW/2, doorH, frontZ + wallT + 2), 
	    cutCol, "Neon", tempCSG)
	table.insert(cuttersWalls, doorCut)
	
	-- Window Cutters
	local winW = 3.5 * sX
	local winH = 4.5 * sY
	local winLowerY = 4 * sY
	local winUpperY = yMid + 3 * sY
	local winX = 7 * sX
	
	local function addWinCut(x, y, z, isFront)
	    local minX = isFront and x - winW/2 or x - wallT - 2
	    local maxX = isFront and x + winW/2 or x + wallT + 2
	    local minZ = isFront and z - 2 or z - winW/2
	    local maxZ = isFront and z + wallT + 2 or z + winW/2
	    local cut = GP.axisAlignedBlockFromCorners("CutWin", 
	        Vector3.new(minX, y, minZ), 
	        Vector3.new(maxX, y + winH, maxZ), 
	        cutCol, "Neon", tempCSG)
	    table.insert(cuttersWalls, cut)
	end
	
	-- Front Windows (Viewer Left +X, Viewer Right -X)
	addWinCut(winX, winLowerY, frontZ, true)
	addWinCut(-winX, winLowerY, frontZ, true)
	addWinCut(winX, winUpperY, frontZ - overhang, true)
	addWinCut(-winX, winUpperY, frontZ - overhang, true)
	
	-- Side Windows
	addWinCut(halfW, winLowerY + 2*sY, 0, false)
	addWinCut(-halfW, winLowerY + 2*sY, 0, false)
	addWinCut(halfW + overhang, winUpperY, 0, false)
	addWinCut(-halfW - overhang, winUpperY, 0, false)
	
	-- Ruin Cutter (Large damage on viewer's left (+X) and roof)
	local ruinX = 6 * sX
	local ruinY = yTop
	local ruinZ = frontZ + 2*sZ
	
	local ruinSphere1 = GP.sphere("RS1", Vector3.new(ruinX, ruinY, ruinZ), 6 * math.min(sX, sY), cutCol, "Neon", tempCSG)
	local ruinSphere2 = GP.sphere("RS2", Vector3.new(ruinX + 3*sX, ruinY + 4*sY, ruinZ + 4*sZ), 5 * math.min(sX, sY), cutCol, "Neon", tempCSG)
	local ruinBlock = GP.axisAlignedBlockFromCorners("RB1", 
	    Vector3.new(ruinX - 4*sX, ruinY - 2*sY, ruinZ - 5*sZ), 
	    Vector3.new(ruinX + 6*sX, ruinY + 8*sY, ruinZ + 5*sZ), 
	    cutCol, "Neon", tempCSG)
	
	local ruinCutterUnion = CSG.union("RuinCutter", ruinSphere1, {ruinSphere2, ruinBlock})
	if ruinCutterUnion then
	    table.insert(cuttersWalls, ruinCutterUnion)
	    -- Clone for roof cutting
	    local ruinCutterRoof = ruinCutterUnion:Clone()
	    ruinCutterRoof.Parent = tempCSG
	    table.insert(cuttersRoof, ruinCutterRoof)
	end
	
	-- ==========================================
	-- 2. WALLS & FOUNDATION
	-- ==========================================
	-- Lower Stone Shell
	local lowerShellSolid = GP.axisAlignedBlockFromCorners("LowerSolid", 
	    Vector3.new(-halfW, yGround, frontZ), 
	    Vector3.new(halfW, yMid, backZ), 
	    colStone, matStone, tempCSG)
	
	local lowerHollow = GP.axisAlignedBlockFromCorners("LowerHollow", 
	    Vector3.new(-halfW + wallT, yGround - 1, frontZ + wallT), 
	    Vector3.new(halfW - wallT, yMid + 1, backZ - wallT), 
	    cutCol, "Neon", tempCSG)
	
	local lowerWallBase = CSG.subtract("LowerWallBase", lowerShellSolid, {lowerHollow})
	
	-- Upper Plaster Shell (Overhangs slightly)
	local uMinX = -halfW - overhang
	local uMaxX = halfW + overhang
	local uMinZ = frontZ - overhang
	local uMaxZ = backZ + overhang
	
	local upperShellSolid = GP.axisAlignedBlockFromCorners("UpperSolid", 
	    Vector3.new(uMinX, yMid, uMinZ), 
	    Vector3.new(uMaxX, yTop, uMaxZ), 
	    colPlaster, matPlaster, tempCSG)
	
	local upperHollow = GP.axisAlignedBlockFromCorners("UpperHollow", 
	    Vector3.new(uMinX + wallT, yMid - 1, uMinZ + wallT), 
	    Vector3.new(uMaxX - wallT, yTop + 1, uMaxZ - wallT), 
	    cutCol, "Neon", tempCSG)
	
	local upperWallBase = CSG.subtract("UpperWallBase", upperShellSolid, {upperHollow})
	
	-- Combine walls and apply global cutters (windows, doors, ruins)
	local combinedWalls = CSG.union("CombinedWalls", lowerWallBase, {upperWallBase})
	if combinedWalls then
	    local finalWalls = CSG.subtract("FinalWalls", combinedWalls, cuttersWalls)
	    if finalWalls then
	        finalWalls.Parent = grpWalls
	    end
	end
	
	-- Floors
	GP.axisAlignedBlockFromCorners("Floor1", Vector3.new(-halfW + wallT, yGround, frontZ + wallT), Vector3.new(halfW - wallT, yGround + 1*sY, backZ - wallT), colDarkWood, matWood, grpWalls)
	GP.axisAlignedBlockFromCorners("Floor2", Vector3.new(uMinX + wallT, yMid, uMinZ + wallT), Vector3.new(uMaxX - wallT, yMid + 1*sY, uMaxZ - wallT), colDarkWood, matWood, grpWalls)
	
	-- Timber Framing (Decorative beams on upper walls)
	local bT = 0.8 * math.min(sX, sZ)
	local function addBeam(name, p1, p2)
	    GP.strutFromTwoPoints(name, p1 + Vector3.new(0, -2e-3, 0), p2 + Vector3.new(2e-3, 2e-3, 2e-3), bT, bT, colWood, matWood, grpWalls) -- zf-prevention: vector3_component
	end
	
	-- Horizontal bands
	local bandY = yMid + bT/2
	addBeam("BandFront", Vector3.new(uMinX, bandY, uMinZ - 0.1), Vector3.new(uMaxX, bandY, uMinZ - 0.1))
	addBeam("BandBack", Vector3.new(uMinX, bandY, uMaxZ + 0.1), Vector3.new(uMaxX, bandY, uMaxZ + 0.1))
	addBeam("BandLeft", Vector3.new(uMaxX + 0.1, bandY, uMinZ), Vector3.new(uMaxX + 0.1, bandY, uMaxZ))
	addBeam("BandRight", Vector3.new(uMinX - 0.1, bandY, uMinZ), Vector3.new(uMinX - 0.1, bandY, uMaxZ))
	
	local bandTop = yTop - bT/2
	addBeam("BandTFront", Vector3.new(uMinX, bandTop, uMinZ - 0.1), Vector3.new(uMaxX, bandTop, uMinZ - 0.1))
	
	-- Vertical Posts
	local function addPost(name, x, z)
	    addBeam(name, Vector3.new(x, yMid, z), Vector3.new(x, yTop, z))
	end
	addPost("PostFL", uMaxX + 0.1, uMinZ - 0.1)
	addPost("PostFR", uMinX - 0.1, uMinZ - 0.1)
	addPost("PostBL", uMaxX + 0.1, uMaxZ + 0.1)
	addPost("PostBR", uMinX - 0.1, uMaxZ + 0.1)
	-- Center posts
	addPost("PostFC", 0, uMinZ - 0.1)
	addPost("PostLMid", uMaxX + 0.1, 0)
	addPost("PostRMid", uMinX - 0.1, 0)
	
	-- Diagonal braces (Front Right, since Front Left is ruined)
	addBeam("BraceFR", Vector3.new(uMinX - 0.1, yMid, uMinZ - 0.1), Vector3.new(-winX - winW/2, yTop, uMinZ - 0.1))
	
	-- Corbels supporting the overhang
	local function addCorbel(name, x)
	    GP.axisAlignedBlockFromCorners(name, Vector3.new(x - 0.6*sX, yMid - 1.5*sY, frontZ - 0.2), Vector3.new(x + 0.6*sX, yMid, uMinZ + 0.2), colWood, matWood, grpWalls)
	end
	addCorbel("Corb1", uMaxX - 1*sX)
	addCorbel("Corb2", uMinX + 1*sX)
	addCorbel("Corb3", 0)
	
	-- ==========================================
	-- 3. DOOR & WINDOW FIXTURES
	-- ==========================================
	-- Door
	GP.axisAlignedBlockFromCorners("DoorStep1", Vector3.new(-doorW/2 - 1*sX, yGround, frontZ - 2.5*sZ), Vector3.new(doorW/2 + 1*sX, yGround + 0.8*sY, frontZ), colStone, matStone, grpDoor)
	GP.axisAlignedBlockFromCorners("DoorStep2", Vector3.new(-doorW/2 - 0.5*sX, yGround + 0.8*sY, frontZ - 1.5*sZ), Vector3.new(doorW/2 + 0.5*sX, yGround + 1.6*sY, frontZ), colStone, matStone, grpDoor)
	
	local fT = 0.6 * math.min(sX, sZ)
	GP.axisAlignedBlockFromCorners("DoorFrameL", Vector3.new(doorW/2, yGround, frontZ - 0.2), Vector3.new(doorW/2 + fT, doorH, frontZ + fT), colStone, matStone, grpDoor)
	GP.axisAlignedBlockFromCorners("DoorFrameR", Vector3.new(-doorW/2 - fT, yGround, frontZ - 0.2), Vector3.new(-doorW/2, doorH, frontZ + fT), colStone, matStone, grpDoor)
	GP.axisAlignedBlockFromCorners("DoorFrameT", Vector3.new(-doorW/2 - fT, doorH, frontZ - 0.2), Vector3.new(doorW/2 + fT, doorH + fT, frontZ + fT), colStone, matStone, grpDoor)
	-- Empty door opening (ruined)
	
	-- Windows
	local function buildWindow(name, cx, cy, cz, isFront, isStone)
	    local fMat = isStone and matStone or matWood
	    local fCol = isStone and colStone or colWood
	    local mod = GP.model("Win_"..name, grpWindows)
	    
	    local wW = winW - 0.4*sX
	    local wH = winH - 0.4*sY
	    
	    local dx = isFront and 1 or 0
	    local dz = isFront and 0 or 1
	    
	    local minX = cx - (wW/2)*dx - fT*(1-dx)
	    local maxX = cx + (wW/2)*dx + fT*(1-dx)
	    local minZ = cz - (wW/2)*dz - fT*(1-dz)
	    local maxZ = cz + (wW/2)*dz + fT*(1-dz)
	    
	    local dOff = 0.2
	    
	    -- Frame
	    GP.axisAlignedBlockFromCorners("FT", Vector3.new(minX - fT*dx, cy + wH, minZ - fT*dz), Vector3.new(maxX + fT*dx, cy + wH + fT, maxZ + fT*dz), fCol, fMat, mod)
	    GP.axisAlignedBlockFromCorners("FB", Vector3.new(minX - fT*dx - 0.2*dx, cy - fT, minZ - fT*dz - 0.2*dz), Vector3.new(maxX + fT*dx + 0.2*dx, cy, maxZ + fT*dz + 0.2*dz), fCol, fMat, mod) -- Sill
	    GP.axisAlignedBlockFromCorners("FL", Vector3.new(maxX, cy, maxZ), Vector3.new(maxX + fT*dx + dOff*(1-dx), cy + wH, maxZ + fT*dz + dOff*(1-dz)), fCol, fMat, mod)
	    GP.axisAlignedBlockFromCorners("FR", Vector3.new(minX - fT*dx - dOff*(1-dx), cy, minZ - fT*dz - dOff*(1-dz)), Vector3.new(minX, cy + wH, minZ), fCol, fMat, mod)
	    
	    -- Cross Mullion
	    GP.axisAlignedBlockFromCorners("MH", Vector3.new(minX, cy + wH/2 - 0.2*sY, minZ), Vector3.new(maxX, cy + wH/2 + 0.2*sY, maxZ), colDarkWood, matWood, mod)
	    GP.axisAlignedBlockFromCorners("MV", Vector3.new(cx - 0.2*sX, cy, cz - 0.2*sZ), Vector3.new(cx + 0.2*sX, cy + wH, cz + 0.2*sZ), colDarkWood, matWood, mod)
	end
	
	-- Only build windows that aren't completely destroyed by the ruin cutter
	buildWindow("G_FrontL", winX, winLowerY, frontZ, true, true)
	buildWindow("G_FrontR", -winX, winLowerY, frontZ, true, true)
	buildWindow("U_FrontR", -winX, winUpperY, uMinZ, true, false)
	-- U_FrontL is destroyed
	
	buildWindow("G_SideL", halfW, winLowerY + 2*sY, 0, false, true)
	buildWindow("G_SideR", -halfW, winLowerY + 2*sY, 0, false, true)
	buildWindow("U_SideR", -uMaxX, winUpperY, 0, false, false)
	
	
	-- ==========================================
	-- 4. ROOF & RAFTERS
	-- ==========================================
	local rOverhang = 2.0 * sZ
	local rEave = 1.5 * sX
	local rZMin = uMinZ - rOverhang
	local rZMax = uMaxZ + rOverhang
	
	-- Gables (Plaster triangles)
	GP.triangularPrismFromThreePoints("GableL", Vector3.new(uMaxX - 0.1, yTop, uMinZ), Vector3.new(uMaxX - 0.1, yTop, uMaxZ), Vector3.new(uMaxX - 0.1, yPeak, 0), wallT, Vector3.xAxis, colPlaster, matPlaster, grpRoof)
	GP.triangularPrismFromThreePoints("GableR", Vector3.new(uMinX + 0.1, yTop, uMaxZ), Vector3.new(uMinX + 0.1, yTop, uMinZ), Vector3.new(uMinX + 0.1, yPeak, 0), wallT, Vector3.new(-1,0,0), colPlaster, matPlaster, grpRoof)
	
	-- Roof Planes
	local rT = 1.0 * sY
	local pPeakF = Vector3.new(0, yPeak, rZMin)
	local pPeakB = Vector3.new(0, yPeak, rZMax)
	local pEaveLF = Vector3.new(uMaxX + rEave, yTop - 1*sY, rZMin)
	local pEaveLB = Vector3.new(uMaxX + rEave, yTop - 1*sY, rZMax)
	local pEaveRF = Vector3.new(uMinX - rEave, yTop - 1*sY, rZMin)
	local pEaveRB = Vector3.new(uMinX - rEave, yTop - 1*sY, rZMax)
	
	-- Left Roof Plane (+X, Viewer's Left) - This gets subtracted!
	local roofLeftSolid = GP.quadFromFourPoints("RoofLeftSolid", pPeakB, pEaveLB, pEaveLF, pPeakF, rT, Vector3.yAxis, colRoof, "Slate", tempCSG)
	
	-- Right Roof Plane (-X, Viewer's Right) - Intact
	GP.quadFromFourPoints("RoofRight", pEaveRB, pPeakB, pPeakF, pEaveRF, rT, Vector3.yAxis, colRoof, "Slate", grpRoof)
	
	-- Subtract ruins from left roof
	local roofLeftFinal = CSG.subtract("RoofLeft", roofLeftSolid, cuttersRoof)
	if roofLeftFinal then
	    roofLeftFinal.Parent = grpRoof
	end
	
	-- Clean up temps
	tempCSG:Destroy()
	
	-- Exposed Rafters (Under the roof, visible through the hole)
	local numRafters = 6
	local rafterSpacing = (rZMax - rZMin) / (numRafters - 1)
	for i = 1, numRafters do
	    local z = rZMin + (i-1)*rafterSpacing
	    -- Left rafters (+X)
	    GP.strutFromTwoPoints("RafterL_"..i, Vector3.new(0, yPeak - 0.5*sY, z - 2e-3), Vector3.new(uMaxX + rEave - 0.5*sX, yTop - 1.5*sY, z + 2e-3), 0.6*sX, 1.2*sY, colDarkWood, matWood, grpRoof) -- zf-prevention: vector3_component
	    -- Right rafters (-X)
	    GP.strutFromTwoPoints("RafterR_"..i, Vector3.new(0, yPeak - 0.5*sY, z - 2e-3), Vector3.new(uMinX - rEave + 0.5*sX, yTop - 1.5*sY, z + 2e-3), 0.6*sX, 1.2*sY, colDarkWood, matWood, grpRoof) -- zf-prevention: vector3_component
	end
	
	-- Ridge Beam
	GP.axisAlignedBlockFromCorners("RidgeBeam", Vector3.new(-0.6*sX, yPeak - 1*sY, rZMin), Vector3.new(0.6*sX, yPeak + 0.5*sY, rZMax + 2e-3), colWood, matWood, grpRoof) -- zf-prevention: vector3_component
	
	-- ==========================================
	-- 5. DEBRIS
	-- ==========================================
	local function addDebrisBlock(parent, name, center, size, col, mat)
	    local hs = size / 2
	    GP.axisAlignedBlockFromCorners(name, (center - hs) + Vector3.new(0, -2e-3, 0), center + hs, col, mat, parent) -- zf-prevention: vector3_component
	end
	
	-- Ground Debris (Stones near door and walls)
	addDebrisBlock(grpWalls, "D_Stone1", Vector3.new(doorW/2 + 3*sX, yGround + 0.5*sY, frontZ - 3*sZ), Vector3.new(2*sX, 1*sY, 1.5*sZ), colStone, matStone)
	addDebrisBlock(grpWalls, "D_Stone2", Vector3.new(doorW/2 + 5*sX, yGround + 0.3*sY, frontZ - 2*sZ), Vector3.new(1.5*sX, 0.6*sY, 2*sZ), colStone, matStone)
	addDebrisBlock(grpWalls, "D_Stone3", Vector3.new(-doorW/2 - 4*sX, yGround + 0.8*sY, frontZ - 1.5*sZ), Vector3.new(2.5*sX, 1.6*sY, 1.5*sZ), colStone, matStone)
	
	-- Roof Debris (Tiles and wood on the ground viewer left +X)
	addDebrisBlock(grpRoof, "D_Tile1", Vector3.new(uMaxX - 2*sX, yGround + 0.2*sY, frontZ - 4*sZ), Vector3.new(3*sX, 0.4*sY, 4*sZ), colTile, "Slate")
	addDebrisBlock(grpRoof, "D_Tile2", Vector3.new(uMaxX + 2*sX, yGround + 0.4*sY, frontZ - 2*sZ), Vector3.new(2.5*sX, 0.4*sY, 3*sZ), colTile, "Slate")
	addDebrisBlock(grpRoof, "D_Wood1", Vector3.new(uMaxX, yGround + 0.3*sY, frontZ - 5*sZ), Vector3.new(4*sX, 0.6*sY, 0.8*sZ), colDarkWood, matWood)
	
	-- Roof Debris on the roof itself (stuck near the hole)
	addDebrisBlock(grpRoof, "D_RoofTile1", Vector3.new(ruinX - 2*sX, yPeak - 2*sY, frontZ + 1*sZ), Vector3.new(2*sX, 0.5*sY, 2*sZ), colTile, "Slate")
	addDebrisBlock(grpRoof, "D_RoofTile2", Vector3.new(ruinX + 1*sX, yPeak - 4*sY, frontZ + 3*sZ), Vector3.new(1.5*sX, 0.5*sY, 1.5*sZ), colTile, "Slate")
	
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

return RuinedMedievalHouse

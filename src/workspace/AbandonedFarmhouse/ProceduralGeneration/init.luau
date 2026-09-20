--!strict
-- generationId: 412dda19-188e-41b6-99f4-09e66416a602
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local AbandonedFarmhouse = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		rubbleAmount: number?,
		woodWeatheringColor: Color3?,
		collapseSeverity: number?,
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

AbandonedFarmhouse.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	local house = GP.model("AbandonedFarmhouse", nil)-- Fix orientation of the model
	house.WorldPivot = CFrame.identity
	
	
	-- REQUIRED ATTRIBUTES
	local sWidth = parameters.Size.X
	local sHeight = parameters.Size.Y
	local sDepth = parameters.Size.Z
	
	-- CUSTOM ATTRIBUTES
	local rubbleAmount = parameters.Attributes.rubbleAmount or 50
	local woodColor = parameters.Attributes.woodWeatheringColor or Color3.fromRGB(160, 150, 140)
	local severity = parameters.Attributes.collapseSeverity or 0.7 -- 0.0 to 1.0
	
	-- TOP-LEVEL MODELS (Must match exactly)
	local wallsModel = GP.model("walls", house)
	local windowsModel = GP.model("windows", house)
	local doorModel = GP.model("door", house)
	local roofModel = GP.model("roof", house)
	
	-- MATERIALS & COLORS
	local matWood = "WoodPlanks"
	local matFrame = "Wood"
	local matStone = "Slate"
	
	local frameColor = MU.lerpColor(woodColor, Color3.fromRGB(100, 90, 80), 0.5)
	local darkWood = MU.lerpColor(woodColor, Color3.fromRGB(50, 45, 40), 0.7)
	local stoneColor = Color3.fromRGB(130, 135, 130)
	
	-- LAYOUT VARIABLES
	local halfW = sWidth / 2
	local halfD = sDepth / 2
	local wallT = 1.0
	local floorY = 1.0
	local wallH = sHeight
	local peakY = wallH + (sWidth * 0.4)
	
	local leftX = halfW
	local rightX = -halfW
	local frontZ = -halfD
	local backZ = halfD
	
	-- Pseudo-random helper for consistent scattering
	local function prand(seed)
	    local x = math.sin(seed * 12.9898) * 43758.5453
	    return x - math.floor(x)
	end
	
	-- ==========================================
	-- 1. WALLS (CSG Base + Foundation + Debris)
	-- ==========================================
	local stoneBaseH = 1.5
	
	-- Cutout dimensions
	local doorW, doorH = 5.0, 8.0
	local winW, winH = 4.0, 5.0
	local winY = 4.0
	
	-- Window Layout
	local windowsData = {
	    {name="FrontL", cx=leftX - 5, cy=winY, cz=frontZ, isZ=true},
	    {name="FrontR", cx=rightX + 5, cy=winY, cz=frontZ, isZ=true},
	    {name="SideL", cx=leftX, cy=winY, cz=0, isZ=false},
	    {name="SideR", cx=rightX, cy=winY, cz=0, isZ=false}
	}
	
	-- Create Cutters
	local cutters = {}
	local function addCutter(name, minC, maxC)
	    local cut = GP.axisAlignedBlockFromCorners("Cut_"..name, minC, maxC, Color3.new(1,0,0), "SmoothPlastic", workspace, 0)
	    table.insert(cutters, cut)
	end
	
	-- Door Cutter
	addCutter("Door", Vector3.new(-doorW/2, floorY, frontZ - 2), Vector3.new(doorW/2, floorY + doorH, frontZ + 2))
	
	-- Window Cutters
	for _, w in ipairs(windowsData) do
	    if w.isZ then
	        addCutter(w.name, Vector3.new(w.cx - winW/2, w.cy, w.cz - 2), Vector3.new(w.cx + winW/2, w.cy + winH, w.cz + 2))
	    else
	        addCutter(w.name, Vector3.new(w.cx - 2, w.cy, w.cz - winW/2), Vector3.new(w.cx + 2, w.cy + winH, w.cz + winW/2))
	    end
	end
	
	-- Raw Walls
	local rawFront = GP.axisAlignedBlockFromCorners("RawFront", Vector3.new(rightX, floorY, frontZ), Vector3.new(leftX, wallH, frontZ + wallT), woodColor, matWood, workspace, 0)
	local rawBack = GP.axisAlignedBlockFromCorners("RawBack", Vector3.new(rightX, floorY, backZ - wallT), Vector3.new(leftX, wallH, backZ), woodColor, matWood, workspace, 0)
	local rawLeft = GP.axisAlignedBlockFromCorners("RawLeft", Vector3.new(leftX - wallT, floorY, frontZ + wallT), Vector3.new(leftX, wallH, backZ - wallT), woodColor, matWood, workspace, 0)
	local rawRight = GP.axisAlignedBlockFromCorners("RawRight", Vector3.new(rightX, floorY, frontZ + wallT), Vector3.new(rightX + wallT, wallH, backZ - wallT), woodColor, matWood, workspace, 0)
	
	-- Execute Subtractions
	local wFront = CSG.subtract("WallFront", rawFront, cutters)
	wFront.Parent = wallsModel
	local wBack = CSG.subtract("WallBack", rawBack, cutters)
	wBack.Parent = wallsModel
	local wLeft = CSG.subtract("WallLeft", rawLeft, cutters)
	wLeft.Parent = wallsModel
	local wRight = CSG.subtract("WallRight", rawRight, cutters)
	wRight.Parent = wallsModel
	
	for _, c in ipairs(cutters) do c:Destroy() end
	
	-- Gables (Side triangles)
	GP.triangularPrismFromThreePoints("GableLeft", 
	    Vector3.new(leftX - wallT, wallH, frontZ), 
	    Vector3.new(leftX - wallT, wallH, backZ), 
	    Vector3.new(leftX - wallT, peakY, 0), 
	    wallT, nil, woodColor, matWood, wallsModel)
	
	GP.triangularPrismFromThreePoints("GableRight", 
	    Vector3.new(rightX, wallH, backZ), 
	    Vector3.new(rightX, wallH, frontZ), 
	    Vector3.new(rightX, peakY, 0), 
	    wallT, nil, woodColor, matWood, wallsModel)
	
	-- Stone Foundation
	local function buildStoneLine(startX, startZ, endX, endZ, count, seedBase)
	    local dx = (endX - startX) / count
	    local dz = (endZ - startZ) / count
	    for i = 1, count do
	        local cx = startX + dx * (i - 0.5)
	        local cz = startZ + dz * (i - 0.5)
	        local jx = (prand(seedBase + i) - 0.5) * 0.4
	        local jz = (prand(seedBase + i + 100) - 0.5) * 0.4
	        local jy = prand(seedBase + i + 200) * 0.5
	        
	        local bw = 1.5 + prand(seedBase + i*3)
	        local bh = stoneBaseH + jy
	        local bd = 1.5 + prand(seedBase + i*5)
	        
	        GP.axisAlignedBlockFromCorners("Stone_"..i, 
	            Vector3.new(cx - bw/2 + jx, 0, cz - bd/2 + jz), 
	            Vector3.new(cx + bw/2 + jx, bh, cz + bd/2 + jz), 
	            stoneColor, matStone, wallsModel)
	    end
	end
	
	buildStoneLine(leftX, frontZ, rightX, frontZ, math.floor(sWidth/2), 100)
	buildStoneLine(rightX, frontZ, rightX, backZ, math.floor(sDepth/2), 200)
	buildStoneLine(rightX, backZ, leftX, backZ, math.floor(sWidth/2), 300)
	buildStoneLine(leftX, backZ, leftX, frontZ, math.floor(sDepth/2), 400)
	
	-- Broken Floor Inside
	GP.axisAlignedBlockFromCorners("BrokenFloorBase", 
	    Vector3.new(rightX + wallT, stoneBaseH - 0.2, frontZ + wallT), 
	    Vector3.new(leftX - wallT, floorY, backZ - wallT), 
	    darkWood, matWood, wallsModel)
	
	-- Scattered Rubble & Debris
	local numDebris = math.floor(rubbleAmount)
	for i = 1, numDebris do
	    local isWood = prand(i * 13) > 0.5
	    local rx = rightX - 2 + prand(i * 17) * (sWidth + 4)
	    local rz = frontZ - 2 + prand(i * 19) * (sDepth + 4)
	    local ry = prand(i * 23) * 1.5
	    
	    local dx = (prand(i * 29) - 0.5) * 4
	    local dz = (prand(i * 31) - 0.5) * 4
	    local dy = (prand(i * 37) - 0.5) * 2
	    
	    local p1 = Vector3.new(rx, ry, rz)
	    local p2 = Vector3.new(rx + dx, ry + dy, rz + dz)
	    
	    if (p1 - p2).Magnitude > 0.5 then
	        if isWood then
	            local thick = 0.2 + prand(i)*0.4
	            GP.strutFromTwoPoints("DebrisWood_"..i, p1, p2, thick, thick/2, woodColor, matWood, wallsModel)
	        else
	            GP.sphere("DebrisStone_"..i, p1, 0.4 + prand(i)*0.5, stoneColor, matStone, wallsModel)
	        end
	    end
	end
	
	-- ==========================================
	-- 2. WINDOWS (Empty frames)
	-- ==========================================
	local fT = 0.3
	for _, w in ipairs(windowsData) do
	    local cx, cy, cz = w.cx, w.cy, w.cz
	    if w.isZ then
	        GP.axisAlignedBlockFromCorners("FrameT_"..w.name, Vector3.new(cx - winW/2 - fT, cy + winH, cz - wallT/2 - 0.2), Vector3.new(cx + winW/2 + fT, cy + winH + fT, cz + wallT/2 + 0.2), frameColor, matFrame, windowsModel)
	        GP.axisAlignedBlockFromCorners("FrameB_"..w.name, Vector3.new(cx - winW/2 - fT, cy - fT, cz - wallT/2 - 0.2), Vector3.new(cx + winW/2 + fT, cy, cz + wallT/2 + 0.2), frameColor, matFrame, windowsModel)
	        GP.axisAlignedBlockFromCorners("FrameL_"..w.name, Vector3.new(cx + winW/2, cy, cz - wallT/2 - 0.2), Vector3.new(cx + winW/2 + fT, cy + winH, cz + wallT/2 + 0.2), frameColor, matFrame, windowsModel)
	        GP.axisAlignedBlockFromCorners("FrameR_"..w.name, Vector3.new(cx - winW/2 - fT, cy, cz - wallT/2 - 0.2), Vector3.new(cx - winW/2, cy + winH, cz + wallT/2 + 0.2), frameColor, matFrame, windowsModel)
	        -- Broken Mullion
	        if prand(cx) > 0.3 then
	            GP.axisAlignedBlockFromCorners("MullV_"..w.name, Vector3.new(cx - 0.1, cy, cz - 0.1), Vector3.new(cx + 0.1, cy + winH * 0.6, cz + 0.1), frameColor, matFrame, windowsModel)
	        end
	    else
	        GP.axisAlignedBlockFromCorners("FrameT_"..w.name, Vector3.new(cx - wallT/2 - 0.2, cy + winH, cz - winW/2 - fT), Vector3.new(cx + wallT/2 + 0.2, cy + winH + fT, cz + winW/2 + fT), frameColor, matFrame, windowsModel)
	        GP.axisAlignedBlockFromCorners("FrameB_"..w.name, Vector3.new(cx - wallT/2 - 0.2, cy - fT, cz - winW/2 - fT), Vector3.new(cx + wallT/2 + 0.2, cy, cz + winW/2 + fT), frameColor, matFrame, windowsModel)
	        GP.axisAlignedBlockFromCorners("FrameL_"..w.name, Vector3.new(cx - wallT/2 - 0.2, cy, cz - winW/2 - fT), Vector3.new(cx + wallT/2 + 0.2, cy + winH, cz - winW/2), frameColor, matFrame, windowsModel)
	        GP.axisAlignedBlockFromCorners("FrameR_"..w.name, Vector3.new(cx - wallT/2 - 0.2, cy, cz + winW/2), Vector3.new(cx + wallT/2 + 0.2, cy + winH, cz + winW/2 + fT), frameColor, matFrame, windowsModel)
	    end
	end
	
	-- ==========================================
	-- 3. DOOR & STEPS
	-- ==========================================
	-- Door Frame
	GP.axisAlignedBlockFromCorners("DFrameT", Vector3.new(-doorW/2 - fT, floorY + doorH, frontZ - wallT/2 - 0.2), Vector3.new(doorW/2 + fT, floorY + doorH + fT, frontZ + wallT/2 + 0.2), frameColor, matFrame, doorModel)
	GP.axisAlignedBlockFromCorners("DFrameL", Vector3.new(doorW/2, floorY - 2e-3, frontZ - wallT/2 - 0.2), Vector3.new(doorW/2 + fT, floorY + doorH, frontZ + wallT/2 + 0.2), frameColor, matFrame, doorModel) -- zf-prevention: vector3_component
	GP.axisAlignedBlockFromCorners("DFrameR", Vector3.new(-doorW/2 - fT, floorY - 2e-3, frontZ - wallT/2 - 0.2), Vector3.new(-doorW/2, floorY + doorH, frontZ + wallT/2 + 0.2), frameColor, matFrame, doorModel) -- zf-prevention: vector3_component
	
	-- Broken Steps
	local stepCount = 4
	local stepD = 1.2
	local stepH = floorY / stepCount
	for i = 1, stepCount do
	    local sy = (i - 1) * stepH
	    local sz = frontZ - (stepCount - i + 1) * stepD
	    -- Tilted broken step
	    local tilt = (prand(i * 11) - 0.5) * 0.4
	    local p1 = Vector3.new(-doorW/2 + 0.5, sy + tilt, sz)
	    local p2 = Vector3.new(doorW/2 - 0.5, sy - tilt, sz)
	    GP.strutFromTwoPoints("Step_"..i, p1, p2, stepD * 0.8, 0.2, woodColor, matWood, doorModel)
	end
	-- Step stringers
	GP.strutFromTwoPoints("StringerL", Vector3.new(doorW/2 - 0.2, 0, frontZ - stepCount*stepD), Vector3.new(doorW/2 - 0.2, floorY, frontZ), 0.4, 0.4, frameColor, matFrame, doorModel)
	GP.strutFromTwoPoints("StringerR", Vector3.new(-doorW/2 + 0.2, 0, frontZ - stepCount*stepD), Vector3.new(-doorW/2 + 0.2, floorY, frontZ), 0.4, 0.4, frameColor, matFrame, doorModel)
	
	
	-- ==========================================
	-- 4. ROOF (Exposed Framework & Broken Planks)
	-- ==========================================
	local overhang = 2.0
	local eaveY = wallH - 0.5
	local roofZMin = frontZ - overhang
	local roofZMax = backZ + overhang
	
	-- Ridge Beam
	GP.axisAlignedBlockFromCorners("RidgeBeam", Vector3.new(rightX, peakY - 0.6, roofZMin), Vector3.new(leftX, peakY + 2e-3, roofZMax), frameColor, matFrame, roofModel) -- zf-prevention: vector3_component
	
	-- Crossbeams
	local numBeams = math.floor(sDepth / 5)
	local beamSpacing = sDepth / numBeams
	for i = 0, numBeams do
	    local bz = frontZ + i * beamSpacing
	    GP.axisAlignedBlockFromCorners("CrossBeam_"..i, Vector3.new(rightX, wallH - 0.8, bz - 0.3), Vector3.new(leftX + 2e-3, wallH - 0.2, bz + 0.3), frameColor, matFrame, roofModel) -- zf-prevention: vector3_component
	end
	
	-- Rafters
	local rafterSpacing = 2.5
	local numRafters = math.floor((sDepth + overhang*2) / rafterSpacing)
	local rDist = (sDepth + overhang*2) / numRafters
	
	for i = 0, numRafters do
	    local rz = roofZMin + i * rDist
	    -- Right (-X) Rafter
	    local rr1 = Vector3.new(0, peakY - 0.3, rz)
	    local rr2 = Vector3.new(rightX - overhang, eaveY, rz)
	    -- Left (+X) Rafter
	    local rl1 = Vector3.new(0, peakY - 0.3, rz)
	    local rl2 = Vector3.new(leftX + overhang, eaveY, rz)
	    
	    -- Collapse random rafters if severity is high
	    if prand(i * 43) > (severity * 0.8) then
	        GP.strutFromTwoPoints("RafterR_"..i, rr1, rr2, 0.3, 0.6, frameColor, matFrame, roofModel)
	    else
	        -- Broken hanging rafter
	        local br2 = MU.lerpVector3(rr1, rr2, 0.4 + prand(i)*0.3)
	        GP.strutFromTwoPoints("RafterR_Broken_"..i, rr1, br2 - Vector3.new(0, prand(i), 0), 0.3, 0.6, frameColor, matFrame, roofModel)
	    end
	    
	    if prand(i * 47) > (severity * 0.8) then
	        GP.strutFromTwoPoints("RafterL_"..i, rl1, rl2, 0.3, 0.6, frameColor, matFrame, roofModel)
	    end
	end
	
	-- Broken Roof Planks
	local plankW = 1.2
	local numPlanksZ = math.floor((sDepth + overhang*2) / plankW)
	local plankThick = 0.15
	
	local slopeDistL = math.sqrt((leftX + overhang)^2 + (peakY - eaveY)^2)
	local numPlanksX = math.floor(slopeDistL / plankW)
	
	local upDir = Vector3.new(0, 1, 0)
	
	for z = 0, numPlanksZ do
	    local pz = roofZMin + z * plankW
	    for x = 0, numPlanksX do
	        -- Skip generating plank based on collapse severity
	        if prand(z * 100 + x) > severity then
	            local t = x / numPlanksX
	            local pColor = MU.lerpColor(woodColor, Color3.new(0.4, 0.35, 0.3), prand(z * 3 + x))
	            
	            -- Left Side Planks (+X)
	            local lx1 = MU.lerp(0, leftX + overhang, t)
	            local lx2 = MU.lerp(0, leftX + overhang, t + 1/numPlanksX)
	            local ly1 = MU.lerp(peakY, eaveY, t)
	            local ly2 = MU.lerp(peakY, eaveY, t + 1/numPlanksX)
	            
	            -- Jitter
	            local tilt = (prand(z * 7 + x) - 0.5) * 0.3
	            
	            local pl1 = Vector3.new(lx1, ly1 + tilt, pz + 0.1)
	            local pl2 = Vector3.new(lx2, ly2 - tilt, pz + 0.1)
	            local pl3 = Vector3.new(lx2, ly2 - tilt, pz + plankW - 0.1)
	            local pl4 = Vector3.new(lx1, ly1 + tilt, pz + plankW - 0.1)
	            
	            GP.quadFromFourPoints("PlankL_"..z.."_"..x, pl1, pl2 + Vector3.new(0, 0, 2e-3), pl3, pl4, plankThick, upDir, pColor, matWood, roofModel) -- zf-prevention: vector3_component
	            
	            -- Right Side Planks (-X)
	            if prand(z * 101 + x) > severity then
	                local rx1 = MU.lerp(0, rightX - overhang, t)
	                local rx2 = MU.lerp(0, rightX - overhang, t + 1/numPlanksX)
	                local ry1 = MU.lerp(peakY, eaveY, t)
	                local ry2 = MU.lerp(peakY, eaveY, t + 1/numPlanksX)
	                
	                local pr1 = Vector3.new(rx2, ry2 - tilt, pz + 0.1)
	                local pr2 = Vector3.new(rx1, ry1 + tilt, pz + 0.1)
	                local pr3 = Vector3.new(rx1, ry1 + tilt, pz + plankW - 0.1)
	                local pr4 = Vector3.new(rx2, ry2 - tilt, pz + plankW - 0.1)
	                
	                GP.quadFromFourPoints("PlankR_"..z.."_"..x, pr1, pr2, pr3, pr4, plankThick, upDir, pColor, matWood, roofModel)
	            end
	        end
	    end
	end
	
	
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

return AbandonedFarmhouse

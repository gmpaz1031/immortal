--!strict
-- generationId: 9257e6f6-103e-4ac3-be83-cdf0e42ca69d
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local MuddyPathSegment = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		RutSpacing: number?,
		RutWidth: number?,
		RutDepth: number?,
		MudColor: Color3?,
		MudMaterial: string?,
		WaterColor: Color3?,
		WaterMaterial: string?,
		RockColor: Color3?,
		RockMaterial: string?,
		MossColor: Color3?,
		MossMaterial: string?,
		WoodColor: Color3?,
		WoodMaterial: string?,
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

MuddyPathSegment.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	local GP = GP
	local CSG = CSG
	local SO = SO
	local MU = MU
	
	local pathModel = GP.model("MuddyPathSegment", nil)-- Fix orientation of the model
	pathModel.WorldPivot = CFrame.identity
	
	
	-- ==========================================
	-- SEMANTIC PARAMETERS & SMART SCALING
	-- ==========================================
	local smartWidth = parameters.Size.X
	local smartHeight = parameters.Size.Y
	local smartDepth = parameters.Size.Z
	
	local rutSpacing = parameters.Attributes.RutSpacing or 7.0
	local rutWidth = parameters.Attributes.RutWidth or 2.2
	local rutDepth = parameters.Attributes.RutDepth or 0.6
	
	-- Colors & Materials
	local mudColor = parameters.Attributes.MudColor or Color3.fromRGB(60, 45, 30)
	local mudMat = parameters.Attributes.MudMaterial or "Mud"
	
	local waterColor = parameters.Attributes.WaterColor or Color3.fromRGB(80, 65, 45)
	local waterMat = parameters.Attributes.WaterMaterial or "Foil" -- Foil gives a nice wet reflection
	
	local rockColor = parameters.Attributes.RockColor or Color3.fromRGB(75, 70, 65)
	local rockMat = parameters.Attributes.RockMaterial or "Slate"
	
	local mossColor = parameters.Attributes.MossColor or Color3.fromRGB(70, 90, 40)
	local mossMat = parameters.Attributes.MossMaterial or "Grass"
	
	local woodColor = parameters.Attributes.WoodColor or Color3.fromRGB(45, 30, 20)
	local woodMat = parameters.Attributes.WoodMaterial or "Wood"
	
	-- ==========================================
	-- PATH CURVE DEFINITION
	-- ==========================================
	-- Define a gentle 'S' curve from back (+Z) to front (-Z)
	-- Path bends to the viewer's right (-X) then straightens
	local p0 = Vector3.new(0, smartHeight, smartDepth / 2)
	local p1 = Vector3.new(smartWidth * 0.1, smartHeight, smartDepth * 0.2)
	local p2 = Vector3.new(-smartWidth * 0.2, smartHeight, -smartDepth * 0.2)
	local p3 = Vector3.new(-smartWidth * 0.1, smartHeight, -smartDepth / 2)
	
	local segments = 8
	local pathPoints = MU.sampleBezierPoints(p0, p1, p2, p3, segments)
	
	-- Helper function to get tangent at a point
	local function getTangent(t)
		local t0 = math.clamp(t - 0.01, 0, 1)
		local t1 = math.clamp(t + 0.01, 0, 1)
		local pt0 = MU.bezier(t0, p0, p1, p2, p3)
		local pt1 = MU.bezier(t1, p0, p1, p2, p3)
		return (pt0 - pt1).Unit -- Direction from back to front
	end
	
	-- Collect left/right edge points and rut center points
	local leftEdges = {}
	local rightEdges = {}
	local leftRutPts = {}
	local rightRutPts = {}
	
	for i = 0, segments do
		local t = i / segments
		local pt = MU.bezier(t, p0, p1, p2, p3)
		local tangent = getTangent(t)
		
		-- Normal is UP, so cross product gives us left/right directions
		local rightDir = tangent:Cross(Vector3.yAxis).Unit -- Points to Viewer's Right (-X generally)
		local leftDir = -rightDir -- Points to Viewer's Left (+X generally)
		
		table.insert(leftEdges, pt + leftDir * (smartWidth / 2))
		table.insert(rightEdges, pt + rightDir * (smartWidth / 2))
		
		table.insert(leftRutPts, pt + leftDir * (rutSpacing / 2))
		table.insert(rightRutPts, pt + rightDir * (rutSpacing / 2))
	end
	
	-- ==========================================
	-- CSG CONSTRUCTION: MUD BASE & RUTS
	-- ==========================================
	local csgTemp = GP.model("CSG_Temp", pathModel)
	
	-- 1. Build the solid base from quads
	local baseQuads = {}
	for i = 1, segments do
		local idx1 = i
		local idx2 = i + 1
		
		local qP1 = leftEdges[idx1]  -- Left Back
		local qP2 = rightEdges[idx1] -- Right Back
		local qP3 = rightEdges[idx2] -- Right Front
		local qP4 = leftEdges[idx2]  -- Left Front
		
		-- Extrude downwards to create thickness
		local quad = GP.quadFromFourPoints("BaseSegment_"..i, qP1, qP2, qP3, qP4, smartHeight, Vector3.new(0, -1, 0), mudColor, mudMat, csgTemp)
		table.insert(baseQuads, quad)
	end
	
	-- Union all base segments
	local mainBase = baseQuads[1]
	local otherBases = {}
	for i = 2, #baseQuads do table.insert(otherBases, baseQuads[i]) end
	local unionBase = CSG.union("UnionBase", mainBase, otherBases)
	
	-- 2. Build the ruts (subtract tubes)
	-- Offset the rut points down so the tube cuts into the surface
	local cutRadius = rutWidth / 2
	local lRutCuts = {}
	local rRutCuts = {}
	for i, pt in ipairs(leftRutPts) do
		lRutCuts[i] = pt - Vector3.new(0, cutRadius - rutDepth, 0)
	end
	for i, pt in ipairs(rightRutPts) do
		rRutCuts[i] = pt - Vector3.new(0, cutRadius - rutDepth, 0)
	end
	
	local leftRutTube = GP.tube("LeftRutCut", lRutCuts, cutRadius, mudColor, mudMat, csgTemp)
	local rightRutTube = GP.tube("RightRutCut", rRutCuts, cutRadius, mudColor, mudMat, csgTemp)
	
	-- Extend ends slightly to ensure clean cuts at the boundaries
	local leftRutCutUnion = CSG.union("AllRuts", leftRutTube, {rightRutTube})
	
	-- 3. Perform Subtraction
	local finalMudPath = CSG.subtract("MudSurface", unionBase, {leftRutCutUnion})
	finalMudPath.Parent = pathModel
	finalMudPath.Color = mudColor
	finalMudPath.Material = mudMat
	
	-- ==========================================
	-- PUDDLES / WATER IN RUTS
	-- ==========================================
	local puddlesModel = GP.model("Puddles", pathModel)
	-- We'll create small segments of water lying in the ruts
	-- Puddle height is slightly above the deepest part of the rut
	local puddleY = smartHeight - rutDepth + 0.15
	
	for i = 1, segments - 1 do
		-- Skip some segments randomly to make isolated puddles
		if i % 2 == 1 or i == segments / 2 then
			-- Left Puddle
			local lp1 = leftRutPts[i]
			local lp2 = leftRutPts[i+1]
			local lDist = (lp1 - lp2).Magnitude
			-- We use a flat box to avoid z-fighting with the curved rut bottom
			local lCenter = (lp1 + lp2) / 2
			lCenter = Vector3.new(lCenter.X, puddleY, lCenter.Z)
			
			-- Simple alignment hack using lookAt logic manually:
			local dir = (lp2 - lp1).Unit
			local w = rutWidth * 0.75
			local right = dir:Cross(Vector3.yAxis).Unit
			
			-- Create a thin quad for the puddle
			local wq1 = lCenter - dir * (lDist/2) + right * (w/2)
			local wq2 = lCenter - dir * (lDist/2) - right * (w/2)
			local wq3 = lCenter + dir * (lDist/2) - right * (w/2)
			local wq4 = lCenter + dir * (lDist/2) + right * (w/2)
			
			GP.quadFromFourPoints("LeftPuddle_"..i, wq1, wq2, wq3, wq4, 0.05, Vector3.yAxis, waterColor, waterMat, puddlesModel)
			
			-- Right Puddle
			local rp1 = rightRutPts[i]
			local rp2 = rightRutPts[i+1]
			local rDist = (rp1 - rp2).Magnitude
			local rCenter = (rp1 + rp2) / 2
			rCenter = Vector3.new(rCenter.X, puddleY, rCenter.Z)
			
			local rDir = (rp2 - rp1).Unit
			local rRight = rDir:Cross(Vector3.yAxis).Unit
			
			local rq1 = rCenter - rDir * (rDist/2) + rRight * (w/2)
			local rq2 = rCenter - rDir * (rDist/2) - rRight * (w/2)
			local rq3 = rCenter + rDir * (rDist/2) - rRight * (w/2)
			local rq4 = rCenter + rDir * (rDist/2) + rRight * (w/2)
			
			GP.quadFromFourPoints("RightPuddle_"..i, rq1, rq2, rq3, rq4, 0.05, Vector3.yAxis, waterColor, waterMat, puddlesModel)
		end
	end
	
	-- ==========================================
	-- DEBRIS SCATTERING
	-- ==========================================
	local debrisModel = GP.model("Debris", pathModel)
	
	local debrisCount = math.floor(smartDepth * 2.5)
	
	for i = 1, debrisCount do
		-- Pseudo-random t along the path
		local t = (math.sin(i * 13.5) * 0.5 + 0.5)
		
		local pt = MU.bezier(t, p0, p1, p2, p3)
		local tangent = getTangent(t)
		local leftDir = -(tangent:Cross(Vector3.yAxis).Unit)
		
		-- Distribute across the width: mostly on edges, some in the middle ridge
		-- Cross-section normalized from -1 (Right Edge) to 1 (Left Edge)
		local lateralPos = math.cos(i * 7.2)
		
		-- Avoid the ruts
		local rutThreshold = (rutSpacing / smartWidth) -- roughly 0.43
		local rutWNormalized = (rutWidth / smartWidth) -- roughly 0.13
		
		-- Snap out of ruts if inside them
		if math.abs(lateralPos) > (rutThreshold - rutWNormalized) and math.abs(lateralPos) < (rutThreshold + rutWNormalized) then
			if lateralPos > 0 then
				lateralPos = rutThreshold + rutWNormalized + 0.05
			else
				lateralPos = -(rutThreshold + rutWNormalized + 0.05)
			end
		end
		
		local offsetDist = lateralPos * (smartWidth / 2 * 0.85) -- keep slightly inside outer edge
		local spawnPos = pt + leftDir * offsetDist
		
		-- Randomize type based on index
		local typeVal = i % 10
		
		if typeVal < 5 then
			-- Mud clump / Pebble
			local r = 0.1 + (math.sin(i*9) * 0.5 + 0.5) * 0.2
			-- Sink into ground slightly
			local pos = spawnPos - Vector3.new(0, r * 0.4, 0)
			GP.roundedBox("MudClump_"..i, pos, Vector3.new(r*2.5, r*1.5, r*2), r*0.4, mudColor, mudMat, debrisModel)
			
		elseif typeVal < 7 then
			-- Rock
			local r = 0.2 + (math.cos(i*4) * 0.5 + 0.5) * 0.3
			local pos = spawnPos - Vector3.new(0, r * 0.3, 0)
			GP.sphere("Rock_"..i, pos, r, rockColor, rockMat, debrisModel)
			
		elseif typeVal < 9 then
			-- Moss patch (mostly near extreme edges)
			if math.abs(lateralPos) > 0.7 then
				local r = 0.4 + (math.sin(i*11) * 0.5 + 0.5) * 0.4
				local pos = spawnPos - Vector3.new(0, r * 0.6, 0)
				GP.hemisphere("Moss_"..i, pos, pos + Vector3.new(0, r, 0), mossColor, mossMat, debrisModel)
			end
			
		else
			-- Twig
			local length = 0.6 + (math.cos(i*17) * 0.5 + 0.5) * 0.8
			local thick = 0.05 + (math.sin(i*3) * 0.5 + 0.5) * 0.05
			
			-- Random rotation on ground plane
			local angle = math.sin(i) * math.pi
			local dir = (tangent * math.cos(angle) + leftDir * math.sin(angle)).Unit
			
			local tP1 = spawnPos - dir * (length/2) + Vector3.new(0, thick, 0)
			local tP2 = spawnPos + dir * (length/2) + Vector3.new(0, thick, 0)
			
			GP.cylinder("Twig_"..i, tP1, tP2, thick, woodColor, woodMat, debrisModel)
		end
	end
	
	-- Clean up
	csgTemp:Destroy()
	
	
	pathModel.Parent = targetContainer
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

return MuddyPathSegment

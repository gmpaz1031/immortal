--!strict
-- generationId: a1251bc9-5605-4429-a2d1-25ca56b2c496
local CSG = require(script.Dependencies.ConstructiveSolidGeometry)
local GP = require(script.Dependencies.GeometryPrimitives)
local SO = require(script.Dependencies.SmartObject)
local MU = require(script.Dependencies.MathUtils)


local ModularFence = {}

type Parameters = {
	Size: Vector3,
	Attributes: {
		WoodColor: Color3?,
		WoodMaterial: string?,
		PostSpacing: number?,
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

ModularFence.OnGenerate = function(parameters: Parameters, targetContainer: Instance)
	-- Timer setup
	startTime = tick()

	-- local GP = require(script.Parent.GeometryPrimitives)
	-- local CSG = require(script.Parent.ConstructiveSolidGeometry)
	-- local SO = require(script.Parent.SmartObject)
	
	local myModel = GP.model("ModularFence", nil)-- Fix orientation of the model
	myModel.WorldPivot = CFrame.identity
	
	
	-- == ATTRIBUTES ==
	local smartWidth = parameters.Size.X
	local smartHeight = parameters.Size.Y
	local smartDepth = parameters.Size.Z
	
	local woodColor = parameters.Attributes.WoodColor or Color3.fromRGB(130, 110, 90)
	local woodMaterial = parameters.Attributes.WoodMaterial or "WoodPlanks"
	
	local postSpacing = parameters.Attributes.PostSpacing or 2.5
	
	-- == CALCULATIONS ==
	local postWidth = smartDepth * 0.8
	local postDepth = smartDepth * 0.8
	local railHeight = smartDepth * 0.6
	local railDepth = smartDepth * 0.5
	local cornerRadius = math.min(postWidth, postDepth, railHeight, railDepth) * 0.2
	
	-- Determine number of posts based on smartWidth
	local postCount = math.max(2, math.floor(smartWidth / postSpacing) + 1)
	local actualSpacing = smartWidth / (postCount - 1)
	
	-- Layout coordinates
	local topRailY = smartHeight * 0.75
	local bottomRailY = smartHeight * 0.25
	local railZ = -postDepth * 0.4 -- Offset to the back (-Z)
	
	-- == BUILD FENCE POSTS ==
	local postsModel = GP.model("fence posts", myModel)
	
	for i = 1, postCount do
	    -- Distribute from right to left (object's right is +X, left is -X)
	    -- Actually, left to right from viewer is +X to -X
	    local xPos = (smartWidth / 2) - ((i - 1) * actualSpacing)
	    
	    local postCenter = Vector3.new(xPos, smartHeight / 2, 0)
	    local postSize = Vector3.new(postWidth, smartHeight, postDepth)
	    
	    GP.roundedBox("Post_" .. i, postCenter, postSize, cornerRadius, woodColor, woodMaterial, postsModel)
	end
	
	-- == BUILD HORIZONTAL RAILS ==
	local railsModel = GP.model("horizontal rails", myModel)
	
	-- Extend rails slightly past the end posts
	local railExtension = postWidth * 0.5
	local railLength = smartWidth + (railExtension * 2)
	
	-- Top Rail
	local topRailCenter = Vector3.new(0, topRailY, railZ)
	local topRailSize = Vector3.new(railLength, railHeight, railDepth)
	GP.roundedBox("TopRail", topRailCenter, topRailSize, cornerRadius, woodColor, woodMaterial, railsModel)
	
	-- Bottom Rail
	local bottomRailCenter = Vector3.new(0, bottomRailY, railZ)
	local bottomRailSize = Vector3.new(railLength, railHeight, railDepth)
	GP.roundedBox("BottomRail", bottomRailCenter, bottomRailSize, cornerRadius, woodColor, woodMaterial, railsModel)
	
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

return ModularFence

local Players = game:GetService("Players")

local zombie = script.Parent
local humanoid = zombie:WaitForChild("Humanoid")
local root = zombie:WaitForChild("HumanoidRootPart")

local CHASE_DISTANCE = 80
local ATTACK_DISTANCE = 4
local DAMAGE = 15
local ATTACK_COOLDOWN = 1
local SPAWN_CFRAME = root.CFrame -- capture actual placed position

zombie.PrimaryPart = root

for _, instance in zombie:GetChildren() do
	if instance:IsA("BasePart") then
		instance.Anchored = false
		instance.Massless = instance ~= root
		instance.CanCollide = instance == root
		if instance ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = instance
			weld.Parent = instance
		end
	end
end

local function nearestLivingPlayer()
	local closestHumanoid, closestRoot, closestDistance

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if targetHumanoid and targetRoot and targetHumanoid.Health > 0 then
			local distance = (targetRoot.Position - root.Position).Magnitude
			if distance <= CHASE_DISTANCE and (not closestDistance or distance < closestDistance) then
				closestHumanoid = targetHumanoid
				closestRoot = targetRoot
				closestDistance = distance
			end
		end
	end

	return closestHumanoid, closestRoot, closestDistance
end

humanoid.Died:Connect(function()
	-- Award gold to nearby living players
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local pRoot = character and character:FindFirstChild("HumanoidRootPart")
		if pRoot and (pRoot.Position - root.Position).Magnitude <= 35 then
			local leaderstats = player:FindFirstChild("leaderstats")
			local gold = leaderstats and leaderstats:FindFirstChild("Gold")
			if gold then
				local reward = math.random(15, 25)
				gold.Value = gold.Value + reward
			end
		end
	end

	-- Respawn after 5 seconds
	task.wait(5)
	if root and humanoid then
		root.CFrame = SPAWN_CFRAME
		humanoid.Health = humanoid.MaxHealth
	end
end)

local nextAttack = 0
while true do
	if humanoid.Health > 0 then
		local targetHumanoid, targetRoot, distance = nearestLivingPlayer()
		if targetRoot then
			humanoid:MoveTo(targetRoot.Position)
			if distance <= ATTACK_DISTANCE and time() >= nextAttack then
				local targetChar = targetHumanoid.Parent
				local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
				local playerDef = targetPlayer and (targetPlayer:GetAttribute("Defense") or 0) or 0
				targetHumanoid:TakeDamage(math.max(1, DAMAGE - playerDef))
				nextAttack = time() + ATTACK_COOLDOWN
			end
		end
	end
	task.wait(0.2)
end

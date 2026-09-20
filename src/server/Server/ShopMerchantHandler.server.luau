--!strict
-- src/server/ShopMerchantHandler.server.luau
-- Attaches an interactive ProximityPrompt to the village Pill Merchant

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("CultivationRemote") :: RemoteEvent

local function setupMerchant()
	local merchant = Workspace:WaitForChild("ShopMerchant", 10)
	if not merchant then return end

	local promptPart = merchant:FindFirstChild("HumanoidRootPart") or merchant:FindFirstChild("ShopCircle") or merchant.PrimaryPart
	if not promptPart and merchant:IsA("Model") then
		promptPart = merchant:FindFirstChildWhichIsA("BasePart")
	end

	if promptPart then
		local prompt = promptPart:FindFirstChild("ShopPrompt") :: ProximityPrompt?
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.Name = "ShopPrompt"
			prompt.ActionText = "Trade / Shop"
			prompt.ObjectText = "Pill Herbalist · Senior Sister"
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Parent = promptPart
		else
			prompt.ActionText = "Trade / Shop"
			prompt.ObjectText = "Pill Herbalist · Senior Sister"
		end

		prompt.Triggered:Connect(function(player: Player)
			remote:FireClient(player, "OpenShop")
		end)
		print("[ShopMerchant] Interactive ProximityPrompt attached to ShopMerchant.")
	end
end

task.spawn(setupMerchant)

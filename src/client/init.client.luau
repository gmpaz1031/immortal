local StarterGui = game:GetService("StarterGui")

-- Rule 6.2: Keep default Roblox CoreGui Backpack disabled in favor of custom UI
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

print("[Client] Initialized with CoreGui Backpack disabled.")

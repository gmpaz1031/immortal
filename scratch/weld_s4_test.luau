local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local ra = s4 and s4:FindFirstChild("Right Arm")
local weapon = s4 and s4:FindFirstChild("EquippedWeapon")
if not ra or not weapon then return "No s4" end

local guard = weapon:FindFirstChild("JianGuard")
local hilt = weapon:FindFirstChild("JianHilt")

-- Let's inspect current relative CFrame
local relHilt = ra.CFrame:Inverse() * hilt.CFrame
local relGuard = ra.CFrame:Inverse() * guard.CFrame

-- Create weld between Right Arm and JianGuard or JianHilt
local w = ra:FindFirstChild("WeaponGripWeld") or Instance.new("Weld")
w.Name = "WeaponGripWeld"
w.Part0 = ra
w.Part1 = guard
w.C0 = relGuard
w.C1 = CFrame.new()
w.Parent = ra

return game:GetService("HttpService"):JSONEncode({
    success = true,
    C0 = tostring(w.C0),
    guardPos = tostring(guard.Position),
    raPos = tostring(ra.Position)
})

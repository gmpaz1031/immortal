local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local ra = s4 and s4:FindFirstChild("Right Arm")
local weapon = s4 and s4:FindFirstChild("EquippedWeapon")
if not ra or not weapon then return "No ra or weapon" end

local guard = weapon:FindFirstChild("JianGuard") or weapon:FindFirstChild("WeaponBlade") or weapon:FindFirstChild("JianHilt")
local hilt = weapon:FindFirstChild("JianHilt")
local blade = weapon:FindFirstChild("WeaponBlade")

local relGuard = ra.CFrame:Inverse() * guard.CFrame
local relHilt = ra.CFrame:Inverse() * hilt.CFrame
local relBlade = ra.CFrame:Inverse() * blade.CFrame

local function cfToStr(cf)
    local x, y, z = cf.X, cf.Y, cf.Z
    local rx, ry, rz = cf:ToOrientation()
    return string.format("Pos(%.4f, %.4f, %.4f) RotDeg(%.2f, %.2f, %.2f)", x, y, z, math.deg(rx), math.deg(ry), math.deg(rz))
end

return game:GetService("HttpService"):JSONEncode({
    Hilt = cfToStr(relHilt),
    Guard = cfToStr(relGuard),
    Blade = cfToStr(relBlade),
    HiltMatrix = tostring(relHilt),
    GuardMatrix = tostring(relGuard),
    BladeMatrix = tostring(relBlade),
})

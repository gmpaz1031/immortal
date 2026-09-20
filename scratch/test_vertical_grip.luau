local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local weaponModel = s1 and s1:FindFirstChild("EquippedWeapon")
local rightArm = s1 and s1:FindFirstChild("Right Arm")
local gripPart = weaponModel and weaponModel:FindFirstChild("KatanaHilt")
local weld = rightArm and rightArm:FindFirstChildOfClass("Weld")

if weld and gripPart then
    -- Let's test standard vertical grip:
    -- Hand is at (0, -1, 0). Hilt is in the hand.
    -- Blade extends UPWARD (+Y in Right Arm) or slightly tilted forward/outward.
    -- In Right Arm space: CFrame.new(0, -0.9, -0.1) * CFrame.Angles(math.rad(15), 0, math.rad(-5))
    weld.C0 = CFrame.new(0, -0.85, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-5))
    return "Updated weld C0"
end
return "Failed to find weld"

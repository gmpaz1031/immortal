local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local root = s1 and s1:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

if cam and root then
    local camCF = root.CFrame * CFrame.new(2, 0.5, -8) * CFrame.Angles(0, math.rad(165), 0)
    cam.CFrame = camCF
    return "Camera adjusted"
end
return "Failed"

local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local root = s1 and s1:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

if cam and root then
    -- Put camera directly in front of Swordsman_1 looking at his torso and right arm
    local camCF = root.CFrame * CFrame.new(0, 0.5, -5) * CFrame.Angles(0, math.rad(180), 0)
    cam.CFrame = camCF
    return "Camera positioned at Swordsman_1: " .. tostring(camCF.Position)
end
return "Failed to find Swordsman_1 or cam"

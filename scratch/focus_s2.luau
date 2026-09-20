local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s2 = enemies and enemies:FindFirstChild("Swordsman_2")
local root = s2 and s2:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

if cam and root then
    cam.CameraType = Enum.CameraType.Scriptable
    local target = root.Position + Vector3.new(0, 0.5, 0)
    local eye = root.Position + (root.CFrame.LookVector * 6) + Vector3.new(1.5, 0.5, 0)
    cam.CFrame = CFrame.lookAt(eye, target)
    return "Camera focused on Swordsman_2"
end
return "Failed to focus on Swordsman_2"

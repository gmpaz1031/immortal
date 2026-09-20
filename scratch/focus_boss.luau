local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local boss = enemies and enemies:FindFirstChild("Swordmaster_Boss")
local root = boss and boss:FindFirstChild("HumanoidRootPart")
local cam = workspace.CurrentCamera

if cam and root then
    cam.CameraType = Enum.CameraType.Scriptable
    local target = root.Position + Vector3.new(0, 1.0, 0)
    local eye = root.Position + (root.CFrame.LookVector * 10) + Vector3.new(2, 1.5, 0)
    cam.CFrame = CFrame.lookAt(eye, target)
    return "Camera focused on Boss"
end
return "Failed to focus on Boss"

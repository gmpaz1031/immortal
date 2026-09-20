local cam = workspace.CurrentCamera
local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local root = s1 and s1:FindFirstChild("HumanoidRootPart")

if cam and root then
    cam.CameraType = Enum.CameraType.Scriptable
    -- Face Swordsman_1 from 6 studs away, looking directly at his chest and sword
    local target = root.Position + Vector3.new(0, 0.5, 0)
    local eye = root.Position + (root.CFrame.LookVector * 6) + Vector3.new(0, 0.5, 0)
    cam.CFrame = CFrame.lookAt(eye, target)
    return "Camera set to Scriptable and focused"
end
return "Failed"

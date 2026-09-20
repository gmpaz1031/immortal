local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
local ra = s1 and s1:FindFirstChild("Right Arm")
if not ra then return "No Right Arm" end

return game:GetService("HttpService"):JSONEncode({
    Size = tostring(ra.Size),
    CFrame = tostring(ra.CFrame),
    LookVector = tostring(ra.CFrame.LookVector),
    UpVector = tostring(ra.CFrame.UpVector),
    RightVector = tostring(ra.CFrame.RightVector),
})

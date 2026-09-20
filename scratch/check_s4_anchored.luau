local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
local weapon = s4 and s4:FindFirstChild("EquippedWeapon")
if not weapon then return "No weapon" end

local result = {}
for _, p in ipairs(weapon:GetChildren()) do
    if p:IsA("BasePart") then
        table.insert(result, {
            Name = p.Name,
            Anchored = p.Anchored,
            CanCollide = p.CanCollide,
            Massless = p.Massless,
            WeldCount = #p:GetChildren()
        })
    end
end
return game:GetService("HttpService"):JSONEncode(result)

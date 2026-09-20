local enemiesFolder = workspace:FindFirstChild("DestroyedVillage_Enemies")
if not enemiesFolder then
    return game:GetService("HttpService"):JSONEncode({ error = "DestroyedVillage_Enemies not found" })
end

local FORWARD_GRIP_ROT = CFrame.fromMatrix(
    Vector3.new(),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 0, -1),
    Vector3.new(0, -1, 0)
)

local results = {}
local expectedEnemies = {
    "Swordsman_1",
    "Swordsman_2",
    "Swordsman_3",
    "Swordsman_4",
    "Swordsman_5",
    "Swordmaster_Boss"
}

for _, name in ipairs(expectedEnemies) do
    local enemy = enemiesFolder:FindFirstChild(name)
    if not enemy then
        results[name] = { exists = false }
    else
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local hrp = enemy:FindFirstChild("HumanoidRootPart")
        local torso = enemy:FindFirstChild("Torso")
        local rightArm = enemy:FindFirstChild("Right Arm")
        local weapon = enemy:FindFirstChild("EquippedWeapon")
        
        local weaponDetails = {}
        if weapon then
            for _, p in ipairs(weapon:GetChildren()) do
                if p:IsA("BasePart") then
                    local weld = p:FindFirstChildOfClass("Weld")
                    table.insert(weaponDetails, {
                        name = p.Name,
                        weldPart0 = weld and weld.Part0 and weld.Part0.Name or "nil",
                        weldPart1 = weld and weld.Part1 and weld.Part1.Name or "nil",
                    })
                end
            end
        end

        local rootJoint = torso and torso:FindFirstChild("RootJoint")
        local rightArmWeld = rightArm and rightArm:FindFirstChildOfClass("Weld")

        results[name] = {
            exists = true,
            hasHumanoid = hum ~= nil,
            hasHrp = hrp ~= nil,
            hasTorso = torso ~= nil,
            hasRightArm = rightArm ~= nil,
            hasWeapon = weapon ~= nil,
            weaponPartCount = #weaponDetails,
            weaponParts = weaponDetails,
        }
    end
end

return game:GetService("HttpService"):JSONEncode(results)

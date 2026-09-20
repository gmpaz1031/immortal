local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local kfs = KeyframeSequenceProvider:GetKeyframeSequenceAsync("rbxassetid://243827693")

local frames = {}
for _, kf in ipairs(kfs:GetKeyframes()) do
    local entry = { time = kf.Time }
    for _, p in ipairs(kf:GetPoses()) do
        for _, sub in ipairs(p:GetSubPoses()) do
            for _, sub2 in ipairs(sub:GetSubPoses()) do
                if sub2.Name == "Right Arm" then
                    local rx, ry, rz = sub2.CFrame:ToOrientation()
                    entry.rightArmRot = { math.deg(rx), math.deg(ry), math.deg(rz) }
                end
            end
        end
    end
    table.insert(frames, entry)
end

return game:GetService("HttpService"):JSONEncode(frames)

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local function inspectKFS(id: string)
    local kfs = KeyframeSequenceProvider:GetKeyframeSequenceAsync("rbxassetid://" .. id)
    local result = { id = id, keyframes = {} }
    for _, kf in ipairs(kfs:GetKeyframes()) do
        local poseNames = {}
        for _, p in ipairs(kf:GetPoses()) do
            table.insert(poseNames, p.Name)
            for _, sub in ipairs(p:GetSubPoses()) do
                table.insert(poseNames, "  " .. sub.Name)
                for _, sub2 in ipairs(sub:GetSubPoses()) do
                    table.insert(poseNames, "    " .. sub2.Name)
                end
            end
        end
        table.insert(result.keyframes, { time = kf.Time, poses = poseNames })
    end
    return result
end

local r1 = inspectKFS("74897796")
local r2 = inspectKFS("243827693")

return game:GetService("HttpService"):JSONEncode({ r1 = r1, r2 = r2 })

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local function getSummary(id: string)
    local kfs = KeyframeSequenceProvider:GetKeyframeSequenceAsync("rbxassetid://" .. id)
    local affected = {}
    for _, kf in ipairs(kfs:GetKeyframes()) do
        for _, p in ipairs(kf:GetPoses()) do
            affected[p.Name] = true
            for _, s in ipairs(p:GetSubPoses()) do
                affected[s.Name] = true
                for _, s2 in ipairs(s:GetSubPoses()) do
                    affected[s2.Name] = true
                end
            end
        end
    end
    return affected
end

return game:GetService("HttpService"):JSONEncode({
    slash = getSummary("129967390"),
    overhead = getSummary("125750867"),
})

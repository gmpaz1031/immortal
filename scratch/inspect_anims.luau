local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local ids = {"74897796", "243827693", "129967390", "125750867"}
local info = {}

for _, id in ipairs(ids) do
    local s, kfs = pcall(function()
        return KeyframeSequenceProvider:GetKeyframeSequenceAsync("rbxassetid://" .. id)
    end)
    if s and kfs then
        local kfsName = kfs.Name
        local keyframeNames = {}
        for _, kf in ipairs(kfs:GetKeyframes()) do
            table.insert(keyframeNames, kf.Name)
        end
        info[id] = {
            Name = kfsName,
            Keyframes = keyframeNames,
            Count = #keyframeNames
        }
    else
        info[id] = { Error = tostring(kfs) }
    end
end

return game:GetService("HttpService"):JSONEncode(info)

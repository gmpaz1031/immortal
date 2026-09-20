import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy_pickaxe():
    print("=== Deploying Xianxia Novice Pickaxe Tool to StarterPack & ServerStorage ===")

    lua_pickaxe = """
    local StarterPack = game:GetService("StarterPack")
    local ServerStorage = game:GetService("ServerStorage")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- Clean old pickaxes
    for _, ch in ipairs(StarterPack:GetChildren()) do
        if ch.Name == "Novice Pickaxe" then ch:Destroy() end
    end
    for _, ch in ipairs(ServerStorage:GetChildren()) do
        if ch.Name == "Novice Pickaxe" then ch:Destroy() end
    end

    -- Ensure MiningRemote exists
    local remote = ReplicatedStorage:FindFirstChild("MiningRemote")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "MiningRemote"
        remote.Parent = ReplicatedStorage
    end

    local tool = Instance.new("Tool")
    tool.Name = "Novice Pickaxe"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool.Grip = CFrame.new(0, -0.6, 0) * CFrame.Angles(math.rad(-90), 0, 0)

    -- Handle (Invisible primary anchor part for Roblox tool system)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.4, 2.8, 0.4)
    handle.Transparency = 1
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool

    -- Visual Parts
    local function makeToolPart(name, size, cf, color, mat)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.CFrame = cf
        p.Color = color
        p.Material = mat or Enum.Material.Metal
        p.CanCollide = false
        p.CastShadow = false
        p.Massless = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = tool

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = handle
        weld.Part1 = p
        weld.Parent = p
        return p
    end

    local function makeToolWedge(name, size, cf, color, mat)
        local w = Instance.new("WedgePart")
        w.Name = name
        w.Size = size
        w.CFrame = cf
        w.Color = color
        w.Material = mat or Enum.Material.Metal
        w.CanCollide = false
        w.CastShadow = false
        w.Massless = true
        w.TopSurface = Enum.SurfaceType.Smooth
        w.BottomSurface = Enum.SurfaceType.Smooth
        w.Parent = tool

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = handle
        weld.Part1 = w
        weld.Parent = w
        return w
    end

    local hCf = handle.CFrame
    -- 1. Hardwood Shaft
    makeToolPart("Shaft", Vector3.new(0.24, 2.6, 0.24), hCf * CFrame.new(0, 0, 0), Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
    makeToolPart("ShaftGripWrap", Vector3.new(0.28, 0.9, 0.28), hCf * CFrame.new(0, -0.6, 0), Color3.fromRGB(60, 42, 28), Enum.Material.Fabric)

    -- 2. Bronze Reinforcing Collar
    makeToolPart("BronzeCollar", Vector3.new(0.35, 0.35, 0.35), hCf * CFrame.new(0, 1.15, 0), Color3.fromRGB(180, 140, 70), Enum.Material.Metal)

    -- 3. Forged Double-Pick Head
    local headCf = hCf * CFrame.new(0, 1.3, 0)
    makeToolPart("PickHead", Vector3.new(0.32, 0.38, 1.4), headCf, Color3.fromRGB(145, 148, 155), Enum.Material.Metal)
    -- Front Chisel Tip
    makeToolWedge("FrontTip", Vector3.new(0.3, 0.35, 0.5), headCf * CFrame.new(0, -0.05, 0.95) * CFrame.Angles(0, math.rad(180), 0), Color3.fromRGB(180, 185, 195), Enum.Material.Metal)
    -- Rear Claw Spike
    makeToolWedge("RearSpike", Vector3.new(0.28, 0.32, 0.45), headCf * CFrame.new(0, -0.05, -0.925), Color3.fromRGB(160, 165, 175), Enum.Material.Metal)

    -- Swing sound inside handle
    local swingSound = Instance.new("Sound")
    swingSound.Name = "SwingSound"
    swingSound.SoundId = "rbxassetid://169445121"
    swingSound.Volume = 0.6
    swingSound.Parent = handle

    -- Client Tool Controller Script (Handles smooth swing animation and raycast strike)
    local localScript = Instance.new("LocalScript")
    localScript.Name = "PickaxeClient"
    localScript.Source = [====[
        local Tool = script.Parent
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local player = Players.LocalPlayer
        local remote = ReplicatedStorage:WaitForChild("MiningRemote") :: RemoteEvent
        local swingSound = Tool:WaitForChild("Handle"):WaitForChild("SwingSound") :: Sound

        local canSwing = true
        local swingCooldown = 0.55

        local swingAnimation = Instance.new("Animation")
        swingAnimation.AnimationId = "rbxassetid://522635514" -- Standard tool slash/swing animation

        local animTrack = nil

        Tool.Equipped:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator") or hum
                pcall(function()
                    animTrack = animator:LoadAnimation(swingAnimation)
                end)
            end
        end)

        Tool.Unequipped:Connect(function()
            if animTrack then
                animTrack:Stop()
            end
        end)

        Tool.Activated:Connect(function()
            if not canSwing then return end
            canSwing = false

            swingSound:Play()
            if animTrack then
                animTrack:Play(0.1, 1, 1.25)
            end

            -- Raycast forward from camera / character root to find targeted ore
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local rayOrigin = hrp.Position + Vector3.new(0, 1, 0)
                local lookDir = hrp.CFrame.LookVector
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = { char }
                raycastParams.FilterType = RaycastFilterType.Exclude

                local result = workspace:Raycast(rayOrigin, lookDir * 8.5, raycastParams)
                if result and result.Instance then
                    local model = result.Instance:FindFirstAncestorOfClass("Model")
                    if model and model:GetAttribute("OreName") then
                        remote:FireServer("MineHit", model)
                    end
                else
                    -- Fallback: check closest ore within 8 studs
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Model") and obj:GetAttribute("OreName") and not obj:GetAttribute("Mined") then
                            local orePos = obj:GetPivot().Position
                            if (orePos - hrp.Position).Magnitude <= 8.5 then
                                remote:FireServer("MineHit", obj)
                                break
                            end
                        end
                    end
                end
            end

            task.wait(swingCooldown)
            canSwing = true
        end)
    ]====]
    localScript.Parent = tool

    -- Save copy in ServerStorage
    local ssCopy = tool:Clone()
    ssCopy.Parent = ServerStorage

    -- Put in StarterPack so all players get it on spawn
    tool.Parent = StarterPack

    return "Successfully deployed Novice Pickaxe to StarterPack and ServerStorage!"
    """

    ok, res = exec_code(lua_pickaxe)
    print("Deploy Pickaxe Result:", ok, res)
    assert ok, f"Failed deploying pickaxe: {res}"

if __name__ == '__main__':
    deploy_pickaxe()

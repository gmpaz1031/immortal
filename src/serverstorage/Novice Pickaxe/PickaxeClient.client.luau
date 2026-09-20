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
    
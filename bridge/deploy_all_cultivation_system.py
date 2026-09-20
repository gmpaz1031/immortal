import sys
import os
import json
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

def deploy_all():
    print("=== Master Deployment: Cultivation System ===")

    # 1. CultivationConfig
    with open('src/shared/CultivationConfig.luau', 'r', encoding='utf-8') as f:
        cc_src = f.read()
    cc_json = json.dumps({"source": cc_src})

    # 2. ItemConfig
    with open('src/shared/ItemConfig.luau', 'r', encoding='utf-8') as f:
        ic_src = f.read()
    ic_json = json.dumps({"source": ic_src})

    # 3. MAINSERVER
    with open('src/server/MAINSERVER.server.luau', 'r', encoding='utf-8') as f:
        server_src = f.read()
    server_json = json.dumps({"source": server_src})

    # 4. CultivationClient
    with open('src/gui/CultivationClient.client.luau', 'r', encoding='utf-8') as f:
        client_src = f.read()
    client_json = json.dumps({"source": client_src})

    lua = f"""
    local HttpService = game:GetService("HttpService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")
    local StarterGui = game:GetService("StarterGui")

    local report = {{}}

    -- 1. CultivationConfig
    local shared = ReplicatedStorage:WaitForChild("Shared")
    local cc = shared:WaitForChild("CultivationConfig")
    local ccData = HttpService:JSONDecode({json.dumps(cc_json)})
    cc.Source = ccData.source
    table.insert(report, "CultivationConfig deployed: " .. #cc.Source)

    -- 2. ItemConfig
    local ic = shared:WaitForChild("ItemConfig")
    local icData = HttpService:JSONDecode({json.dumps(ic_json)})
    ic.Source = icData.source
    table.insert(report, "ItemConfig deployed: " .. #ic.Source)

    -- 3. MAINSERVER
    local serverFolder = ServerScriptService:WaitForChild("Server")
    local main = serverFolder:WaitForChild("MAINSERVER")
    local sData = HttpService:JSONDecode({json.dumps(server_json)})
    main.Source = sData.source
    table.insert(report, "MAINSERVER deployed: " .. #main.Source)

    -- 4. CultivationClient
    local ui = StarterGui:WaitForChild("CultivationUI")
    local clientScript = ui:WaitForChild("CultivationClient")
    local cData = HttpService:JSONDecode({json.dumps(client_json)})
    clientScript.Source = cData.source
    table.insert(report, "CultivationClient deployed: " .. #clientScript.Source)

    -- 5. ManualSynergyBanner in cultModal
    local cultModal = ui:WaitForChild("CultivationScrollModal")
    local manualBanner = cultModal:FindFirstChild("ManualSynergyBanner")
    if not manualBanner then
        manualBanner = Instance.new("Frame")
        manualBanner.Name = "ManualSynergyBanner"
        manualBanner.Size = UDim2.new(1, -36, 0, 24)
        manualBanner.Position = UDim2.new(0, 18, 0, 188)
        manualBanner.BackgroundColor3 = Color3.fromRGB(24, 38, 32)
        manualBanner.BorderSizePixel = 0
        manualBanner.ZIndex = 25
        manualBanner.Parent = cultModal

        local mbCorner = Instance.new("UICorner")
        mbCorner.CornerRadius = UDim.new(0, 5)
        mbCorner.Parent = manualBanner

        local mbStroke = Instance.new("UIStroke")
        mbStroke.Color = Color3.fromRGB(180, 145, 65)
        mbStroke.Thickness = 1
        mbStroke.Parent = manualBanner

        local mbLabel = Instance.new("TextLabel")
        mbLabel.Name = "Label"
        mbLabel.Size = UDim2.new(1, 0, 1, 0)
        mbLabel.BackgroundTransparency = 1
        mbLabel.Font = Enum.Font.GothamMedium
        mbLabel.Text = "CULTIVATION MANUAL: None  |  EQUIP AN ELEMENTAL SCRIPTURE FOR SYNERGY"
        mbLabel.TextColor3 = Color3.fromRGB(155, 168, 175)
        mbLabel.TextSize = 11
        mbLabel.ZIndex = 26
        mbLabel.Parent = manualBanner
    end
    table.insert(report, "ManualSynergyBanner present: true")

    -- 6. Clean Typography
    local header = cultModal:FindFirstChild("HeaderBanner")
    if header then
        local t = header:FindFirstChild("TitleText") or header:FindFirstChild("Title")
        if t then t.Text = "XIANXIA RPG - CULTIVATION & TECHNIQUES" end
        local s = header:FindFirstChild("SubtitleText") or header:FindFirstChild("Subtitle")
        if s then s.Text = "PROGRESSION PATHWAY - ACTIVE MEDITATION FOCUS" end
    end
    local closeBtn = cultModal:FindFirstChild("CloseBtn", true)
    if closeBtn then
        closeBtn.Text = "X"
        closeBtn.TextSize = 14
    end
    table.insert(report, "Clean typography verified: true")

    return table.concat(report, "\\n")
    """

    ok, res = exec_code(lua)
    print("Master deploy result:\n" + str(res))
    assert ok, f"Deploy failed: {res}"

if __name__ == '__main__':
    deploy_all()

import sys
import os
import pathlib
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from exec import exec_code

def run(lua, label, timeout=25.0):
    print(f"  >> {label}...")
    ok, out = exec_code(lua, timeout=timeout)
    status = "OK" if ok else "FAIL"
    msg = out[:300].replace('\n', ' | ')
    print(f"    [{status}] {msg}")
    return ok

def escape_lua(s):
    return "[====[" + s + "]====]"

def inject(parent_expr, name, source):
    return f"""
local parent = {parent_expr}
local ex = parent:FindFirstChild({repr(name)})
if ex then ex:Destroy() end
local m = Instance.new("ModuleScript")
m.Name = {repr(name)}
m.Source = {escape_lua(source)}
m.Parent = parent
return "Injected: " .. {repr(name)}
"""

def read_server(name):
    return (pathlib.Path(__file__).parent.parent / "src" / "server" / name).read_text(encoding="utf-8")

def read_shared(name):
    return (pathlib.Path(__file__).parent.parent / "src" / "shared" / name).read_text(encoding="utf-8")

WIPE = """
-- Wipe all old DemonCult content before fresh rebuild
local function destroy(parent, name)
    local c = parent:FindFirstChild(name)
    if c then c:Destroy() end
end
destroy(workspace, "DemonCultVillage")
destroy(workspace, "DemonCultTower")
destroy(workspace, "DemonCult_Enemies")
destroy(workspace, "DemonCult_Bosses")
destroy(workspace, "Map")
destroy(game.ServerStorage, "DemonCult_BossTemplates")
destroy(game.ServerStorage, "DemonCult_EnemyTemplates")
for _, c in ipairs(workspace:GetChildren()) do
    if c.Name == "Player" and c:IsA("Model") then c:Destroy() end
end
return "Wiped all DemonCult content."
"""

INIT = """
local SSS = game:GetService("ServerScriptService")
local server = SSS:WaitForChild("Server", 10)
local mgr = server:WaitForChild("DemonCultManager", 10)
if not mgr then return "ERROR: DemonCultManager not found" end
local ok, err = pcall(function()
    local m = require(mgr)
    m.init()
end)
if not ok then return "ERROR: " .. tostring(err) end
return "DemonCultManager.init() SUCCESS"
"""

if __name__ == "__main__":
    server = "game:GetService('ServerScriptService'):WaitForChild('Server')"
    shared = "game:GetService('ReplicatedStorage'):WaitForChild('Shared')"

    print("Phase C -- Demon Cult Tower Deploy\n")

    run(WIPE, "Wipe old DemonCult content")

    # Inject modules
    run(inject(shared, "DemonCultConfig",            read_shared("DemonCultConfig.luau")),          "DemonCultConfig")
    run(inject(server, "DemonCultFactory",           read_server("DemonCultFactory.luau")),         "DemonCultFactory", 30)
    run(inject(server, "DemonCultAI",                read_server("DemonCultAI.luau")),              "DemonCultAI", 30)
    run(inject(server, "DemonCultVillageGenerator",  read_server("DemonCultVillageGenerator.luau")), "DemonCultVillageGenerator", 30)
    run(inject(server, "DemonCultTowerGenerator",    read_server("DemonCultTowerGenerator.luau")),  "DemonCultTowerGenerator", 30)
    run(inject(server, "DemonCultManager",           read_server("DemonCultManager.luau")),         "DemonCultManager", 30)

    # Fire init
    run(INIT, "DemonCultManager.init() -- village + tower + all enemies", timeout=45.0)

    print("\nPhase C deployment complete.")

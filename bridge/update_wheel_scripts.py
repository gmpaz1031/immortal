import sys
import os
sys.path.insert(0, os.path.abspath('.'))
from bridge.exec import exec_code

with open('src/server/DATA.server.luau', 'r', encoding='utf-8') as f:
    data_src = f.read()

with open('src/server/MAINSERVER.server.luau', 'r', encoding='utf-8') as f:
    main_src = f.read()

with open('src/gui/CultivationClient.client.luau', 'r', encoding='utf-8') as f:
    client_src = f.read()

def deploy(parent_code, name, src):
    lua = f"""
    local target = {parent_code}:WaitForChild('{name}')
    target.Source = [====[{src}]====]
    return 'Updated ' .. target:GetFullName()
    """
    ok, res = exec_code(lua)
    print(f"Deploy {name}: ok={ok}, res={res}")
    assert ok, f"Failed to deploy {name}: {res}"

deploy("game:GetService('ServerScriptService'):WaitForChild('Server')", 'DATA', data_src)
deploy("game:GetService('ServerScriptService'):WaitForChild('Server')", 'MAINSERVER', main_src)
deploy("game:GetService('StarterGui'):WaitForChild('CultivationUI')", 'CultivationClient', client_src)
print("All 3 scripts successfully updated!")

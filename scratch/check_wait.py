import re
import urllib.request
import json

with open("src/gui/CultivationUI/CultivationClient.client.luau", "r", encoding="utf-8") as f:
    code = f.read()

matches = re.findall(r'(\w+):WaitForChild\("([^"]+)"\)', code)
print(f"Total WaitForChild calls: {len(matches)}")
for var, child in matches:
    print(f"  {var}:WaitForChild(\"{child}\")")

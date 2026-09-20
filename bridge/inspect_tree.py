import json

with open("instance_tree.json", "r", encoding="utf-8") as f:
    tree = json.load(f)

def print_children(node, path="", max_depth=2, current_depth=0):
    if current_depth >= max_depth:
        return
    for c in node.get("children", []):
        c_path = f"{path}/{c['name']}" if path else c['name']
        print(f"  {c_path} ({c['class']})")
        print_children(c, c_path, max_depth, current_depth + 1)

print("=== REPLICATEDSTORAGE ===")
print_children(tree.get("ReplicatedStorage", {}), max_depth=3)

print("\n=== SERVERSCRIPTSERVICE ===")
print_children(tree.get("ServerScriptService", {}), max_depth=2)

print("\n=== STARTERGUI ===")
print_children(tree.get("StarterGui", {}), max_depth=2)

print("\n=== WORKSPACE HIGHLIGHTS ===")
for c in tree.get("Workspace", {}).get("children", []):
    if c["class"] in ["Model", "Folder", "SpawnLocation"]:
        print(f"  {c['name']} ({c['class']}) - {len(c.get('children', []))} children")

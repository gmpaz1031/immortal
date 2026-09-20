import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from bridge.exec import exec_code
from bridge.capture import capture

cam_script = """
local cam = workspace.CurrentCamera
local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s1 = enemies and enemies:FindFirstChild("Swordsman_1")
if not s1 then return "Swordsman_1 not found" end

local hrp = s1:FindFirstChild("HumanoidRootPart")
if not hrp then return "HRP not found" end

cam.CameraType = Enum.CameraType.Scriptable
local target = hrp.Position + Vector3.new(0, 0, 0)
local eye = hrp.Position + (hrp.CFrame.LookVector * 5.0) + (hrp.CFrame.RightVector * 4.0) + Vector3.new(0, 0.8, 0)
cam.CFrame = CFrame.lookAt(eye, target)

return "Camera placed at Swordsman_1"
"""

ok, res = exec_code(cam_script)
time.sleep(0.5)

img_path = capture(region="viewport", label="swordsman_1_final_forward_grip")
print("Captured screenshot at:", img_path)

restore_script = """
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Fixed
return "Camera restored"
"""
exec_code(restore_script)

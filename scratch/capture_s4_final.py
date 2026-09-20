import sys
import time
from pathlib import Path

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from bridge.exec import exec_code
from bridge.capture import capture

# 1. Position Camera in Studio looking at Swordsman_4
cam_script = """
local cam = workspace.CurrentCamera
local enemies = workspace:FindFirstChild("DestroyedVillage_Enemies")
local s4 = enemies and enemies:FindFirstChild("Swordsman_4")
if not s4 then return "Swordsman_4 not found" end

local hrp = s4:FindFirstChild("HumanoidRootPart")
if not hrp then return "HRP not found" end

cam.CameraType = Enum.CameraType.Scriptable
-- Position camera in front-right of Swordsman_4 looking directly at the sword and right arm
local target = hrp.Position + Vector3.new(0, 0, 0)
local eye = hrp.Position + (hrp.CFrame.LookVector * 4.2) + (hrp.CFrame.RightVector * 3.5) + Vector3.new(0, 0.5, 0)
cam.CFrame = CFrame.lookAt(eye, target)

return "Camera placed at Swordsman_4"
"""

ok, res = exec_code(cam_script)
print("Cam script result:", ok, res)
time.sleep(0.5)

# 2. Capture screenshot
img_path = capture(region="viewport", label="swordsman_4_final_forward_grip")
print("Captured screenshot at:", img_path)

# 3. Restore camera to Fixed
restore_script = """
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Fixed
return "Camera restored"
"""
exec_code(restore_script)

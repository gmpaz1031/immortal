local cam = workspace.CurrentCamera
if cam then
    cam.CameraType = Enum.CameraType.Fixed
end
return "Camera restored"

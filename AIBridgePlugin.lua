-- Local Studio Plugin for Antigravity AI Bridge
-- Automatically installed into %LOCALAPPDATA%\Roblox\Plugins

local HttpService = game:GetService("HttpService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local BRIDGE_URL = "http://127.0.0.1:34875"

print("[AI Bridge Plugin] Initialized and polling bridge server...")

task.spawn(function()
	while true do
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = BRIDGE_URL .. "/poll",
				Method = "GET"
			})
		end)

		if success and response and response.Success then
			local decodeSuccess, data = pcall(function()
				return HttpService:JSONDecode(response.Body)
			end)

			if decodeSuccess and data and data.action == "execute" and data.code then
				print("[AI Bridge Plugin] Executing command: " .. tostring(data.id))
				local fn, compileErr = loadstring(data.code)
				if fn then
					local execSuccess, execOutput = pcall(fn)
					ChangeHistoryService:SetWaypoint("AI Bridge Action")

					pcall(function()
						HttpService:RequestAsync({
							Url = BRIDGE_URL .. "/result",
							Method = "POST",
							Headers = { ["Content-Type"] = "application/json" },
							Body = HttpService:JSONEncode({
								id = data.id,
								success = execSuccess,
								output = tostring(execOutput or "OK")
							})
						})
					end)
				else
					pcall(function()
						HttpService:RequestAsync({
							Url = BRIDGE_URL .. "/result",
							Method = "POST",
							Headers = { ["Content-Type"] = "application/json" },
							Body = HttpService:JSONEncode({
								id = data.id,
								success = false,
								error = tostring(compileErr)
							})
						})
					end)
				end
			end
		end

		task.wait(0.25)
	end
end)

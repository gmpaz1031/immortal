-- Local Studio Plugin for Antigravity AI Bridge
-- Automatically installed into %LOCALAPPDATA%\Roblox\Plugins

local HttpService = game:GetService("HttpService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local BRIDGE_URL = "http://127.0.0.1:34875"

-- Auto-enable LoadStringEnabled in ServerScriptService if possible
pcall(function()
	game:GetService("ServerScriptService").LoadStringEnabled = true
end)

-- Create a toolbar button in Studio
pcall(function()
	local toolbar = plugin:CreateToolbar("AI Bridge")
	local btn = toolbar:CreateButton("Bridge Active", "Antigravity AI Bridge is running", "")
	btn.ClickableWhenViewportHidden = true
	btn.Enabled = false
end)

print("[AI Bridge Plugin] Initialized and polling bridge server on " .. BRIDGE_URL .. "...")

task.spawn(function()
	local hasConnected = false
	while true do
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = BRIDGE_URL .. "/poll",
				Method = "GET"
			})
		end)

		if success and response and response.Success then
			if not hasConnected then
				hasConnected = true
				print("[AI Bridge Plugin] Successfully connected to Python Bridge Server!")
			end

			local decodeSuccess, data = pcall(function()
				return HttpService:JSONDecode(response.Body)
			end)

			if decodeSuccess and data and data.action == "execute" and data.code then
				print("[AI Bridge Plugin] Executing command: " .. tostring(data.id))
				
				-- Ensure LoadStringEnabled
				pcall(function()
					game:GetService("ServerScriptService").LoadStringEnabled = true
				end)

				local fn, compileErr = loadstring(data.code)
				if fn then
					local execSuccess, execOutput = pcall(fn)
					pcall(function()
						ChangeHistoryService:SetWaypoint("AI Bridge Action")
					end)

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


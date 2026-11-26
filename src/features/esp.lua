-- esp.lua — Highlight-based player outline. Local instances never replicate.
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Util = __require("util")

local ESP = {}

local container
local tracked = {}
local connection
local fill = Color3.fromRGB(120, 180, 255)

local function getContainer()
	if container and container.Parent then
		return container
	end

	local folder = Instance.new("Folder")
	folder.Name = "OJB_ESP"

	-- CoreGui survives ScreenGui cleanup by the game and is never replicated.
	local ok = pcall(function()
		folder.Parent = CoreGui
	end)
	if not ok or not folder.Parent then
		local camera = workspace.CurrentCamera
		if camera then
			folder.Parent = camera
		end
	end

	container = folder
	return container
end

local function isTarget(player)
	return player ~= Players.LocalPlayer and player.Character ~= nil
end

local function attach(player)
	if not isTarget(player) then
		return
	end

	local character = player.Character
	if not character or not character:FindFirstChildOfClass("Humanoid") then
		return
	end

	local highlight = tracked[player]
	if highlight and highlight.Parent then
		highlight.Adornee = character
		return
	end

	highlight = Instance.new("Highlight")
	highlight.Name = "OJB_ESP_" .. player.Name
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = fill
	highlight.FillTransparency = 0.55
	highlight.OutlineColor = fill
	highlight.OutlineTransparency = 0
	highlight.Parent = getContainer()

	tracked[player] = highlight
end

local function detach(player)
	local highlight = tracked[player]
	if highlight then
		highlight:Destroy()
		tracked[player] = nil
	end
end

local function clearAll()
	for player in pairs(tracked) do
		detach(player)
	end
	table.clear(tracked)
end

local function sweep()
	for _, player in ipairs(Players:GetPlayers()) do
		attach(player)
	end
end

function ESP.setEnabled(enabled)
	if not enabled then
		if connection then
			connection:Disconnect()
			connection = nil
		end
		clearAll()
		return true
	end

	sweep()

	if not connection then
		connection = RunService.Heartbeat:Connect(function()
			sweep()
			-- Drop entries for players who left or lost their character.
			for player, highlight in pairs(tracked) do
				if not player.Parent or not player.Character then
					detach(player)
				elseif highlight.Adornee ~= player.Character then
					highlight.Adornee = player.Character
				end
			end
		end)
	end
	return true
end

function ESP.setColor(color)
	fill = color
	for _, highlight in pairs(tracked) do
		if highlight.Parent then
			highlight.FillColor = color
			highlight.OutlineColor = color
		end
	end
	return true
end

function ESP.bind()
	Players.PlayerAdded:Connect(function(player)
		if connection then
			player.CharacterAdded:Connect(function()
				if connection then
					task.wait(0.3)
					attach(player)
				end
			end)
		end
	end)
	Players.PlayerRemoving:Connect(detach)
end

function ESP.destroy()
	ESP.setEnabled(false)
	if container then
		container:Destroy()
		container = nil
	end
end

return ESP

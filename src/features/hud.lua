-- hud.lua — on-screen readouts: fps, ping, player count, position, clock.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Config = __require("config")
local Draw = __require("features/draw")

local HUD = {}

local ORDER = { "FPS", "Ping", "Players", "Coords", "Clock" }
local lines = {}
local connection
local enabled = false
local frames, elapsed, fps = 0, 0, 0
local color = Color3.fromRGB(235, 235, 242)

local function lineFor(key)
	if lines[key] then
		return lines[key]
	end
	local index = table.find(ORDER, key) or 1
	lines[key] = Draw.text({
		Size = 13,
		Color = color,
		Outline = true,
		Visible = false,
		Position = Vector2.new(12, 12 + (index - 1) * 16),
	})
	return lines[key]
end

local function ping()
	local ok, value = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if ok and type(value) == "number" then
		return math.floor(value)
	end
	return nil
end

local function refresh()
	fps = (elapsed > 0) and math.floor(frames / elapsed + 0.5) or fps
	frames, elapsed = 0, 0

	local values = {
		FPS = ("fps: %d"):format(fps),
		Ping = (function()
			local value = ping()
			return value and ("ping: %d ms"):format(value) or "ping: ?"
		end)(),
		Players = ("players: %d"):format(#Players:GetPlayers()),
		Clock = ("time: %s"):format(os.date("%H:%M:%S")),
	}

	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	values.Coords = root
		and ("pos: %d, %d, %d"):format(math.floor(root.Position.X), math.floor(root.Position.Y), math.floor(root.Position.Z))
		or "pos: ?"

	for key, text in pairs(values) do
		local line = lineFor(key)
		if line then
			local shown = enabled and Config.get("HUD_" .. key)
			Draw.set(line, { Visible = shown == true, Text = text })
		end
	end
end

function HUD.setEnabled(state)
	enabled = state

	if not state then
		if connection then
			connection:Disconnect()
			connection = nil
		end
		for _, line in pairs(lines) do
			Draw.set(line, { Visible = false })
		end
		return true
	end

	if not Draw.available() then
		return false, "executor has no Drawing API"
	end

	if not connection then
		connection = RunService.Heartbeat:Connect(function(delta)
			frames += 1
			elapsed += delta
			if elapsed >= 0.25 then
				refresh()
			end
		end)
	end
	refresh()
	return true
end

function HUD.setColor(value)
	color = value
	for _, line in pairs(lines) do
		Draw.set(line, { Color = value })
	end
end

function HUD.destroy()
	HUD.setEnabled(false)
	for key, line in pairs(lines) do
		Draw.remove(line)
		lines[key] = nil
	end
end

return HUD

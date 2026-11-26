-- hitsound.lua — plays a sound when another player's health drops.
-- Roblox ships the built-in sounds below with the client, so they cannot 404.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = __require("config")

local Hitsound = {}

Hitsound.choices = {
	{ name = "Ping", id = "rbxasset://sounds/electronicpingshort.wav" },
	{ name = "Button", id = "rbxasset://sounds/button.wav" },
	{ name = "Switch", id = "rbxasset://sounds/switch3.wav" },
	{ name = "Click", id = "rbxasset://sounds/clickfast.wav" },
	{ name = "Hit", id = "rbxasset://sounds/hit.wav" },
	{ name = "Impact", id = "rbxasset://sounds/impact_generic.mp3" },
	{ name = "Water", id = "rbxasset://sounds/impact_water.mp3" },
	{ name = "Bass", id = "rbxasset://sounds/bass.wav" },
}

local connection
local enabled = false
local health = {}

local function resolveSound()
	local custom = Config.get("HitSoundCustom") or ""
	if type(custom) == "string" and custom ~= "" then
		if custom:match("^%d+$") then
			return "rbxassetid://" .. custom
		end
		return custom
	end

	local choice = Config.get("HitSoundChoice") or "Ping"
	for _, entry in ipairs(Hitsound.choices) do
		if entry.name == choice then
			return entry.id
		end
	end
	return Hitsound.choices[1].id
end

function Hitsound.play()
	local id = resolveSound()
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = Config.get("HitSoundVolume") or 1
	sound.PlaybackSpeed = Config.get("HitSoundPitch") or 1
	sound.Parent = SoundService

	SoundService:PlayLocalSound(sound)
	task.delay(4, function()
		sound:Destroy()
	end)
end

local function scan()
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local previous = health[player]
			if previous and humanoid.Health < previous - 0.5 and humanoid.Health > 0 then
				Hitsound.play()
			end
			health[player] = humanoid.Health
		else
			health[player] = nil
		end
	end
end

function Hitsound.setEnabled(state)
	enabled = state

	if not state then
		if connection then
			connection:Disconnect()
			connection = nil
		end
		table.clear(health)
		return true
	end

	if not connection then
		local accumulator = 0
		connection = RunService.Heartbeat:Connect(function(delta)
			if not enabled then
				return
			end
			accumulator += delta
			if accumulator < 0.1 then
				return
			end
			accumulator = 0
			scan()
		end)
	end
	return true
end

function Hitsound.destroy()
	Hitsound.setEnabled(false)
end

return Hitsound

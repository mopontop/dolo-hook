-- ambience.lua — looping local background sound with a few built-in choices.
local SoundService = game:GetService("SoundService")

local Config = __require("config")

local Ambience = {}

Ambience.choices = {
	{ name = "Hum", id = "rbxasset://sounds/bass.wav" },
	{ name = "Ping loop", id = "rbxasset://sounds/electronicpingshort.wav" },
	{ name = "Switch loop", id = "rbxasset://sounds/switch3.wav" },
	{ name = "Impact loop", id = "rbxasset://sounds/impact_water.mp3" },
}

local sound

local function resolve()
	local custom = Config.get("AmbienceCustom") or ""
	if type(custom) == "string" and custom ~= "" then
		if custom:match("^%d+$") then
			return "rbxassetid://" .. custom
		end
		return custom
	end
	local choice = Config.get("AmbienceChoice") or "Hum"
	for _, entry in ipairs(Ambience.choices) do
		if entry.name == choice then
			return entry.id
		end
	end
	return Ambience.choices[1].id
end

function Ambience.stop()
	if sound then
		pcall(function()
			sound:Stop()
			sound:Destroy()
		end)
		sound = nil
	end
end

function Ambience.apply()
	Ambience.stop()

	sound = Instance.new("Sound")
	sound.Name = "DoloHook_Ambience"
	sound.SoundId = resolve()
	sound.Looped = true
	sound.Volume = Config.get("AmbienceVolume") or 0.3
	sound.Parent = SoundService

	SoundService:PlayLocalSound(sound)
	return true
end

function Ambience.destroy()
	Ambience.stop()
end

return Ambience
